package TPath::Compiler;
$TPath::Compiler::VERSION = '1.007';
# ABSTRACT: takes ASTs and returns compiled L<TPath::Expression> objects


use strict;
use warnings;
use v5.10;
no if $] >= 5.018, warnings => "experimental";
use Scalar::Util qw(refaddr blessed reftype);

use TPath::Grammar qw(%FUNCTIONS);

use parent 'Exporter';

use aliased 'TPath::Attribute';
use aliased 'TPath::AttributeTest';
use aliased 'TPath::Concatenation';
use aliased 'TPath::Expression';
use aliased 'TPath::Function';
use aliased 'TPath::Math';
use aliased 'TPath::Predicate::Attribute'     => 'PA';
use aliased 'TPath::Predicate::AttributeTest' => 'PAT';
use aliased 'TPath::Predicate::Boolean'       => 'PB';
use aliased 'TPath::Predicate::Expression'    => 'PE';
use aliased 'TPath::Predicate::Index';
use aliased 'TPath::Selector';
use aliased 'TPath::Selector::Expression' => 'SE';
use aliased 'TPath::Selector::Id';
use aliased 'TPath::Selector::Parent';
use aliased 'TPath::Selector::Previous';
use aliased 'TPath::Selector::Quantified';
use aliased 'TPath::Selector::Self';
use aliased 'TPath::Selector::Test::Anywhere';
use aliased 'TPath::Selector::Test::AnywhereAttribute';
use aliased 'TPath::Selector::Test::AnywhereMatch';
use aliased 'TPath::Selector::Test::AnywhereTag';
use aliased 'TPath::Selector::Test::AxisAttribute';
use aliased 'TPath::Selector::Test::AxisMatch';
use aliased 'TPath::Selector::Test::AxisTag';
use aliased 'TPath::Selector::Test::AxisWildcard';
use aliased 'TPath::Selector::Test::ChildAttribute';
use aliased 'TPath::Selector::Test::ChildMatch';
use aliased 'TPath::Selector::Test::ChildTag';
use aliased 'TPath::Selector::Test::ClosestAttribute';
use aliased 'TPath::Selector::Test::ClosestMatch';
use aliased 'TPath::Selector::Test::ClosestTag';
use aliased 'TPath::Selector::Test::Root';
use aliased 'TPath::Test::And';
use aliased 'TPath::Test::Not';
use aliased 'TPath::Test::Or';
use aliased 'TPath::Test::One';

our @EXPORT_OK = qw(compile);


sub compile {
    my $e = treepath(@_);
    exp_attribute_link( $e, $e, {} );
    return $e;
}

sub exp_attribute_link {
    my ( $e, $ref, $cache ) = @_;
    my $rt = reftype($ref) // '';
    return unless $rt eq 'HASH' or $rt eq 'ARRAY';
    return if $cache->{ refaddr $ref}++;
    if ( blessed $ref && $ref->isa('TPath::Attribute') ) {
        $ref->_expr($e);
    }
    for ($rt) {
        when ('HASH') {
            exp_attribute_link( $e, $_, $cache ) for values %$ref;
        }
        when ('ARRAY') {
            exp_attribute_link( $e, $_, $cache ) for @$ref;
        }
    }
}

sub treepath {
    my ( $ref, $forester ) = @_;
    my @paths;
    for my $p ( @{ $ref->{treepath}{path} } ) {
        push @paths, path( $p, $forester );
    }
    return Expression->new( f => $forester, _selectors => \@paths );
}

sub path {
    my ( $p, $forester ) = @_;
    my @selectors;
    for my $step ( @{ $p->{segment} } ) {
        push @selectors, step( $step, $forester );
    }
    return \@selectors;
}

sub step {
    my ($step) = @_;
    return cs(@_) if exists $step->{cs};
    return full(@_) if exists $step->{step} && exists $step->{step}{full};
    return abbreviated(@_);
}

sub cs {
    my ( $step, $forester ) = @_;
    my $q = $step->{cs}{quantifier};
    if ( exists $step->{cs}{step} ) {
        my $s = full( $step->{cs}, $forester );
        return Quantified->new(
            s          => $s,
            quantifier => 'e',
            top        => $q->{enum}{end},
            bottom     => $q->{enum}{start}
        ) if ref $q;
        return Quantified->new(
            s          => $s,
            quantifier => $q
        );
    }
    my @predicates =
      predicates( $step->{cs}{grouped_step}{predicate}, $forester, 1 );
    return SE->new(
        e          => treepath( $step->{cs}{grouped_step}, $forester ),
        predicates => \@predicates,
    ) unless $q;
    my $e = SE->new( e => treepath( $step->{cs}{grouped_step}, $forester ) );
    return Quantified->new(
        s          => $e,
        quantifier => 'e',
        top        => $q->{enum}{end},
        bottom     => $q->{enum}{start}
    ) if ref $q;
    return Quantified->new(
        s          => $e,
        quantifier => $q
    );
}

sub full {
    my ( $step, $forester ) = @_;
    my @predicates = predicates( $step->{step}{predicate}, $forester );
    return Previous->new( f => $forester, predicates => \@predicates )
      if $step->{step}{full}{previous};
    my $sep        = $step->{separator};
    my $type       = $step->{step}{full}{forward};
    my $complement = $step->{step}{full}{forward}{complement};
    my $axis       = $step->{step}{full}{axis};
    my ( $key, $val ) = each %$type;
    my $rv;    # return value

    for ($key) {
        when ('wildcard') {
            for ($sep) {
                when ('/') {
                    if ($axis) {
                        $rv = AxisWildcard->new(
                            f          => $forester,
                            axis       => $axis,
                            predicates => \@predicates
                        );
                    }
                    else {
                        $rv = AxisWildcard->new(
                            f               => $forester,
                            first_sensitive => 1,
                            predicates      => \@predicates
                        );
                    }
                }
                when ('//') {
                    die 'axes disallowed with // separator' if defined $axis;
                    set_anywhere( \@predicates );
                    $rv = Anywhere->new(
                        f          => $forester,
                        predicates => \@predicates
                    );
                }
                when ('/>') { die '/>* disallowed' }
                default {
                    $rv =
                      $axis
                      ? AxisWildcard->new(
                        f          => $forester,
                        axis       => $axis,
                        predicates => \@predicates
                      )
                      : AxisWildcard->new(
                        f          => $forester,
                        predicates => \@predicates
                      );
                }
            }
        }
        when ('specific') {
            for ($sep) {
                when ('/') {
                    if ($axis) {
                        $rv = AxisTag->new(
                            f          => $forester,
                            axis       => $axis,
                            tag        => $val,
                            predicates => \@predicates
                        );
                    }
                    else {
                        $rv = ChildTag->new(
                            f               => $forester,
                            first_sensitive => 1,
                            tag             => $val,
                            predicates      => \@predicates
                        );
                    }
                }
                when ('//') {
                    die 'axes disallowed with // separator' if defined $axis;
                    set_anywhere( \@predicates );
                    $rv = AnywhereTag->new(
                        f          => $forester,
                        tag        => $val,
                        predicates => \@predicates
                    );
                }
                when ('/>') {
                    die 'axes disallowed with /> separator' if defined $axis;
                    $rv = ClosestTag->new(
                        f          => $forester,
                        tag        => $val,
                        predicates => \@predicates
                    );
                }
                default {
                    $rv =
                      $axis
                      ? AxisTag->new(
                        f          => $forester,
                        axis       => $axis,
                        tag        => $val,
                        predicates => \@predicates
                      )
                      : ChildTag->new(
                        f          => $forester,
                        tag        => $val,
                        predicates => \@predicates
                      );
                }
            }
        }
        when ('pattern') {
            my $rx = $forester->case_insensitive ? qr/$val/i : qr/$val/;
            my %common_args = (
                f          => $forester,
                rx         => $rx,
                val        => $val,
                predicates => \@predicates
            );
            for ($sep) {
                when ('/') {
                    if ($axis) {
                        $rv = AxisMatch->new( %common_args, axis => $axis );
                    }
                    else {
                        $rv =
                          ChildMatch->new( %common_args, first_sensitive => 1 );
                    }
                }
                when ('//') {
                    die 'axes disallowed with // separator' if defined $axis;
                    set_anywhere( $common_args{predicates} );
                    $rv =
                      TPath::Selector::Test::AnywhereMatch->new(%common_args);
                }
                when ('/>') {
                    die 'axes disallowed with /> separator' if defined $axis;
                    $rv = ClosestMatch->new(%common_args);
                }
                default {
                    $rv =
                      $axis
                      ? AxisMatch->new( %common_args, axis => $axis, )
                      : ChildMatch->new(%common_args);
                }
            }
        }
        when ('attribute') {
            my $a =
              attribute( $step->{step}{full}{forward}{attribute}, $forester );
            for ($sep) {
                when ('/') {
                    $rv =
                      $axis
                      ? AxisAttribute->new(
                        f          => $forester,
                        axis       => $axis,
                        a          => $a,
                        predicates => \@predicates
                      )
                      : ChildAttribute->new(
                        f               => $forester,
                        first_sensitive => 1,
                        a               => $a,
                        predicates      => \@predicates
                      );
                }
                when ('//') {
                    die 'axes disallowed with // separator' if defined $axis;
                    set_anywhere( \@predicates );
                    $rv = AnywhereAttribute->new(
                        f          => $forester,
                        a          => $a,
                        predicates => \@predicates
                    );
                }
                when ('/>') {
                    die 'axes disallowed with /> separator' if defined $axis;
                    $rv = ClosestAttribute->new(
                        f          => $forester,
                        a          => $a,
                        predicates => \@predicates
                    );
                }
                default {
                    $rv =
                      $axis
                      ? AxisAttribute->new(
                        f          => $forester,
                        axis       => $axis,
                        a          => $a,
                        predicates => \@predicates
                      )
                      : ChildAttribute->new(
                        f          => $forester,
                        a          => $a,
                        predicates => \@predicates
                      );
                }
            }
        }
    }
    $rv->_invert if $complement;
    return $rv;
}

# tell index predicates if they're attached to a // step
sub set_anywhere {
    my $predicates = shift;
    return unless $predicates;
    for my $p (@$predicates) {
        $p->_anywhere(1) if $p->isa('TPath::Predicate::Index');
    }
}

sub predicates {
    my ( $predicates, $forester, $outer ) = @_;
    return () unless $predicates;
    my @predicates = map { predicate( $_, $forester, $outer ) } @$predicates;
    if ( 1 < grep { $_->isa('TPath::Predicate::Index') } @predicates ) {
        die 'a step may only have one index predicate';
    }
    return @predicates;
}

sub predicate {
    my ( $predicate, $forester, $outer ) = @_;
    my $idx = $predicate->{idx};
    return Index->new( f => $forester, idx => $idx, outer => $outer )
      if defined $idx;
    my $op = $predicate->{condition}{operator};
    return PB->new(
        t     => condition( $predicate, $forester, $op ),
        outer => $outer
    ) if defined $op;
    return PE->new( e => treepath( $predicate, $forester ), outer => $outer )
      if exists $predicate->{treepath};
    my $at = $predicate->{attribute_test};
    return PAT->new( at => attribute_test( $at, $forester ), outer => $outer )
      if defined $at;
    return PA->new(
        a     => attribute( $predicate->{attribute}, $forester ),
        outer => $outer
    );
}

sub attribute {
    my ( $attribute, $forester ) = @_;
    my @args;
    my $args = $attribute->{args};
    if ( defined $args ) {
        push @args, arg( $_, $forester ) for @{ $args->{arg} };
    }
    my $name       = $attribute->{aname}{name};
    my $autoloaded = $attribute->{aname}{autoloaded};
    my $code;
    if ($autoloaded) {
        $code = $forester->autoload_attribute( $name, @args );
        die( ref $forester ) . ' cannot autoload attribute ' . $attribute->{''}
          unless defined $code;
    }
    else {
        $code = $forester->_attributes->{$name};
        die 'unkown attribute @' . $name unless defined $code;
    }
    return Attribute->new(
        name       => $name,
        args       => \@args,
        code       => $code,
        autoloaded => $autoloaded
    );
}

sub arg {
    my ( $arg, $forester ) = @_;
    return $arg unless ref $arg;
    my $v = $arg->{v};
    return $v if defined $v;
    my $num = $arg->{num};
    return $num if defined $num;
    return attribute( $arg, $forester ) if exists $arg->{aname};
    my $a = $arg->{attribute};
    return attribute( $a, $forester ) if defined $a;
    return treepath( $arg, $forester ) if exists $arg->{treepath};
    my $at = $arg->{attribute_test};
    return attribute_test( $at, $forester ) if defined $at;
    my $m = $arg->{math};
    return math( $m, $forester ) if defined $m;
    my $f = $arg->{function};
    return function( $f, $forester ) if defined $f;
    my $c = $arg->{concat};
    return concat( $forester, $c ) if defined $c;
    my $op = $arg->{condition}{operator};
    return condition( $arg, $forester, $op ) if defined $op;
    die
      'fatal compilation error; could not compile parsable argument with keys '
      . ( join ', ', sort keys %$arg );
}

sub concat {
    my ( $f, $c ) = @_;
    my @args = map { arg( $_, $f ) } @{ $c->{carg} };

    # concatenate all constants
    my $i = 0;
    my $acc;
    while ( $i < @args ) {
        my $v = $args[$i];
        if ( ref $v ) {
            $i++;
            $acc = 0;
        }
        elsif ($acc) {
            $args[ $i - 1 ] .= $v;
            splice @args, $i, 1;
            $acc = 1;
        }
        else {
            $acc = 1;
            $i++;
        }
    }
    return $args[0] unless @args > 1;
    return Concatenation->new( args => \@args );
}

sub function {
    my ( $f, $forester ) = @_;
    my $name = $f->{f};
    return Function->new(
        f    => $FUNCTIONS{$name},
        name => $name,
        arg => arg( $f->{arg}, $forester )
    );
}

sub math {
    my ( $m, $forester ) = @_;
    my @args = map { arg( $_, $forester ) } @{ $m->{item} };
    return Math->new( operator => $m->{operator}, args => \@args );
}

sub attribute_test {
    my ( $at, $forester ) = @_;
    my $op    = $at->{cmp};
    my @args  = @{ $at->{value} };
    my $left  = arg( $args[0], $forester );
    my $right = arg( $args[1], $forester );
    return AttributeTest->new( op => $op, left => $left, right => $right );
}

sub condition {
    my ( $predicate, $forester, $op ) = @_;
    my $args = $predicate->{condition}{args};
    my @args;
    push @args, arg( $_, $forester ) for @$args;
    for ($op) {
        when ('!') { return Not->new( t     => $args[0] ) }
        when ('&') { return And->new( tests => \@args ) }
        when ('||') { return Or->new( tests => \@args ) }
        when (';') { return One->new( tests => \@args ) }
    }
}

sub abbreviated {
    my ( $step, $forester ) = @_;
    my $abb = $step->{step}{abbreviated};
    return id(@_) if ref $abb;
    for ($abb) {
        when ('.')  { state $s = Self->new;   return $s }
        when ('..') { state $p = Parent->new; return $p }
        when (':root') { return Root->new( f => $forester ) }
    }
}

sub id {
    my ($step) = @_;
    return Id->new( id => $step->{step}{abbreviated}{id} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Compiler - takes ASTs and returns compiled L<TPath::Expression> objects

=head1 VERSION

version 1.007

=head1 DESCRIPTION

This module is a ghetto for the code that converts an AST produced by L<TPath::Grammar>
into a L<TPath::Expression> object. It's really not something you should be messing
around with unless you're working on TPath itself.

=head1 FUNCTIONS

=head2 compile

Takes an AST reference and a L<TPath::Forester> reference and returns a L<TPath::Expression>.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

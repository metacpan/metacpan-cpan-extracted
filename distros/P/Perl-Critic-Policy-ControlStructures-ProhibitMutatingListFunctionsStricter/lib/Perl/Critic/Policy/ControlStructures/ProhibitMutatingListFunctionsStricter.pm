package Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctionsStricter 0.003;

# ABSTRACT: Do not change $_ in a list function, directly or through a sub that the block calls.

use strict;
use warnings FATAL => 'all';
use 5.014;
use re '/aa';
use Readonly;
use List::Util                 qw{any first};
use Scalar::Util               ();
use Perl::Critic::Distribution ();
use Perl::Critic::Document     ();
use PPI::Statement             ();
use Perl::Critic::Utils        qw{ :severities is_function_call is_method_call is_perl_builtin first_arg };

use parent qw{Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions};


Readonly::Scalar my $CORE            => 'Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions';
Readonly::Scalar my $DESC            => q{Don't modify $_ in list functions};
Readonly::Scalar my $DESC_CALLED     => q{A sub that modifies $_ is called in a list function};
Readonly::Scalar my $EXPL            => [114];
Readonly::Scalar my $DESC_UNRESOLVED => q{A sub or method that may modify $_ is called in a list function};
Readonly::Scalar my $EXPL_UNRESOLVED => q{Say "local ($_) = $_;" before the first call, so that a callee that writes $_ writes a copy};
Readonly::Scalar my $DESC_POSTFIX    => q{A sub or method that may modify $_ is called in a statement with a postfix for};
Readonly::Scalar my $EXPL_POSTFIX    => q{Write a block "for my $x (...) { ... }" instead, so that $_ is not the element};

# The functions that make $_ an alias to each element, for report_unresolved_calls.
Readonly::Array my @ALIASING_FUNCS => (
    qw{ map grep },
    map { ( $_, "List::Util::$_" ) } qw{ first any all none notall },
    map { ( $_, "List::MoreUtils::$_", "List::SomeUtils::$_" ) } qw{
      any all none notall true false firstidx first_index lastidx last_index
      firstval first_value lastval last_value firstres first_result lastres
      last_result onlyidx only_index onlyval only_value onlyres only_result
      indexes after after_incl before before_incl part insert_after
    },
    map { ( $_, "List::UtilsBy::$_" ) } qw{ max_by min_by },
);
Readonly::Hash my %EXPR_FORM => map { $_ => 1 } qw{ map grep };

Readonly::Hash my %CHOPS         => map { $_ => 1 } qw{ chop chomp };
Readonly::Hash my %LOOP          => map { $_ => 1 } qw{ for foreach };
Readonly::Hash my %LIST_FUNCTION => map { $_ => 1 } split m/\s+/xs, ( first { $_->{name} eq 'list_funcs' } $CORE->supported_parameters )->{default_string};

# Change it when what the collector returns changes shape.
Readonly::Scalar my $DATA_FORMAT => 2;

# The definition of what changes $_ is the core policy's, in a sub that it does
# not export.  Said at load, not at the first file.
my $core_side_effect = $CORE->can('_has_topic_side_effect') or die "$CORE has no _has_topic_side_effect, which this policy reuses\n";

# The part of a name after its last ::, which is all of a bare name.
my $bare_name = sub {
    my ($name) = @_;
    my $at     = rindex $name, '::';
    return $at < 0 ? $name : substr $name, $at + 2;
};


sub supported_parameters {
    my ($class) = @_;
    return (
        $class->SUPER::supported_parameters(),
        {
            name           => 'report_unresolved_calls',
            description    => q{Report a call in a list function block that this policy cannot read},
            default_string => '0',
            behavior       => 'boolean',
        },
        {
            name           => 'report_postfix_for_calls',
            description    => q{Report a call in a statement with a postfix for},
            default_string => '0',
            behavior       => 'boolean',
        },
        {
            name           => 'allow_calls',
            description    => q{Subs and methods that those two reports take as not writing $_},
            default_string => q{can DOES isa VERSION},
            behavior       => 'string list',
        },
    );
}


sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    my $enabled = $self->SUPER::initialize_if_enabled($config);

    # The list functions as the core policy configured them, from its
    # list_funcs and add_list_funcs, and those that report_unresolved_calls adds.
    $self->{_block_funcs} = { %{ $self->{_all_list_funcs} }, $self->{_report_unresolved_calls} ? ( map { $_ => 1 } @ALIASING_FUNCS ) : () };

    Perl::Critic::Distribution->register(
        name    => __PACKAGE__,
        version => join( q{/}, $DATA_FORMAT, $CORE->VERSION, Perl::Critic::Distribution->stamp(__FILE__) // q{} ),
        collect => sub {
            my ($ppi)    = @_;
            my $doc      = Perl::Critic::Document->new( -source => $ppi );
            my $packages = packages_in($doc);
            return {
                mutating_subs => [ map { $_->[1] } grep { !$_->[0]->type } mutating_subs_in( $doc, $packages ) ],
                subs          => [ map { $_->[1] } grep { !$_->[0]->type } subs_in( $doc, $packages ) ],
            };
        },
    );
    return $enabled;
}


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @core = $self->SUPER::violates( $elem, $doc );
    return @core if @core;

    if ( $self->{_report_postfix_for_calls} && ( my $statement = postfix_statement($elem) ) ) {
        my $known = $self->known_subs($doc);
        my $call  = $self->first_call( $known, 1, [ topic_owned_in( $statement, $self->{_block_funcs} ) ], grep { precedes( $_, $elem ) } $statement->schildren ) or return;
        return $self->violation( $DESC_POSTFIX, $EXPL_POSTFIX, $call );
    }

    return if !$self->{_block_funcs}{$elem} || !is_function_call($elem);
    my $arg = first_arg($elem) or return;

    my @aliased;
    my %expression;
    if ( $arg->isa('PPI::Structure::Block') ) {
        return $self->violation( $DESC, $EXPL, $elem ) if chops_topic($arg) || ( !$self->{_all_list_funcs}{$elem} && $core_side_effect->( $arg, $doc ) );
        @aliased = aliased_statements($arg);
    }
    elsif ( @aliased = expression_of($elem) ) {
        my $copy = PPI::Statement->new;
        $copy->add_element( $_->clone ) for @aliased;
        return $self->violation( $DESC, $EXPL, $elem ) if mutates_topic( $copy, $doc );
        %expression = map { Scalar::Util::refaddr($_) => 1 } @aliased;
    }
    else {
        return;
    }

    # An expression's owner is its statement, in which topic_owned_in also
    # finds the expression itself.
    my $known = $self->known_subs($doc);
    my $owner = $arg->isa('PPI::Structure::Block') ? $arg : $elem->statement;
    my @owned = grep { !$expression{ Scalar::Util::refaddr($_) } } topic_owned_in( $owner, $self->{_block_funcs} );
    my %owned = map  { Scalar::Util::refaddr($_) => 1 } @owned;
    foreach my $word ( map { $_->isa('PPI::Node') ? @{ $_->find('PPI::Token::Word') || [] } : $_ } @aliased ) {
        next                                                  if !$word->isa('PPI::Token::Word') || !is_function_call($word) || is_inside( $word, \%owned );
        return $self->violation( $DESC_CALLED, $EXPL, $elem ) if calls_sub_in( $word, $word->content, $known->{mutating}, $known->{packages} );
    }

    return if !$self->{_report_unresolved_calls};
    my $call = $self->first_call( $known, 0, \@owned, @aliased ) or return;
    return $self->violation( $DESC_UNRESOLVED, $EXPL_UNRESOLVED, $call );
}


sub first_call {
    my ( $self, $known, $mutating_too, $owned, @elements ) = @_;

    my %owned = map { Scalar::Util::refaddr($_) => 1 } @$owned;
    foreach my $token ( map { $_->isa('PPI::Node') ? $_->tokens : $_ } @elements ) {
        next          if !$token->significant || is_inside( $token, \%owned );
        return $token if $self->is_unsafe_call( $token, $known, $mutating_too );
    }
    return;
}


sub is_unsafe_call {
    my ( $self, $token, $known, $mutating_too ) = @_;

    my $name;
    if ( $token->isa('PPI::Token::Word') ) {
        $name = $token->content;
        return !$self->{_allow_calls}{$name} if is_method_call($token);
        return                               if !is_function_call($token) || $self->{_block_funcs}{$name};
        ( my $core = $name ) =~ s/\ACORE::(?:GLOBAL::)?//xms;
        return if is_perl_builtin($core);
    }
    elsif ( $token->isa('PPI::Token::Symbol') && $token->raw_type eq q{&} ) {
        $name = substr $token->content, 1;
    }
    elsif ( $token->isa('PPI::Token::Cast') ) {
        return $token->content eq q{&};
    }
    elsif ( $token->isa('PPI::Token::Operator') && $token->content eq q{->} ) {
        my $next = $token->snext_sibling;
        return $next && ( $next->isa('PPI::Structure::List') || $next->isa('PPI::Token::Symbol') );
    }
    else {
        return;
    }

    return $mutating_too && calls_sub_in( $token, $name, $known->{mutating}, $known->{packages} ) if calls_sub_in( $token, $name, $known->{defined}, $known->{packages} );
    return !$self->{_allow_calls}{$name};
}


sub known_subs {
    my ( $self, $doc ) = @_;

    # The document is held, not just its address, so the address cannot be
    # handed to the next document while this still answers for it.
    my $last = $self->{_known};
    return $last->{subs} if $last && Scalar::Util::refaddr( $last->{doc} ) == Scalar::Util::refaddr($doc);

    my $packages = packages_in($doc);
    my @here     = subs_in( $doc, $packages );
    my %subs     = (
        packages => $packages,
        mutating => { local => { map { ( $_->[0]->name => 1 ) } mutating_subs_in( $doc, $packages ) }, remote => {} },
        defined  => { local => { map { ( $_->[0]->name => 1 ) } @here },                               remote => { map { ( $_->[1] => 1 ) } @here } },
    );

    my $filename = $doc->filename;
    if ( my $dist = defined $filename && Perl::Critic::Distribution->for_file($filename) ) {
        foreach my $file ( values %{ $dist->collected(__PACKAGE__) } ) {
            $subs{mutating}{remote}{$_} = 1 for @{ $file->{mutating_subs} };
            $subs{defined}{remote}{$_}  = 1 for @{ $file->{subs} };
        }
    }
    foreach my $set ( @subs{qw{ mutating defined }} ) {
        $set->{bare} = { map { ( $bare_name->($_) => 1 ) } keys %{ $set->{remote} } };
    }

    $self->{_known} = { doc => $doc, subs => \%subs };
    return \%subs;
}


sub precedes {
    my ( $elem, $mark ) = @_;
    my ( $line,  $col )  = @{ $elem->location }[ 0, 1 ];
    my ( $mline, $mcol ) = @{ $mark->location }[ 0, 1 ];
    return $line < $mline || ( $line == $mline && $col < $mcol );
}


sub is_inside {
    my ( $elem, $owned ) = @_;
    for ( my $up = $elem; $up; $up = $up->parent ) {
        return 1 if $owned->{ Scalar::Util::refaddr($up) };
    }
    return;
}


sub calls_sub_in {
    my ( $elem, $name, $set, $packages ) = @_;

    return 1 if $set->{local}{$name};
    return   if !$set->{bare}{ $bare_name->($name) };
    my $full = index( $name, '::' ) >= 0 ? $name : package_at( $elem, $packages ) . "::$name";
    return $set->{remote}{$full};
}


sub postfix_statement {
    my ($elem) = @_;

    return if !$LOOP{ $elem->content };
    my $statement = $elem->parent;
    return if !$statement || !$statement->isa('PPI::Statement') || $statement->isa('PPI::Statement::Compound');
    return if $statement->schild(0) == $elem;
    return $statement;
}


sub subs_in {
    my ( $doc, $packages ) = @_;
    return map {
        my $name = $_->name;
        [ $_, index( $name, '::' ) >= 0 ? $name : package_at( $_, $packages ) . "::$name" ]
    } grep { $_->block } @{ $doc->find('PPI::Statement::Sub') || [] };
}


sub mutating_subs_in {
    my ( $doc, $packages ) = @_;

    my @found;
    foreach my $found ( subs_in( $doc, $packages ) ) {
        my $block = $found->[0]->block;
        next if any {
            $_->type eq 'local' && any { $_ eq q{$_} }
              $_->variables
        } @{ $block->find('PPI::Statement::Variable') || [] };
        next if !mutates_topic( own_topic_removed($block), $doc );

        push @found, $found;
    }
    return @found;
}


sub own_topic_removed {
    my ($block) = @_;

    my $copy = $block->clone;

    # An element inside one that is already gone is gone with it.
    foreach my $elem ( topic_owned_in($copy) ) {
        $elem->delete if $elem->top == $copy;
    }
    return $copy;
}


sub topic_owned_in {
    my ( $node, $list_functions ) = @_;
    $list_functions //= \%LIST_FUNCTION;

    my @owned;
    foreach my $statement ( @{ $node->find('PPI::Statement') || [] } ) {
        my @parts = $statement->schildren;
        if ( $statement->isa('PPI::Statement::Compound') ) {
            push @owned, grep { $_->isa('PPI::Structure::Block') } @parts[ 2 .. $#parts ] if $LOOP{ $parts[0] // q{} } && $parts[1] && $parts[1]->isa('PPI::Structure::List');
        }
        elsif ( $statement->isa('PPI::Statement::Sub') ) {
            push @owned, $statement;
        }
        elsif ( my $loop = first { $parts[$_]->isa('PPI::Token::Word') && $LOOP{ $parts[$_]->content } } 1 .. $#parts ) {
            push @owned, @parts[ 0 .. $loop - 1 ];
        }
    }
    foreach my $word ( @{ $node->find('PPI::Token::Word') || [] } ) {
        my $next = $word->snext_sibling;
        if ( $word->content eq 'sub' ) {
            $next = $next->snext_sibling while $next && is_sub_header($next);
        }
        push @owned, $next                if $next && $next->isa('PPI::Structure::Block') && ( $word->content eq 'sub' || $list_functions->{ $word->content } );
        push @owned, expression_of($word) if $list_functions->{ $word->content };
    }
    return @owned;
}


sub expression_of {
    my ($elem) = @_;

    return if !$EXPR_FORM{ $elem->content } || !is_function_call($elem);
    my $arg = first_arg($elem);
    return if !$arg || $arg->isa('PPI::Structure::Block');

    my @parts;
    for ( my $part = $arg; $part && !( $part->isa('PPI::Token::Operator') && $part->content eq q{,} ); $part = $part->snext_sibling ) {
        push @parts, $part;
    }
    return @parts;
}


sub is_sub_header {
    my ($elem) = @_;
    return
         $elem->isa('PPI::Token::Prototype')
      || $elem->isa('PPI::Token::Attribute')
      || $elem->isa('PPI::Structure::List')
      || ( $elem->isa('PPI::Token::Operator') && $elem->content eq q{:} );
}


sub mutates_topic {
    my ( $block, $doc ) = @_;
    return 1 if $core_side_effect->( $block, $doc );
    return chops_topic($block);
}


sub aliased_statements {
    my ($block) = @_;

    my @statements;
    foreach my $statement ( $block->schildren ) {
        push @statements, $statement;
        last if $statement->isa('PPI::Statement::Variable') && $statement->type eq 'local' && any { $_ eq q{$_} } $statement->variables;
    }
    return @statements;
}


sub chops_topic {
    my ($block) = @_;
    return any {
        my $arg = first_arg($_);
        $CHOPS{ $_->content } && is_function_call($_) && ( !$arg || ( $arg->isa('PPI::Token::Structure') && $arg->content eq q{;} ) )
    } @{ $block->find('PPI::Token::Word') || [] };
}


sub packages_in {
    my ($ppi) = @_;
    return $ppi->find('PPI::Statement::Package') || [];
}


sub package_at {
    my ( $elem, $packages ) = @_;

    my $package = 'main';
    foreach my $statement (@$packages) {
        my $block = first { $_->isa('PPI::Structure::Block') } $statement->schildren;
        if ($block) {
            for ( my $up = $elem->parent; $up; $up = $up->parent ) {
                return $statement->namespace if $up == $block;
            }
            next;
        }
        my ( $line,    $col )    = @{ $statement->location }[ 0, 1 ];
        my ( $at_line, $at_col ) = @{ $elem->location }[ 0, 1 ];
        $package = $statement->namespace if $line < $at_line || ( $line == $at_line && $col < $at_col );
    }
    return $package;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctionsStricter - Do not change $_ in a list function, directly or through a sub that the block calls.

=head1 VERSION

version 0.003

=head1 DESCRIPTION

The block of C<map>, C<grep>, C<first> and the other list functions sees each
element of its list as C<$_>, and C<$_> is an alias: a change to C<$_> changes
the list.  C<ControlStructures::ProhibitMutatingListFunctions> reports a block
that changes C<$_>.  It cannot see a block that calls a sub that changes it:

    sub trim { s/\s+\z//; return }
    ...
    my @tidy = map { trim(); $_ } @lines;    # reported: @lines is trimmed too

This policy reports everything that the core policy reports, and that call.
Enable it in place of the core policy, not beside it, or each direct case is
reported twice.

Two more reports are off by default.  One is a call in the block to a sub or
method that this policy cannot read, L</Calls that this policy cannot read>.
The other is a call in a statement with a postfix C<for>, L</A postfix for>.

=head2 What changes $_

The definition of the core policy, which this policy subclasses: an assignment
to C<$_>, a substitution or a transliteration that binds to it without C</r>,
C<chop>, C<chomp>, and a four-argument C<substr> of it.  The C<list_funcs> and
C<add_list_funcs> parameters of the core policy work here too.

One addition: C<chomp;> and C<chop;>, written with the semicolon that ends their
statement.  The core policy takes that semicolon for an argument, and misses
them.

And one more: C<map EXPR, LIST> and C<grep EXPR, LIST> alias C<$_> as the
block forms do, so their expression counts as a block, for every rule here.
The core policy reads only the block:

    my @z = map s/x//, @y;    # reported
    my @z = map trim(), @y;   # reported, as a call of a sub that changes $_

=head2 A sub that changes $_

A sub whose body changes C<$_>, by the definition above, and does not make
C<$_> its own first.  These do not count, because there C<$_> is not the
caller's:

=over

=item * the body of a C<foreach> with no loop variable, and the part of a
statement before a postfix C<for>, but not the list of either, which perl
evaluates before it aliases C<$_>,

=item * the block of a list function inside the sub, and the expression of a
C<map EXPR> or C<grep EXPR>, but not its list,

=item * an inner sub, named or anonymous, with or without a signature, a
prototype or attributes.

=back

A sub that declares C<local $_> anywhere does not count at all.

The sub can be in the same file, by its name.  It can be in another file of the
same distribution, which L<Perl::Critic::Distribution> reads: a package sub,
called by its full name, or by its bare name from the same package.  A bare call
from another package is left alone, because what that package imports is not
known.  A method call is left alone, because the method that runs can be another
sub of the same name.

Only one call deep: a sub that calls a sub that changes C<$_> is not reported.

The same places count in the block that calls it.  A call there does not
count, because it changes another list, or runs later, or not at all:

    my @t = map { my @z = map { trim(); $_ } @y; $_ } @lines;  # the inner map only
    my @t = map { for (@y) { trim() } $_ } @lines;             # OK! changes @y
    my @t = map { my $c = sub ($y) { trim() }; $_ } @lines;    # OK! not called here

A C<for my $x> loop names its own variable and leaves C<$_> as the element, so
a call in its body still counts.

=head2 A local $_ in the block

A C<local $_> at the top level of the block gives the block a C<$_> of its
own.  A sub that is called after it changes that copy, and not the list, so
those calls do not count.  Say it before the first call:

    my @tidy = map { local ($_) = $_; trim(); $_ } @lines;    # OK!

A call in the C<local> statement itself still counts:
C<local ($_) = trim()> calls C<trim> before C<$_> is localized.  So does a
call before it, and a C<local $_> inside an inner block covers nothing.

C<local $_;> and C<local $_ = $_;> work as well.  But the second is reported
as a change to C<$_> by the core policy, so by this one, and
C<Variables::RequireInitializationForLocalVars> reports the first.

A change to C<$_> in the block itself, after the C<local>, is still reported.
It is the core policy's test, and that test does not read the C<local>.

=head2 Calls that this policy cannot read

Off unless C<report_unresolved_calls> turns it on.

The rules above can judge only a sub whose body they can read.  A method, a
code reference, or a sub of another distribution can change C<$_> just the
same, and the commonest case is a C<while (<$fh>)> in some helper of another
module:

    sub first_line {
        my ($file) = @_;
        open my $fh, '<', $file or die "$file: $!";
        while (<$fh>) { last }     # assigns each line to $_
        return $_;
    }

    my @heads = map { first_line($_) } @files;
    # @files now holds the first line of each file, or undef for an empty one

With C<report_unresolved_calls>, a call in the block of a list function to a
callee that this policy cannot read is reported, before any C<local $_> at the
top of the block.  The fix is the one in L</A local $_ in the block>:

    my @heads = map { local ($_) = $_; first_line($_) } @files;    # OK!

A copy, such as C<my $file = $_;>, is no fix, because the callee still writes
C<$_>, which is still the element.

These are calls that cannot be read:

    f($_)                     # a sub defined in no file of the distribution
    Some::Where::f($_)        # the same, by its full name
    $_->is_ok                 # a method
    Some::Class->new($_)      # a class method
    $o->$name                 # a method by its name in a variable
    $code->($_)               # a code reference
    &$code  &f                # with an ampersand
    PI                        # a constant is a sub too

These are not calls that cannot be read:

    lc  CORE::lc($_)          # a builtin
    trim()                    # a sub that this policy reads, as above
    $_->isa('Some::Class')    # a method named in allow_calls

A sub is read when it is found as L</A sub that changes $_> finds it: by its
name in the same file, or by its full name in the distribution.  So a bare call
from another package, whose import is not known, cannot be read, and is
reported.  A method is never read, because the method that runs can be another
sub of the same name.

The list functions are those of C<list_funcs> and C<add_list_funcs>, and also
these, with or without the package.  On perl 5.44, a callee that assigns to
C<$_> changed the elements of each of them:

    map grep
    List::Util       first any all none notall
    List::MoreUtils  any all none notall true false firstidx first_index
    List::SomeUtils  lastidx last_index firstval first_value lastval
                     last_value firstres first_result lastres last_result
                     onlyidx only_index onlyval only_value onlyres
                     only_result indexes after after_incl before
                     before_incl part insert_after
    List::UtilsBy    max_by min_by

The core's C<list_funcs> names only the full names of the functions of CPAN,
and code calls them by the name that it imported.  With
C<report_unresolved_calls>, every report of this policy uses this longer list,
so a change to C<$_> in the block of a bare C<any> is reported too.

These do not alias C<$_>, and are not list functions here: C<sort> and
C<reduce>, which set C<$a> and C<$b>; C<apply> of List::MoreUtils, and
C<sort_by>, C<uniq_by> and the other functions of List::UtilsBy, which give the
block a copy.  C<insert_after_string>, which the core lists, takes no block.

In the block, a call does not count where C<$_> belongs to another construct:
in the places that L</A sub that changes $_> lists, which are reported on
their own or run later.

=head2 A postfix for

Off unless C<report_postfix_for_calls> turns it on.

A statement with a postfix C<for> makes C<$_> an alias to each element, as a
list function does.  It has no block to put a C<local> in, and it cannot name
its variable.  With C<report_postfix_for_calls>, the part of the statement
before the C<for> is reported when it calls a sub that changes C<$_>, by
L</A sub that changes $_>, or a call that cannot be read, by
L</Calls that this policy cannot read>.  Write it as a block C<for> with a
lexical variable, which does not make C<$_> an alias at all:

    $_->load for @documents;                  # reported
    for my $doc (@documents) { $doc->load }   # OK!

    print for @lines;                         # OK! a builtin
    s/\s+\z// for @lines;                     # OK! a change on purpose
    sub has_x { return /x/ } has_x() for @x;  # OK! read, and it does not change $_

A block C<foreach> with no loop variable makes C<$_> an alias as well, but it
can name one.  L<Perl::Critic::Policy::Variables::ProhibitTopicIterator>, in
Perl-Critic-Grape, reports each of them, and this policy does not.

=head2 Caveats

A call that perl makes for the code, and that the code does not spell, is not
seen: an overloaded operator, a tied variable, a C<DESTROY>, C<sort SUBNAME>,
C<require> and C<do FILE>.

Some lists are not the caller's data, and a call there is reported all the
same.  C<keys> returns copies, so a write to C<$_> in C<for (keys %h)> changes
nothing that lasts.  A write to an element of a literal list, as in
C<for (1, 2)>, dies with "Modification of a read-only value attempted".
C<values> does return aliases.

=head1 CONFIGURATION

The C<list_funcs> and C<add_list_funcs> of
L<Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions>.

C<report_unresolved_calls> reports a call in a list function block that this
policy cannot read, as L</Calls that this policy cannot read> says.  Off by
default.

C<report_postfix_for_calls> reports a call in a statement with a postfix
C<for>, as L</A postfix for> says.  Off by default.

C<allow_calls> names subs and methods that those two take as not writing C<$_>.
A sub is matched as it is written in the call, so C<Some::g> does not allow
C<g>, and a method by its name alone.  It does not cover a sub that this policy
reads and finds to change C<$_>.  The default is C<can DOES isa VERSION>, the
methods of C<UNIVERSAL>, which perl provides.  A list replaces the default, so
name them too to keep them.

    [ControlStructures::ProhibitMutatingListFunctionsStricter]
    report_unresolved_calls  = 1
    report_postfix_for_calls = 1
    allow_calls = can DOES isa VERSION to_string id name

    my @r = map { f($_) } @x;                      # reported
    my @r = map { $_->id } @x;                     # OK! in allow_calls
    my @r = map { local ($_) = $_; f($_) } @x;     # OK!
    $_->save for @objects;                         # reported
    for my $object (@objects) { $object->save }    # OK!

=head2 METHODS

=head3 supported_parameters

Those of the core policy, and C<report_unresolved_calls>,
C<report_postfix_for_calls> and C<allow_calls>.

=head3 default_severity

=head3 default_themes

=head3 applies_to

Those of the core policy.

=head3 initialize_if_enabled

What the core policy does, and registers what this policy needs from each file
of a distribution with L<Perl::Critic::Distribution>: the package subs that
change C<$_>, and all the package subs.  A lexical sub is left out, because no
other file can call it.

=head3 violates

=head3 first_call

    my $call = $self->first_call( $known, $mutating_too, \@owned, @elements );

The first token of C<@elements>, or inside them, that calls a sub or method
that this policy cannot read, and is not in C<allow_calls>.  With
C<$mutating_too>, a call of a sub that changes C<$_> counts as well.  Nothing
inside an element of C<@owned>, from C<topic_owned_in>, counts.  C<$known> is
from C<known_subs>.

=head3 is_unsafe_call

    my $unsafe = $self->is_unsafe_call( $token, $known, $mutating_too );

Whether a token calls a sub or method that C<first_call> counts: one that this
policy cannot read and C<allow_calls> does not name, or, with
C<$mutating_too>, a sub that changes C<$_>.  A builtin is not a call.

=head3 known_subs

The subs of a document and of the rest of its distribution, for
C<calls_sub_in>: under C<mutating> those that change C<$_>, and under
C<defined> all of them.  Each holds the names in the document under C<local>,
the full names under C<remote>, and the part after the last C<::> of each full
name under C<bare>.  Worked out once for each document, since C<violates> is
called once for each word.

=head2 FUNCTIONS

The steps of C<violates>, for its tests.

=head3 precedes

    my $earlier = precedes( $elem, $mark );

Whether C<$elem> starts before C<$mark> in the document.

=head3 is_inside

    my $inside = is_inside( $elem, \%by_address );

Whether C<$elem>, or a node around it, is in a hash keyed by the address of
each element.

=head3 calls_sub_in

    my $found = calls_sub_in( $elem, $name, $known->{mutating}, $known->{packages} );

Whether a call of C<$name> at C<$elem> runs a sub of a set from C<known_subs>:
one of the document by its name, or one of the distribution by its full name,
where a bare name is in the package of C<$elem>.

=head3 postfix_statement

The statement of C<$elem>, when C<$elem> is the C<for> or C<foreach> of a
postfix C<for>.

=head3 subs_in

    my @found = subs_in( $doc, packages_in($doc) );

Each sub of a L<Perl::Critic::Document> that has a body, as a pair of its
statement and its full name.

=head3 mutating_subs_in

    my @found = mutating_subs_in( $doc, packages_in($doc) );

Each sub of a L<Perl::Critic::Document> that changes C<$_>, as a pair of its
statement and its full name.  L</A sub that changes $_> says which.

=head3 own_topic_removed

A copy of a block without the parts that C<topic_owned_in> finds.

=head3 topic_owned_in

    my @owned = topic_owned_in( $node, \%list_functions );

The parts of a node where C<$_> is not the caller's: the blocks of a
C<foreach> with no loop variable, the part of a statement before a postfix
C<for>, the block of a list function, the expression of C<map EXPR, LIST> and
C<grep EXPR, LIST>, and an inner sub.  The list of a loop or of a list
function is the caller's, because perl evaluates it before it aliases C<$_>.
The list functions are those of the core's C<list_funcs> unless
C<\%list_functions> names others.

=head3 expression_of

    my @parts = expression_of($elem);

The parts of the expression of C<map EXPR, LIST> or C<grep EXPR, LIST>, when
C<$elem> is its C<map> or C<grep>, up to the comma before the list.  None for
the block form, or for any other word.

=head3 is_sub_header

Whether an element is one of those that L<PPI> puts between the word
C<sub> of an anonymous sub and its block: a signature or a prototype, which it
gives as a L<PPI::Token::Prototype>, and the C<:> and L<PPI::Token::Attribute>
of each attribute, with a signature after them as a L<PPI::Structure::List>.

=head3 mutates_topic

Whether a block changes C<$_>: the core policy's test, and C<chomp;> or
C<chop;>, which it misses.  C<$doc> is a L<Perl::Critic::Document>, which the
core test reads a regular expression with.

=head3 aliased_statements

    my @statements = aliased_statements($block);

The statements at the top level of a block, up to and with the first that
says C<local $_>.  The statements after it run with a C<$_> of the block's
own.

=head3 chops_topic

Whether a block calls C<chop> or C<chomp> with no argument, including one that
ends its statement, as C<chomp;>.

=head3 packages_in

The C<package> statements of a document, in order, for C<package_at>.  A
document is searched once, and not once for each element.

=head3 package_at

    my $package = package_at( $elem, packages_in($ppi) );

The package that an element is in: that of the block of a C<package NAME { }>
around it, or else that of the last C<package NAME;> before it, or C<main>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitmutatinglistfunctionsstricter/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

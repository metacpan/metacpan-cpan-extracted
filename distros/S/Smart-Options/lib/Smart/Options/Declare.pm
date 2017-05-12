package Smart::Options::Declare;
use strict;
use warnings;

use Exporter 'import';
use Smart::Options;
use PadWalker qw/var_name/;

our @EXPORT = qw(opts opts_coerce);

our $COERCE = {
    Multiple => {
        type      => 'ArrayRef',
        generater => sub {
            if ( defined $_[0] ) {
                return [
                    split(
                        qr{,},
                        ref( $_[0] ) eq 'ARRAY' ? join( q{,}, @{ $_[0] } ) : $_[0]
                    )
                ];
            } else {
                return $_[0];
            }
        }
    }
};
my %is_invocant = map{ $_ => undef } qw($self $class);

sub opts {
    {
        package DB;
        () = caller(1);
    }

    if ( exists $is_invocant{ var_name( 1, \$_[0] ) || '' } ) {
        $_[0] = shift @DB::args;
        shift;
    }

    my $opt = Smart::Options->new();
    $opt->type(config => 'Config');

    for ( my $i = 0 ; $i < @_ ; $i++ ) {
        ( my $name = var_name( 1, \$_[$i] ) )
          or Carp::croak('usage: opts my $var => TYPE, ...');

        $name =~ s/^\$//;

        if ($name =~ /_/) {
            (my $newname = $name) =~ s/_/-/g;
            $opt->alias($newname => $name);

            $name = $newname;
        }

        my $rule = $_[$i+1];

        if ($rule) {
            if (ref($rule) && ref($rule) eq 'HASH') {

                if ($rule->{default}) {
                    $opt->default($name => $rule->{default});
                }

                if ($rule->{required}) {
                    $opt->demand($name);
                }

                if ($rule->{alias}) {
                    $opt->alias($rule->{alias} => $name);
                }

                if ($rule->{comment}) {
                    $opt->describe($name => $rule->{comment});
                }

                if (my $isa = $rule->{isa}) {
                    if ($isa eq 'Bool') {
                        $opt->boolean($name);
                    }
                    $opt->type($name => $isa);
                }
            }
            else {
                if ($rule eq 'Bool') {
                    $opt->boolean($name);
                }
                $opt->type($name => $rule);
            }
        }

        #auto set alias
        if (length($name) > 1) {
            $opt->alias(substr($name,0,1) => $name);
        }

        $i++ if defined $_[$i+1]; # discard type info
    }

    while (my ($isa, $c) = each(%$COERCE)) {
        $opt->coerce($isa => $c->{type}, $c->{generater});
    }

    my $argv = $opt->parse;
    for ( my $i = 0 ; $i < @_ ; $i++ ) {
        ( my $name = var_name( 1, \$_[$i] ) )
          or Carp::croak('usage: opts my $var => TYPE, ...');

        $name =~ s/^\$//;

        $_[$i] = $argv->{$name};
        $i++ if defined $_[$i+1]; # discard type info
    }
}

sub opts_coerce {
    my ($isa, $type, $generater) = @_;

    $COERCE->{$isa} = { type => $type, generater => $generater };
}

1;
__END__

=encoding utf8

=head1 NAME

Smart::Options::Declare - DSL for Smart::Options

=head1 SYNOPSIS

  use Smart::Options::Declare;

  opts my $rif => 'Int', my $xup => 'Num';

  if ($rif - 5 * $xup > 7.138) {
      say 'Buy more fiffiwobbles';
  }
  else {
     say 'Sell the xupptumblers';
  }

  # $ ./example.pl --rif=55 --xup=9.52
  # Buy more fiffiwobbles
  #
  # $ ./example.pl --rif 12 --xup 8.1
  # Sell the xupptumblers

=head1 DESCRIPTION

Smart::Options::Declare is a library which offers DSL for Smart::Options. 

=head1 METHOD

=head2 opts $var => TYPE, $var2 => { isa => TYPE, RULE => ... }

set option value to variable.

  use Smart::Options::Declare;
  
  opts my $var => 'Str', my $value => { isa => 'Int', default => 4 };

=head2 opts_coerce ( NewType, Source, Generater )

define new type and convert logic.

  opts_coerce Time => 'Str', sub { Time::Piece->strptime($_[0]) }
  
  opts my $time => 'Time';
  
  $time->hour;

=head1 RULE

=head2 isa
define option value type. see L</TYPES>.

=head2 required
define option value is required.

=head2 default
define options default value. If passed a coderef, it
will be executed if no value is provided on the command line.

=head2 alias
define option param's alias.

=head2 comment
this comment is used to generate help. help can show --help

=head1 TYPES

=head2 Str

=head2 Int

=head2 Num

=head2 Bool

=head2 ArrayRef

=head2 HashRef

=head2 Multiple

This subtype is based off of ArrayRef. It will attempt to split any values passed on the command line on a comma: that is,

  opts my $foo => 'ArrayRef';
  # script.pl --foo=one --foo=two,three
  # => ['one', 'two,three']

will become

  opts my $foo => 'Multiple';
  # script.pl --foo=one --foo=two,three
  # => ['one', 'two', 'three']

=head1 AUTHOR

Kan Fushihara E<lt>kan.fushihara@gmail.comE<gt>

=head1 SEE ALSO

L<opts>

=head1 LICENSE

Copyright (C) Kan Fushihara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

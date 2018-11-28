package String::Interpolate::RE;

# ABSTRACT: interpolate variables into strings using regular expressions

use strict;
use warnings;
use Carp;

use Exporter qw[ import ];
our @EXPORT_OK = qw( strinterp );

our $VERSION = '0.08';

## no critic (ProhibitAccessOfPrivateData)

sub strinterp {

    my ( $text, $var, $opts ) = @_;

    $var = {} unless defined $var;

    my %opt = (
        variable_re        => qr/\w+/,
        raiseundef         => 0,
        emptyundef         => 0,
        useenv             => 1,
        format             => 0,
        recurse            => 0,
        recurse_limit      => 0,
        recurse_fail_limit => 100,
        defined $opts
        ? ( map { ( lc $_ => $opts->{$_} ) } keys %{$opts} )
        : (),
    );
    ## use critic

    my $fmt = $opt{format} ? ':([^}]+)' : '()';

    $opt{track} = {};
    $opt{loop}  = 0;
    $opt{fmt}   = $fmt;

    _strinterp( $text, $var, \%opt );

    return $text;
}

sub _strinterp {

    my $var = $_[1];
    my $opt = $_[2];
    my $fmt = $opt->{fmt};
    my $re  = $opt->{variable_re};

    $_[0] =~ s{
               \$                    # find a literal dollar sign
              (                      # followed by either
               \{ ($re)(?:$fmt)? \}  #  a variable name in curly brackets ($2)
                                     #  and an optional sprintf format
               |                     # or
                (\w+)                #   a bareword ($3)
              )
            }{
              my $t = defined $4 ? $4 : $2;

              my $user_value = 'CODE' eq ref $var ? $var->($t) : $var->{$t};

              my $v =
              # user provided?
                defined $user_value               ? $user_value

              # maybe in the environment
              : $opt->{useenv} && exists $ENV{$t}   ? $ENV{$t}

              # undefined: throw an error?
              : $opt->{raiseundef}                  ? croak( "undefined variable: $t\n" )

              # undefined: replace with ''?
              : $opt->{emptyundef}                  ? ''

              # undefined
              :                                     undef

              ;

              if ( $opt->{recurse} && defined $v ) {


                RECURSE:
                  {

                      croak(
                          "circular interpolation loop detected with repeated interpolation of <\$$t>\n"
                      ) if $opt->{track}{$t}++;

                      ++$opt->{loop};

                      last RECURSE if $opt->{recurse_limit} && $opt->{loop} > $opt->{recurse_limit};

                      croak(
                          "recursion fail-safe limit ($opt->{recurse_fail_limit}) reached at interpolation of <\$$t>\n"
                      ) if $opt->{recurse_fail_limit} && $opt->{loop} > $opt->{recurse_fail_limit};

                      _strinterp( $v, $_[1], $_[2] );

                  }

                  delete $opt->{track}{$t};
                  --$opt->{loop};
              }

              # if not defined, just put it back into the string
                 ! defined $v                     ? '$' . $1

              # no format? return as is
              :  ! defined $3 || $3 eq ''         ? $v

              # format it
              :                                     sprintf( $3, $v)

              ;

        }egx;
}

1;

#
# This file is part of String-Interpolate-RE
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

String::Interpolate::RE - interpolate variables into strings using regular expressions

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use String::Interpolate::RE qw( strinterp );

    $str = strinterp( "${Var1} $Var2", $vars, \%opts );

=head1 DESCRIPTION

This module interpolates variables into strings using regular
expression matching rather than Perl's built-in interpolation
mechanism and thus hopefully does not suffer from the security
problems inherent in using B<eval> to interpolate into strings of
suspect ancestry.

=head1 INTERFACE

=over

=item strinterp

    $str = strinterp( $template );
    $str = strinterp( $template, $vars );
    $str = strinterp( $template, $vars, \%opts );

Interpolate variables into a template string, returning the
resultant string.  The template string is scanned for tokens of the
form

    $VAR
    ${VAR}

where C<VAR> is composed of one or more word characters (as defined by
the C<\w> Perl regular expression pattern). C<VAR> is resolved using
the optional C<$vars> argument, which may either by a hashref (in
which case C<VAR> must be a key), or a function reference (which is
passed C<VAR> as its only argument and must return the value).

If the value returned for C<VAR> is defined, it will be interpolated
into the string at that point.  By default, variables which are not
defined are by default left as is in the string.

The C<%opts> parameter may be used to modify the behavior of this
function.  The following (case insensitive) keys are recognized:

=over

=item format I<boolean>

If this flag is true, the template string may provide a C<sprintf>
compatible format which will be used to generate the interpolated
value.  The format should be appended to the variable name with
an intervening C<:> character, e.g.

    ${VAR:fmt}

For example,

    %var = ( foo => 3 );
    print strinterp( '${foo:%03d}', \%var, { format => 1 } );

would result in

    003

=item raiseundef I<boolean>

If true, a variable which has not been defined will result in an
exception being raised.  This defaults to false.

=item emptyundef I<boolean>

If true, a variable which has not been defined will be replaced with
the empty string.  This defaults to false.

=item useENV I<boolean>

If true, the C<%ENV> hash will be searched for variables which are not
defined in the passed C<%var> hash.  This defaults to true.

=item recurse I<boolean>

If true, derived values are themselves scanned for variables to
interpolate.  To specify a limit to the number of levels of recursions
to attempt, set the C<recurse_limit> option.  Circular dependencies
are caught, but just to be safe there's a limit of recursion levels
specified by C<recurse_fail_limit>, beyond which an exception is
thrown.

For example,

  my %var = ( a => '$b', b => '$c', c => 'd' );
  strinterp( '$a', \%var ) => '$b'
  strinterp( '$a', \%var, { recurse => 1 } ) => 'd'
  strinterp( '$a', \%var, { recurse => 1, recurse_limit => 1 } ) => '$c'

  strinterp( '$a', { a => '$b', b => '$a' } , { recurse => 1 }
        recursive interpolation loop detected with repeated
        interpolation of $a

=item recurse_limit I<integer>

The number of recursion levels to descend when recursing into a
variable's value before stopping.  The default is C<0>, which means no
limit.

=item recurse_fail_limit I<integer>

The number of recursion levels to descend when recursing into a
variable's value before giving up and croaking.  The default is C<100>.
Setting this to C<0> means no limit.

=item variable_re I<regular expression>

This specifies the regular expression (created with the C<qr>
operator) which will match a variable name.  It defaults to
C<qr/\w+/>. Don't use C<:>, C<{>, or C<}> in the regex, or things may
break.

=back

=back

=head1 DIAGNOSTICS

=over

=item C<< undefined variable: %s >>

This string is thrown if the C<RaiseUndef> option is set and the
variable C<%s> is not defined.

=item C<< recursive interpolation loop detected with repeated interpolation of <%s> >>

When resolving nested interpolated values (with the C<recurse> option
true ) a circular loop was found.

=item C<< recursion fail-safe limit (%d) reached at interpolation of <%s> >>

The recursion fail safe limit (C<recurse_fail_limit>) was reached while
interpolating nested variable values (with the C<recurse> option true ).

=back

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Interpolate-RE>.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod     use String::Interpolate::RE qw( strinterp );
#pod
#pod     $str = strinterp( "${Var1} $Var2", $vars, \%opts );
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module interpolates variables into strings using regular
#pod expression matching rather than Perl's built-in interpolation
#pod mechanism and thus hopefully does not suffer from the security
#pod problems inherent in using B<eval> to interpolate into strings of
#pod suspect ancestry.
#pod
#pod
#pod =head1 INTERFACE
#pod
#pod =over
#pod
#pod =item strinterp
#pod
#pod     $str = strinterp( $template );
#pod     $str = strinterp( $template, $vars );
#pod     $str = strinterp( $template, $vars, \%opts );
#pod
#pod Interpolate variables into a template string, returning the
#pod resultant string.  The template string is scanned for tokens of the
#pod form
#pod
#pod     $VAR
#pod     ${VAR}
#pod
#pod where C<VAR> is composed of one or more word characters (as defined by
#pod the C<\w> Perl regular expression pattern). C<VAR> is resolved using
#pod the optional C<$vars> argument, which may either by a hashref (in
#pod which case C<VAR> must be a key), or a function reference (which is
#pod passed C<VAR> as its only argument and must return the value).
#pod
#pod If the value returned for C<VAR> is defined, it will be interpolated
#pod into the string at that point.  By default, variables which are not
#pod defined are by default left as is in the string.
#pod
#pod The C<%opts> parameter may be used to modify the behavior of this
#pod function.  The following (case insensitive) keys are recognized:
#pod
#pod =over
#pod
#pod =item format I<boolean>
#pod
#pod If this flag is true, the template string may provide a C<sprintf>
#pod compatible format which will be used to generate the interpolated
#pod value.  The format should be appended to the variable name with
#pod an intervening C<:> character, e.g.
#pod
#pod     ${VAR:fmt}
#pod
#pod For example,
#pod
#pod     %var = ( foo => 3 );
#pod     print strinterp( '${foo:%03d}', \%var, { format => 1 } );
#pod
#pod would result in
#pod
#pod     003
#pod
#pod
#pod =item raiseundef I<boolean>
#pod
#pod If true, a variable which has not been defined will result in an
#pod exception being raised.  This defaults to false.
#pod
#pod =item emptyundef I<boolean>
#pod
#pod If true, a variable which has not been defined will be replaced with
#pod the empty string.  This defaults to false.
#pod
#pod =item useENV I<boolean>
#pod
#pod If true, the C<%ENV> hash will be searched for variables which are not
#pod defined in the passed C<%var> hash.  This defaults to true.
#pod
#pod =item recurse I<boolean>
#pod
#pod If true, derived values are themselves scanned for variables to
#pod interpolate.  To specify a limit to the number of levels of recursions
#pod to attempt, set the C<recurse_limit> option.  Circular dependencies
#pod are caught, but just to be safe there's a limit of recursion levels
#pod specified by C<recurse_fail_limit>, beyond which an exception is
#pod thrown.
#pod
#pod For example,
#pod
#pod   my %var = ( a => '$b', b => '$c', c => 'd' );
#pod   strinterp( '$a', \%var ) => '$b'
#pod   strinterp( '$a', \%var, { recurse => 1 } ) => 'd'
#pod   strinterp( '$a', \%var, { recurse => 1, recurse_limit => 1 } ) => '$c'
#pod
#pod   strinterp( '$a', { a => '$b', b => '$a' } , { recurse => 1 }
#pod         recursive interpolation loop detected with repeated
#pod         interpolation of $a
#pod
#pod =item recurse_limit I<integer>
#pod
#pod The number of recursion levels to descend when recursing into a
#pod variable's value before stopping.  The default is C<0>, which means no
#pod limit.
#pod
#pod =item recurse_fail_limit I<integer>
#pod
#pod The number of recursion levels to descend when recursing into a
#pod variable's value before giving up and croaking.  The default is C<100>.
#pod Setting this to C<0> means no limit.
#pod
#pod =item variable_re I<regular expression>
#pod
#pod This specifies the regular expression (created with the C<qr>
#pod operator) which will match a variable name.  It defaults to
#pod C<qr/\w+/>. Don't use C<:>, C<{>, or C<}> in the regex, or things may
#pod break.
#pod
#pod =back
#pod
#pod =back
#pod
#pod
#pod =head1 DIAGNOSTICS
#pod
#pod =over
#pod
#pod =item C<< undefined variable: %s >>
#pod
#pod This string is thrown if the C<RaiseUndef> option is set and the
#pod variable C<%s> is not defined.
#pod
#pod =item C<< recursive interpolation loop detected with repeated interpolation of <%s> >>
#pod
#pod When resolving nested interpolated values (with the C<recurse> option
#pod true ) a circular loop was found.
#pod
#pod =item C<< recursion fail-safe limit (%d) reached at interpolation of <%s> >>
#pod
#pod The recursion fail safe limit (C<recurse_fail_limit>) was reached while
#pod interpolating nested variable values (with the C<recurse> option true ).
#pod
#pod =back
#pod

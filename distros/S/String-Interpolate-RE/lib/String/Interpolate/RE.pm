# --8<--8<--8<--8<--
#
# Copyright (C) 2007, 2014 Smithsonian Astrophysical Observatory
#
# This file is part of String::Interpolate::RE
#
# String::Interpolate::RE is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package String::Interpolate::RE;

use strict;
use warnings;
use Carp;

use Exporter qw[ import ];
our @EXPORT_OK = qw( strinterp );

our $VERSION = '0.05';

## no critic (ProhibitAccessOfPrivateData)

sub strinterp {

    my ( $text, $var, $opts ) = @_;

    $var = {} unless defined $var;

    my %opt = (
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

    $_[0] =~ s{
	       \$                # find a literal dollar sign
	      (                  # followed by either
	       {(\w+)(?:$fmt)?}  #  a variable name in curly brackets ($2)
				 #  and an optional sprintf format
	       |                 # or
		(\w+)            #   a bareword ($3)
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

__END__

=head1 NAME

String::Interpolate::RE - interpolate variables into strings


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

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-string-interpolate-re@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Interpolate-RE>.

=head1 SEE ALSO

Other CPAN Modules which interpolate into strings are
L<String::Interpolate> and L<Interpolate>.  This module avoids the use
of B<eval()> and presents a simpler interface.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, 2014 The Smithsonian Astrophysical Observatory

String::Interpolate::RE is free software: you can redistribute
it and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>



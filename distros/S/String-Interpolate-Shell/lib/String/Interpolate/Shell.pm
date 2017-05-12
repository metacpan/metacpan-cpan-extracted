# --8<--8<--8<--8<--
#
# Copyright (C) 2011 Smithsonian Astrophysical Observatory
#
# This file is part of String-Interpolate-Shell
#
# String-Interpolate-Shell is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
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

package String::Interpolate::Shell;

use strict;
use warnings;

use Text::Balanced qw[ extract_bracketed extract_multiple extract_quotelike];
use Params::Check qw[ check ];
use Carp;

use base 'Exporter';

our @EXPORT_OK = qw[ strinterp ];

our $VERSION = 0.01;

sub _extract {

    extract_multiple( $_[0],
		      [
		       qr/\s+/,
		       qr/\\(\\)/,
		       qr/\\(\$)/,
		       { V => qr/\$(\w+)/ },
		       { B => sub { (extract_bracketed( $_[0], '{}', qr/\$/ ))[0] } },
		      ] );
}

sub _handle_undef {

    my ( $var, $q, $attr, $rep ) = @_;

    ## no critic(ProhibitAccessOfPrivateData)

    return $var->{$q} if defined $var->{$q};

    carp( sprintf( $attr->{undef_message}, $rep) )
      if $attr->{undef_verbosity} eq 'warn';

    croak( sprintf( $attr->{undef_message}, $rep) )
      if $attr->{undef_verbosity} eq 'fatal';

    return $rep if $attr->{undef_value} eq 'ignore';
}

sub strinterp{

    my ( $text, $var, $attr ) = @_;

    ## no critic(ProhibitAccessOfPrivateData)
    $attr = check( {
		    undef_value => { allow => [ qw[ ignore remove ] ],
				     default => 'ignore' },
		    undef_verbosity => { allow => [ qw[ silent warn fatal ] ],
					 default => 'silent' },
		    undef_message => { default => "undefined variable: %s\n" },
		    }, $attr || {} )
      or croak( "error parsing arguments: ", Params::Check::last_error() );

    my @matches;

    for my $matchstr ( _extract($text ) ) {

	my $ref = ref $matchstr;

	if ( 'B' eq $ref ) {

	    # remove enclosing brackets
	    my $match = substr( $$matchstr, 1,-1 );

	    # see if there's a 'shell' modifier expression
	    my ( $ind, $q, $modf, $rest ) = $match =~ /^(!)?(\w+)(:[-?=+~:])?(.*)/;

	    # if there's no modifier but there is trailing cruft, it's an error
	    die( "unrecognizeable variable name: \${$match}\n")
		if ! defined $modf && $rest ne '';

	    # if indirect flag is set, expand variable
	    if ( defined $ind ) {

		if ( defined $var->{$q} ) {
		    $q = $var->{$q};
		}
		else
		{
		    push @matches, _handle_undef( $attr, '$' . $$matchstr );
		    next;
		}
	    }


	    if ( ! defined $modf ) {

		push @matches, _handle_undef( $var, $q, $attr, '$' . $$matchstr );
	    }

	    elsif ( ':?' eq $modf ) {

		local $attr->{undef_verbosity} = 'fatal';
		local $attr->{undef_message} = $rest;

		push @matches, _handle_undef( $var, $q, $attr, '$' . $$matchstr );

	    }
	    elsif ( ':-' eq $modf ) {

		push @matches, defined $var->{$q} ? $var->{$q} : strinterp( $rest, $var, $attr );

	    }

	    elsif ( ':=' eq $modf ) {


		$var->{$q} = strinterp( $rest, $var, $attr )
		  unless defined $var->{$q};
		push @matches, $var->{$q};

	    }

	    elsif ( ':+' eq $modf ) {

		push @matches, strinterp( $rest, $var, $attr )
		  if defined $var->{$q};

	    }

	    elsif ( '::' eq $modf ) {

		push @matches, sprintf( $rest,  _handle_undef( $var, $q, $attr, '$' . $$matchstr ) );

	    }

	    elsif ( ':~' eq $modf ) {

		my ( $expr, $xtra, $op ) = (extract_quotelike( $rest ))[0,1,3];
		die( "unable to parse variable substitution command: $rest\n" )
		    if $xtra !~ /^\s*$/ or $op !~ /^(s|tr|y)$/;

		my $t = $var->{$q};
		## no critic(ProhibitStringyEval)
		eval "\$t =~ $expr";
		die $@ if $@;

		push @matches, $t;

	    }

	    else { die( "internal error" ) }

	}
	elsif ( 'V' eq $ref ) {

	    my $q = $$matchstr;

	    push @matches, _handle_undef( $var, $q, $attr, "\$$q" );

	}

	elsif ( $ref ) {

	    push @matches, $$matchstr;

	}
	else {

	    push @matches, $matchstr;

	}


    }

    return join('', @matches);

}

1;

__END__

=head1 NAME

String::Interpolate::Shell -- Variable interpolation, shell style

=head1 SYNOPSIS

  use String::Interpolate::Shell qw[ strinterp ];

  $interpolated_text = strinterp( $text, \%var, \%attr );

=head1 DESCRIPTION

B<String::Interpolate::Shell> interpolates variables into strings.
Variables are specified using a syntax similar to that use by B<bash>.
Undefined variables can be silently ignored, removed from the string,
can cause warnings to be issued or errors to be thrown.

=over

=item $I<varname>

Insert the value of the variable.


=item ${I<varname>}

Insert the value of the variable.

=item ${I<varname>:?error message}

Insert the value of the variable.  If it is not defined,
the routine croaks with the specified message.

=item ${I<varname>:-I<default text>}

Insert the value of the variable.  If it is not defined,
process the specified default text for any variable interpolations and
insert the result.

=item ${I<varname>:+I<default text>}

If the variable is defined, insert the result of interpolating
any variables into the default text.

=item ${I<varname>:=I<default text>}

Insert the value of the variable.  If it is not defined,
insert the result of interpolating any variables into the default text
and set the variable to the same value.


=item ${I<varname>::I<format>}

Insert the value of the variable as formatted according to the
specified B<sprintf> compatible format.

=item ${I<varname>:~I<op>/I<pattern>/I<replacement>/msixpogce}

Insert the modified value of the variable.  The modification is
specified by I<op>, which may be any of C<s>, C<tr>, or C<y>,
corresponding to the Perl operators of the same name. Delimiters for
the modification may be any of those recognized by Perl.  The
modification is performed using a Perl string B<eval>.

=back

In any of the bracketed forms, if the variable name is preceded with an exclamation mark (C<!>)
the name of the variable to be interpreted is taken from the value of the specified variable.


=head1 FUNCTIONS

=over

=item strinterp

  $interpolated_text = strinterp( $template, \%var, \%attr );

Return a string containing a copy of C<$template> with variables interpolated.

C<%var> contains the variable names and values.

C<%attr> may contain the following entries:

=over

=item undef_value

This indicates how undefined variables should be interpolated

=over

=item C<ignore>

Ignore them.  The token in C<$text> is left as is.

=item C<remove>

Remove the token from C<$text>.

=back

=item undef_verbosity

This indicates how undefined variables should be reported.

=over

=item C<silent>

No message is returned.

=item C<warn>

A message is output via C<carp()>.

=item C<fatal>

A message is output via C<croak()>.

=back



=back

=back

=head1 SEE ALSO

L<String::Interpolate>, L<String::Interpolate::RE>, L<String::Expand>, L<String::MatchInterpolate>.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Smithsonian Astrophysical Observatory

This is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


=head1 AUTHOR

Diab Jerius

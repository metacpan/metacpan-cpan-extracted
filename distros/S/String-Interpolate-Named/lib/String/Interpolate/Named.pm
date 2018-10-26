#! perl

package String::Interpolate::Named;

use warnings;
use strict;
use utf8;
use Carp qw( carp croak );

use parent 'Exporter';
our @EXPORT = qw( interpolate );

=head1 NAME

String::Interpolate::Named - Interpolated named arguments in string

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use String::Interpolate::Named;

    my $ctl = { args => { fn => "Johan", ln => "Bach" } };
    say interpolate( $ctl, "The famous %{fn} %{ln}." );

=head1 DESCRIPTION

String::Interpolate::Named exports a single function, C<interpolate>, that
takes a string and substitutes named I<variables> by I<target texts>.

The subroutine takes two arguments: a reference to a control hash and
the string.

The arguments to be replaced are marked in the string by enclosing
them between C<%{> and C<}>. For example, the string C<"The famous
%{fn} %{ln}."> contains two named arguments, C<fn> and C<ln>.

In its basic form, the C<%{var}> is replaced by the value of the key
C<var> in the C<args> element of the control hash. It is also possible
to specify replacement values depending on whether C<var> has a
value or not:

    "This book has %{title|title %{title}}"
    "This book has %{title|title %{title}|no title}"

Assuming argument C<title> has the value C<"My Book">, in the first
example the text C<"title My Book"> will be substituted. If C<title>
does not have a value, the empty string is substituted.

In the second example, the string C<"no title"> will be substituted.

As can be seen, the replacement texts may contain interpolations as
well. For convenience, you can use C<%{}> to refer to the value of the
named variable currently being examinated. The last example above can
be written more shortly and elegantly as:

    "This book has %{title|title %{}|no title}"

You can test for specific values:

    "This takes %{days=1|%{} day|%{} days}"

Finally, the values as specified in the control hash may be scalar (in
general: strings and numbers) or lists of scalars. If a value is a
list of scalars, it is possible to select a value from the list by
appending a period and a number to the key. Assume C<customer> has
value C<[ "Jones", "Smith" ]>, then:

    "%{customer.1} will be Smith"
    "%{customer.2} will be Jones"
    "%{customer} will be Jones Smith"

The control hash contains the values for the variables in C<"args">:

    { args => { customer => [ "Jones", "Smith" ],
                days => 2, ... },
    }

When list values need to be concatenated, a separator may be
specified:

    { args => { customer => [ "Jones", "Smith" ],
                days => 2, ... },
      separator => ", ",
    }

The separator defaults to perl variable C<$">, which defaults to a
single space.

=cut

sub interpolate {
    my ( $ctl, $tpl ) = @_;

    for ( my $cnt = 0; ; $cnt++ ) {

	my $prev = $tpl;

	# Hide escaped specials by replacing them with Unicode noncharacters.
	$tpl =~ s/\\\\/\x{fdd0}/g;
	$tpl =~ s/\\\{/\x{fdd1}/g;
	$tpl =~ s/\\\}/\x{fdd2}/g;
	$tpl =~ s/\\\|/\x{fdd3}/g;

	# Replace some seqs by a single char for easy matching.
	$tpl =~ s/\%\{\}/\x{fdd4}/g;
	$tpl =~ s/\%\{/\x{fdd5}/g;

	# %{ key [ .index ] [ = value ] [ | then [ | else ] ] }

	$tpl =~ s; ( \x{fdd5}
		     (?<key>\w+[-_\w.]*)
		     (?: (?<op> \= )
			 (?<test> [^|}\x{fdd5}]*) )?
		     (?: \| (?<then> [^|}\x{fdd5}]*  )
			 (?: \| (?<else> [^|}\x{fdd5}]* ) )?
		     )?
		     \}
		   )
		 ; _interpolate($ctl, {%+} ) ;exo;

	# Unescape escaped specials.
	$tpl =~ s/\x{fdd0}/\\/g;
	$tpl =~ s/\x{fdd1}/\\{/g;
	$tpl =~ s/\x{fdd2}/\\}/g;
	$tpl =~ s/\x{fdd3}/\\|/g;

	# Restore (some) seqs.
	$tpl =~ s/\x{fdd4}/%{}/g;
	$tpl =~ s/\x{fdd5}/%{/g;

	last if $prev eq $tpl;
	# warn("$cnt: $prev -> $tpl\n");
    }

    $tpl;
}

sub _interpolate {
    my ( $ctl, $i ) = @_;
    my $key = $i->{key} // '';
    my $m = $ctl->{args};

    # Establish the value for this key.
    my $val = '';
    my $inx = 0;

    # Split off possible index.
    if ( $key =~ /^(.*)\.(-?\d+)$/ ) {
	( $key, $inx ) = ( $1, $2 );
    }

    if ( defined $m->{$key} ) {
	$val = $m->{$key};

	if ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
	    # 1, 2, ... selects 1st, 2nd value; -1 counts from end.
	    if ( $inx ) {
		if ( $inx > 0 && $inx <= @$val ) {
		    $val = $val->[$inx-1];
		}
		else {
		    $val = $val->[$inx];
		}
	    }
	    # Zero or none means concatenate all.
	    else {
		$val = join( $ctl->{separator} // $", @$val );
	    }
	}
	elsif ( $inx ) {
	    Carp::croak("Expecting an array for variable '$key'")
	}
    }

    my $subst = '';
    if ( $i->{op} ) {
	my $test = $i->{test} // '';
	if ( $i->{op} eq '=' && $val eq $test ) {
	    $subst = $i->{then} // '';
	}
	else {
	    $subst = $i->{else} // '';
	}
    }
    elsif ( $val ne '' ) {
	$subst = $i->{then} ? $i->{then} : $i->{else} ? '' : $val;
    }
    else {
	$subst = $i->{else} ? $i->{else} : '';
    }

    $subst =~ s/\x{fdd4}/$val/g;
    return $subst;
}


=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>


=head1 SUPPORT

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-String-Interpolate-Named.

You can find documentation for this module with the perldoc command.

    perldoc String::Interpolate::Named

Please report any bugs or feature requests using the issue tracker on
GitHub.


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2018 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of String::Interpolate::Named

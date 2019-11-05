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

our $VERSION = '1.00';

=head1 SYNOPSIS

    use String::Interpolate::Named;

    my $ctl = { args => { fn => "Johan", ln => "Bach" } };
    say interpolate( $ctl, "The famous %{fn} %{ln}." );

    # If you like object orientation.
    my $int = String::Interpolate::Named->new( { args => { ... } } );
    say $int->interpolate("The famous %{fn} %{ln}.");

=head1 DESCRIPTION

String::Interpolate::Named provides a function to interpolate named
I<arguments> by I<target texts> in a template string. The target texts
are provided to the function via a hash, where the keys correspond to
the named argument to be replaced.

=head2 Named Arguments

The arguments to be replaced are marked in the template by enclosing
them between C<%{> and C<}>. For example, the string C<"The famous
%{fn} %{ln}."> contains two named arguments, C<fn> and C<ln>.

=head2 Basic Interpolation

When interpolated, the keys C<fn> and C<ln> are looked up in the hash,
and the corresponding values are substituted. If no value was found
for a named argument, nothing is substituted and the C<%{...}> is
removed.

You can precede C<%>, C<{>, C<}> (and C<|>, see below) with a
backslash C<\> to hide their special meanings. For example, C<\}> will
I<not> be considered closing an argument but yield a plain C<}> in the
text.

=head2 Conditional Interpolation

It is possible to select replacement values depending on whether
the named argument has a value or not:

    "This book has %{title|title %{title}}"
    "This book has %{title|title %{title}|no title}"

These are considered C<%{if|then}> and C<%{if|then|else}> cases.

Assuming argument C<title> has the value C<"My Book">, in the first
example the text C<"title My Book">, the 'then' text, will be
substituted, resulting in

    "This book has title My Title"

If C<title> does not have a value, the empty string is substituted. In
the second example, the string C<"no title">, the 'else' text, will be
substituted.

As can be seen, the replacement texts may contain interpolations as
well. For convenience, you can use C<%{}> to refer to the value of the
named argument currently being examinated. The last example above can
be written more shortly and elegantly as:

    "This book has %{title|title %{}|no title}"

=head2 Testing Values

Instead of testing for named variables to have a value, you can also
test for specific values:

    "This takes %{days=1|%{} day|%{} days}"

=head2 List Values

The replacement values hash may be scalar (in general: strings and
numbers) or lists of scalars. If a value is a list of scalars, it is
possible to select a particular value from the list by appending an
index (period and a number) to the named argument.

Assume C<customer> has value C<[ "Jones", "Smith" ]>, then:

    "%{customer.1} will be Smith"
    "%{customer.2} will be Jones"
    "%{customer} will be Jones Smith"

When no element is selected the values are concatenated.

=head2 The Control Hash

The interpolation process requires two parameters: a hash with
settings and values for the named arguments, and the string to be used
as a template for interpolation. The hash will be further referred to
as the I<control hash>.

The hash can have the following keys:

=over

=item vars

This is the hash that contains replacement texts for the named variables.

This element should be considered mandatory.

=item separator

The separator used to concatenate list values, see L<List Values> above.

It defaults to Perl variable C<$"> that, on its turn, defaults to a
single space.

=item maxiter

To enable nested substitutions and recursive replacement, the
interpolation process is repeated until there are no more
interpolations to be made. The maximun number of iterations is limited
to the value of C<maxiter>.

By default maxiter is 16.

=back

An example of a control hash:

    my %ctl =
      ( args => {
          customer => [ "Jones", "Smith" ],
          days     => 2,
          title    => "My Title",
        },
        separator => ", ",
      );

=head2 Object Oriented API

    my $ii = String::Interpolate::Named->new;
    $ii->ctl(\%ctl);
    $result = $ii->interpolate($template);

For convenience, the control hash may be passed to the constructor:

    my $ii = String::Interpolate::Named->new(\%ctl);
    $result = $ii->interpolate($template);

=head2 Functional API

String::Interpolate::Named privides a single function, C<interpolate>,
which is exported by default.

The subroutine takes two arguments: a reference to a control hash and
the template string.

   $result = interpolate( \%ctl, $template );

=cut

=head1 METHODS

=head2 new

Constructs a new String::Interpolate::Named object.

    my $ii = String::Interpolate::Named->new;

or

    my $ii = String::Interpolate::Named->new(\%ctl);

=cut

sub new {
    my ( $pkg, $ctl ) = @_;
    $ctl //= {};
    bless $ctl => $pkg;
}

=head2 ctl

Associates a control has with an existing object.

    $ii->ctl(\%ctl);

=cut

sub ctl {
    my ( $self, $ctl ) = @_;
    $self->{$_} = $ctl->{$_} for keys(%$ctl);
    return $self;
}

=head2 interpolate

This routine performs the actual interpolations. It can be used as a method:

    $ii->interpolate($template);

and functional:

    interpolate( \%ctl, $template );

=cut

sub interpolate {
    my ( $ctl, $tpl ) = @_;

    my $maxiter = $ctl->{maxiter} // 16;

    for ( my $cnt = 1; $cnt <= $maxiter; $cnt++ ) {

	my $prev = $tpl;

	# Hide escaped specials by replacing them with Unicode noncharacters.
	$tpl =~ s/\\\\/\x{fdd0}/g;
	$tpl =~ s/\\\{/\x{fdd1}/g;
	$tpl =~ s/\\\}/\x{fdd2}/g;
	$tpl =~ s/\\\|/\x{fdd3}/g;
	$tpl =~ s/\\\%/\x{fdd4}/g;

	# Replace some seqs by a single char for easy matching.
	$tpl =~ s/\%\{\}/\x{fdde}/g;
	$tpl =~ s/\%\{/\x{fddf}/g;

	# %{ key [ .index ] [ = value ] [ | then [ | else ] ] }

	$tpl =~ s; ( \x{fddf}
		     (?<key>\w+[-_\w.]*)
		     (?: (?<op> \= )
			 (?<test> [^|}\x{fddf}]*) )?
		     (?: \| (?<then> [^|}\x{fddf}]*  )
			 (?: \| (?<else> [^|}\x{fddf}]* ) )?
		     )?
		     \}
		   )
		 ; _interpolate($ctl, {%+} ) ;exo;

	# Unescape escaped specials.
	$tpl =~ s/\x{fdd0}/\\\\/g;
	$tpl =~ s/\x{fdd1}/\\\{/g;
	$tpl =~ s/\x{fdd2}/\\\}/g;
	$tpl =~ s/\x{fdd3}/\\\|/g;
	$tpl =~ s/\x{fdd4}/\\\%/g;

	# Restore (some) seqs.
	$tpl =~ s/\x{fdde}/%{}/g;
	$tpl =~ s/\x{fddf}/%{/g;

	if ( $prev eq $tpl ) {
	    $tpl =~ s/\\([%{}|])/$1/g;
	    return $tpl;
	}
	warn("$cnt: $prev -> $tpl\n") if $ctl->{trace};
    }
    Carp::croak("Maximum number of iterations exceeded");
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

    $subst =~ s/\x{fdde}/$val/g;
    return $subst;
}

=head1 REQUIREMENTS

Minimal Perl version 5.10.1.

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

Development of this module takes place on GitHub:
L<https://github.com/sciurius/perl-String-Interpolate-Named>.

You can find documentation for this module with the perldoc command.

    perldoc String::Interpolate::Named

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 ACKNOWLEDGEMENTS

Many of the existing template / interpolate / substitute modules.

=head1 COPYRIGHT & LICENSE

Copyright 2018,2019 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of String::Interpolate::Named

#! perl

package String::Interpolate::Named;

use warnings;
use strict;
use utf8;
use Carp qw( carp croak );

# Disable 'Unicode character 0xfddX is illegal' warnings.
no if $] < 5.014, q|warnings|, qw(utf8);

use parent 'Exporter';
our @EXPORT = qw( interpolate );

=head1 NAME

String::Interpolate::Named - Interpolated named arguments in string

=cut

our $VERSION = '1.06';

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
the named argument to be replaced, or a subroutine that performs the
lookup.

=head2 Named Arguments

The arguments to be replaced are marked in the template by enclosing
them between C<%{> and C<}>. For example, the string C<"The famous
%{fn} %{ln}."> contains two named arguments, C<fn> and C<ln>.

Note that the activator may be changed from C<%> into something else,
see below. Throughout this document we use the default value.

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

    "%{customer} will be Jones Smith"
    "%{customer.0} will be Jones Smith"
    "%{customer.1} will be Jones"
    "%{customer.2} will be Smith"

When the value exceeds the number of elements in the list, an empty
value is returned.
Index zero, or no index, will return all values concatenated.

=head2 Format modifiers

A named variable may have I<format modifiers> attached to perform
formatting operations on the substituted value.
Format modifiers start with a colon C<:>.

Assuming argument C<title> has the value C<"My Book">, then
C<"%{title:lc}">
will yield the title in lowercase C<"my book">.

The following format modifiers are available:

=over 6

=item C<:lc>

Yields the substituted value in all lower case.

Using the example above, this will be C<"my book">.

=item C<:uc>

Yields the substituted value in all upper case.

Using the example above, this will be C<"MY BOOK">.

=item C<:ic>

Yields the substituted value with initial caps, e.g. the first letter
of each word is capitalized.

Using the example above, this will be C<"My Book">.
Indeed, no difference since the value is already correctly cased.

To enforce lower case before applying initial case, use format modifiers
C<:lc:ic>.

=item C<:sc>

Yields the substituted value with an initial cap and the rest lower case.

Using the example above, this will be C<"My Book">.
Again, no difference since the value already has an initial capital.

To enforce lower case before applying initial case, use format modifiers
C<:lc:sc>. Now the result will be C<"My book">.

=item C<:lpad(>I<N>C<)>   C<:lpad(>I<N>C<,>I<S>C<)>

Pads the value by repeatedly prepending the string I<S> until the
total width is I<N>.

If I<S> is omitted, uses spaces.

=item C<:rpad(>I<N>C<)>   C<:rpad(>I<N>C<,>I<S>C<)>

Pads the value by repeatedly appending the string I<S> until the
total width is I<N>.

If I<S> is omitted, uses spaces.

=item C<:replace(>I<SRC>C<,>I<DST>C<)>

Replaces all occurrences of I<STR> by I<DST>,

If I<S> is omitted, uses spaces.

=item C<:%>I<fmt>

Apply standard printf() formatting, e.g. C<%{key:%03d}> yields the numeric
value of C<key> as a 3-digit string, adding leading zeroes if necessary.

=back

Note that, when combining formatting and conditional interpolation,
you must check for the I<formatted> value:

    "This takes %{days:%02d=01|%{} day|%{} days}"

You can prevent a colon from splitting formatters with a backslash:

     %{title:replace( ,\:)}

=head2 The Control Hash

The interpolation process requires two parameters: a hash with
settings and values for the named arguments, and the string to be used
as a template for interpolation. The hash will be further referred to
as the I<control hash>.

The hash can have the following keys:

=over

=item args

This is either a hash that contains replacement texts for the named
variables, or a subroutine that gets called with a variable as
argument and returns a replacement value.

This element should be considered mandatory.

=item separator

The separator used to concatenate list values, see L<List Values> above.

It defaults to Perl variable C<$"> that, on its turn, defaults to a
single space.

=item activator

This is a single character that activates interpolation. By default
this is the percent C<%> character.

=item keypattern

The pattern to match key names. Default is C<qr/\w+[-_\w.]*/>.

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
    my $activator = $ctl->{activator} // '%';
    my $keypat = $ctl->{keypattern} // qr/\w+[-_\w.]*/;

    for ( my $cnt = 1; $cnt <= $maxiter; $cnt++ ) {

	my $prev = $tpl;

	# Hide escaped specials by replacing them with Unicode noncharacters.
	$tpl =~ s/\\\\/\x{fdd0}/g;
	$tpl =~ s/\\\{/\x{fdd1}/g;
	$tpl =~ s/\\\}/\x{fdd2}/g;
	$tpl =~ s/\\\|/\x{fdd3}/g;
	$tpl =~ s/\\\Q$activator\E/\x{fdd4}/g;

	# Replace some seqs by a single char for easy matching.
	$tpl =~ s/\Q$activator\E\{\}/\x{fdde}/g;
	$tpl =~ s/\Q$activator\E\{/\x{fddf}/g;

	# %{ key [ .index ] [ = value ] [ | then [ | else ] ] }

	my $pre  = '';
	my $post = '';
	if ( $tpl =~ s; ( ^
		     (?<pre> .*? )
		     \x{fddf}
		     (?<key> $keypat )
		     (?: : (?<fmt> .*? ) )?
		     (?: (?<op> \= )
			 (?<test> [^|}\x{fddf}]*) )?
		     (?: \| (?<then> [^|}\x{fddf}]*  )
			 (?: \| (?<else> [^|}\x{fddf}]* ) )?
		     )?
		     \}
		     (?<post> .* )
		     $
		   )
		      ; _interpolate($ctl, {%+} ) ;exso ) {
	    $pre  = $+{pre};
	    $post = $+{post};
	}
	else {
	    $pre = $tpl;
	    $tpl = '';
	}
	for ( $pre, $tpl, $post ) {
	    # Unescape escaped specials.
	    s/\x{fdd0}/\\\\/g;
	    s/\x{fdd1}/\\\{/g;
	    s/\x{fdd2}/\\\}/g;
	    s/\x{fdd3}/\\\|/g;
	    s/\x{fdd4}/\\$activator/g;

	    # Restore (some) seqs.
	    s/\x{fdde}/$activator."{}"/ge;
	    s/\x{fddf}/$activator."{"/ge;
	}
	$tpl =~ s/\\(\Q$activator\E|[{}|\\])/$1/g;
	warn ("'$prev' => '$pre' '$tpl' '$post'\n" ) if $ctl->{trace};

	my $t = $pre . $tpl . $post;
	if ( $prev eq $t ) {
	    # De-escape in subst part only (issue #6);
	    $tpl =~ s/\\(\Q$activator\E|[{}|])/$1/g;
	    return $pre . $tpl . $post;
	}
	$tpl = $t;
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

    my $newval = ref($m) eq 'CODE' ? $m->($key) : $m->{$key};
    if ( defined $newval ) {
	$val = $newval;

	if ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
	    # 1, 2, ... selects 1st, 2nd value; -1 counts from end.
	    if ( $inx ) {
		if ( $inx > 0 ) {
		    if ( $inx <= @$val ) {
			$val = $val->[$inx-1];
		    }
		    else {
			$val = "";
		    }
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
    for ( split( /(?<!\\):/, $i->{fmt}//'' ) ) {
	last unless defined $newval;
	next unless my $fmt = $_;

	# Simple formatters.
	if    ( $fmt eq 'lc' ) { $val = lc($val) }
	elsif ( $fmt eq 'uc' ) { $val = uc($val) }
	elsif ( $fmt eq 'sc' ) { $val = ucfirst($val) }
	elsif ( $fmt eq 'ic' ) { $val = f_ic($val) }

	# Functions.
	elsif ( $fmt =~ /^([lr])pad\((\d+)(?:,(.*?))?\)$/ ) {
	    $val = f_pad( $val, $1, $2, $3 );
	}

	elsif ( $fmt =~ /^replace\((.+?),(.*?)\)$/ ) {
	    $val = f_replace( $val, $1, $2 );
	}

	# Printf formatting.
	elsif ( $fmt =~ /^%/ ) { $val = f_printf( $val, $fmt ) }

	else { Carp::croak("Invalid format code '$fmt'"); }
    }
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
	$subst = $i->{then} // $val;
    }
    else {
	$subst = $i->{else} // '';
    }

    $subst =~ s/\x{fdde}/$val/g;
    return $subst;
}

# Formatter functions.
# First arg = $val.
# Return new value.

sub f_ic {
    my ( $val ) = @_;
    join('', map { ucfirst } (split( /(^|\s+|-)/, $val )));
}

sub f_pad {
    my ( $val, $lr, $len, $str ) = @_;
    $str //= " ";
    return $val unless ( my $need = $len - length($val) ) > 0;
    my $pad = $str x (1+int(($len-1)/length($str)));
    if ( $lr eq 'l' ) {
	return substr( $pad, 0, $need ) . $val;
    }
    $val . substr( $pad, 0, $need );
}

sub f_replace {
    my ( $val, $rep, $str ) = @_;
    $val =~ s/\Q$rep\E/$str/g;
    $val;
}

sub f_printf {
    my ( $val, $fmt ) = @_;
    # A common problem is when a numeric format does not
    # have a value to format. Suppress the warning.
    no warnings qw(numeric);
    sprintf( $fmt, $val );
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

Copyright 2018,2025 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

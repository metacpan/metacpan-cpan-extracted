package Regexp::NamedCaptures;

use warnings;
use strict;

# $^N didn't appear in perlvar til then.
use 5.007_01;

use Text::Balanced qw( extract_bracketed extract_quotelike );
use Carp qw( croak carp );

# Attempt to load a real Params::Validate or just create a fake one if
# the user doesn't have one.`
BEGIN {
    eval {
        require Params::Validate;
        Params::Validate->import( 'validate_pos', 'SCALAR', 'UNDEF',
            'CODEREF' );
    };

    if ($@) {
        eval(     'sub validate_pos (\@@) { @{$_[0]} }'
                . 'sub SCALAR () { 0 }'
                . 'sub UNDEF () { 0 }'
                . 'sub CODEREF () { 0 }' );
    }
}

# Predeclare these so I can call them without needing parentheses and
# so perl will help me notice if I've mispelled them at *compile*
# time.
sub convert;
sub _convert_foo_expr;
sub _convert_chevron_expr;
sub _convert_quote_expr;

=head1 NAME

Regexp::NamedCaptures - Saves capture results to your own variables

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

 use Regexp::NamedCaptures;
 my ( $name, $title, $first, $last );
 /(?<\$name>(?<\$title>Mr\.|Ms\.) (?<\$first>\w+) (?<\$last>\w+))/;
 
 # is the same as
 
 my ( $name, $title, $first, $last )
     = /((Mr\.|Ms\.) (\w+) (\w+))/;

 # use re 'eval' when interpolating
 use Regexp::NamedCaptures;
 use re 'eval';
 /(?<\$something>$pattern)/


=head1 DESCRIPTION

This B<highly experimental> module implements named captures for
perl-5.008. Perl-5.10+ has built-in named captures and you should not
attempt to use this module.

When your regular expression captures something, you can have it
automatically copied out to the right location. This is an improvement
over normal perl because now you don't have to deal with positional
captures. When your expression is complex and there are multiple or
nested captures it really helps to not have to track what number
you're supposed to find your data in.

=head1 NAMED CAPTURE SYNTAX

I have borrowed the syntax from .Net. I'm told that each of the
following forms are equivalent so I've treated them identically.

 (?< name >pattern)
 (?' name 'pattern)

C<name> should be a a piece of valid perl code. In a normal,
interpolating regular expression, you would write
C<(?<\$something>...) if you wanted to have the result copied to the
C<$something> variable. That is, perl will interpolate your variables
just like it always does.

The value of name may be arbitrary perl code. It must be a valid
lvalue.

C<pattern> is a normal pattern.

The entire expression is rewritten as:

 (pattern)(?{ name = $^N })

=head1 FUNCTIONS

=head2 $rewritten_regexp = convert( $original_regexp )

This function does all the work of converting a regular expression
containing named capture expressions into an expression that can be
used by perl. You only need this if you're going to be creating
regular expressions at runtime.

 use re 'eval';
 $re = Regexp::NamedCapture::convert '(?<$var>...)'
 $re = qr/$re/

 use re 'eval';
 $re = Regexp::NamedCapture::convert "(?'\$var'...)";

=cut

sub convert {
    my ($in) = validate_pos( @_, { type => SCALAR | UNDEF } );

    if ( not defined $in ) {
        $in = '';
        carp "Use of uninitialized value in regexp compilation";
    }

    my @targets;
    my $out = '';
    while ( length $in ) {

        # Seek $in forward until a (?< or (?' is found. Be sure to
        # exclude (?<! and (?<= because they are normal regexp
        # patterns.
        if ( $in !~ /\((?:(?=\?<[^!=])|(?=\?\'))/ ) {

            # Nothing was found - copy the rest of $in to $out and
            # empty $in.
            $out .= $in;
            $in = '';
        }
        else {

            # Copy any leading text directly to the output.
            $out .= substr $in, 0, $-[0], '';

            my $expr;
            ( $expr, $in ) = extract_bracketed $in, '()';

            my $target;
            ( $target, $expr ) = (
                  '(?<' eq substr( $expr, 0, 3 ) ? _convert_chevron_expr $expr
                : '(?\'' eq substr( $expr, 0, 3 ) ? _convert_quote_expr $expr
                : croak "Invalid escape sequence in $expr."
            );
            $out .= $expr;

            push @targets, $target;
        }
    }

    if (@targets) {

        # Prepend target clearing code.
        $out = "(?{" . join( '=', @targets ) . "=undef})$out";
    }
    return $out;
}

=head1 C<use re 'eval'> AND SECURITY

This module functions by inserting (?{ code }) blocks into your
expression. As a security feature, perl does not allow new (?{ ... })
blocks to be compiled once BEGIN-time has passed unless the programmer
specifically lifts that restriction by including the C<use re 'eval'>
pragma.

If you trust all of the expressions that you're interpolating, you can
use this safely. If you are accepting regular expressions from sources
you might not trust, you should not use C<use re 'eval'>.

If you still want to use this module, see if you can push your regular
expression compilation earlier.

Consider these two examples:

 use re 'eval';
 $rx = qr/(?<\$name>$expr)/;

 BEGIN {
     $rx = qr/(?<\$name>$expr)/;
 }

The first one requires the C<use re 'eval'> pragma because the
interpolation and compilation occurs at runtime. The second does not
because it interpolated and compiled the pattern at BEGIN-time. It
suffers the obvious drawback that you must have the value for $expr at
BEGIN-time instead of runtime.

=head1 AUTHOR

"Joshua ben Jore" <jjore@cpan.org>

=head1 BUGS

\Q escapes are completed ignored. If you try to use one to prevent
something that looks like a named capture from being parsed as one, it
won't work.

Please report any bugs or feature requests to
C<bug-regexp-namedcaptures@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-NamedCaptures>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Jeffrey Friedl's book Mastering Regular Expressions for the original inspiration.
perlre for making it possible.
Minneapolis.pm for giving me a reason to create this.
Tanktalus, Ctrl-z, and others of perlmonks.org

=head1 COPYRIGHT & LICENSE

Copyright 2005 Joshua ben Jore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub _convert_quote_expr {
    my ($re) = validate_pos(
        @_,
        {   type  => SCALAR,
            regex => qr<\A\(\?\'.+\'.*\)\z>s
        }
    );
    _convert_foo_expr sub {&extract_quotelike}, $re;
}

sub _convert_chevron_expr {
    my ($re) = validate_pos(
        @_,
        {   type  => SCALAR,
            regex => qr<\A\(\?\<.+\>.*\)\z>s
        }
    );
    _convert_foo_expr sub { extract_bracketed shift, '<>' }, $re;
}

sub _convert_foo_expr {
    my ( $extract, $in ) = validate_pos(
        @_,
        { type => CODEREF },
        {   type  => SCALAR,
            regex => qr<^\(\?..+..*\)$>s
        }
    );

    # Zap the (? and ) parts of (?...) away.
    substr $in, 0,  2, '';
    substr $in, -1, 1, '';

    # Split the _NAME_ part from the EXPR part of _NAME_EXPR
    my ( $name, $expr ) = $extract->($in);

    # Possibly transform the contents of $expr if it contained some
    # (?<...>...) expressions.
    $expr = convert $expr;

    # Zap the delimiters on _NAME_
    substr $name, 0,  1, '';
    substr $name, -1, 1, '';

    # Unescape stuff in $name
    $name =~ s/\\(.)/$1/gs;

    # Rewrite the expression so it's a plain capture followed by a
    # code block.
    return ( $name => "($expr)(?{$name=\$^N})" );
}

#####################################################################
#####################################################################

# Overload magic follows

use overload(
    '.'  => \&_concat,
    '""' => \&_finalize
);

sub import {

    # Constants are overloaded so their fragments are passed to
    # _postpone().
    overload::constant 'qr' => \&_postpone;
}

sub _postpone {

    # _postpone returns an object.
    my ($re) = @_;

    # If I was given an undef, pass the error back to the right
    # place. Without this, the user is going to get an error about an
    # undefined value in *my* code. Blech.
    if ( not defined $re ) {
        carp "Use of uninitialized value in regexp compilation";
        $re = '';
    }
    return bless \$re, __PACKAGE__;
}

sub _concat {

    # _concat happens anytime something is interpolated. It
    # re-postpones things until later.

    my ( $left, $right, $inverted ) = @_;
    ( $left, $right ) = ( $right, $left ) if $inverted;

    for my $tgt ( $left, $right ) {
        $tgt = $$tgt if ref($tgt) eq __PACKAGE__;

        # As in _postpone, I want to pass this warning off as my
        # caller's problem and not a problem with
        # Regexp::NamedCaptures.
        if ( not defined $tgt ) {
            carp "Use of uninitialized value in concatenation (.) or string";
            $tgt = '';
        }
    }

    my $re = "$left$right";
    return bless \$re, __PACKAGE__;
}

sub _finalize {

    # _finalize happens when the regex is due to be compiled. Here, I
    # just rethrow the regex to the user-accessible function
    # convert().

    return convert ${ $_[0] };
}

"Read more smut.";

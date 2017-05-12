package Test::Carp;

use strict;
use warnings;
use Carp;

$Test::Carp::VERSION = '0.2';

# Prototype mismatch: sub Test::Carp::_ok: none vs ($;$) at .../Test/Carp.pm line ...
# perl -MTest::More  -e 'print prototype("Test::More::ok");'
# sub _ok($;$) {
sub _ok {
    require Test::More;

    # no warnings 'redefine';
    # *_ok = \&Test::More::ok;    # make subsequent calls not do all of this ferdiddling
    goto &Test::More::ok;
}

sub import {
    my $caller = caller();

    use Data::Dumper;
    if ( ref( $_[1] ) eq 'CODE' ) {
        no warnings 'redefine';
        *_ok = $_[1];
    }

    no strict 'refs';
    for my $func (qw(
      does_carp               does_cluck
      does_croak              does_confess
      does_carp_that_matches  does_cluck_that_matches
      does_croak_that_matches does_confess_that_matches
      )) {
        *{ $caller . "::$func" } = *{$func};
      };
}

sub _does {
    my $caller = caller();
    my $func   = shift;
    my $code   = shift;

    no strict 'refs';
    my ( $carp_orig, $caller_orig ) = ( \&{"Carp::$func"}, \&{"${caller}::$func"} );

    no warnings 'redefine';
    my $called = 0;

    *{"Carp::$func"} = sub {
        return if $called++;
        _ok( 1, "$func() was called (@_)" );
        if ( $func eq 'croak' || $func eq 'confess' ) {
            local $Carp::CarpLevel = $Carp::CarpLevel + 2;
            $carp_orig->( $_[0] );
        }
    };
    *{"${caller}::$func"} = \&{"Carp::$func"};

    ( $func eq 'croak' || $func eq 'confess' ) ? eval { $code->(@_) } : $code->(@_);
    _ok( 0, "$func() was called" ) if !$called;

    *{"Carp::$func"}      = $carp_orig;
    *{"${caller}::$func"} = $caller_orig;
}

sub does_carp {
    unshift @_, 'carp';
    goto &_does;
}

sub does_cluck {
    unshift @_, 'cluck';
    goto &_does;
}

sub does_croak {
    unshift @_, 'croak';
    goto &_does;
}

sub does_confess {
    unshift @_, 'confess';
    goto &_does;
}

sub _does_and_matches {
    my $caller = caller();

    my $func  = shift;
    my $code  = shift;
    my $match = pop;

    no strict 'refs';
    my ( $carp_orig, $caller_orig ) = ( \&{"Carp::$func"}, \&{"${caller}::$func"} );

    no warnings 'redefine';
    my $called = 0;

    if ( !defined $match ) {
        $match = 'undef()';    # so you don't get "Use of uninitialized value" when used in the test name during
                               # t/02.functions.t oddity (look for 'to test that these are working we need to reverse ok()')
        *{"Carp::$func"} = sub {
            return if @_ && grep { defined $_ } @_;
            return if $called++;
            _ok( 1, "$func() was called w/ undefined argument" );
            if ( $func eq 'croak' || $func eq 'confess' ) {
                local $Carp::CarpLevel = $Carp::CarpLevel + 2;
                $carp_orig->();    # do not pass @_ or you get: Use of uninitialized value in join or string at .../Carp/Heavy.pm at line ...
            }
        };
    }
    elsif ( $match eq '' ) {
        *{"Carp::$func"} = sub {
            return if "@_" ne '';
            return if $called++;
            _ok( 1, "$func() was called w/ empty string argument" );
            if ( $func eq 'croak' || $func eq 'confess' ) {
                local $Carp::CarpLevel = $Carp::CarpLevel + 2;
                $carp_orig->(@_);
            }
        };
    }
    elsif ( ref($match) eq 'Regexp' ) {
        *{"Carp::$func"} = sub {
            return if "@_" !~ $match;
            return if $called++;
            _ok( 1, "$func() was called (w/ '@_') and matches '$match'" );
            if ( $func eq 'croak' || $func eq 'confess' ) {
                local $Carp::CarpLevel = $Carp::CarpLevel + 2;
                $carp_orig->(@_);
            }
        };
    }
    else {

        # On some odd setups qr() is not available
        if ( eval { $match = qr/$match/; ref($match) eq 'Regexp' ? 1 : 0 } ) {
            *{"Carp::$func"} = sub {
                return if "@_" !~ $match;
                return if $called++;
                _ok( 1, "$func() was called (w/ '@_') and matches '$match'" );
                if ( $func eq 'croak' || $func eq 'confess' ) {
                    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
                    $carp_orig->(@_);
                }
            };
        }
        else {
            $match = quotemeta($match);    # use this instead of \Q\E so that it will be escaped in the test label
            *{"Carp::$func"} = sub {
                return if "@_" !~ m/$match/;
                return if $called++;
                _ok( 1, "$func() was called (w/ '@_') and matches '$match'" );
                if ( $func eq 'croak' || $func eq 'confess' ) {
                    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
                    $carp_orig->(@_);
                }
            };
        }
    }
    *{"${caller}::$func"} = *{"Carp::$func"};

    ( $func eq 'croak' || $func eq 'confess' ) ? eval { $code->(@_) } : $code->(@_);
    _ok( 0, "$func() was called and matches '$match'" ) if !$called;

    *{"Carp::$func"}      = $carp_orig;
    *{"${caller}::$func"} = $caller_orig;
}

sub does_carp_that_matches {
    unshift @_, 'carp';
    goto &_does_and_matches;
}

sub does_cluck_that_matches {
    unshift @_, 'cluck';
    goto &_does_and_matches;
}

sub does_croak_that_matches {
    unshift @_, 'croak';
    goto &_does_and_matches;
}

sub does_confess_that_matches {
    unshift @_, 'confess';
    goto &_does_and_matches;
}

1;

__END__

=head1 NAME

Test::Carp - test your code for calls to Carp functions

=head1 VERSION

This document describes Test::Carp version 0.2

=head1 SYNOPSIS

    use Test::More tests => 42;
    use Test::Carp;
    
    ok($x eq $y, "X does equal Y");
    does_carp(\&function);
    does_croak(\&function, 1, 2, 3);
    does_carp_that_matches(\&function, qr/whoopsy/);
    does_croak_that_matches(\&function, 1, 2, 3, qr/a likely story/);

=head1 DESCRIPTION

Call given code (with given arguments) and tests whether the given Carp function (or their imported versions) are called (with a given value) or not.

=head1 INTERFACE 

All functions are put in the caller's name space during import(). If you'd rather use their full name space and not clutter up the current package with functions just:

  require Test::Carp;

or

  use Test::Carp ();

instead of 

  use Test::Carp;

=head2 being ok() w/ ok()

Internally, Test::Carp uses Test::More::ok() (require()ing in Test::More if needed) when it needs to use an ok() function.

If you want to specify a different one for it to use simply supply a coderef in the use statement.

   use Test::Carp \&Test::Foo::ok;

The function should take the same args as Test::More::ok() and probably behave the same as well.

=head2 carp()/cluck() functions

=over 4

=item does_carp()

Test whether the given code ref, when executed, calls carp().

Test fails if carp() is not called. There are 2 forms:

Without arguments to codreref:

   does_carp(sub {...});

With arge to coderef:

   does_carp(sub {...},"first arg to coderef", "second arg to coderef", ...);

=item does_carp_that_matches()

Test whether the given code ref, when executed, calls carp() with a specific message.

The test fails if carp() is not called with the given message. 

The last argument should be a string or Regexp ref (i.e. qr//) to match the message against.

There are 2 forms:

Without arguments passed to codreref:

   does_carp(sub {...}, $match_me)

With arguments passed to coderef:

   does_carp(sub {...},"first arg to coderef", "second arg to coderef", ..., $match_me);

=item does_cluck

Like does_carp() but for cluck()

=item does_cluck_that_matches

Like does_carp_that_matches() but for cluck()

=back

=head2 croak()/confess() functions

These functions stop running at the point it calls the [croak|cluck]() just like in normal code.

=over 4

=item does_croak()

Like does_carp() but for croak()

=item does_croak_that_matches()

Like does_carp_that_matches() but for croak()

=item does_confess()

Like does_carp() but for confess()

=item does_confess_that_matches()

Like does_carp_that_matches() but for confess()

=back

=head1 DIAGNOSTICS

Throws no warnings or errors of it's own.

=head1 CONFIGURATION AND ENVIRONMENT

Test::Carp requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Test::More> for ok() unless you define a different ok() for it to use.

It uses Carp in order to ensure carp and corak are defined before it does what it does.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-carp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Corresponding does_not_* functions. (v0.2)

TODOs in 02.functions.t (v0.2)

Maybe count and overall call info type functions, depending on demand ?

Determine [what needs done/if it should be done/etc] to make the test syntax not require a codref ?

Add mostly-internal Carp functions like (short|long)mess[_heavy](), etc ?

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

package Perl6ish::Syntax::DotMethod;
use strict;
use Sub::Uplevel;

require Acme::Dot;

sub import {
    uplevel 1, \&Acme::Dot::import;
}


1;

=head1 NAME

Perl6ish::Syntax::DotMethod - Allow methods to be invoked with dot.

=head1 SYNOPSIS

    package Cow;
    use Perl6ish::Syntax::DotMethod;

    sub new { bless {}, shift }

    sub sound { "moooo" };

    package main;
    my $animal = new Cow;

    # Cow methods can be invoked with dot.
    print "A cow goes " . $animal.sound();

=head1 DESCRIPTION

This syntax extension allows your instance methods to be invked with a
dot.  It is only supposed to be used when you're defining classes. It
does not turn all objects methods invokable with a dot.

It's not source-filtering, but operator overloading. Under the hood,
the real work is done in L<Acme::Dot>.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

L<Acme::Dot>

=cut


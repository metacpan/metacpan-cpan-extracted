#!perl -w

package ClassWithTestsAtTheEnd;

use strict;

=head1 NAME

B<ClassWithTestsAtTheEnd> - Demonstrating putting synopsis tests at
the end of an object class, L<perlmodlib>-style

=head1 SYNOPSIS

=for test "synopsis" begin

  my $foo = new ClassWithTestsAtTheEnd;

  $foo->zonk();

=for test "synopsis" end

=head1 DESCRIPTION

This is a dud class to demonstrate a particular use of
L<Pod::Snippets> that its author finds convenient (nay: way groovy
actually).

First we have some foo-ness so that we can pretend we are a real
package.

=cut

sub new { bless {}, shift }

sub zonk { "GLORPS" }

sub foo { "barracuda" }

=head1 TEST SUITE

The test suite is introduced by the "unless caller" mantra straight
from L<perlmodlib>.  "unless caller" means that the test suite won't
even be compiled if we have a caller, that is, the library is being
invoked with "use" or "require".  If one executes the library directly
(as in C<perl ClassWithTestsAtTheEnd.pm>), the test suite is fired up.

=cut

eval join('',<main::DATA>) || die $@ unless caller();

1;

__END__

=pod

We first put ourselves into a neutral package (eg "main") because the
name of the package you are in at the beginning of an eval "string" is
not consistent between Perl 5.6 and 5.8.

=cut

package main;

use strict;

=pod

Now we do some testing.

=cut

use Test::More tests => 3;

is(1 + 1, 2, "hooray, mathematics are still alive!");

like(ClassWithTestsAtTheEnd->foo(), qr/bar/,
     "your usual run-off-the-mill unit tests");

=pod

But we also want to test the synopsis, right? It's also source code,
right? Right.

=cut

use Pod::Snippets;

=pod

Lo and behold, the <main::DATA> pseudo-file descriptor is seekable!
This, people, is why I B<so> love Perl :-)

=cut

seek(DATA, 0, 0);

my $snips = Pod::Snippets->load(\*DATA, -filename => $0,
                                -markup => "test");

my $code_snippet = $snips->as_code("synopsis");

my $result = eval $code_snippet . "\$foo;\n"; die $@ if $@;

like($result->foo(), qr/bar/);

=head1 THAT'S ALL FOLKS!

I can has Kwalitee now?

=cut


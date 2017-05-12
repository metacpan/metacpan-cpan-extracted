#!/usr/bin/perl

use Test::More tests => 1;
use Pod::From::GoogleWiki;

my $wiki = <<'WIKI';
= Biggest heading =

*This is bold*, _this is italic_, `this is code` and so is {{{$obj->method}}}.

== Subheading ==

{{{
This is a block
of code
}}}

=== Smaller heading ===

  * A
  * List
  * Of
  * Stuff

==== Even smaller ====

  This is some
  literal quoted
  text

Here's a link to [http://www.microsoft.com] and here's one to [Test::More].
WIKI

my $pod = <<'POD';

=head1 Biggest heading

B<This is bold>, I<this is italic>, C<this is code> and so is C<<<$obj->method>>>.

=head2 Subheading

  This is a block
  of code


=head3 Smaller heading

  * A
  * List
  * Of
  * Stuff

=head4 Even smaller

  This is some
  literal quoted
  text

Here's a link to L<http://www.microsoft.com> and here's one to L<Test::More>.
POD

my $pfg = Pod::From::GoogleWiki->new();
my $ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'yup!');

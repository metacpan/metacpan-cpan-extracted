=pod

=encoding utf-8

=head1 PURPOSE

Test that Module::Notify compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use lib "t/lib";
use lib "lib";
use strict;
use warnings;
use Test::More tests => 3;

use_ok('Module::Notify');

my $str;
my $hook1 = Module::Notify->new(Foo  => sub { $str .= "hook1" });
my $hook2 = Module::Notify->new(Foo  => sub { $str .= "hook2" });
my $hook3 = Module::Notify->new(Foo2 => sub { $str .= "hook3" });

$hook1->cancel;

$str .= "before1";
require Foo;
$str .= "after1";

$str .= "before2";
eval { require Foo2 };
ok(defined $@, "got error loading Foo2");
$str .= "after2";

is($str, "before1hook2after1before2after2", "things happened in the correct sequence");


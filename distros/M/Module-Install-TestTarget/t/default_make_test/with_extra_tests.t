use strict;
use warnings;
use Test::Requires 'Module::Install::ExtraTests';

use Test::More;
use t::Util;

ok my $cmd = find_make_test_command(*DATA, 'test_dynamic'), 'find make test command';
like $cmd->{test_dynamic}, qr|-MFoo::Bar|, 'overwrote test_dynamic';

done_testing;

__DATA__
@@ Makefile.PL
use inc::Module::Install;

name 'MyModule';
all_from 'lib/MyModule.pm';

tests 't/*.t';

extra_tests;

default_test_target(
    load_modules => ['Foo::Bar'],
);

auto_include;
WriteAll;
@@ lib/MyModule.pm
package MyModule;
use 5.006;
our $VERSION = '0.1';
1;
__END__
=pod

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

@@ t/00_ok.t
use Test::More tests => 1;
pass;


@@ xt/author/00_xt_ok.t
use Test::More tests => 1;
pass;

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use t::Util;

ok my $cmd = find_make_test_command(*DATA, 'test_pp', 'testall', 'xxx'),
    'find make test command';
like $cmd->{test_pp}, qr|Foo::Bar|, 'find module';
ok exists $cmd->{testall}, 'eixsts testall';
ok exists $cmd->{xxx},     'exists xxx (alias_for_author)'
    or diag explain $cmd;
done_testing;

__DATA__
@@ Makefile.PL
use inc::Module::Install;

name 'MyModule';
all_from 'lib/MyModule.pm';

tests 't/*.t';

test_target test_pp => (
    alias            => 'testall',
    alias_for_author => 'xxx',
    load_modules     => 'Foo::Bar',
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

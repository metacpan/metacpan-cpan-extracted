use strict;
use warnings;
use lib 't/lib';

use Test::More;
use t::Util;

my $cmd = find_make_test_command(*DATA, 'extends_test');
ok $cmd, 'find make test command';
note 'extends_test: ', $cmd->{extends_test} || '';
like $cmd->{extends_test}, qr|t/foo.t|, 'find tests';
like $cmd->{extends_test}, qr|"t/foo.t"|, 'quoted correctly';
done_testing;

__DATA__
@@ Makefile.PL
use inc::Module::Install;

name 'MyModule';
all_from 'lib/MyModule.pm';

tests 't/*.t';

test_target extends_test => (
    tests => 't/foo.t',
);

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

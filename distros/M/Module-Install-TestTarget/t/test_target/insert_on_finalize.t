use strict;
use warnings;
use lib 't/lib';

use Test::More;
use t::Util;

ok my $cmd = find_make_test_command(*DATA, 'extends_test'), 'find make test command';
like $cmd->{extends_test}, qr|system.+cat.+Makefile\.PL|, 'find after run coderef';
if (DMAKE) {
    like $cmd->{extends_test}, qr|sub {{ print scalar localtime }}->\(\); |, 'find after run code';
    like $cmd->{extends_test}, qr|\$\$ENV{{__TEST__}} = 1|, 'find escaped sigil';
}
elsif (NMAKE) {
    like $cmd->{extends_test}, qr|sub { print scalar localtime }->\(\); |, 'find after run code';
    like $cmd->{extends_test}, qr|\$\$ENV{__TEST__} = 1|, 'find escaped sigil';
}
else {
    like $cmd->{extends_test}, qr|sub { print scalar localtime }->\(\); |, 'find after run code';
    like $cmd->{extends_test}, qr|\\\$\$ENV{__TEST__} = 1|, 'find escaped sigil';
}

done_testing;

__DATA__
@@ Makefile.PL
use inc::Module::Install;

name 'MyModule';
all_from 'lib/MyModule.pm';

tests 't/*.t';

test_target extends_test => (
    insert_on_finalize => [
        'print scalar localtime',
        sub { system qw/cat Makefile.PL/ },
        '$ENV{__TEST__} = 1',
    ],
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

use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;
use strict;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA, , file => "./t/data/dhcpd.conf");
is($config->parse, 3, 'Parsed 3 lines?');

my $include = $config->includes->[0];
is($include->parse, 1, 'Parsed 1 line in included file.');

my $include2 = $include->includes->[0];
like($include2->file, qr{foo-included.conf}, 'foo-included.conf got included');
is($include2->parse, 6, 'second included file got parsed');
is(scalar(@_=$include2->hosts), 1, 'included file contains one host');

my $cb = sub {
    my $file = shift;
    if ($file =~ /catphotos/) {
        return "foo-included.conf";
    }
};


$config->filename_callback($cb);
$config->includes->[1]->parse;

is($config->includes->[1]->file, 't/data/foo-included.conf', 'Can we change filenames?');
done_testing();

__DATA__
include "test-recursive-include.conf";

include "/path/to/where/my/catphotos/are.conf";

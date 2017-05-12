use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my $server_description;
    ok($server_description = $freedb->ver());
    ok($server_description =~ /cddbd v[^\s]+ Copyright \(c\) \d{4}-\d{4} Steve Scherf et al\./);
}

done_testing;

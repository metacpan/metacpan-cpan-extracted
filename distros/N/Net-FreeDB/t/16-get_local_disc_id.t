use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my $disc_id = undef;
    my $device = undef;
    $device = '/dev/cdrom' if ($^O =~ /linux/);
    $device = 0            if ($^O =~ /MSWin32/);
    $device = '/dev/acd0'  if ($^O =~ /freebsd/);
    
    if ($device) {
        ok($disc_id = $freedb->get_local_disc_id($device), "Unable to scan local disc drive");
    }
}

done_testing;

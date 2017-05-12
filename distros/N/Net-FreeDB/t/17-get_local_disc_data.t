use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my $disc_data = undef;
    my $device    = undef;
    
    $device = '/dev/cdrom' if ($^O =~ /linux/);
    $device = 0            if ($^O =~ /MSWin32/);
    $device = '/dev/acd0'  if ($^O =~ /freebsd/);
    
    if ($device) {
        ok($disc_data = $freedb->get_local_disc_data($device), "Unable to scan local disc drive");
    }
}

done_testing;

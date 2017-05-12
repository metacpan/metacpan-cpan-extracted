use Test::More;

BEGIN{
        use_ok Net::TFTP;
}

use Test::MockModule;
my $mock_io =  Test::MockModule->new('Net::TFTP::IO', no_auto => 1);
$mock_io->mock('new', 
               sub { open (my $fh, "<", 't/files/source'  ) or die "Can not open t/files/source: $!";
                     return $fh; }
              );



$tftp = Net::TFTP->new("some.host.name", BlockSize => 1024);
my $retval = $tftp->get('somefile','t/files/directory');
is($retval, undef, 'Error handled, no die');
like($tftp->{error}, qr(Can not open t/files/directory), 'Error message');

done_testing;

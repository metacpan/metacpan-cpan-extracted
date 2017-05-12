use Test::More;
use Test::Warn;

use Net::TFTP;

# we test for warnings
$^W = 1;

my $tftp = Net::TFTP->new();
warnings_are { $tftp->get('somefile','t/files/directory') } [], 'Warnings for new' ;
is($tftp->{error}, 'No hostname given', 'Missing hostname detected');

done_testing;

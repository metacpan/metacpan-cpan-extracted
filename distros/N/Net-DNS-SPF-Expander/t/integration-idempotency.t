use strict;
use warnings;
use lib 'lib';

use Net::DNS::SPF::Expander;
use IO::All -utf8;

use Test::More tests => 35;
use Test::Exception;
use Test::Differences;

my $backup_file  = 't/etc/test_zonefile_idem.bak';
my $new_file     = 't/etc/test_zonefile_idem.new';
my @output_files = ( $backup_file, $new_file );
for my $deletion (@output_files) {
    if ( -e $deletion ) {
        lives_ok { unlink $deletion } "I am deleting $deletion";
    } else {
        ok( 1 == 1, "$deletion was already deleted" );
    }
}

my $file_to_expand = 't/etc/test_zonefile_idem';

my $expander;
lives_ok {
    $expander
        = Net::DNS::SPF::Expander->new( input_file => $file_to_expand, );
}
"I can make a new expander";

my $string;
lives_ok { $string = $expander->write } "I can call write on my expander";

ok( -e $_, "File $_ was created" ) for @output_files;

like($string, qr/\$ORIGIN campusexplorer.com./, "Content test OK");
like($string, qr/yo      CNAME   111.222.333.4./, "Content test OK");
like($string, qr/mama    CNAME   222.333.444.5./, "Content test OK");
like($string, qr/;\*               TXT     "v=spf1 include:_spf2.campusexplorer.com include:_spf3.campusexplorer.com include:_spf4.campusexplorer.com include:_spf5.campusexplorer.com include:_spf6.campusexplorer.com ~all"/, "Content test OK");
like($string, qr/;\*               SPF     "v=spf1 include:_spf2.campusexplorer.com include:_spf3.campusexplorer.com include:_spf4.campusexplorer.com include:_spf5.campusexplorer.com include:_spf6.campusexplorer.com ~all"/, "Content test OK");
like($string, qr/;@               TXT     "v=spf1 include:_spf2.campusexplorer.com include:_spf3.campusexplorer.com include:_spf4.campusexplorer.com include:_spf5.campusexplorer.com include:_spf6.campusexplorer.com ~all"/, "Content test OK");
like($string, qr/;@               SPF     "v=spf1 include:_spf2.campusexplorer.com include:_spf3.campusexplorer.com include:_spf4.campusexplorer.com include:_spf5.campusexplorer.com include:_spf6.campusexplorer.com ~all"/, "Content test OK");
like($string, qr/;_spf.campusexplorer.com.    SPF     "v=spf1 include:_spf2.campusexplorer.com include:_spf3.campusexplorer.com include:_spf4.campusexplorer.com include:_spf5.campusexplorer.com include:_spf6.campusexplorer.com ~all"/, "Content test OK");
like($string, qr/;_spf.campusexplorer.com.    TXT     "v=spf1 include:_spf2.campusexplorer.com include:_spf3.campusexplorer.com include:_spf4.campusexplorer.com include:_spf5.campusexplorer.com include:_spf6.campusexplorer.com ~all"/, "Content test OK");
like($string, qr/;_spf2.campusexplorer.com.   SPF     "v=spf1/, "Content test OK");
like($string, qr/;_spf2.campusexplorer.com.   TXT     "v=spf1/, "Content test OK");
like($string, qr/;_spf3.campusexplorer.com.   SPF     "v=spf1/, "Content test OK");
like($string, qr/;_spf3.campusexplorer.com.   TXT     "v=spf1/, "Content test OK");
like($string, qr/;_spf4.campusexplorer.com.   SPF     "v=spf1/, "Content test OK");
like($string, qr/;_spf4.campusexplorer.com.   TXT     "v=spf1/, "Content test OK");
like($string, qr/;_spf5.campusexplorer.com.   SPF     "v=spf1/, "Content test OK");
like($string, qr/;_spf5.campusexplorer.com.   TXT     "v=spf1/, "Content test OK");
like($string, qr/;_spf6.campusexplorer.com.   SPF     "v=spf1/, "Content test OK");
like($string, qr/;_spf6.campusexplorer.com.   TXT     "v=spf1/, "Content test OK");
like($string, qr/\*    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/_spf.campusexplorer.com.    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/@    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/_spf1.campusexplorer.com.    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/_spf2.campusexplorer.com.    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/_spf3.campusexplorer.com.    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/_spf4.campusexplorer.com.    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/_spf5.campusexplorer.com.    600    IN    TXT    "v=spf1/, "Content test OK");
like($string, qr/greasy  CNAME   333.444.555.6./, "Content test OK");
like($string, qr/granny  CNAME   666.777.888.9./, "Content test OK");

#!perl -T
 
use strict;
use warnings;
 
use Test::More;
use Net::API::Gett;
 
if (!eval { require Socket; Socket::inet_aton('open.ge.tt') }) {
    plan skip_all => "Cannot connect to the API server";
} 
else {
    plan tests => 6;
}
 
my $g = Net::API::Gett->new();
 
my $share = $g->get_share('6s6enNB');
 
isa_ok($share, 'Net::API::Gett::Share', "Share");
like($share->title, qr/Many/, "Has right share title");
is(scalar $share->files, 14, "Has right number of files");
 
my $file = ($share->files)[0]; # 14
isa_ok($file, 'Net::API::Gett::File', "File");
is($file->fileid, "2f", "Has right non-integer file id");
is($file->getturl, "http://ge.tt/6s6enNB/v/2f", "right getturl");

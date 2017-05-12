#!/usr/bin/perl

use strict;
use Test::More;
use File::Temp;

if (!eval { require Socket; Socket::inet_aton('open.ge.tt') }) {
    plan skip_all => "Cannot connect to the API server";
} 
elsif ( ! $ENV{GETT_API_KEY} || ! $ENV{GETT_EMAIL} || ! $ENV{GETT_PASSWORD} ) {
    plan skip_all => "API credentials required for these tests";
}
else {
    plan tests => 11;
}

# untaint environment variables
# They will be validated for correctness in the User.pm module, so just match anything here.

my @params = map {my ($v) = $ENV{uc "GETT_$_"} =~ /\A(.*)\z/; $_ => $v} qw(api_key email password);

use Net::API::Gett;

my $gett = Net::API::Gett->new( @params );

isa_ok($gett, 'Net::API::Gett', "Gett object constructed");
isa_ok($gett->request, 'Net::API::Gett::Request', "Gett request constructed");

isa_ok($gett->user, 'Net::API::Gett::User', "Gett User object constructed");
is($gett->user->has_access_token, '', "Has no access token");

$gett->user->login or die $!;

is($gett->user->has_access_token, 1, "Has access token now");

my $test_string = "Some test data. Whee!";

my $tmp = File::Temp->new();
open my $fh, ">", $tmp->filename;
print $fh $test_string;
close $fh;

# Upload a file, download its contents, then destroy the share and the file
my $file = $gett->upload_file(
    filename => "test.t",
    contents => $tmp->filename,
    title => "perltest",
);

isa_ok($file, 'Net::API::Gett::File', "File uploaded");

is($file->filename, "test.t", "Got right filename");

my $content = $file->contents();

like($content, qr/Whee/, "Got right file content");

my $share = $gett->get_share( $file->sharename );

is($share->title, "perltest", "Got right share title");

my $file1 = ($share->files)[0];

is($file1->size, length($test_string), "Got right filesize");

is($share->destroy(), 1, "Share destroyed");

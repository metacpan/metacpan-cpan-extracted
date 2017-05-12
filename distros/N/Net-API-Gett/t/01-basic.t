#!/usr/bin/perl

use strict;
use Test::More;

if (!eval { require Socket; Socket::inet_aton('open.ge.tt') }) {
    plan skip_all => "Cannot connect to the API server";
} 
else {
    plan tests => 15;
}

use Net::API::Gett;

# doesn't require auth
# get_share()
# get_file()
# $file->contents

my $gett = Net::API::Gett->new();

isa_ok($gett, 'Net::API::Gett', "Gett object constructed");
isa_ok($gett->request, 'Net::API::Gett::Request', "Gett request constructed");

my $share = $gett->get_share("928PBdA");

isa_ok($share, 'Net::API::Gett::Share', "share object constructed");

is($share->sharename, "928PBdA", "got share name");
is($share->created, "1322847473", "got share created");
like($share->title, qr/Test/, "got share title");
is(scalar $share->files, 2, "got 2 files");

my $iter = $share->file_iterator;

isa_ok($iter, 'Array::Iterator', "Array iterator constructed");

my $file = $gett->get_file("928PBdA", 0); #hello.c

isa_ok($file, 'Net::API::Gett::File', "file object constructed");

is($file->created, 1322847473, "got file created");
is($file->fileid, 0, "got fileid");
is($file->filename, "hello.c", "got filename");
is(defined $file->getturl, 1, "getturl defined");

my $contents = $file->contents;

like($contents, qr/Hello world/, "Got hello.c content");
is(length($contents), $file->size, "file content size matches file object");

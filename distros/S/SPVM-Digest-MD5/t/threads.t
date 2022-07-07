use lib 't/lib';
use Digest::MD5;
use SPVMImpl;
Digest::MD5::is_spvm();
die unless $INC{'Digest/MD5.pm'} =~ /\bblib\b/;

use strict;
use warnings;

use Test::More;
use Config;

BEGIN {
    plan skip_all => 'Perl compiled without ithreads'
        unless $Config{useithreads};
    plan skip_all => 'no threads.pm'
        unless eval { require threads };
    plan tests => 2;
}

use threads;
use Digest::MD5;

my $module = 'Digest::MD5';

my $obj = $module->new;
$obj->add("foo");
my $tdigest = threads->create(sub { $obj->add("bar"); $obj->hexdigest })->join;

isnt $obj->clone->hexdigest, $tdigest, "unshared object unaffected by the thread";

$obj->add("bar");
is $obj->clone->hexdigest, $tdigest;

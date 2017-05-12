######################################################################
# Test suite for Net::SSH::AuthorizedKeysFile
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;
use File::Temp qw(tempfile);

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

use Test::More tests => 10;
BEGIN { use_ok('Net::SSH::AuthorizedKeysFile') };

my $tdir = "t";
$tdir = "../t" unless -d $tdir;
my $cdir = "$tdir/canned";

use Net::SSH::AuthorizedKeysFile;

my $ak = Net::SSH::AuthorizedKeysFile->new(
    file => "$cdir/ak-broken.txt",
);
my $rc = $ak->read();
is($rc, 1, "read ok on broken authorized_keys (no strict)");

$ak = Net::SSH::AuthorizedKeysFile->new(
    file   => "$cdir/ak-broken.txt",
    abort_on_error => 1,
);
$rc = $ak->read();
is($rc, undef, "read fail on broken authorized_keys (strict)");
is($ak->error(), "Line 1: [ene mene meck] rejected by all parsers",
                 "error message");

$ak = Net::SSH::AuthorizedKeysFile->new(file => "$cdir/ak.txt");
$rc = $ak->read();

is($rc, 1, "read ok on ok authorized_keys");

$ak = Net::SSH::AuthorizedKeysFile->new(file => "$cdir/ak-broken.txt",
                                        strict => 1,
                                        abort_on_error => 1);
$rc = $ak->read();

is($rc, undef, "read fail on broken authorized_keys");
is($ak->error(), "Line 1: [ene mene meck] rejected by all parsers",
                 "error message");

$ak = Net::SSH::AuthorizedKey->parse( 
    'from="bing.bang.boom",no-pty,,, 1024 35 372');

my $options = $ak->options();

is($options->{from}, "bing.bang.boom", "options with trailing commas");
is($options->{"no-pty"}, 1, "options with trailing commas");
is(join("-", sort keys %$options), "from-no-pty", 
    "options with trailing commas");

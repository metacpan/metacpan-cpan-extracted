######################################################################
# Test suite for SWISH::API::Common
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

BEGIN { use_ok('SWISH::API::Common') };

my $CANNED = "eg/canned";
$CANNED = "../eg/canned" unless -d $CANNED;

use SWISH::API::Common;
my $sw = SWISH::API::Common->new(swish_adm_dir => "$CANNED/adm");
$sw->index("$CANNED/data1/abc");

    # One
my @found = $sw->search("mike");
my $found = join " ", map { $_->path } @found;
like($found, qr(canned/data1/abc), "simple query");

    # and not the other
@found = $sw->search("someone AND else");
$found = join " ", map { $_->path } @found;
unlike($found, qr(canned/data1/def), "boolean query");

    # Now add 2nd file to index
$sw->index_add("$CANNED/data1/def");

    # Match one ...
@found = $sw->search("someone AND else");
$found = join " ", map { $_->path } @found;
like($found, qr(canned/data1/def), "boolean query");

    # ... AND the other
@found = $sw->search("mike");
$found = join " ", map { $_->path } @found;
like($found, qr(canned/data1/abc), "simple query");

END { rmf "$CANNED/adm"; }

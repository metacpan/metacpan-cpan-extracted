#
# $Id$

use strict;

use Test::More tests => 14;

use REST::Google::Search;

REST::Google::Search->http_referer('http://www.cpan.org');

use Data::Dumper;

# empty search
# defect #37213 by Xuerui Wang
my $search = REST::Google::Search->new( q => '' );
is($search->responseStatus, 200, "empty search status");

my $data = $search->responseData;
ok(defined $data, "empty search data");

my $cursor = $data->cursor;
ok(defined $cursor, "empty search cursor");

my $pages = $cursor->pages;
is(scalar(@{$pages}), 0, "empty search pages");

$search = REST::Google::Search->new( q => 'perl' );
is($search->responseStatus, 200, "status");

$data = $search->responseData;
ok(defined $data, "data");

$cursor = $data->cursor;
ok(defined $cursor, "cursor");

# defect #42011 by Dave Wolfe
$pages = $cursor->pages;
ok(scalar(@{$pages}) > 0, "pages");
is($pages->[0]->{start}, 0, "first page start");
is($pages->[0]->{label}, 1, "first page label");

my @results = $data->results;
# defect #42031 by Dave Wolfe
for (0..3) {
	is($results[$_]->{url}, $data->results->[$_]->{url});
}


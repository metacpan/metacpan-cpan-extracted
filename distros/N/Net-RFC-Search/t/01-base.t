use 5.006;
use strict;
use Test::More tests => 8;
use File::Tempdir;
use Data::Dumper;

BEGIN {
    use_ok( 'Net::RFC::Search' ) || print "Bail out!\n";
}

my $rfc_search = Net::RFC::Search->new;

#
# Search in RFC header by keyword
#
my @search_result = $rfc_search->search_by_header('WebSocket');
is_deeply(\@search_result, [6455], 'Found RFC 6455 for WebSocket protocol by "WebSocket" keyword');

@search_result = $rfc_search->search_by_header('icmp');
cmp_ok(scalar @search_result, ">", 1, 'Found multiple RFC containing ICMP keyword in their headers');

#
# Downloading RFC and dumping to file
#
my $rfc_content = $rfc_search->get_by_index(123456);
is($rfc_content, '404 Not Found', 'There is no RFC with index 123456');

$rfc_content = $rfc_search->get_by_index(6455);
ok($rfc_content, 'Downloaded RFC 6455');

{
    my $tmp_file = File::Tempdir->new->name;
    $rfc_search->get_by_index(6455, $tmp_file);
    ok(-e $tmp_file, "Successfully dumped RFC into file $tmp_file");
}

#
# User-defined rfcbaseurl and indexpath
#
{
    my $tmp_index_file = File::Tempdir->new->name;
    $rfc_search = Net::RFC::Search->new(rfcbaseurl => 'http://www.isi.edu/in-notes/', indexpath => $tmp_index_file);
    my @search_result = $rfc_search->search_by_header('icmp');
    cmp_ok(scalar @search_result, ">", 1, 'Found multiple RFC containing ICMP keyword in their headers');
}

#
# User-defined rfcbaseurl with spaces and w/o trailing slash
# Error here...
undef $rfc_search;
$rfc_search = Net::RFC::Search->new(rfcbaseurl => 'http://ietf. org/rfc');
is($rfc_search->{rfcbaseurl}, 'http://ietf.org/rfc/', 'This is now a correct rfcbaseurl');

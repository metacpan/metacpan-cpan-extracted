#!/usr/bin/perl

#
# Since July 2007 Yahoo provides search suggestions called 'Search Suggest'.
# See http://www.ysearchblog.com/archives/000469.html for the announcement.
# Suggestions are delivered in a format similar to OpenSearch Suggestions
# but not the same. This script parses Yahoo's search suggestions, adds
# links to Yahoo and cleanly wrapped provides a SeeAlso service.
#
# Please note that Yahoo might not want you to query their server via this
# method, and they might change their server, so also consider
# http://developer.yahoo.com/search/web/V1/relatedSuggestion.html
#
# A similar service for Google is available at
# http://google.com/complete/search?output=toolbar&q=...
#

use strict;
use utf8;
use LWP::Simple;
use URI::Escape qw(uri_escape);
use JSON::XS qw(decode_json);
use SeeAlso::Response;
use SeeAlso::Server;

use FindBin;
use lib "$FindBin::RealBin/lib";

sub query_method {
    my $identifier = shift;
    return unless $identifier->valid;

    my $urlbase = "http://search.yahoo.com/search?p=";
    my $url = 'http://sugg.search.yahoo.com/sg/?output=fxsearch&nresults=10&command='
            . uri_escape($identifier->value);

    my $json = get($url);
    $json =~ s/^fxsearch\(//;
    $json =~ s/\)\s*(<!--.*-->)?\s*$//m; 

    # Parse JSON data (you should NEVER trust a web service whithout checking)
    my $obj = decode_json $json; 
    for (my $i=0; $i < @{$obj->[1]}; $i++) {
        $obj->[3][$i] = $urlbase . uri_escape($obj->[1][$i]);
    }

    return SeeAlso::Response->new( @$obj );
}

print query_seealso_server(
    \&query_method,
    [
      "ShortName" => "Yahoo Search Suggest",
      #"Example" => { "id" => "hello" },
      #"Examples" => [ { "id" => "hello" }, {"id"=>"huhu", "response"=>"..."} ]
    ]
);

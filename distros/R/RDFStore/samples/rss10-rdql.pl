#!/usr/bin/perl

use DBI;

my  $dbh= DBI->connect("DBI:RDFStore:", "dan", 0 );

my $query = $dbh->prepare(<<QUERY);
SELECT ?title, ?link
FROM <http://www.kanzaki.com/info/rss.rdf>
WHERE
        (?item, <rdf:type>, <rss:item>),
        (?item, <rss::title>, ?title),
        (?item, <rss::link>, ?link)
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rss for <http://purl.org/rss/1.0/>
QUERY
$query->execute();
my ($title,$link);
$query->bind_columns(\$title, \$link);

while ($query->fetch()) {
        print "title=",$title->toString," link=".$link->toString,"\n";
        };
$query->finish();

#or free-text (actually we have to agree whether or not to use =~ and bind free-text matched to a query var)
my $query = $dbh->prepare(<<QUERY);
SELECT ?title, ?link
FROM <http://www.kanzaki.com/info/rss.rdf>
WHERE
	(?item, <rss::title>, %"RDF"%),
        (?item, <rdf:type>, <rss:item>),
        (?item, <rss::title>, ?title),
        (?item, <rss::link>, ?link)
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rss for <http://purl.org/rss/1.0/>
QUERY
$query->execute();
my ($title,$link);
$query->bind_columns(\$title, \$link);
while ($query->fetch()) {
        print "freetext: title=",$title->toString," link=".$link->toString,"\n";
        };
$query->finish();

#or with LIKE - which is a bit less efficient and using perl regex engine
my $query = $dbh->prepare(<<QUERY);
SELECT ?title, ?link
FROM <http://www.kanzaki.com/info/rss.rdf>
WHERE
        (?item, <rdf:type>, <rss:item>),
        (?item, <rss::title>, ?title),
        (?item, <rss::link>, ?link)
AND
	?title LIKE '/Rdf/i'
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rss for <http://purl.org/rss/1.0/>
QUERY
$query->execute();
my ($title,$link);
$query->bind_columns(\$title, \$link);
while ($query->fetch()) {
        print "freetext like: title=",$title->toString," link=".$link->toString,"\n";
        };
$query->finish();

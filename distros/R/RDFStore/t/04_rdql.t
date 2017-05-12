use strict ;
 
BEGIN { print "1..127\n"; };
END { print "not ok 1\n" unless $::loaded; RDFStore::debug_malloc_dump(); };

my $a = "";
local $SIG{__WARN__} = sub {$a = $_[0]} ;
 
sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}
 
sub docat
{
    my $file = shift;
    local $/ = undef;
    open(CAT,$file) || die "Cannot open $file:$!";
    my $result = <CAT>;
    close(CAT);
    return $result;
};

$::debug=0;

umask(0);
 
use RDQL::Parser;
use DBI;
use RDFStore::NodeFactory;
use RDFStore::Parser::SiRPAC;
use File::Path qw(rmtree);

$::loaded = 1;
print "ok 1\n";

my $tt=2;

#test the parser
eval {
	while(<t/rdql-tests/test-*>) {
		ok $tt++, my $parser = new RDQL::Parser();
		$parser->parse(docat($_));
		};
};
ok $tt++, !$@;

my $factory= new RDFStore::NodeFactory();

#RDQL queries
ok $tt++, my  $dbh= DBI->connect("DBI:RDFStore:", "root", 0, { nodeFactory => $factory } );

ok $tt++, my $query = $dbh->prepare(<<QUERY);
SELECT ?title, ?link
FROM <file:t/rdql-tests/rdf/rss10.php>
WHERE
	(?item, <rdf:type>, <rss:item>),
	(?item, <rss::title>, ?title),
	(?item, <rss::link>, ?link)
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rss for <http://purl.org/rss/1.0/>
QUERY
ok $tt++, $query->execute();
my ($title,$link);
ok $tt++, $query->bind_columns(\$title, \$link);
my $kk=0;
eval {
while ($query->fetch()) {
	print "title=",$title->toString," link=".$link->toString,"\n"
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (8 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT ?link, ?title
FROM <file:t/rdql-tests/rdf/rss10.php>
WHERE
	(?item, <rdf:type>, <rss:item>),
	(?item, <rss::title>, %"February"% ),
	(?item, <rss::title>, ?title ),
	(?item, <rss::link>, ?link)
#ORDER BY ( ?title =~ m/1/ )
ORDER BY ?title
LIMIT 10 
OFFSET 0
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rss for <http://purl.org/rss/1.0/>
QUERY
ok $tt++, $query->execute(); # still getting silly perl warning: Argument "February" isn't numeric in subroutine entry at blib/lib/DBD/RDFStore.pm line 315. :-(
ok $tt++, $query->bind_columns(\$link,\$title);
$kk=0;
eval {
while ($query->fetch()) {
	print "title=",$title->toString," link=".$link->toString,"\n"
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (4 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT ?title, ?link
FROM <file:t/rdql-tests/rdf/rss10.php>
WHERE
	(?item, <rdf:type>, <rss:item>),
	(?item, <rss::title>, ?title),
	(?item, <rss::link>, ?link)
AND 
        ?title LIKE /(4 February)/i
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rss for <http://purl.org/rss/1.0/>
QUERY
ok $tt++, $query->execute();
ok $tt++, $query->bind_columns(\$title,\$link);
$kk=0;
eval {
while ($query->fetch()) {
	print "title=",$title->toString," link=".$link->toString,"\n"
                if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (1 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT 	?x, ?title, ?a, ?moddate, ?createddate, ?name, ?creatormail
FROM 	<file:t/rdql-tests/rdf/dc3.rdf>
WHERE
	( ?x, <dc:title>, ?title),
	( ?x, <dcq:modified>, ?m),
	( ?m, <rdf:value>, ?moddate),
	( ?x, <dcq:created>, ?cd),
	( ?cd, <rdf:value>, ?createddate),
	( ?x, <dcq:abstract>, ?a),
	( ?cr, <vcard:FN>, ?name),
	( ?x, <dc:creator>, ?cr),
	( ?cr, <vcard:EMAIL>, ?creatormail)
USING 	dcq for <http://dublincore.org/2000/03/13/dcq#>,
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	vcard for <http://www.w3.org/2001/vcard-rdf/3.0#>,
	dc for <http://purl.org/dc/elements/1.1/>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (1 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT ?sal, ?t, ?x  
FROM	<file:t/rdql-tests/rdf/jobs-rss.rdf>,
	<file:t/rdql-tests/rdf/jobs.rss>
WHERE 
   (?x, <job:advertises>, ?y),
   (?y, <job:title>, ?t) ,
   (?y, <job:salary>, ?sal)
AND (?sal == 100000) && (?x eq <http://www.lotsofjobs.com/job2>)
USING job for <http://ilrt.org/discovery/2000/11/rss-query/jobvocab.rdf#>

QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (1 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT
	?title_value, ?title_language,
	?subject_value,?subject_language,
	?description_value, ?description_language,
	?language,
	?identifier
FROM
	<file:t/rdql-tests/rdf/example10.xml>
WHERE
	( ?tt, <rdf:value>, ?title_value),
	( ?x, <dc:title>, ?tt),
	( ?ttl, <dcq:RFC1766>, ?title_language),
	( ?ss1, <etbthes:ETBT>, ?ss2),
	( ?x, <dc:subject>, ?ss1),
	( ?ss2, <rdf:value>, ?subject_value),
	( ?tt, <dc:language>, ?ttl),
	( ?ss2, <dc:language>, ?ss3),
	( ?ss3, <dcq:RFC1766>, ?subject_language),
	( ?x, <dc:description>, ?dd),
	( ?ddl, <dcq:RFC1766>, ?description_language),
	( ?dd, <rdf:value>, ?description_value),
	( ?x, <dc:identifier>, ?identifier),
	( ?dd, <dc:language>, ?ddl),
	( ?ll1, <dcq:RFC1766>, ?language),
	( ?x, <dc:language>, ?ll1)
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
	dc for <http://purl.org/dc/elements/1.1/>,
	dcq for <http://purl.org/dc/terms/>,
	dct for <http://purl.org/dc/dcmitype/>,
	etb for <http://eun.org/etb/elements/>,
	etbthes for <http://eun.org/etb/thesaurus/elements/>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (4 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT
        ?subject_keywords_value,?subject_keywords_language
FROM
	<file:t/rdql-tests/rdf/example10.xml>
WHERE
	( ?x, <dc:subject>, ?ss1),
        ( ?ss1, <etb:Keywords>, ?ss2),
        ( ?ss2, <rdf:value>, ?subject_keywords_value),
        ( ?ss2, <dc:language>, ?ss3),
        ( ?ss3, <dcq:RFC1766>, ?subject_keywords_language)
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
	dc for <http://purl.org/dc/elements/1.1/>,
	dcq for <http://purl.org/dc/terms/>,
	dct for <http://purl.org/dc/dcmitype/>,
	etb for <http://eun.org/etb/elements/>,
	etbthes for <http://eun.org/etb/thesaurus/elements/>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (3 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT
        ?subject_keywords_value,?subject_keywords_language
FROM
	<file:t/rdql-tests/rdf/example10.xml>
WHERE
	( ?x, <dc:subject>, ?ss1),
        ( ?ss1, <etb:BREAKQUERY>, ?ss2),
        ( ?ss2, <rdf:value>, ?subject_keywords_value),
        ( ?ss2, <dc:language>, ?ss3),
        ( ?ss3, <dcq:RFC1766>, ?subject_keywords_language)
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
	dc for <http://purl.org/dc/elements/1.1/>,
	dcq for <http://purl.org/dc/terms/>,
	dct for <http://purl.org/dc/dcmitype/>,
	etb for <http://eun.org/etb/elements/>,
	etbthes for <http://eun.org/etb/thesaurus/elements/>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (0 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT 	?x, ?y, ?title1, ?title2, ?abstract1, ?abstract2, ?lastmod
FROM	
	<file:t/rdql-tests/rdf/features_fix.rdf>,
	<file:t/rdql-tests/rdf/humans_fix.rdf>
WHERE
	(?x, <dc:title>, ?title1),
        (?y, <dc:title>, ?title2),
        (?x, <dcq:abstract>, ?abstract1),
        (?y, <dcq:abstract>, ?abstract2),
        (?x, <dcq:references>, ?y),
        (?y, <dcq:modified>, ?m),
        (?m, <rdf:value>, ?lastmod)
USING 	dcq for <http://dublincore.org/2000/03/13/dcq#>,
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	vcard for <http://www.w3.org/2001/vcard-rdf/3.0#>,
	dc for <http://purl.org/dc/elements/1.1/>
QUERY
ok $tt++, $query->execute();
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
        };
};
ok $tt++, !$@;
ok $tt++, $query->finish();

if(0){
ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT 	?x, ?title, ?a, ?moddate, ?createddate, ?name, ?creatormail
FROM 	<file:t/rdql-tests/rdf/dc.rdf>,
	<file:t/rdql-tests/rdf/dc1.rdf>
 WHERE
	(?x, <dc:title>, ?title),
	(?x, <dcq:abstract>, ?a),
	(?x, <dcq:modified>, ?m),
	(?x, <dcq:created>, ?cd),
	(?m, <rdf:value>, ?moddate),
	(?cd, <rdf:value>, ?createddate),
	(?x, <dc:creator>, ?cr),
	(?cr, <vcard:FN>, ?name),
	(?cr, <vcard:EMAIL>, ?creatormail)
USING 	dcq for <http://dublincore.org/2000/03/13/dcq#>,
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	vcard for <http://www.w3.org/2001/vcard-rdf/3.0#>,
	dc for <http://purl.org/dc/elements/1.1/>
QUERY
ok $tt++, $query->execute();
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
        };
};
ok $tt++, !$@;
ok $tt++, $query->finish();
};

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?name, ?info 
SOURCE <file:t/rdql-tests/rdf/swws2001-07-30.rdf>
WHERE  
(?cal, <dc::source>, <http://www.SemanticWeb.org/SWWS/program/>),
(?cal, <ical::VEVENT-PROP>, ?event),
(?event, <ical::LOCATION>, ?geo),
(?geo, <ical::GEO-NAME>, ?text),
(?text, <rdf::value>, ?name),
(?geo, <rdfs::seeAlso>, ?info)  
USING 
rdf FOR <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
rdfs FOR <http://www.w3.org/2000/01/rdf-schema#>,
ical FOR <http://ilrt.org/discovery/2001/06/schemas/ical-full/hybrid.rdf#>,
util FOR <http://ilrt.org/discovery/2001/06/schemas/swws/index.rdf#>,
foaf FOR <http://xmlns.com/foaf/0.1/>,
dc FOR <http://purl.org/dc/elements/1.1/>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (19 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?link
SOURCE <file:t/rdql-tests/rdf/lastampaEconomia.rdf>
WHERE  
(?x, <rdf:type>, <rss:item>),
(?x, <rss::title>, ?title),
(?x, <rss::link>, ?link)
AND ?title LIKE /incombe/i
USING
rss for <http://purl.org/rss/1.0/>,
rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
        print join(',',map { $_->toString } @row)."\n"
                if($::debug);
	$kk++;
        };
};
ok $tt++, !$@;
ok $tt++, (1 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  *
SOURCE <file:t/rdql-tests/rdf/lastampaEconomia.rdf>
WHERE  
(?x, <rdf:type>, <rss:item>),
(?x, <rss::title>, ?title),
(?x, <rss::link>, ?link)
USING
rss for <http://purl.org/rss/1.0/>,
rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
QUERY
ok $tt++, $query->execute();
ok $tt++, ($#{$query->{NAME}}==2);
$kk=0;
eval {
while (my @a = $query->fetchrow_array()) {
	die
		unless(scalar(@a)>0);
	map { print $_->toString,"\n" } @a
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (19 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?y
SOURCE <file:t/rdql-tests/rdf/lastampaEconomia.rdf>
WHERE  
(?x, <rdf:type>, <rss:item>),
(?x, <rss::title>, ?title),
(?x, <rss::link>, ?link)
USING
rss for <http://purl.org/rss/1.0/>,
rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
	die
		unless(scalar(@row)>0);
	map { print $_->toString,"\n" } @row
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (19 == $kk);
ok $tt++, $query->finish();

# test context/statement grouping RDQL support
# NOTE: once the RDF Core WG will add proper context support to the XML/RDF xyntax we will be able to do it inside the SiRPAC parser self; on the other side
#       we could use the rdf:bagID reification (mess) to "automatically" associate a context to a group of statements (perhaps removing the useless high order statements)
my $now='now'.time;
my $p=new RDFStore::Parser::SiRPAC(
		Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory =>          $factory,
                style_options   => { store_options => { FreeText => 1, Context => $factory->createResource($now) } }
                );
my $model = $p->parsefile("file:t/rdql-tests/rdf/lastampaEconomia.rdf");

ok $tt++, $dbh= DBI->connect("DBI:RDFStore:", "root", 0, { sourceModel => $model } );
ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?link
WHERE  
(?x, <rdf:type>, <rss:item>, <$now>),
(?x, <rss::title>, ?title, <$now>),
(?x, <rss::link>, ?link, <$now>)
AND ?title LIKE /incombe/i
USING
rss for <http://purl.org/rss/1.0/>,
rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
	die
		unless(scalar(@row)>0);
	map { print $_->toString,"\n" } @row
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (1 == $kk);
ok $tt++, $query->finish();

# a different context
my $context='urn:rdf:magic:context:12345_ertoiororr';
my $rdf_parser=new RDFStore::Parser::SiRPAC(
		Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory =>          $factory,
                style_options   => { store_options => { FreeText => 1, Context => $factory->createResource($context) } }
                );
$model = $rdf_parser->parsefile("file:t/rdql-tests/rdf/lastampaEconomia.rdf");

ok $tt++, $dbh= DBI->connect("DBI:RDFStore:", "root", 0, { sourceModel => $model } );
ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?link
WHERE  
(?x, <rdf:type>, <rss:item>, <$context>),
(?x, <rss::title>, ?title, <$context>),
(?x, <rss::link>, ?link, <$context>)
AND ?title LIKE /incombe/i
USING
rss for <http://purl.org/rss/1.0/>,
rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) {
	die
		unless(scalar(@row)>0);
	map { print $_->toString,"\n" } @row
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (1 == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?x
WHERE  
(?x, ?y, ?z, <$context>)
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) { $kk++; };
};
ok $tt++, !$@;
ok $tt++, ($model->size == $kk);
ok $tt++, $query->finish();

ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT  ?x
WHERE  
(?x, <rdf:type>, ?y, <$context>)
USING
rss for <http://purl.org/rss/1.0/>,
rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
QUERY
ok $tt++, $query->execute();
$kk=0;
eval {
while (my @row = $query->fetchrow_array()) { $kk++; };
};
ok $tt++, !$@;
ok $tt++, (21 == $kk);
ok $tt++, $query->finish();

#remote queries
if(0){
ok $tt++, $query = $dbh->prepare(<<QUERY);
SELECT ?title, ?link
FROM <rdfstore://myremotedb_of_rss\@localhost:1234>
WHERE
	(?item, <rdf:type>, <rss:item>),
	(?item, <rss::title>, ?title),
	(?item, <rss::link>, ?link)
USING
	rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	rss for <http://purl.org/rss/1.0/>
QUERY
ok $tt++, $query->execute();
ok $tt++, $query->bind_columns(\$title, \$link);
$kk=0;
eval {
while ($query->fetch()) {
	print "title=",$title->toString," link=".$link->toString,"\n"
		if($::debug);
	$kk++;
	};
};
ok $tt++, !$@;
ok $tt++, (8 == $kk);
ok $tt++, $query->finish();
};

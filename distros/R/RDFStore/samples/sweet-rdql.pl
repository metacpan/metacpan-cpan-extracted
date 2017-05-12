#!/usr/bin/perl

use DBI;

my  $dbh= DBI->connect("DBI:RDFStore:", "sweet", 0 );

my $query = $dbh->prepare(<<QUERY); # FROM clause means fetch the URL, parse it as RDF and store it into an in-memory rdfstore :)
SELECT ?class, ?label, ?creator
FROM <http://sweet.jpl.nasa.gov/sweet/humanactivities.daml>
WHERE
        (?class, <rdf:type>, <daml:Class>),
        (?class, <rdfs:label>, ?label),
        (?class, <oiled:creator>, ?creator)
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
        oiled for <http://img.cs.man.ac.uk/oil/oiled#>,
	daml for <http://www.daml.org/2001/03/daml+oil#>
QUERY
$query->execute();
my ($class,$label,$creator);
$query->bind_columns(\$class, \$label, \$creator);

while ($query->fetch()) {
        print "class=",$class->toString," label=".$label->toString," creator=".$creator->toString."\n";
        };
$query->finish();

#or free-text (actually the RDQL syntax has to formally whether or not to use =~ and bind free-text matched to a query var)
my $query = $dbh->prepare(<<QUERY);
SELECT ?class, ?label, ?creator
FROM <http://sweet.jpl.nasa.gov/sweet/humanactivities.daml>
WHERE
        (?class, <rdfs:label>, %"Management"%),
        (?class, <rdf:type>, <daml:Class>),
        (?class, <rdfs:label>, ?label),
        (?class, <oiled:creator>, ?creator)
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
        oiled for <http://img.cs.man.ac.uk/oil/oiled#>,
	daml for <http://www.daml.org/2001/03/daml+oil#>
QUERY
$query->execute();
my ($class,$label,$creator);
$query->bind_columns(\$class, \$label, \$creator);

while ($query->fetch()) {
        print "freetext: class=",$class->toString," label=".$label->toString," creator=".$creator->toString."\n";
        };
$query->finish();

#or with LIKE - which is a bit less efficient and using perl regex engine (but allows stemming :)
my $query = $dbh->prepare(<<QUERY);
SELECT ?class, ?label, ?creator
FROM <http://sweet.jpl.nasa.gov/sweet/humanactivities.daml>
WHERE
        (?class, <rdf:type>, <daml:Class>),
        (?class, <rdfs:label>, ?label),
        (?class, <oiled:creator>, ?creator)

AND
	?label LIKE '/agement/i'
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
        oiled for <http://img.cs.man.ac.uk/oil/oiled#>,
	daml for <http://www.daml.org/2001/03/daml+oil#>
QUERY
$query->execute();
my ($class,$label,$creator);
$query->bind_columns(\$class, \$label, \$creator);

while ($query->fetch()) {
        print "freetext LIKE: class=",$class->toString," label=".$label->toString," creator=".$creator->toString."\n";
        };
$query->finish();

# or SQL like boolean expressions
my $query = $dbh->prepare(<<QUERY);
SELECT ?class, ?label, ?creator
FROM <http://sweet.jpl.nasa.gov/sweet/humanactivities.daml>
WHERE
        (?class, <rdf:type>, <daml:Class>),
        (?class, <rdfs:label>, ?label),
        (?class, <oiled:creator>, ?creator)

AND
	( ?label LIKE '/agement/i' ) || ( ?creator eq 'raskin' )
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
        oiled for <http://img.cs.man.ac.uk/oil/oiled#>,
	daml for <http://www.daml.org/2001/03/daml+oil#>
QUERY
$query->execute();
my ($class,$label,$creator);
$query->bind_columns(\$class, \$label, \$creator);

while ($query->fetch()) {
        print "SQL-ish: class=",$class->toString," label=".$label->toString," creator=".$creator->toString."\n";
        };
$query->finish();

# or if you have your daml/ subdir with your ontologies already in
my  $dbh1= DBI->connect("DBI:RDFStore:database=daml", "sweet", 0 );

my $query = $dbh1->prepare(<<QUERY); # we do not have a FROM clause because we are reading triples from the database daml/
SELECT ?class, ?label, ?creator
WHERE
        (?class, <rdf:type>, <daml:Class>),
        (?class, <rdfs:label>, ?label),
        (?class, <oiled:creator>, ?creator)

AND
	( ?label LIKE '/agement/i' ) || ( ?creator eq 'raskin' )
USING
        rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
        rdfs for <http://www.w3.org/2000/01/rdf-schema#>,
        oiled for <http://img.cs.man.ac.uk/oil/oiled#>,
	daml for <http://www.daml.org/2001/03/daml+oil#>
QUERY
$query->execute();
my ($class,$label,$creator);
$query->bind_columns(\$class, \$label, \$creator);

while ($query->fetch()) {
        print "stored SQL-ish: class=",$class->toString," label=".$label->toString," creator=".$creator->toString."\n";
        };
$query->finish();

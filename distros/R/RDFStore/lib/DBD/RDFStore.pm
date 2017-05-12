# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1
# *		- first hacked version of DBI driver for RDFStore
# *     version 0.2
# *		- added SELECT DISTINCT support
# *		- updated RDF-for-XML format to return xsi:type information
# *		- start adding empty bound/var support
# *             - added ?prefix:var QName support to vars
# *		- updated RDF/XML format to stream one single grap
# *		- added SPARQL CONSTRUCT support
# *		- added DBD::RDFStore::st::getQueryStatement() method
# *		- renamed asRDF DBI parameter as results - and removed output handle and output_string modes
# *		- updated XML and misc RDF output format interface to use DBD::RDFStore::st specific methods:
# *		  	fetchrow_XML(), fetchall_XML(), fetchsubgraph_serialize(), fetchallgraph_serialize()
# *		- added fetchsubgraph() and fetchallgraph() methods to return matches as RDFStore::Model
# *		- added SPARQL DESCRIBE support
# *		- fixed bug into _prepareTriplepattern() when bNode is substituted
# *		- added simple RDF/S rdfs:subClassOf rdfs:subPropertyOf and owl:sameAs inferencing if aval into input RDF merge and requested
# *		- updated search() method call to use new XS code interface (hash ref)
# *		- added simpler XML serialization (dawg-xml) see http://www.w3.org/2001/sw/DataAccess/rf1/
# *		- replaced rdfqr-results with dawg-results format http://www.w3.org/2001/sw/DataAccess/tests/result-set#
# *		- removed rs:size from dawg-results format see http://lists.w3.org/Archives/Public/public-rdf-dawg/2004OctDec/0196.html
# *		- added not standard RDQL/SPARQL DELETE support
# *		- updated to rw mode for database connection if specified or DELETE requested
# *		- added default SPARQL PREFIX op: <http://www.w3.org/2001/sw/DataAccess/operations> and PREFIX fn: <http://www.w3.org/2004/07/xpath-functions>	
# *		- added basic set of SPARQL operations and functions - see http://www.w3.org/2001/sw/DataAccess/rq23/#tests
# *		- constraints are now process using a RPN stack
# *		- added simple SPARQL OPTIONAL keyword support
# *		- fixed bug when processing bNodes
# *		- added SPARQL LIMIT support
# *             - added SPARQL OFFSET support
# *             - added SPARQL ORDER BY support
# *

package DBD::RDFStore;

use DBI qw(:sql_types);
use strict;
use vars qw($err $errstr $sqlstate $drh $VERSION);

use Carp;
 
$VERSION = '0.2';

$err = 0;             # holds error code   for DBI::err
$errstr = "";         # holds error string for DBI::errstr
$sqlstate = "";       # holds SQL state for    DBI::state

$drh = undef;         # holds driver handle once initialized

sub driver {
        return $drh if $drh;        # already created - return same one
        my($class, $attr) = @_;
        
        $class .= "::dr";
        
        # not a 'my' since we use it above to prevent multiple drivers
        $drh = DBI::_new_drh($class, {
            'Name'    => 'DBD::RDFStore',
            'Version' => $VERSION,
            'Err'     => \$DBD::RDFStore::err,
            'Errstr'  => \$DBD::RDFStore::errstr,
            'State'   => \$DBD::RDFStore::state,
            'Attribution' => 'DBD::RDFStore by Alberto Reggiori',
        });
        
        return $drh;
};

package DBD::RDFStore::dr; # ====== DRIVER ======

use vars qw ($VERSION);
use strict;
 
$VERSION = '0.2';

use RDFStore::NodeFactory;
use RDFStore::Model;

$DBD::RDFStore::dr::imp_data_size = 0;
    
sub connect {
        my($drh, $dbname, $user, $auth, $attr)= @_;
        
        # Some database specific verifications, default settings
        # and the like following here. This should only include
        # syntax checks or similar stuff where it's legal to
        # 'die' in case of errors.

	# e.g. DBI:rdfstore:database=cooltest;host=localhost;port=1234
	my %params;
	$params{ Name } = $1
		if ($dbname =~ /database=([^;]+)/);
	$params{ Host } = $1
		if ($dbname =~ /host=([^;]+)/);
	$params{ Port } = $1
		if ($dbname =~ /port=([^;]+)/);
	if ($dbname =~ /mode=([^;]+)/) {
		$params{ Mode } = $1;
	} else {
		$params{ Mode } = 'r'; #read-only
		};
	$params{ FreeText } = 1; # force this

	my $factory;
	if(	(exists $attr->{nodeFactory}) &&
		(defined $attr->{nodeFactory}) &&
		(ref($attr->{nodeFactory})) &&
		($attr->{nodeFactory}->isa("RDFStore::NodeFactory")) ) {
		$factory = $attr->{nodeFactory};
	} else {
		$factory = new RDFStore::NodeFactory;
		};

	# source model
        my $source_model;
	if(	(exists $attr->{sourceModel}) &&
		(defined $attr->{sourceModel}) &&
		(ref($attr->{sourceModel})) &&
		($attr->{sourceModel}->isa("RDFStore::Model")) ) {
		$source_model = $attr->{sourceModel};
	} else {
                eval {
                        $source_model = new RDFStore::Model( nodeFactory => $factory, %params );
                };
                if ($@) {
                        DBI::_new_dbh($drh, {})->DBI::set_err( 1, $@ );
                        return undef;
                        };
		};

        my $smarter = 0;
	if(	(exists $attr->{'smarter'}) &&
		(defined $attr->{'smarter'}) &&
		($attr->{'smarter'}) =~ m/(yes|on|1)/) {
		$smarter = 1;
		};

        # create a 'blank' dbh (call superclass constructor)
        my %options = (
            'Name' => $dbname,
            'USER' => $user,
            'CURRENT_USER' => $user,
	    'FACTORY' => $factory );

	if(	(exists $attr->{'results'}) &&
               	(defined $attr->{'results'}) &&
		(ref($attr->{'results'}) =~ /HASH/) &&
		(exists $attr->{'results'}->{'syntax'}) &&
		(defined $attr->{'results'}->{'syntax'}) ) {
		#output syntax
		if($attr->{'results'}->{'syntax'} !~ m#(RDF/XML|N-Triples|dawg-results|rdf-for-xml|dawg-xml)#i) {
        		DBI::_new_dbh($drh, {})->DBI::set_err( 1, "Unrecognized serialization syntax '".$attr->{'results'}->{'syntax'}."'" );
                	return undef;
			};
		$attr->{'results'}->{'syntax'} = 'RDF/XML'
			unless(exists $attr->{'results'}->{'syntax'});

		$options{'results'} = $attr->{'results'};
		};

	$options{'SOURCE_MODEL'} = $source_model
		if($source_model);

	$options{'SMARTER'} = $smarter;

        my $dbh = DBI::_new_dbh($drh, \%options, {});
        
        $dbh;
};

sub disconnect_all {
        # we don't need to tidy up anything
	};

sub DESTROY {
	};

package DBD::RDFStore::db; # ====== DATABASE ======

use vars qw ($VERSION);
use strict;
 
$VERSION = '0.2';

use RDQL::Parser;
    
$DBD::RDFStore::db::imp_data_size = 0;
    
sub prepare {
        my($dbh, $statement, @attribs)= @_;

	#parse the RDQL statement (2nd tier thingie :)
        my $parser = RDQL::Parser->new();
	$parser->parse( $statement ); #bear in mind that if we would use cache_prepare() we need to keep a copy (clone) of this!!!!

        # create a 'blank' sth
        my %options = (
            'Statement' => $parser, #bit ugly I know....
	    'FACTORY' => $dbh->{'FACTORY'},
	    'Default_prefixes' => {}
        	);
	map { $options{ 'Default_prefixes' }->{ $RDQL::Parser::default_prefixes{$_} } = $_;
	} keys %RDQL::Parser::default_prefixes;

	# primitive query optimizer - rewrite constraints to triple-patterns if possible - see http://www.w3.org/2001/sw/DataAccess/rq23/#ConstraintsAndPredciates
	# (push what possible down to DB level - see optimize() method )
	$options{'ce'} = new DBD::RDFStore::db::constraints();
	return
		unless( $options{'ce'}->optimize( $dbh, $options{'Statement'} ) );
	#use Data::Dumper;
	#print STDERR Dumper( $options{'Statement'} );

	$options{'results'} = $dbh->{'results'}
		if(exists $dbh->{'results'});

        $options{'SOURCE_MODEL'} = $dbh->{'SOURCE_MODEL'}
		if(exists $dbh->{'SOURCE_MODEL'});

        $options{'SMARTER'} = $dbh->{'SMARTER'};

        my $sth = DBI::_new_sth($dbh, \%options );

        # Setup module specific data
        $sth->STORE('driver_params', []);

	# if we do not set NUM_OF_PARAMS we could not call bind_param - see DBI::DBD(3)
	#$sth->STORE('NUM_OF_PARAMS', $#{$parser->{resultVars}}+1 ); # what about SELECT '*' ??!!!??
	#$sth->STORE('NUM_OF_PARAMS', ($statement =~ tr/?//)); # RDQL/SquishQL uses '?' for something else?? need to read the DBI docs better....

	if(	( ($#{$sth->{'Statement'}->{resultVars}}==0) &&
               	  ($sth->{'Statement'}->{resultVars}->[0] eq '*') ) ||
		( $sth->{'Statement'}->getQueryType eq 'CONSTRUCT' ) ||
		( $sth->{'Statement'}->getQueryType eq 'DELETE' ) ) {	# obviously this is wrong due the just want to bypass/cheat 
									# the DBI interface when return RDF content...
		my %vars;
		foreach my $gp ( @{ $sth->{'Statement'}->{'graphPatterns'} } ) {
			next
				unless( ref($gp) ); #skip AND or UNION keyword eventually
			foreach my $tp ( @{ $gp->{'triplePatterns'} } ) {
				@vars{ grep /^([\?\$].+)$/, @{ $tp } } = ();
				};
			};
                my @vv = sort keys %vars; # but the order here sucks!!
                $sth->STORE( NAME =>  \@vv );
                $sth->STORE('NUM_OF_FIELDS', $#vv+1 );
	} elsif( $sth->{'Statement'}->getQueryType eq 'DESCRIBE' ) {
                my @vv = grep /^([\?\$].+)$/, @{ $sth->{'Statement'}->{'describes'} };
                $sth->STORE( NAME =>  \@vv );
                $sth->STORE('NUM_OF_FIELDS', $#vv+1 );
        } else {
                $sth->STORE( NAME => $sth->{'Statement'}->{resultVars} );
                $sth->STORE('NUM_OF_FIELDS', $#{$sth->{'Statement'}->{resultVars}}+1 ); # it might be that the resultsing table could have different colums lenghts....
                };

        return $sth;
	};

sub FETCH {
        my ($dbh, $attrib) = @_;
        # In reality this would interrogate the database engine to
        # either return dynamic values that cannot be precomputed
        # or fetch and cache attribute values too expensive to prefetch.
        return 1 if $attrib eq 'AutoCommit';
        # else pass up to DBI to handle
        return $dbh->SUPER::FETCH($attrib);
	};

sub STORE {
        my ($dbh, $attrib, $value) = @_;
        # would normally validate and only store known attributes
        # else pass up to DBI to handle
        if ($attrib eq 'AutoCommit') {
		return 1
			if $value; # is already set
		Carp::croak("Can't disable AutoCommit");
        	};
        return $dbh->SUPER::STORE($attrib, $value);
	};

sub DESTROY {
	};

package DBD::RDFStore::db::constraints;
    
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use Carp;

$DBD::RDFStore::db::constraints::debug = 0;

%DBD::RDFStore::db::constraints::namespaces = (
	'op' => 'http://www.w3.org/2001/sw/DataAccess/operations',
	'fn' => 'http://www.w3.org/2004/07/xpath-functions'
	);
%DBD::RDFStore::db::constraints::prefixes = (
	'http://www.w3.org/2001/sw/DataAccess/operations' => 'op',
	'http://www.w3.org/2004/07/xpath-functions' => 'fn'
	);

sub isString {
	my ($node) = @_;

	return ( ! isNumeric($node) ) ? 1 : 0 ;
	};

sub isNumeric {
	my ($node) = @_;

	my $status=0;

	return $status
		unless( $node );

	if(	(ref($node)) &&
		( $node->getDataType ) ) {
		$status = (	($node->isa("RDFStore::Literal")) &&
				(	( $node->getDataType eq 'http://www.w3.org/2001/XMLSchema#integer' ) ||
					( $node->getDataType eq 'http://www.w3.org/2001/XMLSchema#float' ) ||
					( $node->getDataType eq 'http://www.w3.org/2001/XMLSchema#double' ) ) ) ? 1 : 0 ;
	} else {
		my $num = (ref($node)) ? $node->toString : $node ;
		$status = (	( int($num) ) ||
				( $num =~ /^\s*(([0-9]+\.[0-9]*([eE][+-]?[0-9]+)?[fFdD]?)|(\.[0-9]+([eE][+-]?[0-9]+)?[fFdD]?)|([0-9]+[eE][+-]?[0-9]+[fFdD]?)|([0-9]+([eE][+-]?[0-9]+)?[fFdD]))\s*/ ) ||
                		( $num =~ /^\s*([0-9]+)\s*/ ) ||
				( $num =~ /^\s*(0[xX]([0-9",a-f,A-F])+)\s*/ ) ) ? 1 : 0 ;
		};

	return $status;
	};

sub getContent {
	my ($node) = @_;

	return (	( $node ) &&
			(ref($node)) &&
			($node->isa("RDFStore::RDFNode")) ) ? $node->toString : $node ;
	};

# operators and functions - see http://www.w3.org/2001/sw/DataAccess/rq23/#tests
%DBD::RDFStore::db::constraints::dictionary = ();

# General Operations

# a EQ b
$DBD::RDFStore::db::constraints::dictionary{ 'eq' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( getContent($b) eq getContent($a) ) ? 1 : 0 ; # correct? I think not due in perl this is for strings
	return \@ret, 2;
	};

# a NE b
$DBD::RDFStore::db::constraints::dictionary{ 'ne' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( getContent($b) ne getContent($a) ) ? 1 : 0 ; # correct? I think not due in perl this is for strings
	return \@ret, 2;
	};

# a && b
$DBD::RDFStore::db::constraints::dictionary{ '&&' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( getContent($b) && getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};

# a || b
$DBD::RDFStore::db::constraints::dictionary{ '||' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( getContent($b) || getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};

# not(a)
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'not' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	push @ret, not( getContent($a) );
	return \@ret, 1;
	};

# Operators on Numeric Values

# a + b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-add' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, getContent($b) + getContent($a);
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '+' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-add' };

# a - b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-subtract' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, getContent($b) - getContent($a);
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '-' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-subtract' };

# a * b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-multiply' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, getContent($b) * getContent($a);
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '*' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-multiply' };

# a / b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-divide' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, getContent($b) / getContent($a);
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '/' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-divide' };

$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-integer-divide' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-divide' };

# a % b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-mod' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, getContent($b) % getContent($a);
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '%' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-mod' };

# +a
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-unary-plus' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	push @ret, +$a;
	return \@ret, 1;
	};

# -a
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-unary-minus' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	push @ret, -$a;
	return \@ret, 1;
	};

# Comparison of Numeric Values ( they will be pushed down to DB level)

# a < b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-less-than' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( isNumeric($a) and isNumeric($b) and getContent($b) < getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '<' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-less-than' };

# a <= b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-less-than-or-equal' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( isNumeric($a) and isNumeric($b) and getContent($b) <= getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '<=' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-less-than-or-equal' };

# a == b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-equal' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( isNumeric($a) and isNumeric($b) and getContent($b) == getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '==' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-equal' };

# a != b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-not-equal' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( isNumeric($a) and isNumeric($b) and getContent($b) != getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '!=' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-not-equal' };

# a >= b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-greater-than-or-equal' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( isNumeric($a) and isNumeric($b) and getContent($b) >= getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '>=' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-greater-than-or-equal' };

# a > b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-greater-than' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( isNumeric($a) and isNumeric($b) and getContent($b) > getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};
$DBD::RDFStore::db::constraints::dictionary{ '>' } =
	$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'numeric-greater-than' };

# Functions on Numeric Values

# abs a
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'abs' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	push @ret, abs( getContent($a) );
	return \@ret, 1;
	};

# ceiling a
# description: Returns the smallest number with no fractional part that is greater than or equal to the argument.
#$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'ceiling' } = sub {};

# floor a
# description: Returns the largest number with no fractional part that is less than or equal to the argument.
#$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'floor' } = sub {};

# round a
# description: Rounds to the nearest number with no fractional part.
#$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'round' } = sub {};

# round-half-to-even a
# description: Takes a number and a precision and returns a number rounded to the given precision. If the fractional part 
#              is exactly half, the result is the number whose least significant digit is even.
#$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'round-half-to-even' } = sub {};

# Comparison and Collation on Strings

# a cmp b
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'compare' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( getContent($b) cmp getContent($a) ) ? 1 : 0 ;
	return \@ret, 2;
	};

# Functions on Strings

# contains(a, b)
# description: Indicates whether one xs:string contains another xs:string. A collation may be specified.
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'contains' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	push @ret, ( $b =~ /\Q$a\E/ ) ? 1 : 0 ;
	return \@ret, 2;
	};

# starts-with(a, b)
# description: Indicates whether the value of one xs:string begins with the collation units of another 
#              xs:string. A collation may be specified.
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'starts-with' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	push @ret, ( $b =~ /^\Q$a\E/ ) ? 1 : 0 ;
	return \@ret, 2;
	};

# ends-with(a, b)
# description: Indicates whether the value of one xs:string ends with the collation units of another 
#              xs:string. A collation may be specified.
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'ends-with' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	push @ret, ( $b =~ /\Q$a\E$/ ) ? 1 : 0 ;
	return \@ret, 2;
	};

# substring-before(a, b)
# description: Returns the collation units of one xs:string that precede in that xs:string the collation 
#              units of another xs:string. A collation may be specified.
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'substring-before' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	$b =~ /\Q$a\E/;
	push @ret, $`;
	return \@ret, 2;
	};

# substring-after(a, b)
# description: Returns the collation units of xs:string that follow in that xs:string the collation units 
#              of another xs:string. A collation may be specified.
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'substring-after' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	$b =~ /\Q$a\E/;
	push @ret, $';
	return \@ret, 2;
	};

# string-length(a)
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'string-length' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	push @ret, length( getContent($a) );
	return \@ret, 1;
	};

# upper-case(a)
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'upper-case' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	push @ret, uc( getContent($a) );
	return \@ret, 1;
	};

# lower-case(a)
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'lower-case' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	push @ret, lc( getContent($a) );
	return \@ret, 1;
	};

# matches(a, b)
# description: Returns an xs:boolean value that indicates whether the value of the first argument is matched 
#              by the regular expression that is the value of the second argument.
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'matches' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	push @ret, ( $b =~ /$a/ ) ? 1 : 0 ;
	return \@ret, 2;
	};

# Comparison of Strings

# Functions and Operators /  Equality and Comparison of Strings

# $a =~ $b
# $b pattern is like [m]/pattern/[i][m][s][x]
# sparql:regex ????
$DBD::RDFStore::db::constraints::dictionary{ '=~' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
#print "matching( $b =~ $a )\n"
#	if( $a =~ m/[m]?\/(.*)\/[i]?[m]?[s]?[x]?/ );
	push @ret, ( $a =~ m/[m]?\/(.*)\/[i]?[m]?[s]?[x]?/ and eval " \"$b\" =~ $a " ) ? 1 : 0 ;
	return \@ret, 2;
	};

# $a !~ $b
# $b pattern is like [m]/pattern/[i][m][s][x]
$DBD::RDFStore::db::constraints::dictionary{ '!~' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	$b = getContent($b);
	push @ret, ( $a =~ m/[m]?\/(.*)\/[i]?[m]?[s]?[x]?/ and eval " \"$b\" !~ $a " ) ? 1 : 0 ;
	return \@ret, 2;
	};

# String Operations
# asstring(a)
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'fn'}.'string' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my @ret;
	$a = getContent($a);
	push @ret, "$a";
	return \@ret, 1;
	};

# AnyURI
# op:anyURI-equal( a )
# description: Returns true if the two arguments are equal
$DBD::RDFStore::db::constraints::dictionary{ $DBD::RDFStore::db::constraints::namespaces{'op'}.'anyURI-equal' } = sub {
	my $work1 = shift;
	my $a     = pop @{ $work1 };
	my $b     = pop @{ $work1 };
	my @ret;
	push @ret, ( lc(getContent($b)) eq lc(getContent($a)) ) ? 1 : 0 ; #correct?
	return \@ret, 2;
	};

sub new {
	return bless {}, shift;
	};

# very primitive query optimizer - this expression re-write to triple-patterns should probably feed back into SPARQL parser itself - or not?
# NOTE: the constraints should be fed as RPN stack of iterators and their operations
sub optimize {
	my ($class, $dbh, $sparql_statement ) = @_;

	foreach my $i ( 0..$#{ $sparql_statement->{'graphPatterns'} } ) {
		next
			unless( ref($sparql_statement->{'graphPatterns'}->[$i]) ); #skip AND or UNION keyword eventually

		return
			unless( _do_optimize_level0( $dbh, $sparql_statement, $sparql_statement->{'graphPatterns'}->[$i] ) );

		return
			unless( _do_optimize_level1( $dbh, $sparql_statement, $sparql_statement->{'graphPatterns'}->[$i] ) );
		};

	return 1;
	};

# level1: triple-patterns optimization
sub _do_optimize_level0 {
	my ( $dbh, $sparql_statement, $gp ) = @_;

	# we could eventually further sort the main triple-patterns to make the query more efficient (kinds topological order here with the shortest first)
	# TBD...

	# optionals are process always after
	# see http://lists.w3.org/Archives/Public/public-rdf-dawg/2005JanMar/0101.html
	@{ $gp->{'triplePatterns'} } = sort { $a->[0] <=> $b->[0] } @{ $gp->{'triplePatterns'} };

	return 1;
	};

# level1: constraints optimization
sub _do_optimize_level1 {
	my ( $dbh, $sparql_statement, $gp ) = @_;

if(0) {
if($#{$gp->{'triplePatterns'}}>=0) { #we do this only if we really have other triple-patterns to match against given constraints
	# (this part needs to scan the RPN STACK)
	# try to re-write some constraints to triple-patterns using op: and fn: special prefixes
	# NOTE: the list of "known" operators supported is DB/store specific of course
	my @constraints_tps = ();
	my @splice_pos=();
	for my $i ( 0..$#{ $gp->{'constraints'} } ) {

		# numerical comparinson
		if( $gp->{'constraints'}->[$i] eq '<' ) {
			# operators must be numerical (int or float)
			next
				if(	( $gp->{'constraints'}->[$i-1] =~ m/^([\"\']|true|false|null)/ ) ||
					( $gp->{'constraints'}->[$i+1] =~ m/^([\"\']|true|false|null)/ ) );
			push @constraints_tps, [	$gp->{'optional'},
							$gp->{'constraints'}->[$i-1], 
							'<'.$sparql_statement->{'prefixes'}->{'op'}.'numeric-less-than'.'>',
							$gp->{'constraints'}->[$i+1] ];
			push @splice_pos, $i-1;
		} elsif( $gp->{'constraints'}->[$i] eq '<=' ) {
			next
				if(	( $gp->{'constraints'}->[$i-1] =~ m/^([\"\']|true|false|null)/ ) ||
					( $gp->{'constraints'}->[$i+1] =~ m/^([\"\']|true|false|null)/ ) );
			push @constraints_tps, [	$gp->{'optional'},
							$gp->{'constraints'}->[$i-1], 
							'<'.$sparql_statement->{'prefixes'}->{'op'}.'numeric-less-than-or-equal'.'>',
							$gp->{'constraints'}->[$i+1] ];
			push @splice_pos, $i-1;
		} elsif( $gp->{'constraints'}->[$i] eq '==' ) {
			next
				if(	( $gp->{'constraints'}->[$i-1] =~ m/^([\"\']|true|false|null)/ ) ||
					( $gp->{'constraints'}->[$i+1] =~ m/^([\"\']|true|false|null)/ ) );
			push @constraints_tps, [	$gp->{'optional'},
							$gp->{'constraints'}->[$i-1], 
							'<'.$sparql_statement->{'prefixes'}->{'op'}.'numeric-equal'.'>',
							$gp->{'constraints'}->[$i+1] ];
			push @splice_pos, $i-1;
		} elsif( $gp->{'constraints'}->[$i] eq '>' ) {
			next
				if(	( $gp->{'constraints'}->[$i-1] =~ m/^([\"\']|true|false|null)/ ) ||
					( $gp->{'constraints'}->[$i+1] =~ m/^([\"\']|true|false|null)/ ) );
			push @constraints_tps, [	$gp->{'optional'},
							$gp->{'constraints'}->[$i-1], 
							'<'.$sparql_statement->{'prefixes'}->{'op'}.'numeric-greater-than'.'>',
							$gp->{'constraints'}->[$i+1] ];
			push @splice_pos, $i-1;
		} elsif( $gp->{'constraints'}->[$i] eq '>=' ) {
			next
				if(	( $gp->{'constraints'}->[$i-1] =~ m/^([\"\']|true|false|null)/ ) ||
					( $gp->{'constraints'}->[$i+1] =~ m/^([\"\']|true|false|null)/ ) );
			push @constraints_tps, [	$gp->{'optional'},
							$gp->{'constraints'}->[$i-1], 
							'<'.$sparql_statement->{'prefixes'}->{'op'}.'numeric-greater-than-or-equal'.'>',
							$gp->{'constraints'}->[$i+1] ];
			push @splice_pos, $i-1;
			};
		};

	# zapped those re-wrtiten
	my $zz=0;
	foreach( @splice_pos ) {
		splice( @{ $gp->{'constraints'} }, ($_-$zz), 3, 1 );
		$zz+=2; #correct?
		};

	# add constraints to triple-patterns list
	push @{ $gp->{triplePatterns} }, @constraints_tps;	
	};
};

	# we really going to modify the parsed SPARQL statement object here - not good...
	$gp->{'constraints_triplePatterns'} = [];

	# separate known constraints triple-patterns from main triple-patterns - they will be joined back when each query is run (see _prepareTriplePattern())
	my $ops_prefix = $sparql_statement->{'prefixes'}->{'op'};
	my @splice_pos=();
        for my $i ( 0..$#{ $gp->{triplePatterns} } ) {
		if(	( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-less-than>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-less-than>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-less-than>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-less-than-or-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-less-than-or-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-less-than-or-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-not-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-not-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-not-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-greater-than-or-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-greater-than-or-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-greater-than-or-equal>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-greater-than>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-greater-than>' ) ||
			( $gp->{triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-greater-than>' ) ) {

			push @{ $gp->{'constraints_triplePatterns'} }, $gp->{triplePatterns}->[$i];

			push @splice_pos, $i;
		} elsif( $gp->{triplePatterns}->[$i]->[2] =~ m|^<$ops_prefix| ) {
			$dbh->DBI::set_err( 1, "Unknown SPARQL operator ". $gp->{triplePatterns}->[$i]->[2] );
                	return undef;
			};
		};
	my $zz=0;
	foreach( @splice_pos ) {
		splice( @{ $gp->{triplePatterns} }, ($_-$zz), 1 );
		$zz++;
		};

	# but if there are not triple-patterns left to match against we should piggy back to plain AND constraints (inefficient I know!)
	if($#{$gp->{'triplePatterns'}}<0) {
		@splice_pos=();
        	for my $i ( 0..$#{ $gp->{constraints_triplePatterns} } ) {
			if(	( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-less-than>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-less-than>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-less-than>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-less-than-or-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-less-than-or-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-less-than-or-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-not-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-not-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-not-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-greater-than-or-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-greater-than-or-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-greater-than-or-equal>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'numeric-greater-than>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'date-greater-than>' ) ||
				( $gp->{constraints_triplePatterns}->[$i]->[2] eq '<'.$ops_prefix.'dateTime-greater-than>' ) ) {
				my $op = $gp->{constraints_triplePatterns}->[$i]->[2];
				$op =~ s/^<//;
				$op =~ s/>$//;
				push @{ $gp->{'constraints'} }, (
					$gp->{constraints_triplePatterns}->[$i]->[1],
					$gp->{constraints_triplePatterns}->[$i]->[3],
					$op );

				push @{ $gp->{'constraints'} }, '&&'
					if( ( $#{ $gp->{'constraints'} } - 3 ) >= 0 );

				push @splice_pos, $i;
				};
			};
		$zz=0;
		foreach( @splice_pos ) {
			splice( @{ $gp->{constraints_triplePatterns} }, ($_-$zz), 1 );
			$zz++;
			};
		};

	return 1;
	};

sub eval {
	my ($class, $sth, $constraints, $result ) = @_;

	# make a copy of the constraints
	my @stack = @{ $constraints };

	my @return;

	if($DBD::RDFStore::db::constraints::debug) {
		#print "DBD::RDFStore::db::constraints::eval STACK:\n";
		#use Data::Dumper;
		#print Dumper(\@stack);
		print "BINDINGS:\n";
		map {
			print $_." = ".( $result ? $result->{$_}->toString : '' )."\n";
		} keys %{ $result };
		};

	my @work;
	while( @stack ) {
		my $op = shift @stack;
		my $is_string = 0;
		my $is_uri = 0;
		my $is_function = 0;
		if( $op eq '&' ) {
			$op = shift @stack; # hop to next one
			last
				unless($op);
			$is_function = 1;
			};
		if ( $op =~ s/^["'](.*)["']$/$1/g ) {
			$is_string = 1;
		} elsif( $op =~ s/^<(.*)>$/$1/ ) {
			$is_uri = 1;
			};
                if ( 	!$is_string and
			defined( $DBD::RDFStore::db::constraints::dictionary{ $op } ) ) {
                    	my @work_stack = @work;
			my ( $ret, $remove_stack, $remove_return );
			eval { #fire safe
				( $ret, $remove_stack, $remove_return ) = $DBD::RDFStore::db::constraints::dictionary{ $op } ( \@work_stack );
				};
			if($@) {
				$sth->DBI::set_err( 1, "Cannot process query constraints: ". $@ );
                        	return 0;
				};
			if ( $remove_return >= 0 ) {
				for ( 1 .. $remove_return ) {
					pop @return;
					}
			} else {
				my $to_ret = pop @{ $ret };
				push @return, $to_ret;
			};
			for ( 1 .. $remove_stack ) {
				pop @work;
				};
			unshift @stack, @work, @{ $ret };
			undef @work; # eaten operators
		} else {
			if($is_function) {
				$sth->DBI::set_err( 1, "Undefined function $op" );
				return 0;
				};
			if( $op =~ /\s*([\?\$][a-zA-Z0-9_\$\.:]+)\s*/ ) {
				unless( exists $result->{ $op } ) {
					#should eventually warn/error of not existent var
					$sth->DBI::set_err( 1, "Variable $op not existing" );
					return 0;
					};

				push @work, $result->{ $op };
			} else {
				# we should take care of Unicode escapes, intergers and floats formats and cast to perl SVs (nums done automatically?)
				push @work, $op;
				};
			};
		};

	# leave the rest on the stack
	unshift @stack, @work;

#print "LEFT ON STACK '".join(',',@stack)."'\n";

	return 0
		if( $#stack > 0 );

	my $status = getContent( $stack[0] );

	if($DBD::RDFStore::db::constraints::debug) {
		print "DBD::RDFStore::db::constraints::eval RETURN STATUS=$status\n";
		};

	return $status;
	};

package DBD::RDFStore::st;
    
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.2';

use Carp;
use RDFStore::Parser::SiRPAC; #for RDQL query sources parsing on-the-fly
use RDFStore::Model;
use RDFStore::Serializer;
use RDFStore::Vocabulary::RDF;
use RDFStore::Vocabulary::RDFS;
use RDFStore::Vocabulary::OWL;

$DBD::RDFStore::st::serializer = new RDFStore::Serializer(); #fake one for the moment just for xml-escape functionality

$DBD::RDFStore::st::imp_data_size = 0;
$DBD::RDFStore::st::debug = 0;

sub bind_param {
        my($sth, $pNum, $val, $attr) = @_;
        my $type = (ref $attr) ? $attr->{TYPE} : $attr;
        if ($type) {
            my $dbh = $sth->{Database};
            $val = $dbh->quote($sth, $type);
        }
        my $params = $sth->FETCH('driver_params');
        $params->[$pNum-1] = $val;
	1;
};

sub getQueryStatement {
        my($sth) = @_;

	return $sth->{'Statement'};
	};

sub execute {
        my($sth, @bind_values) = @_;

        $sth->{'driver_data'} = [];

	$sth->{'iterators'} = {};
        $sth->{'binds'} = [];
        $sth->{'result'} = {};
        $sth->{'global_result'} = {};
        $sth->{'result_RPN_stack'} = [];
        $sth->{'result_cache'} = [];
	$sth->{'total_matches'} = 0;
	
	$sth->{'previous_results'} = {}; #this keeps in-memory all the crypto-digests of all results (expensive?)

	$sth->{'cp_closure'}={};
	$sth->{'cp_sameas'}={};

	# parse the RDF or pick up the right database
	my $source_model;
	if($#{$sth->{'Statement'}->{sources}}>=0) {
		my $genid=0;
		foreach my $source (@{$sth->{'Statement'}->{sources}}) {
			$source =~ s/^\<([^\>]+)\>$/$1/; #actually Andy wants this a QName :-(
			my $model;

			eval {
				if ( $source =~ m#^rdfstore://([^@]+)@([^:]+):?(\d+)?# ) {
					# connect to remote DB
					$model = new RDFStore::Model (
							Name => $1,
                                                	Host => $2,
                                                	Port => $3,
                                                	nodeFactory => $sth->{'FACTORY'},
                                                	FreeText => 1,
							Mode => ( $sth->{'Statement'}->getQueryType eq 'DELETE' ) ? 'rw' : 'r'
							);
				} elsif ( $source =~ m#^rdfstore://# ) {
					# connect to local DB
					$model = new RDFStore::Model (
							Name => $source,
                                                	nodeFactory => $sth->{'FACTORY'},
                                                	FreeText => 1,
							Mode => ( $sth->{'Statement'}->getQueryType eq 'DELETE' ) ? 'rw' : 'r'
							);
				} else {
					#in-memory model
					my $p = new RDFStore::Parser::SiRPAC(
						Style =>        'RDFStore::Parser::Styles::RDFStore::Model',
                                        	NodeFactory =>  $sth->{'FACTORY'},
                                        	GenidNumber =>  $genid,
                                        	style_options   =>      { store_options => { FreeText => 1 } } #we should check if we are using LIKE operator here...
						);
					$model= $p->parsefile($source);
					$genid = $p->getReificationCounter();
					};
				};

			if($@) {
                               	$sth->DBI::set_err( 1, $@ ); # correct??!
                               	next;
                               	};

			next 
				unless(defined $model);

			if(defined $source_model) {
				if ( $source_model->isRemote ) {
					$sth->DBI::set_err( 1, "For remote queries can not have more than just one RDF source: $@" );
					return undef;
					};
				# the following will break if you have multiple rdfstore:// URLs as sources because is tied read-only
				# a solution would be to have an in-memory model anyway
				#smush() will be better at some point :)
				my $ee = $model->elements;
				while ( my $ss = $ee->each ) {
					$source_model->add( $ss );
					};
			} else {
				#$model = $model->duplicate #which is bad for the moment but allows "to join distributed searches" :-)
				#	if(	( scalar(@{$sth->{'Statement'}->{sources}}) > 0 ) &&
				#		( $model->isRemote ) );
				$source_model=$model;
				};
			};
		unless(defined $source_model) {
			$sth->DBI::set_err( 1, "Cannot process RDF input: $@" );
			return undef;
			};
	} else {
		$source_model=$sth->{'SOURCE_MODEL'};
                };    

        unless(defined $source_model) {
                $sth->DBI::set_err( 1, "Cannot detect RDF input" );
                return undef;
                };

	#print STDERR $source_model->serialize(undef,'RDF/XML')."\n";

	$sth->{'source_model'} = $source_model;

	# zap the whole model
	if(	( $sth->{'Statement'}->getQueryType eq 'DELETE' ) &&
		($#{$sth->{'Statement'}->{resultVars}}==0) &&
		($sth->{'Statement'}->{resultVars}->[0] eq '*') ) {
		my $elements = $sth->{'source_model'}->elements;
		while( my $st = $elements->each ) {	
			unless($sth->{'source_model'}->remove( $st )) {
				$sth->DBI::set_err( 1, "Cannot DELETE triple ". $st->toString );
                		return undef;
				};
			};
		};

        return '0E0'; #we do *not* want to know the number of rows affected at the moment due to efficency problems :)
	};

# fetch the next result set (row)
# This subroutine runs a depth-first like visit of the graph matching the triple patterns (even if we do not really 
# have an in-memory rep of the query process!)
# i.e. the way we visit the graph (backtrack) is "told" by the triple-patterns in the query
# i.e. $sth->{'result'} = ( '?x' => 1, '?y' => Test1 )
#
sub _nextMatch {
        my( $sth, $rpi, $gp, $tpi, %bind ) = @_;

	if($DBD::RDFStore::st::debug>1) {
		print STDERR (" " x $tpi);
		print STDERR "$tpi BEGIN\n";	
		};

	# if we have a previous state try to recover it (this is needed for streaming results)
	my $bind_state = pop @{ $sth->{'binds'} };

	if(	( $bind_state ) && ($DBD::RDFStore::st::debug>1) ) {
		print STDERR (" " x $tpi);
		print STDERR "RECOVER previous state for $tpi\n";
		};

	_nextMatch( $sth, $rpi, $gp, $tpi+1, %{$bind_state} )
		if( $bind_state );

	#we stop on the way if some result was matched already
	if ( scalar(keys %{$sth->{'result'}}) > 0 ) {
		#save actual state on the stack
		push @{ $sth->{'binds'} }, \%bind
			if(	scalar(keys %bind) > scalar(keys %{$gp->{'previous_bindings'}}) and #did we got new columns? (correct??!?!)
				scalar(keys %bind) > 0 );

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi GOT NEW RESULT ready (top)\n";
			};

		return;
		};

	if ( $tpi > $#{$gp->{triplePatterns}} ) {
		# actually copy the new result
		map { $sth->{'result'}->{$_} = $bind{$_}; } keys %bind;

		return;
		};

	delete( $sth->{'iterators'}->{$rpi}->{$tpi} ) #retry
		if(     $gp->{'optional'} and #optional block?
			exists $sth->{'iterators'}->{$rpi}->{$tpi} and
               		! $sth->{'iterators'}->{$rpi}->{$tpi}->{itr}->hasnext ); # and previous iterator is over?

	# we want to keep the current iterator state and avoid to run the same query over and over again
	unless( exists $sth->{'iterators'}->{$rpi}->{$tpi} ) {
		$sth->{'iterators'}->{$rpi}->{$tpi} = {};

		#substitute %bind into i-esim triple-pattern if possible and needed

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi BEFORE substitute: TP( ",join(',',@{ $gp->{triplePatterns}->[$tpi] })," )\n";
			};

		my @tp;
		my %vars;
		$sth->{'iterators'}->{$rpi}->{$tpi}->{vars} = {};
		$sth->{'iterators'}->{$rpi}->{$tpi}->{optional} = 0;
		my @tp_copy; # local copy of i-esim triple-pattern - needed??!?
		for my $i ( 0..$#{$gp->{triplePatterns}->[$tpi]} ) {
			if($i==0) {
				$sth->{'iterators'}->{$rpi}->{$tpi}->{optional} = $gp->{triplePatterns}->[$tpi]->[$i];
				next;
				};
			push @tp_copy, $gp->{triplePatterns}->[$tpi]->[$i];
			};
		my $j=0;
        	foreach ( @tp_copy ) {
                	if(/^([\?\$].+)$/) {
				my $var = $1;

				if(exists $bind{$var}) {
                       			if(	(defined $bind{$var}) &&
						($bind{$var}->isa("RDFStore::Literal")) &&
						($j==2) && #do not join in literals on the wrong position
						(s/^\Q$var\E$/$bind{$var}->toString/eg) ) {
                               			$_ = '"'.$_.'"';
						$_ .= '@'.$bind{$var}->getLang
							if($bind{$var}->getLang);
                       			} elsif(	(defined $bind{$var}) &&
							($bind{$var}->isa("RDFStore::Resource")) &&
							(s/^\Q$var\E$/$bind{$var}->toString/eg) ) {
                               			$_ = '<'.( ($bind{$var}->isbNode) ? '_:'.$_ : $_ ).'>';
                               		} else {
						#unbound var can not continue if conjunctive AND simple query
						# NOTE: optionals will change this perhaps with hoping to next TP _nextMatch() recursive call

						delete($sth->{'iterators'}->{$rpi}->{$tpi}); #forget to have been here

						if($DBD::RDFStore::st::debug>1) {
							print STDERR "variable $var is unbound for TP ( ".join(',',@{ $gp->{triplePatterns}->[$tpi] }).")\n";
							};

						return;
						};
				} else {
					$sth->{'iterators'}->{$rpi}->{$tpi}->{vars}->{$var} = $j; #i-esim position is a var/to-bind
					};
				};
			$j++;

               		push @tp, $_;
       			};

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi AFTER substitute: TP( ",join(',',@tp)," )\n";
			};

		#run i-esim search
		$sth->{'iterators'}->{$rpi}->{$tpi}->{itr} = $sth->{'source_model'}->{rdfstore}->search( _prepareTriplepattern( $sth, $gp, @tp ) );

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi JUST GOT '".($sth->{'iterators'}->{$rpi}->{$tpi}->{itr}->size)."' RESULTS\n"
				if(defined $sth->{'iterators'}->{$rpi}->{$tpi}->{itr});
			};

		if(	$sth->{'iterators'}->{$rpi}->{$tpi}->{optional} and # optional?
			( ! defined $sth->{'iterators'}->{$rpi}->{$tpi}->{itr} or # and did not match?
			  $sth->{'iterators'}->{$rpi}->{$tpi}->{itr}->size == 0 ) ) {
			#print "GOT OPTIONAL ".join(',',@tp_copy)."\n";
			map {
				$bind{ $_ } = undef
					unless(exists $bind{ $_ });
			} keys %{ $sth->{'iterators'}->{$rpi}->{$tpi}->{vars} }; # fill up holes
#print "NOT BOUNDs '".join(',',map { (ref($bind{$_})) ? $bind{$_}->toString : $bind{$_} } keys %bind)."'\n";
			_nextMatch( $sth, $rpi, $gp, $tpi+1, %bind );

			#we stop on the way if some result was matched already
			if ( scalar(keys %{$sth->{'result'}}) > 0 ) {
				#forget the last ones (it is for the @tp substitution above i.e. same as it was called)
                        	map { delete( $bind{$_} ); } keys %{$sth->{'iterators'}->{$rpi}->{$tpi}->{vars}};

                        	#save actual state on the stack
                        	push @{ $sth->{'binds'} }, \%bind
					if(	scalar(keys %bind) > scalar(keys %{$gp->{'previous_bindings'}}) and #did we got new columns? (correct??!?!)
						scalar(keys %bind) > 0 );

                        	if($DBD::RDFStore::st::debug>1) {
                                	print STDERR (" " x $tpi);
                                	print STDERR "$tpi GOT NEW RESULT ready (bottom)\n";
                                	};
                        	return;
                        	};
			};
		};

	return
		unless( $sth->{'iterators'}->{$rpi}->{$tpi}->{itr} );

	#for each resulting new vars recursively call itself to solve the others; the i-esim process is over when all vars are bounded
	while ( my $c = $sth->{'iterators'}->{$rpi}->{$tpi}->{itr}->each ) {
		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi GOT TRIPLE MATCH '".$c->toString."'\n";
			};

		#fill-in the bindings for the current match and fetch the properties values
		foreach my $var ( keys %{$sth->{'iterators'}->{$rpi}->{$tpi}->{vars}} ) {

                	# get the variable value out
                        my $pp = ($sth->{'iterators'}->{$rpi}->{$tpi}->{vars}->{$var} == 0) ? ($c->subject) :
                        	 ($sth->{'iterators'}->{$rpi}->{$tpi}->{vars}->{$var} == 1) ? ($c->predicate) :
                        	 ($sth->{'iterators'}->{$rpi}->{$tpi}->{vars}->{$var} == 2) ? ($c->object) :
                        	                                                      ($c->context) ;

                        $bind{ $var } = $pp; #got result (var could be unbound/undef also) - shall we check if already there/passed??

			if($DBD::RDFStore::st::debug>1) {
				print STDERR (" " x $tpi);
                                print STDERR "$tpi GOT RESULT '$var'='".( ($bind{ $var }) ? $bind{ $var }->toString : '' )."' and '".$c->toString."'\n";
				};

			};

		# we save into local stack the current state for future each() calls
		# i.e. save %bind per call to _nextMatch()
		
		#look for the next bind
		_nextMatch( $sth, $rpi, $gp, $tpi+1, %bind );

		# we could even return the result to the caller using a callback perhaps??!?!? i.e. pull model

		#we stop on the way if some result was matched already
		if ( scalar(keys %{$sth->{'result'}}) > 0 ) {
			#forget the last ones (it is for the @tp substitution above i.e. same as it was called)
			map { delete( $bind{$_} ); } keys %{$sth->{'iterators'}->{$rpi}->{$tpi}->{vars}};

			#save actual state on the stack
			push @{ $sth->{'binds'} }, \%bind
				if(	scalar(keys %bind) > scalar(keys %{$gp->{'previous_bindings'}}) and #did we got new columns? (correct??!?!)
					scalar(keys %bind) > 0 );

			if($DBD::RDFStore::st::debug>1) {
				print STDERR (" " x $tpi);
				print STDERR "$tpi GOT NEW RESULT ready (bottom)\n";
				};

			return;
			};
		};

	delete( $sth->{'iterators'}->{$rpi}->{$tpi} );

	if($DBD::RDFStore::st::debug>1) {
		print STDERR (" " x $tpi);
		print STDERR "$tpi END\n";
		};
	};

sub _isBlock {
	my ($block) = @_;

	return
		unless(ref($block));

	return (	exists $block->{'triplePatterns'} and
			exists $block->{'constraints'} ) ? 1 : 0;
	};

sub _isEmptyBlock {
	my ($block) = @_;

	return
		unless(ref($block));

	return (	( $#{ $block->{'triplePatterns'} } >= 0 ) ||
			( $#{ $block->{'constraints'} } >= 0 ) ) ? 0 : 1;
	};

# Each call to _each() goes through the triple patterns and try to bind/solve the next variable; all the iterators (search) are cached and not run twice 
# if not necessary. The whole process could probably be compiled (pre-processed) in the DBI execute() in the future and the _each() will do real iterator 
# style fetch next
#
sub _each {
        my( $sth ) = @_;

	$sth->{'result'} = {};
	$sth->{'result_RPN_stack'} = [];

	if( $#{ $sth->{'result_cache'} } >= 0 ) {
		$sth->{'result'} = shift @{ $sth->{'result_cache'} };
	} elsif( $#{ $sth->{'Statement'}->{'graphPatterns'} } == 0 ) {
		# simplest case - one single graph-pattern
		_each_other( $sth, 0, $sth->{'Statement'}->{'graphPatterns'}->[0] ); #run $a block
	} else {
		return; #DISABLE blocks processing for the moment - not finished

		# we need to copy the RPN stack across each time (expensive or possble to avoid this?) and add some extra fields for processing
		foreach my $i ( 0..$#{ $sth->{'Statement'}->{'graphPatterns'} } ) {
			if( ref($sth->{'Statement'}->{'graphPatterns'}->[$i]) ) {
				my $gp = {
					'triplePatterns' =>     [],
					'constraints'    =>     [],
					'constraints_triplePatterns'    =>     [],
					'optional'       =>     $sth->{'Statement'}->{'graphPatterns'}->[$i]->{'optional'}
					};
				map {
					my @tp = @{ $_ };
					push @{ $gp->{'triplePatterns'} }, \@tp;
				} @{ $sth->{'Statement'}->{'graphPatterns'}->[$i]->{'triplePatterns'} };
				map {
					my @tp = @{ $_ };
					@{ $gp->{'constraints_triplePatterns'} }, \@tp;
				} @{ $sth->{'Statement'}->{'graphPatterns'}->[$i]->{'constraints_triplePatterns'} };
				@{ $gp->{'constraints'} } = @{ $sth->{'Statement'}->{'graphPatterns'}->[$i]->{'constraints'} };
				$gp->{'empty'} = _isEmptyBlock( $gp );
				push @{ $sth->{'result_RPN_stack'} }, $gp;
			} else {
				push @{ $sth->{'result_RPN_stack'} }, $sth->{'Statement'}->{'graphPatterns'}->[$i];
				};
			};

		# process the RPN stack now and return in-between results if possible
		if( $DBD::RDFStore::st::debug > 2 ) {       
                	print "DBD::RDFStore::st::_each RPN STACK:\n";
                	#use Data::Dumper;
                	#print Dumper(\@{ $sth->{'result_RPN_stack'} });
                	};

		# run each graph-pattern and get the next match (if any) for each one and stack it up
		my @work;
		my $rpi=0; #used for global tracking of iterators per graph-pattern
		my $result;
		while( @{ $sth->{'result_RPN_stack'} } ) {
			my $op = shift @{ $sth->{'result_RPN_stack'} };
			if( ref($op) ) {
				push @work, $op;
			} else {
				if ( $op eq 'AND' ) { # simple (graph-pattern-A) AND (graph-pattern-B)

					# remove the two results
					my $b = pop @work;
					my $a = pop @work;

					# not sure the following is needed...
					#my $swap;
					#if(	$a->{'optional'} and
					#	! $b->{'optional'} ) { #do optionals later if possible
					#	$swap = $b;
					#	$b = $a;
					#	$a = $swap;
					#	};

					# run the two queries if not done already in previous steps of stack processing
					if( _isBlock( $a ) ) { #to be run
						$a->{'result'} = {};
						$a->{'previous_bindings'} = {};
						unless( $a->{'empty'} ) { # skip empty blocks
							_each_other( $sth, $rpi, $a ); #run $a block
							%{ $a->{ 'result' } } = %{ $sth->{'result'} }; #copy
							$rpi++;
							};
						};

					if( _isBlock( $b ) ) { #to be run
						$b->{'result'} = {};
						$b->{'previous_bindings'} = $a->{'result'};
						unless(	scalar(keys %{$a->{'result'}}) == 0 or
							$b->{'empty'} ) { # skip empty blocks
							_each_other( $sth, $rpi, $b ); #run $a block
							%{ $b->{ 'result' } } = %{ $sth->{'result'} }; #copy
							$rpi++;
							};
						};

                			#use Data::Dumper;
                			#print "A:\n";
                			#print Dumper($a);
                			#print "B:\n";
                			#print Dumper($b);

					$result = {
						'empty' => 0,
						'optional' => 0,
						'result' => {}
						};

					my $false = 0;
					if(	$a->{'optional'} and
						$b->{'optional'} ) {
						$result->{'optional'} = 1;

						#outer one must match for the contained block
						# see http://www.w3.org/2001/sw/DataAccess/rq23/#OptionalMatchingGrouped
						#my %vars;
						#foreach my $tp ( @{ $b->{'triplePatterns'} } ) {
						#	@vars{ grep /^([\?\$].+)$/, @{ $tp } } = ();
						#	};
					} elsif(	$a->{'empty'} and
							$b->{'empty'} ) {
						$result->{'empty'} = 1;
						$false = 1;
					} elsif(	(	$a->{'empty'} and
								$b->{'optional'} ) or
							(	$a->{'optional'} and
								$b->{'empty'} ) ) {
						$result->{'optional'} = 1;
					} elsif(	! $a->{'empty'} and
							! $b->{'empty'} ) {
						$result->{'empty'} = 0;
						#$false = (	scalar( keys %{ $a->{'result'} } ) > 0 and
						#		scalar( keys %{ $b->{'result'} } ) > 0	) ? 0 : 1 ; #both must match - correct?
					} elsif(	(	$a->{'empty'} and
								! $b->{'empty'} ) or
							(	! $a->{'empty'} and
								$b->{'empty'} ) ) {
						$result->{'empty'} = 0;
						};
					unless($false) {
						# merge the two results keys
						map {
							$result->{'result'}->{ $_ } = $a->{'result'}->{ $_ };
							} keys %{ $a->{'result'} };
						map {
							$result->{'result'}->{ $_ } = $b->{'result'}->{ $_ }
								unless( exists $a->{'result'}->{ $_ } ); # which should be useless due to previous result passed
							} keys %{ $b->{'result'} };

		if( $DBD::RDFStore::st::debug > 1 ) {       
        		map {
                		print STDERR "NEW RPN RESULT \t$_ = ".( (defined $result->{'result'}->{$_}) ? $result->{'result'}->{$_}->toString : '' )."\n";
                		} sort keys %{$result->{'result'}};
			};

						};

                			#print "RESULT:\n";
                			#print Dumper($result);
				} elsif ( $op eq 'UNION' ) { # simple (graph-pattern-A) OR (graph-pattern-B)
					# simply put @work_stack into cache and set $sth->{'result'} to the first
					return;
					};

                        	unshift @{ $sth->{'result_RPN_stack'} }, @work, $result;
                        	undef @work; # eaten operators
				};
			};
		# leave the rest on the stack
		unshift @{ $sth->{'result_RPN_stack'} }, @work;

		if( $DBD::RDFStore::st::debug > 2 ) {       
                	print "DBD::RDFStore::st::_each LEFT ON RPN STACK:\n";
                	#use Data::Dumper;
                	#print Dumper(\@{ $sth->{'result_RPN_stack'} });
                	};

		return
			if( $#{ $sth->{'result_RPN_stack'} } > 0 ); 

		my $status = shift @{ $sth->{'result_RPN_stack'} };
		$sth->{'result'} = $status->{'result'};
		};

	return
		unless( scalar(keys %{ $sth->{'result'} }) > 0 ); #is the query over?

	# i.e. fetch a row - e.g. [var1.a, var2.a,...varn.a], [var1.b, var2.b,.....varn.b], [var1.c, var2.c,...varn.c], .......
        my @result = map {
                $sth->{'result'}->{$_};
                } @{ $sth->FETCH ('NAME') }; # the variables are not of course in order of "execution"

        # i.e [var1.a, var2.a,...varn.a], [var1.b, var2.b,.....varn.b], [var1.c, var2.c,...varn.c], .......
        return \@result;
	};

sub _each_other {
        my( $sth, $rpi, $gp ) = @_;

	$sth->{'result'} = {};

	#start matching
        $sth->{'iterators'}->{$rpi} = {}
		unless( exists $sth->{'iterators'}->{$rpi} );
	
	if( $DBD::RDFStore::st::debug > 1 ) {       
        	map {
                	print STDERR "PREVIOUS BINDING \t$_ = ".( (defined $gp->{'previous_bindings'}->{$_}) ? $gp->{'previous_bindings'}->{$_}->toString : '' )."\n";
                        } sort keys %{$gp->{'previous_bindings'}};
		print "\n";
        	};

	_nextMatch( $sth, $rpi, $gp, 0, %{ $gp->{'previous_bindings'} } );

	if( $DBD::RDFStore::st::debug > 1 ) {       
        	map {
                	print STDERR "NEW RESULT \t$_ = ".( (defined $sth->{'result'}->{$_}) ? $sth->{'result'}->{$_}->toString : '' )."\n";
                        } sort keys %{$sth->{'result'}};
		print "\n";
        	};

	# eval constraints which can not be pushed down to DB search() method
	if($#{$gp->{constraints}}>=0) {
		# the following should be done automatically by calling _nextMatch() with empty triple-patterns (see the method)
		#%{ $sth->{'result'} } = %{ $gp->{'previous_bindings'} }
		#	unless( scalar(keys %{$sth->{'result'}}) > 0 ); #otherwise give a shot to the previous passed constraints
		# purge matched positions with constraints
		while (	(scalar(keys %{$sth->{'result'}})>0) && # still bound vars?
			(!( $sth->{'ce'}->eval($sth, $gp->{constraints}, $sth->{'result'} ) )) && #got a valid constrained match ?
			( scalar( keys %{$sth->{'iterators'}->{$rpi}}) > 0 ) ) { #there are still nodes to be visitied

			#reset current result set which is not matching the constraints
			$sth->{'result'} = {};

			#_nextMatch( $sth, $rpi, $gp, 0, () );
			_nextMatch( $sth, $rpi, $gp, 0, %{ $gp->{'previous_bindings'} } ); #try the next one
			};
		};
	};

sub _result_digest {
        my ($result ) = @_;

	my $digest;
	for my $i ( 0..$#{$result} ) {
		if($digest) {
			$digest = $result->[$i]->getDigest
				if($result->[$i]);
		} else {
			$digest .= $result->[$i]->getDigest
				if($result->[$i]);
			};
		};

	return $digest;
	};

sub _distinct {
        my ($sth, $result ) = @_;

	# two results are DISTINCT if any of thier bindings are different
	return ( exists $sth->{'previous_results'}->{ _result_digest( $result ) } ) ? 0 : 1 ;
	};

sub _prepareTriplepattern {
	my ($sth, $gp, @tp) = @_;

print STDERR "TP=".join(',', @tp)."\n" if($DBD::RDFStore::st::debug>1);

        #all non-words operators are set to 0=OR - will need 1=AND for real RDQL query
	my $query={	"search_type" => 0, #default triple-pattern search
			"s" => [],
			"s_op" => "or",
			"p" => [],
			"p_op" => "or",
			"o" => [],
			"o_op" => "or",
			"c" => [],
			"c_op" => "or",
			"xml:lang" => [],
			"xml:lang_op" => "or",
			"rdf:datatype" => [],
			"rdf:datatype_op" => "or",
			"ranges" => []
			};

	# current triple-pattern variables
	my %vars;
        @vars{ grep /^([\?\$].+)$/, @tp } = ();

	# process constraints related to current triple-pattern
	my %ranges;
	for my $i ( 0..$#{ $gp->{'constraints_triplePatterns'} } ) {
		if(exists $vars{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }) {
			$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] } = {
				'vals' => [],
				'op' => []
				} unless(exists $ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] });

			# remove quotes
			my $string = $gp->{'constraints_triplePatterns'}->[$i]->[3];	
                       	$string =~ s/^\s*["']//;
                       	$string =~ s/["']\s*$//;
			if(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-less-than>' ) ||
				( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-less-than>' ) ||
				( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-less-than>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'op'}}, "a < b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-less-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-less-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-less-than-or-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'op'}}, "a <= b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'op'}}, "a == b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-not-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-not-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-not-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'op'}}, "a != b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-greater-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-greater-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-greater-than-or-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'op'}}, "a >= b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-greater-than>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-greater-than>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-greater-than>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[1] }->{'op'}}, "a > b";
				};
		} elsif(exists $vars{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }) {
			$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] } = {
				'vals' => [],
				'op' => []
				} unless(exists $ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] });

			# remove quotes
			my $string = $gp->{'constraints_triplePatterns'}->[$i]->[1];
                       	$string =~ s/^\s*["']//;
                       	$string =~ s/["']\s*$//;
			if(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-less-than>' ) ||
				( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-less-than>' ) ||
				( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-less-than>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'op'}}, "a > b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-less-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-less-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-less-than-or-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'op'}}, "a >= b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'op'}}, "a == b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-not-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-not-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-not-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'op'}}, "a != b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-greater-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-greater-than-or-equal>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-greater-than-or-equal>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'op'}}, "a <= b";
			} elsif(	( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'numeric-greater-than>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'date-greater-than>' ) ||
					( $gp->{'constraints_triplePatterns'}->[$i]->[2] eq '<'.$sth->{'Statement'}->{'prefixes'}->{'op'}.'dateTime-greater-than>' ) ) {
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'vals'}}, $string;
				push @{$ranges{ $gp->{'constraints_triplePatterns'}->[$i]->[3] }->{'op'}}, "a < b";
				};
			};
		};
	foreach my $key ( keys %ranges ) {
		if(	$ranges{ $key }->{'op'}->[0] eq 'a < b' and
			$ranges{ $key }->{'op'}->[1] eq 'a > b' ) {
			push @{$query->{'ranges'}}, reverse @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a < b < c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a <= b' and
				$ranges{ $key }->{'op'}->[1] eq 'a > b' ) {
			push @{$query->{'ranges'}}, reverse @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a < b <= c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a <= b' and
				$ranges{ $key }->{'op'}->[1] eq 'a >= b' ) {
			push @{$query->{'ranges'}}, reverse @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a <= b <= c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a < b' and
				$ranges{ $key }->{'op'}->[1] eq 'a >= b' ) {
			push @{$query->{'ranges'}}, reverse @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a <= b < c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a > b' and
				$ranges{ $key }->{'op'}->[1] eq 'a < b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a < b < c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a >= b' and
				$ranges{ $key }->{'op'}->[1] eq 'a < b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a <= b < c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a >= b' and
				$ranges{ $key }->{'op'}->[1] eq 'a <= b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a <= b <= c";
		} elsif(	$ranges{ $key }->{'op'}->[0] eq 'a > b' and
				$ranges{ $key }->{'op'}->[1] eq 'a <= b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a < b <= c";
		} elsif( $ranges{ $key }->{'op'}->[0] eq 'a < b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a < b";
		} elsif( $ranges{ $key }->{'op'}->[0] eq 'a <= b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a <= b";
		} elsif( $ranges{ $key }->{'op'}->[0] eq 'a >= b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a >= b";
		} elsif( $ranges{ $key }->{'op'}->[0] eq 'a > b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a > b";
		} elsif( $ranges{ $key }->{'op'}->[0] eq 'a == b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a == b";
		} elsif( $ranges{ $key }->{'op'}->[0] eq 'a != b' ) {
			push @{$query->{'ranges'}}, @{$ranges{ $key }->{'vals'}};
			$query->{'ranges_op'} = "a != b";
		} else {
			return; #rest is unknown/ignored
			};
		};

        my $node;
	my $isrdftype=0;
        for my $j ( 0..$#tp ) {
		my $field = ( $j==0 ) ? 's' : ( $j==1 ) ? 'p' : ( $j==2 ) ? 'o' : 'c' ;
		next
			if($tp[$j]=~/^([\?\$].+)$/);

               	if($tp[$j]=~/^<(([^\:]+)\:{1,2}([^>]+))>$/) {
			map {
				my $ored=$_;
               			if($ored=~/^(([^\:]+)\:{1,2}(.*))$/) {
					if($ored=~/^_:([A-Za-z][A-Za-z0-9_\-\.]*)$/) {
                       				#bNode joining in
                              			$node = $sth->{'FACTORY'}->createAnonymousResource($1);

						print STDERR "bNode=",$node->toString,"\n"
							if($DBD::RDFStore::st::debug>1);
                       			} elsif(	(defined $2) &&
                       					(	(exists $sth->{'Statement'}->{prefixes}->{$2}) ||
								(exists $sth->{'Default_prefixes'}->{$2}) ) ) {
                               			$node = $sth->{'FACTORY'}->createResource(
						(exists $sth->{'Statement'}->{prefixes}->{$2}) ? 
							$sth->{'Statement'}->{prefixes}->{$2} : 
							$sth->{'Default_prefixes'}->{$2} ,$3);

						print STDERR "NODE=",$node->toString,"\n"
							if($DBD::RDFStore::st::debug>1);
                       			} else {
                       				#no namespace set - see RDFStore::Resource
                       				$node = $sth->{'FACTORY'}->createResource($1);

						print STDERR "NODE1=",$node->toString,"\n"
							if($DBD::RDFStore::st::debug>1);
                               			};
					$isrdftype=1
						if(	($j==1) &&
							($node->equals($RDFStore::Vocabulary::RDF::type)) );

					if($sth->{'SMARTER'}) {
						if($j==1) {
							my $sameas = sameAs( $sth, $node, 'property' );
							push @{$query->{$field}}, values %{$sameas};
						} elsif(	($j==2)  &&
								($isrdftype) ) {
							my $sameas = sameAs( $sth, $node, 'class' );
							push @{$query->{$field}}, values %{$sameas};
						} else {
                       					push @{$query->{$field}}, $node;
							};
					} else {
                       				push @{$query->{$field}}, $node;
						};
					};
			} split(/\s+,\s+/, $1); #hack for OR-ed nodes
               	} elsif($tp[$j]=~/^<([^>]+)>$/) {
			map {
				my $ored=$_;
				my $lang=$1
					if($ored =~ s/\@([a-z0-9]+(-[a-z0-9]+)?)\s*$//m); #xml:lang
				if(     ($ored=~ s/^\s*["']//) &&
                                        ($ored=~ s/["']\s*$//) ) {
                                        # to add rdf:datatype and rdf:parseType too - see SPARQL spec
                                        $node = $sth->{'FACTORY'}->createLiteral($ored, undef, $lang);

                                        print STDERR "LITERAL =".$node->toString,"\n"
						if($DBD::RDFStore::st::debug>1);

                                        push @{$query->{$field}}, $node;
				} elsif($ored=~/^_:([A-Za-z][A-Za-z0-9_\-\.]*)$/) {
                       			#bNode joining in
                              		$node = $sth->{'FACTORY'}->createAnonymousResource($1);

					print STDERR "bNode=",$node->toString,"\n"
						if($DBD::RDFStore::st::debug>1);

					if($sth->{'SMARTER'}) {
						if($j==1) { #impossible anyway to have a bNode as predicate...should croak!
                       					push @{$query->{$field}}, $node;
						} elsif(	($j==2)  &&
								($isrdftype) ) { # I guess also this case is impossible rdf:type to a bNode...
							my $sameas = sameAs( $sth, $node, 'class' );
							push @{$query->{$field}}, values %{$sameas};
						} else { #use any owl:sameAs mapping if there instead...
							my $sameas = sameAs( $sth, $node, 'resource' );
							push @{$query->{$field}}, values %{$sameas};
							};
					} else {
                       				push @{$query->{$field}}, $node;
						};
				} elsif($ored=~/^([^>]+)$/) {
               				$node = $sth->{'FACTORY'}->createResource($1);

					print STDERR "NODE1=",$node->toString,"\n"
						if($DBD::RDFStore::st::debug>1);

					$isrdftype=1
						if(	($j==1) &&
							($node->equals($RDFStore::Vocabulary::RDF::type)) );

					if($sth->{'SMARTER'}) {
						my $sameas;
						if($j==1) {
							$sameas = sameAs( $sth, $node, 'property' );
						} elsif(	($j==2)  &&
								($isrdftype) ) {
							$sameas = sameAs( $sth, $node, 'class' );
						} else { #use any owl:sameAs mapping if there instead...
							$sameas = sameAs( $sth, $node, 'resource' );
							};
						push @{$query->{$field}}, values %{$sameas};
					} else {
                       				push @{$query->{$field}}, $node;
						};
					};
			} split(/\s+,\s+/, $1); #hack for OR-ed nodes
               	} else {
			my $string = $tp[$j];

			my $isft=0;
			$isft=1
                        	if(     ($string =~ s/^%//) && #my free-text extensions
                              		($string =~ s/%$//) );

			my $lang=$1
				if($string =~ s/\@([a-z0-9]+(-[a-z0-9]+)?)\s*//m); #xml:lang

			# for literal or free-text remove quotes
                       	$string =~ s/^\s*["']//;
                       	$string =~ s/["']\s*$//;

                       	# free-text query part
                       	if ($isft) {
				# ok we try the clever one:
				#   1 - try to match ANDed words e.g. string1 & string2 & string3
				#   2 - otherwise try to match ORed words e.g. string1 | string2 | string3
				#   3 - otheriwse try NOTed words ~string1 ~string2 ~string3
				my @words = split /\&/, $string;
				if ( $#words > 0 ) {
					my @ww;
					map {
                               			s/^\s+//;
						s/\s+$//;
						s/['"]//;
						s/^\s*$//;
						push @{$query->{'words'}}, $_ if($_ ne '');
					} @words;
					$query->{'words_op'} = 'and';
				} else {
					@words = split /\|/, $string;
					if ( $#words > 0 ) {
						my @ww;
						map {
                               				s/^\s+//;
							s/\s+$//;
							s/['"]//;
							s/^\s*$//;
							push @{$query->{'words'}}, $_ if($_ ne '');
						} @words;
						$query->{'words_op'} = 'or';
					} else {
						@words = split /\~/, $string;
						if ( $#words > 0 ) {
							my @ww;
							map {
                               					s/^\s+//;
								s/\s+$//;
								s/['"]//;
								s/^\s*$//;
								push @{$query->{'words'}}, $_ if($_ ne '');
							} @words;
							$query->{'words_op'} = 'not';
						} else {
							push @{$query->{'words'}}, $string;
							$query->{'words_op'} = 'and'; #AND in only one word for the moment
							};
						};
					};
                       	} else {
				# to add rdf:datatype and rdf:parseType too - see SPARQL spec
                       		$node = $sth->{'FACTORY'}->createLiteral($string, undef, $lang);
                               	push @{$query->{$field}}, $node;
                               	};
                       	};
		};

	if($DBD::RDFStore::st::debug>1) {
		print STDERR "TO SEARCH:\n";
		map {
			print " $_ = ";
			if( ref($query->{ $_ }) ) {
				print join(',', map { ( ref($_) ) ? $_->toString : $_ } @{ $query->{ $_ } } );
			} else {
				print $query->{ $_ };
				};
			print "\n";
			} keys %{$query};
		};

	return $query;
	};

sub sameAs {
        my ($sth, $cp, $what) = @_;

	if($DBD::RDFStore::st::debug>1) {
		print STDERR "ALREADY THERE SAMEAS '".$cp->toString."' = '".join(',', map { $_->toString } values %{ $sth->{'cp_closure'}->{ $cp->toString } })."'\n"
			if( exists $sth->{'cp_closure'}->{ $cp->toString } );
		};

        return $sth->{'cp_closure'}->{ $cp->toString }
                if( exists $sth->{'cp_closure'}->{ $cp->toString } );

        $sth->{'cp_closure'}->{ $cp->toString } = { $cp->toString => $cp };

        _cp( $sth, $cp, $sth->{'cp_closure'}->{ $cp->toString }, $what );

	# copy the $cp owl:sameAs through to avoid to carry out them twice
	map {
		my $sa = $_;

        	$sth->{'cp_closure'}->{ $sa->toString } = { $sa->toString => $sa };
		map {
			$sth->{'cp_closure'}->{ $sa->toString }->{ $_->toString } = $_;
			} values %{ $sth->{'cp_closure'}->{ $cp->toString } };

			print STDERR ">COPIED '".$cp->toString."' SAMEAS '".$sa->toString."' = '".join(',', map { $_->toString } values %{ $sth->{'cp_closure'}->{ $sa->toString } })."'\n"
				if($DBD::RDFStore::st::debug>1);

		} values %{ $sth->{'cp_sameas'}->{ $cp->toString } };

	print STDERR "SAMEAS '".$cp->toString."' = '".join(',', map { $_->toString } values %{ $sth->{'cp_closure'}->{ $cp->toString } })."'\n"
		if($DBD::RDFStore::st::debug>1);

        return $sth->{'cp_closure'}->{ $cp->toString };
        };

sub _cp {
        my ($sth, $cp, $cc, $what) = @_;

	unless(exists $sth->{'cp_sameas'}->{ $cp->toString } ) {
		$sth->{'cp_sameas'}->{ $cp->toString } = {};

		# owl:sameAs is two ways - correct?
        	my $sameas = $sth->{'source_model'}->find( undef, $RDFStore::Vocabulary::OWL::sameAs, $cp )->elements;
        	while( my $ss = $sameas->each_subject ) {
                	next
                        	unless( $ss->isa("RDFStore::Resource") );

                	next
                        	if(	(exists $cc->{ $ss->toString }) ||
					($ss->equals($cp)) );

                	if( exists $sth->{'cp_closure'}->{ $ss->toString } ) {
				# copy the cached one
				map {
                			$cc->{ $_->toString } = $_;
					} values %{ $sth->{'cp_closure'}->{ $ss->toString } };
			} else {
                		_cp( $sth, $ss, $cc, $what );
				};

                	$cc->{ $ss->toString } = $ss;
			$sth->{'cp_sameas'}->{ $cp->toString }->{ $ss->toString } = $ss;
			};

        	$sameas = $sth->{'source_model'}->find( $cp, $RDFStore::Vocabulary::OWL::sameAs )->elements;
		while( my $ss = $sameas->each_object ) {
                	next
                        	unless( $ss->isa("RDFStore::Resource") );

                	next
                        	if(	(exists $cc->{ $ss->toString }) ||
					($ss->equals($cp)) );

                	if( exists $sth->{'cp_closure'}->{ $ss->toString } ) {
				# copy the cached one
				map {
                			$cc->{ $_->toString } = $_;
					} values %{ $sth->{'cp_closure'}->{ $ss->toString } };
			} else {
                		_cp( $sth, $ss, $cc, $what );
				};

                	$cc->{ $ss->toString } = $ss;
			$sth->{'cp_sameas'}->{ $cp->toString }->{ $ss->toString } = $ss;
			};
		};

	return
		if( $what eq 'resource' ); #just looking for resource equivalence?

        my $supercp = $sth->{'source_model'}->{'rdfstore'}->search(	{
									"p" => [ ( $what eq 'class' ) ?
											$RDFStore::Vocabulary::RDFS::subClassOf :
											$RDFStore::Vocabulary::RDFS::subPropertyOf ],
									"o" => [ $cp, values %{ $sth->{'cp_sameas'}->{ $cp->toString } } ]
									} );

        while( my $ss = $supercp->each_subject ) {
                next
                        unless( $ss->isa("RDFStore::Resource") );

                next
                        if(	(exists $cc->{ $ss->toString }) ||
				($ss->equals($cp)) );

                if( exists $sth->{'cp_closure'}->{ $ss->toString } ) {
			# copy the cached one
			map {
                		$cc->{ $_->toString } = $_;
				} values %{ $sth->{'cp_closure'}->{ $ss->toString } };
		} else {
                	_cp( $sth, $ss, $cc, $what );
			};

                $cc->{ $ss->toString } = $ss;
                };

	print STDERR "_cp '".$cp->toString."' = '".join(',', map { $_->toString } values %{ $cc })."'\n"
		if($DBD::RDFStore::st::debug>1);

        };

sub rows {
        my $sth = shift;

        #my $data = $sth->FETCH('driver_data');
        #return $#{$data}+1;

        return -1; #we do *not* want to know the number of rows affected at the moment due to efficency problems :)
};

sub _each_distinct {
        my($sth) = @_;

	#reset
	$sth->{'result'} = {};

	my $row = _each( $sth );

	if(     ( $sth->{'Statement'}->{'distinct'} ) &&
        	( exists $sth->{'previous_results'} ) &&
                ( scalar( keys %{$sth->{'previous_results'}} > 0 ) ) ) {
                # purge matched positions with SELECT DISTINCT clause
                while ( ( $row ) &&
                	(!( _distinct($sth, $row) )) ) { #got a distinct match

                       #reset current result set
                       $sth->{'result'} = {};

                       $row = _each( $sth );
                       };
		};

	return $row;
	};

sub fetchrow_arrayref {
        my($sth) = @_;

	return
		unless( $sth->{'Statement'}->getQueryType eq 'SELECT' );

	if( exists $sth->{'Statement'}->{'limit'} ) {
                return
			unless( $sth->{'total_matches'} < $sth->{'Statement'}->{'limit'} );
                };

	my $offset = $sth->{'Statement'}->{'offset'};
	$offset = 0
		unless($offset);

        my $row;

	while( 1 ) {
		# NOTE: now, this is very inefficient due is pre-fetching the whole result set to sort it out - be careful with large result sets!
		if(	$#{ $sth->{'Statement'}->{'order_by'} } >= 0 and
			$#{ $sth->{'result_cache'} } < 0 ) { # do it once
			my @all; # keep the whole result set in-memory!
        		while( my $r = _each_distinct( $sth ) ) {
				push @all, $sth->{'result'};
				};
		
			my $order = pop @{ $sth->{'Statement'}->{'order_by'} };

			# order by...
			@all = sort {
				$sth->{'ce'}->eval($sth, $sth->{'Statement'}->{'order_by'}, $a ) cmp
					$sth->{'ce'}->eval($sth, $sth->{'Statement'}->{'order_by'}, $b )
				} @all;

			@all = reverse @all
				if( $order eq 'DESC' );

			# update cache which will make _each() method to use it i.e. fake calls in this case
			@{ $sth->{'result_cache'} } = ( @all, undef ); # or more efficient \@all in cache?
			undef @all;
			};

        	$row = _each_distinct( $sth );

		last
			unless( $row and $#{$row}>=0 );

		$sth->{'total_matches'}++; #one more match

		last
			if( $sth->{'total_matches'} > $offset ); # skip matched positions upto OFFSET i.e. need to match and go through all the above anyway! ;(
		};

	$sth->{'previous_results'}->{ _result_digest( $row ) } = 1
		if($row);
	
        return undef
        	unless $row;

        return $sth->_set_fbav( $row );
};

*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref

# RDF and XML results specific methods (will be part of some RDBC some day...)

# pull methods

# return string containing the bindings XML chunk
# syntax: rdf-for-xml, dawg-xml, RDF/XML and dawg-results
sub fetchrow_XML {
        my($sth, $syntax) = @_;

	return
		unless( $sth->{'Statement'}->getQueryType eq 'SELECT' );

	return
		unless($syntax =~ m#(RDF/XML|dawg-results|rdf-for-xml|dawg-xml)#i);

	if($sth->{'RDF_or_XML_stream_finished'}) {
		$sth->{'RDF_or_XML_stream_finished'} = 0;
		return;
		};

	return _fetchrow_RDF_or_XML( $sth, $syntax );
	};

# return string containing the bindings XML document
sub fetchall_XML {
        my($sth, $syntax) = @_;

	return
		unless( $sth->{'Statement'}->getQueryType eq 'SELECT' );

	return
		unless($syntax =~ m#(RDF/XML|dawg-results|rdf-for-xml|dawg-xml)#i);

	my $XML;
	while( my $xml_match = fetchrow_XML( $sth, $syntax ) ) {
		if($XML) {
			$XML .= $xml_match;
		} else {
			$XML = $xml_match;
			};
		};

	return $XML;
	};

# return string containing the RDF subgraph matching
# syntax: RDF/XML, dawg-results or N-Triples
sub fetchsubgraph_serialize {
        my($sth, $syntax) = @_;

	return
		unless($syntax =~ m#(RDF/XML|N-Triples)#i);

	if($sth->{'RDF_or_XML_stream_finished'}) {
		$sth->{'RDF_or_XML_stream_finished'} = 0;
		return;
		};

	return _fetchrow_RDF_or_XML( $sth, $syntax );
	};

# return string containing the whole RDF graph matching
# syntax: RDF/XML, dawg-results or N-Triples
sub fetchallgraph_serialize {
        my($sth, $syntax) = @_;

	return
		unless($syntax =~ m#(RDF/XML|N-Triples)#i);

	my $RDF;
	while( my $rdf_subgraph = fetchsubgraph_serialize( $sth, $syntax ) ) {
		if($RDF) {
			$RDF .= $rdf_subgraph;
		} else {
			$RDF = $rdf_subgraph;
			};
		};

	return $RDF;
	};

# return RDFStore::Model of matching statements for i-esim iteration
sub fetchsubgraph {
        my($sth) = @_;

	if($sth->{'RDF_or_XML_stream_finished'}) {
		$sth->{'RDF_or_XML_stream_finished'} = 0;
		return;
		};

	return _fetchrow_RDF_or_XML( $sth );
	};

# fetch the whole matching graph in one call (not streaming then)
# return RDFStore::Model of matching statements
sub fetchallgraph {
        my($sth) = @_;

	my $whole_graph;
	while ( my $graph = fetchsubgraph($sth) ) {
		$whole_graph = $graph
			unless($whole_graph);
		my $e = $graph->elements;
		while(my $ss = $e->each) {
			$whole_graph->add($ss);
			};
		};

	return $whole_graph;
	};

# should be streaming
sub _fetchrow_RDF_or_XML {
        my($sth, $syntax) = @_;

	return
		if($sth->{'RDF_or_XML_stream_finished'});

	unless($syntax) {
		$syntax = $sth->{'results'}->{'syntax'}
			if(exists $sth->{'results'}->{'syntax'});
		};

	return
		unless(	(!$syntax) ||
			($syntax =~ m#(RDF/XML|N-Triples|dawg-results|rdf-for-xml|dawg-xml)#i) );

	my $result = '';

	my $mm = new RDFStore::Model; # we want streaming - that's why this...

	# DESCRIBE <URI> are done once in one single subgraph / match
	if(	( $sth->{'Statement'}->getQueryType eq 'DESCRIBE' ) &&
		( grep m/^<([^>]+)>/, @{ $sth->{'Statement'}->{'describes'} }) ) {
		foreach my $d ( @{ $sth->{'Statement'}->{'describes'} } ) {
			next
				unless($d =~ m/^<([^>]+)>/);

			$d = $1;

			my $describe = $sth->{'source_model'}->{rdfstore}->fetch_object(
				$sth->{'FACTORY'}->createResource( $d ) ); #SOURCE / context is not known in SPARQL??

			if($describe) {
				while( my $ss = $describe->each ) {
					$mm->add( $ss );
					};
				};
			};

		$sth->{'RDF_or_XML_stream_finished'} = 1; # must be reset by caller

		if($syntax =~ m#(RDF/XML|dawg-results|rdf-for-xml|dawg-xml)#i) {
			$result .= '<?xml version="1.0"?>'."\n";
			$result .= "\n<!--\n" . $sth->{'results'}->{'comment'} ."\n-->\n\n"
				if(exists $sth->{'results'}->{'comment'});
		} elsif($syntax =~ m/N-Triples/i) {
			$result .= join('# ',split(/\n/,$sth->{'results'}->{'comment'})) ."\n\n"
				if(exists $sth->{'results'}->{'comment'});
			};

		if( $syntax ) {
			$result .= $mm->serialize( undef, $syntax );

			return $result;
		} else {
			return $mm;
			};
		};

	my $first=(scalar( keys %{$sth->{'result'}} ) <= 0 ) ? 1 : 0 ;

	if($first) {
		if($syntax =~ m#(RDF/XML|dawg-results|rdf-for-xml|dawg-xml)#i) {
			$result .= '<?xml version="1.0"?>'."\n";
			$result .= "\n<!--\n" . $sth->{'results'}->{'comment'} ."\n-->\n\n"
				if(exists $sth->{'results'}->{'comment'});
		} elsif($syntax =~ m/N-Triples/i) {
			$result .= join('# ',split(/\n/,$sth->{'results'}->{'comment'})) ."\n\n"
				if(exists $sth->{'results'}->{'comment'});
			};
		if( $sth->{'Statement'}->getQueryType eq 'SELECT' ) {
			if($syntax =~ m/dawg-results/i) {
				# see http://www.w3.org/2001/sw/DataAccess/tests/result-set#
				$sth->{'num_results'}=0;
				$result .=  "<rdf:RDF\n   xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'   xmlns:rs='http://www.w3.org/2001/sw/DataAccess/tests/result-set#'>\n<rs:ResultSet rdf:about=''>\n";
				map {
					my $ff = $_;
					$ff =~ s/^[\?\$]//;
        				$result .= "      <rs:resultVariable>$ff</rs:resultVariable>\n";
				} @{ $sth->FETCH ('NAME') };
			} elsif($syntax =~ m/rdf-for-xml/i) {
				# see http://jena.hpl.hp.com/~afs/RDF-XML.html
				$sth->{'num_results'}=0;
				$result .= "<resultSet>\n";
				$result .= "   <vars>\n";
				map {
					my $ff = $_;
					$ff =~ s/^[\?\$]//;
					$result .= "      <var>$ff</var>\n";
				} @{ $sth->FETCH ('NAME') };
				$result .= "   </vars>\n";
			} elsif($syntax =~ m/dawg-xml/i) {
				# see http://www.w3.org/2001/sw/DataAccess/rf1/
				$sth->{'num_results'}=0;
				$result .= "<sparql xmlns='http://www.w3.org/2005/sparql-results#' ";
				my %pp=();
				my @val =  @{ $sth->FETCH ('NAME') };
				foreach my $vv ( @val ) {
					if( $vv =~ s/^[\?\$]([^:]+):(.*)/$1/ ) {
						$vv = '#default'
							unless(length($vv)>0);
 						if ( !exists($pp{$vv}) ) {
							$pp{$vv}=1;
							$result .= " xmlns". ( (length($vv)>0) ? ':'.$vv : '' );
							$result .= "='". ( (exists $sth->{'Statement'}->{prefixes}->{$vv}) ?
									 $sth->{'Statement'}->{prefixes}->{$vv} :
									$sth->{'Default_prefixes'}->{$vv} ) ."' ";
							};
						};
					};
				# should get the namespace out as well...
				$result .= ">\n";
				$result .= "   <head>\n";
				unless( $sth->{'Statement'}->getQueryType eq 'ASK' ) {
					map {
						my $ff = $_;
						$ff =~ s/^[\?\$]//;
						$result .= "      <variable name='$ff'/>\n";
						} @val;
					};

				# eventually add a <link href="metadata.rdf" /> element here...
				$result .= "      <link href='" . $sth->{'results'}->{'metadata'} ."' />\n"
					if(exists $sth->{'results'}->{'metadata'});

				$result .= "   </head>\n";

				# NOTE: need to add ASK query support <boolean />...

				if( $sth->{'Statement'}->getQueryType eq 'ASK' ) {
					$result .= "   <!-- <boolean> ASK queries not supported-->\n";
				} else {
					my $ordered =  ( $sth->{'Statement'}->{'ordered'} ) ? 'true' : 'false' ; # not into syntax yet
					my $distinct = ( $sth->{'Statement'}->{'distinct'} ) ? 'true' : 'false' ;
					$result .= "   <results ordered='$ordered' distinct='$distinct'>\n";
					};
				};
			};
		};

        my $row;

	unless( exists $sth->{'Statement'}->{'limit'} and
		$sth->{'total_matches'} >= $sth->{'Statement'}->{'limit'} ) {

		my $offset = $sth->{'Statement'}->{'offset'};
		$offset = 0
			unless($offset);

		while( 1 ) {
			# NOTE: now, this is very inefficient due is pre-fetching the whole result set to sort it out - be careful with large result sets!
			if(     $#{ $sth->{'Statement'}->{'order_by'} } >= 0 and
				$#{ $sth->{'result_cache'} } < 0 ) { # do it once
				my @all; # keep the whole result set in-memory!
				while( my $r = _each_distinct( $sth ) ) {
					push @all, $sth->{'result'};
					};

				my $order = pop @{ $sth->{'Statement'}->{'order_by'} };

                        	# order by...
                        	@all = sort {
                                	$sth->{'ce'}->eval($sth, $sth->{'Statement'}->{'order_by'}, $a ) cmp
                                        	$sth->{'ce'}->eval($sth, $sth->{'Statement'}->{'order_by'}, $b )
                                	} @all;

                        	@all = reverse @all
                                	if( $order eq 'DESC' );

                        	# update cache which will make _each() method to use it i.e. fake calls in this case
                        	@{ $sth->{'result_cache'} } = ( @all, undef ); # or more efficient \@all in cache?
                        	undef @all;
                        	};

			$row = _each_distinct( $sth );

			last
				unless( $row and $#{$row}>=0 );

			$sth->{'total_matches'}++; #one more match

			last
				if( $sth->{'total_matches'} > $offset ); # skip matched positions upto OFFSET 
									 # i.e. need to match and go through all the above anyway! ;(
			};
		};

	if(	$row and
		$#{$row}>=0 ) {
		if( $sth->{'Statement'}->getQueryType eq 'DESCRIBE' ) {
			foreach my $d ( @{$sth->{'Statement'}->{'describes'}} ) {
				next
					unless($d =~ m/^[\?\$]/); #DESCRIBE <URI> are managed above

				my $describe = $sth->{'source_model'}->{rdfstore}->fetch_object( $sth->{'result'}->{$d} ) #SOURCE / context is not known in SPARQL??
					if(	(defined $sth->{'result'}->{$d}) &&
						(ref($sth->{'result'}->{$d})) &&
						($sth->{'result'}->{$d}->isa("RDFStore::Resource")) ); #we use simple CBD def and literal are excluded

				if($describe) {
					while( my $ss = $describe->each ) {
						$mm->add( $ss );
						};
					};
				};

			if( $syntax ) {
				my $rdf = $mm->serialize( undef, $syntax );

				if($syntax =~ m#RDF/XML#i) {
					if(!$first) {
						$rdf =~ s|^<rdf:RDF([^>]+)>||mg;
						};
					$rdf =~ s|</rdf:RDF>$||mg;
					};
				$result .= $rdf;
			} else {
				$sth->{'previous_results'}->{ _result_digest( $row ) } = 1
					if($row);

				return $mm;
				};
		} elsif( $sth->{'Statement'}->getQueryType eq 'CONSTRUCT' ) {
			# build triples from given CONSTRUCT
			my %bnodes=();
			my $i=0;
			if( ref($sth->{'Statement'}->{'constructPatterns'}->[0]) ) {
				foreach my $tp ( @{ $sth->{'Statement'}->{'constructPatterns'} } ) {
					my ($optional, @ttpp) = @{$tp};
					# we should skip OPTIONALs I guess...
					_constructTriplepattern( $sth, $mm, \%bnodes, @ttpp );
					$i++;
					};
			} else {
				# CONSTRUCT *
				foreach my $gp ( @{ $sth->{'Statement'}->{'graphPatterns'} } ) {
                        		next
						unless( ref($gp) ); #skip AND or UNION keyword eventually
					foreach my $tp ( @{ $gp->{'triplePatterns'} } ) {
						my ($optional, @ttpp) = @{$tp};
						# we should skip OPTIONALs I guess...
						_constructTriplepattern( $sth, $mm, \%bnodes, @ttpp );
						$i++;
                                		};
                        		};
				};

			if( $syntax ) {
				my $rdf = $mm->serialize( undef, $syntax );

				if($syntax =~ m#RDF/XML#i) {
					$rdf =~ s|^<rdf:RDF([^>]+)>||mg
						unless($first);
					$rdf =~ s|</rdf:RDF>$||mg;
					};
				$result .= $rdf;
			} else {
				$sth->{'previous_results'}->{ _result_digest( $row ) } = 1
					if($row);

				return $mm;
				};
		} elsif( $sth->{'Statement'}->getQueryType eq 'SELECT' ) {
			if($syntax =~ m/dawg-results/i) {
				$sth->{'num_results'}++;
				$result .= "\n      <rs:solution rdf:parseType='Resource'>\n";
				for my $i (0..$#{$row}) {
					next
						unless($row->[$i]);

					my $ff = $sth->FETCH ('NAME')->[$i];
					$ff =~ s/^[\?\$]//;
           				$result .= "            <rs:binding rdf:parseType='Resource'>\n";
              				$result .= "               <rs:variable>$ff</rs:variable>\n";
              				$result .= "               <rs:value";
					if($row->[$i]->isa("RDFStore::Resource")) {
                        			$result .= " ";
						if ( $row->[$i]->isbNode ) {
                               				$result .= "rdf:nodeID='" . $row->[$i]->getLabel;
                        			} else {
                               				$result .= "rdf:resource='" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getURI,"'" );
                               				};
                        			$result .= "' />\n";
                			} else {
                        			$result .= " xml:lang='" . $row->[$i]->getLang . "'"
							if($row->[$i]->getLang);
						$result .= " rdf:datatype='" . $row->[$i]->getDataType . "'"
                               				if($row->[$i]->getDataType);
						if($row->[$i]->getParseType) {
							$result .= " rdf:parseType='Literal'>";
                               				$result .= $row->[$i]->getLabel;
						} else {
							$result .= ">" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getLabel );
							};
                        			$result .= "</rs:value>\n";
                        			};
					$result .= "            </rs:binding>\n";
					};
				$result .= "\n      </rs:solution>\n";
			} elsif($syntax =~ m/rdf-for-xml/i) {
				my $missed=0;
				my $first=0;
				for my $i (0..$#{$row}) {
					unless($row->[$i]) {
						$missed++;
						next;
						};

					unless($first) {
						$result .= "   <solution>\n";
						$first=1;
						};

					my $ff = $sth->FETCH ('NAME')->[$i];
					$ff =~ s/^[\?\$]//;
           				$result .= "      <binding>\n";
              				$result .= "         <var>$ff</var>\n";
					if($row->[$i]->isa("RDFStore::Resource")) {
						if ( $row->[$i]->isbNode ) {
              						$result .= "         <bNode>". $row->[$i]->getLabel ."</bNode>\n";
                        			} else {
              						$result .= "         <uri>".$DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getURI )."</uri>\n";
                               				};
                			} else {
              					$result .= "         <value";
                        			$result .= " xml:lang='" . $row->[$i]->getLang . "'"
							if($row->[$i]->getLang);
						# no clue how to do this - probably we should have a full blown XSD namespace declared???
						$result .= " xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:type='" . $row->[$i]->getDataType . "'"
                               				if($row->[$i]->getDataType);
						if($row->[$i]->getParseType) {
							$result .= ">";
                               				$result .= $row->[$i]->getLabel;
						} else {
							$result .= ">" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getLabel );
							};
                        			$result .= "</value>\n";
                        			};
           				$result .= "      </binding>\n";
					};

				unless($missed==($#{$row}+1)) {
					$result .= "   </solution>\n";
					$sth->{'num_results'}++;
					};
			} elsif($syntax =~ m/dawg-xml/i) {
				my $missed=0;
				my $first=0;
				for my $i (0..$#{$row}) {
					unless($first) {
						$result .= "   <result>\n";
						$first=1;
						};

					my $ff = $sth->FETCH ('NAME')->[$i];
					$ff =~ s/^[\?\$]//;

              				$result .= "         <binding name='$ff'>\n";

					unless($row->[$i]) {
              					$result .= "               <unbound/>\n";
              					$result .= "         </binding>\\nn";
						$missed++;
						next;
						};

					if($row->[$i]->isa("RDFStore::Resource")) {
						if ( $row->[$i]->isbNode ) {
              						$result .= "               <bnode>". $row->[$i]->getLabel ."</bnode>\n";
                        			} else {
              						$result .= "               <uri>".$DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getURI )."</uri>\n";
                               				};
                			} else {
              					$result .= "               <literal";
                        			$result .= " xml:lang='" . $row->[$i]->getLang . "'"
							if($row->[$i]->getLang);
						# no clue how to do this - probably we should have a full blown XSD namespace declared???
						$result .= " datatype='" . $row->[$i]->getDataType . "'"
                               				if($row->[$i]->getDataType);
						if($row->[$i]->getParseType) {
							$result .= ">";
                               				$result .= $row->[$i]->getLabel;
						} else {
							$result .= ">" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getLabel );
							};
                        			$result .= "</literal>\n";
                        			};

              				$result .= "         </binding>\n";
					};

				unless($missed==($#{$row}+1)) {
					$result .= "   </result>\n";
					$sth->{'num_results'}++;
					};
			} else {
				# like CONSTRUCT * but considering only triple-patterns containing requested vars (or all if '*')
				my %bnodes=();
				my $i=0;
				foreach my $gp ( @{ $sth->{'Statement'}->{'graphPatterns'} } ) {
                                        next
						unless( ref($gp) ); #skip AND or UNION keyword eventually
					foreach my $tp ( @{ $gp->{'triplePatterns'} } ) {
                				my %vars;
                				@vars{ grep /^([\?\$].+)$/, @{ $tp } } = ();
						my $skip = 1;
						foreach my $var ( keys %vars ) {
							if( grep /^$var$/, @{ $sth->FETCH ('NAME') } ) {
								$skip = 0;
								last;
								};
							};
						if($skip) {
							$i++;
							next;
							};

						my ($optional, @ttpp) = @{$tp};
						_constructTriplepattern( $sth, $mm, \%bnodes, @ttpp );
						$i++;
                        			};
					};

                        	if( $syntax ) {
                                	my $rdf = $mm->serialize( undef, $syntax );

                                	if($syntax =~ m#RDF/XML#i) {
                                        	$rdf =~ s|^<rdf:RDF([^>]+)>||mg
                                               		unless($first);
                                        	$rdf =~ s|</rdf:RDF>$||mg;
                                        	};
                                	$result .= $rdf;
				} else {
					$sth->{'previous_results'}->{ _result_digest( $row ) } = 1
						if($row);

					return $mm;
                                	};
				};
		} elsif( $sth->{'Statement'}->getQueryType eq 'DELETE' ) {
			# like CONSTRUCT * but considering only triple-patterns containing requested vars (or all if '*')
			my %bnodes=();
			my $i=0;
			foreach my $gp ( @{ $sth->{'Statement'}->{'graphPatterns'} } ) {
                        	next
					unless( ref($gp) ); #skip AND or UNION keyword eventually
				foreach my $tp ( @{ $gp->{'triplePatterns'} } ) {
                			my %vars;
                			@vars{ grep /^([\?\$].+)$/, @{ $tp } } = ();
					my $skip = 1;
					foreach my $var ( keys %vars ) {
						if( grep /^$var$/, @{ $sth->FETCH ('NAME') } ) {
							$skip = 0;
							last;
							};
						};
					if($skip) {
						$i++;
						next;
						};

					my ($optional, @ttpp) = @{$tp};
					_constructTriplepattern( $sth, $mm, \%bnodes, @ttpp );
					$i++;
                       			};
				};
	
			# zap each matched statement from source
			my $eles = $mm->elements;
			while( my $st = $eles->each ) {
				unless($sth->{'source_model'}->remove( $st )) {
					$sth->DBI::set_err( 1, "Cannot DELETE triple ". $st->toString );
                                	return undef;
                                	};
				};

                        if( $syntax ) {
                               	my $rdf = $mm->serialize( undef, $syntax );

                               	if($syntax =~ m#RDF/XML#i) {
                                       	$rdf =~ s|^<rdf:RDF([^>]+)>||mg
                                      		unless($first);
                                       	$rdf =~ s|</rdf:RDF>$||mg;
                                       	};
                               	$result .= $rdf;
			} else {
				$sth->{'previous_results'}->{ _result_digest( $row ) } = 1
					if($row);

				return $mm;
                               	};
			};
	} else {
		if( $sth->{'Statement'}->getQueryType eq 'SELECT' ) {
			if($syntax =~ m/rdf-for-xml/i) {
				$result .= "</resultSet>\n";
			} elsif($syntax =~ m/dawg-results/i) {
				$result .= "</rs:ResultSet>\n</rdf:RDF>\n";
			} elsif($syntax =~ m/dawg-xml/i) {
				if( $sth->{'Statement'}->getQueryType eq 'ASK' ) {
					$result .= "   <!-- </boolean> ASK queries not supported-->\n";
				} else {
					$result .= "   </results>\n";
					};
				$result .= "</sparql>\n";
			} else {
				if($syntax =~ m#RDF/XML#i) {
					if(	( exists $sth->{'previous_results'} ) &&
						( scalar( keys %{$sth->{'previous_results'}} > 0 ) ) ) {
						$result .= '</rdf:RDF>';
					} else {
						$result .= $mm->serialize( undef, $syntax );
						};
					};
				};
		} else {
			if($syntax =~ m#RDF/XML#i) {
				if(	( exists $sth->{'previous_results'} ) &&
					( scalar( keys %{$sth->{'previous_results'}} > 0 ) ) ) {
					$result .= '</rdf:RDF>';
				} else {
					$result .= $mm->serialize( undef, $syntax );
					};
				};
			};

		$sth->{'RDF_or_XML_stream_finished'} = 1; # must be reset by caller
		};

	$sth->{'previous_results'}->{ _result_digest( $row ) } = 1
		if($row);

	return $result;
	};

sub _constructTriplepattern {
	my ($sth, $model, $bnodes, @tp) = @_;

print STDERR "_constructTriplepattern TP=".join(',', @tp)."\n" if($DBD::RDFStore::st::debug>1);

        my $node;
	my @quad = ( [], [], [], [] );
        for my $j ( 0..$#tp ) {
		if($tp[$j]=~/^([\?\$].+)$/) {
			my $var = $1;
			if(exists $sth->{'result'}->{$var}) {
				return
					if(	($j<3) &&
						(! defined $sth->{'result'}->{$var}) ); #OPTIONALs if not at 4th postion are skipeed of course
				# fetch var
                   		push @{$quad[$j]}, $sth->{'result'}->{$var};
			} else {
				# or create bNode
				$bnodes->{ $var } = $sth->{'FACTORY'}->createbNode
					unless( exists $bnodes->{ $var } );
                   		push @{$quad[$j]}, $bnodes->{ $var };
				};
                } elsif($tp[$j]=~/^<(([^\:]+)\:{1,2}([^>]+))>$/) {
			map {
				my $ored=$_;
                		if($ored=~/^(([^\:]+)\:{1,2}(.*))$/) {
					if($ored=~/^_:([A-Za-z][A-Za-z0-9_\-\.]*)$/) {
                               			$node = $sth->{'FACTORY'}->createAnonymousResource($1);
                        		} elsif(	(defined $2) &&
                        				(	(exists $sth->{'Statement'}->{prefixes}->{$2}) ||
								(exists $sth->{'Default_prefixes'}->{$2}) ) ) {
                                		$node = $sth->{'FACTORY'}->createResource(
						(exists $sth->{'Statement'}->{prefixes}->{$2}) ? 
							$sth->{'Statement'}->{prefixes}->{$2} : 
							$sth->{'Default_prefixes'}->{$2} ,$3);
                        		} else {
                        			#no namespace set - see RDFStore::Resource
                               			$node = $sth->{'FACTORY'}->createResource($1);
                                		};
                   			push @{$quad[$j]}, $node;
					};
			} split(/\s+,\s+/, $1); #hack for OR-ed nodes
                } elsif($tp[$j]=~/^<([^>]+)>$/) {
			map {
				my $ored=$_;
				my $lang=$1
					if($ored =~ s/\@([a-z0-9]+(-[a-z0-9]+)?)\s*$//m); #xml:lang

				if(	($ored=~ s/^\s*["']//) &&
					($ored=~ s/["']\s*$//) ) {
					# to add rdf:datatype and rdf:parseType too - see SPARQL spec
                        		$node = $sth->{'FACTORY'}->createLiteral($ored, undef, $lang);

                   			push @{$quad[$j]}, $node;
				} elsif($ored=~/^_:([A-Za-z][A-Za-z0-9_\-\.]*)$/) {
                        		#bNode joining in
                               		$node = $sth->{'FACTORY'}->createAnonymousResource($1);

                   			push @{$quad[$j]}, $node;
				} elsif($ored=~/^([^>]+)$/) {
                			$node = $sth->{'FACTORY'}->createResource($1);

                   			push @{$quad[$j]}, $node;
					};
			} split(/\s+,\s+/, $1); #hack for OR-ed nodes
                } else {
			my $string = $tp[$j];

			my $isft=0;
			$isft=1
                               	if(     ($string =~ s/^%//) && #my free-text extensions
                               		($string =~ s/%$//) );

			my $lang=$1
				if($string =~ s/\@([a-z0-9]+(-[a-z0-9]+)?)\s*//m); #xml:lang

			# for literal or free-text remove quotes
                        $string =~ s/^\s*["']//;
                        $string =~ s/["']\s*$//;

                        # free-text query part
                        if ($isft) {
				return;
                        } else {
				# to add rdf:datatype and rdf:parseType too - see SPARQL spec
                        	$node = $sth->{'FACTORY'}->createLiteral($string, undef, $lang);
                   		push @{$quad[$j]}, $node;
                                };
                        };
		};

	for my $s ( @{$quad[0]} ) {
		for my $p ( @{$quad[1]} ) {
			for my $o ( @{$quad[2]} ) {
				if( $#{$quad[3]} >= 0 ) {
					for my $c ( @{$quad[3]} ) {
						my $st = $sth->{'FACTORY'}->createStatement( $s, $p, $o, $c );
						$model->add( $st );
						};
				} else {
					my $st = $sth->{'FACTORY'}->createStatement( $s, $p, $o );
					$model->add( $st );
					};
				};
			};
		};

	return 1;
	};

sub FETCH {
	my $sth = shift;
        my $key = shift;

	return $sth->{NAME} if $key eq 'NAME';

	return $sth->SUPER::FETCH($key);
	};

sub STORE {
	my $sth = shift;
        my ($key, $value) = @_;

	if ($key eq 'NAME') {
        	$sth->{NAME} = $value;
                return 1;
        	};

	return $sth->SUPER::STORE($key, $value);
	};

sub DESTROY {
};

1;

__END__

=head1 NAME

DBD::RDFStore - Simple DBI driver for RDFStore using RDQL:Parser

=head1 SYNOPSIS

	use DBI;

	# on the local disk
	$dbh = DBI->connect( "DBI:rdfstore:database=cooltest", "user", "password" );

	# on a remote dbmsd(8) server
	$dbh = DBI->connect( "DBI:rdfstore:database=cooltest;host=localhost;port=1234", "user", "password" );

	# or in the fly
	$dbh = DBI->connect( "DBI:rdfstore", "user", "password" );

	$sth = $dbh->prepare(<<QUERY);

	SELECT
           ?title, ?link
        FROM
           <http://xmlhack.com/rss10.php>
        WHERE
           (?item, <rdf:type>, <rss:item>),
           (?item, <rss::title>, ?title),
           (?item, <rss::link>, ?link)
        USING
           rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
           rss for <http://purl.org/rss/1.0/>

	QUERY;

	my $num_rows = $sth->execute();

	print "news from XMLhack.com\n" if($num_rows == $sth->rows);

	$sth->bind_columns(\$title, \$link);

	while ($sth->fetch()) {
		print "title=$title lin=$link\n";
		};
	$sth->finish();

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

DBI(3) RDQL::Parser(3) RDFStore(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

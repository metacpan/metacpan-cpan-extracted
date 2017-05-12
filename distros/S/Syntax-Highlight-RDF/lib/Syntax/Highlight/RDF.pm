package Syntax::Highlight::RDF;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$Syntax::Highlight::RDF::AUTHORITY = 'cpan:TOBYINK';
	$Syntax::Highlight::RDF::VERSION   = '0.003';
}

use MooX::Struct -retain, -rw,
	Feature                   => [],
	Token                     => [-extends => [qw<Feature>], qw($spelling!)],
	Comment                   => [-extends => [qw<Token>]],
	Brace                     => [-extends => [qw<Token>]],
	Bracket                   => [-extends => [qw<Token>]],
	Parenthesis               => [-extends => [qw<Token>]],
	Datatype                  => [-extends => [qw<Token>]],
	AtRule                    => [-extends => [qw<Token>]],
	Shorthand                 => [-extends => [qw<Token>]],
	BNode                     => [-extends => [qw<Token>]],
	Variable                  => [-extends => [qw<Token>]],
	Number                    => [-extends => [qw<Token>]],
	Number_Double             => [-extends => [qw<Number>]],
	Number_Decimal            => [-extends => [qw<Number>]],
	Number_Integer            => [-extends => [qw<Number>]],
	Punctuation               => [-extends => [qw<Token>]],
	Path                      => [-extends => [qw<Token>]],
	Boolean                   => [-extends => [qw<Token>]],
	Sparql                    => [-extends => [qw<Token>]],
	Sparql_Keyword            => [-extends => [qw<Sparql>]],
	Sparql_Operator           => [-extends => [qw<Sparql>]],
	Sparql_Function           => [-extends => [qw<Sparql>]],
	Sparql_Aggregate          => [-extends => [qw<Sparql_Function>]],
	Sparql_Ordering           => [-extends => [qw<Sparql_Function>]],
	IsOf                      => [-extends => [qw<Token>]],
	Language                  => [-extends => [qw<Token>]],
	Unknown                   => [-extends => [qw<Token>]],
	Whitespace                => [-extends => [qw<Token>]],
	Name                      => [-extends => [qw<Token>]],
	URIRef                    => [-extends => [qw<Token>], qw($absolute_uri)],
	CURIE                     => [-extends => [qw<Token>], qw($absolute_uri)],
	String                    => [-extends => [qw<Token>], qw($quote_char $parts $language)],
	LongString                => [-extends => [qw<String>]],
	ShortString               => [-extends => [qw<String>]],
	Structure_Start           => [-extends => [qw<Feature>], qw($end)],
	Structure_End             => [-extends => [qw<Feature>], q($start) => [weak_ref => 1]],
	PrefixDefinition_Start    => [-extends => [qw<Structure_Start>], qw($prefix $absolute_uri)],
	PrefixDefinition_End      => [-extends => [qw<Structure_End>]],
	Pretdsl                   => [-extends => [qw<Token>]],
	Pretdsl_Perl_Dist         => [-extends => [qw<Pretdsl>]],
	Pretdsl_Perl_Release      => [-extends => [qw<Pretdsl>]],
	Pretdsl_Perl_File         => [-extends => [qw<Pretdsl>]],
	Pretdsl_Perl_Module       => [-extends => [qw<Pretdsl>]],
	Pretdsl_Perl_Package      => [-extends => [qw<Pretdsl>]],
	Pretdsl_RT                => [-extends => [qw<Pretdsl>]],
	Pretdsl_CPANID            => [-extends => [qw<Pretdsl>]],
	Pretdsl_Date              => [-extends => [qw<Pretdsl>]],
	Pretdsl_DateTime          => [-extends => [qw<Pretdsl>]],
	Pretdsl_Keyword           => [-extends => [qw<Pretdsl>], qw($absolute_uri)],
;

use Throwable::Factory
	Tokenization              => [qw( $remaining -caller )],
	NotImplemented            => [qw( -notimplemented )],
	WTF                       => [],
	WrongInvocant             => [qw( -caller )],
;

{
	use HTML::HTML5::Entities qw/encode_entities/;
	no strict 'refs';
	
	my $unescape = sub
	{
		my $u = $_[0];
		$u =~ s{
			(  \\  ([\\nrt"]|U[A-Fa-f0-9]{8}|u[A-Fa-f0-9]{4})  )
		}{
			$2 eq "\\"    ? "\\" :
			$2 eq "n"     ? "\n" :
			$2 eq "r"     ? "\r" :
			$2 eq "t"     ? "\t" :
			$2 eq '"'     ? "\"" :
			chr hex("0x".substr($2, 1))
		}exg;
		return $u;
	};
	
	*{Feature    . "::tok"}        = sub { sprintf "%s~", $_[0]->TYPE };
	*{Token      . "::tok"}        = sub { sprintf "%s[%s]", $_[0]->TYPE, $_[0]->spelling };
	*{Whitespace . "::tok"}        = sub { $_[0]->TYPE };
	*{Feature    . "::TO_STRING"}  = sub { "" };
	*{Token      . "::TO_STRING"}  = sub { $_[0]->spelling };
	*{Token      . "::TO_HTML"}    = sub {
		sprintf "<span class=\"rdf_%s\">%s</span>", lc $_[0]->TYPE, encode_entities($_[0]->spelling)
	};
	*{Whitespace . "::TO_HTML"}  = sub { $_[0]->spelling };
	*{URIRef     . "::uri"}      = sub { my $u = $_[0]->spelling; $unescape->(substr $u, 1, length($u)-2) };
	*{CURIE      . "::prefix"}   = sub { (split ":", $_[0]->spelling)[0] };
	*{CURIE      . "::suffix"}   = sub { (split ":", $_[0]->spelling)[1] };
	*{PrefixDefinition_Start . "::tok"} = sub {
		sprintf '%s{prefix:"%s",uri:"%s"}', $_[0]->TYPE, $_[0]->prefix, $_[0]->absolute_uri;
	};
	*{PrefixDefinition_End . "::tok"} = sub {
		sprintf '%s{prefix:"%s",uri:"%s"}', $_[0]->TYPE, $_[0]->start->prefix, $_[0]->start->absolute_uri;
	};
	*{CURIE      . "::tok"} = sub {
		sprintf '%s[%s]{uri:"%s"}', $_[0]->TYPE, $_[0]->spelling, $_[0]->absolute_uri//"???";
	};
	*{URIRef     . "::tok"} = sub {
		sprintf '%s[%s]{uri:"%s"}', $_[0]->TYPE, $_[0]->spelling, $_[0]->absolute_uri//"???";
	};
	*{Structure_Start . "::TO_HTML"} = sub {
		my @attrs = sprintf 'class="rdf_%s"', lc $_[0]->TYPE;
		sprintf "<span %s>", join " ", @attrs;
	};
	*{Structure_End . "::TO_HTML"} = sub {
		"</span>"
	};
	*{PrefixDefinition_Start . "::TO_HTML"} = sub {
		my @attrs = sprintf 'class="rdf_%s"', lc $_[0]->TYPE;
		push @attrs, sprintf 'data-rdf-prefix="%s"', encode_entities($_[0]->prefix) if defined $_[0]->prefix;
		push @attrs, sprintf 'data-rdf-uri="%s"', encode_entities($_[0]->absolute_uri) if defined $_[0]->absolute_uri;
		sprintf "<span %s>", join " ", @attrs;
	};
	*{CURIE . "::TO_HTML"} = sub {
		my @attrs = sprintf 'class="rdf_%s"', lc $_[0]->TYPE;
		push @attrs, sprintf 'data-rdf-prefix="%s"', encode_entities($_[0]->prefix) if defined $_[0]->prefix;
		push @attrs, sprintf 'data-rdf-suffix="%s"', encode_entities($_[0]->suffix) if defined $_[0]->suffix;
		push @attrs, sprintf 'data-rdf-uri="%s"', encode_entities($_[0]->absolute_uri) if defined $_[0]->absolute_uri;
		sprintf "<span %s>%s</span>", join(" ", @attrs), encode_entities($_[0]->spelling)
	};
	*{URIRef . "::TO_HTML"} = sub {
		my @attrs = sprintf 'class="rdf_%s"', lc $_[0]->TYPE;
		push @attrs, sprintf 'data-rdf-uri="%s"', encode_entities($_[0]->absolute_uri) if defined $_[0]->absolute_uri;
		sprintf "<span %s>%s</span>", join(" ", @attrs), encode_entities($_[0]->spelling)
	};
	*{Pretdsl_Keyword . "::TO_HTML"} = sub {
		my @attrs = sprintf 'class="rdf_%s"', lc $_[0]->TYPE;
		push @attrs, sprintf 'data-rdf-uri="%s"', encode_entities($_[0]->absolute_uri) if defined $_[0]->absolute_uri;
		sprintf "<span %s>%s</span>", join(" ", @attrs), encode_entities($_[0]->spelling)
	};
}

our %STYLE = (
	rdf_brace       => 'color:#990000;font-weight:bold',
	rdf_bracket     => 'color:#990000;font-weight:bold',
	rdf_parenthesis => 'color:#990000;font-weight:bold',
	rdf_punctuation => 'color:#990000;font-weight:bold',
	rdf_datatype    => 'color:#990000;font-weight:bold',
	rdf_atrule      => 'color:#000000;font-weight:bold',
	rdf_comment     => 'color:#669933;font-style:italic',
	rdf_isof        => 'color:#000099;font-style:italic',
	rdf_sparql_keyword    => 'color:#000000;font-weight:bold;font-style:italic',
	rdf_sparql_operator   => 'color:#000000;font-weight:bold;font-style:italic',
	rdf_sparql_function   => 'color:#000000;font-weight:bold;font-style:italic',
	rdf_sparql_aggregate  => 'color:#000000;font-weight:bold;font-style:italic',
	rdf_sparql_ordering   => 'color:#000000;font-weight:bold;font-style:italic',
	rdf_unknown     => 'color:#ffff00;background-color:#660000;font-weight:bold',
	rdf_uriref      => 'color:#0000cc',
	rdf_curie       => 'color:#000099;font-weight:bold',
	rdf_bnode       => 'color:#009900;font-weight:bold',
	rdf_shorthand   => 'color:#000099;font-weight:bold;font-style:italic',
	rdf_variable    => 'color:#009900;font-weight:bold;font-style:italic',
	rdf_shortstring => 'color:#cc00cc',
	rdf_longstring  => 'color:#cc00cc;background-color:#ffddff;font-style:italic',
	rdf_language    => 'color:#ff0000',
	rdf_number_double     => 'color:#cc00cc;font-weight:bold',
	rdf_number_decimal    => 'color:#cc00cc;font-weight:bold',
	rdf_number_integer    => 'color:#cc00cc;font-weight:bold',
	rdf_boolean     => 'color:#cc00cc;font-weight:bold;font-style:italic',
	rdf_path        => 'color:#000099;background-color:#99ffff;font-weight:bold',
	rdf_name        => 'color:#000099;background-color:#ffff99;font-weight:bold',
	rdf_pretdsl_perl_dist       => 'color:white;background:#FF9900;font-weight:bold',
	rdf_pretdsl_perl_release    => 'color:white;background:#FF6666;font-weight:bold',
	rdf_pretdsl_perl_file       => 'color:white;background:#00ff66;font-weight:bold',
	rdf_pretdsl_perl_module     => 'color:white;background:#00ff66;font-weight:bold',
	rdf_pretdsl_perl_package    => 'color:white;background:#000099;font-weight:bold',
	rdf_pretdsl_rt              => 'color:white;background:#990000;font-weight:bold',
	rdf_pretdsl_cpanid          => 'color:white;background:#009900;font-weight:bold',
	rdf_pretdsl_date            => 'color:#cc00cc;font-style:italic',
	rdf_pretdsl_datetime        => 'color:#cc00cc;font-style:italic',
	rdf_pretdsl_keyword         => 'color:#000099;font-weight:bold;font-style:italic',
);

use Moo;

use IO::Detect qw( as_filehandle );
use Scalar::Util qw( blessed );

use constant {
	MODE_NTRIPLES       => 0,
	MODE_TURTLE         => 1,
	MODE_NOTATION_3     => 2,
	MODE_SPARQL         => 4,
	MODE_PRETDSL        => 8,
	MODE_TRIG           => 16,
};

use constant mode => (MODE_NTRIPLES | MODE_TURTLE | MODE_NOTATION_3 | MODE_SPARQL | MODE_PRETDSL | MODE_TRIG);

has _remaining => (is => "rw");
has _tokens    => (is => "rw");

my ($nameStartChar, $nameStartChar2, $nameChar);
{
	no warnings "utf8";
	$nameStartChar  = qr{A-Za-z_\x{00C0}-\x{00D6}\x{00D8}-\x{00F6}\x{00F8}-\x{02FF}\x{0370}-\x{037D}\x{037F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}};
	$nameStartChar2 = qr{A-Za-yz\x{00C0}-\x{00D6}\x{00D8}-\x{00F6}\x{00F8}-\x{02FF}\x{0370}-\x{037D}\x{037F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}};
	$nameChar       = qr{A-Za-z_\x{00C0}-\x{00D6}\x{00D8}-\x{00F6}\x{00F8}-\x{037D}\x{037F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}\x{00B7}\x{203F}\x{2040}0-9-};
}

our @sparqlQueryWord = qw(
	BASE
	PREFIX
	SELECT
	DISTINCT
	REDUCED
	AS
	CONSTRUCT
	WHERE
	DESCRIBE
	ASK
	FROM
	NAMED
	GROUP__BY
	HAVING
	ORDER__BY
	LIMIT
	OFFSET
	VALUES
	DEFAULT
	ALL
	OPTIONAL
	SERVICE
	BIND
	UNDEF
	MINUS
	FILTER
);

our @sparqlUpdateWord = qw(
	LOAD
	SILENT
	INTO
	CLEAR
	DROP
	CREATE
	ADD
	MOVE
	COPY
	INSERT__DATA
	DELETE__DATA
	DELETE__WHERE
	DELETE
	INSERT
	USING
);

our @sparqlOperator = qw(
	||
	&&
	=
	!=
	<
	>
	<=
	>=
	NOT__IN
	NOT
	IN
	+
	-
	*
	/
	!
);

our @sparqlFunction = qw(
	STR
	LANG
	LANGMATCHES
	DATATYPE
	BOUND
	IRI
	URI
	BNODE
	RAND
	ABS
	CEIL
	FLOOR
	ROUND
	CONCAT
	STRLEN
	UCASE
	LCASE
	ENCODE_FOR_URI
	CONTAINS
	STRSTARTS
	STRENDS
	STRBEFORE
	STRAFTER
	YEAR
	MONTH
	DAY
	HOURS
	MINUTES
	SECONDS
	TIMEZONE
	TZ
	NOW
	UUID
	STRUUID
	MD5
	SHA1
	SHA256
	SHA384
	SHA512
	COALESCE
	IF
	STRLANG
	STRDT
	sameTerm
	isIRI
	isURI
	isBLANK
	isLITERAL
	isNUMERIC
	REGEX
	SUBSTR
	REPLACE
	NOT__EXISTS
	EXISTS
);

our @sparqlAggregate = qw(
	COUNT
	SUM
	MIN
	MAX
	AVG
	SAMPLE
	GROUP_CONCAT
);

our @sparqlOrdering = qw(
	ASC
	DESC
);

our %pretdslKeywords = (
	label   =>  "http://www.w3.org/2000/01/rdf-schema#label",
	comment   =>  "http://www.w3.org/2000/01/rdf-schema#comment",
	seealso   =>  "http://www.w3.org/2000/01/rdf-schema#seeAlso",
	abstract_from   =>  "http://purl.org/NET/cpan-uri/terms#abstract_from",
	author_from   =>  "http://purl.org/NET/cpan-uri/terms#author_from",
	license_from   =>  "http://purl.org/NET/cpan-uri/terms#license_from",
	requires_from   =>  "http://purl.org/NET/cpan-uri/terms#requires_from",
	perl_version_from   =>  "http://purl.org/NET/cpan-uri/terms#perl_version_from",
	version_from   =>  "http://purl.org/NET/cpan-uri/terms#version_from",
	readme_from   =>  "http://purl.org/NET/cpan-uri/terms#readme_from",
	no_index   =>  "http://purl.org/NET/cpan-uri/terms#no_index",
	install_script   =>  "http://purl.org/NET/cpan-uri/terms#install_script",
	requires   =>  "http://purl.org/NET/cpan-uri/terms#requires",
	requires_external_bin   =>  "http://purl.org/NET/cpan-uri/terms#requires_external_bin",
	recommends   =>  "http://purl.org/NET/cpan-uri/terms#recommends",
	test_requires   =>  "http://purl.org/NET/cpan-uri/terms#test_requires",
	configure_requires   =>  "http://purl.org/NET/cpan-uri/terms#configure_requires",
	build_requires   =>  "http://purl.org/NET/cpan-uri/terms#build_requires",
	provides   =>  "http://purl.org/NET/cpan-uri/terms#provides",
	issued   =>  "http://purl.org/NET/dc/terms/issued",
	changeset   =>  "http://ontologi.es/doap-changeset#changeset",
	item   =>  "http://ontologi.es/doap-changeset#item",
	versus   =>  "http://ontologi.es/doap-changeset#versus",
	Addition   =>  "http://ontologi.es/pretdsl#dt/Addition",
	Bugfix   =>  "http://ontologi.es/pretdsl#dt/Bugfix",
	Change   =>  "http://ontologi.es/pretdsl#dt/Change",
	Documentation   =>  "http://ontologi.es/pretdsl#dt/Documentation",
	Packaging   =>  "http://ontologi.es/pretdsl#dt/Packaging",
	Regresion   =>  "http://ontologi.es/pretdsl#dt/Regression",
	Removal   =>  "http://ontologi.es/pretdsl#dt/Removal",
	SecurityFix   =>  "http://ontologi.es/pretdsl#dt/SecurityFix",
	SecurityRegression   =>  "http://ontologi.es/pretdsl#dt/SecurityRegression",
	Update   =>  "http://ontologi.es/pretdsl#dt/Update",
);

sub _peek
{
	my $self = shift;
	my ($regexp) = @_;
	$regexp = qr{^(\Q$regexp\E)} unless ref $regexp;
	
	if (my @m = (${$self->_remaining} =~ $regexp))
	{
		return \@m;
	}
	
	return;
}

sub _pull_token
{
	my $self = shift;
	my ($spelling, $class, %more) = @_;
	defined $spelling or WTF->throw("Tried to pull undef token!");
	substr(${$self->_remaining}, 0, length $spelling, "");
	push @{$self->_tokens}, $class->new(spelling => $spelling, %more);
}

sub _pull_bnode
{
	my $self = shift;
	${$self->_remaining} =~ m/^(_:[$nameStartChar][$nameChar]*)/
		? $self->_pull_token($1, BNode)
		: $self->_pull("_:", BNode)
}

sub _pull_variable
{
	my $self = shift;
	${$self->_remaining} =~ m/^([\?\$][$nameStartChar][$nameChar]*)/
		? $self->_pull_token($1, Variable)
		: $self->_pull(substr(${$self->_remaining}, 0, 1), Variable)
}

sub _pull_whitespace
{
	my $self = shift;
	$self->_pull_token($1, Whitespace)
		if ${$self->_remaining} =~ m/^(\s*)/sm;
}

sub _pull_uri
{
	my $self = shift;
	return $self->_pull_token($1, URIRef)
		if ${$self->_remaining} =~ m/^(<(?:\\\\|\\.|[^<>\\]){0,1024}>)/;
	$self->_pull_token("<", Unknown);
}

sub _pull_curie
{
	my $self = shift;
	return $self->_pull_token($1, CURIE)
		if ${$self->_remaining} =~ m/^(([$nameStartChar2][$nameChar]*)?:([$nameStartChar2][$nameChar]*)?)/;
	$self->_pull_token(substr(${$self->_remaining}, 0, 1), Unknown);
}

# Same rules as RDF::TrineX::Parser::Pretdsl
sub _pull_pretdsl
{
	my $self = shift;
	my ($spelling) = @_;
	
	$spelling =~ /^d/ and return $self->_pull_token($spelling, Pretdsl_Perl_Dist);
	$spelling =~ /^r/ and return $self->_pull_token($spelling, Pretdsl_Perl_Release);
	$spelling =~ /^m/ and return $self->_pull_token($spelling, Pretdsl_Perl_Module);
	$spelling =~ /^f/ and return $self->_pull_token($spelling, Pretdsl_Perl_File);
	$spelling =~ /^p/ and return $self->_pull_token($spelling, Pretdsl_Perl_Package);
	
	my ($x, $v) = split /\s+/, substr($spelling, 1, length($spelling)-2);
	$spelling =~ m{::} and return $self->_pull_token($spelling, Pretdsl_Perl_Module);
	$spelling =~ m{/}  and return $self->_pull_token($spelling, Pretdsl_Perl_File);
	length($v)         and return $self->_pull_token($spelling, Pretdsl_Perl_Release);
	
	return $self->_pull_token($spelling, Pretdsl_Perl_Dist);
}

# XXX - this is probably too naive
sub _pull_shortstring
{
	my $self = shift;
	my $quote_char = substr(${$self->_remaining}, 0, 1);
	$self->_pull_token($1, ShortString, quote_char => $quote_char)
		if ${$self->_remaining} =~ m/^($quote_char(?:\\\\|\\.|[^$quote_char])*?$quote_char)/;
}

# XXX - this is probably too naive
sub _pull_longstring
{
	my $self = shift;
	my $quote_char = substr(${$self->_remaining}, 0, 1);
	$self->_pull_token($1, LongString, quote_char => $quote_char)
		if ${$self->_remaining} =~ m/^($quote_char{3}.*?$quote_char{3})/ms;
}

sub _scalarref
{
	my $self = shift;
	my ($thing) = @_;
	
	if (blessed $thing and $thing->isa("RDF::Trine::Model") and $self->can("_serializer"))
	{
		my $t = $self->_serializer->new->serialize_model_to_string($thing);
		$thing = \$t
	}
	
	if (blessed $thing and $thing->isa("RDF::Trine::Iterator") and $self->can("_serializer"))
	{
		my $t = $self->_serializer->new->serialize_iterator_to_string($thing);
		$thing = \$t
	}
	
	unless (ref $thing eq 'SCALAR')
	{
		my $fh = as_filehandle($thing);
		local $/;
		my $t = <$fh>;
		$thing = \$t;
	}
	
	return $thing;
}

sub tokenize
{
	my $self = shift;
	ref $self or WrongInvocant->throw("this is an object method!");
	
	$self->_remaining( $self->_scalarref(@_) );
	$self->_tokens([]);
	
	# Calculate these each time in case somebody wants to play with
	# our variables!
	my $_regexify = sub
	{
		my @in     = @_;
		my $joined = join "|", map { s/__/\\s+/g; $_ } map quotemeta, @in;
		qr{^($joined)}i;
	};
	my $sparqlKeyword   = $_regexify->(@sparqlQueryWord, @sparqlUpdateWord);
	my $sparqlFunction  = $_regexify->(@sparqlFunction);
	my $sparqlAggregate = $_regexify->(@sparqlAggregate);
	my $sparqlOrdering  = $_regexify->(@sparqlOrdering);
	my $sparqlOperator  = $_regexify->(@sparqlOperator);
	my $pretdslKeyword  = $_regexify->(sort { length $a <=> length $b } keys %pretdslKeywords);
	
	# Don't need to repeatedly call this method!
	my $IS_NTRIPLES    = ($self->mode & MODE_NTRIPLES);
	my $IS_TURTLE      = ($self->mode & MODE_TURTLE or $self->mode & MODE_TRIG or $self->mode & MODE_NOTATION_3 or $self->mode & MODE_PRETDSL);
	my $IS_NOTATION_3  = ($self->mode & MODE_NOTATION_3 or $self->mode & MODE_PRETDSL);
	my $IS_SPARQL      = ($self->mode & MODE_SPARQL);
	my $IS_PRETDSL     = ($self->mode & MODE_PRETDSL);
	my $IS_TRIG        = ($self->mode & MODE_TRIG);
	my $ABOVE_NTRIPLES = ($IS_TURTLE or $IS_NOTATION_3 or $IS_SPARQL or $IS_PRETDSL or $IS_TRIG);
	
	# Declare this ahead of time for use in the big elsif!
	my $matches;
	
	while (length ${ $self->_remaining })
	{
		if ($self->_peek(' ') || $self->_peek("\n") || $self->_peek("\r") || $self->_peek("\t"))
		{
			$self->_pull_whitespace;
		}
		elsif ($IS_NOTATION_3||$IS_SPARQL||$IS_TRIG and $self->_peek('{'))
		{
			$self->_pull_token('{', Brace);
		}
		elsif ($IS_NOTATION_3||$IS_SPARQL||$IS_TRIG and $self->_peek('}'))
		{
			$self->_pull_token('}', Brace);
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek('['))
		{
			$self->_pull_token('[', Bracket);
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek(']'))
		{
			$self->_pull_token(']', Bracket);
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek('('))
		{
			$self->_pull_token('(', Parenthesis);
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek(')'))
		{
			$self->_pull_token(')', Parenthesis);
		}
		elsif ($self->_peek('^^'))
		{
			$self->_pull_token('^^', Datatype);
		}
		# Need to handle SPARQL property paths!
		elsif ($IS_NOTATION_3 and $matches = $self->_peek(qr/^([\!\^])/))
		{
			$self->_pull_token($matches->[0], Path);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\,\;])/))
		{
			$self->_pull_token($matches->[0], Punctuation);
		}
		elsif ($self->_peek('.'))
		{
			$self->_pull_token('.', Punctuation);
		}
		elsif ($IS_NOTATION_3||$IS_TURTLE||$IS_TRIG and $matches = $self->_peek(qr/^(\@(?:prefix|base))/))
		{
			$self->_pull_token($matches->[0], AtRule);
		}
		elsif ($IS_NOTATION_3 and $matches = $self->_peek(qr/^(\@(?:keywords|forSome|forAll))/))
		{
			$self->_pull_token($matches->[0], AtRule);
		}
		elsif ($matches = $self->_peek(qr/^(\@[a-z0-9-]+)/i))
		{
			$self->_pull_token($matches->[0], Language);
		}
		elsif ($matches = $self->_peek(qr/^(#.*?)(?:\r|\n|$)/is))
		{
			$self->_pull_token($matches->[0], Comment);
		}
		elsif ($IS_PRETDSL and $matches = $self->_peek(qr{^(RT#[0-9]+)}i))
		{
			$self->_pull_token($matches->[0], Pretdsl_RT);
		}
		elsif ($IS_PRETDSL and $matches = $self->_peek(qr{^(cpan:\w+)}i))
		{
			$self->_pull_token($matches->[0], Pretdsl_CPANID);
		}
		elsif ($IS_PRETDSL and $matches = $self->_peek(qr{^([drfmp]?`.*?`)}i))
		{
			$self->_pull_pretdsl($matches->[0]);
		}
		elsif ($IS_PRETDSL and $matches = $self->_peek(qr{^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{4}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})?)}i))
		{
			$self->_pull_token($matches->[0], Pretdsl_DateTime);
		}
		elsif ($IS_PRETDSL and $matches = $self->_peek(qr{^([0-9]{4}-[0-9]{2}-[0-9]{2})}i))
		{
			$self->_pull_token($matches->[0], Pretdsl_Date);
		}
		elsif ($IS_PRETDSL and $matches = $self->_peek($pretdslKeyword))
		{
			$self->_pull_token($matches->[0], Pretdsl_Keyword, absolute_uri => $pretdslKeywords{$matches->[0]});
		}
		elsif ($self->_peek('_:'))
		{
			$self->_pull_bnode;
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([$nameStartChar2][$nameChar]*)?:([$nameStartChar2][$nameChar]*)?/))
		{
			$self->_pull_curie;
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\-\+]?([0-9]+\.[0-9]*e[\-\+]?[0-9]+))/i))
		{
			$self->_pull_token($matches->[0], Number_Double);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\-\+]?(\.[0-9]+e[\-\+]?[0-9]+))/i))
		{
			$self->_pull_token($matches->[0], Number_Double);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\-\+]?([0-9]+e[\-\+]?[0-9]+))/i))
		{
			$self->_pull_token($matches->[0], Number_Double);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\-\+]?([0-9]+\.[0-9]*))/))
		{
			$self->_pull_token($matches->[0], Number_Decimal);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\-\+]?(\.[0-9]+))/))
		{
			$self->_pull_token($matches->[0], Number_Decimal);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([\-\+]?([0-9]+))/))
		{
			$self->_pull_token($matches->[0], Number_Integer);
		}
		elsif ($self->_peek('<'))
		{
			$self->_pull_uri;
		}
		elsif ($IS_NOTATION_3||$IS_SPARQL and $self->_peek('?'))
		{
			$self->_pull_variable;
		}
		elsif ($IS_SPARQL and $self->_peek('$'))
		{
			$self->_pull_variable;
		}
		elsif ($IS_SPARQL and $self->_peek('*'))
		{
			$self->_pull_token('*', Variable);
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek('"""') || $self->_peek("'''"))
		{
			$self->_pull_longstring;
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek("'"))
		{
			$self->_pull_shortstring;
		}
		elsif ($self->_peek('"'))
		{
			$self->_pull_shortstring;
		}
		elsif ($IS_SPARQL and $matches = $self->_peek($sparqlKeyword))
		{
			$self->_pull_token($matches->[0], Sparql_Keyword);
		}
		elsif ($IS_SPARQL and $matches = $self->_peek($sparqlFunction))
		{
			$self->_pull_token($matches->[0], Sparql_Function);
		}
		elsif ($IS_SPARQL and $matches = $self->_peek($sparqlAggregate))
		{
			$self->_pull_token($matches->[0], Sparql_Aggregate);
		}
		elsif ($IS_SPARQL and $matches = $self->_peek($sparqlOrdering))
		{
			$self->_pull_token($matches->[0], Sparql_Ordering);
		}
		elsif ($IS_SPARQL and $matches = $self->_peek($sparqlOperator))
		{
			$self->_pull_token($matches->[0], Sparql_Operator);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^(true|false)\b/i))
		{
			$self->_pull_token($matches->[0], Boolean);
		}
		elsif ($ABOVE_NTRIPLES and $self->_peek(qr{^(a)\b}))
		{
			$self->_pull_token('a', Shorthand);
		}
		elsif ($IS_NOTATION_3 and $matches = $self->_peek(qr/^(=|=>|<=)/))
		{
			$self->_pull_token($matches->[0], Shorthand);
		}
		elsif ($IS_TRIG and $self->_peek("="))
		{
			$self->_pull_token("=", Shorthand);
		}
		elsif ($IS_NOTATION_3 and $matches = $self->_peek(qr/^(is|of)\b/i))
		{
			$self->_pull_token($matches->[0], IsOf);
		}
		elsif ($ABOVE_NTRIPLES and $matches = $self->_peek(qr/^([$nameStartChar][$nameChar]*)/))
		{
			$self->_pull_token($matches->[0], Name);
		}
		elsif ($matches = $self->_peek(qr/^([^\s\r\n]+)[\s\r\n]/ms))
		{
			$self->_pull_token($matches->[0], Unknown);
		}
		elsif ($matches = $self->_peek(qr/^([^\s\r\n]+)$/ms))
		{
			$self->_pull_token($matches->[0], Unknown);
		}
		else
		{
			Tokenization->throw(
				"Could not tokenise string!",
				remaining => ${ $self->_remaining },
			);
		}
	}
	
	return $self->_tokens;
}

sub _fixup
{
	my $self = shift;
	my ($base) = @_;
	$self->_fixup_urirefs($base);
	$self->_fixup_prefix_declarations;
	$self->_fixup_curies;
}

sub _resolve_uri
{
	shift;
	my ($relative, $base) = @_;
	return $relative unless length $base;
	
	require URI;
	
	# Where the base itself is relative
	if (!URI->new($relative)->scheme and !URI->new($base)->scheme)
	{
		return (
			$base =~ m{^/}
				? "URI"->new_abs(@_)->as_string
				: substr("URI"->new_abs(@_)->as_string, 1)
		);
	}
	
	"URI"->new_abs(@_)->as_string;
}

sub _fixup_urirefs
{
	my $self = shift;
	my ($base) = @_;
	$base //= "";
	
	my $tokens = $self->_tokens;
	my $i = 0;
	while ($i < @$tokens)
	{
		my $t = $tokens->[$i];
		
		if ($t->isa(URIRef) and not defined $t->absolute_uri)
		{
			$t->absolute_uri($self->_resolve_uri($t->uri, $base));
		}
		elsif ( ($t->isa(Sparql_Keyword) and lc($t->spelling) eq 'base')
		or      ($t->isa(AtRule) and lc($t->spelling) eq '@base') )
		{
			# search ahead for the new base URI
			my $j = 1;
			while ($tokens->[$i+$j]->isa(Comment) || $tokens->[$i+$j]->isa(Whitespace))
			{
				$j++;
				last if !defined $tokens->[$i+$j];
			}
			if (defined $tokens->[$i+$j] and $tokens->[$i+$j]->can("uri"))
			{
				# new base URI found!
				$base = $self->_resolve_uri($tokens->[$i+$j]->uri, $base);
				$i += ($j - 1);
			}
		}
		
		$i++;
	}
}

sub _fixup_prefix_declarations
{
	my $self = shift;
	
	my $tokens = $self->_tokens;
	my $i = 0;
	my $started;
	my @bits;
	while ($i < @$tokens)
	{
		my $t = $tokens->[$i];
		my $is_end;
		
		if ($t->isa(AtRule) and lc($t->spelling) eq '@prefix')
		{
			$started = $i;
			@bits    = $t;
		}
		elsif ($t->isa(Sparql_Keyword) and lc($t->spelling) eq 'PREFIX')
		{
			$started = $i;
			@bits    = $t;
		}
		elsif (defined $started and $t->isa(CURIE) || $t->isa(URIRef))
		{
			push @bits, $t;
		}
		elsif (defined $started and @bits==3 and $t->spelling eq "." and $bits[0]->isa(AtRule))
		{
			$is_end = 1;
		}
		
		if (!$is_end and defined $started and @bits==3 and $bits[0]->isa(Sparql_Keyword))
		{
			$is_end = 1;
		}
		
		if ($is_end)
		{
			my $END   = PrefixDefinition_End->new;
			my $START = PrefixDefinition_Start->new(
				prefix       => $bits[1]->prefix,
				absolute_uri => $bits[2]->absolute_uri,
				end          => $END
			);
			$END->start($START);
			
			$bits[1]->absolute_uri($bits[2]->absolute_uri);
			
			splice(@$tokens, $started, 0, $START); $i++;
			splice(@$tokens, $i+1,     0, $END); $i++;
		}
		
		$i++;
	}
}

our %pretdslPrefixes = (
	"grddl" =>   "http://www.w3.org/2003/g/data-view#",
	"ma" =>      "http://www.w3.org/ns/ma-ont#",
	"owl" =>     "http://www.w3.org/2002/07/owl#",
	"rdf" =>     "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	"rdfa" =>    "http://www.w3.org/ns/rdfa#",
	"rdfs" =>    "http://www.w3.org/2000/01/rdf-schema#",
	"rif" =>     "http://www.w3.org/2007/rif#",
	"skos" =>    "http://www.w3.org/2004/02/skos/core#",
	"skosxl" =>  "http://www.w3.org/2008/05/skos-xl#",
	"wdr" =>     "http://www.w3.org/2007/05/powder#",
	"void" =>    "http://rdfs.org/ns/void#",
	"wdrs" =>    "http://www.w3.org/2007/05/powder-s#",
	"xhv" =>     "http://www.w3.org/1999/xhtml/vocab#",
	"xml" =>     "http://www.w3.org/XML/1998/namespace",
	"xsd" =>     "http://www.w3.org/2001/XMLSchema#",
	"cc" =>      "http://creativecommons.org/ns#",
	"ctag" =>    "http://commontag.org/ns#",
	"dc" =>      "http://purl.org/dc/terms/",
	"dcterms" => "http://purl.org/dc/terms/",
	"foaf" =>    "http://xmlns.com/foaf/0.1/",
	"gr" =>      "http://purl.org/goodrelations/v1#",
	"ical" =>    "http://www.w3.org/2002/12/cal/icaltzd#",
	"og" =>      "http://ogp.me/ns#",
	"rev" =>     "http://purl.org/stuff/rev#",
	"sioc" =>    "http://rdfs.org/sioc/ns#",
	"v" =>       "http://rdf.data-vocabulary.org/#",
	"vcard" =>   "http://www.w3.org/2006/vcard/ns#",
	"schema" =>  "http://schema.org/",
	"cpant" =>   "http://purl.org/NET/cpan-uri/terms#",
	"dbug" =>    "http://ontologi.es/doap-bugs#",
	"dcs" =>     "http://ontologi.es/doap-changeset#",
	"doap" =>    "http://usefulinc.com/ns/doap#",
	"earl" =>    "http://www.w3.org/ns/earl#",
	"nfo" =>     "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#",
	"pretdsl" => "http://ontologi.es/pretdsl#",
	"pretdsl-dt" => "http://ontologi.es/pretdsl#dt/",
);

sub _fixup_curies
{
	my $self = shift;
	
	my $map = +{
		$self->mode & MODE_PRETDSL
			? %pretdslPrefixes
			: ()
	};
	my $tokens = $self->_tokens;
	
	for my $t (@$tokens)
	{
		if ($t->isa(PrefixDefinition_End))
		{
			$map->{ $t->start->prefix } = $t->start->absolute_uri;
		}
		elsif ($t->isa(CURIE) and defined $t->prefix and exists $map->{$t->prefix})
		{
			$t->absolute_uri($map->{$t->prefix} . ($t->suffix//""));
		}
	}
}

sub highlight
{
	my $self = shift;
	ref $self or WrongInvocant->throw("this is an object method!");
	
	my ($text, $base) = @_;
	
	$self->tokenize($text);
	$self->_fixup($base);
	
	return join "", map $_->TO_HTML, @{$self->_tokens};
}

{
	package Syntax::Highlight::RDF::NTriples;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES;
	sub _serializer
	{
		require RDF::Trine::Serializer::NTriples;
		"RDF::Trine::Serializer::NTriples";
	}
}

{
	package Syntax::Highlight::RDF::Turtle;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES
		| Syntax::Highlight::RDF::MODE_TURTLE;
	sub _serializer
	{
		eval { require RDF::TrineX::Serializer::MockTurtleSoup }
			and return "RDF::TrineX::Serializer::MockTurtleSoup";
		require RDF::Trine::Serializer::Turtle;
		"RDF::Trine::Serializer::Turtle";
	}
}

{
	package Syntax::Highlight::RDF::Notation_3;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES
		| Syntax::Highlight::RDF::MODE_TURTLE
		| Syntax::Highlight::RDF::MODE_NOTATION_3;
	sub _serializer
	{
		require RDF::Trine::Serializer::Notation3;
		"RDF::Trine::Serializer::Notation3";
	}
}

{
	package Syntax::Highlight::RDF::SPARQL_Query;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES
		| Syntax::Highlight::RDF::MODE_TURTLE
		| Syntax::Highlight::RDF::MODE_SPARQL;
}

{
	package Syntax::Highlight::RDF::SPARQL_Update;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES
		| Syntax::Highlight::RDF::MODE_TURTLE
		| Syntax::Highlight::RDF::MODE_SPARQL;
}

{
	package Syntax::Highlight::RDF::Pretdsl;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES
		| Syntax::Highlight::RDF::MODE_TURTLE
		| Syntax::Highlight::RDF::MODE_NOTATION_3
		| Syntax::Highlight::RDF::MODE_PRETDSL;
}

{
	package Syntax::Highlight::RDF::NQuads;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES;
	sub _serializer
	{
		require RDF::Trine::Serializer::NQuads;
		"RDF::Trine::Serializer::NQuads";
	}
}

{
	package Syntax::Highlight::RDF::TriG;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moo;
	extends "Syntax::Highlight::RDF";
	use constant mode => Syntax::Highlight::RDF::MODE_NTRIPLES
		| Syntax::Highlight::RDF::MODE_TURTLE
		| Syntax::Highlight::RDF::MODE_TRIG;
}

sub highlighter
{
	my $class = shift;
	$class eq __PACKAGE__ or WrongInvocant->throw("this is a factory method!");
	
	my ($hint) = @_;
	
	$hint =~ m{xml}i and do {
		require Syntax::Highlight::XML;
		return "Syntax::Highlight::XML"->new;
	};
	
	$hint =~ m{json}i and do {
		require Syntax::Highlight::JSON2;
		return "Syntax::Highlight::JSON2"->new;
	};
	
	$hint =~ m{(ttl|turtle)}i       and return "$class\::Turtle"->new;
	$hint =~ m{(nt|n.?triples)}i    and return "$class\::NTriples"->new;
	$hint =~ m{(nq|n.?quads)}i      and return "$class\::NQuads"->new;
	$hint =~ m{(trig)}i             and return "$class\::TriG"->new;
	$hint =~ m{(n3|notation.?3)}i   and return "$class\::Notation_3"->new;
	$hint =~ m{(pret)}i             and return "$class\::Pretdsl"->new;
	$hint =~ m{(sparql.?update)}i   and return "$class\::SPARQL_Update"->new;
	$hint =~ m{(sparql)}i           and return "$class\::SPARQL_Query"->new;
	$hint =~ m{(text/plain)}i       and return "$class\::NTriples"->new;
	
	return $class->new;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Syntax::Highlight::RDF - syntax highlighting for various RDF-related formats

=head1 SYNOPSIS

  use Syntax::Highlight::RDF;
  my $syntax = "Syntax::Highlight::RDF"->highlighter("Turtle");
  print $syntax->highlight($filehandle);

=head1 DESCRIPTION

Outputs pretty syntax-highlighted HTML for RDF-related formats. (Actually just
adds C<< <span> >> elements with C<< class >> attributes. You're expected to
bring your own CSS.)

=head2 Formats

=over

=item *

N-Triples

=item *

N-Quads

=item *

Turtle

=item *

TriG

=item *

Notation 3

=item *

Pretdsl

=item *

SPARQL Query 1.1 (but not property paths yet)

=item *

SPARQL Update 1.1 (but not property paths yet)

=item *

JSON - intended for RDF/JSON and SPARQL Results JSON, but just generic highlighting

=item *

XML - intended for RDF/XML and SPARQL Results XML, but just generic highlighting

=back

=head2 Methods

=over

=item C<< highlighter($format) >>

Factory method; generally preferred over calling C<new> on a specific
class.

  "Syntax::Highlight::RDF"->highlighter("Turtle");
  "Syntax::Highlight::RDF::Turtle"->new;  # avoid!

=item C<< highlight($input, $base) >>

Highlight some RDF.

C<< $input >> may be a file handle, filename or a scalar ref of text.
(Most highlighters will also attempt to Do What You Mean if passed something
else sane like an RDF::Trine::Model.) C<< $base >> is an optional base for
resolving relative URIs.

Returns a string of HTML.

=item C<< tokenize($input) >>

This is mostly intended for subclassing Syntax::Highlight::RDF.

C<< $input >> may be a file handle, filename or a scalar ref of text.

Returns an arrayref of token objects. The exact API for the token objects
is subject to change, but currently they support C<< TYPE >> and
C<< spelling >> methods.

=back

=begin private

=item MODE_NTRIPLES       => 0,

=item MODE_TURTLE         => 1,

=item MODE_NOTATION_3     => 2,

=item MODE_SPARQL         => 4,

=item MODE_PRETDSL        => 8,

=item MODE_TRIG           => 16,

=item mode

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Syntax-Highlight-RDF>.

=head1 SEE ALSO

L<Syntax::Highlight::JSON2>,
L<Syntax::Highlight::XML>.

L<PPI::HTML>,
L<Syntax::Highlight::Engine::Kate>.

L<RDF::Trine>, L<RDF::Query>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


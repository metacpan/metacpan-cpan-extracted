package Net::Z3950::FOLIO::Config;

use 5.008000;
use strict;
use warnings;

use IO::File;
use Cpanel::JSON::XS qw(decode_json);


# Possible values of $missingAction
sub MISSING_ERROR { 0 }
sub MISSING_TENANT { 1 }
sub MISSING_FILTER { 2 }


sub new {
    my $class = shift();
    my($cfgbase, @extras) = @_;

    my $cfg = _compileConfig($cfgbase, @extras);
    return bless $cfg, $class;
}


sub _compileConfig {
    my($cfgbase, @extras) = @_;

    my $cfg = _compileConfigFile($cfgbase, undef, MISSING_ERROR);

    my $isFirst = 1;
    while (@extras) {
	my $extra = shift @extras;
	my $overlay = _compileConfigFile($cfgbase, $extra, $isFirst ? MISSING_TENANT : MISSING_FILTER);
	$isFirst = 0;
	_mergeConfig($cfg, $overlay);
    }

    my $gqlfile = $cfg->{graphqlQuery}
        or die "$0: no GraphQL query file defined";

    my $path = $cfgbase;
    if ($path =~ /\//) {
	$path =~ s/(.*)?\/.*/$1/;
	$gqlfile = "$path/$gqlfile";
    }
    my $fh = new IO::File("<$gqlfile")
	or die "$0: can't open GraphQL query file '$gqlfile': $!";
    { local $/; $cfg->{graphql} = <$fh> };
    $fh->close();

    return $cfg;
}


sub _compileConfigFile {
    my($cfgbase, $cfgsub, $missingAction) = @_;

    my $cfgname = $cfgbase . ($cfgsub ? ".$cfgsub" : '') . '.json';
    my $fh = new IO::File("<$cfgname");
    if (!$fh) {
	if ($! == 2 && $missingAction == MISSING_TENANT) {
	    Net::Z3950::FOLIO::_throw(109, "$cfgsub");
	} elsif ($! == 2 && $missingAction == MISSING_FILTER) {
	    Net::Z3950::FOLIO::_throw(1, "filter not configured: $cfgsub");
	}
	die "$0: can't open config file '$cfgbase.json': $!"
    }

    my $json; { local $/; $json = <$fh> };
    $fh->close();

    my $cfg = decode_json($json);
    _expandVariableReferences($cfg);
    return $cfg;
}


sub _expandVariableReferences {
    my($obj) = @_;

    foreach my $key (sort keys %$obj) {
	$obj->{$key} = _expandSingleVariableReference($key, $obj->{$key});
    }

    return $obj;
}

sub _expandSingleVariableReference {
    my($key, $val) = @_;

    if (ref($val) eq 'HASH') {
	return _expandVariableReferences($val);
    } elsif (ref($val) eq 'ARRAY') {
	return [ map { _expandSingleVariableReference($key, $_) } @$val ];
    } elsif (ref($val) eq 'JSON::PP::Boolean') {
	return $val;
    } elsif (!ref($val)) {
	return _expandScalarVariableReference($key, $val);
    } else {
	use Data::Dumper;
	die "non-hash, non-array, non-boolean, non-scalar configuration key '$key' = ", Dumper($val);
    }
}

sub _expandScalarVariableReference {
    my ($key, $val) = @_;

    my $orig = $val;
    while ($val =~ /(.*?)\$\{(.*?)}(.*)/) {
	my($pre, $inclusion, $post) = ($1, $2, $3);

	my($name, $default);
	if ($inclusion =~ /(.*?)-(.*)/) {
	    $name = $1;
	    $default = $2;
	} else {
	    $name = $inclusion;
	    $default = undef;
	}

	my $env = $ENV{$name} || $default;
	if (!defined $env) {
	    warn "environment variable '$2' not defined for '$key'";
	    $env = '';
	}
	$val = "$pre$env$post";
    }

    return $val;
}


sub _mergeConfig {
    my($base, $overlay) = @_;

    my %complex_keys = (
	okapi => 1,
	login => 1,
	indexMap => 1,
	marcHoldings => 1,
	fieldDefinitions => {
	    holding => 1,
	    circulation => 1,
	},
    );

    foreach my $key (keys (%complex_keys)) {
	if (defined $overlay->{$key}) {
	    if (ref $base->{$key} eq 'HASH') {
		_mergeHash($base->{$key}, $overlay->{$key}, $complex_keys{$key});
	    } else {
		$base->{$key} = $overlay->{$key};
	    }
	}
    }

    foreach my $key (sort keys %$overlay) {
	if (!$complex_keys{$key}) {
	    $base->{$key} = $overlay->{$key};
	}
    }
}


sub _mergeHash {
    my($base, $overlay, $keysOfsubStructures) = @_;

    foreach my $key (sort keys %$overlay) {
	if (ref $keysOfsubStructures eq 'HASH' && $keysOfsubStructures->{$key}) {
	    _mergeHash($base->{$key}, $overlay->{$key}, $keysOfsubStructures->{$key});
	} else {
	    $base->{$key} = $overlay->{$key};
	}
    }
}

=encoding utf-8

=head1 NAME

Net::Z3950::FOLIO::Config - configuration file for the FOLIO Z39.50 gateway

=head1 SYNOPSIS

  {
    "okapi": {
      "url": "https://folio-snapshot-okapi.dev.folio.org",
      "tenant": "${OKAPI_TENANT-indexdata}"
    },
    "login": {
      "username": "diku_admin",
      "password": "${OKAPI_PASSWORD}"
    },
    "indexMap": {
      "1": "author",
      "7": "identifiers/@value/@identifierTypeId=\"8261054f-be78-422d-bd51-4ed9f33c3422\"",
      "4": "title",
      "12": {
        "cql": "hrid",
        "relation": "==",
        "omitSortIndexModifiers": [ "missing", "case" ]
      },
      "21": "subject",
      "1016": "author,title,hrid,subject"
    },
    "queryFilter": "source=marc",
    "graphqlQuery": "instances.graphql-query",
    "chunkSize": 5,
    "fieldDefinitions": {
      "circulation": {
	"availableThru": "permanentLoanType"
      }
    },
    "marcHoldings": {
      "restrictToItem": 0,
      "field": "952",
      "indicators": [" ", " "],
      "holdingsElements": {
        "t": "copyNumber"
      },
      "itemElements": {
        "b": "itemId",
        "k": "_callNumberPrefix",
        "h": "_callNumber",
        "m": "_callNumberSuffix",
        "v": "_volume",
        "e": "_enumeration",
        "y": "_yearCaption",
        "c": "_chronology"
      }
    },
    "postProcessing": {
      "marc": {
        "008": { "op": "regsub", "pattern": "([13579])", "replacement": "[$1]", "flags": "g" },
        "245$a": [
          { "op": "stripDiacritics" },
          { "op": "regsub", "pattern": "[abc]", "replacement": "*", "flags": "g" }
        ]
      },
      "opac": {
	"holding": {
	  "callNumber": {
	    "op": "regsub",
	    "pattern": "(.*)",
	    "replacement": "%{_callNumberPrefix}$1%{_callNumberSuffix}"
	  }
	}
      }
    }
  }

=head1 DESCRIPTION

The FOLIO Z39.50 gateway C<z2folio> is configured by a stacking set of
JSON files whose basename is specified on the command-line. These
files specify how to connect to FOLIO, how to log in, and how to
search.

The structure of each of these file is the same, and the mechanism by
which they are stacked is described below. The shared format is
simple. There are several top-level sections, each described in its own
section below, and each of them is an object with several keys that can
exist in it.

If any string value contains sequences of the form C<${NAME}>, they
are each replaced by the values of the corresponding environment
variables C<$NAME>, providing a mechanism for injecting values into
the configuration. This is useful if, for example, it is necessary to
avoid embedding authentication secrets in the configuration file.

When substituting environment variables, the bash-like fallback syntax
C<${NAME-VALUE}> is recognised. This evaluates to the value of the
environment variable C<$NAME> when defined, falling back to the
constant value C<VALUE> otherwise. In this way, the configuration can
include default values which may be overridden with environment
variables.


=head2 C<okapi>

Contains three elements (two mandatory, one optional), all with string values:

=over 4

=item C<url>

The full URL to the Okapi server that provides the gateway to the
FOLIO installation.

=item C<graphqlUrl> (optional)

Usually, the main Okapi URL is used for all interaction with FOLIO:
logging in, searching, retrieving records, etc. When the optional
C<graphqlUrl> configuration entry is provided, it is used for GraphQL
queries only. This provides a way of "side-loading" mod-graphql, which
is useful in at least two situations: when the FOLIO snapshot services
are unavailable (since the production services do not presently
included mod-graphql); and when you need to run against a development
version of mod-graphql so you can make changes to its behaviour.

=item C<tenant>

The name of the tenant within that FOLIO installation whose inventory
model should be queried.

=back

=head2 C<login>

Contains two elements, both with string values:

=over 4

=item C<username>

The name of the user to log in as, unless overridden by authentication information in the Z39.50 init request.

=item C<password>

The corresponding password, unless overridden by authentication information in the Z39.50 init request.

=back

=head2 C<nologin>

If specified and set to 1, then no login is performed, and the
C<login> section need not be provided.

=head2 C<indexMap>

Contains any number of elements. The keys are the numbers of BIB-1 use
attributes, and the corresponding values contain instructions about
the indexes in the FOLIO instance record to map those access-points
to. The key C<default> is special, and is used for terms where no BIB-1
use attribute is specified.

Each value may be either a string, in which case it is interpreted as
a CQL index to map to (see below for details), or an object. When the
object version is used, that object's C<cql> member contains the CQL
index mapping (see below), and any of the following additional members
may also be included:

=over 4

=item C<omitSortIndexModifiers>

A bug in FOLIO's CQL query interpreter means that for some indexes,
query translation will fail if a sort-specification is provided that
requests certain valid behaviours, e.g. a case-sensitive search on the
HRID index. To work around this until it's fixed, an index's
C<omitSortIndexModifiers> allows you to specify a list of the
index-modifier types that they do not support, so that the server can
omit those qualifiers when creating sort-specifications. The valid
index-modifier types are C<missing>, C<relation> and C<case>.

=item C<relation>

If specified, the value is the relation that should be used instead of
C<=> by default when searching in this index. This is useful mostly
for defaulting to the strict-equality relation C<==> for indexes whose
values are atomic, such as identifiers.

=back

Each C<cql> value (or string value when the object form is not used)
may be a comma-separated list of multiple CQL indexes to be queried.

Each CQL index specified as a value, or as one of the comma-separated
components of a value, may contain a forward slash. If it does, then
the part before the slash is used as the actual index name, and the
part after the slash as a CQL relation modifier. For example, if the
index map contains

  "999": "foo/bar=quux"

Then a search for C<@attr 1=9 thrick> will be translated to the CQL
query C<foo =/bar=quux thrick>.

=head2 C<queryFilter>

If specified, this is a CQL query which is automatically C<and>ed with
every query submitted by the client, so it acts as a filter allowing
through only records that satisfy it. This might be used, for example,
to specify C<source=marc> to limit search result to only to those
FOLIO instance records that were translated from MARC imports.

See the section below on B<Configuring filters>.

=head2 C<graphqlQuery>

The name of a file, in the same directory as the main configuration
file, which contains the text of the GraphQL query to be used to
obtain the instance, holdings and item data pertaining to the records
identified by the CQL query.

=head2 C<chunkSize>

An integer specifying how many records to fetch from FOLIO with each
search. This can be tweaked to tune performance. Setting it too low
will result in many requests with small numbers of records returned
each time; setting it too high will result in fetching and decoding
more records than are actually wanted.

=head2 C<fieldDefinitions>

An optional object specifying how the sources from which some
particular holdings fields should draw their data, overriding the
default sources.

The keys of this object specify domains in which the fields can be
found: supported domains are C<holding> and C<circulation>}.

Within the C<holdings> domain, no fields are presently supported;
within the C<circulation> domain, only the C<availableThru> field is
presently supported. Support for further fields may be added as
required.

Each field within a domain is specified by its name as key, and the
corresponding value is a string specifying a path from which to fetch
the data. These strings follow the same syntax as L<the get function
in JavaScript's lodash library|https://docs-lodash.com/v4/get/>. It is
a dot-separate sequence of source field-names to navigate down, with
bracketed numbers indicating the selection of one element of an
array. For example, the path
C<temporaryLocation.servicePoints[0].discoveryDisplayName> fetches the
C<discoveryDisplayName> field from the first element of the
C<servicePoints> array within the C<temporaryLocation> structure. It
will work when running on data with the shape C<{ temporaryLocation: {
servicePoints: [ { discoveryDisplayName: "Main" } ] } }>.


=head2 C<marcHoldings>

An optional object specifying how holdings and item-level data should
be mapped into MARC fields. It contains up to five elements:

=over 4

=item C<restrictToItem>

If specified and set to 1, then the item-level holding information
included in MARC records is restricted to that which pertains to the
barcode mentioned in the search that yielded the record, if any. If
zero (the default), then information on all holdings and items is
included.

=item C<field> (mandatory)

A string specifying which MARC field should be used for holdings
information. When a record contains multiple holdings, a separate
instance of this MARC field is created for each holding.

=item C<indicators> (mandatory)

An array containing two strings, each of them specifying one of the
two indicators to be used in the MARC field that contains
holdings. There must be exactly two elements: blank indicators can
be specified as a single space.

information.

=item C<fieldPerItem>

If specified and set to a true value, then a separate MARC field is
generated for each item in each holding. When this is absent or set to
a false value (the default), one MARC field is generated for each
holding, and multiple items within each holding are represented by
repeating sets of subfields within that field.

This setting makes it simpler to access information about individual
items, at the cost of losing information about how they are grouped
into holdings.

=item C<holdingsElements>

An object specifying MARC subfields that should be set from
holdings-level data. The keys are the single-character names of the
subfields, and the corresponding values are the names of
holdings-level fields in the OPAC XML record structure.

See C<itemElements> for detail of the structure.

=item C<itemElements>

An object specifying MARC subfields that should be set from item-level
data. The keys are the single-character names of the subfields, and
the corresponding values are the names of item-level fields in the
OPAC XML record structure. In addition to the standard field names,
several additional special fields are avaialable, not part of the OPAC
Z39.50 record, assigned names that begin with underscores:

=over 4

=item C<_enumeration>

=item C<_chronology>

=item C<_callNumber>

=item C<_callNumberPrefix>

=item C<_callNumberSuffix>

=item C<_permanentLocation>

=item C<_holdingsLocation>

=item C<_volume>

=item C<_yearCaption>

=item C<_accessionNumber>

=item C<_copyNumber>

=item C<_descriptionOfPieces>

=item C<_discoverySuppress>

=item C<_hrid>

=item C<_id>

=item C<_itemIdentifier>

=back

Since there may be multiple items in a single holding, sets of these
fields can repeat, e.g. for a holding with two items each specifying
data that is encoded in the C<b>, C<e> and C<h> subfields, the field
would take the form

  $b 46243154 $e 1994/95 v.1 $h
  $b 46243072 $e 1994/95 v.2 $h TD224.I3I58b

=back

=head2 C<postProcessing>

Specifies sets of transformations to be applied to the values of
fields retrieved from the back-end. Two top-level keys are supported,
for post-processing of two different types of record, and they work
slightly differently:

=over 4

=item C<marc>

Specifies transformations to be applied to MARC records (either
standalone or as part of OPAC records). The value is an object: keys
are the names of simple MARC fields, such as C<008>; or of complex
field$subfield combinations, such as C<245$a>. The corresponding
values specify the transformations that should be applied to the
values of these fields and subfields -- see below.

=item C<opac>

Specifies transformations to be applied to the holdings and
circulations parts of OPAC records. The value is an object which can
contain either or both C<holding> and C<circulation> keys; the values
corresponding to each of these keys are themselves objects which
specify which fields within the holdings records, or their circulation
subrecords, to transform.

The keys within both of these subobjects are XML fieldnames, including
both those defined for the OPAC record and the "special fields"
beginning with underscores that are listed above in the
C<itemElements> section -- for example, C<_callNumberPrefix>. The
corresponding values specify the transformations that should be
applied to the values of these fields and subfields -- see below.

=back

In summary, the C<marc> section lists fieldnames (both simple and
complex) directly; whereas the C<opac> section contains C<holding> and
C<circulation> subsections which list the XML fieldnames of the two
sections separately.

Post-processing transformation specifications are the same for MARC
and OPAC records. Each value in the specification may be either a
single transformation or an array o zero or more transformations which
will be applied in the specified order.

Individual transformations are represented by objects. The fundamental
behaviour of each transformations is determined by an C<op> key whose
value specifies the required operation.

The following transformation operations are supported:

=over 4

=item C<stripDiacritics>

All diacritics are stripped from the value in the relevant field: for
example, C<délétère> becomes C<deletere>.

=item C<regsub>

A regular expression substitution is performed on the value in the
relevant field, as specified by the parameters in the transformation
object:

=over 4

=item C<pattern>

A regular expression intended to matching some part of the field
value. This is Perl regular expression, as overviewed in
L<perlretut|https://perldoc.perl.org/perlretut>
and fully documented in
L<perlre|https://perldoc.perl.org/perlre>
and as such supports advanced facilities such as back-references.

=item C<replacement>

The string with which to replace the part of the field value that
matches the pattern. This may include numbered references C<$1>,
C<$2>, etc., to parenthesized sub-expressions in the pattern. (If this
statement means nothing to you, you need to
L<go and read about regular expressions|https://perldoc.perl.org/perlretut>.)

Replacement strings may also include sequences of the form
I<%{fieldname}>, where I<fieldname> is interpreted in a manner
appropriate for the kind of record being post-processed. For MARC
records, I<fieldname> is either a simple control-field tag such as
C<001> or a field-and-subfield combination like C<245$a>; for OPAC
records, it is the name of an XML field from the same part of the
record (i.e. a holdings field if substituting holdings data, and a
circulation field if substituting circulation data).

Such sequences cause the value of the specified field within the
current record to be interpolated, so that for example a replacement
string C<%{001}/%{245a}> in a MARC-record substitution will cause the
text that matches the regular expression to be replaced by the
contents of the C<001> and C<245$a> fields separated by a slash.

This mechanism yields a powerful and general facility allowing
installations with complex requirements to generate exactly the detail
they need. For example, it can be used to implement fallbacks, as in
this case where if C<952$2> has no value it's replaced by the value in
C<952$b>. (This could be used for situations like reporting the
item-level copy-number if that's present, but falling back to the
holdings-level copy-number if not.)

  "952$2": [
    { "op": "regsub", "pattern": "^$", "replacement": "%{952$b}" }
  ]

Or a location string could be built in the C<$z> subfield from
fragments in the C<$1>, C<$2> and C<$2> subfields:

  "952$z": [
    { "op": "regsub", "pattern": ".*", "replacement": "%{952$1}/%{952$2}/%{952$3}" }
  ]


=item C<flags>

Optionally, a set of flags such as C<g> for global replacement, C<i>
for case-insensitivity, etc. See
L<Using regular expressions in Perl|https://perldoc.perl.org/perlretut#Using-regular-expressions-in-Perl>.

=back

=back

For example, the MARC post-processing directive

      "245$a": [
        { "op": "stripDiacritics" },
        { "op": "regsub", "pattern": "[abc]", "replacement": "*", "flags": "g" }
      ]

Says first to remove all diacritics from the C<245$a> (title) field of
the MARC record (so that for example C<é> becomes C<e>), then to
replace all vowels with asterisks.


=head1 CONFIGURATION STACKING

To implement both multi-tenancy and per-database output tweaks that may be required for specific Z39.50 client application, it is necessary to allow flexibility in the configuration of the server, based both on Z39.50 database name and on further specifications. Three levels of configuration are therefore supported.

=over 4

=item 1

A base configuration file is always used, and will typically provide the bulk of the configuration that is the same for all supported databases. Its base name is specified when the server is invoked -- for example, as the argument to the C<-c> command-line option of C<z2folio>: when the server is invoked as C<z2folio -c etc/config> the base configuration file is found at C<etc/config.json>.

=item 2

The Z39.50 database name provided in a search is used as a name of a sub-configuration specific to that database. So for example, if a Z39.50 search request come in for the database C<theo>, then the additional database-specific configuration file C<etc/config.theo.json> is also consulted. Often this file will specify the FOLIO tenant to be used for this database.

Values provided in a database-specific configuration are added to those of the base configuration, overriding the base values when the same item is provided at both levels.

=item 3

One or more I<filters> may also be used to specify additional configuration. These are specified as part of the Z39.50 database name, separated from the main part of the name by pipe characters (C<|>). For example, if the database name C<theo|foo|bar> is used, then two additional filter-specific configuration files are also read, C<etc/config.foo.json> and C<etc/config.bar.json>. The values of filter-specific configurations override those of the base or database-specific configuration, and those of later filters override those of earlier filters.

=back

In the example used here, then, a server launched with C<z2folio -c etc/config> and serving a search against the Z39.50 database C<theo|foo|bar> will consult four configuration files:
C<etc/config.json>,
C<etc/config.theo.json> (if present),
C<etc/config.foo.json>
and
C<etc/config.bar.json>.

This scheme allows us to handle several scenarios in a uniform way:

=over 4

=item *

Basic configuration all in one place

=item *

Database-specific overrides, such as the FOLIO tenant and any customer-specific definition of ISBN searching (see issue ZF-24) in the database configuration, leaving the standard definition to apply to other tenants.

=item *

Application-specific overrides, such as those needed by the ABLE client (see issue ZF-25), specified only in a filter that is not used except when explicitly requested.

=back

=head1 CONFIGURING FILTERS

By design, the FOLIO Z39.50 server follows L<the "Mechanism, Not Policy" approach|https://wiki.c2.com/?MechanismNotPolicy>: it is not opinionated about what kinds of records should be returned, how holdings should be encoded in MARC, etc. — instead, it invites institutions to configure it according to their preference.

In some cases, that preference is for suppressed-from-discovery records to be omitted. So the configuration needs to be set up accordingly. The way to do this is with the C<queryFilter> configuration item, which is used to provide a query fragment that gets C<and>ed with every query submitted by the client.

The configuration file could be modified to include, at the top level:

  "queryFilter": "cql.allRecords=1 NOT discoverySuppress=true"

This could be done either in the top-level configuration, in a database-specific configuration, or in a filter configuration.

When this was used this against a good-sized institution's test service, a search for "water" found 19395 records, as opposed to 39181 when the filter was not in place. Search time remained around one or two seconds.

L<A more rigorous filter|https://wiki.folio.org/display/FOLIOtips/Searching> can be used:

  "queryFilter": "cql.allRecords=1 NOT discoverySuppress=true NOT holdingsItems.discoverySuppress=true NOT item.discoverySuppress=true"

But as this is more complex, it has an impact on performance — as is the case when this query is used in the Inventory app's "query search". When this was used against the same institution's test service Chicago's test service, the "water" search came down to 19395 records, but it took nearly a minute to run.

Or an intermediate version can be used that omits both suppressed instances and suppressed holdings, but not suppressed items. This got the result count down to 38791 — as one would expect, more than when only instances are suppress, but less then when items are also suppressed — and took two or three seconds.

It's up to an individual installation to decide which trade-off best suits them. This trade-off may change as FOLIO's indexing changes: for example, if an index is added that makes the omit-instances-with-suppressed-items search much faster, that may become a more attractive option.

=head1 SEE ALSO

=over 4

=item The C<z2folio> script conveniently launches the server.

=item C<Net::Z3950::FOLIO> is the library that consumes this configuration.

=item The C<Net::Z3950::SimpleServer> handles the Z39.50 service.

=back

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2022 The Open Library Foundation

This software is distributed under the terms of the Apache License,
Version 2.0. See the file "LICENSE" for more information.

=cut

1;

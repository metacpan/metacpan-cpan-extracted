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

    my $cfg = compile_config($cfgbase, @extras);
    return bless $cfg, $class;
}


sub compile_config {
    my($cfgbase, @extras) = @_;

    my $cfg = compile_config_file($cfgbase, undef, MISSING_ERROR);

    my $isFirst = 1;
    while (@extras) {
	my $extra = shift @extras;
	my $overlay = compile_config_file($cfgbase, $extra, $isFirst ? MISSING_TENANT : MISSING_FILTER);
	$isFirst = 0;
	merge_config($cfg, $overlay);
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


sub compile_config_file {
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
    expand_variable_references($cfg);
    return $cfg;
}


sub expand_variable_references {
    my($obj) = @_;

    foreach my $key (sort keys %$obj) {
	$obj->{$key} = expand_single_variable_reference($key, $obj->{$key});
    }

    return $obj;
}

sub expand_single_variable_reference {
    my($key, $val) = @_;

    if (ref($val) eq 'HASH') {
	return expand_variable_references($val);
    } elsif (ref($val) eq 'ARRAY') {
	return [ map { expand_single_variable_reference($key, $_) } @$val ];
    } elsif (!ref($val)) {
	return expand_scalar_variable_reference($key, $val);
    } else {
	die "non-hash, non-array, non-scalar configuration key '$key'";
    }
}

sub expand_scalar_variable_reference {
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


sub merge_config {
    my($base, $overlay) = @_;

    my @known_keys = qw(okapi login indexMap);
    foreach my $key (@known_keys) {
	if (defined $overlay->{$key}) {
	    if (ref $base->{$key} eq 'HASH') {
		merge_hash($base->{$key}, $overlay->{$key});
	    } else {
		$base->{$key} = $overlay->{$key};
	    }
	}
    }

    foreach my $key (sort keys %$overlay) {
	if (!grep { $key eq $_ } @known_keys) {
	    $base->{$key} = $overlay->{$key};
	}
    }
}


sub merge_hash {
    my($base, $overlay) = @_;

    foreach my $key (sort keys %$overlay) {
	$base->{$key} = $overlay->{$key};
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
    "chunkSize": 5
    "marcHoldings": {
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

=head2 C<marcHoldings>

An optional object specifying how holdings and item-level data should
be mapped into MARC fields. It contains four elements:

=over 4

=item C<field>

A string specifying which MARC field should be used for holdings
information. When a record contains multiple holdings, a separate
instance of this MARC field is created for each holding.

=item C<indicators>

An array containing two strings, each of them specifying one of the
two indicators to be used in the MARC field that contains
holdings. There must be exactly two elements: blank indicators can
be specified as a single space.

information.

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

=item C<_volume>

=item C<_yearCaption>

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
fields retrieved from the back-end. At present, the only supported key
is C<marc>, which specifies transformations to be applied to MARC
records (either standalone or as part of OPAC records); in the future,
post-processing for JSON and XML records may also be supported.

Within the C<marc> sections, keys are the names of simple MARC fields,
such as C<008>; or of complex field$subfield combinations, such as
C<245$a>. The corresponding values specify the transformations that
should be applied to the values of these fields and subfields.

Transformations are represented by objects with an C<op> key whose
values specifies the required operation. Either single transformation
or an array of transformations may be provided.

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

=head1 SEE ALSO

=over 4

=item The C<z2folio> script conveniently launches the server.

=item C<Net::Z3950::FOLIO> is the library that consumes this configuration.

=item The C<Net::Z3950::SimpleServer> handles the Z39.50 service.

=back

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 The Open Library Foundation

This software is distributed under the terms of the Apache License,
Version 2.0. See the file "LICENSE" for more information.

=cut

1;

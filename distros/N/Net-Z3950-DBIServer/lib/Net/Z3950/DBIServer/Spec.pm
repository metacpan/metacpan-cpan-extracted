# $Id: Spec.pm,v 1.27 2008-07-16 18:37:33 mike Exp $

package Net::Z3950::DBIServer::Spec;
use strict;


=head1 NAME

Net::Z3950::DBIServer::Spec - The zSQLgate Configuration File Format


=head1 SYNOPSIS

C<zSQLgate> configuration files are free-form and treat all whitespace
equivalently, with the sole exception of comments.  Related directives
are grouped together with braces, with sections of detailed
information nested within more general sections.

Apart from a few top-level declarations such as the data-source and
authentication credentials to use, the bulk of a typical configuration
file consists of a set of one or more per-database sections, each
describing a single Z39.50 database (corresponding to a single table
of the relational database).  Each such per-database section has a
subsection specifying how searching should be handled and another
about retrieval, which in turn is broken into stanzas describing each
of the record formats to be supported.

=cut

=head1 DESCRIPTION

Comments are introduced by a hash character (C<#>), and run to the end
of the line.  They are ignored.  Comments are the only part of the
configuration file syntax that treats lines specially: otherwise the
syntax is totally free-form.

The contents of the file must follow this BNF grammar, where C<config>
is the start production.

	config		= chunk*

	chunk		= DATASOURCE '=' STRING
			| USERNAME '=' STRING
			| PASSWORD '=' STRING
			| OPTION STRING '=' string_or_num
			| perDb

	string_or_num	= STRING
			| NUMBER

	perDB		= DATABASE DBNAME '{' section* '}'

	section		= TABLE '=' TABLENAME
			| AUXILIARY TABLENAME WITH CONDITION
			| RESTRICTION '=' STRING
			| JOIN '=' STRING # "implicit" or "outer"
			| searchSpec
			| dataSpec

	searchSpec	= SEARCH attrsetSpec
			| SEARCH '{' attrsetSpec* '}'

	attrsetSpec	= ATTRSET oidSpec '{' accessSpec* '}'
			| DEFAULTATTRS attrs

	attrs		= attr
			| attr ',' attrs

	attr		= NUMBER '=' NUMBER

	oidSpec		= oid
			| SYMBOL
			| STRING

	oid		= NUMBER
			| NUMBER '.' oid

	accessSpec	= ACCESS NUMBER '=' modifier* COLUMNNAME

	modifier	= FULLTEXT
			| UPPERCASE

	dataSpec	= DATA formatSpec
			| DATA '{' formatSpec* '}'

	formatSpec	= CACHESIZE NUMBER
			| FORMAT GRS1 grsFormatSpec
			| FORMAT XML xmlFormatSpec
			| FORMAT MARC xmlFormatSpec
			| FORMAT SUTRS xmlFormatSpec

	grsFormatSpec	= '{' grs1ElementSpec* '}'

	grs1ElementSpec	= FIELD tagPath '=' COLUMNNAME
			| COLUMN COLUMNNAME '=' tagPath # DEPRECATED

	tagPath		= tag+

	tag		= '(' NUMBER ',' tag-val ')'

	tag-val		= NUMBER
			| STRING

	xmlFormatSpec	= '{' xmlElementSpec* '}'

	xmlElementSpec	= RECORD '=' STRING
			| ATTRS '=' STRING
			| TRANSFORM '=' FILENAME
			| SCHEMA '=' IDENTIFIER
			| FIELD TAGNAME '=' COLUMNNAME
			| COLUMN COLUMNNAME '=' TAGNAME # DEPRECATED

	DBNAME		= STRING
	TABLENAME	= STRING
	CONDITION	= STRING
	COLUMNNAME	= STRING
	FILENAME	= STRING
	TAGNAME		= STRING

I didn't initially write prose describing what the various sections
mean, because I thought this format was likely to change a fair bit
before it stabilised enough for that to be worthwhile.  Now, though
(April 2005) the format is stable, and descriptive prose should
follow.  However, work on the tutorial takes precedence.


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Sunday 24th February 2002.

=cut

1;

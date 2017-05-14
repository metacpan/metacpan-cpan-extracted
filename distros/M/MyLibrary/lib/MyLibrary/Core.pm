package MyLibrary;

use MyLibrary::Facet;
use MyLibrary::Librarian;
use MyLibrary::Resource;
use MyLibrary::Resource::Location;
use MyLibrary::Resource::Location::Type;
use MyLibrary::Term;
use strict;
use warnings;

our $VERSION = '3.0.4';

=head1 NAME 

MyLibrary - a database-driven website application for libraries


=head1 SYNOPSIS

  use MyLibrary::Core;


=head1 DESCRIPTION

MyLibrary is a set of object-oriented Perl modules designed to facilitate I/O against a specific, underlying database structure. At its heart, the database contains a table for information resources, and this table is described, for the most part, using Dublin Core. The database also contains tables for creating a controlled vocabulary of your own design. This controlled vocabulary, in the shape of facets and terms, are used to describe and classify the items in the resources table.

These modules facilitate the normal get and set methods found in other database interfaces. The modules also facilitate various find methods allowing you to extract sets of information resources. the developer is expected to loop through these sets of data and output them in format so desired which might include HTML, XML, plain text, etc.

Using these modules the developer could:

=over 4

=item * import data from MARC records

=item * import data from OAI repositories

=item * develop an interface for manual data-entry

=item * create reports, feed them to an indexer, and facilitate search

=item * create reports, format them as HTML, and save them to the file system

=item * write CGI scripts that generate dynamic pages

=item * write CGI scripts and output XML thus implementing a Web Service

=back

To get started, read the PODs for MyLibrary::Facet, MyLibrary::Term, and MyLibrary::Resource.

=head1 AUTHORS

=over 4

=item * Eric Lease Morgan <emorgan@nd.edu>

=item * Rob Fox <rfox2@nd.edu>

=back

=cut

sub version { return $VERSION }

1;

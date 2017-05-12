package RDF::Server::Constants;

use strict;
use warnings;

use vars qw(%EXPORT_TAGS @ISA @EXPORT_OK);
use Exporter;

@ISA = qw( Exporter );

my @APP = qw(APP_NS);

my @ATOM = qw(ATOM_NS);

my @FOAF = qw(FOAF_NS);

my @RSS1 = qw(RSS1_NS);

my @DC = qw(DC_NS);

my @COMMENT = qw(COMMENT_NS);

my @XML = qw(XML_NS);

my @RDF = qw(RDF_NS);

my @RDFS = qw(RDFS_NS);


my @STATUS = qw(HTTP_OK HTTP_NOT_FOUND HTTP_METHOD_NOT_ALLOWED);


my @ALL = (@APP, @ATOM, @FOAF, @RSS1, @DC, @COMMENT, @XML, @RDF, @RDFS, @STATUS);

my @NS = grep { /_NS$/ } @ALL;



%EXPORT_TAGS = (
    all => \@ALL,
    ns => \@NS,
    app => \@APP,
    atom => \@ATOM,
    foaf => \@FOAF,
    rss1 => \@RSS1,
    dc => \@DC,
    comment => \@COMMENT,
    xml => \@XML,
    rdf => \@RDF,
    rdfs => \@RDFS,
    status => \@STATUS
);

@EXPORT_OK = (@ALL);


# APP

use constant APP_NS => 'http://www.w3.org/2007/app';

# ATOM

use constant ATOM_NS => 'http://www.w3.org/2005/Atom';

# FOAF
use constant FOAF_NS    => 'http://xmlns.com/foaf/0.1/';

# RSS1
use constant RSS1_NS    => 'http://purl.org/rss/1.0/';

# DC
use constant DC_NS      => 'http://purl.org/dc/elements/1.1/';

# COMMENT
use constant COMMENT_NS => 'http://purl.org/net/rssmodules/blogcomments/';

# XML
use constant XML_NS     => 'http://www.w3.org/XML/1998/namespace';

# RDF
use constant RDF_NS     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

# RDFS
use constant RDFS_NS    => 'http://www.w3.org/2000/01/rdf-schema#';

# STATUS
use constant HTTP_OK    => 200;
use constant HTTP_NOT_FOUND => 404;
use constant HTTP_METHOD_NOT_ALLOWED => 405;

1;

__END__

=pod

=head1 NAME

RDF::Server::Constants - useful constants used by the framework

=head1 SYNOPSIS

 use RDF::Server::Constants qw(HTTP_OK :rdf);

=head1 DESCRIPTION

A number of constants are available.  These are grouped into various categories.

=head1 CONSTANTS

=head2 :all

This will import all of the constants provided by this module.

=head2 :ns

This will import all of the namespace constants (i.e., those ending in _NS).
Each of the XML namespace categories has a _NS constant for that namespace
(e.g., FOAF has FOAF_NS).

=head2 FOAF (:foaf)

=head2 RSS1 (:rss1)

=head2 DC (:dc)

=head2 COMMENT (:comment)

=head2 XML (:xml)

=head2 ATOM (:atom)

=head2 APP (:app)

=head2 RDF (:rdf)

=head2 RDFS (:rdfs)

=head2 HTTP Status (:status)

=head1 TODO

Only namespaces and a few HTTP status codes are defined at present.  These
will be expanded in a future release.

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut


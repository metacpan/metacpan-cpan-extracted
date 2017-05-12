package Solr::HTTPUpdateHandler;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use File::Slurp qw(slurp);
use Log::Log4perl qw(:easy);

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK =
  qw(add _fixXmlEndTag delete_by_id delete_by_query commit optimize _postRequest add_by_file _logAddDeletes _logPost post_file);

our $VERSION = '0.03';

sub new {
    my $class    = shift;
    my (%params) = @_;
    my $self     = \%params;
    bless( $self, $class );
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;
    unless ( $self->{schema}->{update_post_url} ) {
        die "$! No update_post_url supplied to Solr::HTTPUpdateHandler\n";
    }
    return $self;
}

sub add {

    my $self = shift;

    my ($hash, $timeout) = @_;

    my $addHash;

    foreach my $key ( keys %{$hash} ) {

        # flush out hash ref to create solrXML format
        $addHash->{"field name=\"$key\""} = $hash->{$key};

    }

    # make solrXml
    my $xml = "<add>\n";

    $xml .= XMLout(
        $addHash,
        NumericEscape => 2,
        ContentKey    => 'name',
        NoAttr        => 1,
        RootName      => 'doc',
    );

    $xml .= "</add>\n";

    # remove extra part of end string to fit solrXML format
    $xml = $self->_fixXmlEndTag($xml);

    $self->_postRequest($xml, "add", $timeout);

    return $self;
}

sub add_by_file {
    # add_by_file and post_file differ in logging.
    # add_by_file will parse out the uniqueID element and log the addition of each
    # uniqueID added to the index.  post_file, simply logs the filename of the posted file.

    my $self = shift;

    my ($file, $timeout) = @_;

    if ( -f $file ) {


        my $content = slurp($file);

        $self->_postRequest($content, "add_by_file", $timeout);

    }

    else {

        ERROR("$! file not found, $file");

    }

    return $self;
}

sub post_file {
    # add_by_file and post_file differ in logging.
    # add_by_file will parse out the uniqueID element and log the addition of each
    # uniqueID added to the index.  post_file, simply logs the filename of the posted file.

    my $self = shift;

    my ($file, $timeout) = @_;

    if ( -f $file ) {


        my $content = slurp($file);

        $self->_postRequest($content, "post_file $file", $timeout);

    }

    else {

        ERROR("$! file not found, $file");

    }

    return $self;
}

sub delete_by_id {
    my $self = shift;
    my ($id, $timeout) = @_;
    $self->_postRequest("<delete><id>$id</id></delete>", "delete_by_id", $timeout);
    return $self;
}

sub delete_by_query {
    my $self = shift;
    my ($query, $timeout) = @_;
    $self->_postRequest("<delete><query>$query</query></delete>", "delete_by_query", $timeout);
    return $self;
}

sub commit {
    my $self = shift;
    $self->_postRequest("<commit/>","commit", 600);
    return $self;
}

sub optimize {
    my $self = shift;
    my ($timeout) = @_;
    $self->_postRequest("<optimize/>","optimize", $timeout);
    return $self;
}

sub _postRequest {
    my $self      = shift;
    my ($content, $type, $timeout) = @_;
    $timeout ||= 600;
    my $ua        = LWP::UserAgent->new;
    $ua->timeout($timeout);
    $ua->agent("SolrHTTPUpdateHandlerAgent");
    my $req = HTTP::Request->new( POST => $self->{schema}->{update_post_url} );
    $req->content_type('Content-type:text/xml; charset=utf-8');
    $req->content($content);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ( $res->is_success ) {
        if ($res->content eq '<result status="0"></result>') {
            # log the uniqueKey's in the posted content
            $self->_logPost($content, $type);
        }
        else {
            ERROR("Post Type: $type Error: \"$content\"");
        }
    }
    else {
        ERROR($content);
        ERROR( $res->status_line );
    }
    return $self;
}

sub _fixXmlEndTag {
    my $self = shift;
    my ($xml) = @_;
    my $rv;
    my @lines = split /\n/, $xml;
    foreach my $line (@lines) {
        $line =~ s/<\/field name="\w+">/<\/field>/g;
        $rv .= $line;
        $rv .= "\n";
    }
    return $rv;
}

sub _logPost {
    # intended to take content and type of successful posts and parse into log file info
    my $self = shift;
    my ($content, $type) = @_;
    if ($type eq "commit") {
        INFO("Commit Successfully posted.");
    }
    elsif ($type eq "delete_by_id") {
        $content =~ m/<delete><id>(\w+)<\/id><\/delete>/;
        INFO("$self->{schema}->{uniqueKey} $1 successfully removed from index.");
    }
    elsif ($type eq "delete_by_query") {
        # this is less than perfect.  Mark for future fix.
        my $logString = $content;
        chomp $logString;
        $logString =~s/^\s+<delete><query>//g;
        $logString =~s/<\/query><\/delete>//g;
        INFO("Delete by query: \"$logString\" successfully processed");
    }
    elsif (($type eq "add") || ($type eq "add_by_file")) {
        my @content = split /\n/, $content;
        my @uniqueKeyStrings = grep /$self->{schema}->{uniqueKey}/, @content;
        my $addString ='';
        foreach my $key (@uniqueKeyStrings) {
            chomp $key;
            $key =~ s/^\s+//g;
            $key =~ s/<field name=\"$self->{schema}->{uniqueKey}\">//g;
            $key =~ s/<\/field>$//g;
            # log it
            $addString .= "$self->{schema}->{uniqueKey} $key added to solr index\n";
        }
        INFO($addString);
    }
    elsif ($type eq "optimize") {
        INFO("Solr Index Optimized\n");
    }
    elsif ($type =~ m/^post_file/g) {
        my ($garbage, $filename) = split / /, $type;
        INFO("$filename posted");
    }
    else {
        INFO("The following content succesfully posted to solr Index: \"$content\"");
    }

    return $self;
}


    

1;
__END__

=head1 NAME

Solr::HTTPUpdateHandler - Perl extension for Posting adds, updates, and deletes to a Solr Server.

=head1 SYNOPSIS

  SEE Solr.pm synopsis

=head1 DESCRIPTION

This module is part of the Solr package of modules and implements the posting functions for managing the
the data within the solr index.

=head2 EXPORT

add _fixXmlEndTag delete_by_id delete_by_query commit optimize _postRequest add_by_file _logAddDeletes 
_logPost post_file

=head1 SEE ALSO

see http://wiki.apache.org/solr/FrontPage for additional documenation on setting up and using solr.

=head1 AUTHOR

Timothy Garafola, timothy.garafola@cnet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by CNET Networks

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under
    the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied. See the License for the specific language governing
    permissions and limitations under the License.

=cut

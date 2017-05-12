package Solr;

use 5.006;
use strict;
use warnings;
use Solr::Schema;
use Solr::HTTPUpdateHandler
  qw(add _fixXmlEndTag delete_by_id delete_by_query commit optimize _postRequest add_by_file _logAddDeletes _logPost post_file);
use POSIX qw(strftime);

use Log::Log4perl;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.03';

# Preloaded methods go here.

sub new {

    my $class = shift;

    my (%params) = @_;

    my $self = \%params;

    bless( $self, $class );

    $self->_init;

    return $self;
}

sub _init {

    my $self = shift;
    
    # date string for default log file naming.
    my $date = strftime "%Y%m%d", localtime;

    # Logging (optional params that can be modified from default in initialization).
    $self->{log_dir}   ||= "./";
    $self->{info_log}  ||= "info.$date.log";
    $self->{error_log} ||= "error.$date.log";
    $self->{debug_log} ||= "debug.$date.log";

    my %log4_init;
    # unless $self->{logging_on explitly turned off by setting to 0, turn on default logging.
    unless ($self->{disable_logging})  {
        %log4_init = (
            "log4perl.logger"=> "INFO, AppWarn, AppError",

            "log4perl.filter.MatchError" => "Log::Log4perl::Filter::LevelMatch",
            "log4perl.filter.MatchError.LevelToMatch"  => "ERROR",
            "log4perl.filter.MatchError.AcceptOnMatch" => "true",

            "log4perl.filter.MatchInfo"  => "Log::Log4perl::Filter::LevelMatch",
            "log4perl.filter.MatchInfo.LevelToMatch" => "INFO",
            "log4perl.filter.MatchInfo.AcceptOnMatch" => "true",

            "log4perl.appender.AppError" => "Log::Log4perl::Appender::File",
            "log4perl.appender.AppError.filename" => "$self->{log_dir}/$self->{error_log}",
            "log4perl.appender.AppError.layout" => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.AppError.layout.ConversionPattern" => '%d %p [%c] (%F line %L) %m%n',
            "log4perl.appender.AppError.Filter"   => "MatchError",

            "log4perl.appender.AppWarn" => "Log::Log4perl::Appender::File",
            "log4perl.appender.AppWarn.filename" => "$self->{log_dir}/$self->{info_log}",
            "log4perl.appender.AppWarn.layout"   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.AppWarn.layout.ConversionPattern" => '%d %p %m%n',
            "log4perl.appender.AppWarn.Filter"   => "MatchInfo",
        );
    }
    #otherwise send fatal errors to the screen and ignore other messages.
    else {
        %log4_init = (  
            "log4perl.logger"=> "FATAL,Screen",
            "log4perl.appender.Screen" => "Log::Log4perl::Appender::Screen",
            "log4perl.appender.Screen.layout" => "SimpleLayout",
        );

    }
 

    # blessed reference to log. Log4perl handles passing this into subclasses
    $self->{log} = Log::Log4perl->init( \%log4_init );

    $self->{schema} = Solr::Schema->new(
        schema => $self->{schema},
        url    => $self->{url},
        port   => $self->{port},
    );
    # may want to put a conditional around this in the event this class is also used to interface 
    # future Search and resultHandler modules Yousef Ourabi is working on.
    $self->{HTTPUpdateHandler} = Solr::HTTPUpdateHandler->new(
        schema => $self->{schema},
    );

    return $self;

}

1;
__END__

=head1 NAME

Solr - Perl extension for interfacing with Solr, a lucene based search engine.

=head1 SYNOPSIS

    use Solr;

    my $solr = Solr->new(schema=>"/home/garafolat/cpan/Solr/schema.xml",
                         port=> "8302",
                         url=> "http://solr.foobar.com",
                         log_dir=> "/var/opt/logs");

    #NOTE: timeout is an optional param for each method and is used by LWP to pass a timeout
    for waiting for a response result code from Solr.  It defaults to 600 seconds if not supplied


    $solr->add($hashRef, $timeout); # Takes a reference to a hash of hashes of fields and values, 
                            creates solr xml, and posts to server defined in constructor.
                            Note: An update is performed by adding a document with an existing 
                            uniqueID field.

    $solr->add_by_file($file, $timeout); # simply posts a file.  The file must be in valid solr 
                            xml add syntax matching your solr server's schema for field requirements.

    $solr->post_file($file,$timeout); # posts file to solr server. Differs from add_by_file only in logging
    
    $solr->delete_by_id($id,$timeout); # Deletes by field declared as uniqueID in solr's schema.xml

    $solr->delete_by_query($query,$timeout); # Delete's by query string provided

    $solr->commit(); # commits adds and deletes

    $solr->optimize($timeout); # issues a post to solr server that causes it to perform an optimze
                               # timeout is an optional parameter expressed in seconds before 
                               # LWP stops waiting for a return result code from Solr.  Defaults
                               # to 600 if not supplied.

    For more details on solr's xml posting used by these methods see:
    http://wiki.apache.org/solr/UpdateXmlMessages#head-f5553a8214869b11708ad5476e05e7b05a024c23


    A Note On Logging
    Solr.pm uses Log4perl for logging.  Log4perl is a perl port of log4j.
    to disable logging set the optional initialization variable disable_logging=>1.

    Further reading on Log4perl can be found at:
    http://search.cpan.org/~mschilli/Log-Log4perl-1.14/lib/Log/Log4perl.pm
    http://www.perl.com/pub/a/2002/09/11/log4perl.html?page=1
    http://log4perl.sourceforge.net/releases/Log-Log4perl/docs/html/Log/Log4perl/FAQ.html

    NOTE on Adding documents
    Currently there is no error checking for in add_by_file and add methods.  It is possible to implement
    such checking using the schema object to compare fields in schema with the data structure passed into add
    or the file referenced in add_by_file.  I haven't implemented this yet, as the simply catching a 
    non zero result code from the solr server is sufficient for my needs in notifying of an error at this time.

   
    


=head1 DESCRIPTION

This module provides a set of methods for adding (updating) and deleting entries in an existing solr server.

=head1 EXPORT

None by default.

=head1 THINGS TO DO

-Add options to pass optional parameters to Solr in various post methods
-Add solr search query functionality and parsing of:
    a) xml results
    b) user defined result formats
-Incorporate Error checking of adds and deletes:
    a) Level 1, check for proper syntax
    b) Level 2, compare posts against schema for sanity check

If you'd like to make contributions to project, find bugs, or have suggestions for additions, please feel 
free to email me at the address below.

=head1 SEE ALSO

See http://wiki.apache.org/solr/FrontPage for additional documenation on setting up and using solr.  

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

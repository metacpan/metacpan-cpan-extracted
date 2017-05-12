#!/usr/bin/env perl

use strict;
use warnings;
use YAML;
use Net::OAuth2::Moosey::Client;
use Getopt::Long;
use URL::Encode qw/url_encode/;

# Get the options from the command line
my %opts;
GetOptions( \%opts,
    'client_id=s',
    'client_secret=s',
    'sql=s',
    'token_store=s',
    );

# make sure all required were given
foreach( qw/client_id client_secret token_store sql/ ){
    if( not $opts{$_} ){
	die( "Required param not defined: $_\n" );
    }
}

# Create the client
my $client = Net::OAuth2::Moosey::Client->new(
    client_id		    => $opts{client_id},
    client_secret	    => $opts{client_secret},
    site_url_base           => 'https://accounts.google.com/o/oauth2/auth',
    access_token_url_base   => 'https://accounts.google.com/o/oauth2/token',
    authorize_url_base      => 'https://accounts.google.com/o/oauth2/auth',
    scope                   => 'https://www.google.com/fusiontables/api/query',
    token_store		    => $opts{token_store},
    );

# Put together post arguments.  These are the same as for LWP::UserAgent
# and depend on the service provider.
# First:    URI to post the query to
# Second:   The headers - for fusion tables we need to submit the data as www-form-urlencoded
# Third:    The content. e.g. sql=SELECT * FROM 12345  (urlencoded of course!)
my @post_args =  ( 
    'https://www.google.com/fusiontables/api/query',
    HTTP::Headers->new( Content_Type => 'application/x-www-form-urlencoded' ),
    sprintf( 'sql=%s', url_encode( $opts{sql} ) ),
    );

my $response = $client->post( @post_args );

# Print the result out
print $response->decoded_content;

exit( 0 );

=head1 NAME

fusion_tables_demo.pl - Make an SQL request on google fusion tables

=head1 SYNOPSIS

fusion_tables_demo.pl --client_id 372296649547.apps.googleusercontent.com \
    --client_secret AseL38Set3rjlfql7ljCuw4i --token_store /tmp/my_temporary_oauth_store \
    --sql="SHOW TABLES"

The first time you run the scirpt you will be prompted to open a URL in your browser and
after authorizing your application, paste the access code into the console to continue.
On subsequent requests you should not need to re-authorize your application. 

=head1 COPYRIGHT

Copyright 2011, Robin Clarke

=head1 AUTHOR

Robin Clarke C<perl@robinclarke.net>

=cut


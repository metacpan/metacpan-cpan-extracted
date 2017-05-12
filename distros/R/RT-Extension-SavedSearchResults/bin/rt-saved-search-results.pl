#!/usr/bin/env perl
#
# RT Script to dump results from a SavedSearch.
#
# This is a helper script for RT::Extension::SavedSearchResults
#
# Author: http://alisterwest.com (2013)
#
BEGIN {
    use FindBin qw/$Bin/;
    use lib "$Bin/../../../../local/lib", "$Bin/../../../../lib";
}
use strict;
use warnings;
use feature qw/say/;

use Data::Dumper; $Data::Dumper::Sortkeys++;
use File::Basename qw/basename/;
use CGI::Cookie;
use LWP::UserAgent;

use RT;
use RT::Interface::Web;
use RT::Ticket;
use RT::User;

# --------------------------------------------------------------------------------
# Configuration

my $SS_ID  = shift or Usage(); # Takes last digits from input string
my $TARGET = shift or Usage();

my $RT_USER_ID = 'root';
my $RT_PORT = '8011';
my $DEBUG = 0;

# --------------------------------------------------------------------------------

# Setup - Load RT, establish DB connections, etc..
#
$|++;
use RT;
RT::LoadConfig();
RT::Init();

sub Usage {
    say "  Usage: ". basename($0) ." <SAVED_SEARCH_ID>  <TARGET_FILENAME>";
    say "     Eg: ". basename($0) ."  8  yesterday.tsv";
    exit(1);
}

sub info  { my $msg = shift; $msg = Dumper $msg if ref $msg; say $msg; }
sub debug { info(@_) if $DEBUG; }

# --------------------------------------------------------------------------------
# MAIN
#

# Create valid Session for our reporting user.
my ($cookie_name, $session_id) = create_valid_session( $RT_USER_ID );
info "_Session: $cookie_name=$session_id";

# Make sure we have a valid SavedSearch
my $search = get_savedsearch( $SS_ID );
debug $search;

# Build URL
my $url = RT->Config->Get('WebBaseURL') . "/" . RT->Config->Get('WebPath');
$url =~ s{/$}{};
$url .= "/Search/SavedSearchResults.tsv?SavedSearchId=" . $SS_ID;
info "Fetching: $url";

# Get and Save Data
my $data = get_web_content( $url, "$cookie_name=$session_id" );
write_results($TARGET, $data);
info "Saved-To: $TARGET";

# Delete our session-cookie.
clean_session( $session_id );

exit;




sub get_web_content { 
# --------------------------------------------------------------------------------
# Fetch Content from RT using the cookie we created
#
    my ($url, $cookie) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(10);

    my $request = HTTP::Request->new( GET => $url );
    $request->header( "Cookie", $cookie );

    my $response = $ua->simple_request($request);
    if ($response->is_success) {
        return $response->decoded_content;
    }
    else {
        die "Error: " . $response->status_line;
    }
}


sub write_results {
# --------------------------------------------------------------------------------
# This code is non-mason version of rt/share/html/Search/Results.tsv
# ARGS: $Format => undef, $Query => '', $OrderBy => 'id', $Order => 'ASC', $PreserveNewLines => 0
#
    my ($target, $data) = @_;
    unlink $target if -e $target;
    open (my $fh, ">", $target) or die "Error: could not open file $target";
    print $fh $data;
    close $fh;
}

sub create_valid_session {
# --------------------------------------------------------------------------------
    my $user_id = shift;
    my $user_obj = RT::CurrentUser->new();
    my ($ok, $msg) = $user_obj->Load( $user_id );
    debug "Load RT::User ($user_id): $ok, $msg";
    
    clean_session();
    tie my %session, 'RT::Interface::Web::Session', undef;
    $session{'CurrentUser'} = $user_obj;

    # SessionCookieName uses ENV{SERVER_PORT}
    local $ENV{'SERVER_PORT'} = $RT_PORT;

    my $cookie = CGI::Cookie->new(
        -name     => RT::Interface::Web::_SessionCookieName(),
        -value    => $session{_session_id},
        -path     => RT->Config->Get('WebPath'),
        -secure   => ( RT->Config->Get('WebSecureCookies') ? 1 : 0 ),
        -httponly => ( RT->Config->Get('WebHttpOnlyCookies') ? 1 : 0 ),
    );

    debug $cookie->as_string;
    return ($cookie->name, $cookie->value);
}

sub clean_session {
# --------------------------------------------------------------------------------
    my $session_id = shift or return;
    tie my %session, 'RT::Interface::Web::Session', $session_id;
    tied(%session)->delete;
}


sub get_savedsearch {
# --------------------------------------------------------------------------------
# in:  ss_id   - string of which the last part is an int id.
# out: hashref - data-struct of storable data from Attributes table. 
#
    my $ss_in = shift;
    my ($ss_id) = $ss_in =~ m/(\d+)$/;  

    my $search = RT::Attribute->new( $RT::SystemUser );
    my ($ok, $msg) = $search->Load($ss_id);
    if (!$search->id) {
        die "Failed to load SavedSearch($ss_id): $ok, $msg";
        Usage();
    }
    return $search->Content;
}

__END__


#!/usr/bin/perl

#
# This script can be used to test whether the SeeAlso::Server library
# has been installed properly. Just put it in your Webserver's cgi-bin
# or another place and make sure the Webserver can execute it as a
# perl script.
#
# This test server returns the identifier and a half the
# identifier's length number of links.
#

use CGI::Carp qw(fatalsToBrowser set_message);

BEGIN {
    sub handle_errors {
        my $msg = shift;
        print "<h1>SeeAlso::Server is not working</h1>";
        print "<p>The following error occured:</p>";
        print "<p><tt>$msg</tt></p>";
        if ($msg =~ /^Can't locate/) {
            print <<MSG
SeeAlso::Server or another perl module is not installed in your perl
include path (\@INC). You can add directories to \@INC with <tt>use lib</tt>.
If you put the <tt>lib</tt> directory of the SeeAlso-Server distribution as
a subdirectory of this script, it will be recognised automatically.</p>
MSG
        }
    }
    set_message(\&handle_errors);
}

use FindBin;
use lib "$FindBin::RealBin/lib";
use SeeAlso::Server;
use SeeAlso::Response;
use SeeAlso::Identifier;

use CGI;
my $cgi = CGI->new();
my $server = SeeAlso::Server->new( cgi => $cgi );

my $source = SeeAlso::Source->new(
    sub {
        my $identifier = shift;
        my $response = SeeAlso::Response->new($identifier);

        my $l = int ((length $identifier->value) / 2);
        for ($i=0; $i<$l; $i++) {
            $response->add($i,"","http://www.google.com/q=$l+".$identifier->value);
        }

        return $response;
    },
    ( "ShortName" => "test server" )
);

my $http = $server->query( $source );
print $http;

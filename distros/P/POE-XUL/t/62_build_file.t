#!/usr/bin/perl -w

use strict;

use POE::Component::XUL;
use File::Path;
use HTTP::Request;
use HTTP::Response;

use Test::More ( tests=> 8 );

use POE::XUL::Logging;
use t::XUL;

our $carpline;

########################
my $logdir = "t/poe-xul/log";
my $logfile = "$logdir/some_log";
my $errorfile = "$logdir/err_log";
if( -d $logdir ) {
    File::Path::rmtree( [ $logdir ] );
}

END {
    File::Path::rmtree( [ $logdir ] );
}

########################
# default logging
my $xul = t::XUL->new( { root => 't/poe-xul', port=>8881, 
                         logging => {
                            error_log   => $errorfile,
                            access_log  => $logfile,
                         }
                     } );
ok( $xul, "Created PoCo::XUL object" );

######################## test ->create_cache_file()
my $out = "t/poe-xul/include.cache";
my $in  = "t/poe-xul/include.build";
unlink $out if -f $out;

$xul->create_cache_file( $out, $in );

ok( (-f $out), "Created $out" );

open FILE, $out or die "Unable to read $out: $!";
my @content = <FILE>;
close FILE;
chomp @content;

is_deeply( \@content, [ 'this is foo', 'This is bar', 'end of foo',
                        'This is bar', 
                        'end of includes' ], "Result is well built" 
         );

unlink $out;

######################## test ->build_file()
$xul->{request}  = HTTP::Request->new( GET => '/include' );
$xul->{response} = HTTP::Response->new( 500 );
$xul->{mimetypes} = MIME::Types->new();

my $rv = $xul->build_file( '/include', 't/poe-xul/include' );

is( $rv, 200, "Nice build" );
ok( (-f $out), "Created $out" );

is_deeply( [ split "\n", $xul->{response}->content ],
           [ 'this is foo', 'This is bar', 'end of foo',
                        'This is bar', 
                        'end of includes' 
           ], "Result is well built" 
         );

unlink $out;

######################## small test of ->guess_ct()
my $ct = $xul->guess_ct( 'something.js' );
is( $ct, 'application/javascript', "Right content type of .js" );
$ct = $xul->guess_ct( 'something.js.cache' );
is( $ct, 'application/javascript', "Right content type of .js.cache" );

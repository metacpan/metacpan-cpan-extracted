#!/usr/bin/perl
# $Id: 30_logging.t 1566 2010-11-03 03:13:32Z fil $

use strict;
use warnings;

use POE;
use POE::Component::XUL;
use File::Path;
use Data::Dumper;
use FindBin;

use Test::More ( tests=> 53 );

use POE::XUL::Logging;
use t::XUL;

our $carpline;

my $logdir = "$FindBin::Bin/poe-xul/log";
my $logfile = "$logdir/some_log";
my $errorfile = "$logdir/err_log";
if( -d $logdir ) {
    File::Path::rmtree( [ $logdir ] );
}

END {
    File::Path::rmtree( [ $logdir ] );
}


# default logging
my $xul = t::XUL->new( { root => "$FindBin::Bin/poe-xul", port=>8881, 
                         logging => {
                            error_log   => $errorfile,
                            access_log  => $logfile,
                            apps => {
                                honk => 'honk',
                                bonk => {
                                    error_log => 'bonk.error_log'
                                }
                            }
                         }
                     } );
ok( $xul, "Created PoCo::XUL object" );

$xul->log_setup();

ok( -d $logdir, "Created a log dir" );
ok( -f $logfile, "Created the log file" ) 
        or die "I need $logfile";
ok( -f "$logdir/err_log", "Created the error log");

ok( -d "$logdir/honk", "Created a per-application log dir" );
ok( -f "$logdir/honk/error_log", "Created a per-application error log" );
ok( -f "$logdir/honk/access_log", "Created a per-application access log" );

ok( -d "$logdir/bonk", "Created another per-application log dir" );
ok( -f "$logdir/bonk.error_log", "Created another per-application error log" );
ok( -f "$logdir/bonk/access_log", "Created another per-application access log" );


xwarn "Hello world!";
pass( "xwarn didn't die" );

xlog "It is snowing right now.";
pass( "xlog didn't die" );

xdebug "My pants are on fire!";
pass( "xdebug didn't die" );

do_carp();
pass( "xcarp didn't die" );

my $fh = IO::File->new( $errorfile );
ok( $fh, "Opened the log file" )
        or die "$logfile: $!";
my $msgs;
{
    local $/;
    $msgs = <$fh>;
}

ok( ($msgs =~ m(WARN Hello world! at t/.+t line \d+\n) ),
                "Log contains xwarn" ) or die "Log:\n$msgs";

ok( ($msgs =~ m(It is snowing right now. at t/.+t line \d+\n) ),
                "Log contains xlog" ) or die "Log:\n$msgs";

ok( ($msgs =~ m(DEBUG My pants are on fire! at t/.+t line \d+\n) ),
                "Log contains xdebug" ) or die "Log:\n$msgs";

ok( ($msgs =~ m(WARN This is a carp message at t/.+t line $carpline)),
                "Log contains xcarp" ) or die "carpline=$carpline\nLog:\n$msgs";


###########################################################
$xul->{logging}{app} = 'honk';
xwarn "This is honk";
xlog( { message => "hello honk\n", type=>'REQ' } );

$xul->{logging}{app} = 'bonk';
xwarn "This is bonk";
xlog( { message => "hello bonk\n", type=>'REQ' } );

my @check = ( { file => File::Spec->catfile( $logdir, 'honk', 'error_log' ), 
                contain => 'WARN This is honk'
              },
              { file => File::Spec->catfile( $logdir, 'honk', 'access_log' ), 
                contain => 'hello honk'
              },
              { file => File::Spec->catfile( $logdir, 'bonk.error_log' ), 
                contain => 'WARN This is bonk'
              },
              { file => File::Spec->catfile( $logdir, 'bonk', 'access_log' ), 
                contain => 'hello bonk'
              }
            );
foreach my $c ( @check ) {
    $fh = IO::File->new( $c->{file} );
    $msgs = do { local $/; <$fh> };
    ok( ( $msgs =~ /$c->{contain}/ ), "Per-app log files" );
}


###########################################################
my @EXs;
$xul = t::XUL->new( { root => 't/poe-xul', port=>8881, 
                      logging => {
                            logger      => sub { push @EXs, $_[0] },
                        }
                  } );
ok( $xul, "Created another PoCo::XUL object" );

$xul->log_setup();

xwarn "Hello world!";
pass( "xwarn didn't die" );

xlog "It is snowing right now.";
pass( "xlog didn't die" );

xdebug "My pants are on fire!";
pass( "xdebug didn't die" );

do_carp();
pass( "xcarp didn't die" );

xlog( { type    => 'BONK', 
        message => 'This is a bonk' 
    } );
pass( "xlog w/ hashref didn't die" );

is( 0+@EXs, 6, "6 calls to my prog" )
        or die "EXs=", Dumper \@EXs;

@check = (
        { directory => 't/poe-xul/log', type=>'SETUP' },
        { caller => [ qw( main t/30_logging.t ) ], 
          message => 'Hello world!', type => 'WARN' },
        { caller => [ qw( main t/30_logging.t ) ], 
          message => 'It is snowing right now.', type => 'LOG' },
        { caller => [ qw( main t/30_logging.t ) ], 
          message => 'My pants are on fire!', type => 'DEBUG' },
        { caller => [ qw( main t/30_logging.t ), $carpline ], 
          message => 'This is a carp message', type => 'WARN' },
        { caller => [ qw( main t/30_logging.t ) ], 
          message => 'This is a bonk', type => 'BONK' },
    );

for( my $w=0; $w < @check ; $w++ ) {
    foreach my $f ( keys %{ $check[$w] } ) {
        my $expect = $check[$w]{$f};
        my $got    = $EXs[$w]{$f};
        unless( $f eq 'caller' ) {
            is( $got, $expect, "$w/$f" ) or die Dumper $EXs[$w];
        }
        else {
            for( my $e=0; $e < @$expect; $e++ ) {
                is( $got->[$e], $expect->[$e], "$w/$f/$e" );
            }
        }
    }
}



###########################################################
sub do_carp
{
    $carpline = __LINE__ + 1;
    __do_carp();
}

sub __do_carp()
{
    xcarp "This is a carp message";
}

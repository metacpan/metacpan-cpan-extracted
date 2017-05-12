#!/usr/bin/perl -w

use strict;

use FindBin;
use lib "$FindBin::Bin/..";

my $tests = 5;
use Test::More ( tests => 5 );
use POE;
# use POE::Component::Generic::Net::SSH::Perl;
use POE::Component::Generic;

sub DEBUG () { 0 }

my $daemon=0;
#eval "use POE::Component::Daemon; \$daemon++";

my $has_ssh=0;
eval "use Net::SSH::Perl; \$has_ssh++";


my $N = 1;


##########################################
use t::Config;
my $conf = $t::Config::VAR1->{ssh};

SKIP: {


    skip "SSH not configured by Makefile.PL", $tests
            unless $conf;

    if( ($ENV{HARNESS_PERL_SWITCHES}||'') =~ /Devel::Cover/) {
        $conf = 0;
        skip "Test to slow with Devel::Cover", $tests
    }


    unless( $has_ssh ) {
        $conf = 0;
        skip "Net::SSH::Perl not installed",  $tests;
    }


    unless( $conf->{password} ) {
        $conf = 0;
        skip "No password for SSH", $tests;
    }

}

exit 0 unless $conf;


##########################################
my $ssh = POE::Component::Generic->spawn(
                package => 'Net::SSH::Perl',
                object_options => [ $conf->{host}, 
                                    port     => $conf->{port}, 
                                    debug    => DEBUG,
                                    protocol => 2
                                  ],
                postbacks => { register_handler=>1 },
                alias   => 'my-ssh',
                verbose => 1,
                debug   => DEBUG,
            );

POE::Session->create( 
    inline_states => {
        _start => sub {
            $poe_kernel->alias_set( 'worker' );
            diag( "$N seconds" );
            $poe_kernel->delay( 'connect', $N );
            if( $daemon ) {
                $poe_kernel->sig( USR1=>'USR1' );
            }
        },
        USR1 => sub { Daemon->__peek( 1 ); },

        _stop => sub {
            DEBUG and warn "_stop";
        },

        ###############################
        connect => sub {
            diag( "Be patient; Net::SSH::Perl authentication is very slow." );
            $ssh->login( {event=>'login'}, $conf->{user}, $conf->{password} );
        },
        login => sub {
            my( $resp ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            $ssh->cmd( {event=>'output', wantarray=>1}, "ls -l" );
        },
        output => sub {
            my( $resp, $stdout, $stderr ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            ok( !$stderr, "Nothing on stderr" ) or die $stderr;
            ok( ($stdout =~ /\d+ $conf->{user} $conf->{user} \d+/), 
                    "Output of ls looks ls-like" )
                                    or die "Output=$stdout";


            # The parameters to register_handler are objects, so we
            # need some sort of factory glue in the Child.... maybe later
            # $ssh->register_handler( { event=>'registered' }, 
            #                                'stdout', 'cmd_stdout', 'details' );
            $ssh->shutdown;    
            return;
        },
        cmd_stdout => sub {
            my( $channel, $buffer, $details ) = @_;

            is( $details, 'details', "Got details" );
        },

        registered => sub {
            my( $resp ) = @_;
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            $ssh->cmd( {event=>'output2', wantarray=>1}, "ls -l" );
        },
        output2 => sub {
            my( $resp, $stdout, $stderr ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            ok( !$stderr, "Nothing on stderr" ) or die $stderr;
            ok( ($stdout =~ /\d+ $conf->{user} $conf->{user} \d+/), 
                    "Output of ls looks ls-like" )
                                    or die "Output=$stdout";


            $ssh->shutdown;
            return;
        },
    }    
);


$poe_kernel->run;

pass( "Sane exit" );


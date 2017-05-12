#!/usr/bin/perl -w

use strict;

use FindBin;
use lib "$FindBin::Bin/..";

sub POE::Kernel::ASSERT_EVENTS () { 1 }

my $tests = 27;
use Test::More ( tests => 27 );
use POE;
use POE::Component::Generic;

sub DEBUG () { 0 }

my $daemon=0;
# eval "use POE::Component::Daemon; \$daemon++";

my $has_ssh=0;
eval "use POE::Component::Generic::Net::SSH2; \$has_ssh++";
# warn $@ if $@;

my $N = 1;
my $alt_fork =1;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 5;
}
#$alt_fork = 0 if $^O eq 'MSWin32';


##########################################
use t::Config;
my $conf = $t::Config::VAR1->{ssh};

SKIP: {

    skip "SSH not configured by Makefile.PL", $tests
            unless $conf;

    if( $Net::SSH2::VERSION and $Net::SSH2::VERSION < 0.18 ) {
        $conf = 0;
        skip "Need Net::SSH2 version 0.18 or better", $tests;
    }


    unless( $has_ssh ) {
        $conf = 0;
        skip "Net::SSH2 not installed",  $tests;
    }

    unless( $conf->{password} ) {
        $conf = 0;
        skip "No password for SSH", $tests;
    }

}

exit 0 unless $conf;


##########################################
my $ssh = POE::Component::Generic::Net::SSH2->spawn(
                alias    => 'my-ssh2',
                verbose  => 1,
                alt_fork => $alt_fork,
                debug    => DEBUG,
            );

my $FILE = "/tmp/SSH-TEST-$$", 
my $channel;
my $stdout;

##########################################
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
            $ssh->connect( {event=>'connected'}, 
                            $conf->{host}, $conf->{port} );
        },
        connected => sub {
            $ssh->auth_password( {event=>'login'}, 
                                     $conf->{user}, $conf->{password} );
        },
        error => sub {
            my( $resp, $code, $name, $error ) = @_[ARG0, $#_];
            die "Error $name ($code) $error";
        },

        ###########
        login => sub {
            my( $resp, $OK ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            ok( $OK, "Logged in" ) or do {
                $ssh->error( {event=>'error', wantarray=>1} );
                return;
            };
            $ssh->auth_ok( {event=>'authed'} );
            return;
        },
        authed => sub {
            my( $resp, $authed ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            ok( $authed, "Logged in" ) or die "Not logged in?";

            $ssh->channel( {event=>'got_channel'} );
            return;
        },

        ###########
        got_channel => sub {
            my( $resp, $ch ) = @_[ ARG0..$#_ ];
            ok( !$resp->{error}, "No error" ) 
                    or warn "Error: $resp->{error}";

            ok( $ch, "Got a channel" );
            $channel = $ch;
            $channel->call( 'cmd', { event=>'output', 
                                     wantarray=>1 }, "ls -l" );
        },
        output => sub {
            my( $resp, $stdout ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error on exec" ) 
                                    or die "Error: $resp->{error}";

            ok( ($stdout =~ /\d+ $conf->{user} $conf->{user} \d+/), 
                    "Output of ls looks ls-like" )
                                    or die "Output=$stdout";

            undef( $channel );

            $ssh->channel( {event=>'got_channel2'} );
            return;
        },

        ###########
        got_channel2 => sub {
            my( $resp, $ch ) = @_[ ARG0..$#_ ];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";

            ok( $ch, "Got a channel" );
            $channel = $ch;
            $channel->call( 'cmd', { event=>'output2', 
                                     wantarray=>1 }, "some-error" );
        },
        output2 => sub {
            my( $resp, $stdout, $stderr ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error on exec" ) 
                                    or die "Error: $resp->{error}";

            ok( !$stdout, "No output" );
            ok( ($stderr =~ /some-error/), "Expected error message" )
                or warn "STDERR=$stderr";

            undef( $channel );
            # $ssh->shutdown();
            $ssh->channel( {event=>'setup_handlers'} );
        },

        
        ###########
        setup_handlers => sub {
            my( $resp, $ch ) = @_[ ARG0..$#_ ];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";

            ok( $ch, "Got a channel" );
            $channel = $ch;
            $stdout = '';

            $channel->handler_stderr( {}, 'h_stderr' );
            $channel->handler_stdout( {}, 'h_stdout' );
            $channel->handler_closed( {}, 'h_closed' );

            $channel->exec( {}, 'ls -l' );
        },

        h_stderr => sub {
            my( $text, $bytes ) = @_[ARG0..$#_];
            die "STDERR";
            $ssh->shutdown;    
            return;
        },
        h_stdout => sub {
            my( $text, $bytes ) = @_[ARG0..$#_];
            # warn "STDOUT: $text";
            $stdout .= $text;
            return;
        },
        h_closed => sub {
            DEBUG and warn "CLOSED";

            ok( $stdout, "Got some text from the channel->exec" );
            ok( ($stdout =~ /\d+ $conf->{user} $conf->{user} \d+/), 
                    "Output of ls looks ls-like" )
                                    or die "Output=$stdout";
            
            undef( $channel );
            $poe_kernel->yield( 'better_exec' );
        },

        ###########
        better_exec => sub {
            $stdout = '';
            # diag( "Doing ssh2->exec" );
            $ssh->exec( {}, 'ls -l', StdoutEvent => 'e_stdout', 
                                     ClosedEvent => 'e_closed', );
        },
        e_stdout => sub {
            my( $text, $bytes ) = @_[ARG0..$#_];
            # warn "STDOUT: $text";
            $stdout .= $text;
            return;
        },
        e_closed => sub {
            DEBUG and warn "CLOSED";

            ok( $stdout, "Got some text from ssh2->exec" );
            ok( ($stdout =~ /\d+ $conf->{user} $conf->{user} \d+/), 
                    "Output of ls looks ls-like" )
                                    or die "Output=$stdout";
            
            $poe_kernel->yield( 'interactive_exec' );
        },

        ###########
        interactive_exec => sub {
            $ssh->exec( {event=>'i_channel'}, "cat - >$FILE",
                                    StdoutEvent => 'i_stdout', 
                                    StderrEvent => 'i_stderr', 
                                    ClosedEvent => 'i_closed',  
                                    ErrorEvent  => 'i_error' );
        },
        i_channel => sub {
            my( $resp, $ch ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            ok( $ch, "Got a channel object" );

            $channel = $ch;
            $channel->write( {event=>'i_write2'}, "THIS IS A STRING\n" );
            
        },
        i_write2 => sub {
            my( $resp, $bytes ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            is( $bytes, 17, "Wrote 17 bytes to channel" );
            
            $channel->call( write => {event=>'i_done'}, 
                                    "This is another string\nFrom $$\n" );
        },
        i_done => sub {
            my( $resp, $bytes ) = @_[ARG0..$#_];
            ok( !$resp->{error}, "No error" ) or die "Error: $resp->{error}";
            $channel->send_eof( {} );
        },
        i_error => sub {
            my( $code, $name, $string ) = @_[ARG0..$#_];
            die "ERROR: $name $string";
        },        
        i_stderr => sub {
            my( $text, $bytes ) = @_[ARG0..$#_];
            die "STDERR: $text";
            $ssh->shutdown;    
            return;
        },
        i_stdout => sub {
            my( $text, $bytes ) = @_[ARG0..$#_];
            die "We don't want anything from stdout: $text";
            return;
        },
        i_closed => sub {
            DEBUG and warn "CLOSED";

            $ssh->cmd( {event=>'i_contents', wantarray=>1}, "cat $FILE" );
            return;
        },
        i_contents => sub {
            my( $resp, $stdout, $stderr ) = @_[ARG0..$#_];
            
            ok( $stdout, "Got some text from ssh2->cmd" );
            ok( ($stdout =~ /From $$\n/ and $stdout =~ /THIS IS A STRING/), 
                    "Looks like what we put in it" )
                                    or die "Output=$stdout";

            ### Get rid of the file            
            $ssh->cmd( {event=>'done'}, "rm -fR $FILE" );
            return;
        },
        done => sub {
            diag( "kill -USR1 $$ to see why this doesn't exit" )
                if $daemon;
            $ssh->shutdown;    
            return;
        },
    }    
);


$poe_kernel->run;

pass( "Sane exit" );


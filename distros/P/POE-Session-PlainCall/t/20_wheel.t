#!/usr/bin/perl 

use strict;
use warnings;

use POE;

use Test::More;

if( $^O eq 'MSWin32' ) {
    plan skip_all => "No thank you";
    exit 0;
} 

plan tests => 29;

#####
My::Session->spawn(<<'CODE');
$|++;
my $Q = 0;
# warn "starting";
while(<>) {
    chomp;
    print "$Q: $_\n";
    $Q++;
    # warn "Got '$_'";
    if( $_ eq 'noise' ) {
        print "DONE\n";
        exit 0;
    }
}
CODE

pass( "Built session" );
diag( "sleep 5" );

POE::Kernel->run;

pass( "Sane shutdown" );

##############################################################################
package My::Session;

use strict;
use warnings;

use Test::More;
use POE::Wheel::Run;
use POE::Session::PlainCall;

sub DEBUG () { 0 }

#######################################
sub spawn
{
    my( $package, $code ) = @_;

    POE::Session::PlainCall->create(
                    package => $package,
                    ctor_args => [ $code ],
                    args    => [ qw( bring tha noise ) ],
                    options => { debug => DEBUG, trace => DEBUG },
                    events  => { 
                            _start => '_start',
                            _stop  => '_stop',
                            sayit  => 'sayit',
                            STDERR => 'stderr',
                            STDOUT => 'stdout',
                            CLOSE  => 'close',
                            CHLD   => 'child',
                            done   => 'done',
                            check_timeout => 'timeout_check',
                            start_timeout => 'timeout_start',
                        },
                );
}

#######################################
sub new
{
    my( $package, $text ) = @_;
    return bless { text => $text, name => 'worker' }, $package
}

#######################################
sub _start
{
    my( $self, @say ) = @_;
    $self->check_poe( '_start' );
    $self->sender_is( _start => $poe_kernel->ID );

    $self->{alias} = $self->{name};
    poe->kernel->alias_set( $self->{alias} );

    $self->{wheel} = POE::Wheel::Run->new(
                            Program => 
                                [ $^X, "-we", "$self->{text}; CORE::exit 0" ],
                            StdoutEvent => 'STDOUT',
                            StderrEvent => 'STDERR',
                            CloseEvent  => 'CLOSE',
                        );
    poe->kernel->delay_add( 'sayit', 5, \@say );

    poe->kernel->sig_child( $self->{wheel}->PID, 'CHLD' );

#    poe->kernel->yield( 'sayit' );
}


#######################################
sub _stop
{
    my( $self ) = @_;
    $self->check_poe( "_stop" );
    $self->sender_is( _stop => $poe_kernel->ID );
}

#######################################
sub sayit
{
    my( $self, $say ) = @_;
#    $self->sender_is( sayit => poe->kernel->ID );
    $self->check_poe( sayit => 'sayit' );
    is_deeply( $say, [ qw( bring tha noise ) ], "Arguments" );


    $self->{say} = $say;

    $self->{wheel}->put( join "\n", @$say );
}


#######################################
sub stdout
{
    my( $self, $line, $id ) = @_;
    $self->check_poe( STDOUT => 'stdout' );

    is( $id, $self->{wheel}->ID, "STDOUT from wheel" );

    DEBUG and 
        warn "-------------------------- line='$line'";
    if( $line =~ /^(\d): (.+)/ ) {
        $self->{said}[$1] = $2;
        DEBUG and warn "--- $self [$1] = $2";
    }
    elsif( $line eq 'DONE' ) {
        poe->kernel->yield( 'done' );
    }
    else {
        die "Incoherent line $line";
    }
}

#######################################
sub stderr
{
    my( $self, $line, $id ) = @_;
    warn "ERR: $line\n";
}

#######################################
sub close
{
    my( $self, $id ) = @_;
    $self->check_poe( CLOSE => 'close' );
    is( $id, $self->{wheel}->ID, "CLOSE from wheel" );
    $self->{closed} = 1;
}

sub child
{
    my( $self, $sig, $pid ) = @_;
    DEBUG and warn "----------------------- $sig $pid";
    $self->{closed} = 1;
}


#######################################
sub done
{
    my( $self ) = @_;
    delete $self->{wheel};
    DEBUG and warn "--- $self $self->{said}";
    is_deeply( $self->{said}, $self->{say}, "Got all output" );
    $self->{count} = 10;
    $self->timeout_start;
    return;
}

#######################################
sub timeout_start
{
    my( $self ) = @_;
    return if $self->{closed};
    poe->kernel->delay_add( 'check_timeout', 1 );
#            or die "Can't set delay: $!";
}

#######################################
sub timeout_check
{
    my( $self ) = @_;
    return 1 if $self->{closed};
    $self->{count}--;
    if( $self->{count} <= 0 ) {
        die "Timeout waiting for close";
    }
    poe->kernel->yield( 'start_timeout' );
}

#######################################
sub sender_is
{
    my( $self, $state, $want ) = @_;

    is( poe->sender, $want, "Correct ->sender for $state" );
}

#######################################
sub check_poe
{
    my( $self, $event, $method ) = @_;
    is( poe->kernel->ID, $poe_kernel->ID, " ... ->kernel" );
    is( poe->state, $event, " ... ->state" );
    is( poe->method, $method, " ... ->method" ) if $method;
}






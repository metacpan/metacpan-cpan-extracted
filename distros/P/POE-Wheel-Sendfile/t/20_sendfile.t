#!/usr/bin/perl

use strict;
use warnings;

use POE;
use POE::Pipe::TwoWay;
use POE::Filter::Reference;
use POE::Filter::Stream;

use Test::More tests => 24;
BEGIN { use_ok('POE::Wheel::Sendfile') };

sub DEBUG () { 0 };


# create the pipe
my ($a_read, $a_write, $b_read, $b_write) = POE::Pipe::TwoWay->new("inet");
# flow is $b_write --> $a_read  

my $sender = Sender->spawn( $a_read );
my $reciever = Receiver->spawn( $b_read );

$poe_kernel->run();

pass( "Sane shutdown" );

###########################################################################
package Receiver;

use strict;
use POE;
use POE::Session;
use Test::More;
use File::Spec;
use File::Basename;

sub spawn
{
    my( $package, $socket ) = @_;
    my $self = bless { name=>'Receiver' }, $package;

    $self->{todo} = [ qw( step1 step2 step3 step4 ) ];

    open my $fh, '<', $0 or die "Couldn't open self: $!";
    $self->{slurped} = do { local $/; <$fh> };

    $self->{bigfile} = File::Spec->catfile( dirname( $0 ), 'bigfile' );

    POE::Session->create(
                    options => { debug => ::DEBUG, default => 1 },
                    args => [ $socket ],
                    object_states => [
                        $self => [ qw( _start _stop setup
                                       next done
                                        step1 step1_resp step2 step2_resp
                                        step3 step3_resp step4 step4_resp
                                       response error  ) ]
                    ]
                );
}

sub _start
{
    my( $self, $socket ) = @_[ OBJECT, ARG0 ];
    ::DEBUG and warn "$self->{name}: _start";
    $poe_kernel->alias_set( $self->{name} );
    $poe_kernel->yield( setup => $socket );
}

sub _stop
{
    my( $self ) = $_[OBJECT];
    ::DEBUG and warn "$self->{name}: _stop";
}

sub setup
{
    my( $self, $socket ) = @_[ OBJECT, ARG0 ];
    ::DEBUG and warn "$self->{name}: setup";
    my $wheel = POE::Wheel::Sendfile->new(
                    Handle => $socket,
                    InputEvent => 'response',
                    InputFilter => POE::Filter::Stream->new(),
                    ErrorEvent => 'error',
                    OutputFilter => POE::Filter::Reference->new(),
                );
    isa_ok( $wheel, 'POE::Wheel::Sendfile' );
    die "Can't build wheel: $@" unless $wheel;

    $self->{wheel} = $wheel;

    ::DEBUG and warn "$self->{name}: wheel=", $wheel->ID;


    $poe_kernel->yield( 'next' );
    return;
}

sub next
{
    my( $self ) = $_[OBJECT];
    $self->{step} = shift @{ $self->{todo} };
    unless( $self->{step} ) {
        $poe_kernel->yield( 'done' );
        return;
    }
    # diag( $self->{step} );
    $poe_kernel->yield( $self->{step} );
}

sub response
{
    my( $self, $data, $id ) = @_[OBJECT, ARG0, ARG1];
    ::DEBUG and diag( "Response" );
    
    my $finished = 1 if $data =~ s/DONE$//;
    $self->{accume} .= $data;

    return unless $finished;
    $poe_kernel->yield( $self->{step}. '_resp', delete $self->{accume} );
}

sub done
{
    my( $self ) = $_[OBJECT];
    # diag( "done" );
    $self->{wheel}->put( { done=> 1 } );
    $self->{wheel}->flush;
    delete $self->{wheel};
    return;
}

sub error
{
    my( $self, $op, $errnum, $errstr, $id ) = @_[ARG0..$#_];
    return if $op eq 'read' and $errnum == 0;
    warn "$op error ($errnum) $errstr";
    $self->done;
}


###########################################################
# Testing sending ourselves
sub step1
{
    my( $self ) = $_[OBJECT];
    $self->{wheel}->put( { file => $0 } );
}

sub step1_resp
{
    my( $self, $data ) = @_[OBJECT,ARG0];
    is( $data, $self->{slurped}, "Sent entire file" );
    $poe_kernel->yield( 'next' );
}

###########################################################
# Testing sending a bigger file
sub step2
{
    my( $self ) = $_[OBJECT];
    $self->{wheel}->put( { file => $self->{bigfile} } );
}

sub step2_resp
{
    my( $self, $data ) = @_[OBJECT,ARG0];
    is( length( $data ), 1024*1024, "Received 1MB" );
    like( $data, qr(^\x00+$), " ... of nulls" );

    $poe_kernel->yield( 'next' );
}

###########################################################
# Testing sending only part of a file
sub step3
{
    my( $self ) = $_[OBJECT];
    $DB::single = 1;
    $self->{wheel}->put( { file => $0, size=>1024 } );
}

sub step3_resp
{
    my( $self, $data ) = @_[OBJECT,ARG0];
    ok( $data eq substr( $self->{slurped}, 0, 1024 ), "Received only 1k" );

    $poe_kernel->yield( 'next' );
}

###########################################################
# Testing sending only offset part of a file
sub step4
{
    my( $self ) = $_[OBJECT];
    $self->{wheel}->put( { file => $0, size=>1024, offset=>1024 } );
}

sub step4_resp
{
    my( $self, $data ) = @_[OBJECT,ARG0];
    ok( $data eq substr( $self->{slurped}, 1024, 1024 ), "Received only 1k, offset by 1k" );

    $poe_kernel->yield( 'next' );
}




###########################################################################
package Sender;

use strict;
use POE;
use POE::Session;
use Test::More;

sub spawn
{
    my( $package, $socket ) = @_;
    my $self = bless { name=>'Sender' }, $package;
    POE::Session->create(
                    options => { debug => ::DEBUG, default => 1 },
                    args => [ $socket ],
                    object_states => [
                        $self => [ qw( _start _stop setup req flushed error done ) ]
                    ]
                );
}

sub _start
{
    my( $self, $socket ) = @_[ OBJECT, ARG0 ];
    ::DEBUG and warn "$self->{name}: _start";
    $poe_kernel->alias_set( $self->{name} );
    $poe_kernel->yield( setup => $socket );
}

sub _stop
{
    my( $self ) = $_[OBJECT];
    ::DEBUG and warn "$self->{name}: _stop";
    is( $self->{pending}, 0, "Nothing pending" );
}

sub setup
{
    my( $self, $socket ) = @_[ OBJECT, ARG0 ];
    ::DEBUG and warn "$self->{name}: setup";
    my $wheel = POE::Wheel::Sendfile->new(
                    Handle => $socket,
                    InputEvent => 'req',
                    InputFilter => POE::Filter::Reference->new(),
                    ErrorEvent => 'error',
                    FlushedEvent => 'flushed',
                    OutputFilter => POE::Filter::Stream->new(),
                );
    isa_ok( $wheel, 'POE::Wheel::Sendfile' );
    die "Can't build wheel: $@" unless $wheel;
    $self->{wheel} = $wheel;
    ::DEBUG and warn "$self->{name}: wheel=", $wheel->ID;
    return;
}

sub req
{
    my( $self, $req, $id ) = @_[ OBJECT, ARG0, ARG1 ];
    is( $id, $self->{wheel}->ID, "Request" );
    if( $req->{done} ) {
        ::DEBUG and warn "$self->{name} done";
        $self->done unless $self->{pending};
        $self->{done} = 1;
        return;
    }
    if( $req->{fh} ) {
        my $fh = IO::File->new;
        my $file = $req->{fh};
        $fh->open( $file ) or die "Unable to open $file: $!";
        $req->{file} = $fh;
    }

    $self->{pending}++;
    $self->{wheel}->sendfile( $req ) or die $@;
}

sub flushed
{
    my( $self, $id ) = @_[ OBJECT, ARG0, ARG1 ];
    return unless $self->{pending};

    is( $id, $self->{wheel}->ID, "$self->{name}: Flushed" );
    $self->{pending}--;
    ok( $self->{pending}>=0, " ... and it was expected" )
            or die "pending=$self->{pending}";
    if( $self->{done} and $self->{pending} == 0 ) {
        $poe_kernel->yield( 'done' );
    }
    $self->{wheel}->put( "DONE" );
    $self->{wheel}->flush;
}


sub done
{
    my( $self ) = $_[OBJECT];
    delete $self->{wheel};
    is( $self->{pending}, 0, "Nothing more pending" );
}

sub error
{
    my( $self, $op, $errnum, $errstr, $id ) = @_[OBJECT,ARG0..$#_];
    return if $op eq 'read' and $errnum == 0;
    warn "$op error ($errnum) $errstr";
    $self->done;
}


# END OF FILE

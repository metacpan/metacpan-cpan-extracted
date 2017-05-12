package t::Test;

use strict;
use warnings;

use base qw( Exporter );
use IO::Socket;
use Config;
use Test::More;

our @EXPORT = qw( my_sleep spawn_server connect_server );


#########################################
sub my_sleep
{
    my( $seconds ) = @_;
    if( $ENV{HARNESS_PERL_SWITCHES} ) {
        $seconds *= 10;
    }
    diag( "sleep $seconds" );
    sleep $seconds;
}

#########################################
sub spawn_server
{
    my ($server, @args)=@_;
    foreach my $dir ('../jaeca', '.') {
        next unless -x "$dir/$server";
        $server="$dir/$server";
        last;
    }
    my $exec = $^X || $Config{perl5} || $Config{perlpath};
#    local $ENV{PERL5LIB}=join ':', @INC;
#    $exec .= " ".join " ", map { "-I\Q$_" } @INC;
    $exec .= " -Iblib/lib"; 
    if( $ENV{HARNESS_PERL_SWITCHES} ) {
        $exec .= " $ENV{HARNESS_PERL_SWITCHES}";
    }

    $exec .= join ' ', '', $server, @args;

    unless( defined wantarray ) {
        system( $exec )==0
            or die "Unable to launch $exec: $?\n";
        my_sleep( 2 );
        return;
    }
    open EXEC, "$exec |" or die "Unable to launch $exec: $!\n";
    while(<EXEC>) {
        if( /^PORT=(\d+)/ ) {
            my $port = $1;
            diag "port=$1";
            return $1;
        }
        ::DEBUG() and warn "$server: $_";
    }
    return;
}

#########################################
sub connect_server
{
    my($port)=@_;
    $!=0;
    my $io=IO::Socket::INET->new(PeerAddr=>"localhost:$port");

    die "Can't connect to localhost:$port ($!) Maybe server startup failed?"
            unless $io;
    return $io;
}




1;
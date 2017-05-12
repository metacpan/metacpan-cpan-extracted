use strict;
use warnings;

use Alien::SeleniumRC;

my $sel_rc_port = $ENV{SELENIUM_RC_PORT} || 4446;
my $sel_rc_args = "-singleWindow -port $sel_rc_port";
my $sel_rc      = Alien::SeleniumRC::Server->new( $sel_rc_args );
$sel_rc->start;

while (1) {
    print "type 'q' to quit\n";
    my $i = <>;
    last if ($i =~ /q/);
}

$sel_rc->stop;

warn "hack alert: you'll likely need to kill the java process running selenium\n";

BEGIN{
package Alien::SeleniumRC::Server;

use Carp qw( croak );
use Test::More;

sub new {
    my ($class, $sel_arg) = @_;
    my $self = { sel_arg => $sel_arg };
    return bless $self, $class;
}

sub start {
    my ($self) = @_;

    # fork off a SeleniumRC server
    if (0 == ($self->{pid} = fork())){
        local $SIG{TERM} = sub {
            diag("SeleniumRC server $$ going down (TERM)");
            exit 0;
        };

        diag("Starting SeleniumRC in $$");
	Alien::SeleniumRC::start($self->{sel_arg})
	    or croak "Can't start SeleniumRC server: $!";
        diag("SeleniumRC server $$ going down");
        exit 1;
    }

    return $self->{pid};
}

sub stop {
    my ($self) = @_;
    if ($self->{pid} and kill(0, $self->{pid})) {
	diag("Stopping SeleniumRC " . $self->{pid});
	kill( 'TERM', $self->{pid} );
	sleep 1;
	if (kill(0, $self->{pid})) {
	    diag("Killing SeleniumRC " . $self->{pid});
	    kill( 'KILL', $self->{pid} );
	}
    }
}

sub DESTROY {
    my ($self) = @_;
    $self->stop if ($self->{pid});
}

1;

}

use strict;
use warnings;
use Danga::Socket;
use Danga::Socket::Callback;
use IO::Socket::INET;
use Socket qw/TCP_NODELAY IPPROTO_TCP/;
use IO::Handle;
use Net::Drizzle ':constants';
use Term::ANSIColor ':constants';

my $port = 9429;
my $ssock = IO::Socket::INET->new(
    LocalPort => $port,
    Type      => Socket::SOCK_STREAM,
    Proto     => Socket::IPPROTO_TCP,
    Blocking  => 0,
    Reuse     => 1,
    Listen    => 10
) or die "Error creating socket: $@\n";
$ssock->blocking(0);

sub msg { print "@_\n" }

my $drizzle = Net::Drizzle->new()
                          ->add_options(DRIZZLE_NON_BLOCKING);
my $con = $drizzle->con_create()
                  ->add_options(DRIZZLE_CON_MYSQL)
                  ->set_charset(8)
                  ->set_db('test_net_drizzle_crowler');

Danga::Socket->AddOtherFds(
    fileno($ssock) => sub {
        my $csock = $ssock->accept or return;
        IO::Handle::blocking( $ssock, 0 );
        $csock->autoflush(1);
        $csock->blocking(0);
        setsockopt( $csock, IPPROTO_TCP, TCP_NODELAY, pack( "l", 1 ) )
                    or die;

        setsockopt( $csock, Socket::IPPROTO_TCP, TCP_NODELAY, pack( "l", 1 ) )
          or die;

        OreOre::Danga::Socket::Admin->new($csock);
    }
);

&run_timer;

print "ready to connect\n";
Danga::Socket->EventLoop();
exit; # should not reach here

sub run_timer {
    Danga::Socket->AddTimer(
        1 => sub {
            print "awake by timer\n";
            my $sql = 'SELECT COUNT(*) FROM echo;';
            my $nc = $con->clone;
            $nc->query_add($sql);
            OreOre::Danga::Socket::Drizzle->new(
                con => $nc,
                query => $sql,
                callback => sub {
                    my $result = shift;
                    print BLUE, "Count of rows : " . $result->row_next->[0] . "\n", RESET;
                },
            );
            &run_timer;
        }
    );
}

{
    package OreOre::Danga::Socket::Admin;
    use base 'Danga::Socket';
    use fields 'buffer';
    use Term::ANSIColor ':constants';

    sub new {
        my ($class, $sock) = @_;
        my $self = $class->SUPER::new($sock);
        $self->watch_read(1);
        $self->watch_write(1);
        $self;
    }

    sub event_read {
        my $self = shift;
        my $dat = $self->read(20_000);
        return $self->close unless defined $dat;

        $self->{buffer} .= $$dat;
        while ($self->{buffer} =~ s/^(.*?)\r?\n//) {
            $self->_insert($1) if $1;
        }
    }

    sub _insert {
        my ($self, $dat) = @_;

        my $sql = 'INSERT INTO echo (message) values ("'.$drizzle->escape($dat).'")';
        my $nc = $con->clone;
        $nc->query_add($sql);
        OreOre::Danga::Socket::Drizzle->new(
            con => $nc,
            query => $sql,
            callback => sub {
                my $result = shift;
                print BLUE, "CALLBACK\n", RESET;
                $self->write("finished\n");
            },
        );
    }
}

{
    package OreOre::Danga::Socket::Drizzle;
    use strict;
    use warnings;
    use base 'Danga::Socket';
    use fields qw(con callback);
    use Net::Drizzle ':constants';
    use IO::Poll qw/POLLIN POLLOUT/;
    use IO::Handle;
    use Term::ANSIColor ':constants';

    sub new {
        my OreOre::Danga::Socket::Drizzle $self = shift;
        my %args = @_;
        $self = fields::new($self) unless ref $self;
        $self->{con} = $args{con};
        $self->{callback} = $args{callback};

        while (1) {
            my $ret = $self->handle_once(undef);
            if ($ret == DRIZZLE_RETURN_IO_WAIT) {
                last;
            }
        }

        die "cannot connect?" if $self->{con}->fd < 0;
        $self->SUPER::new( $self->{con}->fh );
        $self->watch_read(1);
        $self->watch_write(1);


        return $self;
    }

    sub event_read {
        my $self = shift;
        print YELLOW, "EVENT READ\n", RESET;

        $self->handle_once(POLLIN);
    }

    sub event_write {
        my $self = shift;

        $self->handle_once(POLLOUT);
    }

    sub handle_once {
        my ($self, $mode) = @_;

        if (defined $mode) {
            $self->{con}->set_revents( POLLIN|POLLOUT );
        }
        my $drizzle = $self->{con}->drizzle;
        my ($ret, $query) = $drizzle->query_run();
        if ($ret != DRIZZLE_RETURN_IO_WAIT && $ret != DRIZZLE_RETURN_OK) {
            die "query error: " . $drizzle->error(). '('.$drizzle->error_code .')';
        }
        if ($query) {
            my $result = $query->result;
            $self->close();
            my $callback = $self->{callback};
            if (defined $callback) {
                $callback->($query->result);
            }
            main::msg("finished query !!");
        }
        return $ret;
    }
}



use strict;
use warnings;
use Net::Drizzle ':constants';
use HTTP::Engine;
use Text::MicroTemplate 'render_mt';
use HTTP::Request::Common;
use POE qw(
    Component::Client::HTTP
    Session
);
use IO::Handle;
use Carp ();
use Term::ANSIColor ':constants';
use IO::Poll qw/POLLIN POLLOUT/;

=pod

please run the following queries before run this script.

    create database if not exists test_net_drizzle_crowler;
    use test_net_drizzle_crowler;
    create table if not exists entry (url text, body text) engine=innodb default charset=utf8;

=cut

sub DEBUG { print "@_\n" if $ENV{DEBUG} }
sub DEBUG2 { print "@_\n" if $ENV{DEBUG2} }
sub msg { print "@_\n" }

my @urls = qw(
    http://livedoor.com/
    http://www.hatena.ne.jp/
    http://mbga.jp/
    http://gree.jp/
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my $drizzle = Net::Drizzle->new()
                                       ->add_options(DRIZZLE_NON_BLOCKING);
            $_[HEAP]->{drizzle} = $drizzle;
            $_[KERNEL]->alias_set('drizzle');

            my $con = $drizzle->con_create()
                              ->add_options(DRIZZLE_CON_MYSQL)
                              ->set_charset(8)
                              ->set_db('test_net_drizzle_crowler');
            $_[HEAP]->{con} = $con;
        },
        query => sub {
            my ($query, $binds, $callback) = @_[ARG0, ARG1, ARG2];
            my $drizzle = $_[HEAP]->{drizzle};
            my $con     = $_[HEAP]->{con};
            
            {
                my $i=0;
                $query =~ s{\?}{"'".$drizzle->escape($binds->[$i++])."'"}eg;
            }
            msg("SEND QUERY '$query'");

            my $newcon = $con->clone();
               $newcon->query_add($query);

            my $container = {
                con      => $newcon,
                sender   => $_[SENDER]->ID,
                callback => $callback,
            };
            warn $_[SENDER]->ID;
            while (1) {
                my $ret = handle_once($_[KERNEL], $_[HEAP]->{drizzle}, $container, undef);
                if ($ret == DRIZZLE_RETURN_IO_WAIT) {
                    last;
                }
            }
            $container->{fh} = $newcon->fh;
            rewatch($_[KERNEL], $container);
        },
        handle_select => sub {
            my ($mode, $container) = ($_[ARG1], $_[ARG2]);
            return unless defined $container;
            return unless defined $container->{con};

            DEBUG("handle_select $mode, $container");
            handle_once($_[KERNEL], $_[HEAP]->{drizzle}, $container, $mode);
        },
    },
);

sub rewatch {
    my ($kernel, $container) = @_;
    return unless $container->{fh};

    my $events = $container->{con}->events;
    if ($events & POLLIN) {
        $kernel->select_read($container->{fh}, 'handle_select', $container);
        $container->{watch_read} = 1;
    } else {
        if ($container->{watch_read}) {
            $kernel->select_read($container->{fh});
            $container->{watch_read} = 0;
        }
    }
    if ($events & POLLOUT) {
        $kernel->select_write($container->{fh}, 'handle_select', $container);
        $container->{watch_write} = 1;
    } else {
        if ($container->{watch_write}) {
            $kernel->select_write($container->{fh});
            $container->{watch_write} = 0;
        }
    }
}

sub handle_once {
    my ($kernel, $drizzle, $container, $mode) = @_;

    if (defined $mode) {
        $container->{con}->set_revents( $mode == 0 ? POLLIN : POLLOUT );
    }
    my ($ret, $query) = $drizzle->query_run();
    if ($ret != DRIZZLE_RETURN_IO_WAIT && $ret != DRIZZLE_RETURN_OK) {
        die "query error: " . $drizzle->error(). '('.$drizzle->error_code .')';
    }
    rewatch($kernel, $container);
    if ($query) {
        my $result = $query->result;
        $kernel->select($container->{con}->fh);
        my ($callback, $sender) = ($container->{callback}, $container->{sender});
        if (defined $callback) {
            DEBUG2("CALLBACK TO $callback, $sender");
            $kernel->post($sender, $callback, $query->result);
        }
        undef $container->{con};
        undef $container;
        msg("finished query !!");
    }
    return $ret;
}

POE::Component::Client::HTTP->spawn(
    Agent           => 'Net::Drizzle/ExampleScript',
    Alias           => 'ua',                    # defaults to 'weeble'
    Timeout         => 10,
    FollowRedirects => 2,
);

POE::Session->create(
    inline_states => {
        _start => sub {
            DEBUG2("START COUNT STATE");
            $_[KERNEL]->yield( 'get' );
        },
        get => sub {
            DEBUG2("GET NEW COUNT");
            $_[KERNEL]->post('drizzle', 'query', 'SELECT COUNT(*) FROM entry', [], 'callback' );

            $_[KERNEL]->delay( 'get' => 1 );
        },
        callback => sub {
            my $result = $_[ARG0];
            my $count = $result->row_next->[0];
            print BLUE, "current rows: $count\n", RESET;
        }
    },
);

# main session
POE::Session->create(
    inline_states => {
        _start => sub {
            for my $url (@urls) {
                msg("enqueue $url");
                $_[KERNEL]->post('ua', 'request', 'got_response', GET($url));
            }
        },
        got_response => sub {
            my ($request_packet, $response_packet) = @_[ARG0, ARG1];
            my $request_object  = $request_packet->[0];
            my $response_object = $response_packet->[0];

            $_[KERNEL]->post('drizzle', 'query', 'INSERT INTO entry (url, body) VALUES (?, ?);',
                [ $request_object->uri, substr($response_object->content, 0, 20)]);
        },
    },
);

POE::Kernel->run;


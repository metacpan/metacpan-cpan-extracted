package Mojolicious::Plugin::ServerStatus;

use Mojo::Base 'Mojolicious::Plugin';
use Net::CIDR::Lite;
use Parallel::Scoreboard;
use JSON;
use Fcntl qw(:DEFAULT :flock);
use IO::Handle;

our $VERSION = '0.04';

my $JSON = JSON->new->utf8(0);

has conf => sub { +{} };
has skip_ps_command => 0;

sub register {
    my ($plugin, $app, $args) = @_;

    $plugin->{uptime} = time;
    $args->{allow} ||= [ '127.0.0.1', '192.168.0.0/16' ];
    $args->{path}  ||= '/server-status';
    $args->{counter_file} ||= '/tmp/counter_file';
    $args->{scoreboard} ||= '/var/run/server';
    $plugin->conf( $args ) if $args;

    if ( $args->{allow} ) {
        my @ip = ref $args->{allow} ? @{ $args->{allow} } : ($args->{allow});
        my @ipv4;
        my @ipv6;
        for (@ip) {
            # hacky check, but actual checks are done in Net::CIDR::Lite.
            if (/:/) {
                push @ipv6, $_;
            } else {
                push @ipv4, $_;
            }
        }
        if ( @ipv4 ) {
            my $cidr4 = Net::CIDR::Lite->new();
            $cidr4->add_any($_) for @ipv4;
            $plugin->{__cidr4} = $cidr4;
        }
        if ( @ipv6 ) {
            my $cidr6 = Net::CIDR::Lite->new();
            $cidr6->add_any($_) for @ipv6;
            $plugin->{__cidr6} = $cidr6;
        }
    }
    else {
        warn "[Mojolicious::Plugin::ServerStatus] 'allow' is not provided. Any host will not be able to access server-status page.\n";
    }
    
    if ( $args->{scoreboard} ) {
        my $scoreboard = Parallel::Scoreboard->new(
            base_dir => $args->{scoreboard}
        );
        $plugin->{__scoreboard} = $scoreboard;
    }

    if ( $args->{counter_file} && ! -f $args->{counter_file} ) {
        open( my $fh, '>>:unix', $args->{counter_file} )
        or die "could not open counter_file: $!";
    }

    my $r = $app->routes;
    $r->route($args->{path})->to(
        cb => sub {
            my $self = shift;
            my $req = $self->req;
            my $env = $req->env;
            my $tx  = $self->tx;

            if ( ! $plugin->allowed($tx->remote_address) ) {
                return $self->render(text => 'Forbidden', status => 403);
            }

            my ($body, $status) = $plugin->_handle_server_status;

            if ( ($env->{QUERY_STRING} || $req->url->query->to_string ||'') =~ m!\bjson\b!i ) {
                return $self->render(json => $status)
            }
            return  $self->render(text => $body, format => 'txt');
        }
    );

    $app->hook(before_dispatch => sub { 
        my $self = shift;
        my $tx  = $self->tx;
        my $req = $self->req;
        my $headers = $req->headers;
        my $env = %{ $req->env } ? $req->env
                   : { 
                        REMOTE_ADDR => $tx->remote_address,
                        HTTP_HOST   => $headers->host || '',
                        REQUEST_METHOD => $req->method,
                        REQUEST_URI => $req->url->path->to_string || '', 
                        SERVER_PROTOCOL => $req->is_secure ? 'HTTPS' : 'HTTP',
                    };
        ($env->{USER}) = defined $self->req->url->to_abs->userinfo ? (split /:/smx,$self->req->url->to_abs->userinfo,2) : '-';
        $plugin->set_state("A", $env);
    });

    $app->hook(after_render => sub { 
        my ($c, $output, $format) = @_;
        if ( $plugin->conf->{counter_file} ) {
            $plugin->counter(1, length($output) );
        }
        $plugin->set_state('.');
    });
}

my $prev={};
sub set_state {
    my $self = shift;
    return if !$self->{__scoreboard};

    my $status = shift || '_';
    my $env = shift;
    if ( $env ) {
        no warnings 'uninitialized';
        $prev = {
            remote_addr => $env->{REMOTE_ADDR},
            host => defined $env->{HTTP_HOST} ? $env->{HTTP_HOST} : '-',
            method => $env->{REQUEST_METHOD},
            uri => $env->{REQUEST_URI},
            protocol => $env->{SERVER_PROTOCOL},
            user => $env->{USER},
            time => time(),
        };
    }
    $self->{__scoreboard}->update($JSON->encode({
        %{$prev},
        pid => $$,
        ppid => getppid(),
        uptime => $self->{uptime},
        status => $status,
    }));
}

sub _handle_server_status {
    my ($self) = @_;


    my $upsince = time - $self->{uptime};
    my $duration = "";
    my @spans = (86400 => 'days', 3600 => 'hours', 60 => 'minutes');
    while (@spans) {
        my ($seconds,$unit) = (shift @spans, shift @spans);
        if ($upsince > $seconds) {
            $duration .= int($upsince/$seconds) . " $unit, ";
            $upsince = $upsince % $seconds;
        }
    }
    $duration .= "$upsince seconds";

    my $body="Uptime: $self->{uptime} ($duration)\n";
    my %status = ( 'Uptime' => $self->{uptime} );

    if ( $self->conf->{counter_file} ) {
        my ($counter,$bytes) = $self->counter;
        my $kbytes = int($bytes / 1_000);
        $body .= sprintf "Total Accesses: %s\n", $counter;
        $body .= sprintf "Total Kbytes: %s\n", $kbytes;
        $status{TotalAccesses} = $counter;
        $status{TotalKbytes} = $kbytes;
    }

    if ( my $scoreboard = $self->{__scoreboard} ) {
        my $stats = $scoreboard->read_all();
        my $idle = 0;
        my $busy = 0;

        my @all_workers = ();
        my $parent_pid = getppid;
        
        if ( $self->skip_ps_command ) {
            # none
            @all_workers = keys %$stats;
        }
        elsif ( $^O eq 'cygwin' ) {
            my $ps = `ps -ef`;
            $ps =~ s/^\s+//mg;
            for my $line ( split /\n/, $ps ) {
                next if $line =~ m/^\D/;
                my @proc = split /\s+/, $line;
                push @all_workers, $proc[1] if $proc[2] == $parent_pid;
            }
        }
        elsif ( $^O !~ m!mswin32!i ) {
            my $psopt = $^O =~ m/bsd$/ ? '-ax' : '-e';
            my $ps = `LC_ALL=C command ps $psopt -o ppid,pid`;
            $ps =~ s/^\s+//mg;
            for my $line ( split /\n/, $ps ) {
                next if $line =~ m/^\D/;
                my ($ppid, $pid) = split /\s+/, $line, 2;
                push @all_workers, $pid if $ppid == $parent_pid;
            }
        }
        else {
            # todo windows?
            @all_workers = keys %$stats;
        }

        my $process_status = '';
        my @process_status;
        for my $pid ( @all_workers  ) {
            my $json = $stats->{$pid};
            my $pstatus = eval { 
                $JSON->decode($json || '{}');
            };
            $pstatus ||= {};
            if ( $pstatus->{status} && $pstatus->{status} eq 'A' ) {
                $busy++;
            }
            else {
                $idle++;
            }

            if ( defined $pstatus->{time} ) {
                $pstatus->{ss} = time - $pstatus->{time};
            }
            $pstatus->{pid} ||= $pid;
            delete $pstatus->{time};
            delete $pstatus->{ppid};
            delete $pstatus->{uptime};
            $process_status .= sprintf "%s\n", 
                join(" ", map { defined $pstatus->{$_} ? $pstatus->{$_} : '' } qw/pid status remote_addr host user method uri protocol ss/);
            push @process_status, $pstatus;
        }
        $body .= <<EOF;
BusyWorkers: $busy
IdleWorkers: $idle
--
pid status remote_addr host user method uri protocol ss
$process_status
EOF
        chomp $body;
        $status{BusyWorkers} = $busy;
        $status{IdleWorkers} = $idle;
        $status{stats} = \@process_status;
    }
    else {
       $body .= "WARN: Scoreboard has been disabled\n";
       $status{WARN} = 'Scoreboard has been disabled';
    }
    return ($body, \%status);

}

sub allowed {
    my ( $self , $address ) = @_;
    if ( $address =~ /:/) {
        return unless $self->{__cidr6};
        return $self->{__cidr6}->find( $address );
    }
    return unless $self->{__cidr4};
    return $self->{__cidr4}->find( $address );
}

sub counter {
    my $self = shift;
    my $parent_pid = getppid;
    if ( ! $self->{__counter} ) {
        open( my $fh, '+<:unix', $self->conf->{counter_file} ) or die "cannot open counter_file: $!";
        $self->{__counter} = $fh;
        flock $fh, LOCK_EX;
        my $len = sysread $fh, my $buf, 10;
        if ( !$len || $buf != $parent_pid ) {
            seek $fh, 0, 0;
            syswrite $fh, sprintf("%-10d%-20d%-20d", $parent_pid, 0, 0);
        } 
        flock $fh, LOCK_UN;
    }
    if ( @_ ) {
        my ($count, $bytes) = @_;
        $count ||= 1;
        $bytes ||= 0;
        my $fh = $self->{__counter};
        flock $fh, LOCK_EX;
        seek $fh, 10, 0;
        sysread $fh, my $buf, 40;
        my $counter = substr($buf, 0, 20);
        my $total_bytes = substr($buf, 20, 20);
        $counter ||= 0;
        $total_bytes ||= 0;
        $counter += $count;
        if ($total_bytes + $bytes > 2**53){ # see docs
            $total_bytes = 0;
        } else {
            $total_bytes += $bytes;
        }
        seek $fh, 0, 0;
        syswrite $fh, sprintf("%-10d%-20d%-20d", $parent_pid, $counter, $total_bytes);
        flock $fh, LOCK_UN;
        return $counter;
    }
    else {
        my $fh = $self->{__counter};
        flock $fh, LOCK_EX;
        seek $fh, 10, 0;
        sysread $fh, my $counter, 20;
        sysread $fh, my $total_bytes, 20;
        flock $fh, LOCK_UN;
        return $counter + 0, $total_bytes + 0;
    }
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::ServerStatus - show server status like Apache's mod_status

=head1 SYNOPSIS

    # Lite
    plugin 'ServerStatus' => {
        path => '/server-status',
        allow => [ '127.0.0.1', '192.168.0.0/16' ],
    };

    # Full Mojolicious
    $self->plugin(
		'ServerStatus' => {
			path  => '/server-status',
			allow => ['127.0.0.1', '192.168.0.0/16'],
			scoreboard => "/some/other/dir",
		}
	);

	# test 
    % curl http://server:port/server-status
    Uptime: 1234567789
    Total Accesses: 123
    BusyWorkers: 2
    IdleWorkers: 3
    --
    pid status remote_addr host method uri protocol ss
    20060 A 127.0.0.1 localhost:10001 GET / HTTP/1.1 1
    20061 .
    20062 A 127.0.0.1 localhost:10001 GET /server-status HTTP/1.1 0
    20063 .
    20064 .

    # JSON format
    % curl http://server:port/server-status?json
    {"Uptime":"1332476669","BusyWorkers":"2",
     "stats":[
       {"protocol":null,"remote_addr":null,"pid":"78639",
        "status":".","method":null,"uri":null,"host":null,"ss":null},
       {"protocol":"HTTP/1.1","remote_addr":"127.0.0.1","pid":"78640",
        "status":"A","method":"GET","uri":"/","host":"localhost:10226","ss":0},
       ...
    ],"IdleWorkers":"3"}

=head1 DESCRIPTION

Mojolicious::Plugin::ServerStatus displays server status in multiprocess
L<Mojolicious> servers such as morbo and hypnotoad. This module changes
status only before and after executing the application, so it cannot
monitor keepalive session and network I/O wait.

=head1 CONFIGURATIONS

=over 4

=item path

  path => '/server-status',

location that displays server status

=item allow

  allow => '127.0.0.1'
  allow => ['192.168.0.0/16', '10.0.0.0/8']

host based access control of a page of server status. supports IPv6 address.

=item scoreboard

  scoreboard => '/path/to/dir'

Scoreboard directory, Mojolicious::Plugin::ServerStatus stores processes activity information in

=item counter_file

  counter_file => '/path/to/counter_file'

Enable Total Access counter

=item skip_ps_command

  skip_ps_command => 1 or 0

ServerStatus executes `ps command` to find all worker processes. But in some systems
that does not mount "/proc" can not find any processes.
IF 'skip_ps_command' is true, ServerStatus does not `ps`, and checks only processes that
already did process requests.

=back

=head1 TOTAL BYTES

The largest integer that 32-bit Perl can store without loss of precision
is 2**53. So rather than getting all fancy with Math::BigInt, we're just
going to be conservative and wrap that around to 0. That's enough to count
1 GB per second for a hundred days.

=head1 WHAT DOES "SS" MEAN IN STATUS

Seconds since beginning of most recent request

=head1 AUTHOR

fu kai E<lt>iakuf {at} 163.comE<gt>

=head1 SEE ALSO

L<Mojolicious>

Original ServerStatus by  L<https://metacpan.org/pod/Plack::Middleware::ServerStatus::Lite>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



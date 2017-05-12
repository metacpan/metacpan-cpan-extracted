package Plack::App::OpenVPN::Status;

# ABSTRACT: Plack application to display the sessions of OpenVPN server

use strict;
use warnings;
use feature ':5.10';

use parent 'Plack::Component';
use Carp ();
use Text::MicroTemplate;
use Plack::Util::Accessor qw/renderer status_from custom_view/;

our $VERSION = '0.16'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

#
# default view (uses Twitter Bootstrap v2.x.x layout)
sub default_view {
    <<'EOTMPL' }
% my $vars = $_[0];
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>OpenVPN Status</title>
        <link href="/static/bootstrap.min.css" rel="stylesheet">
    </head>
    <body>
        <div class="container">
            <div class="row">
                <div class="page-header">
                    <h1>Active OpenVPN Sessions <small>Updated <%= $vars->{updated} %></small></h1>
                </div>
            </div>
            <div class="row">
                <p><code>Status Version #<%= $vars->{version} %></code></p>
% if (scalar @{$vars->{users}}) {
                <table class="table table-bordered table-striped table-hover">
                    <thead>
                        <tr>
                            <th class="span2">Virtual address</th>
                            <th class="span2">Common name</th>
                            <th>Remote IP (port)</th>
                            <th>Recv (from)</th>
                            <th>Xmit (to)</th>
                            <th class="span3">Connected since</th>
                        </tr>
                    </thead>
                    <tbody>
% for my $user (@{$vars->{users}}) {
                        <tr>
                            <td><tt><%= $user->{'virtual'} %></tt></td>
                            <td><%= $user->{'common-name'} %></td>
                            <td><%= $user->{'remote-ip'} %> (<%= $user->{'remote-port'} %>)</td>
                            <td><%= $user->{'rx-bytes'} %></td>
                            <td><%= $user->{'tx-bytes'} %></td>
                            <td><%= $user->{'connected'} %></td>
                        </tr>
% }
                    </tbody>
                </table>
% } else {
                <div class="alert alert-block alert-info">
                    <h4>Attention!</h4>
                    There is no connected OpenVPN users.
                </div>
% }
            </div>
        </div>
    </body>
</html>
EOTMPL

#
# some preparations
sub prepare_app {
    my ($self) = @_;

    my $t_view = $self->default_view;

    if ($self->custom_view) {
        if (ref($self->custom_view) eq 'CODE') {
            $t_view = $self->custom_view->();
        }
        else {
            Carp::croak "Parameter 'custom_view' must be a CODEREF";
        }
    }

    $self->renderer(
        Text::MicroTemplate->new(
            template   => $t_view,
            tag_start  => '<%',
            tag_end    => '%>',
            line_start => '%',
        )->build
    );
}

#
# execute application
sub call {
    my ($self, $env) = @_;

    my ($body);

    unless ($self->status_from) {
        $body = "Error: OpenVPN status file is not set!";
    }
    else {
        unless (-e $self->status_from || -r _) {
            $body = "Error: OpenVPN status file '" . $self->status_from . "' does not exist or unreadable!";
        }
        else {
            $body = $self->renderer->($self->openvpn_status);
        }
    }

    [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ $body ] ];
}

#
# parse OpenVPN status log
sub openvpn_status {
    my ($self) = @_;

    my $lines;

    {
        local $/ = undef;
        open STATUS, '<' . $self->status_from or Carp::croak "Cannot open '" . $self->status_from . "'";
        $lines = <STATUS>;
        close STATUS;
    }

    my ($st_ver, $delim, $sub);

    # guess status file version
    given ($lines) {
        when (/TITLE,/)  {
            $st_ver = 2;
            $delim  = ',';
            $sub    = \&_ovpn_status_v2_parse;
        }
        when (/TITLE\t/) {
            $st_ver = 3;
            $delim  = '\t';
            $sub    = \&_ovpn_status_v2_parse;
        }
        default {
            $st_ver = 1;
            $delim  = ',';
            $sub    = \&_ovpn_status_v1_parse;
        }
    }

    $sub->($lines, $delim, $st_ver);
}

# octets formatter
# http://en.wikipedia.org/wiki/Octet_%28computing%29
sub _adaptive_octets {
    my ($octets) = @_;

    if ($octets > 1152921504606846976) { # exbioctet (Eio) = 2^60 octets
        $octets = sprintf('%.6f Eio', $octets/1152921504606846976);
    }
    elsif ($octets > 1125899906842624) { # pebioctet (Pio) = 2^50 octets
        $octets = sprintf('%.5f Pio', $octets/1125899906842624);
    }
    elsif ($octets > 1099511627776) {    # tebioctet (Tio) = 2^40 octets
        $octets = sprintf('%.4f Tio', $octets/1099511627776);
    }
    elsif ($octets > 1073741824) {       # gibioctet (Gio) = 2^30 octets
        $octets = sprintf('%.3f Gio', $octets/1073741824);
    }
    elsif ($octets > 1048576) {          # mebioctet (Mio) = 2^20 octets
        $octets = sprintf('%.2f Mio', $octets/1048576);
    }
    elsif ($octets > 1024) {             # kibioctet (Kio) = 2^10 octets
        $octets = sprintf('%.1f Kio', $octets/1024);
    }

    $octets;
};

#
# OpenVPN status file format version #1 parser
sub _ovpn_status_v1_parse {
    my ($lines, $delim, $version) = @_;

    my $vars = {};

    my ($users, $updated);

    for (split /\n/, $lines) {
        next if /^$/;
        next if /^(OpenVPN|ROUTING TABLE|GLOBAL STATS|Max bcast|END)/;

        my @line = split $delim, $_;
        my $length = scalar(@line);

        $length == 2 && do {
            next unless $line[0] =~ /^Updated/;
            $updated = $line[1];
            next;
        };

        $length == 5 && do {
            next if $line[0] =~ /^Common Name/;
            my ($ip, $port) = split /:/, $line[1];
            $users->{$line[0]} = {
                'common-name' => $line[0],
                'remote-ip'   => $ip,
                'remote-port' => $port,
                'rx-bytes'    => _adaptive_octets($line[2]),
                'tx-bytes'    => _adaptive_octets($line[3]),
                'connected'   => $line[4],
            };
            next;
        };

        $length == 4 && do {
            next if $line[0] =~ /^Virtual Address/;
            $users->{$line[1]}->{'virtual'} = $line[0];
            $users->{$line[1]}->{'last-ref'} = $line[3];
            next;
        };
    }

    $vars = {
        'version' => $version,
        'updated' => $updated,
        'users'   => [ map { $users->{$_} } keys %$users ],
    };

    $vars;
}

#
# OpenVPN status file format version #2 and #3 parser
sub _ovpn_status_v2_parse {
    my ($lines, $delim, $version) = @_;

    my $vars = {};

    my ($users, $updated);

    for (split /\n/, $lines) {
        next if /^$/;
        next if /^(TITLE|HEADER|GLOBAL_STATS|END)/;

        my @line = split $delim, $_;
        my $length = scalar(@line);

        $length == 3 && do {
            next unless $line[0] =~ /^TIME/;
            $updated = $line[1];
            next;
        };

        $length == 8 && do {
            next unless $line[0] =~ /^CLIENT_LIST/;
            my ($ip, $port) = split /:/, $line[2];
            $users->{$line[1]} = {
                'common-name' => $line[1],
                'remote-ip'   => $ip,
                'remote-port' => $port,
                'rx-bytes'    => _adaptive_octets($line[4]),
                'tx-bytes'    => _adaptive_octets($line[5]),
                'connected'   => $line[6],
            };
            next;
        };

        $length == 6 && do {
            next unless $line[0] =~ /^ROUTING_TABLE/;
            $users->{$line[2]}->{'virtual'} = $line[1];
            $users->{$line[2]}->{'last-ref'} = $line[4];
            next;
        };
    }

    $vars = {
        'version' => $version,
        'updated' => $updated,
        'users'   => [ map { $users->{$_} } keys %$users ],
    };

    $vars;
}

1; # End of Plack::App::OpenVPN::Status

__END__

=pod

=head1 NAME

Plack::App::OpenVPN::Status - Plack application to display the sessions of OpenVPN server

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::App::File;
    use Plack::App::OpenVPN::Status;

    builder {
        mount '/static' => Plack::App::File->new(root => "/path/to/static");
        mount '/' =>
            Plack::App::OpenVPN::Status->new(
                status_from => "/path/to/openvpn/status.log"
            );
    };

=head1 DESCRIPTION

B<Plack::App::OpenVPN::Status> is an application to display active sessions of the OpenVPN server.

It parses OpenVPN status log and displays active sessions. Supported all three versions of the status log. Check the OpenVPN server documentation how to set up version. Howewer, there is no needs (and no ability, at the moment) to point version of status log. Application detect it authomatically. Also status log version will be diplayed on the generated web page.

I<Twitter Bootstrap> layout is used to diplay active OpenVPN sessions.

=head1 METHODS

=head2 new([%options])

Creates a new application. The following options are supported:

=over 4

=item B<status_from>

Path to OpenVPN server status log file. This option is B<required>. At the moment, the application can able to read versions 1, 2, 3 of the status log file.

=item B<custom_view>

Coderef used as a view to display sessions. This must be a valid Text::MicroTemplate's template. The hashref of params is passed to the view as first argument. So you can use it like this:

    % my $vars = $_[0];

Now B<$vars> contains the structure like this:

    $vars = {
        'updated' => 'Wed Dec  5 21:25:58 2012',
        'version' => '2',
        'users'   => [
            {
                'common-name' => 'cadvecisvo',
                'remote-ip'   => '1.2.3.4',
                'remote-port' => '4944',
                'rx-bytes'    => '1.21 Mio',
                'tx-bytes'    => '503.1 Kio',
                'connected'   => 'Wed Dec  5 21:16:58 2012',
                'virtual'     => '00:ff:de:ad:be:ef',
                'last-ref'    => 'Wed Dec  5 21:25:55 2012',
            }
        ]
    }

=back

=head2 default_view

This is the default view to display sessions. It uses Twitter Bootstrap layout.

=head2 openvpn_status

Parses OpenVPN status log. Automatically selects parser for given version of file.

=head2 prepare_app

See L<Plack::Component>

=head2 call

See L<Plack::Component>

=head1 SEE ALSO

L<Plack>

L<Plack::Component>

L<Text::MicroTemplate>

L<OpenVPN Manual|http://openvpn.net/index.php/open-source/documentation/manuals.html>

L<Twitter Bootstrap|https://github.com/twitter/bootstrap>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

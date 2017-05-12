package Shadowd::Connector;

use 5.010;
use strict;

use JSON;
use Config::IniFiles;
use IO::Socket;
use IO::Socket::SSL;
use Crypt::Mac::HMAC qw(hmac_hex);
use Attribute::Abstract;
use POSIX qw(strftime);

use constant {
    SHADOWD_CONNECTOR_VERSION        => '2.0.0-perl',
    SHADOWD_CONNECTOR_CONFIG         => '/etc/shadowd/connectors.ini',
    SHADOWD_CONNECTOR_CONFIG_SECTION => 'shadowd_perl',
    SHADOWD_LOG                      => '/var/log/shadowd.log',
    STATUS_OK                        => 1,
    STATUS_BAD_REQUEST               => 2,
    STATUS_BAD_SIGNATURE             => 3,
    STATUS_BAD_JSON                  => 4,
    STATUS_ATTACK                    => 5,
    STATUS_CRITICAL_ATTACK           => 6
};

=head1 NAME

Shadowd::Connector - Shadow Daemon Connector (Base)

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';

=head1 SYNOPSIS

B<Shadow Daemon> is a collection of tools to I<detect>, I<record> and I<prevent> I<attacks> on I<web applications>.
Technically speaking, Shadow Daemon is a B<web application firewall> that intercepts requests and filters out malicious parameters.
It is a modular system that separates web application, analysis and interface to increase security, flexibility and expandability.

I<Shadowd::Connector> is the base class to connect Perl applications with the Shadow Daemon background server. It is not possible
to use this module directly, because there are abstract methods that have to be implemented.

=cut

=head1 METHODS

=head2 new()

This method is a simple constructor for an object oriented interface.

=cut

sub new {
    my ($class) = @_;
    my $self = {};

    bless $self, $class;
    return $self;
}

=head2 get_client_ip()

This is an abstract method that has to be implemented by a subclass. It has to return the IP address of the client.

=cut

sub get_client_ip: Abstract;

=head2 get_caller()

This is an abstract method that has to be implemented by a subclass. It has to return the name of the caller.

=cut

sub get_caller: Abstract;

=head2 get_resource()

This is an abstract method that has to be implemented by a subclass. It has to return the the requested resource.

=cut

sub get_resource: Abstract;

=head2 gather_input()

This is an abstract method that has to be implemented by a subclass. It has to save the user input in the class attribute I<_input>.

=cut

sub gather_input: Abstract;

=head2 defuse_input($threats)

This is an abstract method that has to be implemented by a subclass. It has to remove threats from the user input.

=cut

sub defuse_input: Abstract;

=head2 gather_hashes()

This is an abstract method that has to be implemented by a subclass. It has to save the cryptographically secure checksums of the
executed script in the class attribute I<_hashes>.

=cut

sub gather_hashes: Abstract;

=head2 error()

This is an abstract method that has to be implemented by a subclass. It has to display an error message.

=cut

sub error: Abstract;

=head2 init_config()

This method initializes and loads the configuration.

=cut

sub init_config {
    my ($self) = @_;

    if (defined $ENV{'SHADOWD_CONNECTOR_CONFIG'}) {
        $self->{'_config_file'} = $ENV{'SHADOWD_CONNECTOR_CONFIG'};
    } else {
        $self->{'_config_file'} = SHADOWD_CONNECTOR_CONFIG;
    }

    $self->{'_config'} = Config::IniFiles->new(-file => $self->{'_config_file'});

    if (!$self->{'_config'}) {
        die('config error');
    }

    if (defined $ENV{'SHADOWD_CONNECTOR_CONFIG_SECTION'}) {
        $self->{'_config_section'} = $ENV{'SHADOWD_CONNECTOR_CONFIG_SECTION'};
    } else {
        $self->{'_config_section'} = SHADOWD_CONNECTOR_CONFIG_SECTION;
    }
}

=head2 get_config($key, $required, $default)

This method returns values from the configuration.

=cut

sub get_config {
    my ($self, $key, $required, $default) = @_;

    if (!$self->{'_config'}->exists($self->{'_config_section'}, $key)) {
        if ($required) {
            die($key . ' in config missing');
        } else {
            return $default;
        }
    } else {
        return $self->{'_config'}->val($self->{'_config_section'}, $key);
    }
}

=head2 get_input()

This method returns the user input that is brought together by I<gather_input>.

=cut

sub get_input {
    my ($self) = @_;

    return $self->{'_input'}
}

=head2 get_hashes()

This method returns the hashes that are brought together by I<gather_hashes>.

=cut

sub get_hashes {
    my ($self) = @_;

    return $self->{'_hashes'}
}

=head2 remove_ignored($file)

The method removes user input that should be ignored from the class attribute I<_input>.

=cut

sub remove_ignored {
    my ($self, $file) = @_;

    local $/ = undef;
    open my $handler, $file or die('could not open ignore file: ' . $!);
    binmode $handler;

    my $content = <$handler>;
    my $json = decode_json($content);

    foreach my $entry (@$json) {
        if (!defined $entry->{'path'} && defined $entry->{'caller'}) {
            if ($self->{'_caller'} eq $entry->{'caller'}) {
                $self->{'_input'} = {};

                last;
            }
        } else {
            if (defined $entry->{'caller'}) {
                if ($self->{'_caller'} ne $entry->{'caller'}) {
                    next;
                }
            }

            if (defined $entry->{'path'}) {
                delete $self->{'_input'}->{$entry->{'path'}};
            }
        }
    }

    close $handler;
}

=head2 send_input($host, $port, $profile, $key, $ssl)

This method sends the user input to the background server and return the parsed response.

=cut

sub send_input {
    my ($self, $host, $port, $profile, $key, $ssl) = @_;

    my $connection;

    if ($ssl) {
        $connection = IO::Socket::SSL->new(
            PeerHost        => $host,
            PeerPort        => $port,
            SSL_verify_mode => SSL_VERIFY_PEER,
            SSL_ca_file     => $ssl
        ) or die('network error (ssl): ' . $!);
    } else {
        $connection = IO::Socket::INET->new(
            PeerAddr => $host,
            PeerPort => $port
        ) or die('network error: ' . $!);
    }

    $connection->autoflush(1);

    my %input_data = (
        'version'   => SHADOWD_CONNECTOR_VERSION,
        'client_ip' => $self->get_client_ip,
        'caller'    => $self->get_caller,
        'resource'  => $self->get_resource,
        'input'     => $self->get_input,
        'hashes'    => $self->get_hashes
    );

    my $json = JSON->new->allow_nonref;
    $json->allow_blessed();
    my $json_text = $json->encode(\%input_data);

    print $connection $profile . "\n" . $self->sign($key, $json_text) . "\n" . $json_text . "\n";

    my $output = <$connection>;

    close $connection;

    return $self->parse_output($output);
}

=head2 parse_output($output)

This method parses the response of the background server.

=cut

sub parse_output {
    my ($self, $output) = @_;

    my $output_data = decode_json($output);

    if ($output_data->{'status'} eq STATUS_OK) {
        return {
            'attack' => 0
        };
    } elsif ($output_data->{'status'} eq STATUS_BAD_REQUEST) {
        die('bad request');
    } elsif ($output_data->{'status'} eq STATUS_BAD_SIGNATURE) {
        die('bad signature');
    } elsif ($output_data->{'status'} eq STATUS_BAD_JSON) {
        die('bad json');
    } elsif ($output_data->{'status'} eq STATUS_ATTACK) {
        return {
            'attack'   => 1,
            'critical' => 0,
            'threats'  => $output_data->{'threats'}
        };
    } elsif ($output_data->{'status'} eq STATUS_CRITICAL_ATTACK) {
        return {
            'attack'   => 1,
            'critical' => 1
        };
    } else {
        die('processing error');
    }
}

=head2 sign($key, $json)

This method signs the input with a secret key to authenticate requests without having to send the password.

=cut

sub sign {
    my ($self, $key, $json) = @_;

    return hmac_hex('SHA256', $key, $json);
}

=head2 log($message)

This method writes messages to a log file.

=cut

sub log {
    my ($self, $message) = @_;

    my $file = $self->get_config('log', 0, SHADOWD_LOG);
    open my $handler, '>>' . $file or die('could not open log file: ' . $!);

    chomp($message);
    my $datetime = strftime('%Y-%m-%d %H:%M:%S', localtime);
    print $handler $datetime . "\t" . $message . "\n";

    close $handler;
}

=head2 escape_key($key)

This method escapes keys, i.e. single elements of a path.

=cut

sub escape_key {
    my ($self, $key) = @_;

    $key =~ s/\\/\\\\/g;
    $key =~ s/\|/\\|/g;

    return $key;
}

=head2 unescape_key($key)

This method unescapes keys, i.e. single elements of a path.

=cut

sub unescape_key {
    my ($self, $key) = @_;

    $key =~ s/\\\\/\\/g;
    $key =~ s/\\\|/|/g;

    return $key;
}

=head2 split_path($path)

This method splits a path into keys.

=cut

sub split_path {
    my ($self, $path) = @_;

    return split(/\\.(*SKIP)(*FAIL)|\|/s, $path);
}

=head2 start()

This method connects the different components of the module and starts the complete protection process.

=cut

sub start {
    my ($self) = @_;

    eval {
        $self->init_config;

        $self->gather_input;
        $self->gather_hashes;

        my $ignored = $self->get_config('ignore');
        if ($ignored) {
            $self->remove_ignored($ignored);
        }

        my $status = $self->send_input(
            $self->get_config('host', 0, '127.0.0.1'),
            $self->get_config('port', 0, '9115'),
            $self->get_config('profile', 1),
            $self->get_config('key', 1),
            $self->get_config('ssl')
        );

        if (!$self->get_config('observe') && $status->{'attack'}) {
            if ($status->{'critical'}) {
                die('shadowd: stopped critical attack from client: ' . $self->get_client_ip);
            }

            if (!$self->defuse_input($status->{'threats'})) {
                die('shadowd: stopped attack from client: ' . $self->get_client_ip);
            }

            if ($self->get_config('debug')) {
                $self->log('shadowd: removed threat from client: ' . $self->get_client_ip);
            }
        }
    };

    if ($@) {
        if ($self->get_config('debug')) {
            $self->log($@);
        }

        unless ($self->get_config('observe')) {
            $self->error;
            return undef;
        }
    }

    return 1;
}

=head1 AUTHOR

Hendrik Buchwald, C<< <hb@zecure.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shadowd-connector@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Shadowd-Connector>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

It is also possible to report bugs via Github at L<https://github.com/zecure/shadowd_perl/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Shadowd::Connector


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Shadowd-Connector>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Shadowd-Connector>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Shadowd-Connector>

=item * Search CPAN

L<http://search.cpan.org/dist/Shadowd-Connector/>

=back

=head1 LICENSE AND COPYRIGHT

Shadow Daemon -- Web Application Firewall

Copyright (C) 2014-2016 Hendrik Buchwald C<< <hb@zecure.org> >>

This file is part of Shadow Daemon. Shadow Daemon is free software: you can
redistribute it and/or modify it under the terms of the GNU General Public
License as published by the Free Software Foundation, version 2.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

1; # End of Shadowd::Connector

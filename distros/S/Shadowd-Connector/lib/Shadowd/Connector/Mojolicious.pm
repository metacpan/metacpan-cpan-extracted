package Shadowd::Connector::Mojolicious;

use 5.010;
use strict;

use base 'Shadowd::Connector';

=head1 NAME

Shadowd::Connector::Mojolicious - Shadow Daemon Mojolicious Connector

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';

=head1 SYNOPSIS

B<Shadow Daemon> is a collection of tools to I<detect>, I<record> and I<prevent> I<attacks> on I<web applications>.
Technically speaking, Shadow Daemon is a B<web application firewall> that intercepts requests and filters out malicious parameters.
It is a modular system that separates web application, analysis and interface to increase security, flexibility and expandability.

I<Shadowd::Connector::Mojolicious> is the Shadow Daemon connector for Perl Mojolicious applications. To use this module you
have to create a hook that is executed on every request and pass the Mojolicious controller object to the constructor.

=head2 Mojolicious

    use Shadowd::Connector::Mojolicious;
    
    sub startup {
      my $app = shift;
    
      $app->hook(before_dispatch => sub {
        my $self = shift;
        return Shadowd::Connector::Mojolicious->new($self)->start();
      });

      # ...
    }

=head2 Mojolicious::Lite

    use Shadowd::Connector::Mojolicious;
    
    under sub {
      my $self = shift;
      return Shadowd::Connector::Mojolicious->new($self)->start();
    };

=cut

=head1 METHODS

=head2 new($query)

This method is a simple constructor for an object oriented interface. It requires a Mojolicious controller object as parameter.

=cut

sub new {
    my ($class, $query) = @_;

    my $self = $class->SUPER::new;
    $self->{'_query'} = $query;

    # Mojolicious supports cookies with shared names, so first we have to get all unique names.
    foreach my $cookie (@{$self->{'_query'}->req->cookies}) {
        $self->{'_cookies'}->{$cookie->name} = 1;
    }

    return $self;
}

=head2 get_client_ip()

This method returns the IP address of the client with the help of the controller. If Mojolicious is configured correctly this is the correct IP
address even if a reverse proxy is used.

=cut

sub get_client_ip {
    my ($self) = @_;

    return $self->{'_query'}->tx->remote_address;
}

=head2 get_caller()

This method returns the caller with the help of the controller. Since everything is routed through a front controller the selected route is the caller.

=cut

sub get_caller {
    my ($self) = @_;

    return $self->{'_query'}->req->url->path->to_string;
}

=head2 get_resource()

This method returns the request resource.

=cut

sub get_resource {
    my ($self) = @_;

    return $self->{'_query'}->req->url->to_string;
}

=head2 gather_input()

This method gathers the user input with the help of the controller.

=cut

sub gather_input {
    my ($self) = @_;

    $self->{'_input'} = {};

    foreach my $key ($self->{'_query'}->param) {
        my $path = $self->{'_query'}->req->method . '|' . $self->escape_key($key);
        my @values;

        # Mojolicious 5 has separate methods to get input with the same name.
        if ($self->{'_query'}->can('every_param')) {
            @values = @{$self->{'_query'}->every_param($key)};
        } else {
            @values = $self->{'_query'}->param($key);
        }

        if ($#values > 0){
            for my $index (0 .. $#values) {
                if (!$values[$index]->isa('Mojo::Upload')) {
                    $self->{'_input'}->{$path . '|' . $index} = $values[$index];
                }
            }
        } else {
            if (!$values[0]->isa('Mojo::Upload')) {
                $self->{'_input'}->{$path} = $values[0];
            }
        }
    }

    foreach my $key (keys %{$self->{'_cookies'}}) {
        my @values;

        if ($self->{'_query'}->can('every_cookie')) {
            @values = @{$self->{'_query'}->every_cookie($key)};
        } else {
            @values = $self->{'_query'}->cookie($key);
        }

        if ($#values > 0){
            for my $index (0 .. $#values) {
                $self->{'_input'}->{'COOKIE|' . $self->escape_key($key) . '|' . $index} = $values[$index];
            }
        } else {
            $self->{'_input'}->{'COOKIE|' . $self->escape_key($key)} = $values[0];
        }
    }

    my $headers = $self->{'_query'}->req->headers->to_hash;

    foreach my $key (keys %$headers) {
        $self->{'_input'}->{'SERVER|' . $self->escape_key($key)} = $headers->{$key};
    }
}

=head2 defuse_input($threats)

This method defuses dangerous input with the help of the controller.

=cut

sub defuse_input {
    my ($self, $threats) = @_;

    my %cookies;

    foreach my $key (keys %{$self->{'_cookies'}}) {
        my @values;

        if ($self->{'_query'}->can('every_cookie')) {
            @values = @{$self->{'_query'}->every_cookie($key)};
        } else {
            @values = $self->{'_query'}->cookie($key);
        }

        $cookies{$key} = \@values;
    }

    foreach my $path (@{$threats}) {
        my @path_split = $self->split_path($path);

        if ($#path_split < 1) {
            next;
        }

        my $key = $self->unescape_key($path_split[1]);

        if ($path_split[0] eq 'SERVER') {
            $self->{'_query'}->req->headers->header($key, '');
        } elsif ($path_split[0] eq 'COOKIE') {
            if ($#path_split == 1) {
                $cookies{$key} = [''];
            } else {
                my $array = $cookies{$key};
                $array->[$path_split[2]] = '';
                $cookies{$key} = $array;
            }
        } else {
            if ($#path_split == 1) {
                $self->{'_query'}->req->param($key, '');
            } else {
                my @values;

                if ($self->{'_query'}->can('every_param')) {
                    @values = @{$self->{'_query'}->every_param($key)};
                } else {
                    @values = $self->{'_query'}->param($key);
                }

                $values[$path_split[2]] = '';
                $self->{'_query'}->req->param($key, @values);
            }
        }
    }

    if ($self->{'_query'}->req->headers->cookie) {
        my $cookie_string = '';

        # No encoding on purpose. That's how Mojolicious roles.
        foreach my $key (keys %cookies) {
            $self->{'_query'}->cookie(@{$cookies{$key}});

            foreach my $value (@{$cookies{$key}}) {
                $cookie_string .= $key . '=' . $value . ';';
            }
        }

        # Remove last semicolon.
        chop($cookie_string);

        # Overwrite the cookie string.
        $self->{'_query'}->req->headers->cookie($cookie_string);
    }

    # Don't stop the complete request.
    return 1;
}

=head2 gather_hashes()

This module does not support the integrity check, because everything is routed through one file.

=cut

sub gather_hashes {
    my ($self) = @_;

    $self->{'_hashes'} = {};
}

=head2 error()

This method renders an error message with the help of the controller.

=cut

sub error {
    my ($self) = @_;

    $self->{'_query'}->render(data => '<h1>500 Internal Server Error</h1>', status => 500);
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

1; # End of Shadowd::Connector::Mojolicious

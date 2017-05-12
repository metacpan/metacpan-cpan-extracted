package Net::Stomp::MooseHelpers::CanConnect;
$Net::Stomp::MooseHelpers::CanConnect::VERSION = '2.9';
{
  $Net::Stomp::MooseHelpers::CanConnect::DIST = 'Net-Stomp-MooseHelpers';
}
use Moose::Role;
use Net::Stomp::MooseHelpers::Exceptions;
use Net::Stomp::MooseHelpers::Types qw(NetStompish
                                       ServerConfigList
                                       Headers
                                  );
use MooseX::Types::Moose qw(CodeRef Bool HashRef);
use Try::Tiny;
use namespace::autoclean;

# ABSTRACT: role for classes that connect via Net::Stomp


has connection => (
    is => 'rw',
    isa => NetStompish,
    lazy_build => 1,
);


has is_connected => (
    traits => ['Bool'],
    is => 'ro',
    isa => Bool,
    default => 0,
    handles => {
      _set_disconnected => 'unset',
      _set_connected => 'set',
    },
);


has connection_builder => (
    is => 'rw',
    isa => CodeRef,
    default => sub {
        sub {
            require Net::Stomp;
            my $ret = Net::Stomp->new($_[0]);
            return $ret;
        }
    },
);


has extra_connection_builder_args => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

sub _build_connection {
    my ($self) = @_;

    return $self->connection_builder->({
        %{$self->extra_connection_builder_args},
        hosts => $self->servers,
    });
}


has servers => (
    is => 'ro',
    isa => ServerConfigList,
    lazy => 1,
    coerce => 1,
    builder => '_default_servers',
    traits => ['Array'],
    handles => {
        _shift_servers => 'shift',
        _push_servers => 'push',
    },
);
sub _default_servers {
    [ { hostname => 'localhost', port => 61613 } ]
};


sub current_server {
    my ($self) = @_;

    return $self->servers->[$self->connection->current_host];
}


has connect_headers => (
    is => 'ro',
    isa => Headers,
    lazy => 1,
    builder => '_default_connect_headers',
);
sub _default_connect_headers { { } }


sub connect {
    my ($self) = @_;

    return if $self->has_connection and $self->is_connected;

    try {
        # the connection will be created by the lazy builder
        $self->connection; # needed to make sure that 'current_server'
                           # is the right one
        my $server = $self->current_server;
        my %headers = (
            %{$self->connect_headers},
            %{$server->{connect_headers} || {}},
        );
        my $response = $self->connection->connect(\%headers);
        if ($response->command eq 'ERROR') {
            die $response->headers->{message} || 'some STOMP error';
        }
        $self->_set_connected;
    } catch {
        Net::Stomp::MooseHelpers::Exceptions::Stomp->throw({
            stomp_error => $_
        });
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::MooseHelpers::CanConnect - role for classes that connect via Net::Stomp

=head1 VERSION

version 2.9

=head1 SYNOPSIS

  package MyThing;
  use Moose; with 'Net::Stomp::MooseHelpers::CanConnect';
  use Try::Tiny;

  sub foo {
    my ($self) = @_;
    SERVER_LOOP:
    while (1) {
      my $exception;
      try {
        $self->connect();

        # do something

      } catch {
        $exception = $_;
      };
      if ($exception) {
        if (blessed $exception &&
            $exception->isa('Net::Stomp::MooseHelpers::Exceptions::Stomp')) {
          warn "connection died, trying again\n";
          $self->clear_connection;
          next SERVER_LOOP;
        }
        die "unhandled exception $exception";
      }
    }
  }

=head1 DESCRIPTION

This role provides your class with a flexible way to connect to a
STOMP server. It delegates connecting to one of many server in a
round-robin fashion to the underlying L<Net::Stomp>-like library.

=head1 ATTRIBUTES

=head2 C<connection>

The connection to the STOMP server. It's built using the
L</connection_builder> (passing L</extra_connection_builder_args>, all
L</servers> as C<hosts>, and SSL flag and options). It's usually a
L<Net::Stomp> object.

=head2 C<is_connected>

True if a call to C</connect>
succeded. L<Net::Stomp::MooseHelpers::ReconnectOnFailure> resets this
when reconnecting; you should not care much about it.

=head2 C<connection_builder>

Coderef that, given a hashref of options, returns a connection. The
default builder just passes the hashref to the constructor of
L<Net::Stomp>.

=head2 C<extra_connection_builder_args>

Optional hashref to pass to the L</connection_builder> when building
the L</connection>.

=head2 C<servers>

A L<ServerConfigList|Net::Stomp::MooseHelpers::Types/ServerConfigList>,
that is, an arrayref of hashrefs, each of which describes how to
connect to a single server. Defaults to C<< [ { hostname =>
'localhost', port => 61613 } ] >>.

=head2 C<connect_headers>

Global setting for connection headers (passed to
L<Net::Stomp/connect>). Can be overridden by the C<connect_headers>
slot in each element of L</servers>. Defaults to the empty hashref.

=head1 METHODS

=head2 C<current_server>

Returns the element of L</servers> that the L</connection> says it's
connected to.

=head2 C<connect>

Call the C<connect> method on L</connection>, passing the generic
L</connect_headers> and the per-server connect headers (from
L</current_server>, slot C<connect_headers>). Throws a
L<Net::Stomp::MooseHelpers::Exceptions::Stomp> if anything goes wrong.

If the L</connection> attribute is set, and L</is_connected>, returns
without doing anything.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

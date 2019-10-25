package <%= ${controller} %>;
use Mojo::Base qw(Mojolicious::Plugin::Qooxdoo::JsonRpcController);

=head1 NAME

<%= ${controller} %> - RPC services for <%= ${class} %>

=head1 SYNOPSIS

  $route->any("jsonrpc")->to(<%= ${controller} %>#dispatch");

=head1 DESCRIPTION

This controller handles the rpc calls from the Qooxdoo frontend.

=head1 ATTRIBUTES

All the attributes from L<Mojolicious::Plugin::Qooxdoo::JsonRpcController>.

=cut

=head1 METHODS

All the methods of L<Mojolicious::Plugin::Qooxdoo::JsonRpcController> as well as:

=cut

=head1 ATTRIBUTES

The controller has the following attributes.

=cut

=head2 service

The service property defines the name of the service.

=cut

has service => sub { "<%= ${filename} %>"};

has log => sub { shift->app->log };

=head1 METHODS

The controller provides the following methods:

=cut

=head2 allow_rpc_access(method)

The dispatcher will call allow_rpc_access prior to handing over controll.

=cut

our %allow = (
    ping => 1,
    getUptime => 1,
    makeException => 1,
);


sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return $allow{$method};
}


=head2 ping(text)

The ping response.

=cut

sub ping {
    my $self = shift;
    my $text = shift;
    $self->log->info("We got pinged");
    return 'got '.$text;
}

=head2 getUptime

Return the output of uptime.

=cut

sub getUptime {
    my $self = shift;
    return `/usr/bin/uptime`;
}

=head2 makeException(code,message)

Create an exception.

=cut

sub makeException {
    my $self = shift;
    my $arg = shift;
    die Exception->new(code => $arg->{code}, message => $arg->{message} );
}

package Exception;

use Mojo::Base -base;
has 'code';
has 'message';
use overload ('""' => 'stringify');
sub stringify {
    my $self = shift;
    return "ERROR ".$self->code.": ".$self->message;
}

1;
<%= '__END__' %>

=head1 COPYRIGHT

Copyright (c) <%= ${year} %> by <%= ${fullName} %>. All rights reserved.

=head1 AUTHOR

S<<%= ${fullName} %> E<lt><%= ${email} %>E<gt>>

=cut

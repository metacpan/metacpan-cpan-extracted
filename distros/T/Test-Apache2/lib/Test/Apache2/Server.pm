package Test::Apache2::Server;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(host));

use Test::Apache2::RequestRec;
use HTTP::Response;
use attributes ();

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);
    $self->{handlers} = [];

    if (! $self->host) {
        $self->host('example.com');
    }

    return $self;
}

sub location {
    my ($self, $path, $config_ref) = @_;

    unshift @{ $self->{handlers} }, {
        path    => $path,
        handler => $config_ref->{PerlResponseHandler},
        config  => $config_ref
    };
}

sub request {
    my ($self, $req) = @_;
    $self->_request(Test::Apache2::RequestRec->new($req));
}

sub get {
    my ($self, $path) = @_;

    my $req = Test::Apache2::RequestRec->new({
        method => 'GET', uri => 'http://' . $self->host . $path,
        headers_in => {}
    });
    $self->_request($req);
}

sub _select {
    my ($self, $path) = @_;
    for my $hash_ref (@{ $self->{handlers} }) {
        my $index = index $path, $hash_ref->{path};
        if (defined $index && $index == 0) {
            return  $path, $hash_ref->{handler}, $hash_ref->{config};
        }
    }

    return;
}

sub _request {
    my ($self, $req) = @_;

    my ($location, $class, $config) = $self->_select($req->path);
    $req->location($location);
    $req->dir_config($config);

    my $buffer = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$buffer;
        my $handler = $class->can('handler');
        if (grep { $_ eq 'method' } attributes::get($handler)) {
            $class->$handler($req);
        }
        else {
            $handler->($req);
        }
    }

    if ($buffer) {
        $req->print($buffer);
    }

    return $req->to_response;
}

1;
__END__

=head1 NAME

Test::Apache2::Server - Facade of Test::Apache2

=head1 DESCRIPTION

This class is "Facade" of Test::Apache2.

=head1 CLASS METHODS

=head2 new(\%args)

Creates a new Test::Apache2::Server object.

=head1 INSTANCE METHODS

=head2 $self->location($path, \%configuration)

Sets a handler on $path.

=head2 $self->get($path)

Requests $path with GET method and returns the HTTP::Response object.

=head2 $self->request($request)

Requests with HTTP::Request object and returns the HTTP::Response object.

=cut

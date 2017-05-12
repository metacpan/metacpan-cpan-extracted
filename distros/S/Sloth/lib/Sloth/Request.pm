package Sloth::Request;
BEGIN {
  $Sloth::Request::VERSION = '0.05';
}
use Moose;
use namespace::autoclean;

use Plack::Request;

has plack_request => (
    is => 'ro',
    isa => 'Plack::Request',
    required => 1,
    handles => qr{.*}
);

has path_components => (
    required => 1,
    is => 'ro'
);

has router => (
    is => 'ro',
    required => 1
);


sub uri_for {
    my ($self, @args) = @_;
    my $qp = @args % 2 ? pop(@args) : {};
    my $relative = $self->router->uri_for(@args) or return;
    my $uri = $self->base;
    $uri->path($uri->path . $relative);
    $uri->query_form(%$qp);
    return $uri->as_string;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Sloth::Request

=head1 METHODS

=head2 uri_for

    $self->uri_for(
        resource => 'users',
        name => $user_name,
        { page => $page }
    )

Create a URI from a resource name, set of path components and an optional hash
reference of query parameters.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles <sloth.cpan@ocharles.org.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


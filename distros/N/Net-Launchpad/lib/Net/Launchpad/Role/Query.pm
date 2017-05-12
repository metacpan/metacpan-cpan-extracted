package Net::Launchpad::Role::Query;
BEGIN {
  $Net::Launchpad::Role::Query::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Query::VERSION = '2.101';
# ABSTRACT: Common pure query roles

use Moose::Role;
use Function::Parameters;
use Data::Dumper::Concise;
use Mojo::Parameters;

has result => (is => 'rw');


has ns => (is => 'rw');


method _build_resource_path ($search_name, $params) {
    my $uri = $self->lpc->__path_cons($search_name);
    return $uri->query($params);
}


method resource ($params) {
    my $uri = $self->_build_resource_path($self->ns, $params);
    $self->result($self->lpc->get($uri->to_string));
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Query - Common pure query roles

=head1 VERSION

version 2.101

=head1 ATTRIBUTES

=head2 ns

Namespace to query for, ie ('bugs'), is overridden in query roles.

=head1 METHODS

=head2 _build_resource_path

Builds a resource path with params encoded

=head2 resource

Returns resource of C<name>

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

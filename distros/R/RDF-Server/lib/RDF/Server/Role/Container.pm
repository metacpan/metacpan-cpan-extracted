package RDF::Server::Role::Container;

use Moose::Role;

with 'RDF::Server::Role::Renderable';

requires 'create';

1;

__END__

=pod

=head1 NAME

RDF::Server::Role::Container - renderable resource that holds resources

=head1 SYNOPSIS

 package My::Container;

 use Moose;

 with 'RDF::Server::Role::Container';

 sub create { }

=head1 DESCRIPTION

Containers are resources that hold other resources but are not themselves
modifiable.

=head2 Methods

=over 4

=item create

The C<create> method will create a new resource within the container instead
of creating a new container.  The path of the new resource relative to the
path of the container should be returned.  This path should result in the
resource handler if given to the container handler.

=back

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


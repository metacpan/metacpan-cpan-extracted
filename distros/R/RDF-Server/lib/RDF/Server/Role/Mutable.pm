package RDF::Server::Role::Mutable;

use Moose::Role;

with 'RDF::Server::Role::Renderable';

has deep_replace => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 }
);

requires 'delete';  # remove resource completely
requires 'modify';  # modify parts of a resource
requires 'replace'; # logically purge and create with supplied content
requires 'remove';  # purge all content directly part of resource

1;

__END__

=pod

=head1 NAME

RDF::Server::Role::Mutable - requirements for a mutable resource

=head1 SYNOPSIS

 package My::Handler

 with 'RDF::Server::Role::Mutable';

 sub create { }
 sub delete { }
 sub modify { }
 sub replace { }
 sub remove { }

=head1 DESCRIPTION

RDF::Server::Role::Mutable is a sub-role of L<RDF::Server::Role::Renderable>.  
In addition to the methods required for this role, you will also need to satisfy
the requirements of the Renderable role.

=head2 Configuration

=over 4

=item deep_replace

A flag indicating whether or not the C<replace> method should propagate to
referenced resources that have attributes specified in the supplied document.
If false, then replacement should switch to modification when crossing into an
embedded rdf:Description element (or its equivalent) that is not a blank node.

Default: false.

=back

=head2 Methods

The following methods require definitions in classes that use this role.  On
success, these methods should return a true value.  Throw a
L<RDF::Server::Exception> if status codes and messages are required 
to shed light on why a request is a failure.

If these methods return a true value, a rendering of the resource will be
returned by the server.

=over 4

=item create

=item delete

=item modify

=item remove

=item replace

=back

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut


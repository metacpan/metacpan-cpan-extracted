package Rapi::Fs::Role::Driver;

use strict;
use warnings;

# ABSTRACT: Role for Rapi::Fs driver classes

use Moo::Role;
use Types::Standard qw(:all);

has 'name', is => 'ro', isa => Str, lazy => 1, required => 1;
has 'args', is => 'ro', isa => Maybe[Str], default => sub { undef };

requires 'get_node';

# Required node_get_ methods:
requires 'node_get_parent';
requires 'node_get_parent_path';
requires 'node_get_subnodes';
requires 'node_get_bytes';
requires 'node_get_mtime';
requires 'node_get_fh';
requires 'node_get_mimetype';
requires 'node_get_link_target';
requires 'node_get_readable_file';

# Note that other node_get_* methods may be implemented, but are not required.

sub call_node_get {
  my ($self, $attr, @args) = @_;
  my $meth = "node_get_$attr";
  $self->can($meth) ? $self->$meth(@args) : undef
}



1;

__END__

=head1 NAME

Rapi::Fs::Role::Driver - Role for Rapi::Fs driver classes

=head1 SYNOPSIS

  package My::Driver;
  
  use Moo;
  with 'Rapi::Fs::Role::Driver';
  
  ...


=head1 DESCRIPTION

This is the role which must be consumed for a class to become a valid L<Rapi::Fs> driver. Most of
the code in this role simply consists of interfaces (i.e. method C<'requires'> statements). For a 
reference implementation of an actual driver class, see L<Rapi::Fs::Driver::Filesystem>.

=head1 ATTRIBUTES

=head2 name

=head2 args

=head1 METHODS

=head2 call_node_get

=head1 REQUIRES

=head2 get_node

Must be defined in subclass - accepts a path string and returns the associated Node object. 
Must also be able to accept existing Node object arg and return it back to the caller as-is.
=cut

=head2 node_get_parent

=head2 node_get_parent_path

=head2 node_get_subnodes

=head2 node_get_bytes

=head2 node_get_mtime

=head2 node_get_fh

=head2 node_get_mimetype

=head2 node_get_link_target

=head2 node_get_readable_file

=head1 SEE ALSO

=over

=item * 

L<Rapi::Fs>

=item * 

L<Rapi::Fs::Driver::Filesystem>

=item * 

L<RapidApp>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

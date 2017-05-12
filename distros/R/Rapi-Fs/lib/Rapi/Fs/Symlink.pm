package Rapi::Fs::Symlink;

use strict;
use warnings;

# ABSTRACT: Object representing a symlink

use Moo;
extends 'Rapi::Fs::File';
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

sub is_file  { 0 }
sub is_link  { 1 }

sub _has_attr {
  my $attr = shift;
  has $attr, is => 'rw', isa => Maybe[Str], lazy => 1,
  default => sub {
    my $self = shift;
    $self->driver->call_node_get( $attr => $self )
  }, @_
}

_has_attr 'link_target', is => 'ro', isa => Str;


1;

__END__

=head1 NAME

Rapi::Fs::File - Object representing a symlink

=head1 DESCRIPTION

This class is used to represent a Symlink by <Rapi::Fs>. This class is used internally and 
should not need to be instantiated directly.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Fs>

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
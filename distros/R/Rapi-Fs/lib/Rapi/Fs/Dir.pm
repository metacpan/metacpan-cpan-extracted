package Rapi::Fs::Dir;

use strict;
use warnings;

# ABSTRACT: Object representing a directory

use Moo;
extends 'Rapi::Fs::Node';
use Types::Standard qw(:all);

sub is_dir { 1 }

sub subnodes {
  my $self = shift;
  $self->driver->node_get_subnodes( $self->path )
}


1;

__END__

=head1 NAME

Rapi::Fs::Dir - Object representing a directory

=head1 DESCRIPTION

This class is used to represent a Directory by <Rapi::Fs>. This class is used internally and 
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
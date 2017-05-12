package NCC::WarpCore;
BEGIN {
  $NCC::WarpCore::AUTHORITY = 'cpan:GETTY';
}
{
  $NCC::WarpCore::VERSION = '0.001';
}
# ABSTRACT: NCC Standard WarpCore (You can make your own)

use Moose;
use Import::Into;

has root => ( is => 'rw' );

sub energize {
  my ( $self, $target ) = @_;
  $self->root($target) unless defined $self->root;
  $self->import_moose($target);
}

sub import_moose { Moose->import::into($_[1]) }

sub enervate {
  my ( $self, $target ) = @_;
  $target->meta->make_immutable;
}

1;

__END__

=pod

=head1 NAME

NCC::WarpCore - NCC Standard WarpCore (You can make your own)

=head1 VERSION

version 0.001

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

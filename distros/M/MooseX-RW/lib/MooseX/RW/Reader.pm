package MooseX::RW::Reader;
{
  $MooseX::RW::Reader::VERSION = '0.003';
}
# ABSTRACT: Moose::Role reader

use Moose::Role;

with 'MooseX::RW';

requires 'read';


sub read {
    my $self = shift;
    $self->count($self->count + 1);
}


1;

__END__
=pod

=encoding UTF-8

=head1 NAME

MooseX::RW::Reader - Moose::Role reader

=head1 VERSION

version 0.003

=head1 METHODS

=head2 read

Required method to read anything.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


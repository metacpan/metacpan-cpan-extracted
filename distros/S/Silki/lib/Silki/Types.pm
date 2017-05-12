package Silki::Types;
{
  $Silki::Types::VERSION = '0.29';
}

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw( Silki::Types::Internal MooseX::Types::Moose MooseX::Types::Path::Class )
);

1;

# ABSTRACT: Exports Silki types as well as Moose and Path::Class types

__END__
=pod

=head1 NAME

Silki::Types - Exports Silki types as well as Moose and Path::Class types

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut


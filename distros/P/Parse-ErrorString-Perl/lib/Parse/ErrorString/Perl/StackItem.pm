package Parse::ErrorString::Perl::StackItem;


use strict;
use warnings;

our $VERSION = '0.27';

sub new {
	my ( $class, $self ) = @_;
	bless $self, ref $class || $class;
	return $self;
}

use Class::XSAccessor getters => {
	sub          => 'sub',
	file         => 'file',
	file_abspath => 'file_abspath',
	file_msgpath => 'file_msgpath',
	line         => 'line',
};

1;

__END__

=head1 NAME

Parse::ErrorString::Perl::StackItem - a Perl stack item object

=head1 DESCRIPTION

=over

=item sub

The subroutine that was called, qualified with a package name (as
printed by C<use diagnostics>).

=item file

File where subroutine was called. See C<file> in
C<Parse::ErrorString::Perl::ErrorItem>.

=item file_abspath

See C<file_abspath> in C<Parse::ErrorString::Perl::ErrorItem>.

=item file_msgpath

See C<file_msgpath> in C<Parse::ErrorString::Perl::ErrorItem>.

=item line

The line where the subroutine was called.

=back

# Copyright 2008-2013 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

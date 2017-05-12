package Net::FSP::Entry;
use strict;
use warnings;
use Carp;

use overload q{""} => sub {
	return $_[0]->short_name;
};
our $VERSION = $Net::FSP::VERSION;

sub new {
	my ($class, $fsp, $name, %attributes) = @_;
	$name =~ s{ \A / }{}mx;
	return bless {
		fsp  => $fsp,
		name => $name,
		%attributes,
	}, $class;
}

for my $subname (qw/name type size time link/) {
	no strict 'refs';    ##no critic strict
	*{$subname} = sub {
		return $_[0]{$subname};
	};
}

sub move {
	my ($self, $new_name) = @_;
	$self->{fsp}->move_file($self->{name}, $new_name);
	return;
}

sub short_name {
	my $self = shift;
	$self->{name} =~ / ( [^\/]* ) \z /mx or croak "Couldn't determine short_name";
	return $1;
}

sub accept;
sub remove;
sub download;

1;

__END__

=head1 NAME

Net::FSP::Entry - An FSP directory entry

=head1 VERSION

This documentation refers to Net::FSP version 0.13

=head1 DESCRIPTION

In FSP there are two kinds of entries, files and directories. This is the
base class of the corresponding types: Net::FSP::File and Net::FSP::Dir.

=head1 METHODS

=over 4

=item name()

Returns the full name of the entry.

=item short_name

Returns the basename of the entry.

=item type()

Returns I<file> or I<dir>, depending on the type of entry.

=item move($new_location)

Move this entry to a new location.

=item remove()

Remove this entry.

=item download($sink = $self->name)

Download this entry.

=item size()

Returns the size (in bytes) of the entry.

=item time()

Returns the modification time of the entry (in seconds since UNIX epoch).

=item link()

Returns the location the symlink is pointing to, or undef if the entry is not a
symlink.

=item accept($visitor)

Accept a visitor. This visitor must be a subref.

=back

=head1 AUTHOR

Leon Timmermans, fawaka@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, 2008 Leon Timmermans. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=begin ignore

=over 4

=item new

=back

=cut


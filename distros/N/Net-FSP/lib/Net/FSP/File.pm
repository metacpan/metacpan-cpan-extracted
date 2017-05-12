package Net::FSP::File;

use strict;
use warnings;
use Net::FSP::Entry;
use base 'Net::FSP::Entry';
our $VERSION = $Net::FSP::VERSION;

sub download {
	my ($self, $sink) = @_;
	$sink = $self->{name} if not defined $sink;
	$self->{fsp}->download_file($self->{name}, $sink);
	return;
}

sub grab {
	my ($self, $sink) = @_;
	$sink = $self->{name} if not defined $sink;
	$self->{fsp}->grab_file($self->{name}, $sink);
	return;
}

sub upload {
	my ($self, $source) = @_;
	$self->{fsp}->grab_file($self->{name}, $source);
	return;
}

sub remove {
	my ($self) = @_;
	$self->{fsp}->delete_file($self->{name});
	return;
}

sub accept {
	my ($self, $visitor) = @_;
	$visitor->($self);
	return;
}

sub open {
	my ($self, $mode) = @_;
	$mode ||= '<';
	return $self->{fsp}->open_file($self->name, $mode);
}

1;

__END__

=head1 NAME

Net::FSP::File - An FSP file

=head1 VERSION

This documentation refers to Net::FSP version 0.13

=head1 DESCRIPTION

This class represents a file on the server.

=head1 METHODS

This class inherits methods I<name>, I<short_name>, I<type>, I<move>,
I<remove>, I<size>, I<time>, I<link> and I<accept> from L<Net::FSP::Entry>.

=over 4

=item download($sink = $self->name)

This method downloads the file to C<$sink>. C<$sink> must either be an
untainted filename, a filehandle or a callback function.

=item grab($sink = $self->name)

This method downloads the file and deletes it at when this is done.
These actions are considered atomic by the server. Its argument works as in
C<download>.

=item cat()

This method downloads the file and returns it as a string. Using this on large
files is not recommended.

=item upload($source)

This method overwrites a file on the server. C<$source> must either be a
filename, a filehandle or a callback function.

=item open($mode)

Open a file and return a filehandle. I<$mode> must be either B<E<lt>> or
B<E<gt>> for reading or writing respectively. Only one writing filehandle at a
time may be opened, this is a protocol restriction.

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

=item accept

=item remove

=back

=cut

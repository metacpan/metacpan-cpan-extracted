package Net::FSP::Dir;

use strict;
use warnings;
use base 'Net::FSP::Entry';
our $VERSION = $Net::FSP::VERSION;

sub list {
	my $self = shift;

	my $dir = $self->name;
	return $self->{fsp}->list_dir($self->name . '/');
}

sub download {
	my ($self, $local_dir) = @_;
	$local_dir = $self->name if not defined $local_dir;

	mkdir $local_dir if not -d $local_dir;
	for my $entry ($self->list) {
		$entry->download("$local_dir/$entry");
	}
	return;
}

sub accept {
	my ($self, $visitor) = @_;
	$visitor->($self);
	for my $entry ($self->list) {
		$entry->accept($visitor);
	}
	return;
}

sub change_current {
	my $self = shift;
	$self->{fsp}->change_dir($self->{name});
	return;
}

sub remove {
	my $self = shift;
	$self->{fsp}->remove_dir($self->{name});
	return;
}

sub readme {
	my $self = shift;
	return $self->{fsp}->get_readme($self->{name});
}

sub get_protection {
	my $self = shift;
	return $self->{fsp}->get_protection($self->{name});
}

sub set_protection {
	my ($self, $mod) = @_;
	return $self->{fsp}->get_protection($self->{name});
}

1;

__END__

=head1 NAME

Net::FSP::Dir - An FSP directory

=head1 VERSION

This documentation refers to Net::FSP version 0.13

=head1 DESCRIPTION

This class represents a file on the server.

=head1 METHODS

This class inherits methods I<name>, I<short_name>, I<type>, I<move>,
I<remove>, I<size>, I<time>, I<link> and I<accept> from L<Net::FSP::Entry>.

=over 4

=item list()

This method returns a list of files and directories in this directory. The
entries in the lists are either L<Net::FSP::File> or a L<Net::FSP::Dir> objects
for files and directories respectively.

=item download($target)

Download this whole directory to $target.

=item change_current()

Change the current directory to this directory.

=item readme()

Get the readme of this directory.

=item get_protection()

This method returns the directory's protection. It returns a hash
reference with the elements C<owner>, C<delete>, C<create>, C<mkdir>,
C<private>, C<readme>, C<list> and C<rename>.

=item set_protection($mode)

This method changes the permission of directory C<$directory_name> for public
users. It's mode argument is consists of two characters. The first byte is I<+>
or I<->, to indicate whether the permission is granted or revoked. The second
byte contains a I<c>, I<d>, I<g>, I<m>, I<l> or I<r> for the permission to
create files, delete files, get files, create directories, list the directory
or rename files.  Its return value is the same as get_protection. 

=back

=head1 TODO

=over 4

=item upload($source)

Upload a local directory to the server.

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

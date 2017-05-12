package POSIX::RT::SharedMem;
$POSIX::RT::SharedMem::VERSION = '0.10';
use strict;
use warnings;

use Exporter 5.57 'import';
use XSLoader;
use Carp qw/croak/;
use Fcntl qw/O_RDONLY O_WRONLY O_RDWR O_CREAT/;

use File::Map 'map_handle';

our @EXPORT_OK = qw/shared_open shared_unlink/;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

my $default_perms = oct '600';

my %flag_for = (
	'<'  => O_RDONLY,
	'+<' => O_RDWR,
	'>'  => O_WRONLY | O_CREAT,
	'+>' => O_RDWR | O_CREAT,
);

sub shared_open {    ## no critic (Subroutines::RequireArgUnpacking)
	my (undef, $name, $mode, %other) = @_;

	my %options = (
		perms  => $default_perms,
		offset => 0,
		flags  => 0,
		%other,
	);
	croak 'Not enough arguments for shared_open' if @_ < 2;
	$mode = '<' if not defined $mode;
	croak 'No such mode' if not defined $flag_for{$mode};
	croak 'Size must be given in creating mode' if $flag_for{$mode} & O_CREAT and $options{size} == 0;

	my $fh = _shm_open($name, $flag_for{$mode} | $options{flags}, $options{perms});
	$options{after_open}->($fh, \%options) if defined $options{after_open};

	$options{size} = -s $fh if not defined $options{size};
	croak 'Can\'t map empty file' if $options{size} == 0;    # Should never happen
	truncate $fh, $options{size} if $options{size} > -s $fh;

	$options{before_mapping}->($fh, \%options) if defined $options{before_mapping};
	map_handle $_[0], $fh, $mode, $options{offset}, $options{size};

	return $fh if defined wantarray;

	close $fh or croak "Could not close shared filehandle: $!";
	return;
}

1;    # End of POSIX::RT::SharedMem

#ABSTRACT: Create/open or unlink POSIX shared memory objects in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

POSIX::RT::SharedMem - Create/open or unlink POSIX shared memory objects in Perl

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use POSIX::RT::SharedMem qw/shared_open/;

 shared_open my $map, '/some_file', '+>', size => 1024, perms => oct(777);

=head1 DESCRIPTION

This module maps POSIX shared memory into a variable that can be read just like any other variable, and it can be written to using standard Perl techniques such as regexps and C<substr>, B<as long as they don't change the length of the variable>.

=head1 FUNCTIONS

=head2 shared_open $map, $name, $mode, ...

Map the shared memory object C<$name> into C<$map>. For portable use, a shared memory object should be identified by a name of the form '/somename'; that is, a string consisting of an initial slash, followed by one or more characters, none of which are slashes.

C<$mode> determines the read/write mode. It works the same as in open and map_file.

Beyond that it can take three named arguments:

=over 4

=item * size

This determines the size of the map. If the map is map has writing permissions and the file is smaller than the given size it will be lengthened. Defaults to the length of the file and fails if it is zero. It is mandatory when using mode C<< > >> or C<< +> >>.

=item * perms

This determines the permissions with which the file is created (if $mode is C<< +> >>). Default is 0600.

=item * offset

This determines the offset in the file that is mapped. Default is C<0>.

=item * flags

Extra flags that are used when opening the shared memory object (e.g. C<O_EXCL>).

=back

It returns a filehandle that can be used to with L<stat>, L<chmod>, L<chown>. For portability you should not assume you can read or write directly from it.

=head2 shared_unlink $name

Remove the shared memory object $name from the namespace. Note that while the shared memory object can't be opened anymore after this, it doesn't remove the contents until all processes have closed it.

=head1 SEE ALSO

=over 4

=item * SysV::SharedMem

This is a rather similar module that works with SysV shared memory. SysV has confusing ideas of how to identify a segment, as well as having various special case functions that are handled by standard filehandle calls in POSIX shared memory. This module should usually be preferred unless portability requires otherwise.

=item * L<File::Map>

This is used to map the shared memory handle into a scalar. If your processes have a parent-child relationship, you may want to look at C<map_anonymous> instead.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Storage::Abstract::Handle;
$Storage::Abstract::Handle::VERSION = '0.007';
use v5.14;
use warnings;

# 5.14 does not allow bypassing CORE function prototype, so we have a bunch of
# uninitialized warnings which need to be silenced.
no warnings 'uninitialized';

use Carp qw();
use Scalar::Util qw();
use Storage::Abstract::X;

use parent 'Tie::Handle';

sub copy
{
	my ($self, $handle_to) = @_;

	# no extra behavior of print
	local $\;

	my $read = sub { $self->READ($_[0], 8 * 1024) };
	my $write = sub { print {$handle_to} $_[0] };

	# can use sysread / syswrite?
	if (fileno $self->{handle} != -1 && fileno $handle_to != -1) {
		$read = sub { sysread $self->{handle}, $_[0], 128 * 1024 };
		$write = sub {
			my $written = 0;
			while ($written < $_[1]) {
				my $res = syswrite $handle_to, $_[0], $_[1], $written;
				return undef unless defined $res;
				$written += $res;
			}

			return 1;
		};
	}

	my $buffer;
	while ('copying') {
		my $bytes = $read->($buffer);

		Storage::Abstract::X::HandleError->raise("error reading from handle: $!")
			unless defined $bytes;
		last if $bytes == 0;
		$write->($buffer, $bytes)
			or Storage::Abstract::X::StorageError->raise("error during file copying: $!");
	}
}

sub size
{
	my ($self) = @_;

	my $handle = $self->{handle};
	my $size;

	if (fileno $handle == -1) {
		my $success = (my $pos = tell $handle) >= 0;
		$success &&= seek $handle, 0, 2;
		$success &&= ($size = tell $handle) >= 0;
		$success &&= seek $handle, $pos, 0;

		$success or Storage::Abstract::X::HandleError->raise($!);
	}
	else {
		$size = -s $handle;
	}

	return $size;
}

sub adapt
{
	my ($class, $arg) = @_;

	return $arg if defined tied($arg) && tied($arg)->isa($class);

	my $fh = \do { local *HANDLE };
	tie *$fh, $class, $arg;

	return $fh;
}

sub TIEHANDLE
{
	my ($class, $handle) = @_;

	if (ref $handle ne 'GLOB') {
		my $arg = $handle;
		undef $handle;

		open $handle, '<:raw', $arg
			or Storage::Abstract::X::HandleError->raise((ref $arg ? '' : "$arg: ") . $!);
	}

	return bless {
		handle => $handle,
	}, $class;
}

sub WRITE
{
	Carp::croak 'Handle is readonly';
}

sub EOF
{
	my $self = shift;

	return eof $self->{handle};
}

sub FILENO
{

	# the main handle cannot have real fileno, since only the underlying
	# handle can be a real file handle
	return -1;
}

sub BINMODE
{
	my $self = shift;

	return binmode $self->{handle}, $_[0];
}

sub TELL
{
	my $self = shift;

	return tell $self->{handle};
}

sub SEEK
{
	my $self = shift;

	return seek $self->{handle}, $_[0], $_[1];
}

sub READLINE
{
	my $self = shift;

	return readline $self->{handle};
}

sub READ
{
	my $self = shift;

	return read $self->{handle}, $_[0], $_[1], $_[2];
}

sub CLOSE
{
	my $self = shift;

	return close $self->{handle};
}

1;

__END__

=head1 NAME

Storage::Abstract::Handle - Tied filehandle for stored files

=head1 SYNOPSIS

	# in driver's code
	Storage::Abstract::Handle->adapt($handle_ref);

	# or
	Storage::Abstract::Handle->adapt($file_name);

	# or
	Storage::Abstract::Handle->adapt(\$file_content);

=head1 DESCRIPTION

This is a class for returning tied file handles to a storage file. Tied handles
allows fetching the content lazily when the read call occurs. Handles created
with this class are always readonly.

This class also contain a couple helpers for reading from user-supplied handles
during adding files to storage.

=head1 INTERFACE

=head2 Attributes

=head3 handle

The actual underlying handle reference. All tie methods in this class by
default are just proxies to same operations on this handle.

=head2 Helper methods

=head3 adapt

	$tied_object = $class->adapt($tied_object)
	$tied_object = $class->adapt($handle_ref)
	$tied_object = $class->adapt($file_name)
	$tied_object = $class->adapt(\$file_content)

This static methods tries to adapt its argument to be a proper tied object.
Does nothing if the argument is a proper tied object already. Otherwise it must
be a file handle or something which can be opened using C<open> (usually a file
name or a scalar reference).

=head3 size

	$size = tied($tied_object)->size

Returns the size of the underlying resource, in bytes.

=head3 copy

	tied($tied_object)->copy($handle_to)

Copies the underlying resource to C<$handle_to>, which must be open for writing
in raw bytes mode. For efficiency, may use C<sysread>/C<syswrite> if both
handles point to regular files, bypassing perl IO layers.

=head1 SUBCLASSING

This class is meant to be subclassed by drivers which read remote resources and
can't simply open and return a handle. Subclassed versions of this class can
track the position in file based on C<READ>, C<READFILE> and C<SEEK> calls, and
fetch required data lazily. Or simply download the file in full once a read has
been requested the first time.

Core Storage::Abstract does not contain any drivers which may fetch remote
resources, so details of the implementation are up to the driver developers.
The only requirement is that no costly data fetch operations are performed
before the handle is first read.


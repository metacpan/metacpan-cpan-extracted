package PID::File;

use 5.006;

use strict;
use warnings;

use File::Basename qw(fileparse);
use FindBin qw($Bin);
use Scalar::Util qw(weaken);

use PID::File::Guard;

use constant DEFAULT_SLEEP   => 1;
use constant DEFAULT_RETRIES => 0;

=head1 NAME

PID::File - PID files that guard against exceptions.

=head1 VERSION

Version 0.32

=cut

our $VERSION = '0.32';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Create PID files.

 use PID::File;

 my $pid_file = PID::File->new;

 exit if $pid_file->running;

 if ( $pid_file->create )
 {
     $pid_file->guard;

     # do something

     $pid_file->remove;
 }

Using the built-in retry mechanism...

 if ( ! $pid_file->create( retries => 10, sleep => 5 ) )
 {
     die "Could not create pid file after 10 attempts";
 }

 # do something

 $pid_file->remove;

=head1 DESCRIPTION

Creating a pid file, or lock file, should be such a simple process.

See L<Daemon::Control> for a more complete solution for creating daemons (and pid files).

After creating a pid file, if an exception is thrown (and the C<$pid_file> goes out of scope) the pid file would normally remain in place.

If you call C<guard()> on the pid object after creation, it will remove the pid file automatically when it goes out of scope.  More on this later.

=head1 Methods

=head2 Class Methods

=head3 new

 my $pid_file = PID::File->new;

=cut

sub new
{
	my ( $class, %args ) = @_;

	my $self = { file       => $args{ file },
	             guard      => sub { return },
	             guard_temp => sub { return },
	           };

	bless( $self, $class );

	return $self;
}

=head2 Instance Methods

=head3 file

The filename for the pid file.

 $pid_file->file( '/tmp/myapp.pid' );

If you specify a relative path, it will be relative to where your scripts runs.

By default it will use the script name and append C<.pid> to it.

=cut

sub file
{
	my ( $self, $arg ) = @_;

	$self->{ file } = $arg if $arg;

	if ( ! defined $self->{ file } )
	{
		my @filename = fileparse( $0 );
		$self->{ file } = $Bin . '/';
		$self->{ file } .= shift @filename;
		$self->{ file } .= '.pid';
	}

	# relative paths are made absolute, to the script dir

	if ( $self->{ file } !~ m:^/: )
	{
		$self->{ file } = $Bin . '/' . $self->{ file };
	}

	return $self->{ file };
}

=head3 create

Attempt to create a new pid file.

 if ( $pid_file->create )

Returns true or false.

If the file already exists, no action will be taken and it will return false.

If you supply the C<retries> parameter, it will retry that many times, sleeping for C<sleep> seconds (1 by default) between retries.

 if ( ! $pid_file->create( retries => 5, sleep => 2 ) )
 {
     die "Could not create pid file";
 }

As a shortcut, you can also C<guard> the pid file by passing the C<guard> boolean as a parameter.

 $pid_file->create( guard => 1 );

See below for more details on the guard mechanism.

=cut

sub create
{
	my ( $self, %args ) = @_;

	my $sleep   = $args{ sleep }   || DEFAULT_SLEEP;
	my $retries = $args{ retries } || DEFAULT_RETRIES;

	my $temp = $self->file . '.' . $$;

	open( my $fh, '>', $temp ) or return 0;

	$self->{ guard_temp } = sub { unlink $temp };

	print $fh $$;
	close $fh;

	my $attempts = 0;

	while ( $attempts <= $retries )
	{
		if ( link( $temp, $self->file ) )
		{
			unlink $temp;

			$self->{ guard_temp } = sub { return };

			$self->pid( $$ );
			$self->_created( 1 );

			$self->guard if $args{ guard };

			return 1;
		}

		last if $attempts == $retries;

		$attempts ++;

		sleep $sleep;
	}

	unlink $temp;
	$self->{ guard_temp } = sub { return };

	return 0;
}

sub _created
{
	my $self = shift;
	$self->{ _created } = $_[0] if @_;
	return $self->{ _created };
}

=head3 pid

 $pid_file->pid

Stores the pid from the pid file, if one exists.  Could be undefined.

=cut

sub pid
{
	my $self = shift;
	$self->{ pid } = $_[0] if @_;
	return $self->{ pid };
}

=head3 running

 if ( $pid_file->running )

Returns true or false to indicate whether the pid in the current pid file is running.

=cut

sub running
{
	my $self = shift;

	$self->pid( undef );

	open( my $fh, $self->file ) or return 0;
	my $pid = do { local $/; <$fh> };
	close $fh or return 1;

	if ( kill 0, $pid )
	{
		$self->pid( $pid );
		return 1;
	}

	return 0;
}

=head3 remove

Removes the pid file.

 $pid_file->remove;

You can only remove a pid file that was created by the same process.

=cut

sub remove
{
	my ( $self, %args ) = @_;

	return $self if ! $self->_created;

	unlink $self->file;
	$self->pid( undef );
	$self->_created( 0 );
	$self->{ guard } = sub { return };

	return $self;
}

=head3 guard

This deals with scenarios where your script may throw an exception before you can remove the lock file yourself.

When called in void context, this configures the C<$pid_file> object to call C<remove> automatically when it goes out of scope.

 if ( $pid_file->create )
 {
     $pid_file->guard;

     die;
 }

When called in either scalar or list context, it will return a single token.

When that B<token> goes out of scope, C<remove> is called automatically.

This gives more control on when to automatically remove the pid file.

 if ( $pid_file->create )
 {
     my $guard = $pid_file->guard;
 }

 # remove() called automatically, even though $pid_file is still in scope

Note, that if you call C<remove> yourself, the guard configuration will be reset, to save trying to remove the
file again when the C<$pid_file> object finally goes out of scope naturally.

You can only guard a pid file that was created by the same process.

=cut

sub guard
{
	my ( $self, %args ) = shift;

	return if ! $self->_created;

	if ( ! defined wantarray )
	{
		$self->{ guard } = sub { 1 };
		return $self;
	}
	else
	{
		my $guard = PID::File::Guard->new( sub { $self->remove } );
		$self->{ guard } = sub{ return };
		return $guard;
	}
}

sub DESTROY
{
	my $self = shift;

	$self->{ guard_temp }->();

    $self->remove if $self->{ guard }->();
}

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pid-file at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PID-File>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PID::File

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PID-File>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PID-File>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PID-File>

=item * Search CPAN

L<http://search.cpan.org/dist/PID-File/>

=back

=head1 SEE ALSO

L<Daemon::Control>

L<Scope::Guard>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of PID::File


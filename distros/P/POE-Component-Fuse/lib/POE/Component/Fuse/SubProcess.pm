# Declare our package
package POE::Component::Fuse::SubProcess;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# We pass in data to POE::Filter::Reference
use POE::Filter::Reference;

# We communicate with FUSE here
use POE::Component::Fuse::myFuse qw( fuse_get_context fuse_set_fh );

# Our Filter object
my $filter = POE::Filter::Reference->new();

# Autoflush to avoid weirdness
$|++;

# Set the binmode stuff
binmode( STDIN );
binmode( STDOUT );

# This is the subroutine that will get executed upon the fork() call by our parent
sub main {
	# in order to mount the FUSE fs and start the eventloop, we have to get the INIT packet
	my $data = receive_master();
	if ( $data->{'ACTION'} eq 'INIT' ) {
		start_fuse( $data->{'MOUNT'}, $data->{'MOUNTOPTS'} );
	} else {
		die 'unable to receive INIT data';
	}

	# should never get here
	return;
}

# gets a packet from STDIN
sub receive_master {
	# Okay, now we listen for commands from our parent :)
	while ( sysread( STDIN, my $buffer = '', 1024 ) ) {
		# Feed the line into the filter
		my $data = $filter->get( [ $buffer ] );

		# should be an array with 1 element
		if ( defined $data ) {
			if ( scalar @$data == 1 ) {
				return $data->[0];
			} else {
				# get more data
			}
		}
	}

	# should never get here
	return;
}

# sends a packet via STDOUT
sub send_master {
	my $data = shift;

	# process it via Filter::Reference
	$data = $filter->put( [ $data ] );
	foreach my $l ( @$data ) {
		print STDOUT $l;
	}

	return;
}

# initializes FUSE and enters the eventloop
sub start_fuse {
	my $mount = shift;
	my $opts = shift;

	# setup our callbacks
	my %callbacks;
	foreach my $cb ( qw( getattr readlink getdir mknod mkdir unlink rmdir symlink rename link chmod
		chown truncate utime open read write statfs flush release fsync
		setxattr getxattr listxattr removexattr ) ) {

		$callbacks{ $cb } = "POE::Component::Fuse::SubProcess::callback_" . $cb;

		# create the sub!
		eval "sub callback_$cb { return fuse_callback( \$cb, \@_ ) }";	## no critic ( ProhibitStringyEval )
		if ( $@ ) {
			die $@;
		}
	}

	# setup FUSE
	POE::Component::Fuse::myFuse::main(
		# basic setup
		'debug'		=> 0,
		'threaded'	=> 0,
		'mountpoint'	=> $mount,
		( defined $opts ? ( 'mountopts' => $opts ) : () ),

		# the callbacks
		%callbacks,
	);

	# should never get here unless we encountered an error
	return;
}

# handles callbacks
sub fuse_callback {
	my $type = shift;

	# get the context
	my $cxt = fuse_get_context();

	# pass it on to our master!
	send_master( {
		'TYPE'		=> $type,
		'ARGS'		=> [ @_ ],
		'CONTEXT'	=> $cxt,
	} );

	# wait for the reply
	my $reply = receive_master();

	# make sure the type is the same
	if ( $reply->{'ACTION'} eq 'REPLY' ) {
		if ( $reply->{'TYPE'} eq $type ) {
			# Fix up the FH if needed
			if ( $type eq 'open' and exists $reply->{'FH'} and defined $reply->{'FH'} ) {
				# compare the data!
				if ( defined $cxt->{'fh'} ) {
					if ( $reply->{'FH'} != $cxt->{'fh'} ) {
						fuse_set_fh( $reply->{'FH'} );
					}
				} else {
					fuse_set_fh( $reply->{'FH'} );
				}
			}

			# one-arg check
			if ( scalar @{ $reply->{'RESULT'} } == 1 ) {
				return $reply->{'RESULT'}->[0];
			} else {
				return @{ $reply->{'RESULT'} };
			}
		} else {
			die "type mismatch - got $reply->{'TYPE'} but expected $type";
		}
	} else {
		die "received unexpected packet";
	}
}

# End of module
1;
__END__

=head1 NAME

POE::Component::Fuse::SubProcess - Backend of POE::Component::Fuse

=head1 SYNOPSIS

  Please do not use this module directly.

=head1 ABSTRACT

Please do not use this module directly.

=head1 DESCRIPTION

This module is responsible for implementing the guts of POE::Component::Fuse.
Namely, the fork/exec and the FUSE eventloop.

=head2 EXPORT

Nothing.

=head1 SEE ALSO

L<POE::Component::Fuse>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

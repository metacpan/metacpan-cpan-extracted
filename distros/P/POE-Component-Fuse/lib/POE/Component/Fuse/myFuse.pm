# Declare our package
package POE::Component::Fuse::myFuse;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# setup our exporting stuff
use Exporter;
use DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = (
		    'all' => [ qw(fuse_get_context fuse_set_fh) ],
		    );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# some more requirements
use Errno;
use Carp;
use Config;

# finally, load our XS file
bootstrap POE::Component::Fuse::myFuse $VERSION;

sub main {
	my @names = qw(getattr readlink getdir mknod mkdir unlink rmdir symlink
			rename link chmod chown truncate utime open read write statfs
			flush release fsync setxattr getxattr listxattr removexattr);
	my @subs = map {undef} @names;
	my @validOpts = qw(ro allow_other default_permissions fsname use_ino nonempty);
	my $tmp = 0;
	my %mapping = map { $_ => $tmp++ } @names;
	my %optmap  = map { $_ => 1 } @validOpts;
	my @otherargs = qw(debug threaded mountpoint mountopts);
	my %otherargs = (debug=>0, threaded=>0, mountpoint=>"", mountopts=>"");
	while(my $name = shift) {
		my ($subref) = shift;
		if(exists($otherargs{$name})) {
			$otherargs{$name} = $subref;
		} else {
			croak "There is no function $name" unless exists($mapping{$name});
			croak "Usage: myFuse::main(getattr => \"main::my_getattr\", ...)" unless $subref;
			$subs[$mapping{$name}] = $subref;
		}
	}
	foreach my $opt ( map {m/^([^=]*)/; $1} split(/,/,$otherargs{mountopts}) ) {
	  next if exists($optmap{$opt});
	  croak "myFuse::main: invalid '$opt' argument in mountopts";
	}
	if($otherargs{threaded}) {
		# make sure threads are both available, and loaded.
		if($Config{useithreads}) {
			if(exists($threads::{VERSION})) {
				if(exists($threads::shared::{VERSION})) {
					# threads will work.
				} else {
					carp("Thread support requires you to use threads::shared.\nThreads are disabled.\n");
					$otherargs{threaded} = 0;
				}
			} else {
				carp("Thread support requires you to use threads and threads::shared.\nThreads are disabled.\n");
				$otherargs{threaded} = 0;
			}
		} else {
			carp("Thread support was not compiled into this build of perl.\nThreads are disabled.\n");
			$otherargs{threaded} = 0;
		}
	}
	perl_fuse_main(@otherargs{@otherargs},@subs);

	return;
}

1;
__END__

=head1 NAME

POE::Component::Fuse::myFuse - wrapper around the XS guts of FUSE

=head1 SYNOPSIS

  Please do not use this module directly.

=head1 ABSTRACT

Please do not use this module directly.

=head1 DESCRIPTION

This module implements the FUSE API in a slightly different way than L<Fuse> so I had to fork it and make the
changes in this module.

=head1 EXPORT

None.

=head1 SEE ALSO

L<POE::Component::Fuse>

L<Fuse>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Also, this module couldn't have gotten off the ground if not for L<Fuse> which did the heavy XS lifting!

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


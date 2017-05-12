package Pid::File::Flock;

use warnings qw(all);
use strict;

=head1 NAME

Pid::File::Flock - PID file operations

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

You can use module generic way:

  use Pid::File::Flock;
  ...
  Pid::File::Flock->new;
  Pid::File::Flock->new('file');
  Pid::File::Flock->new(debug=>1, dir=>'/tmp');

or in simplified form:

  use Pid::File::Flock qw(:auto);
  use Pid::File::Flock qw(:auto :raise);
  use Pid::File::Flock qw(:auto path=file);
  use Pid::File::Flock qw(:auto :debug dir=/tmp);

you can mix both too:

  use Pid::File::Flock qw(:debug dir=/tmp);
  ...
  Pid::File::Flock->new(ext=>'.old');

=cut

use Carp;
use Fcntl qw(:DEFAULT :flock :seek);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile rel2abs tmpdir);

my ($inst,%iopts);


=head1 IMPORT LIST

You can provide 'flag' options ('debug','quiet') like an import tag:
C<use Pid::File::Flock qw(:debug :quiet)>

Valued options can be specified with key=value form:
C<use Pid::File::Flock qw(dir=/tmp ext=.old)>

Pseudo tag ':auto' create lock object implicitly.


=head1 GENERIC USAGE

=head2 new( $path, %options )

Generic constructor

=over

=item $path

Optional argument, if provided options 'dir','name'
and 'ext' will be silently ignored.

=back

Supported options:

=over

=item * dir => 'directory'

Base directory for pid file (by default File::Spec::tmpdir called).

=item * name => 'basename'

Name for pid file (by default like a script self).

=item * ext => 'extension'

Extension for pid file ('.pid' by default).

=item * raise => 1

Use C<croak> instead of simple C<exit>.
Usable from caller eval block to handle unsuccessful locking attempts.

=item * debug => 1

Switch debug mode on (some information via STDERR).

=item * quiet => 1

Switch quiet mode on (don't warn about staled pid files).

=back

=cut

sub new { $inst ||= shift->acquire(@_) }


=head2 abandon

Don't try to remove pid file during destruction.
Become for using in forking applications.

=cut

sub abandon { $inst->{abandoned}=1 }


=head1 INTERNAL ROUTINES

You haven't call these methods directly.

=head2 import

Process 'fake' import list.

=cut

sub import {
	shift;
	for (@_) {
		/^:(.+)/ && do {  # :flag
			$iopts{$1} = 1; next
		};
		/^([^=]+)=([^=]+)$/ && do {  # key=value
			$iopts{$1} = $2; next
		};
		croak "invalid import list statement: $_";
	}
	# auto lock
	__PACKAGE__->new($iopts{path}) if $iopts{auto};
}


=head2 acquire

Acquiring lock, called by C<new> constructor.

=cut

sub acquire {
	my $proto = shift;
	my $path = shift if @_%2;
	my %opts = (wait=>0,%iopts,@_);

	undef $opts{quiet} if $opts{debug};  # mutually exclusive

	# construct and normalize path
	$path = rel2abs $path || catfile $opts{dir}||tmpdir, $opts{name}||(basename($0).($opts{ext}||'.pid'));
	carp "started, pid $$ ($path)" if $opts{debug};

	# try to get locked handle
	my $fh = attempt($path,%opts);

	# unsuccessfully locking
	unless ($fh) {
		# waiting for lock
		if ($opts{wait}) {
			local $SIG{ALRM} = sub { die "x\n" };
			alarm $opts{wait};
			eval {
				do {
					# try to get locked handle (blocking)
					carp "found alive process, waiting $opts{wait}" if $opts{debug};
					$fh = attempt($path,%opts,block=>1);
				} until $fh;
				alarm 0;
			};
			# catched die to croak
			croak $1 if $@ && $@ ne "x\n" && $@ =~ /^(.+)\n?/;
			goto LOCKED if $fh;
		}
		# get pid of alive process
		if ( $opts{raise} || !$opts{quiet}) {
			sysopen FH, $path, O_RDONLY or do {
				croak "can't read pid file ($path): $!" unless $!{ENOENT};
			};
			my $ex = $opts{raise} ? \&croak : \&carp;
			&$ex("found alive process (".<FH>."), exit");
		}
		# gently terminate main process
		exit;
	}

LOCKED:
	# warning about staled pid
	if ($opts{debug}) {
		carp "found staled pid file (".<$fh>.")";
		sysseek $fh,0,SEEK_SET or croak "can't seek in pid file ($path): $!"
	}
	truncate $fh,0 and syswrite $fh,$$ or croak "can't write pid file ($path): $!";
	bless { path => $path, handle => $fh, debug => $opts{debug} }, $proto;
}

=head2 attempt

Attempting acquire lock with additional checks.

=cut

sub attempt {
	my ($path,%opts) = @_;

	# just an open
	sysopen FH, $path, O_CREAT|O_RDWR or croak "can't open pid file ($path): $!";

	# try to lock it
	my $nb = $opts{block} ? 0 : LOCK_NB;
	flock FH, LOCK_EX|$nb or do {
		croak "can't lock pid file ($path): $!" unless $!{EAGAIN};
		return;
	};

	# exclusive locking on win32 is sufficient condition
	return *FH if $^O eq 'MSWin32';

	# ok, now we have locked handle, but is original file name steel exists?
	my @stath = stat FH or croak "can't get stat about locked handle: $!";
	my @statf = stat $path or do {
		croak "can't get stat about file ($path): $!" unless $!{ENOENT};
		# recursive call, no more tries
		return if $opts{recurs};
		# try to recreate dir entry (non-blocking recursive call)
		carp "dir entry for pid file was lost" if $opts{debug};
		return attempt($path,%opts,block=>0,recurs=>1);
	};

	# there is new dir entry, our locked handle is invalid now
	unless ($stath[0] == $statf[0] && $stath[1] == $statf[1]) {
		carp "dir entry for pid file was recreated" if $opts{debug};
		return;
	}

	return *FH;
}

=head2 release

Unlink pid file, handle will be closed a bit later, during object destructing.

=cut

sub release {
	my $self = shift;
	return undef $inst unless ref $self;
	close $self->{handle};
	unlink $self->{path} or carp "can't remove pid file ($self->{path}): $!";
}


=head2 DESTROY

Lock object destructor.

=cut

sub DESTROY { $_[0]->{abandoned} or shift->release }


=head2 END

Undefine module lexical variable to force DESTROY invoking.

=cut

sub END { undef $inst }

1;

__END__

=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg at mamontov.net> >>

=head1 LIMITATIONS

Module works with advisory files locking which is not implemented on win32 platform.

=head1 BUGS

Please report any bugs or feature requests to C<bug-pid-file-flock at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pid-File-Flock>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pid::File::Flock


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pid-File-Flock>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pid-File-Flock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pid-File-Flock>

=item * Search CPAN

L<http://search.cpan.org/dist/Pid-File-Flock/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Oleg A. Mamontov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


=head1 NAME

RSH::FileUtil - TODO RSH::FileUtil description.

=head1 SYNOPSIS

  use RSH::FileUtil;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for RSH::FileUtil, created by epic. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=cut

package RSH::FileUtil;

use 5.008;
use strict;
use warnings;

use base qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

=head2 EXPORT

None by default.

=cut

our @EXPORT_OK = qw(&get_filehandle);

our @EXPORT    = qw(
					
				   );

our $VERSION = '0.0.1';

# use/imports go here
use FileHandle;

# ******************** Class Methods ********************

=head2 FUNCTIONS

=over

=cut


=item get_filehandle($filename, 'READ'|'WRITE'|'RDWR'|'APPEND', [%args]')

Takes care of the logic for getting a filehandle, especially if no_follow => 1.

=cut

sub get_filehandle {
	my $filename = shift;
	my $type = shift;
	my %args = @_;

	my $fh = undef;

	my $flags = undef;
	if ($type eq 'READ') { $flags = O_RDONLY; }
	elsif ($type eq 'WRITE') { $flags = (O_WRONLY | O_CREAT); }
	elsif ($type eq 'RDWR') { $flags = (O_RDWR | O_CREAT); }
	elsif ($type eq 'APPEND') { $flags = (O_WRONLY | O_APPEND | O_CREAT); }
	
	if (defined($args{exclusive}) && ($args{exclusive} eq '1')) {
	    $flags = $flags | O_EXCL;
	}

	if (($type eq 'WRITE') and (not defined($args{no_truncate}) or ($args{no_truncate} eq '0'))) {
	   # by default, we truncate for writing, to make it work like perl defaults ...  
       $flags = $flags | O_TRUNC;
	}

	if (defined($args{no_follow}) && ($args{no_follow} eq '1')) {
		# Do not follow symlinks--useful for the paranoid in cases of
		# sensitive data that should not be moved.
		eval {
			$fh = new FileHandle $filename, $flags | O_NOFOLLOW;
		};
		if ($@) {
			# catches O_NOFOLLOW not being defined--i.e. on filesystems that have
			# no concept of symlinks or following.  Paranoid or not, if it isn't
			# supported we have to just make do
			$fh = new FileHandle $filename, $flags | O_NOFOLLOW;
		}
	} else {
		# Just get a file handle and don't worry about whether we are following
		# symlinks
		$fh = new FileHandle $filename, $flags;
	}

	return $fh;
}

=back

=cut

# #################### RSH::FileUtil.pm ENDS ####################
1;

=head1 SEE ALSO

http://www.rshtech.com/software/

=head1 AUTHOR

Matt Luker  C<< <mluker@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Matt Luker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

__END__
# ---------------------------------------------------------------------
#  $Log$
# ---------------------------------------------------------------------
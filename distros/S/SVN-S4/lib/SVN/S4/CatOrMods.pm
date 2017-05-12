# See copyright, etc in below POD section.
######################################################################

package SVN::S4::CatOrMods;

use SVN::S4;
use strict;
use Carp;
use IO::File;
use Cwd;
use vars qw($AUTOLOAD);

use SVN::S4::Debug qw (DEBUG is_debug);
use SVN::S4::Path;

our $VERSION = '1.064';

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use Cwd qw(getcwd);
use strict;

use SVN::S4::Debug qw (DEBUG is_debug);

sub cat_or_mods {
    my $self = shift;
    my %params = (#filename=>,
		  @_);

    my $filename = $params{filename};
    $filename = getcwd()."/".$filename if $filename !~ m%^/%;

    if (!-f $filename) {
	die "%Error: s4 cat-or-mods: File does not exist: $filename\n";
    }

    my $_Modified = 1;  # Default to safe

    my $stat = $self->client->status
	($filename,		# canonical path
	 "WORKING",		# revision
	 sub {
	     my ($path, $status) = @_;
	     if ($status->text_status == $SVN::Wc::Status::normal) {
		 $_Modified = 0;
	     }
	     #printf "Path: %s\n",$filename;
	     #printf "URL: %s\n",$status->entry->url;
	     #printf "Revision: %s\n", $status->entry->revision;
	     #printf "TS: %s\n", $status->text_status;
	     #printf "Last Changed Author: %s\n", $status->entry->cmt_author;
	     #printf "Last Changed Rev: %s\n", $status->entry->cmt_rev;
	 }, # status func
	 0,			# recursive
	 1,			# get_all
	 0,			# update
	 0,			# no_ignore
	);

    if ($_Modified) {
	DEBUG "cat-or-mods: From WORKING\n" if $self->debug;
	my $fh = IO::File->new("<$filename")
	    or die "s4: %Error: $! $filename\n";
	print join('',$fh->getlines);
    }
    else {
	DEBUG "cat-or-mods: From HEAD\n" if $self->debug;
	#$self->client->cat(\&STDOUT, $filename, "HEAD");
	# Got "unknown type for svn_stream_t"
	# So instead we'll use the command line interface
	$self->run("$self->{svn_binary} cat -r HEAD '$filename'");
    }
}

######################################################################
### Package return
package SVN::S4::CatOrMods;
1;
__END__

=pod

=head1 NAME

SVN::S4::CatOrMods - Fix svn:ignore and svn:keywords properties

=head1 SYNOPSIS

Shell:
  s4 fixprop {files_or_directories}

Scripts:
  use SVN::S4::CatOrMods;
  $svns4_object->fixprop(filename=>I<filename>);

=head1 DESCRIPTION

SVN::S4::CatOrMods provides utilities for changing properties on a file-by-file basis.

=head1 METHODS

None.

=head1 METHODS ADDED TO SVN::S4

The following methods extend to the global SVN::S4 class.

=over 4

=item $s4->cat_or_mods

Cat or show modifications for the specified file.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2009-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut

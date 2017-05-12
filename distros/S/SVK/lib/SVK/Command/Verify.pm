# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Command::Verify;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use SVK::I18N;
use SVK::Logger;

use base qw( SVK::Command );

sub options {
    ();
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if $#arg < 0;
    return ($arg[0], $self->arg_depotname ($arg[1] || '//'));
}

sub _verify {
    my ($depot, $sig, $chg) = @_;
    my $fs = $depot->repos->fs;
    my $editor = SVK::VerifyEditor->new ({ sig => $sig,
					   depot => $depot });

    # should really just use paths_changed
    SVN::Repos::dir_delta ($fs->revision_root ($chg-1), '/', '',
			   $fs->revision_root ($chg), '/',
			   $editor, undef,
			   0, 1, 0, 1
			  );

    return loc ("Signature verification failed.\n") if $editor->{fail};
    return loc( "Signature verified.\n");
}

sub run {
    my ($self, $chg, $depot) = @_;
    my $target = $self->arg_depotpath ("/$depot/");
    my $fs = $target->repos->fs;
    my $sig = $fs->revision_prop ($chg, 'svk:signature');
    return _verify($target->depot, $sig, $chg)
	if $sig;
    $logger->info( "No signature found for change $chg at /$depot/.");
    return;
}

# XXX: Don't need this editor once root->paths_changed is available.
package SVK::VerifyEditor;
use base 'SVK::Editor';
use SVK::Logger;
__PACKAGE__->mk_accessors(qw(depot sig));

sub add_file {
    my ($self, $path, @arg) = @_;
    return $path;
}

sub open_file {
    my ($self, $path, @arg) = @_;
    return $path;
}

sub close_file {
    my ($self, $path, $checksum, $pool) = @_;
    $self->{checksum}{"/$path"} =  $checksum;
}

sub close_edit {
    my ($self, $baton) = @_;
    my $sig = $self->sig;
    local *D;
    # verify the signature
    my $pgp = $ENV{SVKPGP} || 'gpg';
    open D, "|$pgp --verify --batch --no-tty";
    print D $sig;
    close D;

    if ($?) {
        warn "Self is $self";
        $logger->info( "Can't verify signature");
	$self->{fail} = 1;
	return;
    }
    # verify the content
    my $header = '-----BEGIN PGP SIGNED MESSAGE-----';
    $sig =~ s/^.*$header/$header/s;
    my ($anchor) = $sig =~ m/^ANCHOR: (.*)$/m;
    my ($path) = $self->depot->find_local_mirror(split(':', $anchor));
    $path ||= (split(':', $anchor))[1];

    while ($sig =~ m/^MD5\s(.*?)\s(.*?)$/gm) {
	my ($md5, $filename) = ($1, $2);
	my $checksum = delete $self->{checksum}{"$path/$filename"};
	if ($checksum ne $md5) {
	    $logger->info( "checksum for $path/$filename mismatched: $checksum vs $md5");
	    $self->{fail} = 1;
	    return;
	}
    }
    # unsigned change
    if (my @unsig = keys %{$self->{checksum}}) {
	$logger->info("Checksum for changed path ".join (',', @unsig)." not signed.");
	$self->{fail} = 1;
    }
}

1;

__DATA__

=head1 NAME

SVK::Command::Verify - Verify change signatures

=head1 SYNOPSIS

 verify CHANGE [DEPOTNAME]

=head1 OPTIONS

 None


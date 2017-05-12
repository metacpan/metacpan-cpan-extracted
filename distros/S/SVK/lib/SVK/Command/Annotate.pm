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
package SVK::Command::Annotate;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw( SVK::Command );
use SVK::XD;
use SVK::I18N;
use SVK::Util qw( traverse_history );
use SVK::Logger;
use Algorithm::Annotate;

sub options {
    ('x|cross'       => 'cross',
     'remoterev'     => 'remoterev',
     'r|revision=s'  => 'rev');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if $#arg < 0;

    return $self->arg_co_maybe (@arg);
}

sub run {
    my ($self, $target) = @_;
    my $m = $target->is_mirrored;
    my $fs = $target->repos->fs;
    my $ann = Algorithm::Annotate->new;
    my @paths;

    $target = $self->apply_revision($target) if $self->{rev};

    traverse_history (
        root     => $target->as_depotpath->root,
        path     => $target->path,
        cross    => $self->{cross},
        callback => sub {
            my ($path, $rev) = @_;
            unshift @paths,
		$target->as_depotpath($rev)->new(path => $path);
            1;
        }
    );

    $logger->info(loc("Annotations for %1 (%2 active revisions):\n", $target->path, scalar @paths));
    $logger->info( '*' x 16 );
    for my $t (@paths) {
	local $/;
	my $content = $t->root->file_contents($t->path);
	$content = [split /\015?\012|\015/, <$content>];
	no warnings 'uninitialized';
	my $rrev = ($m && $self->{remoterev}) ? $m->find_remote_rev($t->revision) : $t->revision;
	$ann->add ( sprintf("%6s\t(%8s %10s):\t\t", $rrev,
			    $fs->revision_prop($t->revision, 'svn:author'),
			    substr($fs->revision_prop ($t->revision, 'svn:date'),0,10)),
		    $content);
    }

    # TODO: traverse history should just DTRT and we dont need to special case here
    my $last = $target->isa('SVK::Path::Checkout')
	? $target : $paths[-1];
    my $final;
    {
	local $/;
	$final = $last->root->file_contents($last->path);
	$final = [split /\015?\012|\015/, <$final>];
	$ann->add ( "\t(working copy): \t\t", $final )
	    if $target->isa('SVK::Path::Checkout');
    }

    my $result = $ann->result;
    while (my $info = shift @$result) {
        $logger->info($info, shift(@$final), "\n");
    }

}

1;

__DATA__

=head1 NAME

SVK::Command::Annotate - Display per-line revision and author info

=head1 SYNOPSIS

 annotate [PATH][@REV]
 annotate [-r REV] [PATH]
 annotate DEPOTPATH[@REV]
 annotate [-r REV] DEPOTPATH

=head1 OPTIONS

 -r [--revision] REV    : annotate up to revision
 -x [--cross]           : track revisions copied from elsewhere
 --remoterev            : display remote revision numbers (on mirrors only)

=head1 NOTES

Note that -r REV file will do annotation up to REV,
while file@REV will do annotation up to REV,
plus the checkout copy differences.


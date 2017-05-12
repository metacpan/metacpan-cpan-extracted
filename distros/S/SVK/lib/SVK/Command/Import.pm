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
package SVK::Command::Import;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Commit );
use SVK::XD;
use SVK::I18N;
use SVK::Logger;

sub options {
    ($_[0]->SUPER::options,
     'f|from-checkout|force'    => 'from_checkout',
     't|to-checkout'	        => 'to_checkout',
    )
}

sub parse_arg {
    my $self = shift;
    my @arg = @_ or return;

    return if @arg > 2;
    unshift @arg, '' while @arg < 2;

    local $@;
    if (eval { $self->{xd}->find_repos($arg[1]); 1 }) {
        # Reorder to put DEPOTPATH before PATH
        @arg[0,1] = @arg[1,0];
    }
    elsif (!eval { $self->{xd}->find_repos($arg[0]); 1 }) {
        # The user entered a path
	$arg[0] = ($self->prompt_depotpath('import', undef, 1));
    }

    return ($self->arg_depotpath ($arg[0]), $self->arg_path ($arg[1]));
}

sub lock {
    my ($self, $target, $source) = @_;
    unless ($self->{xd}{checkout}->get ($source, 1)->{depotpath}) {
	$self->{xd}->lock ($source) if $self->{to_checkout};
	return;
    }
    $source = $self->arg_copath ($source);
    die loc("Import source (%1) is a checkout path; use --from-checkout.\n", $source->copath)
	unless $self->{from_checkout};
    die loc("Import path (%1) is different from the copath (%2)\n", $target->path_anchor, $source->path_anchor)
	unless $source->path_anchor eq $target->path_anchor;
    $self->lock_target ($source);
}

sub _mkpdir {
    my ($self, $target) = @_;

    $self->command (
        mkdir => { message => "Directory for svk import.", parent => 1 },
    )->run ($target);

    $logger->info( loc("Import path %1 initialized.\n", $target->depotpath));
}

sub run {
    my ($self, $target, $copath) = @_;
    lstat ($copath);
    die loc ("Path %1 does not exist.\n", $copath) unless -e _;
    my $root = $target->root;
    my $kind = $root->check_path ($target->path);

    die loc("import destination cannot be a file") if $kind == $SVN::Node::file;

    my $basetarget = $target;
    if ($kind == $SVN::Node::none) {
	if ($self->{check_only}) {
	    $logger->info( loc("Import path %1 will be created.\n", $target->depotpath));
	    $basetarget = $target->new (revision => 0, path => '/');
	}
	else {
	    $self->_mkpdir ($target);
	    $target->refresh_revision;
	    $root = $target->root;
	}
    }

    unless (exists $self->{xd}{checkout}->get ($copath, 1)->{depotpath}) {
	$self->{xd}{checkout}->store
	    ($copath, {depotpath => '/'.$target->depotname.$target->path_anchor,
		       '.newprop' => undef,
		       '.conflict' => undef,
		       revision => $target->revision});
        delete $self->{from_checkout};
    }

    $self->get_commit_message () unless $self->{check_only};
    my $committed =
	sub { my $yrev = $_[0];
	      $logger->info( loc("Directory %1 imported to depotpath %2 as revision %3.\n",
			$copath, $target->depotpath, $yrev));

	      if ($self->{to_checkout}) {
                  $self->{xd}{checkout}->store (
                      $copath, {
                          depotpath => $target->depotpath,
                          revision => $yrev,
                          $self->_schedule_empty,
                      },
                      {override_sticky_descendents => 1}
                  );
              }
              elsif ($self->{from_checkout}) {
		  $self->committed_import ($copath)->($yrev);
	      }
	      else {
		  $self->{xd}{checkout}->store
		      ($copath, {depotpath => undef,
				 revision => undef,
				 '.schedule' => undef});
	      }
	  };
    my ($editor, %cb) = $self->get_editor ($basetarget, $committed);

    $self->{import} = 1;
    $self->run_delta (SVK::Path::Checkout->real_new
		      ({ source => $basetarget,
			 copath_anchor => $copath }), $root, $editor, %cb);

    if ($self->{check_only}) {
	$logger->info( loc("Directory %1 will be imported to depotpath %2.\n",
		  $copath, $target->depotpath));
	$self->{xd}{checkout}->store
	    ($copath, {depotpath => undef,
		       revision => undef,
		       '.schedule' => undef});
    }
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Import - Import directory into depot

=head1 SYNOPSIS

 import [PATH] DEPOTPATH

 # You may also list the target part first:
 import DEPOTPATH [PATH]

=head1 OPTIONS

 -f [--from-checkout]   : import from a checkout path
 -t [--to-checkout]     : turn the source into a checkout path
 -m [--message] MESSAGE	: specify commit message MESSAGE
 -F [--file] FILENAME	: read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME	: instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 -N [--non-recursive]   : operate on single directory only
 --direct               : commit directly even if the path is mirrored


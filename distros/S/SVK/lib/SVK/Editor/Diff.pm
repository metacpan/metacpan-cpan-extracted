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
package SVK::Editor::Diff;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

require SVN::Delta;
use base 'SVK::Editor';

use SVK::I18N;
use autouse 'SVK::Util' => qw( slurp_fh tmpfile mimetype_is_text catfile abs2rel from_native);

=head1 NAME

SVK::Editor::Diff - An editor for producing textual diffs

=head1 SYNOPSIS

 $editor = SVK::Editor::Diff->new
    ( base_root   => $root,
      base_target => $target,
      cb_llabel      => sub { ... },
      # or llabel => 'revision <left>',
      cb_rlabel      => sub { ... },
      # or rlabel => 'revision <left>',
      oldtarget => $target, oldroot => $root,
    );
 $xd->depot_delta ( editor => $editor, ... );

=cut

sub set_target_revision {
    my ($self, $revision) = @_;
}

sub open_root {
    my ($self, $baserev) = @_;
    $self->{dh} = Data::Hierarchy->new;
    return '';
}

# XXX maybe this needs to be done more methodically
sub _copyfrom_uri_to_path {
    my ($self, $from_path) = @_;

    my $repospath_start = "file://" . $self->{base_target}->repospath;
    $from_path =~ s/^\Q$repospath_start//;

    return $from_path;
}

sub add_file {
    my ($self, $path, $pdir, $from_path, $from_rev, $pool) = @_;
    if (defined $from_path) {
        $from_path = $self->_copyfrom_uri_to_path($from_path);

	$self->{info}{$path}{baseinfo} = [$from_path, $from_rev];
	$self->{dh}->store("/$path", { copyanchor => "/$path",
				       '.copyfrom' => $from_path,
				       '.copyfrom_rev' => $from_rev,
				     });
    }
    else {
	$self->{info}{$path}{added} = 1;
    }
    $self->{info}{$path}{fpool} = $pool;
    return $path;
}

sub open_file {
    my ($self, $path, $pdir, $rev, $pool) = @_;
    $self->{info}{$path}{fpool} = $pool;

    my ($basepath, $fromrev) = $self->_resolve_base($path);
    $self->{info}{$path}{baseinfo} = [$basepath, $fromrev]
	if defined $fromrev;

    return $path;
}

sub _resolve_base {
    my ($self, $path) = @_;
    my ($entry) = $self->{dh}->get("/$path");
    return unless $entry->{copyanchor};
    $entry = $self->{dh}->get($entry->{copyanchor})
	unless $entry->{copyanchor} eq "/$path";
    my $key = 'copyfrom';
    return (abs2rel("/$path",
		    $entry->{copyanchor} => $entry->{".$key"}, '/'),
	    $entry->{".${key}_rev"});
}

sub retrieve_base {
    my ($self, $path, $pool) = @_;
    my ($basepath, $fromrev) = $self->{info}{$path}{baseinfo} ?
	$self->_resolve_base($path) : ($path);

    my $root = $fromrev ? $self->{base_root}->fs->revision_root($fromrev, $pool)
	: $self->{base_root};

    $basepath = $self->{base_target}->path_anchor."/$path"
	if $basepath !~ m{^/};

    return $root->file_contents("$basepath", $pool);
}

# XXX: cleanup
sub retrieve_base_prop {
    my ($self, $path, $prop, $pool) = @_;
    my ($basepath, $fromrev) = $self->_resolve_base($path);
    $basepath = $path unless defined $basepath;

    my $root = $fromrev ? $self->{base_root}->fs->revision_root($fromrev, $pool)
	: $self->{base_root};

    $basepath = $self->{base_target}->path_anchor."/$path"
	if $basepath !~ m{^/};

    return $root->check_path($basepath, $pool) == $SVN::Node::none ?
	undef : $root->node_prop($basepath, $prop, $pool);
}

sub apply_textdelta {
    my ($self, $path, $checksum, $pool) = @_;
    return unless $path;
    my $info = $self->{info}{$path};
    $info->{base} = $self->retrieve_base($path, $info->{fpool})
	unless $info->{added};

    unless ($self->{external}) {
	my $newtype = $info->{prop} && $info->{prop}{'svn:mime-type'};
	my $is_text = !$newtype || mimetype_is_text ($newtype);
	if ($is_text && !$info->{added}) {
	    my $basetype = $self->retrieve_base_prop($path, 'svn:mime-type', $pool);
	    $is_text = !$basetype || mimetype_is_text ($basetype);
	}
	unless ($is_text) {
	    $self->output_diff_header ($self->_report_path ($path));
	    $self->_print (
                loc("Cannot display: file marked as a binary type.\n")
            );
	    return undef;
	}
    }
    my $new;
    if ($self->{external}) {
	my $tmp = tmpfile ('diff');
	slurp_fh ($info->{base}, $tmp)
	    if $info->{base};
	seek $tmp, 0, 0;
	$info->{base} = $tmp;
	$info->{new} = $new = tmpfile ('diff');
    }
    else {
	$info->{new} = '';
	open $new, '>', \$info->{new};
    }

    return [SVN::TxDelta::apply ($info->{base}, $new,
				 undef, undef, $pool)];
}

sub _report_path {
    my ($self, $path) = @_;

    return $path if !(defined $self->{report} && length $self->{report});
    my $report = $self->{report}; $report = "$report";
    from_native($report);
    return catfile($report, $path);
}

sub close_file {
    my ($self, $path, $checksum, $pool) = @_;
    return unless $path;

    if (exists $self->{info}{$path}{new}) {
	no warnings 'uninitialized';
	my $rpath = $self->_report_path ($path);
	my $base = $self->{info}{$path}{added} ?
	    \'' : $self->retrieve_base($path, $self->{info}{$path}{fpool});
	my @label = map { $self->{$_} || $self->{"cb_$_"}->($path) } qw/llabel rlabel/;
	my $showpath = ($self->{lpath} ne $self->{rpath});
	my @showpath = map { $showpath ? $self->{$_} : undef } qw/lpath rpath/;
	if ($self->{external}) {
	    # XXX: the 2nd file could be - and save some disk IO
	    my @content = map { ($self->{info}{$path}{$_}->filename) } qw/base new/;
	    @content = reverse @content if $self->{reverse};
	    (system (split (/ /, $self->{external}),
		    '-L', _full_label ($rpath, $showpath[0], $label[0]),
		    $content[0],
		    '-L', _full_label ($rpath, $showpath[1], $label[1]),
		    $content[1]) >= 0) or die loc("Could not run %1: %2", $self->{external}, $?);
	}
	else {
	    my @content = ($base, \$self->{info}{$path}{new});
	    @content = reverse @content if $self->{reverse};
	    $self->output_diff ($rpath, @label, @showpath, @content);
	}
    } elsif (exists $self->{dh}->get("/$path")->{'.copyfrom'}) {
        # File copied but not changed.
        $self->output_diff_header($path);
    }

    $self->output_prop_diff ($path, $pool);
    delete $self->{info}{$path};
}

sub _full_label {
    my ($path, $mypath, $label) = @_;

    my $full_label = "$path\t";
    if ($mypath) {
        $full_label .= "($mypath)\t";
    }
    $full_label .= "($label)";

    return $full_label;
}

sub output_diff_header {
    my ($self, $path, $is_newdir) = @_;

    my @notes;

    push @notes, ($self->{reverse} ? "deleted" : "new") . " directory" if $is_newdir;

    if (my ($where, $rev) = $self->_resolve_base($path)) {
        push @notes, "copied from $where\@$rev";
    }

    if (@notes) {
        $path = "$path\t(" . (join "; ", @notes) . ")";
    }


    $self->_print (
        "=== $path\n",
        '=' x 66, "\n",
    );
}

sub output_diff {
    my ($self, $path, $llabel, $rlabel, $lpath, $rpath) = splice(@_, 0, 6);
    my $fh = $self->_output_fh;

    $self->output_diff_header ($path);

    unshift @_, $self->_output_fh;
    push @_, _full_label ($path, $lpath, $llabel),
             _full_label ($path, $rpath, $rlabel);

    goto &{$self->can('_output_diff_content')};
}

# _output_diff_content($fh, $ltext, $rtext, $llabel, $rlabel)
sub _output_diff_content {
    my $fh = shift;

    my ($lfh, $lfn) = tmpfile ('diff');
    my ($rfh, $rfn) = tmpfile ('diff');

    slurp_fh (shift(@_) => $lfh); close ($lfh);
    slurp_fh (shift(@_) => $rfh); close ($rfh);

    my $diff = SVN::Core::diff_file_diff( $lfn, $rfn );

    SVN::Core::diff_file_output_unified(
        $fh, $diff, $lfn, $rfn, @_,
    );

    unlink ($lfn, $rfn);
}

sub output_prop_diff {
    my ($self, $path, $pool) = @_;
    if ($self->{info}{$path}{prop}) {
	my $rpath = $self->_report_path ($path);
	$self->_print("\n", loc("Property changes on: %1\n", $rpath), ('_' x 67), "\n");
	for (sort keys %{$self->{info}{$path}{prop}}) {
	    $self->_print(loc("Name: %1\n", $_));
	    my $baseprop;
	    $baseprop = $self->retrieve_base_prop($path, $_, $pool)
		unless $self->{info}{$path}{added};
            my @args =
                map \$_,
                map { (length || /\n$/) ? "$_\n" : $_ }
                    ($baseprop||''), ($self->{info}{$path}{prop}{$_}||'');
            @args = reverse @args if $self->{reverse};

            my $diff = '';
            open my $fh, '>', \$diff;
            _output_diff_content($fh, @args, '', '');
            $diff =~ s/.*\n.*\n//;
            $diff =~ s/^\@.*\n//mg;
            $diff =~ s/^/ /mg;
            $self->_print($diff);
	}
	$self->_print("\n");
    }
}

sub add_directory {
    my ($self, $path, $pdir, $from_path, $from_rev, $pool) = @_;
    $self->{info}{$path}{added} = 1;
    if (defined $from_path) {
        $from_path = $self->_copyfrom_uri_to_path($from_path);

	# XXX: print some garbage about this copy
	$self->{dh}->store("/$path", { copyanchor => "/$path",
				       '.copyfrom' => $from_path,
				       '.copyfrom_rev' => $from_rev,
				     });
    }
    $self->output_diff_header($self->_report_path( $path ), 1);
    return $path;
}

sub open_directory {
    my ($self, $path, $pdir, $rev, @arg) = @_;
    return $path;
}

sub close_directory {
    my ($self, $path, $pool) = @_;
    $self->output_prop_diff ($path, $pool);
    delete $self->{info}{$path};
}

sub delete_entry {
    my ($self, $path, $revision, $pdir, $pool) = @_;
    my $spool = SVN::Pool->new_default;
    # generate delta between empty root and oldroot of $path, then reverse in output
    SVK::XD->depot_delta
	( oldroot => $self->{base_target}->repos->fs->revision_root (0),
	  oldpath => [$self->{base_target}->path_anchor, $path],
	  newroot => $self->{base_root},
	  newpath => $self->{base_target}->path_anchor eq '/' ? "/$path" : $self->{base_target}->path_anchor."/$path",
	  editor => __PACKAGE__->new (%$self, reverse => 1),
	);

}

sub change_file_prop {
    my ($self, $path, $name, $value) = @_;
    $self->{info}{$path}{prop}{$name} = $value;
}

sub change_dir_prop {
    my ($self, $path, $name, $value) = @_;
    $self->{info}{$path}{prop}{$name} = $value;
}

sub close_edit {
    my ($self, @arg) = @_;
}

sub _print {
    my $self = shift;
    $self->{output} or return print @_;
    ${ $self->{output} } .= $_ for @_;
}

sub _output_fh {
    my $self = shift;

    no strict 'refs';
    $self->{output} or return \*{select()};

    open my $fh, '>>', $self->{output};
    return $fh;
}


1;

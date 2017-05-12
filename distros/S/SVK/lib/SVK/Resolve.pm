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
package SVK::Resolve;
use strict;
use SVK::I18N;
use SVK::Util qw(
    slurp_fh tmpfile get_prompt edit_file
    read_file can_run is_executable bsd_glob
);
use File::Copy ();
use SVK::Logger;

use constant Actions => {qw(
    a   accept      e   edit        d   diff
    m   merge       s   skip        t   theirs
    y   yours       h   help
)};

sub new {
    my ($class, %args) = @_;
    return bless(\%args, $class);
}

sub run {
    my $self = shift;

    %$self = (
        action => $self->{action},
        external => $self->{external},
        @_
    );

    return $self->do_resolve;
}

sub init {
    my $self = shift;

    return if exists $self->{merged};

    @{$self}{qw( yours theirs base )} = map $self->{fh}{$_}[1], qw( local new base );
    $self->{merged} = tmpfile ('merged-', OPEN => 0, UNLINK => 0);
    $self->{conflict} = "$self->{mfh}";
    close $self->{mfh};

    $self->{this_action} = $self->{action};
    File::Copy::copy ($self->{conflict} => $self->{merged});
}

sub do_resolve {
    my ($self) = @_;

    return if !exists $self->{has_conflict};
    $self->init;
    
    my ($prompt, $default);
    if ($self->{has_conflict}) {
        $default = ($self->{external} ? 'm' : 'e');
        $prompt = loc(
            "Conflict found in %1:\ne)dit, d)iff, m)erge, s)kip, t)heirs, y)ours, h)elp? [%2] ",
            $self->{path}, $default
        );
    }
    else {
        $default = 'a';
        $prompt = loc(
            "Merged %1:\na)ccept, e)dit, d)iff, m)erge, s)kip, t)heirs, y)ours, h)elp? [%2] ",
            $self->{path}, $default
        );
    }

    my $action = lc(delete($self->{this_action}) || get_prompt(
        $prompt, qr/^[aedmstyh?]?/i
    ) || $default);

    my ($cmd, @arg) = split(//, $action);
    my $method = $self->Actions->{$cmd} || 'help';

    # tail recursion, heh.
    $self->$method(@arg ? @arg : '');
    goto &{$self->can('do_resolve')};
}

sub edit {
    my $self = shift;

    eval { edit_file ($self->{merged}) };
    if (my $err = $@) {
        $logger->error(loc("External editor reported an error: %1.", $err));
    }
    $self->{has_conflict} = index (read_file ($self->{merged}), $self->{marker}) >= 0;

    return 0;
}

sub diff {
    my ($self, $arg) = @_;

    my ($lfn, $llabel, $rfn, $rlabel) = (
        map { $self->{$_}, "$self->{path} (\U$_)" }
        ($arg eq 'y') ? qw( base  yours  ) :
        ($arg eq 't') ? qw( base  theirs ) :
        ($arg eq 'm') ? qw( base  merged ) :
                        qw( yours merged )
    );

    my $diff = SVN::Core::diff_file_diff( $lfn, $rfn );

    no strict 'refs';
    SVN::Core::diff_file_output_unified(
        \*{select()}, $diff, $lfn, $rfn, $llabel, $rlabel
    );

    return 0;
}

sub merge {
    my $self = shift;
    my ($fh, $path) = @{$self}{qw( fh path )};

    $self->{"label_$_"} = "$path (\U$_)" foreach qw( yours base theirs );

    my ($resolver, $cmd, @args) = (is_executable(split(/ /, $self->{external}||'')) ? (
        $self,
        split(/ /, $self->{external}),
        (map @{$self}{"label_$_" => $_}, qw( yours base theirs )),
        $self->{merged},
    ) : $self->get_resolver);

    if (!$resolver) {
        $logger->error(loc("Cannot launch an external merge tool for %1.", $path));
        return;
    }

    # maybe some message here
    $logger->info(loc("Invoking merge tool '%1' for %2.", $resolver->name, $path));

    if ($resolver->run_resolver($cmd, @args)) {
        $self->{has_conflict} = (
            index(read_file($self->{merged}), $self->{marker}) >= 0
        );
    }
    else {
        File::Copy::copy ($self->{conflict} => $self->{merged});
    }

    return 0;
}

sub accept {
    my ($self, $arg) = @_;

    return $self->yours  if ($arg eq 'y');
    return $self->theirs if ($arg eq 't');

    delete $self->{has_conflict} if !$self->{has_conflict};
}

sub skip {
    my $self = shift;

    unlink delete $self->{merged};
    delete $self->{has_conflict};
}

sub filter_conflict {
    my ($self, $want) = @_;

    open my $ifh, '<', $self->{conflict} or die $!;
    open my $ofh, '>', $self->{merged} or die $!;

    my $state = '';
    my $newline = "[\r\n|\n\r?]";
    my $in  = qr/^[>=]{4} (YOUR|ORIGINAL|THEIR) VERSION $self->{path}(?: \(.*\))? $self->{marker}$newline$/;
    my $out = qr/<<<< $self->{marker}$newline/;

    while (<$ifh>) {
        if ($_ =~ $in) {
            $state = $1;
            next;
        }
        elsif (s/$out//) {
            $state = '';
            next unless $want eq 'THEIR';
        }

        next if $state and $state ne $want;
        print $ofh $_;
    }
}

sub theirs {
    my $self = shift;
    $self->filter_conflict('THEIR');
    delete $self->{has_conflict};
}

sub yours {
    my $self = shift;
    $self->filter_conflict('YOUR');
    delete $self->{has_conflict};
}

sub filename {
    my $self = shift;
    $self->SVK::Command::filename;
}

sub help {
    my $self = shift;
    $self->SVK::Command::usage(1);
}

sub get_resolver {
    my $self = shift;

    my %name;
    foreach my $file ( grep -e, map bsd_glob("$_/SVK/Resolve/*.pm"), @INC ) {
        $file =~ /(\w+)\.pm$/i or next;
        if (lc($1) eq lc($self->{external})) {
            %name = ( $1 => 1 ); last;
        }
        $name{$1}++;
    }

    my @resolver;
    foreach my $name ( sort keys %name ) {
        eval { require "SVK/Resolve/$name.pm"; 1 } or next;

        my $resolver = "SVK::Resolve::$name"->new(%$self);
        my $pathname = $resolver->find_command($resolver->commands) or next;
        push @resolver, [$resolver, $pathname];
    }

    if (@resolver > 1) {
        my $range = join('|', 1..@resolver);

	print loc("Multiple merge tools found, choose one:\n");
        print loc(
	    "(to skip this question, set the %1 environment variable to one of them)\n",
            'SVKMERGE',
        );
        my $answer = get_prompt(
            join(
                loc(', '),
                (map { "$_)".$resolver[$_-1][0]->name } 1..@resolver),
                loc('q)uit? ')
            ), qr/^(?:$range|[qQ])$/,
        );
        return if $answer =~ /[qQ]/;
        @resolver = $resolver[$answer-1];
    }

    my ($resolver, $pathname) = @{$resolver[0]||[]} or return;
    return ($resolver, $pathname, $resolver->arguments);
}

sub run_resolver {
    my ($self, $cmd, @args) = @_;
    my $rv = system {$cmd} ($cmd, @args);
    return ($rv == 0 and -e $self->{merged});
}

sub commands {
    my $self = shift;

    if (ref($self) =~ /(\w*)$/) {
        return lc($1);
    }
}

sub paths { () }

sub name {
    my $self = shift;

    return $self->{external} if ref($self) eq __PACKAGE__;
    return $1 if (ref($self) =~ /(\w*)$/);
}

sub find_command {
    my $self = shift;
    foreach my $cmd (@_) {
        my $pathname = can_run($cmd, $self->paths) or next;
        return $pathname;
    }
    return;
}

sub DESTROY {
    my $self = shift;

    ref($self) eq __PACKAGE__ or return;

    unlink $_ for grep {defined and -f} (
        $self->{merged},
    );
}

1;

__DATA__

=head1 NAME

SVK::Resolve - Interactively resolve conflicts

=head1 DESCRIPTION

  Accept:
     a   : Accept the merged/edited file.
     y   : Keep only changes to your file.
     t   : Keep only changes to their file.
  Diff:
     d   : Diff your file against merged file.
     dm  : See merged changes.
     dy  : See your changes alone.
     dt  : See their changes alone.
  Edit:
     e   : Edit merged file with an editor.
     m   : Run an external merge tool to edit merged file.
  Misc:
     s   : Skip this file.
     h   : Print this help message.

  Environment variables:
    EDITOR     : Editor to use for 'e'.
    SVKMERGE   : External merge tool to always use for 'm'.
    SVKRESOLVE : The resolve action to take, instead of asking.

=cut

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
package SVK::Editor::InteractiveStatus;

use strict;
use warnings;

use Algorithm::Diff;
use SVK::I18N;
use SVN::Delta;

use SVK::Version;  our $VERSION = $SVK::VERSION;
use SVK::Editor::Patch;
use Algorithm::Diff;

#our @ISA = qw(SVN::Delta::Editor);

sub new {
    my ($class, @args) = @_;
    #my $self = $class->SUPER::new (@arg);
    my $self = bless {@args}, ref $class || $class;

    $self->{files} = {};
    $self->{conflicts} = [];

    return $self;
}

sub close_edit {
    my ($self, $pool) = @_;

    if (@{$self->{conflicts}}) {
        my $msg = "  ".join("\n  ", @{$self->{conflicts}});

        if (@{$self->{conflicts}} == 1) {
            $msg = loc("Conflict detected in:\n%1\n".
                "file. Do you want to skip it and commit other changes? (y/n) ",
                $msg);
        } else {
            $msg = loc("Conflict detected in:\n%1\n".
                "files. Do you want to skip those and commit other changes? (y/n) ",
                $msg);
        }

        if (SVK::Util::get_prompt($msg, qr/^[yn]$/i) =~ /[Nn]/) {
            $_->on_end_selection_phase($self)
                for @{$self->{actions}};

            for (@{$self->{conflicts}}) {
                $self->{notify}->node_status($_, 'C');
                $self->{notify}->flush($_);
            }
                
            $_->on_end_selection_phase_last_chance($self)
                for @{$self->{actions}};
            return;
        } else {
            my (%actions, @actions);
            @actions = map {delete $self->{info}{$_}} @{$self->{conflicts}};
            # flatten actions list.
            push @actions, @{$_->{children}} for @actions;
            @actions = map {$_->{id}} @actions;

            @actions{@actions} = 1;

            $self->{actions} =
                [grep {not exists $actions{$_->{id}}} @{$self->{actions}}];
        }
    }

    my $ui = SVK::Editor::InteractiveStatus::UI->new($self);
    $ui->run;
    # Should this be on close edit???
    $_->on_end_selection_phase($self)
        for @{$self->{actions}};
    $_->on_end_selection_phase_last_chance($self)
        for @{$self->{actions}};
}

sub abort_edit {
    my ($self, $pool) = @_;

}

sub open_root {
    my ($self, $baserev, $pool) = @_;

    push @{$self->{actions}}, $self->{info}{''} =
        SVK::Editor::InteractiveStatus::OpenDirectoryAction->
            new(undef, $self, '', '', $baserev, $pool);

    return '';
}

sub add_file {
    my ($self, $path, $pdir, $copy_path, $rev, $pool) = @_;

    push @{$self->{actions}}, $self->{info}{$path} =
        SVK::Editor::InteractiveStatus::AddFileAction->new($pdir, @_);
    
    return $path;
}

sub open_file {
    my ($self, $path, $pdir, $rev, $pool) = @_;

    push @{$self->{actions}}, $self->{info}{$path} =
        SVK::Editor::InteractiveStatus::ModifyFileAction->new($pdir, @_);

    return $path;
}

sub apply_textdelta {
    my ($self, $path, $checksum, $pool) = @_;
    my $action = $self->{info}{$path};

    return $action->on_apply_textdelta(@_);
}

sub change_file_prop {
    my ($self, $path, $name, $value, $pool) = @_;
    
    push @{$self->{actions}}, $self->{info}{$path}{props}{$name} = 
        SVK::Editor::InteractiveStatus::ModifyFilePropAction->new($path, @_);
}

sub close_file {
    my ($self, $path, $checksum, $pool) = @_;
    my $action = $self->{info}{$path};

    $action->on_close_file(@_);
}

sub delete_entry {
    my ($self, $path, $rev, $pdir, $pool) = @_;

    my $parent = $path;

    do {
        $parent =~ s{/[^/]*$}{};
    } while (not $self->{info}{$parent});

    return if $pdir ne $parent;

    push @{$self->{actions}}, $self->{info}{$path} =
        SVK::Editor::InteractiveStatus::DeleteFileAction->new($parent, @_);
}

sub add_directory {
    my ($self, $path, $pdir, $copy_from, $rev, $pool) = @_;

    push @{$self->{actions}}, $self->{info}{$path} =
        SVK::Editor::InteractiveStatus::AddDirectoryAction->new($pdir, @_);

    return $path;
}

sub open_directory {
    my ($self, $path, $pdir, $rev, $pool) = @_;

    push @{$self->{actions}}, $self->{info}{$path} =
        SVK::Editor::InteractiveStatus::OpenDirectoryAction->new($pdir, @_);

    return $path;
}

sub change_dir_prop {
    my ($self, $path, $name, $value, $pool) = @_;

    push @{$self->{actions}}, $self->{info}{$path}{props}{$name} = 
        SVK::Editor::InteractiveStatus::ModifyDirectoryPropAction->new($path, @_);
}

sub close_directory {
    my ($self, $path) = @_;
    my $action = $self->{info}{$path};

    $action->on_close_directory(@_);
}

sub conflict {
    my ($self, $path) = @_;

    push @{$self->{conflicts}}, $path;
}

package SVK::Editor::InteractiveStatus::UI;
use SVK::I18N;

sub new {
    my ($class, $editor) = @_;
    my $qcount = 0;

    my $self = bless {
        actions => $editor->{actions},
        current_question => -1,
        current_action => 0,
        current_action_question => -1
    }, $class;

    $qcount += $_->get_questions_count for @{$self->{actions}};
    $self->{questions_count} = $qcount;

    return $self;
}

sub _loc {
    my ($text, $keys, @keys) = @_;

    ($text, @keys) = split /#/, $text;
    return ($text, join("",@keys), $keys);
}

my %prompts = (
    basic =>
        [_loc("[a]ccept, [s]kip this change#a#s", "as")],
    fileChunks =>
        [_loc("[A]ccept, [S]kip the rest of changes to this file#A#S", "AS")],
    fileProps =>
        [_loc("a[c]cept, s[k]ip rest of changes to this file and its properties#c#k", "ck")],
    dirSubdir =>
        [_loc("[A]ccept, [S]kip changes to whole subdirectory#A#S", "AS")],
    dirSubdirAcceptOnly =>
        [_loc("[A]ccept changes to whole subdirectory#A", "A")],
    propsFile =>
        [_loc("[A]ccept, [S]kip the rest of changes to this file properties#A#S", "AS")],
    propsDir =>
        [_loc("[A]ccept, [S]kip the rest of changes to this directory properties#A#S", "AS")],
    props =>
        [_loc("a[c]cept, s[k]ip changes to all properties with that name#c#k", "ck")],
    move_back =>
        [_loc("move to [p]revious change#p", "p")],
);

sub run {
    my $self = shift;
    my ($question, $flags, $state, $change_info, $action, $regexp);

    $self->next_question;

    while ($self->{current_question} < $self->{questions_count}) {
        my ($answers, $keys, @prompts);

        $action = $self->{actions}[$self->{current_action}];

        ($question, $flags, $state, $change_info) =
            $action->get_question($self->{current_action_question});
        
        my @flags = ('basic', @$flags);
        push @flags, 'move_back' if $self->{current_question} > 0;

        for (@flags) {
            push @prompts, $prompts{$_}->[0];
            $keys.= $prompts{$_}->[1];
            $answers.= $prompts{$_}->[2];
        }

        $question = ($change_info||"")."\n[".
            ($self->{current_question}+1)."/$self->{questions_count}] ".
            "$question:\n".join(",\n", @prompts);

        if ($$state) {
            $regexp = qr/^[$keys]?$/;
            $question.= " [$$state]> ";
        } else {
            $regexp = qr/^[$keys]$/;
            $question.= " > ";
        }

        my $answer = SVK::Util::get_prompt($question, $regexp) || $$state;
        $answer =~ eval "\$answer =~ tr/$keys/$answers/";

        if ($answer eq 'p') {
            $self->previous_question;
            next;
        }

        my $res = $action->on_state_update(
            $self->{current_action_question}, $answer);

        $$state = $answer;
        $self->update_questions_count if $res;

        $self->next_question;
    }
}

sub update_questions_count {
    my $self = shift;
    my $qcount = 0;

    $qcount += $_->get_questions_count
        for @{$self->{actions}}[0..$self->{current_action}-1];

    $self->{current_question} = $self->{current_action_question} + $qcount;

    $qcount += $_->get_questions_count
        for @{$self->{actions}}[$self->{current_action}..$#{$self->{actions}}];

    $self->{questions_count} = $qcount;
}

sub next_question {
    my $self = shift;
    my $qid = $self->{current_action_question}+1;
    my $aid = $self->{current_action};

    $self->{current_question}++;

    do {
        if ($self->{actions}[$aid]->get_questions_count > $qid) {
            $self->{current_action_question} = $qid;
            $self->{current_action} = $aid;

            return 1;
        }
        $qid = 0;
        $aid++;
    } while ($aid < @{$self->{actions}});

    return 0;
}

sub previous_question {
    my $self = shift;

    return 0 if $self->{current_question} == 0;

    if ($self->{current_action_question} > 0) {
        --$self->{current_action_question};
        --$self->{current_question};
        return 1;
    }

    my $aid = $self->{current_action}-1;
    $aid-- while $self->{actions}[$aid]->get_questions_count <= 0;

    $self->{current_action_question} =
        $self->{actions}[$aid]->get_questions_count - 1;
    $self->{current_action} = $aid;
    $self->{current_question}--;

    return 1;
}

package SVK::Editor::InteractiveStatus::Action;

sub AUTOLOAD {
    no strict 'refs';
    our $AUTOLOAD;
    my ($self, @arg) = @_;
    my $name = $AUTOLOAD;
    $name =~ s/^.*::on_(.*)_commit$/$1/;

    return unless $name and grep {$name eq $_} qw(delete_entry
        add_file open_file add_directory open_directory apply_textdelta
        change_file_prop close_file change_dir_prop close_directory);

    my $pos = SVK::Editor->baton_at($name);
    if ($pos >= 0) {
        *$AUTOLOAD = sub {
            my ($action, $editor, @args) = @_;
            $args[$pos] = $editor->{storage_baton}{$args[$pos]};
            $editor->{storage}->$name(@args);
        }
    } else {
        *$AUTOLOAD = sub {
            my ($action, $editor, @args) = @_;
            $editor->{storage}->$name(@args);
        }
    }

    goto &$AUTOLOAD;
}

my %globalPropsState;
my $currId = 0;

sub new {
    my ($class, $parent, $editor, $path) = @_;

    my $self = bless {
        path => $path,
        id => $currId++,
        state => '',
        force_disable => {},
        force_enable => {},
        children => [],
    }, $class;

    $parent = $editor->{info}{$parent} if defined $parent;
    push @{$parent->{children}}, $self if $parent;

    return $self;
}

sub on_apply_textdelta { }
sub on_close_file { }
sub on_close_directory { }

sub enabled {
    my $self = shift;

    return 0 if %{$self->{force_disable}};
    return 1 if %{$self->{force_enable}};

    return $self->{enabled} ? 1 : 0;
}

sub get_questions_count {
    my $self = shift;

    return %{$self->{force_disable}} ||
           %{$self->{force_enable}} ? 0 : 1;
}

sub update_children_state {
    my ($self, $state, $by_who) = @_;

    return grep {$_->on_state_update(undef, $state, $by_who || $self)}
        @{$self->{children}};
}

sub on_state_update {
    my ($self, $id, $state, $by_who) = @_;

    if ($by_who) {
        if ($state =~ /[Ac]/) {
            return 0 if exists $self->{force_enable}{$by_who->{id}};

            delete $self->{force_disable}->{$by_who->{id}};
            $self->{force_enable}{$by_who->{id}} = 1;
        } elsif ($state =~ /[Sk]/) {
            return 0 if exists $self->{force_disable}{$by_who->{id}};

            delete $self->{force_enable}->{$by_who->{id}};
            $self->{force_disable}{$by_who->{id}} = 1;
        } else {
            my $ret = delete $self->{force_enable}->{$by_who->{id}};
            $ret ||= delete $self->{force_disable}->{$by_who->{id}};
            return 0 if not $ret;

            $self->update_children_state($state, $by_who);
            return 1;
        }
        $self->update_children_state($state, $by_who);

        return 1;
    }
    $self->{enabled} = $state =~ /[aAc]/;

    return 0;
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;
    $editor->{notify}->node_status($self->{path}, '');
}

sub on_end_selection_phase_last_chance {
    my ($self, $editor) = @_;

    $editor->{notify}->flush($self->{path});
}

package SVK::Editor::InteractiveStatus::AddFileAction;
use base qw(SVK::Editor::InteractiveStatus::Action);

use SVK::I18N;

sub on_apply_textdelta_commit {
    my ($self, $editor, $path, $checksum, $pool) = @_;

    return $self->SUPER::on_apply_textdelta_commit(@_[1..$#_])
        if $self->enabled;

    return undef;
}

sub get_question {
    my ($self, $id) = @_;

    return (loc("File '%1' is marked for addition", $self->{path}),
        [], \$self->{state});
}

sub on_state_update {
    my ($self, $id, $state, $by_who) = @_;

    my $res = $self->SUPER::on_state_update($id, $state, $by_who);
    return $res if $by_who;

    return 0 if $state eq $self->{state};

    return $self->update_children_state($state eq 's' ? 'S' : $state)
        if $self->{state} =~ /[s]/ or $state =~ /[s]/;

    return 0;
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;

    if ($self->enabled) {
        $editor->{notify}->node_status($self->{path}, 'A');
    } else {
        $editor->{notify}->node_status($self->{path}, '');
        $editor->{cb_skip_add}($self->{path});
    }
}

package SVK::Editor::InteractiveStatus::ModifyFileAction;
use base qw(SVK::Editor::InteractiveStatus::Action);

use List::Util qw(min max);
use Digest::MD5 qw(md5_hex);
use SVK::Util qw(mimetype_is_text $EOL);
use SVK::I18N;

sub new {
    my ($class, $parent, $editor, $path, $pdir, $rev, $pool) = @_;
    my $self = $class->SUPER::new(@_[1..$#_]);

    $self->{rev} = $rev;

    return $self
}

sub on_apply_textdelta {
    my ($self, $editor, $path, $checksum, $pool) = @_;

    my ($type) = grep {$_->{name} eq 'svn:mime-type'}
        @{$self->{children}};

    if ($type and !mimetype_is_text($type->{value}) or
        ($type = $editor->{inspector}->localprop($path, 'svn:mime-type', $pool)) and
        !mimetype_is_text($type))
    {
        bless $self,
            "SVK::Editor::InteractiveStatus::ModifyBinaryFileAction";
        return $self->on_apply_textdelta(@_[1..$#_]);
    }
    
    my $fh1 = $editor->{inspector}->localmod($path, '', $pool)->[0];

    {
        # XXX: some swig build doesn't like like mg $/ used in
        # SVN::Stream::readline, so we have to deal with the complicated last newline
        local $/;
        my $buf = <$fh1>;
        if (length $buf) {
            $self->{old_content} = [map { "$_\n" } $buf =~ m/^.*$/mg ];
            substr($self->{old_content}[-1], -1, 1, '')
                if substr($buf, -1, 1) ne "\n";
        }
    }
    $self->{new_content} = '';
    open my $fh2, '>', \$self->{new_content};

    $self->{original_checksum} = $checksum;

    return [SVN::TxDelta::apply($fh1, $fh2,
                                undef, undef, $pool)];
}

sub on_apply_textdelta_commit {
    my ($self, $editor, $path, $checksum, $pool) = @_;
    return undef if $self->{empty_change};

    my $handle = SVK::Editor::InteractiveStatus::Action::on_apply_textdelta_commit(@_);

    return $handle if $self->{full_change};
    
    if ($handle && $#{$handle} >= 0) {
        open my $nfh, '<', \$self->{new_content};
        if ($editor->{send_fulltext}) {
            SVN::TxDelta::send_stream($nfh, @$handle, $self->{pool});
        } else {
            my $ofh = $editor->{inspector}->localmod($path, '', $pool)->[0];
            my $txstream = SVN::TxDelta::new($ofh, $nfh, $pool);

            SVN::TxDelta::send_txstream($txstream, @$handle, $self->{pool});
        }
    }
    return undef;
}

sub on_close_file_commit {
    my ($self, $editor, $path, $checksum, $pool) = @_;

    $editor->{storage}->close_file($editor->{storage_baton}{$path},
        $self->{checksum}, $pool);
}

sub enabled {
    my $self = shift;

    return 0 if %{$self->{force_disable}};
    return 1 if %{$self->{force_enable}};

    return 1 if grep {$_ =~ /[aAc]/} @{$self->{states}};

    return grep {$_->enabled} @{$self->{children}};
}

sub get_questions_count {
    my $self = shift;

    unless (exists $self->{chunks}) {
        $self->split_diff_into_chunks;
    }

    return $self->{cutoff};
}

sub get_question {
    my ($self, $id) = @_;
    my @flags;

    push @flags, "fileChunks" if $id*2+1 < $#{$self->{chunks}};
    push @flags, "fileProps" if @{$self->{children}};

    return (loc("Modification to '%1' file", $self->{path}),
        \@flags, \$self->{states}[$id], $self->{chunks}[$id*2+1][2]);
}

sub on_state_update {
    my ($self, $id, $state, $by_who) = @_;

    my $res = $self->SUPER::on_state_update($id, $state, $by_who);
    return $res if $by_who;

    return 0 if $state eq $self->{states}[$id];

    if ($self->{states}[$id] =~ /[ck]/ or $state =~ /[ck]/) {
        $res = $self->update_children_state($state =~ /[AS]/ ? 'a' : $state);
    }

    if ($state =~ /[ASck]/) {
        ++$id;
        return $self->{cutoff} = $id if $id != $self->{cutoff};
        return $res;
    }

    $id = $self->{cutoff};
    $self->{cutoff} = int(@{$self->{chunks}}/2);

    return $id ne $self->{cutoff};
}

use constant CONTEXT => 5;

sub split_diff_into_chunks {
    my $self = shift;
    my ($p, $b1, $b2, $d1, $d2, $i1, $i2, $a1, $a2) = (0);
    my $di;

    my @old_content = $self->{old_content} ? @{$self->{old_content}} : ();
    delete $self->{old_content};

    my @new_content = defined $self->{new_content} ?
        $self->{new_content} =~ m/.*\n?/g : (1);
    pop @new_content;

    my ($lln, $rln) = (
        !(@old_content and $old_content[-1] =~ /\n$/),
        !(@new_content and $new_content[-1] =~ /\n$/));

    my ($lo, $ln) = (@old_content-1, @new_content-1);
    my $diff = new Algorithm::Diff(\@old_content, \@new_content);

    while ($diff->Next()) {
        next if $diff->Same();

        ($d1, $d2, $i1, $i2) = $diff->Get(qw(Min1 Max1 Min2 Max2));

        if (not $diff->Items(2)) {
            ($b1, $b2) = (max(0, $d1 - CONTEXT), max(-1, $d1 - 1));
            ($a1, $a2) = (min($lo + 1, $d2 + 1), min($lo, $d2 + CONTEXT));
        } elsif (not $diff->Items(1)) {
            ($b1, $b2) = (max(0, $d2 - CONTEXT - 1), $d2);
            ($a1, $a2) = (min($lo + 1, $b2 + 1), min($lo, $b2 + CONTEXT));
        } else {
            ($b1, $b2) = (max(0, $d1 - CONTEXT), max(-1, $d1 - 1));
            ($a1, $a2) = (min($lo + 1, $d2 + 1), min($lo, $d2 + CONTEXT));
        }
        $di = "--- $self->{path}\t(revision $self->{rev})".$EOL;
        $di.= "+++ $self->{path}\t(local)".$EOL;
        my ($l1, $l2) = map {$_ < 1 ? "" : ",$_" } $a2-$b1, $i2-$i1+$a2-$b1;
        $di.= "@@ -$b1$l1 +@{[$i1+$b1-$d1]}$l2 @@".$EOL;
        $di.= join " ","",@old_content[$b1..$b2] if $b1 <= $b2;
        if ($d1 <= $d2) {
            $di.= join "-","",@old_content[$d1..$d2];
            $di.= "\n\\ No newline at end of file".$EOL if $lln and $d2 == $lo;
        }
        if ($i1 <= $i2) {
            $di.= join "+","",@new_content[$i1..$i2];
            $di.= "\n\\ No newline at end of file".$EOL if $rln and $i2 == $ln;
        }
        $di.= join " ","",@old_content[$a1..$a2] if $a1 <= $a2;

        my $b = $p <= $b2  ? join "",@old_content[$p..$b2]  : "";
        my $d = $d1 <= $d2 ? join "",@old_content[$d1..$d2] : "";
        my $i = $i1 <= $i2 ? join "",@new_content[$i1..$i2] : "";

        $p = $a1;

        push @{$self->{chunks}}, $b, [$d, $i, $di];
    }
    push(@{$self->{chunks}}, join("",@old_content[$p..$lo]));

    $self->{cutoff} = int(@{$self->{chunks}}/2);
    $self->{states} = [('') x $self->{cutoff}];
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;

    unless (exists $self->{chunks}) {
        $self->split_diff_into_chunks;
    }

    my @states = map {$_ =~ /[aAc]/ ? 1 : 0} @{$self->{states}};

    @states[$self->{cutoff}..@states] =
        ($self->{cutoff} ? $states[$self->{cutoff}-1] : '') x (@states - $self->{cutoff});

    unless (grep {$_} @states) {
        $editor->{notify}->node_status($self->{path}, '');
        return $self->{empty_change} = 1;
    }

    $editor->{notify}->node_status($self->{path}, 'M');

    return $self->{full_change} = 1 unless grep {!$_} @states;

    my $v = '';
    for (my $idx = 1; $idx < @{$self->{chunks}}; $idx += 2) {
        $v.= $self->{chunks}[$idx-1];
        $v.= $self->{chunks}[$idx][$states[$idx/2]];
    }
    $self->{new_content} = $v.$self->{chunks}[-1];
    $self->{checksum} = md5_hex($self->{new_content});
}

package SVK::Editor::InteractiveStatus::ModifyBinaryFileAction;
use base qw(SVK::Editor::InteractiveStatus::AddFileAction);

use SVK::I18N;

sub get_question {
    my ($self, $id) = @_;
    my @flags;

    push @flags, "fileProps" if @{$self->{children}};

    return (loc("Modifications to binary file '%1'", $self->{path}),
        \@flags, \$self->{state});
}

sub on_state_update {
    my ($self, $id, $state, $by_who) = @_;

    my $res = $self->SUPER::on_state_update($id, $state, $by_who);
    return $res if $by_who;

    if ($state =~ /[ck]/ or $self->{state} =~ /[ck]/) {
        return $self->update_children_state($state);
    }

    return 0;
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;

    $editor->{notify}->node_status($self->{path}, $self->enabled ? 'U' : '');
}

package SVK::Editor::InteractiveStatus::DeleteFileAction;
use base qw(SVK::Editor::InteractiveStatus::Action);

use SVK::I18N;

sub get_question {
    my ($self, $id) = @_;

    return (loc("File or directory '%1' is marked for deletion", $self->{path}),
        [], \$self->{state});
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;

    $editor->{notify}->node_status($self->{path}, 'D') if $self->{enabled}
}

package SVK::Editor::InteractiveStatus::ModifyFilePropAction;
use base qw(SVK::Editor::InteractiveStatus::Action);

use SVK::I18N;
use SVK::Util qw(tmpfile slurp_fh);

sub new {
    my ($class, $parent, $editor, $path, $name, $value, $pool) = @_;
    my $self = $class->SUPER::new(@_[1..$#_]);

    my ($l, $r) = $editor->{inspector}->localprop($path, $name, $pool);
    ($l, $r) = map { !length || /\n$/ ? $_ : "$_\n"}
        defined $l ? $l : "", defined $value ? $value : "";

    my ($lfh, $lfn) = tmpfile('diff'); 
    my ($rfh, $rfn) = tmpfile('diff'); 

    slurp_fh($l, $lfh); close($lfh);
    slurp_fh($r, $rfh); close($rfh);

    my $diff = '';
    open my $fh, '>', \$diff;

    my $dh = SVN::Core::diff_file_diff($lfn, $rfn);
    SVN::Core::diff_file_output_unified($fh, $dh, $lfn, $rfn,
        '', '', $pool);

    $diff =~ s/.*\n.*\n//;
    $diff =~ s/^\@.*\n//mg;
    $diff =~ s/^/ /mg;

    $self->{name} = $name;
    $self->{value} = $value;
    $self->{diff} =
        "Property change on $path\n".("_" x 67)."\n".
        "Name: $name\n$diff";

    return $self;
}

sub get_questions_count {
    my $self = shift;

    return %{$self->{force_disable}} ||
           %{$self->{force_enable}} ||
           exists $globalPropsState{$self->{name}} &&
                $self->{state} !~ /[ck]/ ? 0 : 1;
}

sub get_question {
    my ($self, $id) = @_;
    my @flags = qw(props);

#    unshift @flags, "propsFile" if $id*2 < @{$self->{chunks}};

    return (loc("Property change on '%1' file requested", $self->{path}),
        \@flags, \$self->{state}, $self->{diff});
}

sub on_state_update {
    my ($self, $id, $state, $by_who) = @_;

    my $res = $self->SUPER::on_state_update($id, $state, $by_who);
    return $res if $by_who;

    if ($state ne $self->{state}) {
        if ($state eq 'c') {
            $globalPropsState{$self->{name}} = 1;
        } elsif ($state eq 'k') {
            $globalPropsState{$self->{name}} = 0;
        } elsif ($self->{state} =~ /[ck]/) {
            delete $globalPropsState{$self->{name}};
        } else {
            return 0;
        }
        return 1;
    }
    return 0;
}

sub enabled {
    my $self = shift;
    my $globPropState = $globalPropsState{$self->{name}};

    return 0 if %{$self->{force_disable}} or
        defined $globPropState and not $globPropState;
    return 1 if %{$self->{force_enable}} or
        $globPropState;

    return $self->{enabled};
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;

    if ($self->enabled) {
        $editor->{notify}->prop_status($self->{path}, 'M');
    } else {
        $editor->{cb_skip_prop_change}($self->{path},
            $self->{name}, $self->{value});
    }
}

sub on_end_selection_phase_last_chance { }

package SVK::Editor::InteractiveStatus::AddDirectoryAction;
use base qw(SVK::Editor::InteractiveStatus::Action);

use SVK::I18N;

sub get_question {
    my ($self, $id) = @_;
    my @flags = ();

    push @flags, "dirSubdirAcceptOnly"
        if grep { (ref $_) =~ '::Add(?:File|Directory)Action$' } @{$self->{children}};

    return (loc("Directory '%1' is marked for addition", $self->{path}),
        \@flags, \$self->{state});
}

sub on_state_update {
    my ($self, $id, $state, $by_who) = @_;

    my $res = $self->SUPER::on_state_update($id, $state, $by_who);
    return $res if $by_who;

    return $self->update_children_state($state eq 's' ? 'S' : $state)
        if $state ne $self->{state} and ($self->{state} or $state =~ /[sA]/);

    return 0;
}

sub on_end_selection_phase {
    my ($self, $editor) = @_;

    if ($self->enabled) {
        $editor->{notify}->node_status($self->{path}, 'A');
    } else {
        $editor->{notify}->node_status($self->{path}, '');
        $editor->{cb_skip_add}($self->{path});
    }
}

sub on_end_selection_phase_last_chance {
    my ($self, $editor) = @_;

    $editor->{notify}->flush($self->{path});
}

package SVK::Editor::InteractiveStatus::OpenDirectoryAction;
use base qw(SVK::Editor::InteractiveStatus::Action);

sub get_questions_count {
    return 0;
}

package SVK::Editor::InteractiveStatus::ModifyDirectoryPropAction;
use base qw(SVK::Editor::InteractiveStatus::ModifyFilePropAction);

use SVK::I18N;

sub get_question {
    my ($self, $id) = @_;
    my @flags = qw(props);
    my $path = $self->{path} eq '' ? "." : "$self->{path}";

#    unshift @flags, "propsFile" if $id*2 < @{$self->{chunks}};

    return (loc("Property change on '%1' directory requested", $path),
        \@flags, \$self->{state}, $self->{diff});
}

1;


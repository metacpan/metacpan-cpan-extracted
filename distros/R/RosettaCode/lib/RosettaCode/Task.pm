use strict; use warnings;
package RosettaCode::Task;

use IO::All;
use Carp 'confess';

use Mo qw'build default xxx';

extends 'RosettaCode';

has name   => '';
has path   => '';
has url    => '';
has meta   => {};
has lang   => '';
has prog   => [];
has tasks  => {};
has langs  => {};
has bot    => '';

sub fetch_task {
    my ($self) = @_;
    my $file = io->file("Cache/Task/$self->{path}")->utf8;

    if ($file->exists and time - $file->mtime < $self->CACHE_TIME) {
        $self->text($file->all);
    }
    else {
        my $text = $self->get_text($self->name);
        $file->assert->print($text);
        $self->text($text);
    }
}

sub build_task {
    my ($self) = @_;

    my $name = $self->name;
    my $text = $self->text;
    $text =~ s/\r//g;
    $text =~ s/\n?\z/\n/ if length $text;

    $self->log("TASK    $name");
    my @sections = split /^==+ ?\{\{header\|(.+?)\}\}.*\n/m, $text;
    if (@sections < 3 or $text !~ /<syntaxhighlight/) {
        $self->log("ERROR: No implementations for '$name'");
    }
    my $head_section = shift @sections;
    if (@sections % 2) {
        $self->log("ERROR: Bad task page for '$name'");
        return;
    }
    $self->parse_head_section($head_section);
    my $path = $self->path;
    my $file = lc($path);

    while (@sections) {
        my ($lang, $text) = splice(@sections, 0, 2);
        $lang =~ s/\|.*//;
        $self->log("  $lang");
        my $info = $self->langs->{lc $lang};
        if (not defined $info) {
            $self->log("ERROR: Unknown lang '$lang' ($name)");
            next;
        }
        $self->parse_task_lang_section($text, $lang);
        my $programs = $self->prog;
        next unless @$programs;
        my $lang_path = $info->{path};
        my $ext = $info->{ext};
        my $source = "Lang/$lang_path/$path";
        my $target = "../../Task/$path/$lang_path";
        $self->write_symlink($source, $target, 2);
        if (@$programs == 1) {
            $self->write_file(
                "Task/$path/$lang_path/$file.$ext",
                $programs->[0],
                2,
            );
            next;
        }
        my $count = 1;
        for (@$programs) {
            $self->write_file(
                "Task/$path/$lang_path/$file-$count.$ext",
                $_,
                2,
            );
            $count++;
        }
    }

    $self->meta->{from} = "http://rosettacode.org/wiki/$self->{url}";
    $self->write_file(
        "Task/$path/00-TASK.txt",
        delete $self->meta->{description},
        1,
    );
    $self->dump_file(
        "Task/$path/00-META.yaml",
        $self->meta,
        1,
    ) if %{$self->meta};
}

sub parse_head_section {
    my ($self, $text) = @_;
    $_ = $text;
    my $meta = $self->meta({});

    my $length = length;
    while (1) {
        s/\A<!--.*-->\s*//;
        s/\A\[\[File:.*\s*//;
        s/\A\{\{alertbox\|.*\n\s*//;
        s/\A\{\{[Cc]larified-review\}\}\s*//;
        s/\A\{\{[Cc]larify task\}\}\s*//;
        s/\A\{\{[Oo]mit from\|.*\}\}\s*//;
        s/\A\[\[[Ff]ile:.*\]\]\s*//;
        s/\A\{\{[Ww]ikipedia[^\}]*\}\}\s*//;

        if (s/\A\s*\{\{requires\|(\w[\w ]*)\}\}\s*//) {
            $meta->{requires} ||= [];
            push @{$meta->{requires}}, $1;
        }
        if (s/\A\s*\[\[Category: *(\w[\w ]*)\]\]\s*//) {
            $meta->{category} ||= [];
            push @{$meta->{category}}, $1;
        }
        if (s/\A\{\{(?:[Dd]raft\s+)?[Tt]ask(?:\|([^\}]*?))?\}\}\s*//s) {
            $meta->{note} = $1 if $1;
        }

        last if length == $length;
        $length = length;
    }

    # Get task description text:
    $meta->{description} = $_ if $_;
}

sub parse_task_lang_section {
    my ($self, $text, $lang) = @_;
    local $_ = $text;
    $self->lang($lang);
    my $programs = $self->prog([]);

    while (s/<syntaxhighlight.*?>(.*?)(?:<\/syntaxhighlight>|\z)//si) {
        my $program = $1;
        $program =~ s/\A\s*\n//;
        $program =~ s/ *$//mg;
        $program =~ s/\n*\z/\n/ if length($program);
        push @$programs, $program;
    }
}

1;

use strict; use warnings;
package RosettaCode;

our $VERSION = '0.1.1';

use RosettaCode::Lang;
use RosettaCode::Task;

use utf8;
use MediaWiki::Bot;
use YAML::PP;
use Carp 'confess';

use Module::Pluggable
  require     => 1,
  search_path => [ 'RosettaCode::Command' ];
RosettaCode->plugins;

use Mo qw'build builder default xxx';
extends 'RosettaCode::Command';

has text   => '';
has log_io => '';

use File::Path 'rmtree';
use IO::All;

use constant abstract => 'Sync local repository with remote RosettaCode wiki';
use constant usage_desc => 'rosettacode sync <target_directory> [<options>]';
use constant options => [qw( target )];

use constant ROSETTACODE_API_URL => 'http://rosettacode.org/w/api.php';
use constant TASKS_FILE => 'Cache/tasks.txt';
use constant LANGS_FILE => 'Cache/langs.txt';
use constant TASKS_CATEGORY => 'Category:Programming_Tasks';
use constant LANGS_CATEGORY => 'Category:Programming_Languages';
use constant CACHE_TIME => 7 * 24 * 60 * 60;

has bot => (builder => 'build_bot');
has tasks => (builder => 'build_tasks');
has langs => (builder => 'build_langs');
has log_io => io->file('rosettacode.log')->utf8;

sub run {
    my ($self) = @_;

    die "Current directory does not look like a RosettaCodeData directory"
        unless -f 'Conf/task.yaml';

    for my $dir (qw( Meta Lang Task )) {
        if (-d $dir) {
            print "Removing '$dir'\n";
            rmtree $dir
                or die "Failed to rm -r Meta Lang Task";
        }
    }

    $self->log("START RosettaCode Sync");
    for my $lang (sort keys %{$self->langs}) {
        my $langs = $self->langs;
        my $info = $langs->{$lang} or next;

        my $rcl = RosettaCode::Lang->new(
            %$info,
            langs  => $self->langs,
            tasks  => $self->tasks,
            bot    => $self->bot,
            log_io => $self->log_io,
        );

        print "* LANG: $info->{name}\n";

        $rcl->fetch_lang;

        next if $ENV{RCD_FETCHONLY};

        $rcl->build_lang;
    }

    for my $task (sort keys %{$self->tasks}) {
        # exit if $a++ > 100;
        my $tasks = $self->tasks;
        my $info = $tasks->{$task} or next;

        my $rct = RosettaCode::Task->new(
            %$info,
            langs  => $self->langs,
            tasks  => $self->tasks,
            bot    => $self->bot,
            log_io => $self->log_io,
        );

        print "* TASK: $rct->{name}\n";

        $rct->fetch_task;

        next if $ENV{RCD_FETCHONLY};

        $rct->build_task;
    }

    $self->log("COMPLETE RosettaCode Sync");
}

sub build_tasks {
    my ($self) = @_;
    my $io = io->file(TASKS_FILE)->utf8;
    my @task_list;
    if ($io->exists and time - $io->mtime < CACHE_TIME) {
         @task_list = $io->chomp->slurp;
    }
    else {
        @task_list = $self->get_category(TASKS_CATEGORY);
        $io->assert->println($_) for @task_list;
    }
    my $tasks = YAML::PP::LoadFile('Conf/task.yaml');
    for my $name (keys %$tasks) {
        my $info = $tasks->{$name} ||= {};
        $info->{name} = $name;
        $info->{url} = $name;
        $info->{url} =~ s/ /_/g;
        $info->{path} = $name;
        $info->{path} =~ s/[\'\"]//g;
        $info->{path} =~ s/[\,\ \/\*\!\(\)\x{7f}-\x{ffff}]+/-/g;
        die unless $info->{path};
        die if $info->{path} eq '-';
    }
    return $tasks;
}

sub build_langs {
    my ($self) = @_;
    my $io = io->file(LANGS_FILE)->utf8;
    my @lang_list;
    if ($io->exists and time - $io->mtime < CACHE_TIME) {
         @lang_list = $io->chomp->slurp;
    }
    else {
        @lang_list = map {
            s/^Category://;
            $_;
        } $self->get_category(LANGS_CATEGORY);
        $io->assert->println($_) for @lang_list;
    }
    my $langs = YAML::PP::LoadFile('Conf/lang.yaml');
    my $meta_langs = {};
    for my $name (keys %$langs) {
        my $text = $langs->{$name};
        my $info = {};
        $info->{name} = $name;
        $info->{url} = $name;
        $info->{url} =~ s/ /_/g;
        $info->{path} = $name;
        $info->{path} =~ s/[\ \/\*\!]/-/g;
        $text =~ s/^\.(\S+)\ ?// or die "ERROR: '$name: $text'";
        $info->{ext} = $1;
        $meta_langs->{lc $name} = $info;
    }

    # Common mutations:
    my $m = $meta_langs;
    my $alias = YAML::PP::LoadFile('Conf/alias.yaml');

    for (sort keys %{$alias->{lang}}) {
        $m->{$_} = $m->{$alias->{lang}{$_}};
    }

    $self->log("Dump    Meta/Lang.yaml");
    my $yaml = YAML::PP::Dump($meta_langs);
    $yaml =~ s/FALSE/'FALSE'/g;     # Fix YAML for Ruby
    io->file("Meta/Lang.yaml")->assert->print($yaml);
    return $meta_langs;
}

sub build_bot {
    my ($self) = @_;
    ROSETTACODE_API_URL =~ m!^(https?)://([^/]+)/(.*)/api.php$! or die;
    my ($protocol, $host, $path) = ($1, $2, $3);
    MediaWiki::Bot->new({
        agent =>
            'rosettacodedata/' . $VERSION
            . ' (https://github.com/ingydotnet/rosettacode-pm) MediaWiki::Bot/'
            . MediaWiki::Bot->VERSION,
        assert => 'bot',
        protocol => $protocol,
        host => $host,
        path => $path,
    });
}

sub get_text {
    my ($self, $name) = @_;
    $self->log("Fetch MediaWiki text for '$name'");
    return $self->bot->get_text($name);
}

sub get_category {
    my ($self, $category) = @_;
    $self->log("Fetch MediaWiki category '$category'");
    $self->bot->get_pages_in_category($category, {max => 0});
}

sub write_file {
    my ($self, $file, $content, $indent) = @_;
    $self->log('  ' x $indent . "Write   $file");
    io->file($file)->assert->utf8->print($content);
}

sub write_symlink {
    my ($self, $source, $target, $indent) = @_;
    $self->log('  ' x $indent . "Symlink $source -> $target");
    io->link($source)->assert->symlink($target);
}

sub dump_file {
    my ($self, $file, $object, $indent) = @_;
    $self->log('  ' x $indent . "Dump    $file");
    YAML::PP::DumpFile($file, $object);
}

sub log {
    my ($self, $string, @args) = @_;
    my $time = gmtime();
    $self->log_io->append(sprintf "<$time> $string\n", @args);
}

1;

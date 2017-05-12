package RosettaCode;
our $VERSION = '0.0.15';

use utf8;
use MediaWiki::Bot;
use YAML::XS;
use Carp;

use App::Cmd::Setup ();
App::Cmd::Setup->import(-app);

package RosettaCode::Command;
App::Cmd::Setup->import(-command);

package RosettaCode;

use Module::Pluggable
  require     => 1,
  search_path => [ 'RosettaCode::Command' ];
RosettaCode->plugins;

package RosettaCode::Command::sync;
use Mo qw'build builder default xxx';
extends 'RosettaCode::Command';

use IO::All;

use constant abstract => 'Sync local repository with remote RosettaCode wiki';
use constant usage_desc => 'rosettacode sync <target_directory> [<options>]';
use constant options => [qw( target )];

use constant ROSETTACODE_API_URL => 'http://rosettacode.org/mw/api.php';
use constant TASKS_FILE => 'Cache/tasks.txt';
use constant LANGS_FILE => 'Cache/langs.txt';
use constant TASKS_CATEGORY => 'Category:Programming_Tasks';
use constant LANGS_CATEGORY => 'Category:Programming_Languages';
use constant CACHE_TIME => 24 * 60 * 60;    # 24 hours

has bot => (builder => 'build_bot');
has tasks => (builder => 'build_tasks');
has langs => (builder => 'build_langs');
has target => ();

my $Log;
sub Log {
    my ($string, @args) = @_;
    my $time = gmtime();
    $Log->append(sprintf "<$time> $string\n", @args);
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Sync requires a <target_directory> argument")
        unless @$args == 1;
    my $target = $args->[0];
    $self->usage_error("'$target' directory does not exist")
        unless -d $target;
    my $conffile = "$target/Conf/rosettacode.yaml";
    $self->usage_error("'$conffile' does not exist")
        unless -f $conffile;
    $self->{target} = $target;
}

sub execute {
    my ($self) = @_;

    {
        my $target = $self->target;
        chdir $target or die "Can't chdir to '$target'";
        $Log = io->file('rosettacode.log')->utf8;
    }

    Log 'START RosettaCode Sync';
    for my $lang (sort keys %{$self->langs}) {
        my $info = $self->langs->{$lang};
        $self->parse_lang_page($info, $self->fetch_lang($info));
    }
    for my $task (sort keys %{$self->tasks}) {
        my $info = $self->tasks->{$task};
        $self->parse_task_page($info, $self->fetch_task($info));
    }
    Log 'COMPLETE RosettaCode Sync';
}

# TODO Parse out meta information from Language description text.
sub parse_lang_page {
    my ($self, $info, $content) = @_;
    Log "Parse Language '$info->{name}'";
    $self->write_file(
        "Lang/$info->{path}/README",
        "Data source: http://rosettacode.org/wiki/Category:$info->{url}\n",
    );
    $self->write_file("Lang/$info->{path}/00DESCRIPTION", $content);
}

sub parse_task_page {
    my ($self, $info, $content) = @_;
    Log "Parse Task '$info->{name}'";
    $content =~ s/\r//g;
    $content =~ s/\n?\z/\n/ if length $content;
    if ($content =~ /^#REDIRECT \[\[/) {
        $content =~ s/\n.*//s;
        Log "Skipping redirect: $content";
        return;
    }
    my ($text, $meta) = $self->parse_description(\$content)
        or $self->parse_fail($info->{name}, $content);
    my $path = $info->{path};
    my $file = lc($path);

    while (length $content) {
        my ($lang, @sections) = $self->parse_next_lang_section(\$content)
            or $self->parse_fail($info->{name}, $content);
        next unless $self->langs->{$lang};
        next unless @sections;
        my $lang_path = $self->langs->{$lang}->{path};
        my $ext = $self->langs->{$lang}->{ext} || '';
        $ext = ".$ext" if $ext;
        my $source = "Lang/$lang_path/$path";
        my $target = "../../Task/$path/$lang_path";
        $self->write_symlink($source, $target);
        if (@sections == 1) {
            $self->write_file("Task/$path/$lang_path/$file$ext", $sections[0]);
            next;
        }
        unlink "Task/$path/$lang_path/$file$ext";
        my $count = 1;
        for (@sections) {
            $self->write_file("Task/$path/$lang_path/$file-$count$ext", $_);
            $count++;
        }
    }

    $self->write_file(
        "Task/$path/README",
        "Data source: http://rosettacode.org/wiki/$info->{url}\n",
    );
    $self->write_file("Task/$path/00DESCRIPTION", $text);
    $self->dump_file("Task/$path/00META.yaml", $meta) if $meta;
}

sub parse_description {
    my ($self, $content) = @_;
    $$content =~ s/\A\[\[File:.*\s*//;
    $$content =~ s/\A\{\{alertbox\|.*\n\s*//;
    $$content =~ s/\A\{\{[Cc]larified-review\}\}\s*//;
    $$content =~ s/\A\{\{[Cc]larify task\}\}\s*//;
    $$content =~ s/\A\{\{[Oo]mit from\|.*\}\}\s*//;
    $$content =~ s/\A\[\[[Ff]ile:.*\]\]\s*//;
    $$content =~ s/\A\{\{[Ww]ikipedia[^\}]*\}\}\s*//;
    $$content =~ s/\A\{\{(?:[Dd]raft\s+)?[Tt]ask(?:\|([^\}]*?))?\}\}(.*?\n)(?===\{\{)//s or return;
    my ($note, $text) = ($1, $2);
    my $meta = $note ? {note => $note} : undef;
    while ($text =~ /\A\s*(?:\{\{requires|\[\[Category:)/) {
        $meta ||= {};
        if ($text =~ s/\A\s*\{\{requires\|(\w[\w ]*)\}\}//) {
            $meta->{requires} ||= [];
            push @{$meta->{requires}}, $1;
        }
        elsif ($text =~ s/\A\s*\[\[Category: *(\w[\w ]*)\]\]//) {
            $meta->{category} ||= [];
            push @{$meta->{category}}, $1;
        }
        else {
            die $text;
            return;
        }
    }
    $text =~ s/\A\s*\n//;
    $text =~ s/ *$//mg;
    $text =~ s/\n*\z/\n/ if length($text);
    return ($text, $meta);
}

sub parse_next_lang_section {
    my ($self, $content) = @_;
    $$content =~ s/\A==\{\{[Hh]eader\|(.*?)\}\}(.*?\n)(?:\z|(?===\{\{))//s or return;
    my ($lang, $text) = ($1, $2);
    Log "Parse language section: '$lang'";
    my $original = $text;
    my @sections;
    while ($text =~ s/<lang(?: [^>]+)?>(.*?)<\/lang *>//si) {
        my $section = $1;
        $section =~ s/\A\s*\n//;
        $section =~ s/ *$//mg;
        $section =~ s/\n*\z/\n/ if length($section);
        push @sections, $section;
    }
    die $text . $lang if $text =~ /<lang/;
    return ($lang, @sections);
}

sub fetch_task {
    my ($self, $info) = @_;
    my $file = io->file("Cache/Task/$info->{path}")->utf8;
    if ($file->exists and time - $file->mtime < CACHE_TIME) {
        return $file->all;
    }
    else {
        my $content = $self->get_text($info->{name});
        $file->assert->print($content);
        return $content;
    }
}

sub fetch_lang {
    my ($self, $info) = @_;
    my $file = io->file("Cache/Lang/$info->{path}")->utf8;
    if ($file->exists and time - $file->mtime < CACHE_TIME) {
        return $file->all;
    }
    else {
        my $content = $self->get_text(":Category:$info->{name}");
        $file->assert->print($content);
        return $content;
    }
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
    my $tasks = YAML::XS::LoadFile('Conf/task.yaml');
    for my $name (keys %$tasks) {
        my $info = $tasks->{$name} ||= {};
        $info->{name} = $name;
        $info->{url} = $name;
        $info->{url} =~ s/ /_/g;
        $info->{path} = $name;
        $info->{path} =~ s/[\'\"]//g;
        $info->{path} =~ s/[\ \/\*\!\(\)\x{7f}-\x{ffff}]/-/g;
        #$info->{path} =~ s/^-*(.*?)-*$/$1/;
        die unless $info->{path};
    }
    $self->dump_file("Meta/Task.yaml", $tasks);
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
    my $langs = YAML::XS::LoadFile('Conf/lang.yaml');
    for my $name (keys %$langs) {
        my $info = $langs->{$name} ||= {};
        $info->{name} = $name;
        $info->{url} = $name;
        $info->{url} =~ s/ /_/g;
        $name =~ s/é/e/g;
        $name =~ s/à/a/g;
        $info->{path} = $name;
        $info->{path} =~ s/[\ \/\*\!]/-/g;
        if (not exists $info->{ext}) {
            $info->{ext} = lc($name);
            $info->{ext} = 'net' if $info =~ /\.net$/;
            $info->{ext} = 'bas' if $info =~ /basic/;
            $info->{ext} = 'pas' if $info =~ /pascal/;
            $info->{ext} =~ s/ *script$//;
            $info->{ext} =~ s/[\ \/].*//;
            $info->{ext} =~ s/\+/p/g;
        }
        $info->{ext} ||= '';
    }
    Log "Dump YAML 'Meta/Lang.yaml'";
    my $yaml = YAML::XS::Dump($langs);
    $yaml =~ s/FALSE/'FALSE'/g;     # Fix YAML for Ruby
    io->file("Meta/Lang.yaml")->assert->print($yaml);
    return $langs;
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
    Log "Fetch MediaWiki text for '$name'";
    return $self->bot->get_text($name);
}

sub get_category {
    my ($self, $category) = @_;
    Log "Fetch MediaWiki category '$category'";
    $self->bot->get_pages_in_category($category, {max => 0});
}

sub write_file {
    my ($self, $file, $content) = @_;
    Log "Write '$file'";
    io->file($file)->assert->utf8->print($content);
}

sub write_symlink {
    my ($self, $source, $target) = @_;
    Log "Symlink $source -> $target";
    unlink($source);
    io->link($source)->assert->symlink($target);
}

sub dump_file {
    my ($self, $file, $object) = @_;
    Log "Dump YAML '$file'";
    YAML::XS::DumpFile($file, $object);
}

sub parse_fail {
    my ($self, $task, $content) = @_;
    my $msg = "Task '$task' parse failed:\n" . substr($content, 0, 200);
    Log $msg;
    Carp::confess $msg;
}

1;

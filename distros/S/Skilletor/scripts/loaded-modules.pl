#!/usr/bin/env perl
# Print the modules the skilletor CLI loads, one per line (Foo::Bar), by running the real
# commands. Run it as `perl -Ilib scripts/loaded-modules.pl` from the dist root, with
# Text::Nunjucks installed or on PERL5LIB.
# binary-pp-args.sh turns the list into pp -M options; binary-verify.sh requires every entry
# inside the packed archive. One source, so build and verify cannot drift.
# Problems go to STDERR; the list goes to STDOUT.
#
# Only strict and warnings are loaded here, both of which the CLI loads itself: a helper module
# (File::Temp, File::Find) would land in %INC and be packed for nothing. The fixture is made with
# builtins and git.
use strict;
use warnings;

# A CLI path that re-executes its program ($^X $0 hook __sync-background, say) runs this script
# with arguments: do nothing there, so the run cannot recurse.
exit 0 if @ARGV;

my $MAIN = $$;
my %mods;

# The dist's own namespace, from lib/ only: an installed older Skilletor in @INC must not add
# its stale files. Most of it is reached through use lines, but the Error classes, the Source
# backends and Skilletor::Render (which requires Text::Nunjucks on the first template) load on
# some paths only.
sub pm_under {
  my ( $root, $rel ) = @_;
  my @out;
  if ( -f "$root/$rel.pm" ) { push @out, $rel }
  if ( opendir my $dh, "$root/$rel" ) {
    for my $e ( sort grep { !/\A\./ } readdir $dh ) {
      if    ( -d "$root/$rel/$e" ) { push @out, pm_under( $root, "$rel/$e" ) }
      elsif ( $e =~ /\A(\w+)\.pm\z/ && !-d "$root/$rel/$1" ) { push @out, "$rel/$1" }
    }
  }
  my %seen;
  return grep { !$seen{$_}++ } @out;
}
-f 'lib/Skilletor.pm' or die "loaded-modules: run from the dist root\n";
$mods{ s{/}{::}gr } = 1 for pm_under( 'lib', 'Skilletor' );

# Text::Nunjucks, every module of the copy on @INC: the template engine builds its node classes
# and compiled templates by eval and loads its loaders on some paths only.
my ($tn_dir) = grep { -f "$_/Text/Nunjucks.pm" } grep { !ref } @INC;
defined $tn_dir or die "loaded-modules: Text::Nunjucks is not on \@INC (cpanm --installdeps .)\n";
$mods{ s{/}{::}gr } = 1 for pm_under( $tn_dir, 'Text/Nunjucks' );

# Loaded by name at run time, which pp's scanner cannot see:
#   IO::Socket::SSL, Net::SSLeay  HTTP::Tiny requires them on the first https:// request (a url
#                                 source); the run below reaches it only up to the connect.
#   Mozilla::CA                   IO::Socket::SSL's CA bundle when the target's OpenSSL dir has
#                                 none (default_ca falls back to it by name).
#   Win32::Process                Windows: Skilletor::Process starts the hooks' background sync
#                                 with it (spawn_detached), which only a due prompt reaches.
$mods{$_} = 1 for qw( IO::Socket::SSL Net::SSLeay Mozilla::CA );
$mods{'Win32::Process'} = 1 if $^O eq 'MSWin32';

for my $m ( sort keys %mods ) {
  eval "require $m; 1" or warn "loaded-modules: not loadable: $m (".( split /\n/, $@ )[0].")\n";
}
# What an https request loads beyond the modules themselves (the CA lookup).
HTTP::Tiny->can_ssl if HTTP::Tiny->can('can_ssl');

# The fixture: a home with Claude Code's marker and a user config over three backends (a local
# tree with a template, a git repository reached through insteadOf, an https url nobody serves),
# a project declaring an untrusted source of its own, and an empty cwd.
# Its base: the first of TMPDIR, TEMP and TMP that is a directory, else /tmp. On Windows a caller
# may set no TMPDIR (the bundle's build leg does not) and native perl cannot see Git Bash's /tmp,
# but TEMP and TMP are always set (C:\Users\...\Temp). Forward slashes there, since the fixture's
# JSON and gitconfig take the path as it is.
my ($base) = grep { defined $_ && -d $_ } @ENV{qw( TMPDIR TEMP TMP )};
$base //= '/tmp';
$base =~ tr{\\}{/} if $^O eq 'MSWin32';
my $tmp;
for my $n ( 0 .. 99 ) {
  my $try = "$base/skilletor-loaded-modules.$$.$n";
  if ( mkdir $try, 0700 ) { $tmp = $try; last }
}
defined $tmp or die "loaded-modules: cannot make a temp dir below $base: $!\n";
# local $?: the system() would otherwise set the script's exit code, a die's included.
END { local $?; system( 'rm', '-rf', '--', $tmp ) if $$ == $MAIN && defined $tmp && $tmp =~ m{/skilletor-loaded-modules\.\d+\.\d+\z} }

sub spew {
  my ( $file, $content ) = @_;
  my ( $dir, @parts ) = split m{/}, ( $file =~ s{/[^/]+\z}{}r );    # $dir: '' here, D: on Windows
  for my $part ( grep { length } @parts ) {
    $dir .= "/$part";
    mkdir $dir unless -d $dir;
  }
  open my $fh, '>:raw', $file or die "loaded-modules: $file: $!\n";
  print {$fh} $content;
  close $fh or die "loaded-modules: $file: $!\n";
}

my $home    = "$tmp/home";
my $project = "$tmp/project";
my %git_env = (
  GIT_CONFIG_GLOBAL   => "$tmp/gitconfig",
  GIT_CONFIG_NOSYSTEM => '1',
  GIT_AUTHOR_NAME     => 'loaded-modules', GIT_AUTHOR_EMAIL    => 'loaded-modules@skilletor.invalid',
  GIT_COMMITTER_NAME  => 'loaded-modules', GIT_COMMITTER_EMAIL => 'loaded-modules@skilletor.invalid',
);
my $skill = sub { "---\nname: $_[0]\ndescription: $_[1]\n---\n$_[2]\n" };
spew( "$tmp/src/skills/plain/SKILL.md", $skill->( 'plain', 'A plain skill', 'Plain.' ) );
spew( "$tmp/src/skills/plain/docs/ref.md", "Reference.\n" );
spew( "$tmp/src/skills/tpl/SKILL.md.njk",
  $skill->( 'tpl', 'Greets {{ vars.who }}', "{% if vars.flag %}Hello {{ vars.who | upper }} from {{ item.source }} ({{ harness }}, {{ scope }}).{% endif %}\n{% for x in [1, 2] %}{{ loop.index }}{% endfor %}" ) );
spew( "$tmp/src/agents/rev.md", "---\nname: rev\ndescription: Reviews\ntools: Read, Grep\nmodel: sonnet\n---\nReview.\n" );
spew( "$tmp/src/rules/style.md", "---\ndescription: Style\n---\nWrite clearly.\n" );
spew( "$tmp/src/skilletor.json", qq({\n  "vars": { "who": "world", "flag": true }\n}\n) );
spew( "$tmp/src2/skills/extra/SKILL.md", $skill->( 'extra', 'Extra', 'Extra.' ) );
spew( "$tmp/git/remote/skills/remote-skill/SKILL.md", $skill->( 'remote-skill', 'From git', 'Git.' ) );
spew( "$tmp/git/remote/bundles/pack.yaml", "description: A pack\nskills: [remote-skill]\nvars:\n  who: pack\n" );
# file:///tmp/... here, file:///D:/a/... on Windows.
my $remote_url = 'file://'.( $tmp =~ m{\A/} ? '' : '/' )."$tmp/git/remote";
my $gitconfig = qq([url "$remote_url"]\n\tinsteadOf = https://skilletor.invalid/remote.git\n);
spew( "$tmp/gitconfig", $gitconfig );
# git before 2.32 has no GIT_CONFIG_GLOBAL and reads $HOME/.gitconfig instead: the same file
# there, for the build image's git (perl:5.40-bullseye: 2.30).
spew( "$home/.gitconfig", $gitconfig );
{
  local @ENV{ keys %git_env } = values %git_env;
  for my $cmd ( [qw( init -q -b main )], [qw( add -A )], [qw( commit -q -m one )], [qw( tag v1 )] ) {
    system( 'git', '-C', "$tmp/git/remote", @$cmd ) == 0 or die "loaded-modules: git @$cmd failed\n";
  }
}
spew( "$home/.claude.json", "{}\n" );
mkdir "$tmp/cwd";

my %config = (
  user => qq({
  "sources": {
    "loc": { "local": "$tmp/src" },
    "remote": { "git": "https://skilletor.invalid/remote.git", "ref": "v1" },
    "web": { "url": "https://127.0.0.1:1/skills.tar.gz" }
  },
  "install": {
    "skills": ["*\@loc", "remote-skill\@remote", "web-skill\@web"],
    "bundles": ["pack\@remote"],
    "agents": ["rev\@loc"],
    "rules": ["style\@loc"]
  }
}
),
  targets => qq({
  "targets": ["claude", "codex", "hermes"],
  "sources": { "loc": { "local": "$tmp/src" } },
  "install": { "skills": ["*\@loc"], "agents": ["rev\@loc"], "rules": ["style\@loc"] }
}
),
  project => qq({
  "sources": { "proj": { "local": "$tmp/src2" } },
  "install": { "skills": ["extra\@proj", "plain\@loc"] }
}
),
);
my $user_config = $config{user};
sub reset_fixture {
  spew( "$home/.claude/skilletor.json", $user_config );
  spew( "$project/.claude/skilletor.json", $config{project} );
}

# Every command of the usage text, so a command ported later is run without an edit here.
require Skilletor::CLI;
my $usage = Skilletor::CLI::USAGE();
my ($block) = $usage =~ /^Commands:\n(.*?)\n\n/ms or die "loaded-modules: no Commands: block in the usage text\n";
my @commands = map { /\A  ([a-z][\w-]*(?: [a-z][\w-]*)?)(?=\s|\z)/ ? $1 : () } split /\n/, $block;
@commands >= 3 or die "loaded-modules: found only @commands in the usage text\n";
# The hook events (internal, absent from the usage text): the reference's src/hooks.ts.
my @hooks = qw( session-start user-prompt-submit cwd-changed post-tool-use __sync-background nope );

my @runs = ( [], ['help'], ['--help'], ['-h'], ['--version'], ['-v'], ['nope'], ['--nope'] );
for my $cmd (@commands) {
  my @c = split / /, $cmd;
  push @runs, map { [ @c, @$_ ] } [], ['--json'], ['--help'], ['--bogus'], [ '--scope', 'user' ], [ '--scope', 'nope' ],
    ['--project'], ['--force'], ['plain@loc'], ['tpl@loc'], ['loc'], ['proj'], ['bundle:pack@remote'], ["$tmp/src2"],
    [ '--project-dir', $project ];
}
for my $event (@hooks) {
  push @runs, [ 'hook', $event ], [ 'hook', $event, '--harness', 'codex' ];
}
push @runs, ['hook'];

my $stdin = qq({"session_id":"loaded-modules","cwd":"$project","hook_event_name":"SessionStart","source":"startup","prompt":"hi","tool_name":"Bash","tool_input":{"command":"cd $project"}}\n);
spew( "$tmp/stdin.json", $stdin );

{
  local $ENV{HOME}       = $home;
  local $ENV{CODEX_HOME} = "$home/.codex";
  local $ENV{LC_ALL}     = 'C';
  local @ENV{ keys %git_env } = values %git_env;
  local @ENV{qw( CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT SKILLETOR_PROJECT_DIR SKILLETOR_BIN HERMES_HOME
    GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE )};
  delete @ENV{qw( CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT SKILLETOR_PROJECT_DIR SKILLETOR_BIN HERMES_HOME
    GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE )};
  open my $oldout, '>&', \*STDOUT or die;
  open my $olderr, '>&', \*STDERR or die;
  open my $oldin,  '<&', \*STDIN  or die;
  my $run = sub {
    my ( $cwd, @argv ) = @_;
    reset_fixture();
    chdir $cwd or die "loaded-modules: chdir $cwd: $!\n";
    open STDIN,  '<', "$tmp/stdin.json" or die;
    open STDOUT, '>', '/dev/null' or die;
    open STDERR, '>', '/dev/null' or die;
    my $died = eval { Skilletor::CLI::run(@argv); 1 } ? undef : $@;
    open STDOUT, '>&', $oldout or die;
    open STDERR, '>&', $olderr or die;
    warn "loaded-modules: skilletor @argv died: $died" if defined $died;
  };
  for my $argv (@runs) { $run->( $project, @$argv ) }
  # A source that never resolves runs no path of its own and drops its modules from the list
  # without a word: the git source's sync must have installed its skill.
  -f "$home/.claude/skills/remote-skill/SKILL.md"
    or die "loaded-modules: the git source did not resolve (no skills/remote-skill installed)\n";
  for my $argv ( ['sync'], ['status'], ['check'] ) { $run->( "$tmp/cwd", @$argv ) }    # no project
  {
    local $ENV{CLAUDE_PROJECT_DIR} = $project;                                      # as Claude Code runs the hooks
    $run->( "$tmp/cwd", 'hook', $_ ) for @hooks;
  }
  $user_config = $config{targets};                                                  # Codex and Hermes as targets
  $run->( $project, @$_ ) for ['sync'], [ 'sync', '--json' ], ['check'], ['status'], [ 'status', '--json' ], [ 'hook', 'session-start', '--harness', 'codex' ];
  $user_config = '{ "sources": ';                                                   # a config that does not parse
  $run->( $project, @$_ ) for ['sync'], ['check'], ['status'];
  open STDIN, '<&', $oldin or die;
  chdir '/';
}

for my $file ( sort keys %INC ) {
  next unless $file =~ m{\A[\w/]+\.pm\z};
  next unless defined $INC{$file} && !ref $INC{$file} && $INC{$file} =~ m{/\Q$file\E\z};
  ( my $m = $file ) =~ s{/}{::}g;
  $m =~ s/\.pm\z//;
  print "$m\n";
}

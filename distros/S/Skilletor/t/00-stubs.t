use strict;
use warnings;
use Test::More;
use File::Find ();
use FindBin;
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use lib "$FindBin::Bin/../lib";

# The farewell release: every module that 0.008000 put on CPAN comes back, as an empty stub.
my @modules = qw(
  Skilletor
  Skilletor::AgentsMD Skilletor::Apply Skilletor::Backend Skilletor::Briefing Skilletor::Bundles
  Skilletor::CLI Skilletor::Cache Skilletor::Catalog Skilletor::ClaudeSettings Skilletor::Commands
  Skilletor::Config Skilletor::Convert Skilletor::Engine Skilletor::Entry Skilletor::Error
  Skilletor::Error::Ambiguous Skilletor::Error::Apply Skilletor::Error::Block
  Skilletor::Error::Bundle Skilletor::Error::CacheRejected Skilletor::Error::Catalog
  Skilletor::Error::Command Skilletor::Error::Config Skilletor::Error::Convert
  Skilletor::Error::Frontmatter Skilletor::Error::JSON Skilletor::Error::Lock
  Skilletor::Error::LockTimeout Skilletor::Error::Render Skilletor::Error::Source
  Skilletor::Error::Spec Skilletor::Error::TOML Skilletor::Error::Tar Skilletor::Error::Target
  Skilletor::Error::Unsupported
  Skilletor::FSUtil Skilletor::Frontmatter Skilletor::GitEnv Skilletor::Gitignore Skilletor::Gzip
  Skilletor::Hooks Skilletor::JSON Skilletor::JSON::OrderedHash Skilletor::JSString Skilletor::Lock
  Skilletor::Probe Skilletor::Process Skilletor::Render Skilletor::Render::Loader Skilletor::Report
  Skilletor::Resolver Skilletor::Role::Source Skilletor::Source::Git Skilletor::Source::Local
  Skilletor::Source::Url Skilletor::Spec Skilletor::State Skilletor::TOML Skilletor::Tar
  Skilletor::Targets Skilletor::URL
);
is( scalar @modules, 62, 'the 62 modules of 0.008000' );

my @found;
File::Find::find(
  { no_chdir => 1, wanted => sub { push @found, $File::Find::name if /\.pm\z/ } },
  "$FindBin::Bin/../lib",
);
my @packages = sort map { s{\A\Q$FindBin::Bin\E/\.\./lib/}{}r =~ s{\.pm\z}{}r =~ s{/}{::}gr } @found;
is_deeply( \@packages, [ sort @modules ], 'lib/ holds those modules and no other' );

# What a stub's package may hold: its version, the BEGIN blocks of strict and warnings, and the
# packages below it; Skilletor::CLI also its notice and run.
my %extra = ( 'Skilletor::CLI' => [qw( NOTICE run )] );
for my $module (@modules) {
  require_ok($module);
  is( $module->VERSION, '0.009000', "$module is 0.009000" );
  my %allowed = map { $_ => 1 } 'VERSION', 'BEGIN', @{ $extra{$module} || [] };
  no strict 'refs';
  my @left = sort grep { !/::\z/ && !$allowed{$_} } keys %{"${module}::"};
  is_deeply( \@left, [], "$module is empty" );
}

my $notice = do { no warnings 'once'; $Skilletor::CLI::NOTICE };
unlike( $notice, qr/\n/, 'the notice is one line' );
like( $notice, qr/\Askilletor's Perl port is retired: /, 'notice start' );
like( $notice, qr{/plugin install skilletor\@getty}, 'names the plugin' );
like( $notice, qr{install\.sh}, 'names install.sh' );
like( $notice, qr{https://github\.com/Getty/skilletor#install}, 'carries the URL' );
like( $notice, qr{cpanm --uninstall Skilletor\.\z}, 'names the uninstall' );

# Skilletor::CLI::run as a function and as a class method: its exit status and its STDERR.
sub run_cli {
  my (@args) = @_;
  my $err = '';
  open my $fh, '>', \$err or die $!;
  my $rc = do { local *STDERR = $fh; Skilletor::CLI::run(@args) };
  close $fh;
  return ( $rc, $err );
}
for my $case (
  [ 'no arguments',                [],                                    1 ],
  [ 'status',                      ['status'],                            1 ],
  [ '--version',                   ['--version'],                         1 ],
  [ 'hook not first',              [ 'status', 'hook' ],                  1 ],
  [ 'hook',                        [ 'hook', 'session-start' ],           0 ],
  [ 'a method, no arguments',      ['Skilletor::CLI'],                    1 ],
  [ 'a method, status',            [ 'Skilletor::CLI', 'status' ],        1 ],
  [ 'a method, hook',              [ 'Skilletor::CLI', 'hook', 'prompt' ], 0 ],
) {
  my ( $name, $args, $want ) = @$case;
  my ( $rc, $err ) = run_cli(@$args);
  is( $rc,  $want,        "run: $name returns $want" );
  is( $err, "$notice\n", "run: $name prints the notice" );
}

# The program, as the plugins and a shell run it.
sub run_script {
  my (@args) = @_;
  my $pid = open3( my $in, my $out, my $err = gensym, $^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../script/skilletor", @args );
  close $in;
  my $stdout = do { local $/; <$out> };
  my $stderr = do { local $/; <$err> };
  waitpid $pid, 0;
  return ( $? >> 8, $stdout, $stderr );
}
for my $case ( [ ['status'], 1 ], [ [], 1 ], [ [ 'hook', 'session-start' ], 0 ] ) {
  my ( $args, $want ) = @$case;
  my $name = join( ' ', 'skilletor', @$args );
  my ( $code, $stdout, $stderr ) = run_script(@$args);
  is( $code,   $want, "$name exits $want" );
  is( $stdout, '',    "$name prints nothing on stdout" );
  like( $stderr, qr/\A\Q$notice\E\r?\n\z/, "$name prints the notice on stderr" );
}

done_testing;

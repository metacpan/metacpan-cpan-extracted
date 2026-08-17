#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use File::Spec ();
use Test::More;
use Punk::Generate;

# `punk generate controller|model` into an existing application - the
# add-to-it half `punk new` never had. Driven through bin/punk as a
# subprocess (the t/27 shape): generate reads the class from app.psgi
# without executing anything, so each run is independent.

my $PUNK = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'punk');
plan skip_all => 'bin/punk is missing' unless -f $PUNK;

my @INCARGS = map { "-I$_" } @INC;
sub punk {
    my ($dir, @args) = @_;
    my $cmd = join ' ', map { quotemeta } $^X, @INCARGS, $PUNK, @args;
    my $out = qx{cd @{[quotemeta $dir]} && $cmd 2>&1};
    return ($? >> 8, $out);
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
Punk::Generate->new(name => 'GenInto', dir => $dir)->run;

# ---- a controller --------------------------------------------------------------

{
    my ($rc, $out) = punk($dir, 'generate', 'controller', 'Widget');
    is($rc, 0, 'generate controller exits 0');
    like($out, qr{^wrote lib/GenInto/Controller/Web/Widget\.pm$}m,
        'and says what it wrote');
    my $file = "$dir/lib/GenInto/Controller/Web/Widget.pm";
    ok(-f $file, 'the file exists');
    my $src = do { local (@ARGV, $/) = $file; <> };
    like($src, qr/^package GenInto::Controller::Web::Widget;$/m,
        'the package is the app class plus the name');
    like($src, qr/Web::Widget#index/, 'the wiring comment names the target');
    unlike($src, qr/\{%/, 'no unrendered template syntax');
    is(system($^X, @INCARGS, '-c', $file) >> 8, 0, 'and it compiles');
}
{
    my ($rc, $out) = punk($dir, 'generate', 'controller', 'Widget');
    is($rc, 1, 'an existing file is refused');
    like($out, qr/already exists/, 'and named');
    my ($rc2) = punk($dir, 'generate', 'controller', 'Widget', '--force');
    is($rc2, 0, '--force overwrites');
}
{
    my ($rc, $out) = punk($dir, 'generate', 'controller', 'Stats', '--api');
    is($rc, 0, 'an API controller generates');
    my $src = do { local (@ARGV, $/)
        = "$dir/lib/GenInto/Controller/API/Stats.pm"; <> };
    like($src, qr/^package GenInto::Controller::API::Stats;$/m,
        'under Controller::API');
    like($src, qr/\$c->json\(/, 'answering JSON');
}
{
    my ($rc, $out) = punk($dir, 'generate', 'controller', 'Admin::Report');
    is($rc, 0, 'a nested name generates');
    ok(-f "$dir/lib/GenInto/Controller/Web/Admin/Report.pm",
        'in its nested path');
}

# ---- a model -------------------------------------------------------------------

{
    my ($rc, $out) = punk($dir, 'generate', 'model', 'Widget',
                          '--table', 'gadgets');
    is($rc, 0, 'generate model exits 0');
    my $src = do { local (@ARGV, $/) = "$dir/lib/GenInto/Model/Widget.pm"; <> };
    like($src, qr/^package GenInto::Model::Widget;$/m, 'the package');
    like($src, qr/^table 'gadgets';$/m, '--table is honoured');
    like($src, qr/^use Punk::Model;$/m, 'and it is a Punk::Model');
    is(system($^X, @INCARGS, '-c', "$dir/lib/GenInto/Model/Widget.pm") >> 8, 0,
        'and it compiles');
}
{
    my ($rc, $out) = punk($dir, 'generate', 'model', 'Signup');
    is($rc, 0, 'the table defaults');
    my $src = do { local (@ARGV, $/) = "$dir/lib/GenInto/Model/Signup.pm"; <> };
    like($src, qr/^table 'signups';$/m, 'to the lowercased name, pluralised');
}

# ---- misuse --------------------------------------------------------------------

{
    my ($rc, $out) = punk($dir, 'generate', 'controller');
    is($rc, 2, 'no name is a usage error');
    like($out, qr/a controller name is required/, 'and says so');
}
{
    my ($rc, $out) = punk($dir, 'generate', 'controller', 'not-a-package');
    is($rc, 2, 'a bad name is a usage error');
    like($out, qr/is not a valid package name/, 'and says why');
}
{
    my $empty = File::Temp::tempdir(CLEANUP => 1);
    my ($rc, $out) = punk($empty, 'generate', 'controller', 'X');
    is($rc, 1, 'outside an application it fails');
    like($out, qr/no application found/, 'naming the problem');
}

# ---- the application still boots -----------------------------------------------

{
    # the t/26 child pattern: the generated class, its chdir and its config
    # cannot leak into this process
    my $script = <<"EOS";
\$0 = "$dir/app.psgi";
my \$app = do "$dir/app.psgi";
die "no app: \$\@" unless ref \$app eq 'CODE';
require GenInto::Controller::Web::Widget;
require GenInto::Model::Widget;
open my \$in, '<', \\'';
my \$res = \$app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/',
                     QUERY_STRING => '', SERVER_NAME => 'l',
                     SERVER_PORT => 80, HTTP_HOST => 'l',
                     'psgi.url_scheme' => 'http', 'psgi.input' => \$in });
print "status=\$res->[0]\\n";
EOS
    my $cmd = join ' ', map { quotemeta } $^X, @INCARGS, '-e', $script;
    my $out = qx{$cmd 2>&1};
    like($out, qr/^status=200$/m,
        'the app boots and serves with the generated files in the tree');
}

done_testing;

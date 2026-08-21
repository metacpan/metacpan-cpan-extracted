#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Cwd ();
use Punk ();

# Punk.pm's SYNOPSIS, executed.
#
# It opened with `plugin 'RequestId';` for the whole life of the distribution
# and that line croaked: "Can't locate Punk/Plugin/RequestId.pm in @INC". The
# first thing the framework told a new reader to do was the first thing that
# failed, and nothing noticed because nothing ran it.
#
# So this test does not paraphrase the SYNOPSIS - it READS it out of the POD
# and evals it. A copy would drift; this cannot. If somebody edits the
# SYNOPSIS into something that does not run, this fails.

my $punk_pm = $INC{'Punk.pm'} or plan skip_all => 'cannot locate Punk.pm';

my $synopsis = do {
    open my $fh, '<', $punk_pm or plan skip_all => "cannot read $punk_pm: $!";
    local $/;
    my $pod = <$fh>;
    close $fh;
    $pod =~ /^=head1 SYNOPSIS\s*\n(.*?)^=head1 /ms
        or plan skip_all => 'no SYNOPSIS in Punk.pm';
    $1;
};

# The verbatim block, dedented. Anything not indented is prose.
my @code = map  { my $l = $_; $l =~ s/\A    //; $l }
           grep { /\A(?:    |\s*\z)/ }
           split /\n/, $synopsis;
my $code = join "\n", @code;

like($code, qr/\bplugin 'RequestId'/,
    "the SYNOPSIS still opens with plugin 'RequestId' - if this ever stops "
  . 'being true the rest of this file is testing something else');

# The `# app.psgi` half is a second file, not a continuation of the first.
my ($app_code, $psgi_code) = split /^\s*#\s*app\.psgi\s*$/m, $code, 2;
ok(defined $psgi_code, 'the SYNOPSIS shows an app.psgi section');

# The SYNOPSIS names controllers and a static directory. Provide both, then
# run its code exactly as written.
#
# `Web::Book#home` resolves to MyApp::Controller::Web::Book - the controller
# namespace is relative to the application class, which is the convention
# `punk new` generates into and the SYNOPSIS is written against.
{
    package MyApp::Controller::Web::Book;
    sub home       { $_[0]->text('home') }
    sub view       { $_[0]->text('view ' . $_[0]->param('id')) }
    sub create     { $_[0]->text('created') }
    sub admin_list { $_[0]->text('admin list') }
}

my $tmp = File::Temp::tempdir(CLEANUP => 1);
mkdir "$tmp/root";
mkdir "$tmp/root/static";
open my $sfh, '>', "$tmp/root/static/f.txt" or die $!;
print $sfh 'a static file';
close $sfh;

my $cwd = Cwd::getcwd();
chdir $tmp or die "chdir: $!";

my $ok = eval "$app_code\n1";
my $err = $@;
chdir $cwd or die "chdir back: $!";

ok($ok, 'the SYNOPSIS compiles and runs, verbatim from the POD') or diag $err;

SKIP: {
    skip 'the SYNOPSIS did not compile', 6 unless $ok;

    chdir $tmp or die "chdir: $!";
    my $app = eval { MyApp->to_app };
    my $terr = $@;
    chdir $cwd or die "chdir back: $!";

    ok($app, 'MyApp->to_app, which is what the app.psgi half does') or diag $terr;
    skip 'no app', 5 unless $app;

    my $req = sub {
        my ($method, $path, %extra) = @_;
        return $app->({
            REQUEST_METHOD => $method,
            PATH_INFO      => $path,
            QUERY_STRING   => '',
            'psgi.input'   => undef,
            'psgi.errors'  => \*STDERR,
            %extra,
        });
    };

    is($req->('GET', '/')->[2][0], 'home', "the SYNOPSIS's first route serves");
    is($req->('GET', '/books/7')->[2][0], 'view 7',
        'and its placeholder route captures');
    is($req->('POST', '/books')->[2][0], 'created', 'and its post route');

    # the `under` scope, with and without the header its guard checks
    is($req->('GET', '/admin/books')->[0], 302,
        "the SYNOPSIS's under-scope guard redirects without authorization");
    is($req->('GET', '/admin/books', HTTP_AUTHORIZATION => 'Bearer x')->[2][0],
        'admin list', 'and passes with it');

    # and the thing this whole plan was about
    my %h = @{ $req->('GET', '/')->[1] };
    like($h{'X-Request-Id'}, qr/\A[0-9a-f]{32}\z/,
        'every response carries an id, because line five of the SYNOPSIS '
      . 'asked for one and it now exists');
}

done_testing;

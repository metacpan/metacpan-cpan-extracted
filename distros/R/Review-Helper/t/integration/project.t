# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cpanel::JSON::XS();
use File::Temp qw/tempdir/;
use TestRepo qw/make_repo commit_file write_file/;
use TestCLI qw/cli/;
use Review::Helper::DB;
use Review::Helper::VCS;

# A project review: the Perl side of a small codebase, squashed from the
# empty revision, filled, then iterated after more work lands.

my $JSON = Cpanel::JSON::XS->new->canonical->utf8;
my $tmp  = tempdir(CLEANUP => 1);
my $dir  = make_repo();

my $APP = <<'EOT';
package App;
use v5.36;

sub run($class, @args) {
    return App::Util->clean(@args);
}

1;
EOT

my $UTIL = <<'EOT';
package App::Util;
use v5.36;

sub clean($class, @args) {
    return grep { $_ } @args;
}

1;
EOT

commit_file($dir, 'Start', 'lib/App.pm' => $APP, 'js/app.js' => "export const x = 1;\n");
my $head = commit_file($dir, 'Add Util', 'lib/App/Util.pm' => $UTIL, 't/app.t' => "use Test2::V0;\nok(1);\ndone_testing;\n", 'js/app.js' => "export const x = 2;\n");

my ($exit, $out, $err) = cli($dir, qw{note --flag red --kind note --path lib/App/Util.pm --unit clean --sentence}, 'Drops false values too?');
my $note = $out =~ s/\n//r;

($exit, $out, $err) = cli($dir, qw{build --squash --path lib --path t --title}, 'Perl side');
is([$exit, $err], [0, ''], 'build succeeds') or diag $err;
my $file = $out =~ s/\n//r;
my $dbh  = Review::Helper::DB->open($file)->dbh;

is(
    $dbh->selectrow_hashref('SELECT base, head, squashed, paths FROM iteration'),
    {base => Review::Helper::VCS->detect($dir)->empty_revision, head => $head, squashed => 1, paths => '["lib","t"]'},
    'squashed from the empty revision, limited to the Perl paths',
);
is($dbh->selectall_arrayref('SELECT revision, parent, subject FROM commit_entry'), [[$head, undef, 'Add Util']], 'one entry at the head');
is($dbh->selectall_arrayref('SELECT path, status FROM file_change ORDER BY path'), [['lib/App.pm', 'A'], ['lib/App/Util.pm', 'A'], ['t/app.t', 'A']], 'no JavaScript');

subtest 'page diff spans the whole squash' => sub {
    require Plack::Test;
    require HTTP::Request::Common;
    require Review::Helper::Server;
    my $app  = Review::Helper::Server->new(db_path => $file)->to_app;
    my $test = Plack::Test->create($app);
    my ($id) = $dbh->selectrow_array(q{SELECT id FROM file_change WHERE path = 'lib/App.pm'});
    my $req  = HTTP::Request::Common::GET("http://127.0.0.1/api/diff/$id");
    my $diff = $JSON->decode($test->request($req)->content);
    my @add  = map { $_->{text} } grep { $_->{type} eq '+' } map { @{$_->{lines}} } @{$diff->{hunks}};
    ok((grep { m/package App;/ } @add), 'a file from the first commit shows as added against the empty revision');
};

sub get_sheet() {
    my ($exit, $out, $err) = cli($dir, 'sheet', $file);
    is($exit, 0, 'sheet succeeds') or diag $err;
    return $JSON->decode($out);
}

sub fill_sheet($data) {
    write_file($tmp, 'sheet.json', $JSON->encode($data));
    return cli($dir, 'fill', $file, "$tmp/sheet.json");
}

my $sheet = get_sheet();
my %types;
$types{$_->{type}}{$_->{optional} ? 'optional' : 'required'}++ for @{$sheet->{items}};
is($types{split},  {optional => T()}, 'splits are optional');
is($types{topics}, {required => 1},   'the topics are asked for');
ok(!$types{section}, 'no sections before a split');
is($types{note}, {optional => 1}, 'the note is optional');

# Topics first, alone: they replace the one entry the build made.
my ($topics) = grep { $_->{type} eq 'topics' } @{$sheet->{items}};
is($topics->{about}, {paths => ['lib/App.pm', 'lib/App/Util.pm', 't/app.t'], unassigned => ['lib/App.pm', 'lib/App/Util.pm', 't/app.t']}, 'every path, none in a topic yet');
$topics->{fields} = {topics => [{name => 'Perl modules', paths => ['lib/App.pm', 'lib/App/Util.pm']}, {name => 'Tests', paths => ['t/app.t']}]};
my ($commit_item) = grep { $_->{type} eq 'commit' } @{$sheet->{items}};
$commit_item->{fields} = {what => 'W', why => 'Y', how => 'H'};
($exit, $out, $err) = fill_sheet({%$sheet, items => [$topics, $commit_item]});
like($err, qr/commit:\d+: the topics change in this sheet; fill this item from the next sheet/, 'an entry is not explained in the sheet that splits it');
($exit, $out, $err) = fill_sheet({%$sheet, items => [$topics]});
is($exit, 0, 'topics filled') or diag $err;
is(
    $dbh->selectall_arrayref('SELECT c.position, c.topic, c.revision, f.path FROM commit_entry c JOIN file_change f ON f.commit_id = c.id ORDER BY c.position, f.path'),
    [[1, 'Perl modules', $head, 'lib/App.pm'], [1, 'Perl modules', $head, 'lib/App/Util.pm'], [2, 'Tests', $head, 't/app.t']],
    'one entry per topic, each at the head with its files',
);

$sheet = get_sheet();
my %by_topic = map { ($_->{about}->{topic} => $_) } grep { $_->{type} eq 'commit' } @{$sheet->{items}};
is([sort keys %by_topic], ['Perl modules', 'Tests'], 'a commit item per topic');
my %fill = (
    summary => sub ($about) { +{what   => 'A tiny app.',          why => 'Example.',      how => 'One class calls a helper.'} },
    commit  => sub ($about) { +{what   => "The $about->{topic}.", why => 'Final review.', how => 'Squashed.'} },
    order   => sub ($about) { +{paths  => [sort @{$about->{paths}}]} },
    file    => sub ($about) { +{what   => 'Its purpose.'} },
    note    => sub ($about) { +{commit => $head, path => 'lib/App/Util.pm', lines => [4, 6]} },
    guide   => sub ($about) {
        +{
            steps => [
                {target => {type => 'summary'}, commentary => 'A tiny app in two modules.'},
                {target => {type => 'commit', commit => $head, topic => 'Tests'}, commentary => 'The tests come last.'},
                {target => {type => 'view',   commit => $head, path  => 'lib/App.pm', lines => [1, 8]}, highlight => [{path => 'lib/App.pm', side => 'new', lines => [4, 6]}], commentary => 'The run method is the entry point.'},
                {target => {type => 'flag',   flag   => $note}, commentary => 'Check whether false values should stay.'},
            ],
        };
    },
);
for my $item (@{$sheet->{items}}) {
    my $fields = ($fill{$item->{type}} // next)->($item->{about});
    $item->{fields} = {%{$item->{fields}}, %$fields};
}

($exit, $out, $err) = fill_sheet($sheet);
is([$exit, $out, $err], [0, "filled 10, remaining 0\n", ''], 'everything required filled; splits left out') or diag $err;
is(
    $dbh->selectall_arrayref('SELECT c.topic, f.path, f.line_start, f.line_end FROM flag f JOIN commit_entry c ON c.id = f.commit_id'),
    [['Perl modules', 'lib/App/Util.pm', 4, 6]],
    'note placed at the head, in the topic holding its path',
);
is($dbh->selectrow_array('SELECT COUNT(*) FROM guide_step'),                                      4,                                                     'guide stored');
is($JSON->decode(($dbh->selectrow_array('SELECT target FROM guide_step WHERE position = 2'))[0]), {type => 'commit', commit => $head, topic => 'Tests'}, 'a guide step names its topic');

my $later = commit_file($dir, 'Keep false values', 'lib/App/Util.pm' => $UTIL =~ s/\{ \$_ \}/{ defined }/r, 'lib/App/More.pm' => "package App::More;\n1;\n", 'js/app.js' => "export const x = 3;\n");
($exit, $out, $err) = cli($dir, 'iterate', $file);
is([$exit, $out, $err],                                                                           [0, "2\n", ''],                                                                                                     'iterate');
is($dbh->selectrow_hashref('SELECT base, head, squashed, paths FROM iteration WHERE number = 2'), {base => Review::Helper::VCS->detect($dir)->empty_revision, head => $later, squashed => 1, paths => '["lib","t"]'}, 'same squash and paths');
is(
    $dbh->selectall_arrayref('SELECT c.position, c.topic, c.what, f.path FROM commit_entry c JOIN file_change f ON f.commit_id = c.id WHERE c.iteration = 2 ORDER BY c.position, f.path'),
    [[1, 'Perl modules', undef, 'lib/App.pm'], [1, 'Perl modules', undef, 'lib/App/Util.pm'], [2, 'Tests', 'The Tests.', 't/app.t'], [3, undef, undef, 'lib/App/More.pm']],
    'files keep their topic; a topic whose files all read the same keeps its text; a new file waits in no topic',
);
is(
    $dbh->selectall_arrayref('SELECT c.topic, f.line_start, f.line_end, f.pending FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2'),
    [['Perl modules', 4, 6, 1]],
    'the flag carries with its topic; the line under it changed, so it is pending',
);

$sheet = get_sheet();
($topics) = grep { $_->{type} eq 'topics' } @{$sheet->{items}};
is([$topics->{about}->{unassigned}, $topics->{fields}->{topics}], [['lib/App/More.pm'], [{name => 'Perl modules', paths => ['lib/App.pm', 'lib/App/Util.pm']}, {name => 'Tests', paths => ['t/app.t']}]], 'the new file is asked for');
my ($summary) = grep { $_->{type} eq 'summary' } @{$sheet->{items}};
is($summary->{fields}, {what => undef, why => undef, how => undef, note => undef}, 'the summary asks what the iteration changed');
$summary->{fields} = {what => 'A tiny app.', why => 'Example.', how => 'Same.', note => 'Kept false values.'};
push @{$topics->{fields}->{topics}->[0]->{paths}} => 'lib/App/More.pm';
($exit, $out, $err) = fill_sheet({%$sheet, items => [$summary, $topics]});
is($exit,                                                                                            0,                         'summary and topics filled') or diag $err;
is($dbh->selectrow_array('SELECT note FROM iteration WHERE number = 2'),                             'Kept false values.',      'iteration note stored');
is($dbh->selectcol_arrayref('SELECT topic FROM commit_entry WHERE iteration = 2 ORDER BY position'), ['Perl modules', 'Tests'], 'every file in a topic again');

# The pending flag needs the agent's decision.
$sheet = get_sheet();
my ($flag) = grep { $_->{type} eq 'flag' } @{$sheet->{items}};
ok($flag && !$flag->{optional}, 'the pending flag is asked for');
is($flag->{about}->{previous}, {commit => $head, path => 'lib/App/Util.pm', lines => [4, 6]}, 'with where it was');
$flag->{fields} = {decision => 'recolor', color => 'yellow', reason => 'False values are kept now.'};
($exit, $out, $err) = fill_sheet({%$sheet, items => [$flag]});
is($exit, 0, 'flag recolored') or diag $err;
is(
    $dbh->selectrow_hashref('SELECT f.color, f.color_reason, f.pending FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2'),
    {color => 'yellow', color_reason => 'False values are kept now.', pending => 0},
    'yellow now, with its reason; no longer pending',
);
ok(!grep({ $_->{type} eq 'flag' } @{get_sheet()->{items}}), 'nothing left to decide');

done_testing;

# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo/;
use TestCLI qw/cli/;
use Review::Helper::VCS;
use Review::Helper::Journal;

my $dir     = make_repo();
my $journal = Review::Helper::Journal->new(repo => Review::Helper::VCS->detect($dir));
my @note    = (qw{--flag red --kind note --path lib/Foo.pm --sentence}, 'Looks wrong.');

subtest record => sub {
    my ($exit, $out, $err) = cli($dir, 'note', @note, '--unit', 'bar', '--detail=More.');
    is([$exit, $err], [0, ''], 'succeeds');
    like($out, qr/^[0-9a-f-]{36}\n\z/, 'prints the id');

    chomp(my $id = $out);
    is(
        $journal->notes,
        [{
            id       => $id,
            created  => match qr/^\d+$/,
            flag     => 'red',
            kind     => 'note',
            path     => 'lib/Foo.pm',
            unit     => 'bar',
            snippet  => undef,
            sentence => 'Looks wrong.',
            detail   => 'More.',
        }],
        'journal note written',
    );
};

subtest non_ascii => sub {
    # Arguments arrive as the UTF-8 bytes a shell passes.
    my ($exit, $out, $err) = cli($dir, 'note', qw{--path}, "lib/caf\xc3\xa9.pm", '--sentence', "Caf\xc3\xa9 \xe2\x9c\x93");
    is([$exit, $err], [0, ''], 'succeeds');
    chomp(my $id = $out);

    my ($note) = grep { $_->{id} eq $id } @{$journal->notes};
    is([@{$note}{qw/path sentence kind flag/}], ["lib/caf\x{e9}.pm", "Caf\x{e9} \x{2713}", 'other', undef], 'stored as the text given, kind other by default, a journal entry without --flag');

    open(my $fh, '<:raw', $journal->path) or die $!;
    my $raw = do { local $/; <$fh> };
    like($raw, qr/"sentence":"Caf\xc3\xa9 \xe2\x9c\x93"/, 'the journal holds the UTF-8 encoding once');

    ($exit, $out, $err) = cli($dir, 'note', @note[0 .. 5], '--sentence', "caf\xe9");
    is([$exit, $err], [1, "review-helper note: The value of --sentence is not valid UTF-8\n"], 'text that is not UTF-8 is refused');

    $journal->remove($id);
};

subtest errors => sub {
    my ($exit, $out, $err) = cli($dir, 'note', @note[0 .. 5]);
    is($exit, 1, 'missing sentence fails');
    like($err, qr/^review-helper note: Note field 'sentence' is required/, 'reported');

    (undef, undef, $err) = cli($dir, 'note', @note, '--flag', 'green');
    like($err, qr/flag must be one of: yellow red/, 'color validated');

    (undef, undef, $err) = cli($dir, 'note', @note, '--kind', 'guess');
    like($err, qr/kind must be one of:/, 'kind validated');

    (undef, undef, $err) = cli($dir, 'note', @note, '--severity', '3');
    is($err, "review-helper note: '--severity' is not a valid option.\n", 'unknown option');

    (undef, undef, $err) = cli($dir, 'note', @note, 'extra');
    like($err, qr/Unexpected arguments: extra/, 'positional arguments refused');

    is(scalar(@{$journal->notes}), 1, 'nothing recorded on error');
};

done_testing;

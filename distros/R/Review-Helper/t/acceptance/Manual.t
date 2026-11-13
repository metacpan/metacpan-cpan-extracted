# Test origin: AI
use v5.36;
use Test2::V0;

use Pod::Checker ();

use Review::Helper::CLI;
use Review::Helper::Manual;
use Review::Helper::Util qw/share_dir/;

sub slurp ($file) {
    open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open $file: $!";
    local $/;
    return scalar <$fh>;
}

my $manual_file = $INC{'Review/Helper/Manual.pm'};
my $manual      = slurp($manual_file);

subtest 'pod is clean' => sub {
    my $out = '';
    open(my $fh, '>', \$out) or die "Could not open string handle: $!";
    my $checker = Pod::Checker->new(-warnings => 1);
    $checker->parse_from_file($manual_file, $fh);

    is($checker->num_errors,   0, 'no pod errors')   or diag $out;
    is($checker->num_warnings, 0, 'no pod warnings') or diag $out;
};

subtest 'sections' => sub {
    my @heads = $manual =~ m/^=head1 (.+)$/mg;
    is(
        \@heads,
        [
            'NAME',
            'EARLY VERSION',
            'DESCRIPTION',
            'QUICK START',
            'REVIEWING IN THE BROWSER',
            'WORKING WITH AN AGENT',
            'INTEGRATING WITH A PROJECT',
            "REVIEWING SOMEONE ELSE'S PULL REQUEST",
            'REVIEWING A WHOLE PROJECT',
            'COMMANDS',
            'THE REVIEW FILE FORMAT',
            'SOURCE',
            'MAINTAINERS',
            'AUTHORS',
            'COPYRIGHT',
        ],
        'expected top-level sections, in order',
    );
};

subtest 'every subcommand is documented' => sub {
    my $cli = slurp($INC{'Review/Helper/CLI.pm'});
    my ($table) = $cli =~ m/^my %COMMANDS = \((.*?)^\);/ms;
    ok($table, 'found the dispatch table') or return;

    my @commands = $table =~ m/^\s*'?([\w-]+)'?\s*=>/mg;
    ok(scalar(@commands), 'dispatch table lists subcommands');

    my ($section) = $manual =~ m/^=head1 COMMANDS$(.*?)^=head1 /ms;
    for my $command (@commands) {
        like($section, qr/^=item review-helper \Q$command\E\b/m, "'$command' has an entry under COMMANDS");
    }
};

subtest "every command's options are documented" => sub {
    my $cli     = slurp($INC{'Review/Helper/CLI.pm'});
    my ($table) = $cli =~ m/^my %COMMANDS = \((.*?)^\);/ms;
    my %classes = $table =~ m/^\s*'?([\w-]+)'?\s*=>\s*'([\w:]+)'/mg;
    ok(scalar(keys %classes), 'found the command classes') or return;

    my ($section) = $manual =~ m/^=head1 COMMANDS$(.*?)^=head1 /ms;
    for my $command (sort keys %classes) {
        require(($classes{$command} =~ s{::}{/}gr) . '.pm');
        my @options = map { $_->name } @{$classes{$command}->options->options};
        my @usages  = $section =~ m/^=item (review-helper \Q$command\E\b.*)$/mg;

        # `review-helper FILE` runs serve, so it lists serve's options too.
        push @usages => ($section =~ m/^=item (review-helper FILE\b.*)$/m)[0] // '' if $command eq 'serve';

        for my $usage (@usages) {
            my ($entry) = $usage =~ m/\Areview-helper ([\w-]+(?: [a-z][\w-]*)?)/;
            for my $option (@options) {
                like($usage, qr/--\Q$option\E(?![\w-])/, "'--$option' is in the 'review-helper $entry' entry under COMMANDS");
            }
            my %known = map { ($_ => 1) } @options;
            for my $option ($usage =~ m/--([\w-]+)/g) {
                ok($known{$option}, "'--$option' in the 'review-helper $entry' entry is an option it takes");
            }
        }
    }
};

subtest 'every skill is documented' => sub {
    my @skills = sort map { m{([^/]+)/SKILL\.md\z} } glob(share_dir() . '/skills/*/SKILL.md');
    ok(scalar(@skills), 'found shipped skills');

    my ($section) = $manual =~ m/^=head1 WORKING WITH AN AGENT$(.*?)^=head1 /ms;
    for my $skill (@skills) {
        like($section, qr/^=item \Q$skill\E$/m, "'$skill' has an entry under WORKING WITH AN AGENT");
    }
};

done_testing;

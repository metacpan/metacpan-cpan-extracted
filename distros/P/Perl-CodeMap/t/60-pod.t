use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use Pod::Simple::Checker;

my $root = File::Spec->catdir($FindBin::RealBin, '..');
my $cli = File::Spec->catfile($root, 'bin', 'perl-codemap');
my $module = File::Spec->catfile($root, 'lib', 'Perl', 'CodeMap.pm');

sub file_text {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot read $file: $!";
    local $/;
    return <$fh>;
}

for my $file ($cli, $module) {
    my $checker = Pod::Simple::Checker->new;
    $checker->parse_file($file);
    ok(!$checker->any_errata_seen, "valid POD syntax: $file");
}

my $cli_pod = file_text($cli);
for my $heading (qw(NAME SYNOPSIS DESCRIPTION INSTALLATION OPTIONS EXAMPLES
                    LIMITATIONS SECURITY)) {
    like($cli_pod, qr/^=head1 \Q$heading\E(?: AND PRIVACY)?\s*$/m,
        "CLI documents $heading");
}
for my $flag (qw(root output json from-json parser embed-source no-embed-source
                 max-source-bytes include-tests source-base name version help man)) {
    like($cli_pod, qr/^=item[^\n]*\Q--$flag\E(?:[>,\s]|$)/m,
        "CLI documents --$flag");
}
my $module_pod = file_text($module);
for my $method (qw(new analyze hydrate_sources write_report)) {
    like($module_pod, qr/^=head2 \Q$method\E\s*$/m,
        "public module API documents $method");
}
for my $section ('ANALYSIS DATA FORMAT', 'ERROR HANDLING',
                 'SECURITY AND PRIVACY', 'SEE ALSO', 'AUTHOR') {
    like($module_pod, qr/^=head1 \Q$section\E\s*$/m,
        "module documents $section");
}

my $help = qx{"$^X" "$cli" --help};
is($? >> 8, 0, '--help exits successfully');
like($help, qr/--from-json/, '--help contains CLI option reference');
like($help, qr/--man/, '--help advertises full manual');
my $man = qx{"$^X" "$cli" --man};
is($? >> 8, 0, '--man exits successfully');
like($man, qr/EXIT STATUS/, '--man renders full exit status reference');
like($man, qr/SECURITY AND PRIVACY/, '--man renders security warning');
like($man, qr/Scott Muller/, '--man renders author information');

done_testing;

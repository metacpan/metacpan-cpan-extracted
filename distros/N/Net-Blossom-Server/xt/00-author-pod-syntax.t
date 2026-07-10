use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

eval 'use Test::Pod 1.52; 1'
    or plan skip_all => 'Test::Pod 1.52 is required for author tests';
eval 'use Pod::Checker qw(podchecker); 1'
    or plan skip_all => 'Pod::Checker is required for author tests';

my @files = sort { $a cmp $b } all_pod_files("$FindBin::Bin/../lib");

pod_file_ok($_) for @files;

for my $file (grep { _has_pod($_) } @files) {
    open my $output, '>', \my $diagnostics
        or die "Unable to open scalar output: $!";
    my $errors = podchecker($file, $output, -warnings => 1);
    close $output;

    ok(!$errors, "$file podchecker");
    diag $diagnostics if $errors;
}

my @bad_code_spans = _bad_single_angle_code_spans(@files);
ok(!@bad_code_spans, 'no raw => inside single-angle C<> POD spans');
diag join "\n", @bad_code_spans if @bad_code_spans;

done_testing;

sub _has_pod {
    my ($file) = @_;

    open my $fh, '<', $file
        or die "Unable to read $file: $!";
    while (my $line = <$fh>) {
        return 1 if $line =~ /^=\w/;
    }

    return 0;
}

sub _bad_single_angle_code_spans {
    my @files = @_;
    my @bad;

    for my $file (@files) {
        open my $fh, '<', $file
            or die "Unable to read $file: $!";
        while (my $line = <$fh>) {
            next unless $line =~ /C<(?!<)[^>\n]*=>/;
            push @bad, "$file:$.: use C<< ... >> or E<gt> for => inside POD code spans";
        }
    }

    return @bad;
}

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use lib "$FindBin::RealBin/../lib";
use Perl::CodeMap;

my $root = File::Spec->catdir($FindBin::RealBin, '..');
sub read_file {
    my ($relative) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '<', $path or die "Cannot read $relative: $!";
    local $/;
    return <$fh>;
}

is($Perl::CodeMap::VERSION, '0.3.2', 'maintenance release version');
like(read_file('Makefile.PL'), qr/AUTHOR\s*=>\s*'Scott Muller <scott\@21h\.io>'/,
    'CPAN distribution lists Scott Muller and email');
like(read_file('LICENSE'), qr/Copyright \(c\) 2026 Scott Muller/,
    'project MIT copyright is correctly attributed');
like(read_file('lib/Perl/CodeMap.pm'),
    qr/=head1 AUTHOR\s+Scott Muller <scott\@21h\.io>/,
    'module POD includes author and email');
like(read_file('SECURITY.md'), qr/Scott Muller <scott\@21h\.io>/,
    'security contact is named');
like(read_file('AUTHORS.md'), qr/Scott Muller.*scott\@21h\.io/s,
    'project authors file lists maintainer');
like(read_file('README.md'), qr/Scott Muller.*scott\@21h\.io/s,
    'README lists maintainer');
like(read_file('NOTICE.md'), qr/Peter Retief.*PrismJS/s,
    'original upstream and bundled Prism receive attribution');
unlike(read_file('Makefile.PL'), qr/Perl CodeMap contributors/,
    'distribution author is not anonymous');
done_testing;

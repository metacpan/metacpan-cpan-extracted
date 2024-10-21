#!perl

use warnings;
use strict;
use 5.010;

use lib 't/tlib';

use File::Find;
use Test::More;

plan 'no_plan';

my $last_version;
find({wanted => \&_check_version, no_chdir => 1}, 'blib');
if (! defined $last_version) {
    fail('Failed to find any files with $VERSION');
}

exit 0;


sub _check_version {
    return if (! m{blib/script/} && ! m{\.pm\z});

    local $/ = undef;
    my $fh;
    open $fh, '<', $_ or die $!;
    my $content = <$fh>;
    close $fh;

    # Skip POD
    $content =~ s/^__END__.*//xms;

    # Only look at perl scripts, not sh scripts.
    return if (m{blib/script/} && $content !~ m/\A \#![^\r\n]+?perl/xms);

    my @version_lines = $content =~ m/ ( [^\n]* \$VERSION [^\n]* ) /gxms;
    # Special cases for printing/documenting version numbers
    @version_lines = grep {! m/(?:\\|\"|\'|C<|v)\$VERSION/xms} @version_lines;
    @version_lines = grep {! m/^\s*\#/xms} @version_lines;

    ok( scalar @version_lines, 'Got at least one version line' );
    for my $line (@version_lines) {
        if (!defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        }
        else {
            is($line, $last_version, $_);
        }
    }

    return;
}

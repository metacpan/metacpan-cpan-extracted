use strict;
use warnings;

use Test::More;

use Pod::POM;
use Pod::POM::View::XML;

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::XML';

my @snippets  = <t/snippets/*.sample>;

plan tests => scalar @snippets;

test_snippet($_) for @snippets;

sub test_snippet {
    my $file = shift;
    ( my $testname = $file ) =~ s#.*/([^.]+).*#$1#;

    open my $fh, '<', $file;
    local $/ = "---\n";
    my( $pod, $xml ) = <$fh>;

    $pod =~ s/^---.*//m;
    $xml =~ s/\s*$//;

    is ''.Pod::POM->new->parse_text($pod)
        => $xml, $testname;
}





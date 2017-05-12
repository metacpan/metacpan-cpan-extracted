#!perl -T

use Test::More tests => 4;

use File::Temp qw( tempfile );
use URI::file;
use LWP::Simple qw( get );

my ($temp_fh, $temp_filename) = tempfile( 
    'Deleteme-Perl_QuoteOperator-URL-test-XXXX',
    TMPDIR => 1, 
    UNLINK => 1
);
print $temp_fh stuff();
close $temp_fh;

my $url = URI::file->new_abs( $temp_filename );

my $stuff = stuff();

# default test
use PerlX::QuoteOperator::URL;
is qURL/$url/, $stuff, 'qURL testing file:// content';

# renamed to qh
use PerlX::QuoteOperator::URL 'qh';
is qh{$url}, $stuff, 'qh testing file:// content';

# re-test default again but with ()
is qURL($url), $stuff, 'qURL() testing file:// content';

SKIP: {
    my $example_url = 'http://example.com/';
    my $example_org = undef;

    eval { 
	    $example_org = get( $example_url );
	    my $example_org_2 = get( $example_url );

        unless (defined( $example_org )) {
            die "GET $example_url failed, perhaps no internet connection available\n";
        }

        unless ($example_org =~ /\S/) {
            die "Example URL has no content, can not be used to test\n";
        }

        unless ($example_org eq $example_org_2) {
            die "Example URL has dynamic content, can not be used to test\n";
        }
    };

    diag "\n","Skipping web test\n",$@ if $@;
    skip $@, 1 if $@;

    is qURL($example_url), $example_org, 'qURL() testing web content';
}

sub stuff {
    join "!", (
        "first line of data",
        "now the second line",
        "and finally the third line",
    );
}

#!perl

use strict;
use warnings;

use Test::More tests => 9;

use Razor2::Preproc::deHTMLxs;

my $dh = Razor2::Preproc::deHTMLxs->new;

is( $dh->is_xs, 1, "is_xs" );

my $debug = 0;

my $hdr = "X-Razor2-Dummy: foo\n\n";

my $testnum = 3;
foreach my $html_fn (
    qw(
    html.1 html.2 html.3 html.4 html.5 html.6 html.7 html.8
    )
) {

    my $loop_error = 0;

    my $fn = "t/testit/$html_fn";
    open( my $fh, '<', $fn ) or die "cant read $fn";
    my $html = $hdr . join '', <$fh>;
    close $fh;

    if ( $dh->isit( \$html ) ) {

        #my $cleaned_ref = $dh->doit(\$cleaned);
        #my $cleaned = $$cleaned_ref;

        my $cleaned = $html;
        $dh->doit( \$cleaned );

        $cleaned =~ s/^$hdr//s;

        diag "html: $fn (len=" . length($html) . ") cleaned len=" . length($cleaned) if $debug;

        #print "NOT " unless $cleaned eq $dehtml;

        my $deh_fn = ( $^O eq 'VMS' ) ? "${fn}_deHTMLxs" : "$fn.deHTMLxs";
        open( my $fh, '<', $deh_fn ) or die("Can't read $deh_fn: $?");

        my $dehtml = join '', <$fh>;

        if ( $cleaned eq $dehtml ) {
            diag "YEAH -- cleaned html is same as .deHTMLxs: $fn" if $debug;
        }
        else {
            $loop_error++;
            diag "cleaned html (len=" . length($cleaned) . ") differs from .deHTMLxs (len=" . length($dehtml) . ")\n" if $debug;
        }
    }
    else {
        diag "not html: $fn (len=" . length($html) . ")\n" if $debug;
        $loop_error++;
    }
    is( $loop_error, 0, "$fn" );
}

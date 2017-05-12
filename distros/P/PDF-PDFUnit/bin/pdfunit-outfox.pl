#!/usr/bin/perl
use warnings;
use strict;
use feature ':5.10';
use File::Temp qw(tempfile);
use Time::HiRes qw(sleep);

use PDF::PDFUnit qw(:noinit);
PDF::PDFUnit->load_config();




my $window_title = 'PDFUnit in Evaluation Mode';



if (my $display = PDF::PDFUnit->val('outfox_display')) {

    chomp(my $xvfb_pid = qx/ pidof Xvfb /);

    unless ($xvfb_pid) {
        say "Starting Xvfb X11 server on $display";
        system("Xvfb -fbdir /var/tmp $display &");
    }
    
    $ENV{DISPLAY} = $display;
}


while (1) {
    sleep(0.5);

    my $search_cmd = "xdotool search --name '$window_title'";

    $search_cmd .= " windowactivate"
        unless PDF::PDFUnit->val('outfox_display');
    

    my $ret = system($search_cmd);
    next unless ($ret >> 8) == 0;
    
    say "Detected dialog window!";

    my (undef, $tmp_name) = tempfile(
        "/tmp/pdfunit-outfox_XXXXXX",
        OPEN => 0,
        SUFFIX => '.tiff'
    );

    system("xwd -name '$window_title' | convert - -resize 200% $tmp_name");

    my $ocr = qx/ tesseract -psm 6 $tmp_name stdout /;

    unlink $tmp_name;
    
    my ($expression) = $ocr =~ /result:\s+(\w+\s+[+-]\s+\w+)/i;
    
    my $result = "";
    if (defined $expression) {
        say "Detected expression: $expression";
        $result = eval $expression;
        say "Sending response: $result\n";

        system("xdotool type $result");
        system("xdotool key KP_Enter");
    }
    else {
        warn "Could not extract expression.\n";
        warn "Please cancel and restart your test run.\n";
    }
}


=head1 NAME

pdfunit-outfox.pl - Send responses to the dialog box of the evaluation version



=head1 USAGE

 pdfunit-outfox.pl


=head1 IMPORTANT


B<1. If you are using PDFUnit-Java for productive work, get yourself a license!>

B<2. This program only works on Linux! It will never be ported to Windows!>

B<3. See 1.!>


=head1 DESCRIPTION

B<pdfunit-outfox.pl> runs in an endless loop and waits for the dialog window
of the non-licened version of PDFUnit-Java to appear.

If this happens, it saves a temporary screenshot of the dialog window,
converts it to TIFF,
starts an optical character recognition, and extracts the
arithmetic expression.

Finally it calculates the response and sends it back to the dialog.

=head1 CONFIGURATION

Normally, no configuration is required.

If you don't have X11 running, or if you don't like the dialog to pop up,
you can "fake" an X Server with the following line in your pdfunit config:

  outfox_display = :42

(Choose any number different from existing $DISPLAY numbers.)


=head1 REQUIREMENTS

This program uses the following tools:

=over 4

=item B<Xvfb>

=item B<xwd>

=item B<convert>

=item B<xdotool>

=item B<tesseract>

=back

On a Debian 8 system, you get these installed via:

  aptitude install xvfb x11-apps imagemagick xdotool tesseract-ocr


=head1 BUGS

Sometimes the OCR fails. That's the way it is.

See L</IMPORTANT> in this case.


=head1 AUTHOR

Axel Miesen <miesen@quadraginta-duo.de>

=head1 SEE ALSO

L<PDF::PDFUnit>, L<PDF::PDFUnit::Config>

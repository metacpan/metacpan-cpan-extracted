#!/usr/bin/perl
use warnings;
use strict;
use feature ':5.10';
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Temp qw(tempfile);
use Data::Dumper;
use MIME::Base64;

use PDF::PDFUnit qw(:noinit);
use PDF::PDFUnit::Shortcuts;


my $progname = basename($0);
my %opts;

GetOptions(\%opts,
           "help",
           "debug+",
           "check",
       ) || pod2usage(-verbose => 1);

$ENV{PDFUNIT_PERL_DEBUG} = $opts{debug} if exists $opts{debug};
$ENV{PDFUNIT_PERL_DEBUG} //= 0;


DEBUG "$progname started.";
DEBUG "Debug level: $ENV{PDFUNIT_PERL_DEBUG}";


if ($opts{help} || (keys %opts) == 0) {

    pod2usage(exitval => 0);
}


if ($opts{check}) {
    DEBUG "Check/verify of installation requested.";

    say "PDF::PDFUnit version = $PDF::PDFUnit::VERSION";

    
    PDF::PDFUnit->load_config();


    if ($PDF::PDFUnit::instance->{is_loaded}) {
        say "Config file = ", $PDF::PDFUnit::instance->{config_path};
    }
    else {
        check_result(0);
    }


    PDF::PDFUnit->build_classpath() || check_result(0);

    PDF::PDFUnit->attach_java() || check_result(0);


    DEBUG Dumper($PDF::PDFUnit::instance), 3;



    my $pdfunit_java_version;
    my $compatible_versions;

    eval {
        DEBUG("Trying to get version info from the Java lib");
        $pdfunit_java_version = VersionInfo->getCurrentVersion();

        # This is an Inline::Java::Array object:
        $compatible_versions = VersionInfo->getCompatibleVersions();
    };
    if ($@) {
        die "Cannot get version information out of "
            . "your installed PDFUnit Java library.\n";
    }

    
    print "PDFUnit Java version = $pdfunit_java_version";

    if (@$compatible_versions >= 2) {
        say " (compatible: "
            . join(', ', @$compatible_versions)
            . ")";
    }
    else {
        print "\n";
    }

    if (! grep { $PDF::PDFUnit::PDFUNIT_JAVA_VERSION eq $_ }
            @$compatible_versions) {
        die("\nThis version of PDF::PDFUnit only works with"
                . " $PDF::PDFUnit::PDFUNIT_JAVA_VERSION"
                . " (and compatible releases)\n");
    }
    
    my $tmp_pdf = File::Temp->new(UNLINK => 1, SUFFIX => '.pdf');

    {
        local $/ = '__END__';
        my $base64_encoded = <DATA>;
        my $decoded = decode_base64($base64_encoded);
        DEBUG "Now try to validate this PDF:", 4;
        DEBUG $decoded, 4;
        print $tmp_pdf $decoded;
    }

    DEBUG "Created temporary PDF for validation test: " . $tmp_pdf->filename;
    close $tmp_pdf || die;

    eval {
        DEBUG "Now trying to load it via AssertThat->document().";
        AssertThat->document( $tmp_pdf->filename );
    };


    check_result( $@?  0  :  1 );
}


sub check_result {
    my ($result) = @_;

    say "";

    if ($result == 0) {
        say "Something is wrong with your setup.";
        say "Run again with multiple -d switches to get diagnostic messages...";
        exit 1;
    }
    else {
        say "Your setup looks fine. Have fun with PDF::PDFUnit!";
        exit 0;
    }
}




__DATA__
JVBERi0xLjMKJcOiw6PDj8OTCjEgMCBvYmogCjw8Ci9LaWRzIFsyIDAgUl0KL0NvdW50IDEKL1R5
cGUgL1BhZ2VzCj4+CmVuZG9iaiAKMiAwIG9iaiAKPDwKL1BhcmVudCAxIDAgUgovUmVzb3VyY2Vz
IDMgMCBSCi9NZWRpYUJveCBbMCAwIDU5NSA4NDJdCi9Db250ZW50cyBbNCAwIFJdCi9UeXBlIC9Q
YWdlCj4+CmVuZG9iaiAKMyAwIG9iaiAKPDwKL0ZvbnQgCjw8Ci9GMCAKPDwKL0Jhc2VGb250IC9U
aW1lcy1JdGFsaWMKL1N1YnR5cGUgL1R5cGUxCi9UeXBlIC9Gb250Cj4+Cj4+Cj4+CmVuZG9iaiAK
NCAwIG9iaiAKPDwKL0xlbmd0aCA2Ngo+PgpzdHJlYW0KMS4gMC4gMC4gMS4gMTkwLiA1MDAuIGNt
CkJUCiAgL0YwIDM2LiBUZgogIChIZWxsbywgV29ybGQhKSBUagpFVAoKZW5kc3RyZWFtIAplbmRv
YmogCjUgMCBvYmogCjw8Ci9QYWdlcyAxIDAgUgovVHlwZSAvQ2F0YWxvZwo+PgplbmRvYmogeHJl
ZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDE1IDAwMDAwIG4gCjAwMDAwMDAwNzQg
MDAwMDAgbiAKMDAwMDAwMDE4MiAwMDAwMCBuIAowMDAwMDAwMjgxIDAwMDAwIG4gCjAwMDAwMDA0
MDAgMDAwMDAgbiAKdHJhaWxlcgoKPDwKL1Jvb3QgNSAwIFIKL1NpemUgNgo+PgpzdGFydHhyZWYK
NDUwCiUlRU9GCg==
__END__

=head1 NAME

pdfunit-perl.pl - Verify a PDF::PDFUnit installation

=head1 USAGE

 pdfunit-perl.pl [OPTIONS]

=head1 DESCRIPTION

The purpose of this tool is to check/verify a PDF::PDFUnit installation.

If you start it with B<--check> and everything is fine so far, it outputs
the PDF::PDFUnit version and the path to the used config file.

Furthermore, it creates a small temporary PDF and tries
to load it via C<< AssertThat->document() >>.

Finally it should report: "Your setup looks fine." Good luck!

=head1 OPTIONS

=over

=item B<--check>

Check/verify installation.


=item B<--help>

Print this page.


=item B<--debug>

Output debug messages to STDERR. Can be repeated to achieve higher levels.

=back


=head1 AUTHOR

Axel Miesen <miesen@quadraginta-duo.de>

=head1 SEE ALSO

L<PDF::PDFUnit>, L<PDF::PDFUnit::Config>

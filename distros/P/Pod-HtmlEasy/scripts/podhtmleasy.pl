#! /usr/bin/perl

# This script shows how POD => HTML works

use Pod::HtmlEasy ;

if ( !@ARGV || $ARGV[0] =~ /^-+h/i ) {
    ($script) = ( $0 =~ /([^\\\/]+)$/s );
    print <<_USAGE;
Pod::HtmlEasy - $Pod::HtmlEasy::VERSION
Usage: $script file.pod [file.html]
_USAGE

    exit 0;
}

$podhtml = Pod::HtmlEasy->new();

$pod_file = shift;
$new_file = $pod_file;
$new_file =~ s{\.\w+\z}{};
$html_file = defined $ARGV[0] ? shift : "${new_file}.html";

$podhtml->pod2html( $pod_file , 'output', $html_file , @ARGV );

print "$pod_file converted to $html_file\n";
exit 0;

#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Gzip::Faster;
my $header = 'Content-Type: text/html;charset=UTF-8';
my $output = <<EOF;
I am a CGI program
私はCGIプローグラムです。
EOF
my $hae = $ENV{HTTP_ACCEPT_ENCODING};
if ($hae && $hae =~ /\bgzip\b/) {
    binmode STDOUT, ":raw";
    my $gzoutput = gzip ($output);
    print "$header\nContent-Encoding: gzip\n\n$gzoutput";
}
else {
    binmode STDOUT, ":utf8";
    print "$header\n\n$output";
}
exit;

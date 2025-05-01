use strict;
use warnings;
use Test::More;
use MsOffice::Word::Surgeon;

(my $dir = $0) =~ s[zip_from_filehandle.t$][];
$dir ||= ".";
my $sample_file = "$dir/etc/MsOffice-Word-Surgeon.docx";

open my $fh, "<:raw", $sample_file or die "open $sample_file: $!";

my $surgeon = MsOffice::Word::Surgeon->new($fh);

my $plain_text = $surgeon->plain_text;
like   $plain_text, qr/because documents edited in MsWord often have run boundaries across sentences/,  "plain text";
like   $plain_text, qr/1st/, "found 1st";
like   $plain_text, qr/2nd/, "found 2nd";
like   $plain_text, qr/paragraph\ncontains a soft line break/, "soft line break";
unlike $plain_text, qr/&\w+;/, "decoded entities";

my $zip_in_memory = "";
open my $out, ">:raw", \$zip_in_memory or die "open output handle : $!";
$surgeon->save_as($out);
close $out;
ok bytes::length($zip_in_memory), "output zip in memory is not empty";


done_testing();

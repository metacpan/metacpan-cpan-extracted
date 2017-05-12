# Test form parsing.  Taken out of 83-attachments.t as a special case,
# just to make sure that the form parsing is performed correctly.

use strict;
use warnings;

use Test::More tests => 3;

use RT::Client::REST::Forms qw(form_parse);
use File::Spec::Functions qw(catfile);

my $testfile = "test.png";
my $testfile_path = catfile(t => $testfile);

open (my $fh, "<", $testfile_path) or die "Couldn't open $testfile_path $!";
my $contents = do { local $/; <$fh>; };
close $fh;

sub create_http_body {
    my $binary_string = shift;
    my $length = length($binary_string);
    $binary_string =~ s/\n/\n         /sg;
    $binary_string .= "\n\n";
    my $body = <<"EOF";
id: 873
Subject: 
Creator: 12
Created: 2013-11-06 07:15:36
Transaction: 1457
Parent: 871
MessageId: 
Filename: prova2.png
ContentType: image/png
ContentEncoding: base64

Headers: Content-Type: image/png; name="prova2.png"
         Content-Disposition: attachment; filename="prova2.png"
         Content-Transfer-Encoding: base64
         Content-Length: $length

Content: $binary_string
EOF
    return $body;
}

my $body = create_http_body($contents);
my $form = form_parse($body);
is(ref($form), "ARRAY", "form is an array reference");
my ($c, $o, $k, $e) = @{$$form[0]};
is(ref($k), "HASH", "third element (\$k) is a hash reference");
ok($k->{Content} eq $contents, "form parsed out contents correctly");

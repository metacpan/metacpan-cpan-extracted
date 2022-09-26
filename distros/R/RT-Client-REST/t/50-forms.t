#!perl

# Test form parsing.  Taken out of 83-attachments.t as a special case,
# just to make sure that the form parsing is performed correctly.

use strict;
use warnings;

use Test::More tests => 6;

use RT::Client::REST::Forms qw(form_parse);
use File::Spec::Functions   qw(catfile);

my $testfile      = 'test.png';
my $testfile_path = catfile( 't' => 'data' => $testfile );

open( my $fh, '<', $testfile_path ) or die "Couldn't open $testfile_path $!";
my $contents = do { local $/; <$fh>; };
close $fh;

sub dump_file {
    open( my $out, '>', '/tmp/test.png' );
    print $out $_[0];
    close $out;
}

sub create_http_body {
    my $binary_string = shift;
    my $length        = length($binary_string);
    my $spaces        = ' ' x length('Content: ');
    $binary_string =~ s/\n/\n$spaces/sg;
    my $body = <<"EOF";
id: 873
Subject: \nCreator: 12
Created: 2013-11-06 07:15:36
Transaction: 1457
Parent: 871
MessageId: \nFilename: prova2.png
ContentType: image/png
ContentEncoding: base64

Headers: Content-Type: image/png; name="prova2.png"
         Content-Disposition: attachment; filename="prova2.png"
         Content-Transfer-Encoding: base64
         Content-Length: $length

Content: $binary_string\n\n
EOF
    return $body;
}

{
    my $body = create_http_body($contents);
    my $form = form_parse($body);
    is( ref($form), 'ARRAY', 'form is an array reference' );
    my ( $c, $o, $k, $e ) = @{ $$form[0] };
    is( ref($k), 'HASH', 'third element ($k) is a hash reference' );
    ok( $k->{Content} eq $contents, 'form parsed out contents correctly' );
    dump_file( $k->{Content} );
}

{
my $body = qq|id: 17217
Subject: \nCreator: 12
Created: 2022-09-24 21:26:55
Transaction: 37112
Parent: 17215
MessageId: \nFilename: LG1kcpoxfV
ContentType: text/plain
ContentEncoding: none

Headers: Content-Transfer-Encoding: binary
         Content-Disposition: form-data; filename="LG1kcpoxfV"; name="attachment_1"
         Content-Type: text/plain; charset="utf-8"; name="LG1kcpoxfV"
         X-RT-Original-Encoding: ascii
         Content-Length: 31

Content: dude this is a text attachment



|;
    my $form = form_parse($body);
    is( ref($form), 'ARRAY', 'form is an array reference' );
    my ( $c, $o, $k, $e ) = @{ $$form[0] };
    is( ref($k), 'HASH', 'third element ($k) is a hash reference' );
    ok( $k->{Content} eq "dude this is a text attachment\n",
        'form parsed out contents correctly' );
}

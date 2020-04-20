#!/usr/bin/env perl
# сгенерировано miu

use utf8;
use open qw/:std :utf8/;

BEGIN {
	select(STDERR);	$| = 1;
	select(STDOUT); $| = 1; # default
	close STDERR; open(STDERR, ">&STDOUT");
}

use Test::More tests => 31;

my $_f;
print "= NAME" . "\n";
print "= SINOPSIS" . "\n";
# Make datafiles for test:
`echo "Simple text." > /tmp/file.txt`;
`gzip < /tmp/file.txt > /tmp/file.gz`;

use Multipart::Encoder;

my $multipart = Multipart::Encoder->new(
    x=>1,
    file_name => \"/tmp/file.txt",
    y=>[
        "Content-Type" => "text/json",
        name => 'my-name',
        filename => 'my-filename',
        _ => '{"count": 666}',
        'Any-Header' => 123,
    ],
    z => {
        _ => \'/tmp/file.gz',
        'Any-Header' => 123,
    }
)->buffer_size(2048)->boundary("xYzZY");

my $str = $multipart->as_string;

::is_deeply( scalar(utf8::is_utf8($str)), scalar(""), "utf8::is_utf8(\$str)            ## \"\"" );

::like( scalar($str), qr{\r\n--xYzZY--\r\n\z}, "\$str                           #~ \r\n--xYzZY--\r\n\z" );

$multipart->to("/tmp/file.form-data");

open my $f, "<", "/tmp/file.form-data"; binmode $f; read $f, my $buf, -s $f; close $f;
::is_deeply( scalar($buf), scalar($str), "\$buf                           ## \$str" );

{ local *STDOUT; open STDOUT, '>', \$_f; binmode STDOUT; $multipart->to(\*STDOUT); close STDOUT }; ::is_deeply( scalar($_f), scalar($str), "\$multipart->to(\\*STDOUT);      ##>> \$str" );

print "= DESCRIPTION" . "\n";
print "= INSTALL" . "\n";
print "= SUBROUTINES/METHODS" . "\n";
print "== new" . "\n";
my $multipart1 = Multipart::Encoder->new;
my $multipart2 = $multipart1->new;
::cmp_ok( scalar($multipart2), '!=', scalar($multipart1), "\$multipart2    ##!= \$multipart1" );

::is( scalar(ref Multipart::Encoder::new(0)), "0", "ref Multipart::Encoder::new(0)    # 0" );

::like( scalar(Multipart::Encoder->new(x=>123)->as_string), qr{123}, "Multipart::Encoder->new(x=>123)->as_string    #~ 123" );

print "== content_type" . "\n";
::is( scalar($multipart->content_type), "multipart/form-data", "\$multipart->content_type    # multipart/form-data" );

print "== buffer_size" . "\n";
::is( scalar($multipart->buffer_size(1024)->buffer_size), "1024", "\$multipart->buffer_size(1024)->buffer_size        # 1024" );

::is( scalar(Multipart::Encoder->new->buffer_size), "2048", "Multipart::Encoder->new->buffer_size            # 2048" );

print "== boundary" . "\n";
::is( scalar($multipart->boundary("XYZooo")->boundary), "XYZooo", "\$multipart->boundary(\"XYZooo\")->boundary        # XYZooo" );

::is( scalar(Multipart::Encoder->new->boundary), "xYzZY", "Multipart::Encoder->new->boundary                # xYzZY" );

print "== as_string" . "\n";
::like( scalar(Multipart::Encoder->new(x=>123, y=>456)->as_string), qr{123}, "Multipart::Encoder->new(x=>123, y=>456)->as_string   #~ 123" );

print "== to" . "\n";
$multipart->to("/tmp/file.form-data");

open my $f, ">", "/tmp/file.form-data"; binmode $f;
$multipart->to($f);
close $f;

eval { $multipart->to("/") }; ::like( scalar($@), qr{Not open file `/`. Is a directory}, "\$multipart->to(\"/\")        #\@ ~ Not open file `/`. Is a directory" );

print "= PARAMS" . "\n";
print "== String param type" . "\n";
::like( scalar(Multipart::Encoder->new(x=>"Simple string")->as_string), qr{Simple string}, "Multipart::Encoder->new(x=>\"Simple string\")->as_string    #~ Simple string" );

my $str = Multipart::Encoder->new(
    x => {
        _ => "Simple string",
        header => 123,
    },
)->as_string;

::like( scalar($str), qr{Simple string}, "\$str #~ Simple string" );
::like( scalar($str), qr{header: 123}, "\$str #~ header: 123" );

::like( scalar(Multipart::Encoder->new(x=>"Simple string")->as_string), qr{Content-Disposition: form-data; name="x"}, "Multipart::Encoder->new(x=>\"Simple string\")->as_string    #~ Content-Disposition: form-data; name=\"x\"" );

my $str = Multipart::Encoder->new(
    x => {
        _ => "Simple string",
        name => "xyz",
    },
)->as_string;

::like( scalar($str), qr{Content-Disposition: form-data; name="xyz"}, "\$str #~ Content-Disposition: form-data; name=\"xyz\"" );

my $str = Multipart::Encoder->new(
    0 => {
        _ => "Simple string",
        filename => "xyz.tgz",
    },
)->as_string;

::like( scalar($str), qr{Content-Disposition: form-data; name="0"; filename="xyz.tgz"}, "\$str #~ Content-Disposition: form-data; name=\"0\"; filename=\"xyz.tgz\"" );

my $str = Multipart::Encoder->new(
    x => {
        _ => "Simple string",
        'content-disposition' => "form-data; name=\"z\"; filename=\"xyz\"",
    },
)->as_string;

::like( scalar($str), qr{content-disposition: form-data; name="z"; filename="xyz"}, "\$str #~ content-disposition: form-data; name=\"z\"; filename=\"xyz\"" );

print "== File param type" . "\n";
open my $f, ">/tmp/0"; close $f;

::like( scalar(Multipart::Encoder->new(x=>\"/tmp/0")->as_string), qr{Content-Disposition: form-data; name="x"; filename="0"}, "Multipart::Encoder->new(x=>\\\"/tmp/0\")->as_string    #~ Content-Disposition: form-data; name=\"x\"; filename=\"0\"" );

::like( scalar(Multipart::Encoder->new(x=>\"/tmp/file.gz")->as_string), qr{Content-Type: application/(x-)?gzip; charset=binary}, "Multipart::Encoder->new(x=>\\\"/tmp/file.gz\")->as_string    #~ Content-Type: application/(x-)?gzip; charset=binary" );

my $str = Multipart::Encoder->new(
    x => [
        _ => \"/tmp/file.gz",
        'content-type' => 'text/plain',
    ]
)->as_string;

::like( scalar($str), qr{content-type: text/plain}, "\$str #~ content-type: text/plain" );
::unlike( scalar($str), qr{Content-Type}, "\$str #!~ Content-Type" );

my $str = Multipart::Encoder->new(
    x => {
        _ => \"/tmp/file.txt",
        name => "xyz",
    },
)->as_string;

::like( scalar($str), qr{Content-Disposition: form-data; name="xyz"; filename="file.txt"}, "\$str #~ Content-Disposition: form-data; name=\"xyz\"; filename=\"file.txt\"" );

my $str = Multipart::Encoder->new(
    0 => {
        _ => \"/tmp/file.txt",
        filename => "xyz.tgz",
    },
)->as_string;

::like( scalar($str), qr{Content-Disposition: form-data; name="0"; filename="xyz.tgz"}, "\$str #~ Content-Disposition: form-data; name=\"0\"; filename=\"xyz.tgz\"" );

my $str = Multipart::Encoder->new(
    x => [
        _ => \"/tmp/file.txt",
        'content-disposition' => "form-data; name=\"z\"; filename=\"xyz\"",
    ],
)->as_string;

::like( scalar($str), qr{content-disposition: form-data; name="z"; filename="xyz"}, "\$str #~ content-disposition: form-data; name=\"z\"; filename=\"xyz\"" );

open my $f, ">", "/tmp/bigfile"; binmode $f; print $f 0 x (1024*1024); close $f;

::like( scalar(Multipart::Encoder->new(x=>\"/tmp/bigfile")->as_string), qr{\n0+\r}, "Multipart::Encoder->new(x=>\\\"/tmp/bigfile\")->as_string    #~ \n0+\r" );
Multipart::Encoder->new(x=>\"/tmp/bigfile")->as_string =~ /\n(0+)\r/;
::cmp_ok( scalar(length $1), '==', scalar(1024*1024), "length \$1     ##== 1024*1024" );

eval { Multipart::Encoder->new(x=>\"/tmp/NnKkMm346485923")->as_string }; ::like( scalar($@), qr{Not open file `/tmp/NnKkMm346485923`: No such file or directory}, "Multipart::Encoder->new(x=>\\\"/tmp/NnKkMm346485923\")->as_string #\@ ~ Not open file `/tmp/NnKkMm346485923`: No such file or directory" );


print "= SEE ALSO" . "\n";
print "= LICENSE" . "\n";
print "= AUTHOR" . "\n";
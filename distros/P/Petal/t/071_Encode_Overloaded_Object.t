#!/usr/bin/perl
use Test::More;
use warnings;
use lib 'lib';
use Petal;

eval {
  require URI;
};
if( $@ ) {
  plan skip_all => 'URI.pm not installed';
}
else {
  plan tests => 1;
}

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::HTML_ERRORS  = 1;
$Petal::BASE_DIR     = ('t/data');
my $file             = 'content_encoded.html';

{
    my $t = new Petal ( file => $file );
    my $s = $t->process ( test => URI->new ('http://example.com/test.cgi?foo=test&bar=test') );
    like ($s, qr/\&amp\;/);
}

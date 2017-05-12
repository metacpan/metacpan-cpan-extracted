#########################

use Test;
BEGIN { plan tests => 1 };

#########################

use Qmail::Envelope;

my $env = "Fcrunch\@168.com\0Tcloudnine\@ack.net\0Tsplorch\@asdf.com\0\0";
$E = Qmail::Envelope->new( data => $env );

ok($E->sender, 'crunch@168.com');


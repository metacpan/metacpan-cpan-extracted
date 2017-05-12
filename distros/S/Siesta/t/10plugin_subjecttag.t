#!perl -w
use strict;
use Test::More tests => 20;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::List;
use Siesta::Message;
use Siesta::Plugin::SubjectTag;
my $plugin = Siesta::Plugin::SubjectTag->new(
    list => Siesta::List->create({ name => 'cockknocker' }),
    queue => 'test',
   );

my $mail = Siesta::Message->new;

ok($plugin->pref('subjecttag','[cockknocker]'));

$mail->subject("Mark Hamill");
is( $mail->subject, "Mark Hamill", "before" );
ok( !$plugin->process($mail) );
is( $mail->subject, "[cockknocker] Mark Hamill", "added tag after" );

ok( !$plugin->process($mail) );
is( $mail->subject, "[cockknocker] Mark Hamill", "added tag once" );

$mail->subject("Re: [cockknocker] Mark Hamill");
ok( !$plugin->process($mail) );
is( $mail->subject, "Re: [cockknocker] Mark Hamill", "okay with Re: lines" );

$mail->subject("");
ok( !$plugin->process($mail) );
is( $mail->subject, "[cockknocker] no subject", "null subject handling" );


ok($plugin->pref('subjecttag','(knockcocker)'));

$mail->subject("Mark Hamill");
is( $mail->subject, "Mark Hamill", "before" );
ok( !$plugin->process($mail) );
is( $mail->subject, "(knockcocker) Mark Hamill", "added tag after" );

ok( !$plugin->process($mail) );
is( $mail->subject, "(knockcocker) Mark Hamill", "added tag once" );

$mail->subject("Re: (knockcocker) Mark Hamill");
ok( !$plugin->process($mail) );
is( $mail->subject, "Re: (knockcocker) Mark Hamill", "okay with Re: lines" );

$mail->subject("");
ok( !$plugin->process($mail) );
is( $mail->subject, "(knockcocker) no subject", "null subject handling" );


$plugin->list->delete;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More tests => 226;
BEGIN { use_ok('Synapse::MailSender') };
no warnings;
use strict;

$Synapse::Logger::BASE_DIR = "./t/log";

my $yaml = {
          'subject' => 'Subject@example.com',
          'user' => {
                      'bcc' => [
                                 'Bcc@example.com'
                               ],
                      'to' => [
                                'To@example.com'
                              ],
                      'cc' => [
                                'Cc@example.com'
                              ],
                      'from' => [
                                  'From@example.com'
                                ]
                    },
          'para' => [
                      'para 1',
                      'para 2',
                      'para 3',
                      'para 4',
                      'para 5',
                      'para 6',
                      'para 7',
                      'para 8',
                      'para 9'
                    ],
          'attach' => [
                        './README',
                        './Changes',
                        './MANIFEST'
                      ],
          'setsender' => 'SetSender@example.com'
};


my $xmldata = join '', <DATA>;


my $s = Synapse::MailSender->new();

# new()
ok ($s, 'new() - exists');
ok ($s->isa ('Synapse::MailSender'), 'new() - is Synapse::MailSender');

# From()
$s->From ('From@example.com');
ok ($s->{From}, 'From() - exists');
is (ref $s->{From}, 'ARRAY', 'From() - is array ref');
is ($s->{From}->[0], 'From@example.com', 'From() - is correct value');

# To()
$s->To ('To@example.com');
ok ($s->{To}, 'To() - exists');
is (ref $s->{To}, 'ARRAY', 'To() - is array ref');
is ($s->{To}->[0], 'To@example.com', 'To() - is correct value');

# Cc()
$s->Cc ('Cc@example.com');
ok ($s->{Cc}, 'Cc() - exists');
is (ref $s->{Cc}, 'ARRAY', 'Cc() - is array ref');
is ($s->{Cc}->[0], 'Cc@example.com', 'Cc() - is correct value');

# Bcc()
$s->Bcc ('Bcc@example.com');
ok ($s->{Bcc}, 'Bcc() - exists');
is (ref $s->{Bcc}, 'ARRAY', 'Bcc() - is array ref');
is ($s->{Bcc}->[0], 'Bcc@example.com', 'Bcc() - is correct value');

# Subject()
$s->Subject ('Subject@example.com');
ok ($s->{Subject}, 'Subject() - exists');
isnt (ref $s->{Subject}, 'ARRAY', 'Subject() - is NOT array ref');
is ($s->{Subject}, 'Subject@example.com', 'Subject() - is correct value');

# SetSender()
$s->SetSender ('SetSender@example.com');
ok ($s->{SetSender}, 'SetSender() - exists');
isnt (ref $s->{SetSender}, 'ARRAY', 'SetSender() - is NOT array ref');
is ($s->{SetSender}, 'SetSender@example.com', 'SetSender() - is correct value');

# Body()
$s->Body ('para 1');
$s->Body ('para 2');
$s->Body ('para 3');
ok ($s->{Body}, 'Body() - exists');
is (ref $s->{Body}, 'ARRAY', 'Body() - is array ref');
is ($s->{Body}->[0], 'para 1', 'Body() - para 1 is correct value');
is ($s->{Body}->[1], 'para 2', 'Body() - para 2 is correct value');
is ($s->{Body}->[2], 'para 3', 'Body() - para 3 is correct value');

# Say()
$s->Say ('para 4');
$s->Say ('para 5');
$s->Say ('para 6');
is ($s->{Body}->[3], 'para 4', 'Say() - para 1 is correct value');
is ($s->{Body}->[4], 'para 5', 'Say() - para 2 is correct value');
is ($s->{Body}->[5], 'para 6', 'Say() - para 3 is correct value');

# Para()
$s->Para ('para 7');
$s->Para ('para 8');
$s->Para ('para 9');
is ($s->{Body}->[6], 'para 7', 'Para() - para 1 is correct value');
is ($s->{Body}->[7], 'para 8', 'Para() - para 2 is correct value');
is ($s->{Body}->[8], 'para 9', 'Para() - para 3 is correct value');

# Attach()
$s->Attach('./README');
$s->Attach('./Changes');
$s->Attach('./MANIFEST');
ok ($s->{Attach}, 'Attach() - exists');
is (ref $s->{Attach}, 'ARRAY', 'Attach() - is array ref');
is ($s->{Attach}->[0], './README', 'Attach() - README OK');
is ($s->{Attach}->[1], './Changes', 'Attach() - Changes OK');
is ($s->{Attach}->[2], './MANIFEST', 'Attach() - MANIFEST OK');

# Let's take a look at message()
my $msg = $s->message();
ok ($msg, 'message() - exists');
ok (ref $msg, 'message() - is a reference');
ok ($msg->isa("MIME::Lite"), 'message() is a MIME::Lite() object');

my $string = $msg->as_string();
like ($string, qr/Cc: Cc\@example\.com/, 'string() - check Cc');
like ($string, qr/Subject: Subject\@example\.com/, 'string() - check Subject');
like ($string, qr/To: To\@example\.com/, 'string() - check To');
like ($string, qr/Bcc: Bcc\@example\.com/, 'string() - check Bcc');
like ($string, qr/From: From\@example\.com/, 'string() - check From');
like ($string, qr/This is a multi-part message in MIME format/, 'string() - check Multipart');

my $xml = -e './example.xml' ? './example.xml' : './t/example.xml';
my $yml = -e './example.yml' ? './example.yml' : './t/example.yml';


#### NOW LET'S TRY OUT THE SAME THING, BUT WITH TEMPLATING (xmlfile, yamlfile)

# new()
my $s2  = Synapse::MailSender->new();
$s2->loadxml ($xml, $yml);
ok ($s2, 'new() - exists');
ok ($s2->isa ('Synapse::MailSender'), 'new() - is Synapse::MailSender');

# From()
ok ($s2->{From}, 'From() - exists');
is (ref $s2->{From}, 'ARRAY', 'From() - is array ref');
is ($s2->{From}->[0], 'From@example.com', 'From() - is correct value');

# To()
ok ($s2->{To}, 'To() - exists');
is (ref $s2->{To}, 'ARRAY', 'To() - is array ref');
is ($s2->{To}->[0], 'To@example.com', 'To() - is correct value');

# Cc()
ok ($s2->{Cc}, 'Cc() - exists');
is (ref $s2->{Cc}, 'ARRAY', 'Cc() - is array ref');
is ($s2->{Cc}->[0], 'Cc@example.com', 'Cc() - is correct value');

# Bcc()
ok ($s2->{Bcc}, 'Bcc() - exists');
is (ref $s2->{Bcc}, 'ARRAY', 'Bcc() - is array ref');
is ($s2->{Bcc}->[0], 'Bcc@example.com', 'Bcc() - is correct value');

# Subject()
ok ($s2->{Subject}, 'Subject() - exists');
isnt (ref $s2->{Subject}, 'ARRAY', 'Subject() - is NOT array ref');
is ($s2->{Subject}, 'Subject@example.com', 'Subject() - is correct value');

# SetSender()
ok ($s2->{SetSender}, 'SetSender() - exists');
isnt (ref $s2->{SetSender}, 'ARRAY', 'SetSender() - is NOT array ref');
is ($s2->{SetSender}, 'SetSender@example.com', 'SetSender() - is correct value');

# Body()
ok ($s2->{Body}, 'Body() - exists');
is (ref $s2->{Body}, 'ARRAY', 'Body() - is array ref');
is ($s2->{Body}->[0], 'para 1', 'Body() - para 1 is correct value');
is ($s2->{Body}->[1], 'para 2', 'Body() - para 2 is correct value');
is ($s2->{Body}->[2], 'para 3', 'Body() - para 3 is correct value');

# Say()
is ($s2->{Body}->[3], 'para 4', 'Say() - para 1 is correct value');
is ($s2->{Body}->[4], 'para 5', 'Say() - para 2 is correct value');
is ($s2->{Body}->[5], 'para 6', 'Say() - para 3 is correct value');

# Para()
is ($s2->{Body}->[6], 'para 7', 'Para() - para 1 is correct value');
is ($s2->{Body}->[7], 'para 8', 'Para() - para 2 is correct value');
is ($s2->{Body}->[8], 'para 9', 'Para() - para 3 is correct value');

# Attach()
ok ($s2->{Attach}, 'Attach() - exists');
is (ref $s2->{Attach}, 'ARRAY', 'Attach() - is array ref');
is ($s2->{Attach}->[0], './README', 'Attach() - README OK');
is ($s2->{Attach}->[1], './Changes', 'Attach() - Changes OK');
is ($s2->{Attach}->[2], './MANIFEST', 'Attach() - MANIFEST OK');

# Let's take a look at message()
my $msg = $s2->message();
ok ($msg, 'message() - exists');
ok (ref $msg, 'message() - is a reference');
ok ($msg->isa("MIME::Lite"), 'message() is a MIME::Lite() object');

my $s2tring = $msg->as_string();
like ($s2tring, qr/Cc: Cc\@example\.com/, 'string() - check Cc');
like ($s2tring, qr/Subject: Subject\@example\.com/, 'string() - check Subject');
like ($s2tring, qr/To: To\@example\.com/, 'string() - check To');
like ($s2tring, qr/Bcc: Bcc\@example\.com/, 'string() - check Bcc');
like ($s2tring, qr/From: From\@example\.com/, 'string() - check From');
like ($s2tring, qr/This is a multi-part message in MIME format/, 'string() - check Multipart');


#### NOW LET'S TRY OUT THE SAME THING, BUT WITH TEMPLATING (xmldata, yamlfile)

# new()
$s2  = Synapse::MailSender->new();
$s2->loadxml ($xmldata, $yml);
ok ($s2, 'new() - exists');
ok ($s2->isa ('Synapse::MailSender'), 'new() - is Synapse::MailSender');

# From()
ok ($s2->{From}, 'From() - exists');
is (ref $s2->{From}, 'ARRAY', 'From() - is array ref');
is ($s2->{From}->[0], 'From@example.com', 'From() - is correct value');

# To()
ok ($s2->{To}, 'To() - exists');
is (ref $s2->{To}, 'ARRAY', 'To() - is array ref');
is ($s2->{To}->[0], 'To@example.com', 'To() - is correct value');

# Cc()
ok ($s2->{Cc}, 'Cc() - exists');
is (ref $s2->{Cc}, 'ARRAY', 'Cc() - is array ref');
is ($s2->{Cc}->[0], 'Cc@example.com', 'Cc() - is correct value');

# Bcc()
ok ($s2->{Bcc}, 'Bcc() - exists');
is (ref $s2->{Bcc}, 'ARRAY', 'Bcc() - is array ref');
is ($s2->{Bcc}->[0], 'Bcc@example.com', 'Bcc() - is correct value');

# Subject()
ok ($s2->{Subject}, 'Subject() - exists');
isnt (ref $s2->{Subject}, 'ARRAY', 'Subject() - is NOT array ref');
is ($s2->{Subject}, 'Subject@example.com', 'Subject() - is correct value');

# SetSender()
ok ($s2->{SetSender}, 'SetSender() - exists');
isnt (ref $s2->{SetSender}, 'ARRAY', 'SetSender() - is NOT array ref');
is ($s2->{SetSender}, 'SetSender@example.com', 'SetSender() - is correct value');

# Body()
ok ($s2->{Body}, 'Body() - exists');
is (ref $s2->{Body}, 'ARRAY', 'Body() - is array ref');
is ($s2->{Body}->[0], 'para 1', 'Body() - para 1 is correct value');
is ($s2->{Body}->[1], 'para 2', 'Body() - para 2 is correct value');
is ($s2->{Body}->[2], 'para 3', 'Body() - para 3 is correct value');

# Say()
is ($s2->{Body}->[3], 'para 4', 'Say() - para 1 is correct value');
is ($s2->{Body}->[4], 'para 5', 'Say() - para 2 is correct value');
is ($s2->{Body}->[5], 'para 6', 'Say() - para 3 is correct value');

# Para()
is ($s2->{Body}->[6], 'para 7', 'Para() - para 1 is correct value');
is ($s2->{Body}->[7], 'para 8', 'Para() - para 2 is correct value');
is ($s2->{Body}->[8], 'para 9', 'Para() - para 3 is correct value');

# Attach()
ok ($s2->{Attach}, 'Attach() - exists');
is (ref $s2->{Attach}, 'ARRAY', 'Attach() - is array ref');
is ($s2->{Attach}->[0], './README', 'Attach() - README OK');
is ($s2->{Attach}->[1], './Changes', 'Attach() - Changes OK');
is ($s2->{Attach}->[2], './MANIFEST', 'Attach() - MANIFEST OK');

# Let's take a look at message()
my $msg = $s2->message();
ok ($msg, 'message() - exists');
ok (ref $msg, 'message() - is a reference');
ok ($msg->isa("MIME::Lite"), 'message() is a MIME::Lite() object');

my $s2tring = $msg->as_string();
like ($s2tring, qr/Cc: Cc\@example\.com/, 'string() - check Cc');
like ($s2tring, qr/Subject: Subject\@example\.com/, 'string() - check Subject');
like ($s2tring, qr/To: To\@example\.com/, 'string() - check To');
like ($s2tring, qr/Bcc: Bcc\@example\.com/, 'string() - check Bcc');
like ($s2tring, qr/From: From\@example\.com/, 'string() - check From');
like ($s2tring, qr/This is a multi-part message in MIME format/, 'string() - check Multipart');


#### NOW LET'S TRY OUT THE SAME THING, BUT WITH TEMPLATING (xmlfile, yamldata)

# new()
$s2  = Synapse::MailSender->new();
$s2->loadxml ($xml, yaml => $yaml);
ok ($s2, 'new() - exists');
ok ($s2->isa ('Synapse::MailSender'), 'new() - is Synapse::MailSender');

# From()
ok ($s2->{From}, 'From() - exists');
is (ref $s2->{From}, 'ARRAY', 'From() - is array ref');
is ($s2->{From}->[0], 'From@example.com', 'From() - is correct value');

# To()
ok ($s2->{To}, 'To() - exists');
is (ref $s2->{To}, 'ARRAY', 'To() - is array ref');
is ($s2->{To}->[0], 'To@example.com', 'To() - is correct value');

# Cc()
ok ($s2->{Cc}, 'Cc() - exists');
is (ref $s2->{Cc}, 'ARRAY', 'Cc() - is array ref');
is ($s2->{Cc}->[0], 'Cc@example.com', 'Cc() - is correct value');

# Bcc()
ok ($s2->{Bcc}, 'Bcc() - exists');
is (ref $s2->{Bcc}, 'ARRAY', 'Bcc() - is array ref');
is ($s2->{Bcc}->[0], 'Bcc@example.com', 'Bcc() - is correct value');

# Subject()
ok ($s2->{Subject}, 'Subject() - exists');
isnt (ref $s2->{Subject}, 'ARRAY', 'Subject() - is NOT array ref');
is ($s2->{Subject}, 'Subject@example.com', 'Subject() - is correct value');

# SetSender()
ok ($s2->{SetSender}, 'SetSender() - exists');
isnt (ref $s2->{SetSender}, 'ARRAY', 'SetSender() - is NOT array ref');
is ($s2->{SetSender}, 'SetSender@example.com', 'SetSender() - is correct value');

# Body()
ok ($s2->{Body}, 'Body() - exists');
is (ref $s2->{Body}, 'ARRAY', 'Body() - is array ref');
is ($s2->{Body}->[0], 'para 1', 'Body() - para 1 is correct value');
is ($s2->{Body}->[1], 'para 2', 'Body() - para 2 is correct value');
is ($s2->{Body}->[2], 'para 3', 'Body() - para 3 is correct value');

# Say()
is ($s2->{Body}->[3], 'para 4', 'Say() - para 1 is correct value');
is ($s2->{Body}->[4], 'para 5', 'Say() - para 2 is correct value');
is ($s2->{Body}->[5], 'para 6', 'Say() - para 3 is correct value');

# Para()
is ($s2->{Body}->[6], 'para 7', 'Para() - para 1 is correct value');
is ($s2->{Body}->[7], 'para 8', 'Para() - para 2 is correct value');
is ($s2->{Body}->[8], 'para 9', 'Para() - para 3 is correct value');

# Attach()
ok ($s2->{Attach}, 'Attach() - exists');
is (ref $s2->{Attach}, 'ARRAY', 'Attach() - is array ref');
is ($s2->{Attach}->[0], './README', 'Attach() - README OK');
is ($s2->{Attach}->[1], './Changes', 'Attach() - Changes OK');
is ($s2->{Attach}->[2], './MANIFEST', 'Attach() - MANIFEST OK');

# Let's take a look at message()
my $msg = $s2->message();
ok ($msg, 'message() - exists');
ok (ref $msg, 'message() - is a reference');
ok ($msg->isa("MIME::Lite"), 'message() is a MIME::Lite() object');

my $s2tring = $msg->as_string();
like ($s2tring, qr/Cc: Cc\@example\.com/, 'string() - check Cc');
like ($s2tring, qr/Subject: Subject\@example\.com/, 'string() - check Subject');
like ($s2tring, qr/To: To\@example\.com/, 'string() - check To');
like ($s2tring, qr/Bcc: Bcc\@example\.com/, 'string() - check Bcc');
like ($s2tring, qr/From: From\@example\.com/, 'string() - check From');
like ($s2tring, qr/This is a multi-part message in MIME format/, 'string() - check Multipart');


#### NOW LET'S TRY OUT THE SAME THING, BUT WITH TEMPLATING (xmldata, yamldata)

# new()
$s2  = Synapse::MailSender->new();
$s2->loadxml ($xmldata, yaml => $yaml);
ok ($s2, 'new() - exists');
ok ($s2->isa ('Synapse::MailSender'), 'new() - is Synapse::MailSender');

# From()
ok ($s2->{From}, 'From() - exists');
is (ref $s2->{From}, 'ARRAY', 'From() - is array ref');
is ($s2->{From}->[0], 'From@example.com', 'From() - is correct value');

# To()
ok ($s2->{To}, 'To() - exists');
is (ref $s2->{To}, 'ARRAY', 'To() - is array ref');
is ($s2->{To}->[0], 'To@example.com', 'To() - is correct value');

# Cc()
ok ($s2->{Cc}, 'Cc() - exists');
is (ref $s2->{Cc}, 'ARRAY', 'Cc() - is array ref');
is ($s2->{Cc}->[0], 'Cc@example.com', 'Cc() - is correct value');

# Bcc()
ok ($s2->{Bcc}, 'Bcc() - exists');
is (ref $s2->{Bcc}, 'ARRAY', 'Bcc() - is array ref');
is ($s2->{Bcc}->[0], 'Bcc@example.com', 'Bcc() - is correct value');

# Subject()
ok ($s2->{Subject}, 'Subject() - exists');
isnt (ref $s2->{Subject}, 'ARRAY', 'Subject() - is NOT array ref');
is ($s2->{Subject}, 'Subject@example.com', 'Subject() - is correct value');

# SetSender()
ok ($s2->{SetSender}, 'SetSender() - exists');
isnt (ref $s2->{SetSender}, 'ARRAY', 'SetSender() - is NOT array ref');
is ($s2->{SetSender}, 'SetSender@example.com', 'SetSender() - is correct value');

# Body()
ok ($s2->{Body}, 'Body() - exists');
is (ref $s2->{Body}, 'ARRAY', 'Body() - is array ref');
is ($s2->{Body}->[0], 'para 1', 'Body() - para 1 is correct value');
is ($s2->{Body}->[1], 'para 2', 'Body() - para 2 is correct value');
is ($s2->{Body}->[2], 'para 3', 'Body() - para 3 is correct value');

# Say()
is ($s2->{Body}->[3], 'para 4', 'Say() - para 1 is correct value');
is ($s2->{Body}->[4], 'para 5', 'Say() - para 2 is correct value');
is ($s2->{Body}->[5], 'para 6', 'Say() - para 3 is correct value');

# Para()
is ($s2->{Body}->[6], 'para 7', 'Para() - para 1 is correct value');
is ($s2->{Body}->[7], 'para 8', 'Para() - para 2 is correct value');
is ($s2->{Body}->[8], 'para 9', 'Para() - para 3 is correct value');

# Attach()
ok ($s2->{Attach}, 'Attach() - exists');
is (ref $s2->{Attach}, 'ARRAY', 'Attach() - is array ref');
is ($s2->{Attach}->[0], './README', 'Attach() - README OK');
is ($s2->{Attach}->[1], './Changes', 'Attach() - Changes OK');
is ($s2->{Attach}->[2], './MANIFEST', 'Attach() - MANIFEST OK');

# Let's take a look at message()
my $msg = $s2->message();
ok ($msg, 'message() - exists');
ok (ref $msg, 'message() - is a reference');
ok ($msg->isa("MIME::Lite"), 'message() is a MIME::Lite() object');

my $s2tring = $msg->as_string();
like ($s2tring, qr/Cc: Cc\@example\.com/, 'string() - check Cc');
like ($s2tring, qr/Subject: Subject\@example\.com/, 'string() - check Subject');
like ($s2tring, qr/To: To\@example\.com/, 'string() - check To');
like ($s2tring, qr/Bcc: Bcc\@example\.com/, 'string() - check Bcc');
like ($s2tring, qr/From: From\@example\.com/, 'string() - check From');
like ($s2tring, qr/This is a multi-part message in MIME format/, 'string() - check Multipart');
Test::More::done_testing();


__DATA__
<Message>
  <From petal:condition="true:yaml/user/from" petal:repeat="from yaml/user/from" petal:content="from">Foo</From>
  <To petal:condition="true:yaml/user/to" petal:repeat="to yaml/user/to" petal:content="to">Foo</To>
  <Cc petal:condition="true:yaml/user/cc" petal:repeat="cc yaml/user/cc" petal:content="cc">Foo</Cc>
  <Bcc petal:condition="true:yaml/user/bcc" petal:repeat="bcc yaml/user/bcc" petal:content="bcc">Foo</Bcc>
  <Subject petal:content="yaml/subject">Your account is over limit</Subject>
  <SetSender petal:content="yaml/setsender">Your account is over limit</SetSender>
  <Say petal:repeat="item yaml/para" petal:content="item">Dear Customer,</Say>
  <Attach petal:condition="true:yaml/attach" petal:repeat="item yaml/attach" petal:content="item">File</Attach>
</Message>

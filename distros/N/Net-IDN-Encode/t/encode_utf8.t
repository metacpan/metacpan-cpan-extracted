use utf8;
use strict;

BEGIN { binmode STDOUT, ':utf8'; binmode STDERR, ':utf8'; }

use Test::More tests => 32;
use Test::NoWarnings;

use Net::IDN::Encode qw(:all);

is(to_ascii('mueller'),'mueller');
is(to_ascii('xn--mller-kva'),'xn--mller-kva');
is(to_ascii('müller'),'xn--mller-kva');
is(to_ascii('中央大学'),'xn--fiq80yua78t');

is(to_unicode('mueller'),'mueller');
is(to_unicode('xn--mller-kva'),'müller');
is(to_unicode('müller'),'müller');
is(to_unicode('xn--fiq80yua78t'),'中央大学');

is(domain_to_ascii('mueller.example.com'),'mueller.example.com');
is(domain_to_ascii('xn--mller-kva.example.com'),'xn--mller-kva.example.com');
is(domain_to_ascii('müller.example.com'),'xn--mller-kva.example.com');
is(domain_to_ascii('中央大学.tw'),'xn--fiq80yua78t.tw');

is(domain_to_unicode('mueller.example.com'),'mueller.example.com');
is(domain_to_unicode('xn--mller-kva.example.com'),'müller.example.com');
is(domain_to_unicode('müller.example.com'),'müller.example.com');
is(domain_to_unicode('xn--fiq80yua78t.tw'),'中央大学.tw');

is(email_to_ascii('hans@mueller.example.com'),'hans@mueller.example.com');
is(email_to_ascii('hans@xn--mller-kva.example.com'),'hans@xn--mller-kva.example.com');
is(email_to_ascii('hans@müller.example.com'),'hans@xn--mller-kva.example.com');
is(email_to_ascii('test＠中央大学.tw'),'test@xn--fiq80yua78t.tw');
is(email_to_ascii(''), '');
is(email_to_ascii(undef), undef);
is(email_to_ascii('test'), 'test');

is(email_to_unicode('hans@mueller.example.com'),'hans@mueller.example.com');
is(email_to_unicode('hans＠mueller.example.com'),'hans＠mueller.example.com');
is(email_to_unicode('hans@xn--mller-kva.example.com'),'hans@müller.example.com');
is(email_to_unicode('hans＠xn--mller-kva.example.com'),'hans＠müller.example.com');
is(email_to_unicode('test@xn--fiq80yua78t.tw'),'test@中央大学.tw');
is(email_to_unicode(''),'');
is(email_to_unicode(undef), undef);
is(email_to_unicode('test'),'test');

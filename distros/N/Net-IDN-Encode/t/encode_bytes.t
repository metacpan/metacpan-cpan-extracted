use bytes;
use strict;

use Test::More tests => 24;
use Test::NoWarnings;

use Net::IDN::Encode qw(:all);

is(to_ascii('mueller'),'mueller');
is(to_ascii('xn--mller-kva'),'xn--mller-kva');
is(to_ascii('müller'),'xn--mller-kva');

is(to_unicode('mueller'),'mueller');
is(to_unicode('xn--mller-kva'),'müller');
is(to_unicode('müller'),'müller');

is(domain_to_ascii('mueller.example.com'),'mueller.example.com');
is(domain_to_ascii('xn--mller-kva.example.com'),'xn--mller-kva.example.com');
is(domain_to_ascii('müller.example.com'),'xn--mller-kva.example.com');

is(domain_to_unicode('mueller.example.com'),'mueller.example.com');
is(domain_to_unicode('xn--mller-kva.example.com'),'müller.example.com');
is(domain_to_unicode('müller.example.com'),'müller.example.com');

is(email_to_ascii('hans@mueller.example.com'),'hans@mueller.example.com');
is(email_to_ascii('hans@xn--mller-kva.example.com'),'hans@xn--mller-kva.example.com');
is(email_to_ascii('hans@müller.example.com'),'hans@xn--mller-kva.example.com');
is(email_to_ascii(''), '');
is(email_to_ascii(undef), undef);
is(email_to_ascii('test'), 'test');

is(email_to_unicode('hans@mueller.example.com'),'hans@mueller.example.com');
is(email_to_unicode('hans@xn--mller-kva.example.com'),'hans@müller.example.com');
is(email_to_unicode(''),'');
is(email_to_unicode(undef), undef);
is(email_to_unicode('test'),'test');

#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

name 'Net-SAML2';
all_from 'lib/Net/SAML2.pm';

requires 'XML::XPath';
requires 'XML::Generator';
requires 'Crypt::OpenSSL::RSA';
requires 'Crypt::OpenSSL::X509';
requires 'Crypt::OpenSSL::Random';
requires 'Crypt::OpenSSL::VerifyX509';
requires 'IO::Compress::RawDeflate';
requires 'IO::Uncompress::RawInflate';
requires 'File::Slurp';
requires 'URI';
requires 'MIME::Base64';
requires 'LWP::UserAgent';
requires 'DateTime::Format::XSD';
requires 'Moose';
requires 'MooseX::Types';
requires 'MooseX::Types::URI';
requires 'MooseX::Types::Common';
requires 'MooseX::Types::DateTime';

# XML::Sig's deps
requires 'Class::Accessor';
requires 'Digest::SHA1';
requires 'Crypt::OpenSSL::Bignum';
requires 'Crypt::OpenSSL::DSA';
requires 'XML::CanonicalizeXML';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

test_requires 'Test::More' => '0.88';
test_requires 'Dancer' => '1.2000';
test_requires 'WWW::Mechanize' => '1.66';
test_requires 'YAML';

resources
     license     => "http://dev.perl.org/licenses",
     bugtracker  => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SAML2",
     repository  => "http://github.com/chrisa/perl-Net-SAML2";

author_tests 't/author';

WriteAll;

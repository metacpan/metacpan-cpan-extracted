#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 13;

use_ok 'Mozilla::Mechanize';

my $uri = URI::file->new_abs('t/html/formbasics.html')->as_string;

########################################
# No arguments for constructor

isa_ok my $moz = Mozilla::Mechanize->new(), "Mozilla::Mechanize";
isa_ok $moz->agent, "Mozilla::Mechanize::Browser";

########################################
# Hashref for arguments

isa_ok my $moz2 = Mozilla::Mechanize->new({visible => 0}),
  "Mozilla::Mechanize";
isa_ok $moz2->agent, "Mozilla::Mechanize::Browser";

########################################
# Unsupported arguments mixed in

isa_ok my $moz3 = Mozilla::Mechanize->new({
    visible => 0,
    unsupported => 1
}), "Mozilla::Mechanize";
isa_ok $moz3->agent, "Mozilla::Mechanize::Browser";

########################################
# Supply our own onwarn/ondie handler

isa_ok my $moz4 = Mozilla::Mechanize->new(visible => 0,
                                          onwarn => sub { die @_ }),
  "Mozilla::Mechanize";
isa_ok $moz4->agent, "Mozilla::Mechanize::Browser";

ok $moz4->get( $uri ), "get( $uri )";
my $frm0 = eval { $moz4->form_number( 0 ) };  # form_number 0 becomes 1!
isa_ok $frm0, 'Mozilla::Mechanize::Form';

my $frm3 = eval { $moz4->form_number( 3 ) };
is $frm3, undef, "undef for invalid formnumber (high)";
like $@, qr/There is no form/, "select wrong form (high)";

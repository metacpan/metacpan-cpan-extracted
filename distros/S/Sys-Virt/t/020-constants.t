# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
  use_ok("Sys::Virt") or die;
}

is(Sys::Virt::CRED_USERNAME, 1, "CRED_USERNAME");
is(Sys::Virt::CRED_AUTHNAME, 2, "CRED_AUTHNAME");
is(Sys::Virt::CRED_LANGUAGE, 3, "CRED_LANGUAGE");
is(Sys::Virt::CRED_CNONCE, 4, "CRED_CNONCE");
is(Sys::Virt::CRED_PASSPHRASE, 5, "CRED_PASSPHRASE");
is(Sys::Virt::CRED_ECHOPROMPT, 6, "CRED_ECHOPROMPT");
is(Sys::Virt::CRED_NOECHOPROMPT, 7, "CRED_NOECHOPROMPT");
is(Sys::Virt::CRED_REALM, 8, "CRED_REALM");
is(Sys::Virt::CRED_EXTERNAL, 9, "CRED_EXTERNAL");

is(Sys::Virt::Domain::MEMORY_HARD_LIMIT, "hard_limit", "hard limit");
is(Sys::Virt::Domain::MEMORY_SOFT_LIMIT, "soft_limit", "soft limit");
is(Sys::Virt::Domain::MEMORY_MIN_GUARANTEE, "min_guarantee", "min guarantee");
is(Sys::Virt::Domain::MEMORY_SWAP_HARD_LIMIT, "swap_hard_limit", "swap hard limit");

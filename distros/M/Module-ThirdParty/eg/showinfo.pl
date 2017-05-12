#!/usr/bin/perl
use strict;
use Module::ThirdParty;

my $module = shift || die "needs a module name!";

if (is_3rd_party($module)) {
    my $info = module_information($module);
    print "$module is a known third-party Perl module\n",
          " -> included in $info->{name} ($info->{url})\n",
          " -> made by $info->{author} ($info->{author_url})\n"
} else {
    print "$module is not a known third-party Perl module\n"
}

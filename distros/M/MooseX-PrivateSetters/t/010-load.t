use strict;
use warnings;

#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use Data::Dump 'pp';

my @mods;
BEGIN {
    @mods = qw(
        MooseX::PrivateSetters
        MooseX::PrivateSetters::Role::Attribute
    );
}

use Test::More tests => scalar @mods;
use Moose;

use_ok $_ for @mods;

diag "testing MooseX::PrivateSetters ", MooseX::PrivateSetters->VERSION,
     " on perl $] and Moose ", Moose->VERSION;

# Should check %INC to make sure we've loaded the right modules but
# it's looking fairly hacky. So, I'll just leave the got/expectd
# string here as comments.

# what they shouldn't look like
#  "MooseX/PrivateSetters.pm"                => "/home/bri/lib/perl/MooseX/PrivateSetters.pm",
#  "MooseX/PrivateSetters/Role/Attribute.pm" => "/home/bri/lib/perl/MooseX/PrivateSetters/Role/Attribute.pm",

# what they should look like
#  "MooseX/PrivateSetters.pm"                => "/home/bri/git/+cpan-mods/MooseX-PrivateSetters/t/../lib/MooseX/PrivateSetters.pm",
#  "MooseX/PrivateSetters/Role/Attribute.pm" => "/home/bri/git/+cpan-mods/MooseX-PrivateSetters/t/../lib/MooseX/PrivateSetters/Role/Attribute.pm",

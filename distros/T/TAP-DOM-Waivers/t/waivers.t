#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;
use TAP::DOM;
use TAP::DOM::Waivers 'waive';

sub slurp {
        my ($filename) = @_;

        local $/;
        open (TAP, "<", $filename) or die "Cannot read $filename";
        return <TAP>;
}

# ==================================================

# define waivers and how to modify matching results
my $waivers = [
               {
                # a description of what the waiver is trying to achieve
                comment     => "Force all failed IPv6 stuff to true",
                match_dpath => [ "//lines//description[value =~ /IPv6/]/../is_ok[value eq 0]/.." ],
                patch       => {
                                is_ok        => 1,
                                has_todo     => 1,
                                is_actual_ok => 0,
                                explanation  => 'ignore failing IPv6 related tests',
                                directive    => 'TODO',
                               },
               },
              ];

my $metawaivers = [
                   {
                    # a description of what the waiver is trying to achieve
                    comment     => "Force all failed IPv6 stuff to true",
                    match_dpath => [ "//lines//description[value =~ /IPv6/]/../is_ok[value eq 0]/.." ],
                    metapatch   => {
                                    TODO  => 'ignore failing IPv6 related tests'
                                   },
                   },
                  ];

my $metawaivers_desc = [
                        {
                         # a description of what the waiver is trying to achieve
                         comment           => "Force all failed IPv6 stuff to true",
                         match_description => [ "IPv6" ],
                         metapatch         => {
                                               TODO  => 'ignore failing IPv6 related tests'
                                              },
                        },
                       ];

# ==================================================

my $tap3   = slurp( "t/failed_IPv6.tap" );
my $tapdom = TAP::DOM->new( tap => $tap3 );

my $comment = "failed IPv6";
#
is($tapdom->{summary}{todo},         0,      "$comment - summary todo");
is($tapdom->{summary}{total},        7,      "$comment - summary total");
is($tapdom->{summary}{passed},       5,      "$comment - summary passed");
is($tapdom->{summary}{failed},       2,      "$comment - summary failed");
is($tapdom->{summary}{exit},         0,      "$comment - summary exit");
is($tapdom->{summary}{wait},         0,      "$comment - summary wait");
is($tapdom->{summary}{status},       "FAIL", "$comment - summary status");
is($tapdom->{summary}{all_passed},   0,      "$comment - summary all_passed");
is($tapdom->{summary}{has_problems}, 1,      "$comment - summary has_problems");

# ==================================================

# the actual DOM patching
my $patched_tapdom = waive($tapdom, $waivers);
my $tapdom3        = TAP::DOM->new( tap => $patched_tapdom->to_tap );

$comment = "waivers for IPv6";
#
is($tapdom3->{summary}{todo},         2,      "$comment - summary todo");
is($tapdom3->{summary}{total},        7,      "$comment - summary total");
is($tapdom3->{summary}{passed},       7,      "$comment - summary passed");
is($tapdom3->{summary}{failed},       0,      "$comment - summary failed");
is($tapdom3->{summary}{exit},         0,      "$comment - summary exit");
is($tapdom3->{summary}{wait},         0,      "$comment - summary wait");
is($tapdom3->{summary}{status},       "PASS", "$comment - summary status");
is($tapdom3->{summary}{all_passed},   1,      "$comment - summary all_passed");
is($tapdom3->{summary}{has_problems}, 0,      "$comment - summary has_problems");

$comment = "original failed IPv6 unchanged";
#
is($tapdom->{summary}{todo},         0,      "$comment - summary todo");
is($tapdom->{summary}{total},        7,      "$comment - summary total");
is($tapdom->{summary}{passed},       5,      "$comment - summary passed");
is($tapdom->{summary}{failed},       2,      "$comment - summary failed");
is($tapdom->{summary}{exit},         0,      "$comment - summary exit");
is($tapdom->{summary}{wait},         0,      "$comment - summary wait");
is($tapdom->{summary}{status},       "FAIL", "$comment - summary status");
is($tapdom->{summary}{all_passed},   0,      "$comment - summary all_passed");
is($tapdom->{summary}{has_problems}, 1,      "$comment - summary has_problems");

# DOM patching with metapatch
my $patched_tapdom_meta = waive($tapdom, $metawaivers);
my $tapdom3a            = TAP::DOM->new( tap => $patched_tapdom_meta->to_tap );

$comment = "waivers for IPv6 with metapatch";
#
is($tapdom3a->{summary}{todo},         2,      "$comment - summary todo");
is($tapdom3a->{summary}{total},        7,      "$comment - summary total");
is($tapdom3a->{summary}{passed},       7,      "$comment - summary passed");
is($tapdom3a->{summary}{failed},       0,      "$comment - summary failed");
is($tapdom3a->{summary}{exit},         0,      "$comment - summary exit");
is($tapdom3a->{summary}{wait},         0,      "$comment - summary wait");
is($tapdom3a->{summary}{status},       "PASS", "$comment - summary status");
is($tapdom3a->{summary}{all_passed},   1,      "$comment - summary all_passed");
is($tapdom3a->{summary}{has_problems}, 0,      "$comment - summary has_problems");

# DOM patching with metapatch and match_description
my $patched_tapdom_meta_desc = waive($tapdom, $metawaivers_desc);
my $tapdom3b                 = TAP::DOM->new( tap => $patched_tapdom_meta_desc->to_tap );

$comment = "waivers for IPv6 with metapatch and match_description";
#
# here we match less strict, therefore we patch more entries to be "# TODO"
is($tapdom3b->{summary}{todo},         3,      "$comment - summary todo");
# the rest is the same
is($tapdom3b->{summary}{total},        7,      "$comment - summary total");
is($tapdom3b->{summary}{passed},       7,      "$comment - summary passed");
is($tapdom3b->{summary}{failed},       0,      "$comment - summary failed");
is($tapdom3b->{summary}{exit},         0,      "$comment - summary exit");
is($tapdom3b->{summary}{wait},         0,      "$comment - summary wait");
is($tapdom3b->{summary}{status},       "PASS", "$comment - summary status");
is($tapdom3b->{summary}{all_passed},   1,      "$comment - summary all_passed");
is($tapdom3b->{summary}{has_problems}, 0,      "$comment - summary has_problems");

# ==================================================

waive($tapdom, $waivers, { no_clone => 1 });
my $tapdom4        = TAP::DOM->new( tap => $tapdom->to_tap );

$comment = "original DOM changed in place";
#
is($tapdom4->{summary}{todo},         2,      "$comment - summary todo");
is($tapdom4->{summary}{total},        7,      "$comment - summary total");
is($tapdom4->{summary}{passed},       7,      "$comment - summary passed");
is($tapdom4->{summary}{failed},       0,      "$comment - summary failed");
is($tapdom4->{summary}{exit},         0,      "$comment - summary exit");
is($tapdom4->{summary}{wait},         0,      "$comment - summary wait");
is($tapdom4->{summary}{status},       "PASS", "$comment - summary status");
is($tapdom4->{summary}{all_passed},   1,      "$comment - summary all_passed");
is($tapdom4->{summary}{has_problems}, 0,      "$comment - summary has_problems");

done_testing();

# prove -e 'cat' t/failed_IPv6.tap

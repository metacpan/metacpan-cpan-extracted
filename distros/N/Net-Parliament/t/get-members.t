#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

use_ok 'Net::Parliament';

my $np = Net::Parliament->new( parliament => 40, session => 2 );
isa_ok $np, 'Net::Parliament';

Lite: {
    my $members = $np->members();
    my $member = shift @$members;
    is_deeply $member, {
        'caucus' => 'Conservative',
        'constituency' => 'Kootenay—Columbia',
        'member_url' => 'http://webinfo.parl.gc.ca/MembersOfParliament/ProfileMP.aspx?Key=128634&Language=E',
        member_id => 128634,
        'province' => 'British Columbia',
        'member_name' => 'Abbott, Jim (Hon.)'
    };
}

Full: {
    my $members = $np->members( extended => 1, limit => 1);
    my $member = shift @$members;
    is_deeply $member, {
        'profile_photo_url' =>
            'http://webinfo.parl.gc.ca/MembersOfParliament/Images/OfficialMPPhotos/40/AbbottJim_CPC.jpg',
        'caucus'       => 'Conservative',
        'telephone'    => '(613) 995-7246',
        'web site'     => 'http://www.jimabbott.ca/',
        'member_name'  => 'Abbott, Jim (Hon.)',
        'email'        => 'AbbotJ@parl.gc.ca',
        'constituency' => 'Kootenay—Columbia',
        'member_url' =>
            'http://webinfo.parl.gc.ca/MembersOfParliament/ProfileMP.aspx?Key=128634&Language=E',
        member_id   => 128634,
        'member_id' => '128634',
        'fax'       => '(613) 996-9923',
        'province'  => 'British Columbia'
    };
}

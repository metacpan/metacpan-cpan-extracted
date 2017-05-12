#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::ACNS::Test tests => undef;

my $cf_single;
{
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my ($ret, $msg) = $cf->Create(
        Name  => 'TextSingle',
        Queue => 'General',
        Type  => 'TextSingle',
    );
    ok($ret, "created Custom Field");
    $cf_single = $cf;
}

RT->Config->Set(ACNS =>
    Map      => { $cf_single->id => [qw(Case ID)] },
);

foreach my $file ( glob "t/data/*.eml" ) {
    my ( $status, $id  ) = RT::Test->send_via_mailgate(RT::Test->file_content($file));
    ok($id, 'created a ticket');

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load($id);
    is($ticket->FirstCustomFieldValue($cf_single->id), 'A1234567890', "CF value");
}

done_testing();


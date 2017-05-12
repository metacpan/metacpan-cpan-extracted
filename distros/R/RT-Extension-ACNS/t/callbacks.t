#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::ACNS::Test tests => undef;

my $cf;
{
    $cf = RT::CustomField->new( $RT::SystemUser );
    my ($ret, $msg) = $cf->Create(
        Name  => 'Text',
        Queue => 'General',
        Type  => 'FreeformMultiple',
    );
    ok($ret, "created Custom Field");
}

RT->Config->Set(ACNS =>
    Map => {
        $cf->id => sub {
            my %args = @_;
            return () unless exists $args{'Data'}{'Source'};
            my $source = $args{'Data'}{'Source'};
            my @res = (
                $source->{'Type'}, @{ $source->{'SubType'} }{'BaseType', 'Protocol'}
            );
            my %seen;
            return join ' ', grep !$seen{$_}++, map lc $_,
                grep defined && length, @res;
        },
    },
);

foreach my $file ( glob "t/data/*.eml" ) {
    my ( $status, $id  ) = RT::Test->send_via_mailgate(RT::Test->file_content($file));
    ok($id, 'created a ticket');

    my $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load($id);
    is_deeply(
        [ map $_->Content, @{ $ticket->CustomFieldValues($cf->id)->ItemsArrayRef } ],
        [ 'p2p bittorrent' ],
        "CF value is correct"
    );
}

done_testing();


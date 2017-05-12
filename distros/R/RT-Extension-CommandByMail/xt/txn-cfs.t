use strict;
use warnings;

use RT::Extension::CommandByMail::Test tests => undef;
my $test = 'RT::Extension::CommandByMail::Test';

my $cf_name = 'Test CF';
{
    my $cf = RT::CustomField->new( RT->SystemUser );
    my ($status, $msg) = $cf->Create(
        Name => $cf_name,
        Type => 'Freeform',
        MaxValues => 0,
        LookupType => RT::Transaction->CustomFieldLookupType,
    );
    ok $status, "created a CF" or diag "error: $msg";
    ($status, $msg) = $cf->AddToObject( RT::Queue->new( RT->SystemUser ) );
    ok $status, "applied CF" or diag "error: $msg";
}

my $test_ticket_id;

diag("txn CFs on create") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: test
From: root\@localhost

TxnCF{$cf_name}: foo
TxnCF{$cf_name}: bar
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");

    my @values = sort map $_->Content,
        @{ $obj->Transactions->First->CustomFieldValues( $cf_name )->ItemsArrayRef };
    is_deeply \@values, [qw(bar foo)];

    $test_ticket_id = $obj->id;
}

diag("txn CFs on update") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: [$RT::rtname #$test_ticket_id] test
From: root\@localhost

TxnCF{$cf_name}: foo
TxnCF{$cf_name}: bar
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");

    my $txns = $obj->Transactions;
    $txns->Limit( FIELD => 'Type', VALUE => 'Correspond' );

    my @values = sort map $_->Content,
        @{ $txns->First->CustomFieldValues( $cf_name )->ItemsArrayRef };
    is_deeply \@values, [qw(bar foo)];

    $test_ticket_id = $obj->id;
}

done_testing();

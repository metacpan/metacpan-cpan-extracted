#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 4;

BEGIN {
    use_ok 'Net::EGTS::SubRecord::Auth::DispatcherIdentity';
    use_ok 'Net::EGTS::Codes';
    use_ok 'Encode';
}

subtest 'base' => sub {
    plan tests => 9;

    my $subrecord = Net::EGTS::SubRecord::Auth::DispatcherIdentity->new(
        DID  => 123,
        DSCR => 'АБВ',
    );
    isa_ok $subrecord, 'Net::EGTS::SubRecord::Auth::DispatcherIdentity';

    my $bin = $subrecord->encode;
    ok $bin, 'encode';
    note $subrecord->as_debug;

    my $result = Net::EGTS::SubRecord::Auth::DispatcherIdentity->new( $bin );
    isa_ok $result, 'Net::EGTS::SubRecord::Auth::DispatcherIdentity';
    note $result->as_debug;

    my $result2 = Net::EGTS::SubRecord::Auth::DispatcherIdentity->new->decode( \$bin );
    isa_ok $result2, 'Net::EGTS::SubRecord::Auth::DispatcherIdentity';
    note $result2->as_debug;

    is $subrecord->SRT, EGTS_SR_DISPATCHER_IDENTITY, 'Subrecord Туре';
    is $subrecord->SRL, 8, 'Subrecord Length';

    is $subrecord->DT,      0,      'Dispatcher Type';
    is $subrecord->DID,     123,    'Dispatcher ID';
    is
        Encode::decode('CP1251', $subrecord->DSCR),
        'АБВ',
        'Description'
    ;
};

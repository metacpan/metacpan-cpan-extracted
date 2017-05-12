#!/usr/bin/perl -wT

use strict;

use Test::More tests => 29;

use Net::BGP::Peer qw( :generic ); # dump_hex

# Use
use_ok('Net::BGP::Update');

# Simple construction
my $empty = new Net::BGP::Update;
ok(ref $empty eq 'Net::BGP::Update','Simple construction');

# Complex construction
my $data = new Net::BGP::Update(
	NLRI		=>	[ '10.0.0.0/8', '192.168.0.0/16' ],
	Withdrawn	=>	[ '127.0.0.0/8' ],
	ASPath		=>	'(65001)'
	);
ok(ref $data eq 'Net::BGP::Update','Complex construction');

# Construction from NLRI
my $nlri = new Net::BGP::NLRI(
	ASPath		=>	'(65001)'
	);

my $data2 = new Net::BGP::Update($nlri,[ '10.0.0.0/8', '192.168.0.0/16' ],[ '127.0.0.0/8' ]);
ok(ref $data eq 'Net::BGP::Update','Construction from Net::BGP::NLRI');

# Copying
my $cloneX = clone Net::BGP::Update($data);
ok(ref $cloneX eq 'Net::BGP::Update','Clone construction');
my $clone = $cloneX->clone;
ok(ref $clone eq 'Net::BGP::Update','Cloning');

# NLRI
ok($clone->nlri->[0] eq '10.0.0.0/8','Accessor: NLRI');
$clone->nlri->[0] = '10.10.0.0/16';
ok($clone->nlri->[0] eq '10.10.0.0/16','Accessor: NLRI reference');
$clone->nlri(['10.0.10.0/24']);
ok($clone->nlri->[0] eq '10.0.10.0/24','Accessor: NLRI modifyer');

# Withdrawn
ok($clone->withdrawn->[0] eq '127.0.0.0/8','Accessor: Withdrawn');
$clone->withdrawn->[0] = '127.0.0.0/16';
ok($clone->withdrawn->[0] eq '127.0.0.0/16','Accessor: Withdrawn reference');
$clone->withdrawn(['127.0.0.0/8']);
ok($clone->withdrawn->[0] eq '127.0.0.0/8','Accessor: Withdrawn modifyer');

# AS Path (sample of inherited method)
ok($clone->as_path->asstring eq '(65001)','Accessor: AS Path (inherited)');
$clone->as_path->prepend_confed(65000);
ok($clone->as_path->asstring eq '(65000 65001)','Accessor: AS Path reference (inherited)');
$clone->as_path('(65001)');
ok($clone->as_path->asstring eq '(65001)','Accessor: AS Path modifyer (inherited)');

# ashash

my $hash = $clone->ashash;
ok(exists $hash->{'127.0.0.0/8'} && ! defined $hash->{'127.0.0.0/8'},'Accessor: As HASH Withdrawn');
ok($hash->{'10.0.10.0/24'}->as_path->asstring eq '(65001)','Accessor: As HASH NLRI');

# Comparison
my $clone1 = $data->clone;
my $clone2 = $data->clone;
my $clone3 = $data->clone;
$clone1->as_path->prepend_confed(65000); # Modify NLRI (parrent)
push(@{$clone2->nlri},'172.16.0.0/24'); # Modify Update (self)
ok($data ne $clone1,'Comparison: Not equal (ne) 1');
ok($data ne $clone2,'Comparison: Not equal (ne) 2');
ok($data eq $clone3,'Comparison: Equal     (eq) 1');
ok($data eq $data2 ,'Comparison: Equal     (eq) 2');

# Encoding / Decoding
my @msgs;
push(@msgs, [ qw (
	00 00 00 14  40 01 01 00  40 02 06 02  02 FD EB FD
        EA 40 03 04  0A FF 67 01  18 0A 02 01
	) ]);
push(@msgs, [ qw (
	00 00 00 2F  40 01 01 00  40 02 0C 03  05 FD F4 FD
	F3 FD F3 FD  F5 FD F5 40  03 04 0A 00  00 01 80 04
	04 00 00 00  00 40 05 04  00 00 00 64  C0 08 04 00
	00 00 64 1E  0A 00 22 00  1E 0A FF 03  00 1E 0A FF
	04 00 1E 0A  FF 67 00 
	) ]);
push(@msgs, [ qw (
	00 00 00 2B  40 01 01 00  40 02 08 03  03 FD F3 FD
	F5 FD F5 40  03 04 0A 00  00 04 80 04  04 00 00 00
	00 40 05 04  00 00 00 64  C0 08 04 00  00 00 64 1E
	0A 00 22 00  1E 0A FF 03  00 1E 0A FF  04 00 1E 0A
	FF 67 00
	) ]);

# withdraw 1.2.3.0/24
push (@msgs, [qw (
        00 04
        18 01 02 03
        00 00
        ) ]);

my $i = 0;
foreach my $list (@msgs)
{
    ++$i;
    my $msg = join('',map { pack('H2',$_); } @{$list});

    my $update = eval { Net::BGP::Update->_new_from_msg($msg) };
    if ($@)
    {
        my $msg = notif_msg($@);
        ok(0, "decode(msg $i) failed: $msg");
        next;
    }

    my $recode = eval { $update->_encode_message };
    if ($@)
    {
        my $msg = notif_msg($@);
        ok(0, "encode(msg $i) failed: $msg");
        next;
    }

    ok($msg eq $recode, "msg = encode(decode(msg)) $i");
 };

sub notif_msg {
    my $n = shift;

    if (UNIVERSAL::isa($n, 'Net::BGP::Notification'))
    {
        my $code    = $n->error_code;
        my $subcode = $n->error_subcode;
        return "notification code $code, subcode $subcode";
    }
    else
    {
        return $n;
    }
}


# This is a list of array references
#  The array references contain three elements:
#   0 -> Raw message (hex byte strings in an array ref)
#   1 -> Proper AS path to find in the message
#   2 -> Should encode pass (true if should pass, false if
#        we expect a failure)
#   3 -> Description of what this pattern tests
my @src;

push @src, [
    [ qw (
        00 00 00 1D  40 01 01 00  40 02 06 02  02 FD EB 5B
        A0 40 03 04  0A FF 67 01  C0 11 06 02  01 FA 56 EA
        00 18 0A 02  01
    ) ],
    '65003 4200000000',
    1,
    'AS4_PATH without partial set'
];

push @src, [
    [ qw (
        00 00 00 1D  40 01 01 00  40 02 06 02  02 FD EB 5B
        A0 40 03 04  0A FF 67 01  E0 11 06 02  01 FA 56 EA
        00 18 0A 02  01
    ) ],
    '65003 4200000000',
    1,
    'AS4_PATH with partial set'
];

push @src, [
    [ qw (
        00 00 00 1D  40 01 01 00  40 02 06 02  02 FD EB 5B
        A0 40 03 04  0A FF 67 01  EF 11 06 02  01 FA 56 EA
        00 18 0A 02  01
    ) ],
    '65003 4200000000',
    1,
    'AS4_PATH with partial set and bogus reserved flags'
];

push @src, [
    [ qw (
        00 00 00 1D  40 01 01 00  60 02 06 02  02 FD EB 5B
        A0 40 03 04  0A FF 67 01  EF 11 06 02  01 FA 56 EA
        00 18 0A 02  01
    ) ],
    '65003 4200000000',
    undef,
    'Well known attribute with partial set is invalid'
];

foreach my $ele (@src) {
    my ($hex, $path, $pass, $desc) = @{$ele};

    my $msg = join('',map { pack('H2',$_); } @{$hex});
    
    my $update = eval { Net::BGP::Update->_new_from_msg($msg) };
    if ($@) {
        if ($pass) {
            # We expected a pass
            my $msg = notif_msg($@);
            ok(0, "encode (msg $desc) failed: $msg");
            next;
        } else {
            # We expected a fail!
            ok(1, "encode (msg $desc) failed as expected: $msg");
            next;
        }
    }

    ok(
        ( $update->as_path->as_string() eq $path ),
        "$desc AS Path ".($update->as_path->as_string()). " eq $path"
    );

}

__END__

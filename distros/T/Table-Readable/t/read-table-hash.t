use FindBin '$Bin';
use lib "$Bin";
use TRTest;

# Test basic operation

my $hash = read_table_hash ("$Bin/test-hash.txt", 'id');
is ($hash->{moo}{ja}, 'モー', "Got correct value for moo ja");
is ($hash->{cola}{en}, 'Cola', "Got correct value for cola en");

my (undef, $order) = read_table_hash ("$Bin/test-hash.txt", 'id');

is_deeply ($order, [qw!moo fruit cola!], "Got order of keys");

# Test failures

{
    my $warnings;
    local $SIG{__WARN__} = sub {
	$warnings = "@_";
    };
    my $hash = read_table_hash ("$Bin/test-hash-collide.txt", 'id');
    ok ($warnings, "Got warning with hash collisions");
    like ($warnings, qr!not unique!, "Got right warning");
}

{
    my $warnings;
    local $SIG{__WARN__} = sub {
	$warnings = "@_";
    };
    my $hash = read_table_hash ("$Bin/test-hash-missing.txt", 'id');
    ok ($warnings, "Got warning with hash key missing from elements");
    like ($warnings, qr!No id entry!, "Got right warning");
}

done_testing ();

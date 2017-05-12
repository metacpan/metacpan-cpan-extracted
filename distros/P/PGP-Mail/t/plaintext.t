use PGP::Mail;

print "1..4\nok 1\n";

my $data=join "",<DATA>;
close DATA;

my $hash={
	"no_options" => 1,
	"extra_args" =>
	    [
		"--no-default-keyring",
		"--keyring" => "t/mbm-pgp.pub",
		"--secret-keyring" => "t/mbm-pgp.sec",
		"--keyserver-options" => "no-auto-key-retrieve",
	    ],
	"always_trust" => 1,
	};

my $pgp=new PGP::Mail($data, $hash);

if($pgp->status ne "unverified") {
    print "not ";
}
print "ok 2\n";

if($pgp->keyid ne "0x0000000000000000") {
    print "not ";
}
print "ok 3\n";

my $sigdata=
    "This is a test message, it should be totally unsigned.\n";

if($pgp->data ne $sigdata) {
    print "not ";
}
print "ok 4\n";

__DATA__
From: Matthew Byng-Maddick <mbm@example.com>
To: Testing <test@example.com>
Subject: a test

This is a test message, it should be totally unsigned.

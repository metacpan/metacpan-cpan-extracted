use warnings; use strict;
use Test::More tests => 21;

use Object::Import;

BEGIN { 
	$::W1 = 0;
	$SIG{__WARN__} = sub { 
		my($t) = @_;
		if ($t =~ /\Awarning: Object::Import cannot find methods of /) 
			{ $::W1++; } 
		else
			{ warn $t; }
	};
}


sub greet { "sorry" };

{ 
no strict "refs"; 
*{"=k::greet"} = sub { "hello" }; 
}


{
	{
	no strict "refs";
	*{"|m::crazy"} = sub { $::crazy_pkg_allowed++; };
	}
	$::crazy_ok = eval { "|m"->crazy(); 1 };
	$::crazy_err = $@;
	is(!!$::crazy_ok, !!$::crazy_pkg_allowed, "punctuation package method ran iff call not died");
	is(!!$::crazy_ok, !$::crazy_err, "punctuation package method ran iff no exception");
	SKIP: {
	$::crazy_ok and skip "punctuation package method call allowed", 2;
	like($::crazy_err, qr/\ACan't call method "crazy" without a package or object reference /, "punctuation package method correct error message");
	cmp_ok($], "<", 5.0170059, "punctuation package allowed on new enough perl");
	}
	SKIP: {
	!$::crazy_ok and skip "punctuation package method call not allowed", 1;
	cmp_ok(5.0160015, "<", $], "punctuation package name allowed only on new perl");
	}
}

is($::W1, 0, "no warn 0");

{
package G0;
use Test::More;

for my $testrec (
	[["hello"], "unblessed ref"],
	["hello", "nonexistant package"],
	["!", "invalid string"],
	["", "empty string"],
	["=k", "package with wrong name", $::crazy_ok],
) {
	my($obj, $desc, $expect) = @$testrec;
	my %n;
	
	import Object::Import $obj, savenames => \%n;

	is_deeply(\%n, $expect ? {"greet" => 1} : {}, ($expect ? "one" : "no") . " import from $desc");
	is(exists(&greet), !!$expect, "G0.1 !exi&greet from $desc");
	is($::W1, 0+!$expect, "warnt $desc");
	$::W1 = 0;
}
}

__END__

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Deprecations;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Deprecations->new;
isa_ok($check, 'Test::CPAN::Health::Check::Deprecations');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'deprecations', 'id');
is($check->name,     'Deprecations', 'name');
is($check->weight,   4,              'weight');
is($check->category, 'quality',      'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_lib_pm {
	my ($tmp, $filename, $content) = @_;
	my $lib = File::Spec->catdir($tmp, 'lib');
	make_path($lib);
	my $path = File::Spec->catfile($lib, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
}

# ---------------------------------------------------------------------------
# No source files -> skip
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	is($result->status, 'skip', 'no source files -> skip');
}

# ---------------------------------------------------------------------------
# Clean modern code -> pass, score 100
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Modern.pm', <<'END');
package Modern;

use strict;
use warnings;

sub new { bless {}, shift }

sub check_type {
	my ($self, $obj, $class) = @_;
	return $obj->isa($class);
}

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'clean code -> pass');
	is($result->score,  100,    'clean code -> score 100');
	is($result->data->{affected}, 0, 'data: 0 affected files');
}

# ---------------------------------------------------------------------------
# File using UNIVERSAL::isa() as function -> warn/fail
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'OldStyle.pm', <<'END');
package OldStyle;

use strict;
use warnings;

sub check {
	my ($obj, $class) = @_;
	return UNIVERSAL::isa($obj, $class);
}

1;
END

	my $result = $check->run($dist);
	isnt($result->status, 'pass', 'UNIVERSAL::isa usage -> not pass');
	ok($result->data->{affected} > 0, 'data: affected files > 0');
	ok(@{ $result->details }, 'details list populated');
	like($result->details->[0], qr/UNIVERSAL::isa/i, 'detail names the offender');
}

# ---------------------------------------------------------------------------
# File using given/when -> warn/fail
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'GivenWhen.pm', <<'END');
package GivenWhen;

use strict;
use warnings;
use feature 'switch';

sub classify {
	my ($x) = @_;
	given ($x) {
		when (1) { return 'one' }
		default  { return 'other' }
	}
}

1;
END

	my $result = $check->run($dist);
	isnt($result->status, 'pass', 'given/when -> not pass');
	like($result->details->[0], qr/given/i, 'detail mentions given');
}

# ---------------------------------------------------------------------------
# File using $[ -> flagged
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'ArrayBase.pm', <<'END');
package ArrayBase;
use strict;
use warnings;
my $idx = $[ + 1;
1;
END

	my $result = $check->run($dist);
	isnt($result->status, 'pass', '$[ usage -> not pass');
	like($result->details->[0], qr/\$\[/, 'detail mentions $[');
}

# ---------------------------------------------------------------------------
# run() croaks on wrong argument type
# ---------------------------------------------------------------------------

throws_ok(
	sub { $check->run('not a dist') },
	qr/must be a Test::CPAN::Health::Distribution/,
	'run() croaks on non-Distribution argument',
);

# ---------------------------------------------------------------------------
# Result is a proper Result object
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'deprecations', 'result carries correct check_id');
}

done_testing;

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Perlcritic;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Perlcritic->new;
isa_ok($check, 'Test::CPAN::Health::Check::Perlcritic');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'perlcritic', 'id');
is($check->name,     'Perl::Critic', 'name');
is($check->weight,   6,             'weight');
is($check->category, 'quality',     'category');

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
# Clean file at severity 3 -> pass, score 100
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Clean.pm', <<'END');
package Clean;

use strict;
use warnings;

our $VERSION = '1.0';

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'clean code -> pass');
	is($result->score,  100,    'clean code -> score 100');
	is($result->data->{total}, 1, 'data: 1 file analysed');
	is($result->data->{clean}, 1, 'data: 1 clean file');
}

# ---------------------------------------------------------------------------
# File with violations -> score drops
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();

	# Bareword filehandle is a severity-4 violation and indirect object syntax
	# severity-4 too.  Use an eval{die} pattern which is severity-3.
	write_lib_pm($tmp, 'Messy.pm', <<'END');
package Messy;
use strict;
use warnings;
eval { die 'boom' };
if ($@) { die $@ }
1;
END

	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'perlcritic', 'check_id is perlcritic');
	ok(defined $result->score, 'score is defined');
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
	is($result->check_id, 'perlcritic', 'result carries correct check_id');
}

done_testing;

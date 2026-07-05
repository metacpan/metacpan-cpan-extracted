use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::DeclaredDeps;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::DeclaredDeps->new;
isa_ok($check, 'Test::CPAN::Health::Check::DeclaredDeps');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'declared_deps',          'id');
is($check->name,     'Declared Dependencies',  'name');
is($check->weight,   5,                        'weight');
is($check->category, 'packaging',              'category');

# ---------------------------------------------------------------------------
# Test infrastructure helpers
# ---------------------------------------------------------------------------

sub make_dist_with_meta {
	my (%prereqs) = @_;
	my $tmp = tempdir(CLEANUP => 1);

	my $prereq_json = '';
	if (%prereqs) {
		my @pairs = map { qq{"$_":"$prereqs{$_}"} } sort keys %prereqs;
		$prereq_json = '"runtime":{"requires":{' . join(',', @pairs) . '}}';
	}

	open my $fh, '>', File::Spec->catfile($tmp, 'META.json') or die $!;
	print {$fh} <<"JSON";
{
   "abstract" : "Test",
   "author"   : ["A <a\@example.com>"],
   "license"  : ["perl_5"],
   "meta-spec": { "url": "http://search.cpan.org/perldoc?CPAN::Meta::Spec", "version": 2 },
   "name"     : "My-Dist",
   "version"  : "1.00",
   "prereqs"  : { $prereq_json },
   "dynamic_config": 0
}
JSON
	close $fh;

	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

sub add_pm {
	my ($dist, $relpath, $content) = @_;
	my $full = File::Spec->catfile($dist->path, 'lib', $relpath);
	my ($vol, $dir) = File::Spec->splitpath($full);
	make_path(File::Spec->catpath($vol, $dir, ''));
	open my $fh, '>', $full or die $!;
	print {$fh} $content;
	close $fh;
	return;
}

# ---------------------------------------------------------------------------
# No META file -> skip
# ---------------------------------------------------------------------------

{
	my $tmp  = tempdir(CLEANUP => 1);
	my $dist = Test::CPAN::Health::Distribution->new(path => $tmp);

	my $result = $check->run($dist);
	is($result->status, 'skip', 'no META -> skip');
	like($result->summary, qr/META/, 'skip summary mentions META');
}

# ---------------------------------------------------------------------------
# No source files -> skip
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist_with_meta();
	my $result = $check->run($dist);
	is($result->status, 'skip', 'no source files -> skip');
}

# ---------------------------------------------------------------------------
# All declared -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta('Foo::Bar' => 0, 'Baz::Qux' => '1.0');

	# .pm that uses exactly the declared deps
	add_pm($dist, 'My/Dist.pm', <<'PM');
package My::Dist;
use strict;
use warnings;
use Foo::Bar;
use Baz::Qux;
1;
PM

	my $result = $check->run($dist);
	is($result->status, 'pass', 'all declared -> pass');
	is($result->score,  100,    'all declared -> score 100');
	like($result->summary, qr/declared/, 'summary mentions declared');
}

# ---------------------------------------------------------------------------
# One undeclared dep -> warn or fail, details list it
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta('Foo::Bar' => 0);

	# Uses Foo::Bar (declared) and Undeclared::Module (not declared)
	add_pm($dist, 'My/Dist.pm', <<'PM');
package My::Dist;
use strict;
use Foo::Bar;
use Undeclared::Module;
1;
PM

	my $result = $check->run($dist);
	isnt($result->status, 'pass', 'undeclared dep -> not pass');
	ok($result->score < 100,      'undeclared dep -> score < 100');
	my @details = @{ $result->details };
	ok(grep { /Undeclared::Module/ } @details, 'details list the undeclared module');
	ok(!grep { /Foo::Bar/ } @details, 'declared module not in details');
}

# ---------------------------------------------------------------------------
# Pragmas and core modules are not flagged
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta();

	# Uses only pragmas and core modules -- nothing should be flagged
	add_pm($dist, 'My/Clean.pm', <<'PM');
package My::Clean;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use File::Spec;
use POSIX qw(floor);
1;
PM

	my $result = $check->run($dist);
	# Should be pass (all core/pragma) or skip (no external deps)
	ok($result->status eq 'pass' || $result->status eq 'skip',
		'core-only source -> pass or skip (no external undeclared deps)');
}

# ---------------------------------------------------------------------------
# Lowercase-only module names (pragmas) are not flagged
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta();

	add_pm($dist, 'My/Pragmas.pm', <<'PM');
package My::Pragmas;
use strict;
use warnings;
use autodie qw(:all);
use utf8;
use feature qw(say);
use constant PI => 3.14159;
use parent 'Exporter';
1;
PM

	my $result = $check->run($dist);
	ok($result->status eq 'pass' || $result->status eq 'skip',
		'pragma-only source is not flagged');
}

# ---------------------------------------------------------------------------
# POD code examples with 'use' statements are not counted
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta('Real::Dep' => 0);

	# POD contains "use InPodOnly" which must NOT be flagged
	add_pm($dist, 'My/Pod.pm', <<'PM');
package My::Pod;
use strict;
use Real::Dep;

=head1 SYNOPSIS

    use InPodOnly;

=cut

1;
PM

	my $result = $check->run($dist);
	is($result->status, 'pass', 'use inside POD block is not flagged');
}

# ---------------------------------------------------------------------------
# Comment lines with 'use' are not counted
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta('Real::Dep' => 0);

	add_pm($dist, 'My/Comments.pm', <<'PM');
package My::Comments;
use strict;
use Real::Dep;
# use Commented::Out;
1;
PM

	my $result = $check->run($dist);
	is($result->status, 'pass', "commented-out 'use' is not flagged");
}

# ---------------------------------------------------------------------------
# version requires (require 5.014) are not flagged
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta();

	add_pm($dist, 'My/Version.pm', <<'PM');
package My::Version;
require 5.014;
use strict;
1;
PM

	my $result = $check->run($dist);
	ok($result->status eq 'pass' || $result->status eq 'skip',
		'require 5.014 is not flagged as undeclared dep');
}

# ---------------------------------------------------------------------------
# Internal (same-distribution) modules are not flagged
# ---------------------------------------------------------------------------

{
	my $dist = make_dist_with_meta();

	# My-Dist internally uses My::Dist::Helper -- should not flag it
	add_pm($dist, 'My/Dist.pm', <<'PM');
package My::Dist;
use strict;
use My::Dist::Helper;
1;
PM
	add_pm($dist, 'My/Dist/Helper.pm', "package My::Dist::Helper; 1;\n");

	# META name is "My-Dist" => namespace "My::Dist"
	my $result = $check->run($dist);
	ok($result->status eq 'pass' || $result->status eq 'skip',
		'internal module use is not flagged');
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
	my $dist   = make_dist_with_meta();
	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'declared_deps', 'result carries correct check_id');
}

done_testing;

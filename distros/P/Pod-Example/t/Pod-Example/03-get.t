use strict;
use warnings;

use English qw(-no_match_vars);
use File::Object;
use Pod::Example qw(get);
use Test::More 'tests' => 15;
use Test::NoWarnings;

# Load module.
my $modules_dir;
BEGIN {
	$modules_dir = File::Object->new->up->dir('modules');
	unshift @INC, $modules_dir->s;	
}
use Ex1;

# Test.
my $ret = get('Ex1');
my $right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example.');

# Test.
$ret = get($modules_dir->file('Ex2.pm')->s);
is($ret, $right_ret, 'Example with explicit section.');

# Test.
$ret = get($modules_dir->file('Ex2.pm')->s, 'EXAMPLE');
is($ret, $right_ret, 'Example with explicit section.');

# Test.
$ret = get($modules_dir->file('Ex3.pm')->s);
is($ret, $right_ret, 'Example in POD as normal text (no verbatim).');

# Test.
$ret = get($modules_dir->file('Ex4.pm')->s);
is($ret, $right_ret, 'Example as EXAMPLE1.');

# Test.
$ret = get($modules_dir->file('Ex4.pm')->s, 'EXAMPLE');
is($ret, $right_ret, 'Example as EXAMPLE1 with explicit section.');

# Test.
$ret = get($modules_dir->file('Ex4.pm')->s, 'EXAMPLE', 1);
is($ret, $right_ret, 'Example as EXAMPLE1 with explicit example section '.
	'and number.');

# Test.
$ret = get($modules_dir->file('Ex4.pm')->s, 'EXAMPLE', 2);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Bar.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example as EXAMPLE2 with explicit example section '.
	'and number.');

# Test.
$ret = get($modules_dir->file('Ex5.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

 # Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example with inconsistent spaces on begin '.
	'of code');

# Test.
$ret = get($modules_dir->file('Ex6.pm')->s);
$right_ret = <<'END';
 use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Another example with inconsistent spaces on begin '.
	'of code');

# Test.
$ret = get($modules_dir->file('Ex1.pm')->s, 'NO_SECTION');
is($ret, undef, 'No right section.');

# Test.
eval {
	get('BAD_MODULE');
};
is($EVAL_ERROR, "Cannot open pod file or Perl module.\n",
	'Cannot open pod file or Perl module.');

# Test.
$ret = get($modules_dir->file('Ex7.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example with inner html code.');

# Test.
$ret = get($modules_dir->file('Ex8.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";

#   +-------------+
#   |  foo        |
#   |        bar  |
#   +-------------+
#
# ^^^^ Figure 1. ^^^^
END
chomp $right_ret;
is($ret, $right_ret, 'Example with inner text code.');

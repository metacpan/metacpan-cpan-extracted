use strict;
use warnings;

use English qw(-no_match_vars);
use File::Object;
use Pod::Example qw(get);
use Test::More 'tests' => 28;
use Test::NoWarnings;

# Load module.
my $modules_dir;
BEGIN {
	$modules_dir = File::Object->new->up->dir('modules');
	unshift @INC, $modules_dir->s;	
}

# Test.
my $ret = get('Ex1');
my $right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example from module (.pm).');

# Test.
$ret = get('Ex9');
is($ret, $right_ret, 'Example from module (.pod).');

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
$ret = get($modules_dir->file('Ex16.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example from EXAMPLE1 subsection in EXAMPLES.');

# Test.
$ret = get($modules_dir->file('Ex16.pm')->s, 'EXAMPLE', 1);
is($ret, $right_ret, 'Example from EXAMPLE1 subsection in EXAMPLES with '.
	'number.');

# Test.
$ret = get($modules_dir->file('Ex16.pm')->s, 'EXAMPLE', 2);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Bar.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example from EXAMPLE2 subsection in EXAMPLES with '.
	'number.');

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

#   +-------------+
#   |  foo        |
#   |        bar  |
#   +-------------+
#
# ^^^^ Figure 1. ^^^^

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example with inner text code.');

# Test.
$ret = get($modules_dir->file('Ex14.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example with skipped for html paragraph.');

# Test.
my $example_file;
($ret, $example_file) = get($modules_dir->file('Ex15.pm')->s);
is($ret, $right_ret, 'Example with skipped late filename comment.');
is($example_file, undef, 'Skip filename comment after example code.');

# Test.
($ret, $example_file) = get($modules_dir->file('Ex11.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example.');
is($example_file, 'example.pl', 'Parse example filename from comment (example.pl).');

# Test.
($ret, $example_file) = get($modules_dir->file('Ex12.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example.');
is($example_file, 'example_number-2.pl', 'Parse example filename from comment (example_number-2.pl).');

# Test.
($ret, $example_file) = get($modules_dir->file('Ex13.pm')->s);
$right_ret = <<'END';
use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is($ret, $right_ret, 'Example.');
is($example_file, undef, 'Parse example with skipping of comment.');

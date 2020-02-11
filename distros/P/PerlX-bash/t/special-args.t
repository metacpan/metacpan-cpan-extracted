use Test::Most 0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;
use TestUtilFuncs qw< throws_error >;


# remember: we use $^X because we *know* we can spawn that


# If we pass an argument that is an object which has a `basename` method, it should be treated as a
# filename (and quoted to protect it from being word-split by the shell).  Therefore, we need the
# following:
# 	*	A faux "path" class, with a `basename` method and stringification overloading.
# 	*	Some instances of that class with various special characters in the filenames.
# 	*	A Perl script which can print out its args so we can verify that the "filenames" were quoted
# 		properly.
# See, the filenames don't actually have to refer to physical files.  We just have to make sure that
# the command line is built in such a way that the filenames are being treated as single args and
# not being split on spaces, or having special characters like < or > or ; intercepted by `bash`.

# be careful not to use any single quotes here; we're not testing quoting for Perl proglets
my $proglet = 'print $ARGV[0]';
my ($str, $f);

# This class should get us what we want.
{
	package Path::Bmoogle;
	use overload '""' => sub { shift->{name} };

	sub new { my $class = shift; bless { name => shift }, $class }
	sub basename {}
}

foreach ( 'this is a test', 'this"test"is', "single'quote'test", 'test;pwd', 'test', '# test' )
{
	$f = Path::Bmoogle->new($_);
	$str = bash \string => $^X, -e => $proglet, $f;
	is $str, $_, "successful treatment as a filename: $_"
			or do { diag "command line:"; print STDERR '# '; bash -x => $^X, -e => 1, $f };
}

# This class lacks a basename method, so it shouldn't work.
# NOTE: "Not working" in this case means the object will stringify to the name, but it won't be
# autoquoted.  Therefore, whether it gets quoted or not depends on special characters.  To ensure it
# _won't_ be quoted, it needs to begin with a special character.  I haven't thought of a way to
# begin a string with a special char that actually produces an arg to be printed, but this is
# probably sufficient for now.
{
	package Path::IckyStickyPoo;
	sub new { my $class = shift; bless { name => shift }, $class }
	use overload '""' => sub { shift->{name} }
}
$f = Path::IckyStickyPoo->new("# test");
$str = bash \string => $^X, -e => $proglet, $f;
is $str, "", "no filename without `basename`"
		or do { diag "command line:"; print STDERR '# '; bash -x => $^X, -e => 1, $f };


# If an arg is a regex, that should stringify and quote as well.
my $re = qr/"This" (is) a* 'test'/;
$str = bash \string => $^X, -e => $proglet, $re, '2>'.File::Spec->devnull;
is $str, "$re", "regex quote just like filename";


done_testing;

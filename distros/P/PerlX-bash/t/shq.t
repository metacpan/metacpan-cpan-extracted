use Test::Most 0.25;

use PerlX::bash qw< bash shq >;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;


# Don't want to count on having anything in particular installed, so we'll make our own faux class
# that can stringify.
{
	package Foo;
	use overload '""' => sub { "Foo" };
	sub new { bless {}, __PACKAGE__ }
};


# MANUAL QUOTING

# not testing outer single-quoting specifically, as every single other test tests that implicitly

# stringification
is shq(Foo->new), q|'Foo'|, "shq stringifies";

# internal single quotes
is shq("don't"), q|'don'\''t'|, "shq handles internal quotes";

# constant
sub CONST () { 'XXX' }
is shq(CONST), q|'XXX'|, "shq doesn't choke on constants";


# implicit `-c` (shouldn't be quoted)
is bash(\string => "echo 'foo>bar'"), "foo>bar", "multi-arg single string treated appropriately";


# AUTOQUOTING

# a bunch of autoquoting stuff is tested by t/special-args.t (q.v.)

# args with special chars should get quoted
is bash(\string => echo => "foo>bar"), "foo>bar", "mid-word redirection handled appropriately";
is bash(\string => echo => "foo;bar"), "foo;bar", "mid-word command separator handled appropriately";

# unless the arg _starts_ with a special char, because that could be syntax
is bash(\string => '[[ -z "" ]]', '&&', echo => 'foo'), "foo", "syntax is not autoquoted";

# another exception: don't autoquote redirections, no matter how wacky they look
#
# While our code should work the same regardless of what version of `bash` we're dealing with, we
# don't want to try to run our unit tests on a version of `bash` that doesn't support the syntax
# we're checking, because it would be tricky to predict what the output would be.
# Ref for bash versions: https://wiki.bash-hackers.org/scripting/bashchanges
# Oblig SO ref for how to test version: https://askubuntu.com/questions/916976
my $major_version = bash \string => echo => '${BASH_VERSINFO[0]}';
my $minor_version = bash \string => echo => '${BASH_VERSINFO[1]}';
diag '';											# printing out the bash version info we collected
diag '#' x 20;										# this will help nail down CPAN Testers failures
diag "BASH VERSION: $major_version.$minor_version";
diag '#' x 20;
sub _is_bash_ge
{
	my ($major, $minor) = split(/\./, shift);
	return $major_version > $major || $major_version == $major && $minor_version  >= $minor;
}
is bash(\string => echo => 'foo', '4<'.File::Spec->devnull),  "foo", "fileno redirection is not autoquoted: <";
is bash(\string => echo => 'foo', '4>'.File::Spec->devnull),  "foo", "fileno redirection is not autoquoted: >";
is bash(\string => echo => 'foo', '4>>'.File::Spec->devnull), "foo", "fileno redirection is not autoquoted: >>";
is bash(\string => echo => 'foo', '4>&2'),                    "foo", "fileno redirection is not autoquoted: >&";
subtest 'here string' => sub
{
	my $min_version = "2.05";
	plan skip_all => "requires bash >= $min_version" unless _is_bash_ge($min_version);
	is bash(\string => echo => 'foo', '4<<<nothing'), "foo", "fileno redirection is not autoquoted: <<<";
};
subtest 'append all output' => sub
{
	my $min_version = "4.0";
	plan skip_all => "requires bash >= $min_version" unless _is_bash_ge($min_version);
	# since we're sending STDOUT off to null as well, this will produce no output
	is bash(\string => echo => 'foo', '&>>'.File::Spec->devnull), "", "redirection is not autoquoted: &>>";
};
subtest 'allocate and assign' => sub
{
	my $min_version = "4.1";
	plan skip_all => "requires bash >= $min_version" unless _is_bash_ge($min_version);
	is bash(\string => echo => 'foo', '{foo}>>'.File::Spec->devnull), "foo",
			"varname redirection is not autoquoted";
};
subtest 'allocate and assign to arrayvar' => sub
{
	my $min_version = "4.3";
	plan skip_all => "requires bash >= $min_version" unless _is_bash_ge($min_version);
	is bash(\string => echo => 'foo', '{foo[1]}>>'.File::Spec->devnull), "foo",
			"indexed varname redirection is not autoquoted";
};


done_testing;

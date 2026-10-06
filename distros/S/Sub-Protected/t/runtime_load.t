use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);

# Sub::Protected and the packages that use it loaded at run time (require),
# after CHECK has fired.  Each scenario runs in a child process with
# HARNESS_ACTIVE deleted, since the harness bypass would hide a leak.

plan skip_all => 'Run-time loading needs ${^GLOBAL_PHASE} (Perl 5.14)'
	if $] < 5.014;

my $dir = tempdir(CLEANUP => 1);

my %modules = (
	# Attribute form
	'RTAttr.pm' => <<'EOF',
package RTAttr;
use strict;
use warnings;
use Sub::Protected;
sub new { bless {}, shift }
sub _secret :Protected { 'attr secret' }
sub reveal { $_[0]->_secret }
1;
EOF
	'RTAttrKid.pm' => <<'EOF',
package RTAttrKid;
use strict;
use warnings;
require RTAttr;
our @ISA = ('RTAttr');
sub kid_reveal { $_[0]->_secret }
1;
EOF
	# Declarative form: import() called at the end, after the subs exist
	'RTDecl.pm' => <<'EOF',
package RTDecl;
use strict;
use warnings;
require Sub::Protected;
sub new { bless {}, shift }
sub _secret { 'decl secret' }
sub reveal { $_[0]->_secret }
Sub::Protected->import(qw(_secret));
1;
EOF
	'RTDeclKid.pm' => <<'EOF',
package RTDeclKid;
use strict;
use warnings;
require RTDecl;
our @ISA = ('RTDecl');
sub kid_reveal { $_[0]->_secret }
1;
EOF
);

for my $file (keys %modules) {
	my $path = File::Spec->catfile($dir, $file);
	open(my $fh, '>', $path) or die "$path: $!";
	print $fh $modules{$file};
	close $fh;
}

my $lib = File::Spec->rel2abs('lib');

# Quote a path as a single-quoted Perl string literal
sub perl_quote {
	my $s = shift;
	$s =~ s/([\\'])/\\$1/g;
	return "'$s'";
}

my $script_count = 0;

# Run $code in a child perl with warnings enabled; return (stdout, stderr).
# The code is written to a script file rather than passed with -e, since on
# Windows the arguments are joined into one command line, which mangles
# multi-line code and quotes.  The include paths go in the script for the
# same reason (and because they may contain spaces).
sub run_child {
	my $code = shift;

	my $script = File::Spec->catfile($dir, 'child' . ++$script_count . '.pl');
	open(my $fh, '>', $script) or die "$script: $!";
	print $fh 'use lib ', perl_quote($lib), ', ', perl_quote($dir), ";\n", $code;
	close $fh;

	local $ENV{HARNESS_ACTIVE};
	delete $ENV{HARNESS_ACTIVE};
	local $ENV{PERL5OPT};
	delete $ENV{PERL5OPT};

	my $err = gensym;
	my $pid = open3(my $in, my $out, $err, $^X, '-w', $script);
	close $in;
	my $stdout = do { local $/; <$out> };
	my $stderr = do { local $/; <$err> };
	waitpid($pid, 0);

	# The pipes are read raw, so on Windows lines end in CRLF
	for ($stdout, $stderr) {
		$_ //= q{};
		s/\r\n/\n/g;
	}
	return ($stdout, $stderr);
}

for my $form (['attribute', 'RTAttr'], ['declarative', 'RTDecl']) {
	my ($label, $class) = @{$form};
	my $kid = "${class}Kid";

	subtest "$label form loaded at run time" => sub {
		my ($out, $err) = run_child(<<"EOF");
require $class;
require $kid;
my \$obj = $class->new;
print eval { \$obj->_secret; 1 } ? "outside: LEAK\\n" : "outside: \$@";
print 'inside: ', \$obj->reveal, "\\n";
print 'subclass: ', $kid->new->kid_reveal, "\\n";
EOF

		like $out, qr/^outside: _secret\(\) is a protected method of $class and cannot be called from main at /m,
			'call from outside croaks with the usual message';
		like $out, qr/^inside: \w+ secret$/m, 'call from inside the package works';
		like $out, qr/^subclass: \w+ secret$/m, 'call from a run-time loaded subclass works';
		is $err, q{}, 'no warnings when loaded at run time';
	};
}

subtest 'string eval after CHECK' => sub {
	my ($out, $err) = run_child(<<'EOF');
require Sub::Protected;
eval q{
	package RTEval;
	sub new { bless {}, shift }
	sub _secret :Protected { 'eval secret' }
	sub reveal { $_[0]->_secret }
	1;
} or die $@;
my $obj = RTEval->new;
print eval { $obj->_secret; 1 } ? "outside: LEAK\n" : "outside: $@";
print 'inside: ', $obj->reveal, "\n";
EOF

	like $out, qr/^outside: _secret\(\) is a protected method of RTEval/m,
		'call from outside croaks';
	like $out, qr/^inside: eval secret$/m, 'call from inside works';
	is $err, q{}, 'no warnings';
};

done_testing();

use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "regular expressions for legal licenses",
  "author"         => ["Jonas Smedegaard (JONASS) <jonass\@cpan.org>"],
  "dynamic_config" => 0,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => ["Licensing", "Sourcecode"],
  "license"        => ["gpl_3"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Regexp-Pattern-License",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                          recommends => { "CPAN::Meta::Requirements" => "2.000" },
                          requires   => { "ExtUtils::MakeMaker" => 6.17 },
                        },
                        runtime => {
                          conflicts  => { "App::Licensecheck" => "<= v3.2.6" },
                          recommends => { "re::engine::RE2" => 0 },
                          requires   => { perl => 5 },
                        },
                        test => {
                          requires => {
                            "Regexp::Pattern" => 0,
                            "Test2::V0" => 0,
                            "Test::Regexp::Pattern" => 0.003,
                            "Test::Without::Module" => 0,
                            "Try::Tiny" => 0,
                          },
                        },
                      },
  "provides"       => {
                        "Regexp::Pattern::License"        => { file => "lib/Regexp/Pattern/License.pm", version => "v3.9.4" },
                        "Regexp::Pattern::License::Parts" => { file => "lib/Regexp/Pattern/License/Parts.pm", version => "v3.9.4" },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "https://bugs.debian.org/libregexp-pattern-license-perl" },
                        homepage     => "https://metacpan.org/pod/Regexp::Pattern::License",
                        license      => ["http://www.gnu.org/licenses/gpl-3.0.txt"],
                        repository   => {
                                          type => "git",
                                          web  => "https://salsa.debian.org/build-common-team/regexp-pattern-license.git",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Regexp-Pattern-License/project",
                      },
  "version"        => "v3.9.4",
  "x_breaks"       => { "App::Licensecheck" => "<= v3.2.6" },
  "x_help_wanted"  => ["documenter", "tester"],
};

my %dynamic_config;
for my $stage (keys %{$meta->{prereqs}})
{
	my $conflicts = $meta->{prereqs}{$stage}{conflicts} or next;
	eval { require CPAN::Meta::Requirements } or last;
	$conflicts = 'CPAN::Meta::Requirements'->from_string_hash($conflicts);
	
	for my $module ($conflicts->required_modules)
	{
		eval "require $module" or next;
		my $installed = eval(sprintf('$%s::VERSION', $module));
		$conflicts->accepts_module($module, $installed) or next;
		
		my $message = "\n".
			"** This version of $meta->{name} conflicts with the version of\n".
			"** module $module ($installed) you have installed.\n";
		die($message . "\n" . "Bailing out")
			if $stage eq 'build' || $stage eq 'configure';
		
		$message .= "**\n".
			"** It's strongly recommended that you update it after\n".
			"** installing this version of $meta->{name}.\n";
		warn("$message\n");
	}
}

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t" },
	%dynamic_config,
);

$WriteMakefileArgs{LICENSE} = $meta->{license}[0] if $EUMM >= 6.3001;

sub deps
{
	my %r;
	for my $stage (@_)
	{
		for my $dep (keys %{$meta->{prereqs}{$stage}{requires}})
		{
			next if $dep eq 'perl';
			my $ver = $meta->{prereqs}{$stage}{requires}{$dep};
			$r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
		}
	}
	\%r;
}

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
if ($EUMM >= 6.6303)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.5503)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build', 'test');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
elsif ($EUMM >= 6.52)
{
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime', 'build', 'test');	
}
else
{
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');	
}

{
	my ($minperl) = reverse sort(
		grep defined && /^[0-9]+(\.[0-9]+)?$/,
		map $meta->{prereqs}{$_}{requires}{perl},
		qw( configure build runtime )
	);
	
	if (defined($minperl))
	{
		die "Installing $meta->{name} requires Perl >= $minperl"
			unless $] >= $minperl;
		
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl
			if $EUMM >= 6.48;
	}
}


my $mm = WriteMakefile(%WriteMakefileArgs);

exit(0);


use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "detect source code license statements in a text string",
  "author"           => ["Jonas Smedegaard (JONASS) <jonass\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"         => ["Licensing", "Sourcecode"],
  "license"          => ["agpl_3"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "String-License",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          runtime => {
                            recommends => { "re::engine::RE2" => 0 },
                            requires   => {
                                            "Array::IntSpan"           => 0,
                                            "Feature::Compat::Class"   => 0.07,
                                            "List::Util"               => 1.45,
                                            "Log::Any"                 => 0,
                                            "namespace::clean"         => 0,
                                            "Path::Tiny"               => 0.062,
                                            "perl"                     => "5.020000",
                                            "Regexp::Pattern"          => "v0.2.12",
                                            "Regexp::Pattern::License" => "v3.4.0",
                                          },
                          },
                          test => {
                            recommends => {
                                            "File::BaseDir" => 0,
                                            "Regexp::Pattern::License" => "v3.9.0",
                                            "Software::LicenseUtils" => 0.104006,
                                            "YAML::XS" => 0,
                                          },
                            requires   => { "Test2::V0" => "0.000060", "Test::Without::Module" => 0 },
                          },
                        },
  "provides"         => {
                          "String::License"                 => { file => "lib/String/License.pm", version => "v0.0.11" },
                          "String::License::Naming"         => { file => "lib/String/License/Naming.pm", version => "v0.0.11" },
                          "String::License::Naming::Custom" => { file => "lib/String/License/Naming/Custom.pm", version => "v0.0.11" },
                          "String::License::Naming::SPDX"   => { file => "lib/String/License/Naming/SPDX.pm", version => "v0.0.11" },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => {
                                            web => "https://rt.cpan.org/Dist/Display.html?Queue=String-License",
                                          },
                          homepage     => "https://metacpan.org/pod/String::License",
                          license      => ["http://www.gnu.org/licenses/agpl-3.0.txt"],
                          repository   => {
                                            type => "git",
                                            web  => "https://salsa.debian.org/build-common-team/p5-string-license",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/String-License/project",
                        },
  "version"          => "v0.0.11",
  "x_help_wanted"    => ["tester", "documenter"],
  "x_static_install" => 1,
};

my %dynamic_config;

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


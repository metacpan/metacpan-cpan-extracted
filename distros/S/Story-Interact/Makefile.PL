use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "tools for writing (and reading) an interactive story",
  "author"             => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"           => [],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "Story-Interact",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                            runtime   => {
                                           recommends => { "String::Tagged::Markdown" => 0, "String::Tagged::Terminal" => 0 },
                                           requires   => {
                                                           "Bytes::Random::Secure" => 0,
                                                           "Carp"                  => 0,
                                                           "Compress::Bzip2"       => 0,
                                                           "CryptX"                => 0,
                                                           "DBD::SQLite"           => 0,
                                                           "DBI"                   => 0,
                                                           "Exporter::Shiny"       => 0,
                                                           "List::Util"            => 1.54,
                                                           "match::simple"         => 0,
                                                           "Module::Runtime"       => 0,
                                                           "Moo"                   => 0,
                                                           "namespace::clean"      => 0,
                                                           "perl"                  => 5.010001,
                                                           "Term::Choose"          => 0,
                                                           "Text::Wrap"            => 0,
                                                           "Types::Common"         => 0,
                                                           "Types::Path::Tiny"     => 0,
                                                           "URI::Query"            => 0,
                                                         },
                                         },
                            test      => {
                                           requires => {
                                             "Test2::Require::AuthorTesting" => 0,
                                             "Test2::Require::Module" => 0,
                                             "Test2::Tools::Spec" => 0,
                                             "Test2::V0" => 0,
                                           },
                                         },
                          },
  "provides"           => {
                            "Story::Interact"                        => { file => "lib/Story/Interact.pm", version => 0.001014 },
                            "Story::Interact::Analyze"               => { file => "lib/Story/Interact/Analyze.pm", version => 0.001014 },
                            "Story::Interact::Character"             => { file => "lib/Story/Interact/Character.pm", version => 0.001014 },
                            "Story::Interact::Harness"               => { file => "lib/Story/Interact/Harness.pm", version => 0.001014 },
                            "Story::Interact::Harness::Terminal"     => {
                                                                          file => "lib/Story/Interact/Harness/Terminal.pm",
                                                                          version => 0.001014,
                                                                        },
                            "Story::Interact::Harness::Test"         => { file => "lib/Story/Interact/Harness/Test.pm", version => 0.001014 },
                            "Story::Interact::Page"                  => { file => "lib/Story/Interact/Page.pm", version => 0.001014 },
                            "Story::Interact::PageSource"            => { file => "lib/Story/Interact/PageSource.pm", version => 0.001014 },
                            "Story::Interact::PageSource::DBI"       => { file => "lib/Story/Interact/PageSource/DBI.pm", version => 0.001014 },
                            "Story::Interact::PageSource::Dir"       => { file => "lib/Story/Interact/PageSource/Dir.pm", version => 0.001014 },
                            "Story::Interact::PageSource::Waterfall" => {
                                                                          file => "lib/Story/Interact/PageSource/Waterfall.pm",
                                                                          version => 0.001014,
                                                                        },
                            "Story::Interact::State"                 => { file => "lib/Story/Interact/State.pm", version => 0.001014 },
                            "Story::Interact::Syntax"                => { file => "lib/Story/Interact/Syntax.pm", version => 0.001014 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => { web => "https://github.com/tobyink/p5-story-interact/issues" },
                            homepage     => "https://story-interact.xlc.pl/",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => {
                                              type => "git",
                                              url  => "git://github.com/tobyink/p5-story-interact.git",
                                              web  => "https://github.com/tobyink/p5-story-interact",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/Story-Interact/project",
                          },
  "version"            => 0.001014,
  "x_provides_scripts" => {
                            "story-interact"            => { file => "bin/story-interact" },
                            "story-interact-analyze"    => { file => "bin/story-interact-analyze" },
                            "story-interact-dir2sqlite" => { file => "bin/story-interact-dir2sqlite" },
                          },
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/integration/*.t" },
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


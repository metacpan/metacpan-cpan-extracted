use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "mojolicious app to read interactive stories",
  "author"             => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"           => [],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "Story-Interact-WWW",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => {
                                           requires => { "ExtUtils::MakeMaker" => 6.17, "File::ShareDir::Install" => 0.02 },
                                         },
                            develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                            runtime   => {
                                           requires => {
                                             "Digest::SHA" => 0,
                                             "Mojo::ShareDir" => 0,
                                             "Mojolicious" => 0,
                                             "Nanoid" => 0,
                                             "perl" => "5.024000",
                                             "Story::Interact" => 0.001004,
                                             "Text::Markdown::Hoedown" => 0,
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
                            "Story::Interact::WWW" => { file => "lib/Story/Interact/WWW.pm", version => 0.001006 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => {
                                              web => "https://github.com/tobyink/p5-story-interact-www/issues",
                                            },
                            homepage     => "https://metacpan.org/release/Story-Interact-WWW",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => {
                                              type => "git",
                                              url  => "git://github.com/tobyink/p5-story-interact-www.git",
                                              web  => "https://github.com/tobyink/p5-story-interact-www",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/Story-Interact-WWW/project",
                          },
  "version"            => 0.001006,
  "x_provides_scripts" => { si_www => { file => "bin/si_www" } },
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/unit/Story/Interact/*.t" },
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


use File::ShareDir::Install;
install_share 'share';
{ package MY; use File::ShareDir::Install qw(postamble) };

my $mm = WriteMakefile(%WriteMakefileArgs);

exit(0);


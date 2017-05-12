use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "Base class and scripts for servers that serve RDF as Linked Data.",
  "author"             => ["Kjetil Kjernsmo <kjetilk\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.023, CPAN::Meta::Converter version 2.150005",
  "keywords"           => ["Semantic Web"],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "RDF-LinkedData",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            runtime => {
                              recommends => {
                                              "Config::ZOMG" => 0,
                                              "JSON" => 0,
                                              "Log::Any::Adapter" => 0,
                                              "Plack::Middleware::CrossOrigin" => 0,
                                              "Plack::Middleware::Expires" => 0,
                                              "RDF::Endpoint" => 0.05,
                                              "RDF::Generator::Void" => 0.04,
                                            },
                              requires   => {
                                              "Digest::MD5"               => 0,
                                              "Encode"                    => 0,
                                              "HTML::HTML5::Writer"       => 0,
                                              "HTTP::Headers"             => 0,
                                              "List::Util"                => 1.33,
                                              "Module::Load::Conditional" => 0,
                                              "Moo"                       => 0,
                                              "MooX::Log::Any"            => 0,
                                              "namespace::autoclean"      => 0.12,
                                              "perl"                      => 5.006,
                                              "Plack"                     => 0.9939,
                                              "RDF::Helper::Properties"   => "0.10",
                                              "RDF::NS::Curated"          => 0,
                                              "RDF::RDFa::Generator"      => 0.102,
                                              "RDF::Trine"                => 0.133,
                                              "Scalar::Util"              => 0,
                                              "Try::Tiny"                 => 0,
                                              "Types::Standard"           => 0,
                                              "URI"                       => 1.52,
                                              "URI::NamespaceMap"         => 0.32,
                                            },
                            },
                            test => {
                              requires => {
                                "Config::ZOMG"               => 0,
                                "FindBin"                    => 0,
                                "Log::Any::Adapter"          => 0,
                                "RDF::RDFa::Parser"          => 0,
                                "Test::Exception"            => 0,
                                "Test::JSON"                 => 0,
                                "Test::More"                 => 0.88,
                                "Test::RDF"                  => 1.16,
                                "Test::WWW::Mechanize::PSGI" => 0,
                              },
                            },
                          },
  "provides"           => {
                            "Plack::App::RDF::LinkedData" => { file => "lib/Plack/App/RDF/LinkedData.pm", version => 0.78 },
                            "RDF::LinkedData" => { file => "lib/RDF/LinkedData.pm", version => 0.78 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker    => { web => "https://github.com/kjetilk/RDF-LinkedData/issues" },
                            homepage      => "https://metacpan.org/release/RDF-LinkedData",
                            license       => ["http://dev.perl.org/licenses/"],
                            repository    => { type => "git", web => "https://github.com/kjetilk/RDF-LinkedData/" },
                            x_identifier  => "http://purl.org/NET/cpan-uri/dist/RDF-LinkedData/project",
                            x_IRC         => "irc://irc.perl.org/#perlrdf",
                            x_mailinglist => "http://lists.perlrdf.org/listinfo/dev",
                            x_wiki        => "http://wiki.perlrdf.org/",
                          },
  "version"            => 0.78,
  "x_contributors"     => [
                            "Gregory Todd Williams <gwilliams\@cpan.org>",
                            "Richard Lewis",
                            "Patrick Hochstenbach (HOCHSTEN) <patrick.hochstenbach\@gmail.com>",
                          ],
  "x_provides_scripts" => { "linked_data.psgi" => { file => "script/linked_data.psgi" } },
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

sub FixMakefile
{
	return unless -d 'inc';
	my $file = shift;
	
	local *MAKEFILE;
	open MAKEFILE, "< $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	my $makefile = do { local $/; <MAKEFILE> };
	close MAKEFILE or die $!;
	
	$makefile =~ s/\b(test_harness\(\$\(TEST_VERBOSE\), )/$1'inc', /;
	$makefile =~ s/( -I\$\(INST_ARCHLIB\))/ -Iinc$1/g;
	$makefile =~ s/( "-I\$\(INST_LIB\)")/ "-Iinc"$1/g;
	$makefile =~ s/^(FULLPERL = .*)/$1 "-Iinc"/m;
	$makefile =~ s/^(PERL = .*)/$1 "-Iinc"/m;
	
	open  MAKEFILE, "> $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	print MAKEFILE $makefile or die $!;
	close MAKEFILE or die $!;
}

my $mm = WriteMakefile(%WriteMakefileArgs);
FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');
exit(0);


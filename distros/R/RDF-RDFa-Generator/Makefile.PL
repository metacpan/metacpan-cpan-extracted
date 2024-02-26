use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "Generate data for RDFa serialization",
  "author"           => [
                          "Toby Inkster (TOBYINK) <tobyink\@cpan.org>",
                          "Kjetil Kjernsmo (KJETILK) <kjetilk\@cpan.org>",
                        ],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::KJETILK version 0.101, CPAN::Meta::Converter version 2.150010",
  "keywords"         => ["Semantic Web"],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "RDF-RDFa-Generator",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                          runtime   => {
                                         recommends => { "Attean" => 0.019, "RDF::NS" => 0, "RDF::Prefixes" => 0 },
                                         requires   => {
                                                         "Data::Dumper" => 0,
                                                         "Icon::FamFamFam::Silk" => 0,
                                                         "perl" => 5.008,
                                                         "RDF::NS::Curated" => "0.100",
                                                         "URI::NamespaceMap" => 1.06,
                                                         "XML::LibXML" => "1.60",
                                                       },
                                         suggests   => { "RDF::Trine" => 0.112 },
                                       },
                          test      => {
                                         requires => {
                                           "Attean"        => 0.019,
                                           "RDF::Prefixes" => 0,
                                           "Test::Modern"  => 0,
                                           "Test::More"    => 0.96,
                                           "Test::Output"  => 0,
                                         },
                                       },
                        },
  "provides"         => {
                          "RDF::RDFa::Generator"                     => { file => "lib/RDF/RDFa/Generator.pm", version => 0.204 },
                          "RDF::RDFa::Generator::HTML::Head"         => {
                                                                          file => "lib/RDF/RDFa/Generator/HTML/Head.pm",
                                                                          version => "0.201_01",
                                                                        },
                          "RDF::RDFa::Generator::HTML::Hidden"       => {
                                                                          file => "lib/RDF/RDFa/Generator/HTML/Hidden.pm",
                                                                          version => "0.201_01",
                                                                        },
                          "RDF::RDFa::Generator::HTML::Pretty"       => {
                                                                          file => "lib/RDF/RDFa/Generator/HTML/Pretty.pm",
                                                                          version => "0.201_01",
                                                                        },
                          "RDF::RDFa::Generator::HTML::Pretty::Note" => {
                                                                          file => "lib/RDF/RDFa/Generator/HTML/Pretty/Note.pm",
                                                                          version => "0.201_01",
                                                                        },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => {
                                            web => "https://github.com/kjetilk/p5-rdf-rdfa-generator/issues",
                                          },
                          homepage     => "https://metacpan.org/release/RDF-RDFa-Generator",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/kjetilk/p5-rdf-rdfa-generator.git",
                                            web  => "https://github.com/kjetilk/p5-rdf-rdfa-generator",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/RDF-RDFa-Generator/project",
                          x_IRC        => "irc://irc.perl.org/#perlrdf",
                        },
  "version"          => 0.204,
  "x_contributors"   => ["ZORAN <zoran\@cpan.org>"],
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


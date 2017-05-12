use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "an object-oriented interface for DOAP (Description of a Project) data",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 0,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.016, CPAN::Meta::Converter version 2.140640",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "RDF-DOAP",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       requires => {
                                         "Exporter::Tiny" => 0.026,
                                         "JSON" => "2.00",
                                         "List::MoreUtils" => 0,
                                         "match::simple" => 0.001,
                                         "Moose" => "2.0600",
                                         "MooseX::AttributeTags" => 0.001,
                                         "perl" => "5.010",
                                         "RDF::Trine" => "1.000",
                                         "Types::Standard" => 0.022,
                                       },
                                     },
                        test      => { requires => { "Test::LongString" => 0, "Test::More" => 0.96 } },
                      },
  "provides"       => {
                        "RDF::DOAP"                             => { file => "lib/RDF/DOAP.pm", version => 0.012 },
                        "RDF::DOAP::Change"                     => { file => "lib/RDF/DOAP/Change.pm", version => 0.012 },
                        "RDF::DOAP::Change::Addition"           => { file => "lib/RDF/DOAP/Change/Addition.pm", version => 0.012 },
                        "RDF::DOAP::Change::BackCompat"         => { file => "lib/RDF/DOAP/Change/BackCompat.pm", version => 0.012 },
                        "RDF::DOAP::Change::Bugfix"             => { file => "lib/RDF/DOAP/Change/Bugfix.pm", version => 0.012 },
                        "RDF::DOAP::Change::Documentation"      => { file => "lib/RDF/DOAP/Change/Documentation.pm", version => 0.012 },
                        "RDF::DOAP::Change::Packaging"          => { file => "lib/RDF/DOAP/Change/Packaging.pm", version => 0.012 },
                        "RDF::DOAP::Change::Regression"         => { file => "lib/RDF/DOAP/Change/Regression.pm", version => 0.012 },
                        "RDF::DOAP::Change::Removal"            => { file => "lib/RDF/DOAP/Change/Removal.pm", version => 0.012 },
                        "RDF::DOAP::Change::SecurityFix"        => { file => "lib/RDF/DOAP/Change/SecurityFix.pm", version => 0.012 },
                        "RDF::DOAP::Change::SecurityRegression" => {
                                                                     file => "lib/RDF/DOAP/Change/SecurityRegression.pm",
                                                                     version => 0.012,
                                                                   },
                        "RDF::DOAP::Change::Tests"              => { file => "lib/RDF/DOAP/Change/Tests.pm", version => 0.012 },
                        "RDF::DOAP::Change::Update"             => { file => "lib/RDF/DOAP/Change/Update.pm", version => 0.012 },
                        "RDF::DOAP::ChangeSet"                  => { file => "lib/RDF/DOAP/ChangeSet.pm", version => 0.012 },
                        "RDF::DOAP::Issue"                      => { file => "lib/RDF/DOAP/Issue.pm", version => 0.012 },
                        "RDF::DOAP::Person"                     => { file => "lib/RDF/DOAP/Person.pm", version => 0.012 },
                        "RDF::DOAP::Project"                    => { file => "lib/RDF/DOAP/Project.pm", version => 0.012 },
                        "RDF::DOAP::Repository"                 => { file => "lib/RDF/DOAP/Repository.pm", version => 0.012 },
                        "RDF::DOAP::Resource"                   => { file => "lib/RDF/DOAP/Resource.pm", version => 0.012 },
                        "RDF::DOAP::Types"                      => { file => "lib/RDF/DOAP/Types.pm", version => 0.012 },
                        "RDF::DOAP::Utils"                      => { file => "lib/RDF/DOAP/Utils.pm", version => 0.012 },
                        "RDF::DOAP::Version"                    => { file => "lib/RDF/DOAP/Version.pm", version => 0.012 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=RDF-DOAP" },
                        homepage     => "https://metacpan.org/release/RDF-DOAP",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-rdf-doap.git",
                                          web  => "https://github.com/tobyink/p5-rdf-doap",
                                        },
                        X_identifier => "http://purl.org/NET/cpan-uri/dist/RDF-DOAP/project",
                      },
  "version"        => 0.012,
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


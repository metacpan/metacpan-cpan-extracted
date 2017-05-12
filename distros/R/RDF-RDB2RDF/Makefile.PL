use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "map relational database to RDF declaratively",
  "author"         => [
                        "Toby Inkster <tobyink\@cpan.org>",
                        "TOBYINK <tobyink\@cpan.org>",
                      ],
  "dynamic_config" => 0,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.012, CPAN::Meta::Converter version 2.120921",
  "keywords"       => [
                        "DBI",
                        "Database",
                        "Direct Mapping",
                        "R2R",
                        "R2RML",
                        "RDB2RDF",
                        "RDBMS",
                        "RDF",
                        "SQL",
                        "Semantic Web",
                        "Turtle",
                      ],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "RDF-RDB2RDF",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.012 } },
                        runtime   => {
                                       requires => {
                                         "Data::UUID"       => 0,
                                         "DBI"              => 0,
                                         "JSON"             => "2.50",
                                         "match::simple"    => 0,
                                         "MIME::Base64"     => 0,
                                         "namespace::clean" => 0,
                                         "RDF::Trine"       => 0.135,
                                         "URI::Escape"      => 0,
                                       },
                                     },
                        test      => { requires => { "DBD::SQLite" => 0, "Test::More" => 0.96 } },
                      },
  "provides"       => {
                        "RDF::RDB2RDF"                                               => { file => "lib/RDF/RDB2RDF.pm", version => 0.008 },
                        "RDF::RDB2RDF::DatatypeMapper"                               => { file => "lib/RDF/RDB2RDF/DatatypeMapper.pm", version => 0.008 },
                        "RDF::RDB2RDF::DirectMapping"                                => { file => "lib/RDF/RDB2RDF/DirectMapping.pm", version => 0.008 },
                        "RDF::RDB2RDF::DirectMapping::Store"                         => { file => "lib/RDF/RDB2RDF/DirectMapping/Store.pm", version => 0.008 },
                        "RDF::RDB2RDF::DirectMapping::Store::Mixin::SuperGetPattern" => {
                                                                                          file => "lib/RDF/RDB2RDF/DirectMapping/Store/Mixin/SuperGetPattern.pm",
                                                                                          version => 0.008,
                                                                                        },
                        "RDF::RDB2RDF::R2RML"                                        => { file => "lib/RDF/RDB2RDF/R2RML.pm", version => 0.008 },
                        "RDF::RDB2RDF::Simple"                                       => { file => "lib/RDF/RDB2RDF/Simple.pm", version => 0.008 },
                        "RDF::TrineX::Store::DirectMapping"                          => { file => "lib/RDF/RDB2RDF.pm", version => 0 },
                        "URI::Escape::Optimistic"                                    => { file => "lib/URI/Escape/Optimistic.pm", version => 0.008 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=RDF-RDB2RDF" },
                        homepage     => "https://metacpan.org/release/RDF-RDB2RDF",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => { type => "git", web => "https://github.com/tobyink/p5-rdf-rdb2rdf" },
                        X_identifier => "http://purl.org/NET/cpan-uri/dist/RDF-RDB2RDF/project",
                      },
  "version"        => 0.008,
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
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
	my $minperl = delete $WriteMakefileArgs{PREREQ_PM}{perl};
	exists($WriteMakefileArgs{$_}) && delete($WriteMakefileArgs{$_}{perl})
		for qw(BUILD_REQUIRES TEST_REQUIRES CONFIGURE_REQUIRES);
	if ($minperl and $EUMM >= 6.48)
	{
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl;
	}
	elsif ($minperl)
	{
		die "Need Perl >= $minperl" unless $] >= $minperl;
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


use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "Compatibility layer between Attean and RDF::Trine",
  "author"           => ["Kjetil Kjernsmo (KJETILK) <kjetilk\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "RDF-TrineX-Compatibility-Attean",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                          runtime   => { requires => { "perl" => 5.014, "RDF::Trine" => 0 } },
                          test      => { requires => { "Test::More" => 0.96 } },
                        },
  "provides"         => {
                          "RDF::Trine::Model"                  => { file => "lib/RDF/TrineX/Compatibility/Attean.pm" },
                          "RDF::Trine::Node"                   => { file => "lib/RDF/TrineX/Compatibility/Attean.pm" },
                          "RDF::Trine::Node::Literal"          => { file => "lib/RDF/TrineX/Compatibility/Attean.pm" },
                          "RDF::Trine::Node::Resource"         => { file => "lib/RDF/TrineX/Compatibility/Attean.pm" },
                          "RDF::TrineX::Compatibility::Attean" => {
                                                                    file => "lib/RDF/TrineX/Compatibility/Attean.pm",
                                                                    version => "0.100",
                                                                  },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => {
                                            web => "http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Compatibility-Attean",
                                          },
                          homepage     => "https://metacpan.org/release/RDF-TrineX-Compatibility-Attean",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/kjetilk/p5-rdf-trinex-compatibility-attean.git",
                                            web  => "https://github.com/kjetilk/p5-rdf-trinex-compatibility-attean",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/RDF-TrineX-Compatibility-Attean/project",
                          x_IRC        => "irc://irc.perl.org/#perlrdf",
                        },
  "version"          => "0.100",
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


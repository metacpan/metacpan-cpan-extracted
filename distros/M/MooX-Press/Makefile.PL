use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "quickly create a bunch of Moo/Moose/Mouse classes and roles",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "MooX-Press",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       recommends => { "Moose" => 2.12, "MooseX::NonMoose" => 0 },
                                       requires   => {
                                                       "Exporter::Tiny"       => "1.000000",
                                                       "Import::Into"         => 0,
                                                       "Lexical::Accessor"    => 0.012,
                                                       "Module::Runtime"      => 0,
                                                       "Moo"                  => "2.000000",
                                                       "MooX::Enumeration"    => "0.010",
                                                       "namespace::autoclean" => 0,
                                                       "perl"                 => 5.008008,
                                                       "Role::Hooks"          => 0.001,
                                                       "Sub::HandlesVia"      => 0.013,
                                                       "Sub::MultiMethod"     => 0.008,
                                                       "Sub::SymMethod"       => 0.001,
                                                       "Type::Tiny"           => "1.010000",
                                                     },
                                       suggests   => { "Mouse" => 0, "MouseX::NonMoose" => 0 },
                                     },
                        test      => {
                                       recommends => { "Moose" => 2.12, "MooseX::NonMoose" => 0 },
                                       requires   => { "Test::Fatal" => 0, "Test::More" => 0.96, "Test::Requires" => 0 },
                                       suggests   => { "Mouse" => 0, "MouseX::NonMoose" => 0 },
                                     },
                      },
  "provides"       => {
                        "MooX::Press"           => { file => "lib/MooX/Press.pm", version => 0.083 },
                        "MooX::Press::Keywords" => { file => "lib/MooX/Press/Keywords.pm", version => 0.083 },
                        "Zydeco::Lite"          => { file => "lib/Zydeco/Lite.pm", version => 0.083 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=MooX-Press" },
                        homepage     => "https://metacpan.org/release/MooX-Press",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-moox-press.git",
                                          web  => "https://github.com/tobyink/p5-moox-press",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/MooX-Press/project",
                      },
  "version"        => 0.083,
};

my %dynamic_config;
do {
if ( $] lt '5.010' ) {
	$meta->{prereqs}{runtime}{requires}{'UNIVERSAL::DOES'} = '0.001';
}

if ( eval { require Moose } ) {
	$meta->{prereqs}{runtime}{requires}{'MooseX::NonMoose'} = '0';
}

if ( eval { require Mouse } ) {
	$meta->{prereqs}{runtime}{requires}{'MouseX::NonMoose'} = '0';
}


};

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


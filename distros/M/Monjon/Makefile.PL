use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "create your Moo objects as blessed scalar refs",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.021, CPAN::Meta::Converter version 2.140640",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Monjon",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                          recommends => { "ExtUtils::CBuilder" => 0 },
                          requires   => { "ExtUtils::MakeMaker" => 6.17, "Text::ParseWords" => 0 },
                        },
                        runtime => {
                          requires => {
                                        "Import::Into" => 0,
                                        "List::Util" => 0,
                                        "Moo" => "1.001000",
                                        "perl" => "5.006000",
                                      },
                          suggests => {
                                        "Hash::FieldHash" => 0,
                                        "Hash::Util::FieldHash::Compat" => 0,
                                        "UNIVERSAL::DOES" => 0,
                                      },
                        },
                        test => {
                          recommends => { "Types::Standard" => 0.001 },
                          requires   => { "Test::Modern" => 0.007 },
                        },
                      },
  "provides"       => {
                        "Method::Generate::Accessor::Role::Monjon" => {
                          file => "lib/Method/Generate/Accessor/Role/Monjon.pm",
                          version => 0.004,
                        },
                        "Method::Generate::Constructor::Role::Monjon" => {
                          file => "lib/Method/Generate/Constructor/Role/Monjon.pm",
                          version => 0.004,
                        },
                        "Monjon" => { file => "lib/Monjon.pm", version => 0.004 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Monjon" },
                        homepage     => "https://metacpan.org/release/Monjon",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-monjon.git",
                                          web  => "https://github.com/tobyink/p5-monjon",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Monjon/project",
                      },
  "version"        => 0.004,
};

my %dynamic_config;
do {
# Hash::Util::FieldHash was first released with perl v5.9.4

sub parse_args {
	require ExtUtils::MakeMaker;
	require Text::ParseWords;
	ExtUtils::MakeMaker::parse_args(
		my $tmp = {},
		Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
		@ARGV,
	);
	return $tmp->{ARGS} || {};
}
 
my $have_compiler
	= ! parse_args()->{PUREPERL_ONLY}
	&&  eval { require ExtUtils::CBuilder; 1 }
	&& ExtUtils::CBuilder->new->have_compiler;

if ($] < 5.009004)
{
	my $module = ($have_compiler && $] >= 5.008005)
		? 'Hash::FieldHash'
		: 'Hash::Util::FieldHash::Compat';
	$meta->{prereqs}{runtime}{requires}{$module} = 0;
}

$meta->{prereqs}{runtime}{requires}{'UNIVERSAL::DOES'} = 0
	if $] < 5.010000;

$meta->{prereqs}{test}{requires}{'Types::Standard'} = 0
	if $ENV{AUTOMATED_TESTING} || $ENV{EXTENDED_TESTING};

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


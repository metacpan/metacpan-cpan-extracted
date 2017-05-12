use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"          => "Moops Object-Oriented Programming Sugar",
  "author"            => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"    => 1,
  "generated_by"      => "Dist::Inkt::Profile::TOBYINK version 0.023, CPAN::Meta::Converter version 2.142690",
  "keywords"          => [],
  "license"           => ["perl_5"],
  "meta-spec"         => {
                           url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                           version => 2,
                         },
  "name"              => "Moops",
  "no_index"          => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "optional_features" => {
                           Moo   => {
                                      description => "allow classes and roles to be built with Moo",
                                      prereqs     => { runtime => { suggests => { "MooX::HandlesVia" => 0 } } },
                                      x_default   => 1,
                                    },
                           Moose => {
                                      description => "allow classes and roles to be built with Moose",
                                      prereqs     => {
                                                       runtime => {
                                                         recommends => { "MooseX::XSAccessor" => 0 },
                                                         requires   => { Moose => "2.0600" },
                                                       },
                                                       test => { suggests => { "MooseX::Types::Common::Numeric" => 0 } },
                                                     },
                                      x_default   => 0,
                                    },
                           Mouse => {
                                      description => "allow classes and roles to be built with Mouse",
                                      prereqs     => { runtime => { requires => { Mouse => "1.00" } } },
                                      x_default   => 0,
                                    },
                           Tiny  => {
                                      description => "allow classes and roles to be built with Class::Tiny/Role::Tiny",
                                      prereqs     => {
                                                       runtime => {
                                                         requires => { "Class::Tiny::Antlers" => 0, "Role::Tiny" => "1.000000" },
                                                       },
                                                     },
                                      x_default   => 0,
                                    },
                         },
  "prereqs"           => {
                           configure => {
                             recommends => { "CPAN::Meta::Requirements" => "2.000" },
                             requires   => { "ExtUtils::MakeMaker" => 6.17 },
                           },
                           runtime => {
                             conflicts  => {
                                             "MooseX::Types::Common" => "== 0.001011",
                                             "MooseX::Types::URI"    => "== 0.04",
                                           },
                             recommends => { "Keyword::Simple" => 0.02 },
                             requires   => {
                                             "Exporter::Tiny"       => "0.040",
                                             "Import::Into"         => "1.000000",
                                             "Kavorka"              => 0.034,
                                             "Keyword::Simple"      => 0.01,
                                             "Lexical::Accessor"    => 0.008,
                                             "Module::Runtime"      => 0.013,
                                             "Moo"                  => "1.006000",
                                             "MooseX::MungeHas"     => 0.007,
                                             "MooX::late"           => 0.015,
                                             "namespace::autoclean" => "0.20",
                                             "Parse::Keyword"       => 0.006,
                                             "perl"                 => 5.014,
                                             "PerlX::Assert"        => 0.902,
                                             "Scalar::Util"         => "1.40",
                                             "true"                 => 0.18,
                                             "Try::Tiny"            => 0.12,
                                             "Type::Utils"          => "1.000000",
                                             "Variable::Magic"      => 0,
                                           },
                           },
                           test => {
                             recommends => { "Test::Warnings" => 0 },
                             requires   => { "Test::Fatal" => 0, "Test::More" => 0.96, "Test::Requires" => 0 },
                             suggests   => { "Types::XSD::Lite" => 0.003 },
                           },
                         },
  "provides"          => {
                           "Moops"                                                => { file => "lib/Moops.pm", version => 0.034 },
                           "Moops::ImportSet"                                     => { file => "lib/Moops/ImportSet.pm", version => 0.034 },
                           "Moops::Keyword"                                       => { file => "lib/Moops/Keyword.pm", version => 0.034 },
                           "Moops::Keyword::Class"                                => { file => "lib/Moops/Keyword/Class.pm", version => 0.034 },
                           "Moops::Keyword::Library"                              => { file => "lib/Moops/Keyword/Library.pm", version => 0.034 },
                           "Moops::Keyword::Role"                                 => { file => "lib/Moops/Keyword/Role.pm", version => 0.034 },
                           "Moops::MethodModifiers"                               => { file => "lib/Moops/MethodModifiers.pm", version => 0.034 },
                           "Moops::Parser"                                        => { file => "lib/Moops/Parser.pm", version => 0.034 },
                           "Moops::TraitFor::Keyword::assertions"                 => {
                                                                                       file => "lib/Moops/TraitFor/Keyword/assertions.pm",
                                                                                       version => 0.034,
                                                                                     },
                           "Moops::TraitFor::Keyword::dirty"                      => { file => "lib/Moops/TraitFor/Keyword/dirty.pm", version => 0.034 },
                           "Moops::TraitFor::Keyword::fp"                         => { file => "lib/Moops/TraitFor/Keyword/fp.pm", version => 0.034 },
                           "Moops::TraitFor::Keyword::mutable"                    => { file => "lib/Moops/TraitFor/Keyword/mutable.pm", version => 0.034 },
                           "Moops::TraitFor::Keyword::ro"                         => { file => "lib/Moops/TraitFor/Keyword/ro.pm", version => 0.034 },
                           "Moops::TraitFor::Keyword::rw"                         => { file => "lib/Moops/TraitFor/Keyword/rw.pm", version => 0.034 },
                           "Moops::TraitFor::Keyword::rwp"                        => { file => "lib/Moops/TraitFor/Keyword/rwp.pm", version => 0.034 },
                           "MooseX::FunctionParametersInfo"                       => { file => "lib/MooseX/FunctionParametersInfo.pm", version => 0.034 },
                           "MooseX::FunctionParametersInfo::Trait::Method"        => { file => "lib/MooseX/FunctionParametersInfo.pm", version => 0.034 },
                           "MooseX::FunctionParametersInfo::Trait::WrappedMethod" => { file => "lib/MooseX/FunctionParametersInfo.pm", version => 0.034 },
                           "PerlX::Define"                                        => { file => "lib/PerlX/Define.pm", version => 0.034 },
                         },
  "release_status"    => "stable",
  "resources"         => {
                           bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Moops" },
                           homepage     => "https://metacpan.org/release/Moops",
                           license      => ["http://dev.perl.org/licenses/"],
                           repository   => {
                                             type => "git",
                                             url  => "git://github.com/tobyink/p5-moops.git",
                                             web  => "https://github.com/tobyink/p5-moops",
                                           },
                           x_identifier => "http://purl.org/NET/cpan-uri/dist/Moops/project",
                         },
  "version"           => 0.034,
  "x_breaks"          => {
                           "MooseX::Types::Common" => "== 0.001011",
                           "MooseX::Types::URI"    => "== 0.04",
                         },
  "x_contributors"    => [
                           "Maurice Mengel (MMAURICE) <mmaurice\@cpan.org>",
                           "Aaron James Trevena (TEEJAY) <teejay\@cpan.org>",
                         ],
};

if ($ENV{MM_INSTALL_FEATURES})
{
	my %features = %{ $meta->{optional_features} };
	my @features = sort {
		$features{$b}{x_default} <=> $features{$a}{x_default} or $a cmp $b
	} keys %features;
	
	for my $feature_id (@features)
	{
		my %feature = %{ $features{$feature_id} };
		
		next unless prompt(
			sprintf('Install %s (%s)?', $feature_id, $feature{description} || 'no description'),
			$feature{x_default} ? 'Y' : 'N',
		) =~ /^Y/i;
		
		$features{$feature_id}{x_selected} = 1;
		
		for my $stage (keys %{$feature{prereqs}})
		{
			for my $level (keys %{$feature{prereqs}{$stage}})
			{
				for my $module (keys %{$feature{prereqs}{$stage}{$level}})
				{
					$meta->{prereqs}{$stage}{$level}{$module}
						= $feature{prereqs}{$stage}{$level}{$module};
				}
			}
		}
	}
}
else
{
	print <<'MM_INSTALL_FEATURES';

** Setting the MM_INSTALL_FEATURES environment variable to true
** would allow you to choose additional features.

MM_INSTALL_FEATURES
}

my %dynamic_config;
for my $stage (keys %{$meta->{prereqs}})
{
	my $conflicts = $meta->{prereqs}{$stage}{conflicts} or next;
	eval { require CPAN::Meta::Requirements } or last;
	$conflicts = 'CPAN::Meta::Requirements'->from_string_hash($conflicts);
	
	for my $module ($conflicts->required_modules)
	{
		eval "require $module" or next;
		my $installed = eval(sprintf('$%s::VERSION', $module));
		$conflicts->accepts_module($module, $installed) or next;
		
		my $message = "\n".
			"** This version of $meta->{name} conflicts with the version of\n".
			"** module $module ($installed) you have installed.\n";
		die($message . "\n" . "Bailing out")
			if $stage eq 'build' || $stage eq 'configure';
		
		$message .= "**\n".
			"** It's strongly recommended that you update it after\n".
			"** installing this version of $meta->{name}.\n";
		warn("$message\n");
	}
}

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


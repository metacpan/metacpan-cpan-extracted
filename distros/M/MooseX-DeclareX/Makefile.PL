use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "more sugar for MooseX::Declare",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 0,
  "generated_by"   => "Moose::Meta::Class::__ANON__::SERIAL::10 version , CPAN::Meta::Converter version 2.140640",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "MooseX-DeclareX",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        runtime => {
                          requires => {
                            "Class::Load"                                              => 0,
                            "Data::OptList"                                            => 0,
                            "Devel::Declare"                                           => 0,
                            "Devel::Declare::Context::Simple"                          => 0,
                            "Moose"                                                    => 0,
                            "Moose::Role"                                              => 0,
                            "Moose::Util"                                              => 0,
                            "MooseX::Declare"                                          => 0,
                            "MooseX::Declare::Context::WithOptions::Patch::Extensible" => 0,
                            "MooseX::Method::Signatures"                               => 0,
                            "Sub::Install"                                             => 0,
                            "Throwable::Error"                                         => 0,
                            "TryCatch"                                                 => 0,
                          },
                        },
                        test => { requires => { "Test::Exception" => 0, "Test::More" => 0.61 } },
                      },
  "provides"       => {
                        "MooseX::DeclareX"                                      => { file => "lib/MooseX/DeclareX.pm", version => 0.009 },
                        "MooseX::DeclareX::Keyword::class"                      => { file => "lib/MooseX/DeclareX/Keyword/class.pm", version => 0.009 },
                        "MooseX::DeclareX::Keyword::exception"                  => {
                                                                                     file => "lib/MooseX/DeclareX/Keyword/exception.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Keyword::namespace"                  => {
                                                                                     file => "lib/MooseX/DeclareX/Keyword/namespace.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Keyword::role"                       => { file => "lib/MooseX/DeclareX/Keyword/role.pm", version => 0.009 },
                        "MooseX::DeclareX::MethodPrefix"                        => { file => "lib/MooseX/DeclareX/MethodPrefix.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin"                              => { file => "lib/MooseX/DeclareX/Plugin.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::build"                       => { file => "lib/MooseX/DeclareX/Plugin/build.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::build::MethodModifier"       => { file => "lib/MooseX/DeclareX/Plugin/build.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::guard"                       => { file => "lib/MooseX/DeclareX/Plugin/guard.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::guard::MethodModifier"       => { file => "lib/MooseX/DeclareX/Plugin/guard.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::having"                      => { file => "lib/MooseX/DeclareX/Plugin/having.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::having::Role"                => { file => "lib/MooseX/DeclareX/Plugin/having.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::imports"                     => { file => "lib/MooseX/DeclareX/Plugin/imports.pm", version => 0.009 },
                        "MooseX::DeclareX::Plugin::postprocess"                 => {
                                                                                     file => "lib/MooseX/DeclareX/Plugin/postprocess.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Plugin::postprocess::MethodModifier" => {
                                                                                     file => "lib/MooseX/DeclareX/Plugin/postprocess.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Plugin::preprocess"                  => {
                                                                                     file => "lib/MooseX/DeclareX/Plugin/preprocess.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Plugin::preprocess::MethodModifier"  => {
                                                                                     file => "lib/MooseX/DeclareX/Plugin/preprocess.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Plugin::std_constants"               => {
                                                                                     file => "lib/MooseX/DeclareX/Plugin/std_constants.pm",
                                                                                     version => 0.009,
                                                                                   },
                        "MooseX::DeclareX::Plugin::types"                       => { file => "lib/MooseX/DeclareX/Plugin/types.pm", version => 0.009 },
                        "MooseX::DeclareX::Registry"                            => { file => "lib/MooseX/DeclareX/Registry.pm", version => 0.009 },
                        "MooseX::DeclareX::RegistryUsing"                       => { file => "lib/MooseX/DeclareX/RegistryUsing.pm", version => 0.009 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "http://rt.cpan.org/Dist/Display.html?Queue=MooseX-DeclareX",
                                        },
                        homepage     => "https://metacpan.org/release/MooseX-DeclareX",
                        license      => ["http://dev.perl.org/licenses/"],
                        X_identifier => "http://purl.org/NET/cpan-uri/dist/MooseX-DeclareX/project",
                      },
  "version"        => 0.009,
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


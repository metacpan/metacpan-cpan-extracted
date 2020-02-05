use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "alternative handles_via implementation",
  "author"           => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "Sub-HandlesVia",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                          runtime   => {
                                         recommends => { "Sub::Util" => 0 },
                                         requires   => {
                                                         "Class::Method::Modifiers" => 0,
                                                         "Class::Tiny"              => 0,
                                                         "Eval::TypeTiny"           => 0,
                                                         "Exporter::Shiny"          => 0,
                                                         "List::Util"               => 1.54,
                                                         "perl"                     => 5.008,
                                                         "Role::Tiny"               => 0,
                                                         "Type::Params"             => "1.004000",
                                                         "Types::Standard"          => 0,
                                                       },
                                       },
                          test      => {
                                         recommends => {
                                                         "Class::Tiny" => 0,
                                                         "Moo" => 0,
                                                         "Moose" => 0,
                                                         "MooX::TypeTiny" => 0,
                                                         "Mouse" => 0,
                                                       },
                                         requires   => { "Test::Fatal" => 0, "Test::More" => 0.96, "Test::Requires" => 0 },
                                       },
                        },
  "provides"         => {
                          "Sub::HandlesVia"                               => { file => "lib/Sub/HandlesVia.pm", version => 0.013 },
                          "Sub::HandlesVia::Handler"                      => { file => "lib/Sub/HandlesVia/Handler.pm", version => 0.013 },
                          "Sub::HandlesVia::Handler::CodeRef"             => { file => "lib/Sub/HandlesVia/Handler.pm", version => 0.013 },
                          "Sub::HandlesVia::Handler::Traditional"         => { file => "lib/Sub/HandlesVia/Handler.pm", version => 0.013 },
                          "Sub::HandlesVia::HandlerLibrary"               => { file => "lib/Sub/HandlesVia/HandlerLibrary.pm", version => 0.013 },
                          "Sub::HandlesVia::HandlerLibrary::Array"        => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Array.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::Bool"         => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Bool.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::Code"         => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Code.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::Counter"      => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Counter.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::Hash"         => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Hash.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::Number"       => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Number.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::Scalar"       => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/Scalar.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::HandlerLibrary::String"       => {
                                                                               file => "lib/Sub/HandlesVia/HandlerLibrary/String.pm",
                                                                               version => 0.013,
                                                                             },
                          "Sub::HandlesVia::Toolkit"                      => { file => "lib/Sub/HandlesVia/Toolkit.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Moo"                 => { file => "lib/Sub/HandlesVia/Toolkit/Moo.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Moose"               => { file => "lib/Sub/HandlesVia/Toolkit/Moose.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Moose::PackageTrait" => { file => "lib/Sub/HandlesVia/Toolkit/Moose.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Moose::RoleTrait"    => { file => "lib/Sub/HandlesVia/Toolkit/Moose.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Mouse"               => { file => "lib/Sub/HandlesVia/Toolkit/Mouse.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Mouse::PackageTrait" => { file => "lib/Sub/HandlesVia/Toolkit/Mouse.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Mouse::RoleTrait"    => { file => "lib/Sub/HandlesVia/Toolkit/Mouse.pm", version => 0.013 },
                          "Sub::HandlesVia::Toolkit::Plain"               => { file => "lib/Sub/HandlesVia/Toolkit/Plain.pm", version => 0.013 },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => {
                                            web => "http://rt.cpan.org/Dist/Display.html?Queue=Sub-HandlesVia",
                                          },
                          homepage     => "https://metacpan.org/release/Sub-HandlesVia",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/tobyink/p5-sub-handlesvia.git",
                                            web  => "https://github.com/tobyink/p5-sub-handlesvia",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/Sub-HandlesVia/project",
                        },
  "version"          => 0.013,
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
	test       => { TESTS => "t/*.t t/02moo/*.t t/03moo_mxtt/*.t t/04moose/*.t t/05moose_nativetypes/*.t t/06mouse/*.t t/07mouse_nativetypes/*.t" },
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


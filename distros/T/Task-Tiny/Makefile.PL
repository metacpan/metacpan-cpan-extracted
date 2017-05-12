use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"          => "install a lightweight development environment",
  "author"            => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"    => 1,
  "generated_by"      => "Dist::Inkt::Profile::TOBYINK version 0.013, CPAN::Meta::Converter version 2.120921",
  "keywords"          => [],
  "license"           => ["perl_5"],
  "meta-spec"         => {
                           url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                           version => 2,
                         },
  "name"              => "Task-Tiny",
  "no_index"          => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "optional_features" => {
                           Filesys => {
                                        description => "File system manipulation",
                                        prereqs     => {
                                                         runtime => {
                                                           recommends => { "Types::Path::Tiny" => 0 },
                                                           requires   => { "Path::Tiny" => 0 },
                                                         },
                                                       },
                                        x_default   => 1,
                                      },
                           HTTP    => {
                                        description => "Web stuff",
                                        prereqs     => { runtime => { requires => { "HTTP::Tiny" => 0 } } },
                                        x_default   => 1,
                                      },
                           JSON    => {
                                        description => "JSON stuff",
                                        prereqs     => { runtime => { requires => { "JSON::PP" => 0 } } },
                                        x_default   => 1,
                                      },
                           Objects => {
                                        description => "Framework for OO programming",
                                        prereqs     => {
                                                         runtime => {
                                                           recommends => { "Class::Method::Modifiers" => 0 },
                                                           requires   => { "Class::Tiny" => 0, "Class::Tiny::Antlers" => 0, "Role::Tiny" => 0 },
                                                         },
                                                       },
                                        x_default   => 1,
                                      },
                           Types   => {
                                        description => "Type constraint framework",
                                        prereqs     => {
                                                         runtime => {
                                                           recommends => { "Types::Path::Tiny" => 0 },
                                                           requires   => { "Type::Tiny" => 0 },
                                                         },
                                                       },
                                        x_default   => 1,
                                      },
                           Util    => {
                                        description => "General utilities",
                                        prereqs     => {
                                                         runtime => {
                                                           recommends => { "Config::Tiny" => 0 },
                                                           requires   => { "Exporter::Tiny" => 0, "Try::Tiny" => 0 },
                                                         },
                                                       },
                                        x_default   => 1,
                                      },
                           YAML    => {
                                        description => "YAML stuff",
                                        prereqs     => { runtime => { requires => { "YAML::Tiny" => 0 } } },
                                        x_default   => 0,
                                      },
                         },
  "prereqs"           => {
                           configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                           develop => { recommends => { "Dist::Inkt" => 0.001 } },
                           test => { requires => { "Test::More" => 0.96 } },
                         },
  "provides"          => {
                           "Task::Tiny" => { file => "lib/Task/Tiny.pm", version => 0.002 },
                         },
  "release_status"    => "stable",
  "resources"         => {
                           bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Task-Tiny" },
                           homepage     => "https://metacpan.org/release/Task-Tiny",
                           license      => ["http://dev.perl.org/licenses/"],
                           repository   => { type => "git", web => "https://github.com/tobyink/p5-task-tiny" },
                           X_identifier => "http://purl.org/NET/cpan-uri/dist/Task-Tiny/project",
                         },
  "version"           => 0.002,
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


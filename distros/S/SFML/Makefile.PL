use 5.008009;
use ExtUtils::MakeMaker;
use Config;

#use blib "../Alien-SFML/blib/";
use Alien::SFML;

my $alien = Alien::SFML->new;

my $suppressedwarnings = "-Wno-unused-variable -Wno-duplicate-decl-specifier";

my $clang = `clang -v 2>&1` =~ /clang version [^ ]{2,}/;

my $gpp      = `g++ -v 2>&1` =~ /^gcc version [^ ]{3,}/m;
my $fallback = $Config{cc} . " -x c++ -Wall -ggdb $suppressedwarnings";
if ($clang) {
	print "Using clang compiler\n";
} elsif ($gpp) {
	print "Using g++ to compile\n";
} else {
	print "Using fallback compiler (" . $Config{cc} . ")\n";
}
my $compiler = WriteMakefile(
	NAME           => 'SFML',
	BUILD_REQUIRES => {
		'ExtUtils::CBuilder' => 0,
		'Alien::SFML' => 0.02,
	},
	CONFIGURE_REQUIRES => {
		'Alien::SFML' => 0.02,
	},
	PREREQ_PM => {
		'Alien::SFML' => 0.02,
	},
	LICENSE       => 'zlib',
	VERSION_FROM  => 'lib/SFML.pm',                                                              # finds $VERSION
	ABSTRACT_FROM => 'lib/SFML.pm',                                                              # retrieve abstract from module
	AUTHOR        => 'Jake Bott <jakeanq@gmail.com>, Georgiy Tugai <georgiy.tugai@gmail.com>',
	CC            => (
		$clang ? "clang -x c++ -Wall -ggdb $suppressedwarnings"
		: (
			  $gpp ? "g++ -Wall -ggdb $suppressedwarnings"
			: $fallback
		)
	),
	LD       => $Config{ld} . ' -Wall -ggdb ',
	XSOPT    => '-C++',
	CCFLAGS  => $alien->cflags(),
	TYPEMAPS => [ 'perlobject.map', 'string.map', 'typemaps/Window.map', 'typemaps/Graphics.map' ],
	LIBS     => [ $alien->libs() ],                                                                   # e.g., '-lm'
	DEFINE   => '',                                                                                   # e.g., '-DHAVE_SOMETHING'
	INC      => '-I.',                                                                                # e.g., '-I. -I/usr/include/other'
	                                                                                                  # Un-comment this if you add C files to link with later:
	                                                                                                  # OBJECT            => '$(O_FILES)', # link all the C files too
);

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut

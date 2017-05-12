use strict;
use warnings;
use Module::Build;

# You may want to change these options.
# You probably want to change the cc option to your C compiler
#
my %options = (
	cc => 'gcc',
	debug => 1,
	trace => 0,
);

# You probably want to replace "libexpat.lib" by the value required
# by your linker if you're not using gcc
my $linker_flags = $options{cc} eq 'gcc'
	? q{ -lexpat}
	: q{ libexpat.lib };

# You probably want to change the compiler options unless you're using GCC
my $compiler_flags =  q{ -O3 -DCACHING};

$compiler_flags .= ($options{trace}) ? q{ -DDEBUG } : q{ -UDEBUG };
$compiler_flags .= ($options{debug}) ? q{ -g } : q{};

my $builder = Module::Build->new(
    dist_name           => 'SOAP-WSDL_XS',
    dist_abstract       => 'Fast XML deserializer for SOAP::WSDL',
    keywords            => [qw( SOAP WSDL SOAP::WSDL)],
    license             => 'perl',
    dist_author         => q{Martin Kutter - MKUTTER@cpan.org},
    dist_version        => 0.2,
    extra_linker_flags  => $linker_flags,
    extra_compiler_flags => $compiler_flags,
    add_to_cleanup      => [ 'SOAP-WSDL-Expat-MessageParser-' ],
    prereq              => {
        'SOAP::WSDL' => 2,
        'Class::Std::Fast' => 0,
    },
    build_prereq        => {
        'ExtUtils::CBuilder' => 0.24,
        'Test::More' => 0,

    },
    resources => {
        license => 'perl',
        homepage => 'http://soap-wsdl.sourceforge.net',

    }

);

$builder->create_build_script();

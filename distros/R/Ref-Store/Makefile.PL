use strict;
use warnings;
use ExtUtils::MakeMaker;

my $XSFILE = 'Store.xs';
my $HDR = 'hreg.h';
my @modules = qw(hr_pl hr_hrimpl hr_implattr hreg);
my $modstring = join(".o ", @modules) . ".o";

my $GENERATED_FILES = "*.o Store.* INLINE.h";

WriteMakefile(
    NAME                => 'Ref::Store',
    AUTHOR              => q{M. Nunberg, <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/Ref/Store.pm',
    ABSTRACT_FROM       => 'lib/Ref/Store.pm',
    CONFIGURE_REQUIRES  => { 'InlineX::C2XS' => 0 },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        #for tests:
        'Dir::Self'         => 0,
        'Test::More' 		=> 0,
        #for PP backend
        'Variable::Magic' 	=> 0.47,
        'Task::Weaken'  	=> 0,
        #mainly for tests:
		'Module::Stubber' 	=> 0.02,
        #for base object:
		'Class::XSAccessor' => 0,
        #for sanity:
		'Constant::Generate'=> 0.03,
        #for sanity
        'Devel::GlobalDestruction' => 0.04,
        #for vlist()
        'Devel::FindRef'    => 1.422
    },
    #LIBS                => ['-lprofiler'],
    OBJECT             => join(".o ", @modules) . ".o Store.o",
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ref-Store-* '. $GENERATED_FILES },
    #CCFLAGS              => '-std=gnu89',
);



sub MY::postamble {
    my $self = shift;
    my $perl = $self->{PERLRUN} ? '$(PERLRUN)' : '$(PERL)';
    my $package_name = 'Ref::Store::XS::cfunc';
    my $module_name = 'Ref::Store';
    #c2xs($module_name, $package_name, ".", { SRC_LOCATION => $HDR, AUTOWRAP => 1});
    return "$XSFILE: $HDR $modstring\n\t$perl genxs.pl $HDR $module_name $package_name"
}

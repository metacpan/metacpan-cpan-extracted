
use 5.005;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

# note. EUMM 6.38 and later always includes 'author'
# in META.yml fixing compliance with spec

WriteMakefile(
    NAME              => 'POD2::Base',
    VERSION_FROM      => 'lib/POD2/Base.pm',
    PREREQ_PM         => {
        strict            => 0,
        warnings          => 0,
        vars              => 0,
      ( warnings::compat  => 0, ) x!! ( $] < 5.006 ),

        File::Spec        => 0,

        Test::More        => 0,
    },
    ($] >= 5.005 ? (
        'ABSTRACT_FROM' => 'lib/POD2/Base.pod',
#        'AUTHOR'        => 'Adriano R. Ferreira <ferreira@cpan.org>',
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl',
        EXTRA_META => "recommends:\n" .
                      "    Test::Pod:                     1.18\n" .
                      "    Test::Pod::Coverage:           1.04\n" .
                      "    ExtUtils::MakeMaker:           6.38\n"
    ) :())

);

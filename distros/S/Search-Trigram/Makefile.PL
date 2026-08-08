use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# Search::Trigram publishes a runtime C ABI (include/sg_abi.h) that consumers
# resolve through Search::Trigram::_abi_ptr. ExtUtils::Depends installs the
# interface header and records the include path, so a consumer only has to
# name us in its own ExtUtils::Depends->new to get the -I. Only sg_abi.h is
# installed; sg_abi_impl.h and strigram.h stay private to this build.
my $pkg = ExtUtils::Depends->new('Search::Trigram');
$pkg->set_inc('-I. -Iinclude');
$pkg->install('include/sg_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# get_makefile_vars hands back an empty LIBS/LDFROM that would clobber the
# real ones, and an INC and OBJECT we set ourselves below.
delete @dep{qw(LIBS LDFROM INC OBJECT)};
# It also sets PM explicitly, which makes init_PM return early without running
# MakeMaker's own scan, so re-add what that scan would have found.
$dep{PM}{'lib/Search/Trigram.pm'} = '$(INST_LIB)/Search/Trigram.pm';

WriteMakefile(
    NAME             => 'Search::Trigram',
    VERSION_FROM     => 'lib/Search/Trigram.pm',
    ABSTRACT_FROM    => 'lib/Search/Trigram.pm',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES    => { 'Test::More' => '0.88' },
    PREREQ_PM        => {},
    INC              => '-I. -Iinclude',
    OBJECT           => '$(BASEEXT)$(OBJ_EXT) strigram$(OBJ_EXT)',
    C                => ['strigram.c'],
    macro            => { TARFLAGS => '--format=ustar -c -v -f' },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean            => { FILES => 'Search-Trigram-* Install/Files.pm' },
    # MakeMaker does not rescan an XS file's #includes, so name the headers
    # that get pulled into it: without this an edit to the ABI leaves the old
    # object in place and `make` reports success having rebuilt nothing.
    depend           => {
        '$(BASEEXT)$(OBJ_EXT)' => 'include/sg_abi.h include/sg_abi_impl.h '
                                . 'include/strigram.h',
        'strigram$(OBJ_EXT)'   => 'include/strigram.h',
    },
    %dep,
);

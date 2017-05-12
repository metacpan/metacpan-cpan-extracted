# ****************************************************************
# subroutine(s)
# ****************************************************************

sub author_requires {
    warn 'You need to install Module::Install::AuthorRequires '
       . 'to install modules author requires';

    return;
}

sub recursive_author_tests {
    return;
}


# ****************************************************************
# main routine
# ****************************************************************

use inc::Module::Install 1.06;

# ================================================================
# gathering meta information
# ================================================================
# individual gathering
author(
    'MORIYA Masaki, alias Gardejo <moriya at cpan dot org>'
);
resources(
    repository
        => 'git://github.com/gardejo/p5-moosex-types-locale-language.git',
    # (implicit assignment)
    # bugtracker
    #     => 'http://rt.cpan.org/Public/Dist/Display.html?Name='
    #      . 'MooseX-Types-Locale-Language',
    homepage
        => 'http://github.com/gardejo/p5-moosex-types-locale-language',
);

# the rest of information
# abstract, author, license, name, perl_version(5.008_001), version
all_from(
    'lib/MooseX/Types/Locale/Language.pm'
);

no_index directory => (
    'examples',
#   'extlib',
);

# ================================================================
# general dependency(-ies)
# ================================================================
requires(
    'Locale::Language'                  => '3.00',
        # for Alpha-3 codes
    'Moose'                             => '0.41',
        # cf. MooseX-Types-DateTime
    'MooseX::Types'                     => '0.19',
        # cf. MooseX-Types-DateTime
    'namespace::clean'                  => '0.08',
        # cf. MooseX-Types-DateTime
);

# ================================================================
# optional dependency(-ies)
# ================================================================
features(
);

# ================================================================
# configure dependency(-ies)
# ================================================================
configure_requires(
    'Test::Class'                       => '0.34',
    'Test::Exception'                   => '0.27',
        # cf. MooseX-Types-DateTime
    'Test::More'                        => '0',
    'Test::Requires'                    => '0',
    'Test::Warn'                        => '0',
);

# ================================================================
# test dependency(-ies) / build dependency(-ies)
# ================================================================
build_requires(
);

# ================================================================
# author dependency(-ies) : Module::Install::AuthorRequires
# ================================================================
author_requires(
    'Module::Install::AuthorTests'      => '0',
    'Perl::Critic'                      => '0.094',
    'Test::CPAN::Meta'                  => '0.12',
#   'Test::Kwalitee'                    => '0',
        # is always die (but xt/kwalitee.t need it)
    'Test::NoTabs'                      => '0',
    'Test::Perl::Critic'                => '0',
    'Test::Pod'                         => '1.40',
    'Test::Pod::Coverage'               => '1.08',
    'Test::Synopsis'                    => '0.06',
    'Test::UseAllModules'               => '0',
);

# ================================================================
# test(s)
# ================================================================
tests(
    't/*.t'
);
recursive_author_tests(
    'xt'
);

# ================================================================
# including
# ================================================================
auto_include_deps();
    # 'auto_include' grabs only immediate dependencies

# ================================================================
# installation
# ================================================================
# auto_install();
    # 'auto_install' is deprecated

# ================================================================
# writter
# ================================================================
WriteAll();

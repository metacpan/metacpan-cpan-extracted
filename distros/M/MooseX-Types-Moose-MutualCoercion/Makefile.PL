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
        => 'git://github.com/gardejo/p5-moosex-types-moose-mutualcoercion.git',
    # (implicit assignment)
    # bugtracker
    #     => 'http://rt.cpan.org/Public/Dist/Display.html?Name='
    #      . 'MooseX-Types-Moose-MutualCoercion',
    homepage
        => 'http://github.com/gardejo/p5-moosex-types-moose-mutualcoercion',
);

# the rest of information
# abstract, author, license, name, perl_version(5.008_001), version
all_from(
    'lib/MooseX/Types/Moose/MutualCoercion.pm'
);

no_index directory => (
    'examples',
#   'extlib',
);

# ================================================================
# general dependency(-ies)
# ================================================================
requires(
    'Class::Load'                       => '0',
#   'Carp'                              => '0',
        # was included by perl 5
    'Moose'                             => '0.63',
    'MooseX::Types'                     => '0.19',
#   'MooseX::Types::Moose'              => '0.19',
        # was included by MooseX-Types
    'MooseX::Types::Common'             => '0.001000',  # initial version
    'namespace::clean'                  => '0.08',
);

# ================================================================
# optional dependency(-ies)
# ================================================================
features(
    'Using Regexp::Assemble for performance optimization' => [
        -default => 0,
        recommends(
            'Regexp::Assemble'                  => '0',
        ),
    ],
);

# ================================================================
# configure dependency(-ies)
# ================================================================
configure_requires(
#   'Test::Class'                       => '0.34',
        # was not used this time
    'Test::Exception'                   => '0.27',
        # cf. MooseX-Types-DateTime
    'Test::More'                        => '0',
    'Test::Requires'                    => '0',
#   'Test::Warn'                        => '0',
        # was not used this time
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

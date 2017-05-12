use strict;
use warnings;

use 5.006001;

use lib 'inc';

use Module::Build;
use My::Module::Build;
use My::Module::Meta qw{
    build_required_module_versions
    meta_merge
    recommended_module_versions
    required_module_versions
    requires_perl
};

( my $mbv = Module::Build->VERSION() ) =~ s/_//g;

my %args = (
    module_name         => 'Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter',
    dist_author         => 'Thomas R. Wyant, III (wyant at cpan dot org)',
    dist_abstract       => 'Critique unused variables in Perl source',
    license             => 'perl',
    create_packlist     => 1,
    sign                => 0,

    requires            => { required_module_versions(
                                perl => requires_perl(),
                            ) },
    build_requires      => { build_required_module_versions() },
    recommends          => { recommended_module_versions() },

    add_to_cleanup      => [
        qw<
            Debian_CPANTS.txt
        >,
    ],
);

$mbv >= 0.28
    and $args{meta_merge} = meta_merge();

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $builder = My::Module::Build->new(
    %args,
);

$builder->create_build_script();

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

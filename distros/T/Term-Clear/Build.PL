use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Term::Clear',
    license           => 'artistic2',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Term/Clear.pm',
    requires          => {                                                    # Do not add POSIX, its a best effort if you want it and have it sort of situation
        'Term::Cap'        => 0,
        'Test::Spec'       => 0,
        'Test::MockModule' => 0,
        'Test::Mock::Cmd'  => 0,
    },

    # delete_share => '.', # NYI https://rt.cpan.org/Ticket/Display.html?id=92863
    # install_share => 'share',
    add_to_cleanup => ['Term-Clear-*'],
);

$builder->create_build_script();

# package MY;
# use File::ShareDir::Install 0.07 qw(postamble);
# File::ShareDir::Install::delete_share('.');

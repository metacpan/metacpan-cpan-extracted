use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::CPAN::SQLite::Info',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/CPAN/SQLite/Info.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent'         => 0,
        'File::Spec'             => 0,
        'CPAN::SQLite::Info'     => 0,
        'POE'                    => 0,
        'POE::Wheel::Run'        => 0,
        'POE::Filter::Reference' => 0,
        'POE::Filter::Line'      => 0,
        'Carp'                   => 0,
        perl                     => '5.008008',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-CPAN-SQLite-Info-*' ],
    create_makefile_pl => 'traditional',
);

unlink 'cpan_network_tests';

my $do_network = lc $builder->prompt(make_prompt_message(), 'y' );

if ( $do_network eq 'y' ) {
    open TOUCH, '>', 'cpan_network_tests';
    close TOUCH;
}

$builder->create_build_script();



sub make_prompt_message {
    my $mess = <<'END_MESSAGE';

*********************************************************************
*********************************************************************

Some tests require you to have a functional network and for you to
be able to access http://cpan.perl.org.
Tests will not fail if network is not available, but will take much
longer to test.

Would you like to run network tests? [Y/n]:
END_MESSAGE

    chomp $mess;
    return $mess;
}

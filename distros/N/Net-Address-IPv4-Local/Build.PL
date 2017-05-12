use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Net::Address::IPv4::Local',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        # Core requirements:
        perl                => 0,
        IO::Socket::INET    => 0,
        Error               => 0
    },
    recommends      => {
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL,v 1.3 2005/05/05 12:59:30 julian Exp $
# vim:tw=79

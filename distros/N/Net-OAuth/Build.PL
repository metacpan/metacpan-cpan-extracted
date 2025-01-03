use strict;
use warnings;
use Module::Build;

shift(@ARGV) if defined $ARGV[0] and $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall

my $builder = Module::Build->new(
    module_name         => 'Net::OAuth',
    license             => 'perl',
    dist_author         => [ 'Keith Grennan <kgrennan@cpan.org>', 'Robert Rothenberg <rrwo@cpan.org>' ],
    dist_version_from   => 'lib/Net/OAuth.pm',
    dist_abstract       => 'An implementation of the OAuth protocol',
    build_requires => {
        'Test::More' => '0.66',
        'Test::Warn' => '0.21',
    },
    requires => {
        'Digest::SHA' => '5.47',
        'Digest::HMAC_SHA1' => '1.01',
        'URI' => '5.15',
        'Class::Accessor' => '0.31',
        'Class::Data::Inheritable' => '0.06',
        'Encode' => '2.35',
        'LWP::UserAgent' => '1',
        'Crypt::URandom' => '0.37',
    },
    configure_requires => {
        'Module::Build'         => '0.4234',
        'Module::Build::Compat' => '0.4234',
    },
    add_to_cleanup      => [ 'Net-OAuth-*' ],
    create_makefile_pl  => 'small',
    meta_merge          => {
        resources => {
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Net-OAuth',
            repository => 'https://github.com/keeth/Net-OAuth.git',
        },
    },
);

$builder->create_build_script();

__END__
# handy lister of installed dependency versions
use Data::Dumper;
my $requires = $builder->build_requires;
for my $mod (keys %$requires) {
    eval "require $mod";
    $requires->{$mod} = eval "\$$mod\::VERSION";
}
print "Current dependency versions:\n";
print Dumper $requires;

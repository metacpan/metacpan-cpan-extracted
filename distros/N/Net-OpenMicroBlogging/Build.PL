use strict;
use warnings;
use Module::Build;

shift(@ARGV) if defined $ARGV[0] and $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall

my $builder = Module::Build->new(
    module_name         => 'Net::OpenMicroBlogging',
    license             => 'perl',
    dist_author         => 'Keith Grennan <kgrennan@cpan.org>',
    dist_version_from   => 'lib/Net/OpenMicroBlogging.pm',
    dist_abstract       => 'An implementation of the OpenMicroBlogging protocol',
    build_requires => {
        'Net::OAuth' => '0.12',
        'NEXT' => '0.60',
    },
    add_to_cleanup      => [ 'Net-OpenMicroBlogging-*' ],
    create_makefile_pl => 'passthrough',
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

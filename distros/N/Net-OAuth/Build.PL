use strict;
use warnings;
use Module::Build;

shift(@ARGV) if defined $ARGV[0] and $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall

my $builder = Module::Build->new(
    module_name         => 'Net::OAuth',
    license             => 'perl',
    dist_author         => 'Keith Grennan <kgrennan@cpan.org>',
    dist_version_from   => 'lib/Net/OAuth.pm',
    dist_abstract       => 'An implementation of the OAuth protocol',
    build_requires => {
        'Test::More' => '0.66',
        'Test::Warn' => '0.21',
    },
    requires => {
        'Digest::SHA' => '5.47',
        'Digest::HMAC_SHA1' => '1.01',
        'URI::Escape' => '3.28',
        'Class::Accessor' => '0.31',
        'Class::Data::Inheritable' => '0.06',
        'Digest::SHA1' => '2.12',
        'Encode' => '2.35',
        'LWP::UserAgent' => '1',
    },    
    add_to_cleanup      => [ 'Net-OAuth-*' ],
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

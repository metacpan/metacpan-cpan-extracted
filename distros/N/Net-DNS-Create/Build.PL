use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::DNS::Create',
    license             => 'perl',
    dist_author         => q{David Caldwell <david@porkrind.org>},
    dist_version_from   => 'lib/Net/DNS/Create.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'File::Slurp' => 0,
    },
    requires => {
        'perl'                 => '5.10.0', # I use // indiscriminately.
        'Hash::Merge::Simple'  => 0,
        'Net::DNS'             => '0.72',
        'Net::Amazon::Route53' => 0,
        'LWP::Protocol::https' => 0, # Should probably be required by Net::Amazon::Route53
    },
);


if (-d ".git") { # Are we in our development tree? If so, create MANIFEST.
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    print $manifest "MANIFEST\n";
    open $dir, '-|', 'git', 'ls-files' or die "Couldn't run git: $!";
    while (<$dir>) { print $manifest $_ }

    # Also, create a cpanfile so we can use carton for development
    my $cf;
    open $cf, '>', 'cpanfile' or die "Couldn't create cpanfile";
    my %prereq = ( map { %$_ } values %{$builder->prereq_data} );
    while (my ($dep,$ver) = each %prereq) {
        print $cf "requires '$dep'".($ver ? ", '$ver'" : '').";\n"
    }
}

$builder->create_build_script();

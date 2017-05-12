###############################################################################
#
#   Module::Build file for Task::BeLike::RJRAY
#
###############################################################################

use 5.008;
use strict;
use warnings;
use autodie qw(open close);

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Task::BeLike::RJRAY::Builder',
    code => q|
        sub ACTION_dist
        {
            my $self = shift;

            # Create the text README
            $self->do_system('textile2x',
                             qw(--format plaintext
                                --input README.textile
                                --output README));

            $self->SUPER::ACTION_manifest();
            $self->SUPER::ACTION_dist();
        }
|);

# Get all the requirements from the task POD
my %requires;
open my $fh, '<', 'lib/Task/BeLike/RJRAY.pm';
while (defined(my $line = <$fh>))
{
    next unless ($line =~ /^=head3/);
    my (undef, $mod, $ver, undef) = split /\s+/, $line, 4;
    $ver ||= 0;
    $mod =~ s/L<(.*)>/$1/;

    $requires{$mod} = $ver;
}
close $fh;

my $builder = $class->new(
    module_name        => 'Task::BeLike::RJRAY',
    license            => 'perl',
    dist_author        => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract      => q(RJRAY's favorite modules),
    dist_version_from  => 'lib/Task/BeLike/RJRAY.pm',
    requires           => \%requires,
    add_to_cleanup     => [ qw(README
                               MANIFEST
                               MANIFEST.bak
                               MANIFEST.SKIP.bak
                               META.yml
                               META.json
                               Makefile.PL) ],
    meta_merge         =>
    {
        resources =>
        {
            homepage   => 'http://search.cpan.org/dist/Task-BeLike-RJRAY',
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Task-BeLike-RJRAY',
            repository => 'http://github.com/rjray/task-belike-rjray',
        }
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

exit 0;

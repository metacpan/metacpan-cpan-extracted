package Setup::Project::Flavor::CLI;

use strict;
use warnings;
use parent qw/Setup::Project::ShareDir/;
use Setup::Project::Functions;

sub version  { "0.01" }
sub tmpl_dir { sharedir('Setup::Project', 'tmpl', 'CLI'); }
sub argv     { "flavor_name=light" }

sub parse {
    my ($self, $argv) = @_;
    die unless $argv;

    my %vars = equal_style($argv);
    die unless ($vars{flavor_name});

    $self->maker->file_vars(flavor_name => $vars{flavor_name});
    $self->maker->filename_vars('__FLAVOR_NAME__' => $vars{flavor_name});
}

sub run {
    my $self = shift;
    my $maker = $self->maker;

    $maker->render_all_files;
}

1;


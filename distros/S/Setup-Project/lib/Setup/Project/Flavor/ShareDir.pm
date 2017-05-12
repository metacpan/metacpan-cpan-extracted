package Setup::Project::Flavor::ShareDir;

use strict;
use warnings;
use parent qw/Setup::Project::ShareDir/;
use Setup::Project::Functions;

sub version  { "0.01" }
sub tmpl_dir { sharedir('Setup::Project', 'tmpl', 'ShareDir') }
sub argv { "package=Nanka::Module flavor_name=Light" }

sub parse {
    my ($self, $argv) = @_;
    die unless $argv;

    my %vars = equal_style($argv);
    die unless ($vars{flavor_name} && $vars{package});

    $self->maker->file_vars(
        package     => $vars{package},
        flavor_name => $vars{flavor_name},
    );

    my $package_path = $vars{package};
    $package_path    =~ s|::|/|g;
    $self->maker->filename_vars(
        '__PACKAGE__'     => $package_path,
        '__FLAVOR_NAME__' => $vars{flavor_name},
    );
}


sub run {
    my $self = shift;
    my $maker = $self->maker;

    $maker->render_all_files;
}

1;

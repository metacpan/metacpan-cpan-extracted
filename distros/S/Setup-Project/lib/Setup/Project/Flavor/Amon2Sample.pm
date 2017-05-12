package Setup::Project::Flavor::Amon2Sample;

use strict;
use warnings;
use parent qw/Setup::Project::ShareDir/;
use Setup::Project::Functions;

sub version  { "0.01" }
sub tmpl_dir { sharedir('Setup::Project', 'tmpl', 'Amon2Sample') }
sub argv     { "package=MyProject author='hixi'" }

sub parse {
    my ($self, $argv) = @_;
    die unless $argv;

    my %vars = equal_style($argv);
    die unless ($vars{package} && $vars{author});

    $self->maker->file_vars(%vars);

    my $package_path = $vars{package};
    $package_path    =~ s|::|/|;
    $self->maker->filename_vars(
        '__PACKAGE__' => $package_path,
    );
}


sub run {
    my $self = shift;
    my $maker = $self->maker;

    $maker->render_all_files;
}

1;

package <% $package %>::Flavor::<% $flavor_name %>;

use strict;
use warnings;
use parent qw/Setup::Project::ShareDir/;
use Setup::Project::Functions;

sub version  { "0.01" }
sub tmpl_dir { sharedir('<% $package %>', 'tmpl', '<% $flavor_name %>'); }
sub argv     { "" }

sub parse {
    my ($self, $argv) = @_;
    die unless $argv;

    my %vars = equal_style($argv);

    $self->maker->file_vars(
        %vars,
        flavor_info => flavor_info(),
    );
    $self->maker->filename_vars();
}

sub run {
    my $self = shift;
    my $maker = $self->maker;

    $maker->render_all_files;
}

1;

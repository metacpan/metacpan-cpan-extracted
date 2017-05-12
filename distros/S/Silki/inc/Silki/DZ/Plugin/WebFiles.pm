package inc::Silki::DZ::Plugin::WebFiles;

use strict;
use warnings;
use namespace::autoclean;

use lib 'lib';

use Dist::Zilla::File::InMemory;
use File::Temp qw( tempfile );
use Silki::Web::Javascript;
use Silki::Web::CSS;

use Moose;

with 'Dist::Zilla::Role::FileGatherer';

sub gather_files {
    my ( $self, $arg ) = @_;

    my $css = Dist::Zilla::File::InMemory->new(
        name    => 'share/css/silki-combined.css',
        content => Silki::Web::CSS->new()->create_content(),
    );

    $self->add_file($css);

    my $js = Dist::Zilla::File::InMemory->new(
        name    => 'share/js/silki-combined.js',
        content => Silki::Web::Javascript->new()->create_content(),
    );

    $self->add_file($js);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

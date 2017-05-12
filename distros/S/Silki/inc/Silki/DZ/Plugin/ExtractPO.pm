package inc::Silki::DZ::Plugin::ExtractPO;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
    system( 'dev-bin/extract-po' );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

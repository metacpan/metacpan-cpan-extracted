package inc::Silki::DZ::Plugin::MakeTestSchema;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
    system( 'dev-bin/make-test-schema' );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

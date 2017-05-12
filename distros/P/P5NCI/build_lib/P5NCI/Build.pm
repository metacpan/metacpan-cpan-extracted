package P5NCI::Build;

use strict;
use warnings;

use File::Spec::Functions;

use base 'Module::Build';

sub ACTION_build
{
    my $self = shift;

    $self->build_test_library();
    $self->build_xs_files();
    $self->SUPER::ACTION_build( @_ );
}

sub build_test_library
{
    my $self     = shift;
    require ExtUtils::CBuilder or die "ExtUtils::CBuilder not installed!\n";

    my $b        = ExtUtils::CBuilder->new();
    my $src_file = catfile( 'src', 'nci_test.c' );
    my $obj_file = $b->object_file( $src_file );
    $obj_file    =~ s/src.+(nci_test.*)/$1/;

    return unless $self->should_build( $obj_file, $src_file );

    my $compiled = $b->compile( source => $src_file );
    my $lib_file = $b->link(   objects => $compiled );
}

sub should_build
{
    my ($self, $dest, @sources) = @_;

    return 1 unless -e $dest;

    for my $dependency (@sources)
    {
        return 1 if -M $dependency < -M $dest;
    }

    return;
}

sub build_xs_files
{
    my $self = shift;

    require P5NCI::GenerateXS or die "Can't load XS generator!\n";

    my ($xs_file, $call_list) = map { catfile( 'lib', $_ ) }
        qw( P5NCI.xs call_list.txt );

    return unless $self->should_build(
        $xs_file, $call_list, $INC{'P5NCI/GenerateXS.pm'}
    );

    P5NCI::GenerateXS::generate_xs( $xs_file, $call_list );
}

sub ACTION_clean
{
    my $self = shift;

    unlink( catfile(qw( lib P5NCI.xs ) ) );
    $self->SUPER::ACTION_clean( @_ );
}

1;

package Pg::CLI::Role::Executable;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.13';

use File::Which qw( which );
use MooseX::Types::Moose qw( Str );

use Moose::Role;

has executable => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_executable',
);

sub _build_executable {
    my $self = shift;

    my ($bin) = ( ref $self ) =~ /Pg::CLI::(\w+)/;

    my $path = which($bin);

    die "Cannot find $bin in your path"
        unless $path;
}

1;

package Pg::CLI::Role::Executable;
{
  $Pg::CLI::Role::Executable::VERSION = '0.11';
}

use Moose::Role;

use namespace::autoclean;

use File::Which qw( which );
use MooseX::Types::Moose qw( Str );

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

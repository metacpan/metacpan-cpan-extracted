package Pod::ProjectDocs::File;

use strict;
use warnings;

our $VERSION = '0.52';    # VERSION

use Moose::Role;
use IO::File;
use Carp();

has 'data' => ( is => 'ro', );

has 'default_name' => (
    is  => 'ro',
    isa => 'Str',
);

has 'is_bin' => (
    is      => 'rw',
    default => 0,
);

has 'config' => ( is => 'ro', );

has 'name' => (
    is  => 'rw',
    isa => 'Str',
);

has 'relpath' => (
    is  => 'rw',
    isa => 'Str',
);

sub _get_data {
    my $self = shift;
    return $self->data;
}

sub publish {
    my ( $self, $data ) = @_;
    $data ||= $self->_get_data();
    my $path = $self->get_output_path;
    my $mode = ">>";
    if ( $path =~ m/html$/ ) {
        $mode .= ':encoding(UTF-8)';
    }
    my $fh = IO::File->new( $path, $mode )
      or Carp::croak(qq/Can't open $path./);
    $fh->seek( 0, 0 );
    $fh->truncate(0);
    $fh->print($data);
    $fh->close;
    return;
}

sub get_output_path {
    my $self    = shift;
    my $outroot = $self->config->outroot;
    my $relpath = $self->relpath || $self->default_name;
    my $path    = File::Spec->catfile( $outroot, $relpath );
    return $path;
}

1;
__END__

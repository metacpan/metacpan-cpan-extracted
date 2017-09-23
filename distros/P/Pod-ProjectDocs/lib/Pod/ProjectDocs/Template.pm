package Pod::ProjectDocs::Template;

use strict;
use warnings;

our $VERSION = '0.49';    # VERSION

use Moose::Role;

use Template;
use File::Basename;
use File::Spec;
use Carp();

has '_curpath' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has '_tt' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        my $self = shift;
        Template->new(
            {
                FILTERS => {
                    relpath => sub {
                        my $path    = shift;
                        my $curpath = $self->_curpath();
                        my ( $name, $dir ) = fileparse $curpath, qr/\.html/;
                        return File::Spec->abs2rel( $path, $dir );
                    },
                    return2br => sub {
                        my $text = shift;
                        $text =~ s!\r\n!<br />!g;
                        $text =~ s!\n!<br />!g;
                        return $text;
                    }
                },
            }
        );
    },
);

sub process {
    my ( $self, $doc, $data, $output ) = @_;
    $self->_curpath( $doc->get_output_path );
    $self->_tt()->process( \$data, $output, \my $text )
      or Carp::croak( $self->_tt()->error );
    $self->_curpath('');
    return $text;
}

1;
__END__

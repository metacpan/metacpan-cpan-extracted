package Silki::Formatter::HTMLToWiki::Table::Cell;
{
  $Silki::Formatter::HTMLToWiki::Table::Cell::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Types qw( Int Str Bool );

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has colspan => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

has alignment => (
    is      => 'ro',
    isa     => enum( [qw( left right center )] ),
    default => 'left',
);

has is_header_cell => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has content => (
    traits  => ['String'],
    is      => 'rw',
    isa     => Str,
    default => q{},
    handles => {
        append_content => 'append',
    },
    init_arg => undef,
);

sub formatted_content {
    my $self  = shift;
    my $width = shift;

    $width += 4 * ( $self->colspan() - 1 );

    my $format
        = $self->alignment() eq 'left'  ? " %-${width}s   "
        : $self->alignment() eq 'right' ? "   %${width}s "
        :                                 "  %-${width}s  ";

    my $content = $self->content();
    $content =~ s/\n/ /g;

    return sprintf( $format, $content );
}

__PACKAGE__->meta()->make_immutable();

1;

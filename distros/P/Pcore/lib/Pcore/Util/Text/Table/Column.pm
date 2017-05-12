package Pcore::Util::Text::Table::Column;

use Pcore -class, -ansi;

has id  => ( is => 'ro', isa => Str, required => 1 );
has idx => ( is => 'ro', isa => Int, required => 1 );

has width => ( is => 'ro', isa => Maybe [PositiveInt] );

has title        => ( is => 'ro', isa => Str );
has title_color  => ( is => 'ro', isa => Maybe [Str], default => BOLD . WHITE );
has title_align  => ( is => 'ro', isa => Enum [ -1, 0, 1 ], default => 0 );
has title_valign => ( is => 'ro', isa => Enum [ -1, 0, 1 ], default => 1 );

has align  => ( is => 'ro', isa => Enum [ -1, 0, 1 ], default => -1 );
has valign => ( is => 'ro', isa => Enum [ -1, 0, 1 ], default => -1 );
has format => ( is => 'ro', isa => Maybe [ Str | CodeRef ] );

sub format_val ( $self, $val, $row ) {
    if ( $self->{format} ) {
        if ( !ref $self->{format} ) {
            $val = sprintf $self->{format}, $val;
        }
        else {
            $val = $self->{format}->( $val, $self->{id}, $row );
        }
    }

    return $val // q[];
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Text::Table::Column

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

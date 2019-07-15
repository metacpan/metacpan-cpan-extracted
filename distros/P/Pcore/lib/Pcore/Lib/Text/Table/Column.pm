package Pcore::Lib::Text::Table::Column;

use Pcore -class, -ansi;

has id  => ( required => 1 );
has idx => ( required => 1 );    # Int

has width => ();                 # Maybe [PositiveInt]

has title        => ();
has title_color  => ( $BOLD . $WHITE );
has title_align  => (0);                  # Enum [ -1, 0, 1 ]
has title_valign => (1);                  # Enum [ -1, 0, 1 ]

has align  => (-1);                       # Enum [ -1, 0, 1 ]
has valign => (-1);                       # Enum [ -1, 0, 1 ]
has format => ();                         # Maybe [ Str | CodeRef ]

sub format_val ( $self, $val, $row ) {
    if ( $self->{format} ) {
        if ( !ref $self->{format} ) {
            $val = sprintf $self->{format}, $val;
        }
        else {
            $val = $self->{format}->( $val, $self->{id}, $row );
        }
    }

    return $val // $EMPTY;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Text::Table::Column

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

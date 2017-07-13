package PICA::Parser::Plus;
use strict;
use warnings;

our $VERSION = '0.33';

use charnames qw(:full);
use Carp qw(carp croak);

use parent 'PICA::Parser::Base';

sub SUBFIELD_INDICATOR { "\N{INFORMATION SEPARATOR ONE}" }
sub END_OF_FIELD       { "\N{INFORMATION SEPARATOR TWO}" }
sub END_OF_RECORD      { "\N{LINE FEED}" }

sub _next_record {
    my ($self) = @_;
     
    # TODO: does only work if END_OF_RECORD is LINE FEED
    local $/ = $self->END_OF_RECORD;
    my $line = $self->{reader}->getline // return;
    chomp $line;

    my @fields = split $self->END_OF_FIELD, $line;
    my @record;

    if (@fields and index($fields[0],$self->SUBFIELD_INDICATOR) == -1) {
        # drop leader because usage is unclear
        shift @fields;
    }

    foreach my $field (@fields) {
        my ($tag, $occurence, $data);
        if ( $field =~ m/^(\d{3}[A-Z@])(\/(\d{2}))?\s(.+)/ ) {
            $tag       = $1;
            $occurence = $3 // '';
            $data      = $4;
        }
        else {
            if ( $self->{strict} ) {
                croak "ERROR: no valid PICA field structure \"$field\"";
            }
            else {
                carp
                    "WARNING: no valid PICA field structure \"$field\". Skipped field";
                next;
            }
        }

        my @subfields = map { substr( $_, 0, 1 ), substr( $_, 1 ) }
                        split( $self->SUBFIELD_INDICATOR, substr( $data, 1 ) );
        push @record, [ $tag, $occurence, @subfields ];
    }

    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::Plus - Normalized PICA+ format parser

=head2 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and details.

The counterpart of this module is L<PICA::Writer::Plus>.

=head2 Configuration

See L<PICA::Parser::Base> for common configuration parameters.

=over
 
=item C<strict>

By default faulty fields in records are skipped with warnings. You can make them fatal by setting the I<strict> parameter to 1.
 
=back

=cut

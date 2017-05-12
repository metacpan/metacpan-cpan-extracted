package ParseEmptyTagsTest;
use base qw(Test::C2FIT::ColumnFixture);

sub getText { $_[0]->{text} }

1;

package ParseEmptyTagsTest2;
use base qw(Test::C2FIT::Fixture);

sub doRows {
    my $self = shift;
    my ($rows) = @_;
    $self->SUPER::doRows( $rows->more() );
}

sub doCell {
    my $self = shift;
    my ( $cell, $columnNumber ) = @_;
    if ( $columnNumber == 1 ) {
        $self->info( $cell, "was here" );
    }
    if ( $columnNumber == 2 ) {
        if ( $cell->text eq "error" ) {
            $self->right($cell);
        }
        else {
            $self->wrong( $cell, "error" );
        }
    }
}

1;

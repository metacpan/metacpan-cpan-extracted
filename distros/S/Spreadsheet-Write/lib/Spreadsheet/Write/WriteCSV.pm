package Spreadsheet::Write::WriteCSV;

use 5.008;
use base qw'Spreadsheet::Write';

use Text::CSV 1.18;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    my $filename = $args{'file'} || $args{'filename'} || die "Need filename.";
    $self->{'_FILENAME'}    = $filename;

    $args{'csv_options'}->{'sep_char'}  ||= ",";
    $args{'csv_options'}->{'eol'}       ||= $/;

    $self->{'_CSV_OPTIONS'} = $args{'csv_options'};

    return $self;
}

sub _prepare {
    my $self = shift;
    $self->{'_CSV_OBJ'}||=Text::CSV->new($self->{'_CSV_OPTIONS'});
    return $self;
}

sub close {
    my $self=shift;
    return if $self->{'_CLOSED'};
    $self->{'_FH'}->close if $self->{'_FH'};
    $self->{'_CLOSED'}=1;
    return $self;
}

sub _add_prepared_row {
    my $self = shift;

    my @texts;
    foreach (@_) {
        my $content = $_->{'content'};

        $content = sprintf($content, $_->{'sprintf'})
            if $_->{'sprintf'};

        push @texts, $content;
    }

    $self->{'_CSV_OBJ'}->print($self->{'_FH'},\@texts) ||
        die "csv_combine failed at ".$self->{'_CSV_OBJ'}->error_input();

    return $self;
}

###############################################################################
1;

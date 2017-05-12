package Orze::Sources::Include;

use strict;
use warnings;

use base "Orze::Sources";

=head1 NAME

Orze::Sources::Include - Simply load a file and make its content
available in a variable

=head1 DESCRIPTION

Use the C<file> attribute to give the filename.

=head1 METHOD

=head2 evaluate

=cut

sub evaluate {
    my ($self) = @_;

    my $page = $self->{page};
    my $var  = $self->{var};
    my $file = $self->file();

    if (-r $file) {
        open my $handle, "<", $file;
        my @lines = <$handle>;
        close $handle;
        my $value = join('', @lines);
        return $value;
    }
    else {
        $self->warning("unable to read file " . $file);
    }
}

1;

package Orze::Sources::YAML;

use strict;
use warnings;

use base "Orze::Sources";

use YAML qw/LoadFile/;

=head1 NAME

Orze::Sources::YAML - Load a YAML file in a perl variable

=head1 DESCRIPTION

Take the file given in the C<file> attribute, append C<.yml> suffix,
load it.

=head1 METHOD

=head2 evaluate

=cut

sub evaluate {
    my ($self) = @_;

    my $page = $self->{page};
    my $var  = $self->{var};
    my $file = $self->file("yml");

    if (-r $file) {
        return LoadFile($file);
    }
    else {
        $self->warning("unable to read file " . $file);
    }
}

1;

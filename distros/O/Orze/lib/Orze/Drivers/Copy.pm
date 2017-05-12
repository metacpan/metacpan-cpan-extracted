package Orze::Drivers::Copy;

use strict;
use warnings;

use File::Copy::Recursive qw/rcopy/;

use base "Orze::Drivers";

=head1 NAME

Orze::Drivers::Copy - Create a page by copying a file

=head1 DESCRIPTION

Create a page by copying a file from the C<data/> directory to the
C<www/> directory.

=head1 EXAMPLE

   <page name="images/cool"
         extension="png"
         driver="Copy">
   </page>

This snippet of an xml project description copy the file
C<data/outputdir/images/cool.png> to C<www/outputdir/images/cool.png>

=head1 METHODS

=head2 process

Do the real processing

=cut

sub process {
    my ($self) = @_;

    my $page = $self->{page};

    my ($source, $target) = $self->paths($page->att('name'));
    rcopy($source, $target);
}

1;

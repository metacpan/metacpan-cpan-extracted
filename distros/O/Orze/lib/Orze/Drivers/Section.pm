package Orze::Drivers::Section;

use strict;
use warnings;

use File::Path;

use base "Orze::Drivers";

=head1 NAME

Orze::Drivers::Section - Creates a subsection

=head1 DESCRIPTION

It creates an empty directory in the website tree.

Regarding changing the output directory (or adding a relative path in
the name), it is mainly useful if you want to create a menu of these
subsections.

=head1 EXAMPLE

    <page name="photos">
        <var name="title">Photos</var>
        <var name="sections" src="Menu"/>
        <page name="2008" driver="Section">
             <!-- photo gallery of 2008 events -->
        </page>
        <page name="2007" driver="Section">
             <!-- photo gallery of 2007 events -->
        </page>
        <!-- ... -->
    </page>

The two commented parts will be but in C<2008/> and C<2007/> directories.
The C<sections> variable will contain the following tree:

   | 2008
   | |--> Event 1
   | |--> Event 2
   |
   | 2007
   | |--> Event 1
   | |--> Event 2

=head1 METHODS

=head2 process

Do the real processing

=cut

sub process {
    my ($self) = @_;

    my $page = $self->{page};
    my $name = $page->att('name');

    mkpath($self->output($name));
}

1;

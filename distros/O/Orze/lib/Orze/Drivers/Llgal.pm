package Orze::Drivers::Llgal;

use strict;
use warnings;

use File::Copy::Recursive qw/dircopy/;
use Template;
use String::Escape qw/quote/;

use base "Orze::Drivers";

=head1 NAME

Orze::Drivers::Llgal - Create a photo gallery using Llgal

=head1 DESCRIPTION

This driver copies a directory in the C<www/> directory and run llgal
into it.

=head1 EXAMPLE

	<page name="cool-event" driver="Llgal">
        <var name="title">Cool event</var>
	</page>

=head1 SEE ALSO

Look at C<llgal(1)> and L<http://home.gna.org/llgal/>.

=cut

=head1 METHODS

Do the real processing

=head2 process

=cut

sub process {
    my ($self) = @_;

    my $page = $self->{page};
    my $variables = $self->{variables};

    $variables->{root} = "../" . $self->root();

    my $path = $page->att('path');

    my $name = $page->att('name');
    $variables->{page} = $name;

    my $extension = $page->att('extension');
    $variables->{extension} = $extension;

    $variables->{css} = ".llgal/llgal";

    my $title = $variables->{title};

    my $output = $self->output($name);

    my $tt = Template->new(
                           RELATIVE => 1,
                           INCLUDE_PATH => [
                                            "includes/Template",
                                            "includes/Llgal",
                                            "templates/Llgal",
                                            ],
                           );

    $tt->process("indextemplate.html",
                 $variables,
                 "tmp/" . $path . $name . "/indextemplate.html",
                 )
        || $self->warning($tt->error());
    $tt->process("slidetemplate.html",
                 $variables,
                         "tmp/" . $path . $name . "/slidetemplate.html",
                 )
        || $self->warning($tt->error());
    $tt->process("llgal.css",
                 $variables,
                 "tmp/" . $path . $name . "/llgal.css",
                 )
        || $self->warning($tt->error());
    $tt->process("llgalrc",
                 $variables,
                 "tmp/" . $path . $name . "/llgalrc",
                 )
        || $self->warning($tt->error());

    my $command = "llgal "
        . "-d " . $output . " "
        . "--title " . quote($title) . " "
        . "--config tmp/$path$name/llgalrc "
        . "--templates tmp/$path$name "
        . ">/dev/null";

    dircopy($self->input($name), $output);
    system $command;
}

1;

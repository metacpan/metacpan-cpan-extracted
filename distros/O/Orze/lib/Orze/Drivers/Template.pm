package Orze::Drivers::Template;

use strict;
use warnings;

use Template;

use base "Orze::Drivers";

=head1 NAME

Orze::Drivers::Template - Create a page using the Template module

=head1 DESCRIPTION

This driver uses the famous Template module to create pages. It process
the given template using all the variables of the page as its own
variables.

It takes care of the following attributes:

=over

=item template

The template that will be used. Notice that the default value is "index".

=back

All the templates must be put in the C<templates/Template> directory.
The C<includes/Template> directory will be used for all the includes
defined in the template file.

The new file will be put in C<www/outputdir/> according the current
page path and name.

=head1 EXAMPLE

	<page name="index" template="foobar" >
		<var name="title">Homepage</var>
		<var name="content">Hello world</var>
	</page>

=head1 SEE ALSO

Lookt at L<Template> for the template language.

=head1 METHODS

=head2 process

Do the real processing

=cut

sub process {
    my ($self) = @_;

    my $page = $self->{page};
    my $variables = $self->{variables};

    my $template = $page->att('template');
    my $extension = $page->att('extension');

    $variables->{root} = $self->root();

    my $name = $page->att('name');
    $variables->{page} = $name;

    my $output = $self->output($name . "." . $extension);

    my $tt = Template->new(
                           RELATIVE => 1,
                           INCLUDE_PATH => [
                                            "includes/Template",
                                            "templates/Template",
                                            ],
                           );

    $tt->process($template . "." . $extension,
                 $variables,
                 $output,
                 )
        || $self->warning("processing error, ", $tt->error());
}

1;

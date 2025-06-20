package Reactive::Core::TemplateRenderer;

use warnings;
use strict;

use Moo;
use namespace::clean;
use Types::Standard qw(InstanceOf);

use Reactive::Core::JSONRenderer;

use constant {
    RENDER_TEMPLATE_FILE => 'File',
    RENDER_TEMPLATE_INLINE => 'Inline',
};

has json_renderer => (is => 'lazy', isa => InstanceOf['Reactive::Core::JSONRenderer']);

=head2 render($self, $type, $template, %properties)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core->_to_snapshot

    This method must be overridden with a renderer specific implemenation, for example see Reactive::Mojo implementation

    $type may be 'File' or 'Inline' (RENDER_TEMPLATE_FILE | RENDER_TEMPLATE_INLINE)

    if 'File' then $template will be the path to the file
    if 'Inline' then $template will be the inline template

    %parameters will be the data that should be passed to the template
    it will always include a key of 'self' which will be the component object
    it will also include any data returned by $component->r_get_properties
    which by default will include all public properties on the component

    this method should return a string of html
=cut
sub render {
    my $self = shift;
    my $type = shift;
    my $template = shift;
    my %paramters = @_;

    die "Method `->render(\$type, \$template, \%args)` must be overridden in subclass. $self";
}

=head2 escape($self, $string)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core::TemplateRenderer->inject_attribute

    will convert special characters in the string passed to their html entity equivilent
    eg '<' => '&lt;'

    should be overriden by the framework specific plugin,
    eg Reactive::Mojo::TemplateRenderer overrides this with Mojo::Util->xml_escape
=cut
sub escape {
    my $self = shift;
    my $string = shift;

    die "Method `->escape(\$string)` must be overridden in subclass. $self";
}

=head2 inject_snapshot($self, $html, $snapshot)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core->initial_render

    $html will be the string returned from ->render
    $snapshot will be a HashRef containing various data about the state of the component

    this method will embed that snapshot data into a `reactive:snapshot` attribute on the
    root node of the html
=cut
sub inject_snapshot {
    my $self = shift;
    my $html = shift;
    my $snapshot = shift;

    return $self->inject_attribute($html, 'reactive:snapshot', $snapshot);
}

=head2 inject_attribute($self, $html, $attribute, $value)
    This method is not expected to be called directly via userland code
    but instead will be called by ->inject_snapshot

    $html will be the string returned from ->render
    $attribute will be a string with the attribute name
    $value will be a HashRef containing various data about the state of the component

    this method will json encode the value and embed the result into the root node of the
    html as $attribute

    it will then return the resulting string of html
=cut
sub inject_attribute {
    my $self = shift;
    my $html = shift;
    my $attribute = shift;
    my $value = shift;

    my $escaped_value = $self->escape($self->json_renderer->render($value));

    $html =~ s/^\s*(<[a-z\-]+(?:\s[^\/>]+)*)(\s*)(\/?>)/$1 $attribute="$escaped_value" $3/m;

    return $html;
}

sub _build_json_renderer {
    return Reactive::Core::JSONRenderer->new();
}

=head1 AUTHOR

Robert Moore, C<< <robert at r-moore.tech> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-reactive-core at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Reactive-Core>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Reactive::Core


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Reactive-Core>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Reactive-Core>

=item * Search CPAN

L<https://metacpan.org/release/Reactive-Core>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Robert Moore.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;

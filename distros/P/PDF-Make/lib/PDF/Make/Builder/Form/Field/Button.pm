package PDF::Make::Builder::Form::Field::Button;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field::Button',
        extends => 'PDF::Make::Builder::Form::Field',
        'caption:Str',
        'submit_url:Str',
        'url:Str',
        'is_reset:Bool:default(0)',
        'javascript:Str',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field::Button');
}

sub BUILD {
    my ($self) = @_;
    $self->h(28);
    $self->border_colour('#2c3e50');
    $self->bg_colour('#ecf0f1');
}

sub _draws_own_chrome { 1 }

sub _create_field {
    my ($self, $doc, $name, $fx, $fy, $fw, $fh) = @_;
    my $cap = $self->caption // $self->label // $name;
    my $field = PDF::Make::FieldPtr::button($doc, $name, $fx, $fy, $fw, $fh, $cap);

    my $submit = submit_url $self;
    my $uri    = url $self;
    my $rst    = is_reset $self;
    my $js     = javascript $self;

    if (defined $uri && length $uri) {
        $field->set_uri_action($uri);
    } elsif (defined $submit && length $submit) {
        $field->set_submit_url($submit);
    } elsif ($rst) {
        $field->set_reset_action;
    } elsif (defined $js && length $js) {
        $field->set_javascript($js);
    }

    return $field;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Form::Field::Button - Push button form field

=head1 SYNOPSIS

    # Submit form data to a URL
    $b->add_field(
        type       => 'button',
        name       => 'submit',
        caption    => 'Submit',
        submit_url => 'https://example.com/submit',
        w          => 100,
    );

    # Reset all form fields
    $b->add_field(
        type       => 'button',
        name       => 'reset',
        caption    => 'Reset',
        is_reset   => 1,
        w          => 100,
    );

    # JavaScript action
    $b->add_field(
        type       => 'button',
        name       => 'alert',
        caption    => 'Click Me',
        javascript => 'app.alert("Hello from PDF!");',
        w          => 120,
    );

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Form::Field>, plus:

=over 4

=item C<caption> (Str) - Button face text. Defaults to C<label> or C<name>.

=item C<url> (Str) - URL to open when clicked (works in all PDF viewers).

=item C<submit_url> (Str) - URL to submit form data to (HTML format).

=item C<is_reset> (Bool, default 0) - Make this a form reset button.

=item C<javascript> (Str) - JavaScript code to execute on click (requires
Adobe Acrobat or compatible viewer).

=back

Only one action type can be set per button. Priority: url > submit_url > is_reset > javascript.

=head1 SEE ALSO

L<PDF::Make::Builder::Form::Field>, L<PDF::Make::Builder>

=cut

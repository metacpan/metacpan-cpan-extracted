package PDF::Make::Form;

use strict;
use warnings;
no warnings qw(redefine prototype);  # XS methods are overridden by Perl wrappers
use PDF::Make;
use PDF::Make::Field;

=encoding utf8

=head1 NAME

PDF::Make::Form - PDF interactive forms (AcroForms) for PDF::Make

=head1 SYNOPSIS

    use PDF::Make;
    
    my $pdf = PDF::Make->new();
    my $page = $pdf->add_page(width => 612, height => 792);
    
    # Create a form
    my $form = $pdf->create_form();
    
    # Add a text field
    my $name_field = $form->add_text_field(
        name   => 'name',
        x      => 100,
        y      => 700,
        width  => 200,
        height => 20,
    );
    $name_field->set_value('John Doe');
    $name_field->add_to_page($page);
    
    # Add a checkbox
    my $checkbox = $form->add_checkbox(
        name     => 'agree',
        x        => 100,
        y        => 650,
        width    => 15,
        height   => 15,
        on_value => 'Yes',
    );
    $checkbox->set_value('Yes');  # Check it
    $checkbox->add_to_page($page);
    
    # Finalize and render
    $form->finalize();
    my $bytes = $pdf->render();

=head1 DESCRIPTION

This module provides PDF interactive forms (AcroForms) support per
ISO 32000-2:2020 §12.7. It supports:

=over 4

=item * Text fields (single-line, multiline, password)

=item * Checkboxes and radio button groups

=item * Dropdown (combo) and list boxes

=item * Push buttons

=item * Signature fields (placeholder)

=item * FDF/XFDF export and import

=item * Form flattening

=back

=head1 METHODS

=cut

use constant {
    # Field flags (matching C header)
    FF_READONLY       => (1 << 0),
    FF_REQUIRED       => (1 << 1),
    FF_NOEXPORT       => (1 << 2),
    FF_MULTILINE      => (1 << 12),
    FF_PASSWORD       => (1 << 13),
    FF_FILESELECT     => (1 << 20),
    FF_DONOTSPELLCHECK => (1 << 22),
    FF_DONOTSCROLL    => (1 << 23),
    FF_COMB           => (1 << 24),
    FF_RICHTEXT       => (1 << 25),
    FF_NOTOGGLETOOFF  => (1 << 14),
    FF_RADIO          => (1 << 15),
    FF_PUSHBUTTON     => (1 << 16),
    FF_RADIOSINUNISON => (1 << 25),
    FF_COMBO          => (1 << 17),
    FF_EDIT           => (1 << 18),
    FF_SORT           => (1 << 19),
    FF_MULTISELECT    => (1 << 21),
    FF_COMMITONSELCHANGE => (1 << 26),
    
    # Quadding (text alignment)
    QUADDING_LEFT   => 0,
    QUADDING_CENTER => 1,
    QUADDING_RIGHT  => 2,
};

our @EXPORT_OK = qw(
    FF_READONLY FF_REQUIRED FF_NOEXPORT
    FF_MULTILINE FF_PASSWORD FF_FILESELECT FF_DONOTSPELLCHECK
    FF_DONOTSCROLL FF_COMB FF_RICHTEXT
    FF_NOTOGGLETOOFF FF_RADIO FF_PUSHBUTTON FF_RADIOSINUNISON
    FF_COMBO FF_EDIT FF_SORT FF_MULTISELECT FF_COMMITONSELCHANGE
    QUADDING_LEFT QUADDING_CENTER QUADDING_RIGHT
);

our %EXPORT_TAGS = (
    flags    => [qw(FF_READONLY FF_REQUIRED FF_NOEXPORT FF_MULTILINE 
                    FF_PASSWORD FF_COMB FF_COMBO FF_EDIT FF_MULTISELECT)],
    quadding => [qw(QUADDING_LEFT QUADDING_CENTER QUADDING_RIGHT)],
    all      => \@EXPORT_OK,
);

=head2 new

    my $form = PDF::Make::Form->new($document);

Create a new form for the given document. Usually called via
C<< $pdf->create_form() >> rather than directly.

=cut

sub new {
    my ($class, $doc) = @_;
    
    die "PDF::Make::Form->new: document required" unless $doc;
    
    # $doc is the raw pdfmake_doc_t pointer (Document object)
    my $form = PDF::Make::FormPtr::create($doc);
    
    return bless {
        _form   => $form,
        _doc    => $doc,
        _fields => [],
    }, $class;
}

=head2 add_text_field

    my $field = $form->add_text_field(
        name   => 'field_name',
        x      => 100,
        y      => 500,
        width  => 200,
        height => 20,
    );

Create a text field at the specified location.

Options:

=over 4

=item * name - Field name (required)

=item * x, y - Lower-left corner coordinates

=item * width, height - Field dimensions

=item * value - Initial value

=item * default_value - Default value for reset

=item * max_len - Maximum characters allowed

=item * multiline - Enable multiline input

=item * password - Mask input as password

=item * readonly - Make field read-only

=item * required - Mark as required

=item * quadding - Text alignment (0=left, 1=center, 2=right)

=item * da - Default appearance string

=back

=cut

sub add_text_field {
    my ($self, %opts) = @_;
    
    my $name   = delete $opts{name}   or die "add_text_field: name required";
    my $x      = delete $opts{x}      // 0;
    my $y      = delete $opts{y}      // 0;
    my $width  = delete $opts{width}  // 100;
    my $height = delete $opts{height} // 20;
    
    my $field = PDF::Make::FieldPtr::text(
        $self->{_doc}, $name, $x, $y, $width, $height
    );
    
    $self->_configure_field($field, %opts);
    
    push @{$self->{_fields}}, $field;
    
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 add_checkbox

    my $field = $form->add_checkbox(
        name     => 'agree',
        x        => 100,
        y        => 500,
        width    => 15,
        height   => 15,
        on_value => 'Yes',
    );

Create a checkbox field.

=cut

sub add_checkbox {
    my ($self, %opts) = @_;
    
    my $name     = delete $opts{name}     or die "add_checkbox: name required";
    my $x        = delete $opts{x}        // 0;
    my $y        = delete $opts{y}        // 0;
    my $width    = delete $opts{width}    // 15;
    my $height   = delete $opts{height}   // 15;
    my $on_value = delete $opts{on_value} // 'Yes';
    
    my $field = PDF::Make::FieldPtr::checkbox(
        $self->{_doc}, $name, $x, $y, $width, $height, $on_value
    );
    
    $self->_configure_field($field, %opts);
    
    push @{$self->{_fields}}, $field;
    
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 add_radio_group

    my $group = $form->add_radio_group(name => 'choice');
    $group->add_option(x => 100, y => 500, width => 15, height => 15, value => 'A');
    $group->add_option(x => 100, y => 480, width => 15, height => 15, value => 'B');
    $group->add_option(x => 100, y => 460, width => 15, height => 15, value => 'C');

Create a radio button group.

=cut

sub add_radio_group {
    my ($self, %opts) = @_;
    
    my $name = delete $opts{name} or die "add_radio_group: name required";
    
    my $group = PDF::Make::FieldPtr::radio_group($self->{_doc}, $name);
    
    push @{$self->{_fields}}, $group;
    
    return PDF::Make::Field->_wrap($group, $self);
}

=head2 add_choice

    my $field = $form->add_choice(
        name    => 'country',
        x       => 100,
        y       => 500,
        width   => 150,
        height  => 20,
        combo   => 1,          # 1 for dropdown, 0 for listbox
        options => [
            { display => 'United States', export => 'US' },
            { display => 'Canada', export => 'CA' },
            { display => 'Mexico', export => 'MX' },
        ],
    );

Create a choice field (dropdown or listbox).

=cut

sub add_choice {
    my ($self, %opts) = @_;
    
    my $name    = delete $opts{name}    or die "add_choice: name required";
    my $x       = delete $opts{x}       // 0;
    my $y       = delete $opts{y}       // 0;
    my $width   = delete $opts{width}   // 100;
    my $height  = delete $opts{height}  // 20;
    my $combo   = delete $opts{combo}   // 1;
    my $options = delete $opts{options} // [];
    
    my $field = PDF::Make::FieldPtr::choice(
        $self->{_doc}, $name, $x, $y, $width, $height, $combo
    );
    
    # Add options
    for my $opt (@$options) {
        if (ref $opt eq 'HASH') {
            my $display = $opt->{display};
            my $export = $opt->{export};
            if (defined $export) {
                $field->add_option($display, $export);
            } else {
                $field->add_option($display);
            }
        } else {
            $field->add_option($opt);
        }
    }
    
    $self->_configure_field($field, %opts);
    
    push @{$self->{_fields}}, $field;
    
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 add_combo

    my $field = $form->add_combo(name => 'country', ...);

Shorthand for C<add_choice(combo => 1, ...)>.

=cut

sub add_combo {
    my ($self, %opts) = @_;
    return $self->add_choice(%opts, combo => 1);
}

=head2 add_listbox

    my $field = $form->add_listbox(name => 'items', ...);

Shorthand for C<add_choice(combo => 0, ...)>.

=cut

sub add_listbox {
    my ($self, %opts) = @_;
    return $self->add_choice(%opts, combo => 0);
}

=head2 add_button

    my $field = $form->add_button(
        name    => 'submit',
        x       => 100,
        y       => 100,
        width   => 80,
        height  => 25,
        caption => 'Submit',
    );

Create a push button.

=cut

sub add_button {
    my ($self, %opts) = @_;
    
    my $name    = delete $opts{name}    or die "add_button: name required";
    my $x       = delete $opts{x}       // 0;
    my $y       = delete $opts{y}       // 0;
    my $width   = delete $opts{width}   // 80;
    my $height  = delete $opts{height}  // 25;
    my $caption = delete $opts{caption} // $name;
    
    my $field = PDF::Make::FieldPtr::button(
        $self->{_doc}, $name, $x, $y, $width, $height, $caption
    );
    
    $self->_configure_field($field, %opts);
    
    push @{$self->{_fields}}, $field;
    
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 add_signature

    my $field = $form->add_signature(
        name   => 'sig',
        x      => 100,
        y      => 100,
        width  => 200,
        height => 50,
    );

Create a signature field (placeholder for digital signature).

=cut

sub add_signature {
    my ($self, %opts) = @_;
    
    my $name   = delete $opts{name}   or die "add_signature: name required";
    my $x      = delete $opts{x}      // 0;
    my $y      = delete $opts{y}      // 0;
    my $width  = delete $opts{width}  // 200;
    my $height = delete $opts{height} // 50;
    
    my $field = PDF::Make::FieldPtr::signature(
        $self->{_doc}, $name, $x, $y, $width, $height
    );
    
    $self->_configure_field($field, %opts);
    
    push @{$self->{_fields}}, $field;
    
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 field_count

    my $count = $form->field_count();

Return the number of top-level fields.

=cut

sub field_count {
    my ($self) = @_;
    return $self->{_form}->field_count();
}

=head2 field_at

    my $field = $form->field_at($index);

Get field at the given index.

=cut

sub field_at {
    my ($self, $idx) = @_;
    my $field = $self->{_form}->field_at($idx);
    return unless $field;
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 field_by_name

    my $field = $form->field_by_name('person.name.first');

Find a field by its full name.

=cut

sub field_by_name {
    my ($self, $name) = @_;
    my $field = $self->{_form}->field_by_name($name);
    return unless $field;
    return PDF::Make::Field->_wrap($field, $self);
}

=head2 fields

    my @fields = $form->fields();

Get all top-level fields.

=cut

sub fields {
    my ($self) = @_;
    return map { PDF::Make::Field->_wrap($_, $self) } $self->{_form}->fields();
}

=head2 finalize

    $form->finalize();

Finalize the form: create AcroForm dictionary, field dictionaries,
widget annotations, and appearance streams. Call this before rendering.

=cut

sub finalize {
    my ($self) = @_;
    $self->{_form}->finalize();
    return $self;
}

=head2 flatten

    $form->flatten();

Flatten all form fields: render values into page content and remove
interactive elements. After flattening, the PDF is no longer editable.

=cut

sub flatten {
    my ($self) = @_;
    $self->{_form}->flatten();
    return $self;
}

=head2 export_fdf

    my $fdf_data = $form->export_fdf();

Export form data in FDF format.

=cut

sub export_fdf {
    my ($self) = @_;
    return $self->{_form}->export_fdf();
}

=head2 export_xfdf

    my $xfdf_data = $form->export_xfdf();

Export form data in XFDF (XML) format.

=cut

sub export_xfdf {
    my ($self) = @_;
    return $self->{_form}->export_xfdf();
}

=head2 import_fdf

    $form->import_fdf($fdf_data);

Import form data from FDF format.

=cut

sub import_fdf {
    my ($self, $data) = @_;
    $self->{_form}->import_fdf($data);
    return $self;
}

=head2 import_xfdf

    $form->import_xfdf($xfdf_data);

Import form data from XFDF format.

=cut

sub import_xfdf {
    my ($self, $data) = @_;
    $self->{_form}->import_xfdf($data);
    return $self;
}

=head2 set_need_appearances

    $form->set_need_appearances(1);

Set the NeedAppearances flag. If true, the PDF viewer will generate
field appearances. If false (default), appearances are generated
during finalization.

=cut

sub set_need_appearances {
    my ($self, $need) = @_;
    $self->{_form}->set_need_appearances($need ? 1 : 0);
    return $self;
}

# Internal: configure field with common options
sub _configure_field {
    my ($self, $field, %opts) = @_;
    
    if (defined $opts{value}) {
        $field->set_value($opts{value});
    }
    if (defined $opts{default_value}) {
        $field->set_default_value($opts{default_value});
    }
    if (defined $opts{max_len}) {
        $field->set_max_len($opts{max_len});
    }
    if (defined $opts{quadding}) {
        $field->set_quadding($opts{quadding});
    }
    if (defined $opts{da}) {
        $field->set_da($opts{da});
    }
    
    # Flags
    if ($opts{multiline}) {
        $field->multiline(1);
    }
    if ($opts{password}) {
        $field->password(1);
    }
    if ($opts{readonly}) {
        $field->readonly(1);
    }
    if ($opts{required}) {
        $field->required(1);
    }
}

# Internal: get raw form pointer
sub _form {
    return $_[0]->{_form};
}

1;

__END__

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Field>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package PDF::Make::Field;

use strict;
use warnings;
no warnings qw(redefine prototype);  # XS methods are overridden by Perl wrappers
use PDF::Make;
use PDF::Make::Form;

=head1 NAME

PDF::Make::Field - PDF form field for PDF::Make

=head1 SYNOPSIS

    use PDF::Make;
    
    my $pdf = PDF::Make->new();
    my $page = $pdf->add_page(width => 612, height => 792);
    my $form = $pdf->create_form();
    
    # Create and configure a text field
    my $field = $form->add_text_field(
        name   => 'name',
        x      => 100,
        y      => 700,
        width  => 200,
        height => 20,
    );
    
    # Set properties
    $field->set_value('John Doe');
    $field->readonly(1);
    $field->align_center();
    
    # Add to page
    $field->add_to_page($page);

=head1 DESCRIPTION

This class represents a PDF form field. Fields are created via the
L<PDF::Make::Form> methods like C<add_text_field>, C<add_checkbox>, etc.

=head1 METHODS

=cut

# Constructor - internal use only
sub _wrap {
    my ($class, $field, $form) = @_;
    return bless {
        _field => $field,
        _form  => $form,
    }, $class;
}

=head2 type

    my $type = $field->type();

Return the field type as a string: 'text', 'button', 'choice', or 'signature'.

=cut

sub type {
    return $_[0]->{_field}->type();
}

=head2 name

    my $name = $field->name();

Return the partial field name.

=cut

sub name {
    return $_[0]->{_field}->name();
}

=head2 full_name

    my $full_name = $field->full_name();

Return the full field name (includes parent hierarchy).

=cut

sub full_name {
    return $_[0]->{_field}->full_name();
}

=head2 value

    my $value = $field->value();
    $field->value('new value');

Get or set the field value.

=cut

sub value {
    my ($self, $val) = @_;
    if (@_ > 1) {
        $self->{_field}->value($val);
        return $self;
    }
    return $self->{_field}->value();
}

=head2 set_value

    $field->set_value('value');

Set the field value.

=cut

sub set_value {
    my ($self, $val) = @_;
    $self->{_field}->set_value($val);
    return $self;
}

=head2 set_default_value

    $field->set_default_value('default');

Set the default value (used when form is reset).

=cut

sub set_default_value {
    my ($self, $val) = @_;
    $self->{_field}->set_default_value($val);
    return $self;
}

=head2 flags

    my $flags = $field->flags();

Return the field flags as an integer.

=cut

sub flags {
    return $_[0]->{_field}->flags();
}

=head2 set_flags

    $field->set_flags($flags);

Set the field flags (replaces existing).

=cut

sub set_flags {
    my ($self, $flags) = @_;
    $self->{_field}->set_flags($flags);
    return $self;
}

=head2 add_flags

    $field->add_flags($flags);

Add flags to the existing set.

=cut

sub add_flags {
    my ($self, $flags) = @_;
    $self->{_field}->add_flags($flags);
    return $self;
}

=head2 clear_flags

    $field->clear_flags($flags);

Clear specific flags.

=cut

sub clear_flags {
    my ($self, $flags) = @_;
    $self->{_field}->clear_flags($flags);
    return $self;
}

=head2 readonly

    $field->readonly(1);   # Make read-only
    $field->readonly(0);   # Make editable
    my $ro = $field->readonly(); # Alias for is_readonly

Set or check the read-only flag.

=cut

sub readonly {
    my ($self, $val) = @_;
    if (@_ > 1) {
        $self->{_field}->readonly($val ? 1 : 0);
        return $self;
    }
    return $self->{_field}->is_readonly();
}

=head2 is_readonly

    if ($field->is_readonly()) { ... }

Check if field is read-only.

=cut

sub is_readonly {
    return $_[0]->{_field}->is_readonly();
}

=head2 required

    $field->required(1);   # Mark as required
    $field->required(0);   # Mark as optional
    my $req = $field->required(); # Alias for is_required

Set or check the required flag.

=cut

sub required {
    my ($self, $val) = @_;
    if (@_ > 1) {
        $self->{_field}->required($val ? 1 : 0);
        return $self;
    }
    return $self->{_field}->is_required();
}

=head2 is_required

    if ($field->is_required()) { ... }

Check if field is required.

=cut

sub is_required {
    return $_[0]->{_field}->is_required();
}

=head2 noexport

    $field->noexport(1);

Set the no-export flag (field value not included in FDF export).

=cut

sub noexport {
    my ($self, $val) = @_;
    $self->{_field}->noexport($val ? 1 : 0);
    return $self;
}

=head2 multiline

    $field->multiline(1);

Enable multiline text input (text fields only).

=cut

sub multiline {
    my ($self, $val) = @_;
    $self->{_field}->multiline($val ? 1 : 0);
    return $self;
}

=head2 password

    $field->password(1);

Enable password masking (text fields only).

=cut

sub password {
    my ($self, $val) = @_;
    $self->{_field}->password($val ? 1 : 0);
    return $self;
}

=head2 set_da

    $field->set_da('/Helv 12 Tf 0 g');

Set the default appearance string (font, size, color).

=cut

sub set_da {
    my ($self, $da) = @_;
    $self->{_field}->set_da($da);
    return $self;
}

=head2 set_quadding

    $field->set_quadding(0);  # Left
    $field->set_quadding(1);  # Center  
    $field->set_quadding(2);  # Right

Set text alignment.

=cut

sub set_quadding {
    my ($self, $q) = @_;
    $self->{_field}->set_quadding($q);
    return $self;
}

=head2 align_left

    $field->align_left();

Set left text alignment.

=cut

sub align_left {
    $_[0]->{_field}->align_left();
    return $_[0];
}

=head2 align_center

    $field->align_center();

Set center text alignment.

=cut

sub align_center {
    $_[0]->{_field}->align_center();
    return $_[0];
}

=head2 align_right

    $field->align_right();

Set right text alignment.

=cut

sub align_right {
    $_[0]->{_field}->align_right();
    return $_[0];
}

=head2 set_max_len

    $field->set_max_len(100);

Set maximum character length (text fields only).

=cut

sub set_max_len {
    my ($self, $len) = @_;
    $self->{_field}->set_max_len($len);
    return $self;
}

=head2 add_option

    $field->add_option('Display Text');
    $field->add_option('Display Text', 'export_value');

Add an option to a choice field.

=cut

sub add_option {
    my ($self, $display, $export) = @_;
    if (defined $export) {
        $self->{_field}->add_option($display, $export);
    } else {
        $self->{_field}->add_option($display);
    }
    return $self;
}

=head2 option_count

    my $count = $field->option_count();

Return the number of options (choice fields only).

=cut

sub option_count {
    return $_[0]->{_field}->option_count();
}

=head2 options

    my @opts = $field->options();

Return all options as a list of hashrefs with 'display' and 'export' keys.

=cut

sub options {
    return $_[0]->{_field}->options();
}

=head2 add_radio_option

    $group->add_radio_option(
        x      => 100,
        y      => 500,
        width  => 15,
        height => 15,
        value  => 'Option1',
    );

Add a radio button option to a radio group. Returns the option field.

=cut

sub add_radio_option {
    my ($self, %opts) = @_;
    
    my $x      = delete $opts{x}      // 0;
    my $y      = delete $opts{y}      // 0;
    my $width  = delete $opts{width}  // 15;
    my $height = delete $opts{height} // 15;
    my $value  = delete $opts{value}  or die "add_radio_option: value required";
    
    my $option = $self->{_field}->add_radio_option($x, $y, $width, $height, $value);
    
    return PDF::Make::Field->_wrap($option, $self->{_form});
}

=head2 add_to_page

    $field->add_to_page($page);

Add the field's widget annotation to a page. This makes the field visible.

=cut

sub add_to_page {
    my ($self, $page) = @_;
    
    # Page is already the raw pdfmake_page_t pointer
    $self->{_field}->add_to_page($page);
    return $self;
}

=head2 generate_appearance

    $field->generate_appearance();

Generate the appearance stream for this field.

=cut

sub generate_appearance {
    $_[0]->{_field}->generate_appearance();
    return $_[0];
}

=head2 flatten

    $field->flatten();

Flatten this field: render its value into page content and remove it.

=cut

sub flatten {
    $_[0]->{_field}->flatten();
    return $_[0];
}

=head2 parent

    my $parent = $field->parent();

Return the parent field (for hierarchical fields).

=cut

sub parent {
    my $p = $_[0]->{_field}->parent();
    return unless $p;
    return PDF::Make::Field->_wrap($p, $_[0]->{_form});
}

=head2 children

    my @children = $field->children();

Return child fields (for hierarchical fields).

=cut

sub children {
    my ($self) = @_;
    return map { PDF::Make::Field->_wrap($_, $self->{_form}) } 
           $self->{_field}->children();
}

=head2 has_children

    if ($field->has_children()) { ... }

Check if field has children.

=cut

sub has_children {
    return $_[0]->{_field}->has_children();
}

# Internal: get raw field pointer
sub _field {
    return $_[0]->{_field};
}

1;

__END__

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Form>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

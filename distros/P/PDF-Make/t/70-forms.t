#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use PDF::Make::Document;
use PDF::Make::Form;
use PDF::Make::Field;

# Test basic form creation
subtest 'form creation' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    
    my $form = PDF::Make::Form->new($pdf);
    isa_ok($form, 'PDF::Make::Form', 'form created');
    
    is($form->field_count(), 0, 'empty form has no fields');
};

# Test text field
subtest 'text field' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name   => 'name',
        x      => 100,
        y      => 700,
        width  => 200,
        height => 20,
    );
    
    isa_ok($field, 'PDF::Make::Field', 'text field created');
    is($field->type(), 'text', 'field type is text');
    is($field->name(), 'name', 'field name correct');
    is($field->full_name(), 'name', 'full name correct');
    
    # Set value
    $field->set_value('John Doe');
    is($field->value(), 'John Doe', 'value set correctly');
    
    # Method chaining
    $field->value('Jane Doe');
    is($field->value(), 'Jane Doe', 'value() getter/setter works');
    
    # Add to page
    $field->add_to_page($page);
    
    is($form->field_count(), 1, 'field added to form');
};

# Test text field properties
subtest 'text field properties' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name      => 'notes',
        x         => 100,
        y         => 600,
        width     => 300,
        height    => 100,
        multiline => 1,
        readonly  => 1,
        required  => 1,
        max_len   => 500,
    );
    
    ok($field->is_readonly(), 'readonly flag set');
    ok($field->is_required(), 'required flag set');
    
    # Toggle flags
    $field->readonly(0);
    ok(!$field->is_readonly(), 'readonly cleared');
    
    $field->required(0);
    ok(!$field->is_required(), 'required cleared');
};

# Test checkbox
subtest 'checkbox' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $checkbox = $form->add_checkbox(
        name     => 'agree',
        x        => 100,
        y        => 550,
        width    => 15,
        height   => 15,
        on_value => 'Yes',
    );
    
    isa_ok($checkbox, 'PDF::Make::Field', 'checkbox created');
    is($checkbox->type(), 'button', 'checkbox type is button');
    is($checkbox->name(), 'agree', 'checkbox name correct');
    
    # Check the checkbox
    $checkbox->set_value('Yes');
    is($checkbox->value(), 'Yes', 'checkbox checked');
    
    # Uncheck
    $checkbox->set_value('Off');
    is($checkbox->value(), 'Off', 'checkbox unchecked');
    
    $checkbox->add_to_page($page);
};

# Test radio group
subtest 'radio group' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $group = $form->add_radio_group(name => 'choice');
    isa_ok($group, 'PDF::Make::Field', 'radio group created');
    is($group->type(), 'button', 'radio type is button');
    
    # Add options
    my $opt1 = $group->add_radio_option(x => 100, y => 500, width => 15, height => 15, value => 'A');
    my $opt2 = $group->add_radio_option(x => 100, y => 480, width => 15, height => 15, value => 'B');
    my $opt3 = $group->add_radio_option(x => 100, y => 460, width => 15, height => 15, value => 'C');
    
    isa_ok($opt1, 'PDF::Make::Field', 'radio option created');
    
    # Select an option
    $group->set_value('B');
    is($group->value(), 'B', 'radio option selected');
    
    ok($group->has_children(), 'radio group has children');
    my @children = $group->children();
    is(scalar @children, 3, 'three radio options');
    
    $opt1->add_to_page($page);
    $opt2->add_to_page($page);
    $opt3->add_to_page($page);
};

# Test choice field (combo/dropdown)
subtest 'choice combo' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $combo = $form->add_combo(
        name    => 'country',
        x       => 100,
        y       => 400,
        width   => 150,
        height  => 20,
        options => [
            { display => 'United States', export => 'US' },
            { display => 'Canada', export => 'CA' },
            'Mexico',  # Simple string
        ],
    );
    
    isa_ok($combo, 'PDF::Make::Field', 'combo created');
    is($combo->type(), 'choice', 'combo type is choice');
    is($combo->option_count(), 3, 'three options');
    
    # Get options
    my @opts = $combo->options();
    is($opts[0]->{display}, 'United States', 'first option display');
    is($opts[0]->{export}, 'US', 'first option export');
    is($opts[2]->{display}, 'Mexico', 'third option display');
    
    # Select value
    $combo->set_value('CA');
    is($combo->value(), 'CA', 'combo value set');
    
    $combo->add_to_page($page);
};

# Test choice field (listbox)
subtest 'choice listbox' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $listbox = $form->add_listbox(
        name   => 'items',
        x      => 100,
        y      => 300,
        width  => 150,
        height => 80,
    );
    
    $listbox->add_option('Item 1', '1');
    $listbox->add_option('Item 2', '2');
    $listbox->add_option('Item 3', '3');
    
    is($listbox->option_count(), 3, 'three items in listbox');
    
    $listbox->add_to_page($page);
};

# Test pushbutton
subtest 'pushbutton' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $button = $form->add_button(
        name    => 'submit',
        x       => 100,
        y       => 100,
        width   => 80,
        height  => 25,
        caption => 'Submit',
    );
    
    isa_ok($button, 'PDF::Make::Field', 'button created');
    is($button->type(), 'button', 'button type correct');
    is($button->name(), 'submit', 'button name correct');
    
    $button->add_to_page($page);
};

# Test signature field
subtest 'signature field' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $sig = $form->add_signature(
        name   => 'signature',
        x      => 100,
        y      => 50,
        width  => 200,
        height => 40,
    );
    
    isa_ok($sig, 'PDF::Make::Field', 'signature field created');
    is($sig->type(), 'signature', 'signature type correct');
    
    $sig->add_to_page($page);
};

# Test text alignment
subtest 'text alignment' => sub {
    my $pdf = PDF::Make::Document->new();
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name   => 'aligned',
        x      => 100,
        y      => 200,
        width  => 200,
        height => 20,
    );
    
    $field->align_left();
    # Can't easily test internal state, but ensure no crash
    
    $field->align_center();
    # No crash
    
    $field->align_right();
    # No crash
    
    $field->set_quadding(1);  # Center
    # No crash
    
    pass('alignment methods work');
};

# Test field lookup
subtest 'field lookup' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    $form->add_text_field(name => 'first', x => 100, y => 700, width => 100, height => 20);
    $form->add_text_field(name => 'second', x => 100, y => 670, width => 100, height => 20);
    $form->add_text_field(name => 'third', x => 100, y => 640, width => 100, height => 20);
    
    is($form->field_count(), 3, 'three fields');
    
    # By index
    my $f0 = $form->field_at(0);
    is($f0->name(), 'first', 'first field by index');
    
    my $f1 = $form->field_at(1);
    is($f1->name(), 'second', 'second field by index');
    
    # By name
    my $found = $form->field_by_name('second');
    is($found->name(), 'second', 'found by name');
    
    my $notfound = $form->field_by_name('nonexistent');
    ok(!defined $notfound, 'not found returns undef');
    
    # All fields
    my @all = $form->fields();
    is(scalar @all, 3, 'all fields returned');
};

# Test form finalization and PDF generation
subtest 'form finalize and render' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $name = $form->add_text_field(
        name  => 'name',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
        value => 'Test Value',
    );
    $name->add_to_page($page);
    
    my $checkbox = $form->add_checkbox(
        name => 'agree',
        x    => 100,
        y    => 650,
        width => 15,
        height => 15,
    );
    $checkbox->set_value('Yes');
    $checkbox->add_to_page($page);
    
    # Finalize
    $form->finalize();
    
    # Render PDF
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 0, 'PDF rendered');
    like($bytes, qr/^%PDF-/, 'valid PDF header');
    like($bytes, qr/AcroForm/, 'contains AcroForm');
};

# Test FDF export
subtest 'FDF export' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'testfield',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    $field->set_value('Test Data');
    $field->add_to_page($page);
    
    my $fdf = $form->export_fdf();
    ok(length($fdf) > 0, 'FDF exported');
    like($fdf, qr/%FDF/, 'contains FDF header');
    like($fdf, qr/testfield/, 'contains field name');
};

# Test XFDF export
subtest 'XFDF export' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'xmlfield',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    $field->set_value('XML Value');
    $field->add_to_page($page);
    
    my $xfdf = $form->export_xfdf();
    ok(length($xfdf) > 0, 'XFDF exported');
    like($xfdf, qr/<xfdf/i, 'contains XFDF root');
    like($xfdf, qr/xmlfield/, 'contains field name');
};

# Test form with all options
subtest 'comprehensive form' => sub {
    my $pdf = PDF::Make::Document->new();
    $pdf->title('Form Test');
    
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    # Text field with all options
    my $name = $form->add_text_field(
        name          => 'fullname',
        x             => 150,
        y             => 700,
        width         => 300,
        height        => 20,
        value         => 'John Smith',
        default_value => '',
        max_len       => 50,
        quadding      => 0,  # Left
    );
    $name->add_to_page($page);
    
    # Multiline text
    my $notes = $form->add_text_field(
        name      => 'notes',
        x         => 150,
        y         => 600,
        width     => 300,
        height    => 80,
        multiline => 1,
    );
    $notes->set_value("Line 1\nLine 2\nLine 3");
    $notes->add_to_page($page);
    
    # Password field
    my $password = $form->add_text_field(
        name     => 'password',
        x        => 150,
        y        => 550,
        width    => 200,
        height   => 20,
        password => 1,
    );
    $password->add_to_page($page);
    
    # Checkbox
    my $terms = $form->add_checkbox(
        name => 'accept_terms',
        x    => 150,
        y    => 500,
        width => 15,
        height => 15,
    );
    $terms->set_value('Yes');
    $terms->add_to_page($page);
    
    # Radio group
    my $gender = $form->add_radio_group(name => 'gender');
    my $male = $gender->add_radio_option(x => 150, y => 450, width => 15, height => 15, value => 'M');
    my $female = $gender->add_radio_option(x => 200, y => 450, width => 15, height => 15, value => 'F');
    my $other = $gender->add_radio_option(x => 250, y => 450, width => 15, height => 15, value => 'O');
    $gender->set_value('M');
    $male->add_to_page($page);
    $female->add_to_page($page);
    $other->add_to_page($page);
    
    # Dropdown
    my $country = $form->add_combo(
        name => 'country',
        x    => 150,
        y    => 400,
        width => 200,
        height => 20,
        options => ['USA', 'Canada', 'UK', 'Australia'],
    );
    $country->set_value('USA');
    $country->add_to_page($page);
    
    # Listbox
    my $hobbies = $form->add_listbox(
        name   => 'hobbies',
        x      => 150,
        y      => 280,
        width  => 200,
        height => 100,
    );
    $hobbies->add_option('Reading');
    $hobbies->add_option('Sports');
    $hobbies->add_option('Music');
    $hobbies->add_option('Travel');
    $hobbies->add_to_page($page);
    
    # Submit button
    my $submit = $form->add_button(
        name    => 'submit',
        x       => 150,
        y       => 100,
        width   => 100,
        height  => 30,
        caption => 'Submit',
    );
    $submit->add_to_page($page);
    
    # Reset button
    my $reset = $form->add_button(
        name    => 'reset',
        x       => 260,
        y       => 100,
        width   => 100,
        height  => 30,
        caption => 'Reset',
    );
    $reset->add_to_page($page);
    
    # Signature
    my $sig = $form->add_signature(
        name   => 'signature',
        x      => 150,
        y      => 50,
        width  => 200,
        height => 40,
    );
    $sig->add_to_page($page);
    
    # Finalize and render
    $form->finalize();
    
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 1000, 'comprehensive PDF generated');
    
    # Verify it's valid
    like($bytes, qr/AcroForm/, 'has AcroForm');
    like($bytes, qr/fullname/, 'has fullname field');
    like($bytes, qr/accept_terms/, 'has checkbox');
    like($bytes, qr/gender/, 'has radio group');
    like($bytes, qr/country/, 'has dropdown');
};

# Test NeedAppearances flag
subtest 'need appearances' => sub {
    my $pdf = PDF::Make::Document->new();
    my $form = PDF::Make::Form->new($pdf);
    
    # Default should generate appearances
    $form->set_need_appearances(0);  # We generate
    pass('set_need_appearances(0) ok');
    
    $form->set_need_appearances(1);  # Viewer generates
    pass('set_need_appearances(1) ok');
};

# Test method chaining
subtest 'method chaining' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name   => 'chained',
        x      => 100,
        y      => 700,
        width  => 200,
        height => 20,
    );
    
    # Chain multiple calls
    $field->set_value('test')
          ->readonly(1)
          ->align_center()
          ->set_max_len(100)
          ->add_to_page($page);
    
    is($field->value(), 'test', 'value after chaining');
    ok($field->is_readonly(), 'readonly after chaining');
};

# Test FDF import
subtest 'FDF import' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field1 = $form->add_text_field(
        name  => 'firstname',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    $field1->add_to_page($page);
    
    my $field2 = $form->add_text_field(
        name  => 'lastname',
        x     => 100,
        y     => 670,
        width => 200,
        height => 20,
    );
    $field2->add_to_page($page);
    
    # Create FDF data
    my $fdf_data = <<'FDF';
%FDF-1.2
1 0 obj
<< /FDF << /Fields [
<< /T (firstname) /V (John) >>
<< /T (lastname) /V (Doe) >>
] >> >>
endobj
trailer
<< /Root 1 0 R >>
%%EOF
FDF
    
    # Import FDF
    $form->import_fdf($fdf_data);
    
    is($field1->value(), 'John', 'firstname imported from FDF');
    is($field2->value(), 'Doe', 'lastname imported from FDF');
};

# Test XFDF import
subtest 'XFDF import' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field1 = $form->add_text_field(
        name  => 'email',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    $field1->add_to_page($page);
    
    my $field2 = $form->add_text_field(
        name  => 'company',
        x     => 100,
        y     => 670,
        width => 200,
        height => 20,
    );
    $field2->add_to_page($page);
    
    # Create XFDF data
    my $xfdf_data = <<'XFDF';
<?xml version="1.0" encoding="UTF-8"?>
<xfdf xmlns="http://ns.adobe.com/xfdf/">
  <fields>
    <field name="email">
      <value>test@example.com</value>
    </field>
    <field name="company">
      <value>Acme &amp; Co</value>
    </field>
  </fields>
</xfdf>
XFDF
    
    # Import XFDF
    $form->import_xfdf($xfdf_data);
    
    is($field1->value(), 'test@example.com', 'email imported from XFDF');
    is($field2->value(), 'Acme & Co', 'company imported with entity decoding');
};

# Test form flatten
subtest 'form flatten' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'flattened',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
        value => 'Flattened Text',
    );
    $field->add_to_page($page);
    
    # Flatten the entire form
    $form->flatten();
    
    # After flattening, form should still be accessible
    # The fields become part of page content
    pass('form flatten completed without error');
    
    # Render PDF
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 0, 'PDF rendered after flatten');
};

# Test individual field flatten
subtest 'field flatten' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field1 = $form->add_text_field(
        name  => 'keep_editable',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
        value => 'Editable',
    );
    $field1->add_to_page($page);
    
    my $field2 = $form->add_text_field(
        name  => 'flatten_me',
        x     => 100,
        y     => 670,
        width => 200,
        height => 20,
        value => 'Static',
    );
    $field2->add_to_page($page);
    
    # Flatten only one field
    $field2->flatten();
    
    pass('individual field flatten completed without error');
};

# Test noexport flag
subtest 'noexport flag' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $exported = $form->add_text_field(
        name  => 'exported',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
        value => 'Include Me',
    );
    $exported->add_to_page($page);
    
    my $hidden = $form->add_text_field(
        name  => 'hidden',
        x     => 100,
        y     => 670,
        width => 200,
        height => 20,
        value => 'Exclude Me',
    );
    $hidden->noexport(1);
    $hidden->add_to_page($page);
    
    # Export FDF - hidden field should not be included
    my $fdf = $form->export_fdf();
    like($fdf, qr/exported/, 'exported field in FDF');
    unlike($fdf, qr/hidden/, 'noexport field excluded from FDF');
    
    # Export XFDF
    my $xfdf = $form->export_xfdf();
    like($xfdf, qr/exported/, 'exported field in XFDF');
    unlike($xfdf, qr/hidden/, 'noexport field excluded from XFDF');
};

# Test default appearance (DA)
subtest 'default appearance' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'styled',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    
    # Set custom appearance (font, size, color)
    $field->set_da('/Helv 14 Tf 0 0 1 rg');  # Blue text
    $field->set_value('Blue Text');
    $field->add_to_page($page);
    
    $form->finalize();
    
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 0, 'PDF with custom DA rendered');
};

# Test default value
subtest 'default value' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'resetable',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    
    # Set default value (used on form reset)
    $field->set_default_value('Default Text');
    $field->set_value('Current Text');
    $field->add_to_page($page);
    
    is($field->value(), 'Current Text', 'current value set');
    
    $form->finalize();
    
    my $bytes = $pdf->to_bytes();
    like($bytes, qr/Default Text/, 'default value in PDF');
};

# Test flags integer access
subtest 'flags integer' => sub {
    my $pdf = PDF::Make::Document->new();
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'flagtest',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
    );
    
    # Get initial flags
    my $flags = $field->flags();
    ok(defined $flags, 'flags() returns value');
    
    # Set specific flags
    $field->set_flags(0);
    is($field->flags(), 0, 'flags cleared');
    
    # Add flags
    $field->add_flags(1);  # ReadOnly
    ok($field->flags() & 1, 'readonly flag set');
    
    $field->add_flags(2);  # Required
    ok($field->flags() & 2, 'required flag set');
    ok($field->flags() & 1, 'readonly still set');
    
    # Clear specific flag
    $field->clear_flags(1);
    ok(!($field->flags() & 1), 'readonly cleared');
    ok($field->flags() & 2, 'required still set');
};

# Test checkbox with custom on_value
subtest 'checkbox on_value' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $checkbox = $form->add_checkbox(
        name     => 'custom_check',
        x        => 100,
        y        => 700,
        width    => 15,
        height   => 15,
        on_value => 'Checked',
    );
    $checkbox->add_to_page($page);
    
    # Check with custom value
    $checkbox->set_value('Checked');
    is($checkbox->value(), 'Checked', 'custom on_value works');
    
    # Uncheck
    $checkbox->set_value('Off');
    is($checkbox->value(), 'Off', 'off value works');
};

# Test generate_appearance
subtest 'generate appearance' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $field = $form->add_text_field(
        name  => 'with_appearance',
        x     => 100,
        y     => 700,
        width => 200,
        height => 20,
        value => 'Visible Text',
    );
    $field->add_to_page($page);
    
    # Explicitly generate appearance
    $field->generate_appearance();
    
    $form->finalize();
    
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 0, 'PDF with generated appearance');
};

# Test parent/children for non-radio hierarchical fields
subtest 'field hierarchy' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    # Radio group has children
    my $group = $form->add_radio_group(name => 'hierarchy_test');
    my $opt1 = $group->add_radio_option(x => 100, y => 700, width => 15, height => 15, value => 'A');
    my $opt2 = $group->add_radio_option(x => 100, y => 680, width => 15, height => 15, value => 'B');
    
    ok($group->has_children(), 'group has children');
    
    my @children = $group->children();
    is(scalar @children, 2, 'two children');
    
    # Children should have parent
    my $parent = $opt1->parent();
    ok(defined $parent, 'child has parent');
    is($parent->name(), 'hierarchy_test', 'parent is the group');
    
    # Group should have no parent
    my $group_parent = $group->parent();
    ok(!defined $group_parent, 'group has no parent');
    
    $opt1->add_to_page($page);
    $opt2->add_to_page($page);
};

# Test multiline and password text field flags
subtest 'text field flags' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    my $multiline = $form->add_text_field(
        name   => 'multi',
        x      => 100,
        y      => 700,
        width  => 200,
        height => 80,
    );
    $multiline->multiline(1);
    $multiline->set_value("Line 1\nLine 2");
    $multiline->add_to_page($page);
    
    my $password = $form->add_text_field(
        name   => 'pass',
        x      => 100,
        y      => 600,
        width  => 200,
        height => 20,
    );
    $password->password(1);
    $password->add_to_page($page);
    
    $form->finalize();
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 0, 'PDF with multiline and password fields');
};

# Test empty form
subtest 'empty form' => sub {
    my $pdf = PDF::Make::Document->new();
    my $page = $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    
    is($form->field_count(), 0, 'empty form');
    
    my @fields = $form->fields();
    is(scalar @fields, 0, 'no fields');
    
    my $f = $form->field_at(0);
    ok(!defined $f, 'field_at(0) returns undef for empty form');
    
    $form->finalize();
    my $bytes = $pdf->to_bytes();
    ok(length($bytes) > 0, 'PDF with empty form renders');
};

done_testing();

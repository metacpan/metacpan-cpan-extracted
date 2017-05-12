#!/usr/bin/perl -w

use strict;

use Test::More tests => 264;

BEGIN 
{
  $ENV{'RHTMLO_TEST_MOD_PERL'} = 1;

  use_ok('Rose::HTML::Form');
  use_ok('Rose::HTML::Form::Field::Text');
  use_ok('Rose::HTML::Form::Field::SelectBox');
  use_ok('Rose::HTML::Form::Field::RadioButtonGroup');
  use_ok('Rose::HTML::Form::Field::CheckboxGroup');
  use_ok('Rose::HTML::Form::Field::DateTime::Split::MonthDayYear');
  use_ok('Rose::HTML::Form::Field::DateTime::Split::MDYHMS');
}

#
# Form children
#

my $form = Rose::HTML::Form->new;

$form->add_fields
([
  street =>
  {
    type => 'text',
    size => 25,
  },

  city => 
  {
    type => 'text',
    size => 25,
  },
]);

$form->unshift_child(Rose::HTML::Object->new('p', class => 'top', children => [ 'start' ]));

$form->push_child(Rose::HTML::Object->new('div', class => 'bottom', children => [ 'end' ]));

is($form->xhtml_table,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">

<p class="top">start</p>

<table class="form">
<tr class="field-odd">
<td class="label"><label>Street</label></td>
<td class="field"><input name="street" size="25" type="text" value="" /></td>
</tr>
<tr class="field-even">
<td class="label"><label>City</label></td>
<td class="field"><input name="city" size="25" type="text" value="" /></td>
</tr>
</table>

<div class="bottom">end</div>

</form>), 'children 1');

$form->params(street => 'Main', city => 'Anytown');
$form->field('street')->label('Street');
$form->field('city')->label('City');
$form->init_fields();

is($form->xhtml,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">) .
qq(<p class="top">start</p>) .
qq(<div class="field-with-label"><label>City</label><div class="field"><input name="city" size="25" type="text" value="Anytown" /></div></div>) .
qq(<div class="field-with-label"><label>Street</label><div class="field"><input name="street" size="25" type="text" value="Main" /></div></div>) .
qq(<div class="bottom">end</div>) .
qq(</form>), 'xhtml 1');

is($form->html,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">) .
qq(<p class="top">start</p>) .
qq(<div class="field-with-label"><label>City</label><div class="field"><input name="city" size="25" type="text" value="Anytown"></div></div>) .
qq(<div class="field-with-label"><label>Street</label><div class="field"><input name="street" size="25" type="text" value="Main"></div></div>) .
qq(<div class="bottom">end</div>) .
qq(</form>), 'html 1');

$form->field('street')->label(undef);
$form->field('city')->label(undef);

$form->clear;

is($form->pop_child->html, '<div class="bottom">end</div>', 'pop_child 1');

is($form->xhtml_table,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">

<p class="top">start</p>

<table class="form">
<tr class="field-odd">
<td class="label"><label>Street</label></td>
<td class="field"><input name="street" size="25" type="text" value="" /></td>
</tr>
<tr class="field-even">
<td class="label"><label>City</label></td>
<td class="field"><input name="city" size="25" type="text" value="" /></td>
</tr>
</table>

</form>), 'pop_child 2');

is($form->pop_child->html, '<p class="top">start</p>', 'pop_child 3');

is($form->xhtml_table,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">

<table class="form">
<tr class="field-odd">
<td class="label"><label>Street</label></td>
<td class="field"><input name="street" size="25" type="text" value="" /></td>
</tr>
<tr class="field-even">
<td class="label"><label>City</label></td>
<td class="field"><input name="city" size="25" type="text" value="" /></td>
</tr>
</table>

</form>), 'pop_child 4');

$form->unshift_child(Rose::HTML::Object->new('p', class => 'top2', children => [ 'start' ]));

$form->push_child(Rose::HTML::Object->new('div', class => 'bottom2', children => [ 'end' ]));

is($form->shift_child->html, '<p class="top2">start</p>', 'shift_child 1');

is($form->xhtml_table,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">

<table class="form">
<tr class="field-odd">
<td class="label"><label>Street</label></td>
<td class="field"><input name="street" size="25" type="text" value="" /></td>
</tr>
<tr class="field-even">
<td class="label"><label>City</label></td>
<td class="field"><input name="city" size="25" type="text" value="" /></td>
</tr>
</table>

<div class="bottom2">end</div>

</form>), 'shift_child 2');

is($form->shift_child->html, '<div class="bottom2">end</div>', 'shift_child 3');

is($form->xhtml_table,
qq(<form action="" enctype="application/x-www-form-urlencoded" method="get">

<table class="form">
<tr class="field-odd">
<td class="label"><label>Street</label></td>
<td class="field"><input name="street" size="25" type="text" value="" /></td>
</tr>
<tr class="field-even">
<td class="label"><label>City</label></td>
<td class="field"><input name="city" size="25" type="text" value="" /></td>
</tr>
</table>

</form>), 'shift_child 4');

$form = Rose::HTML::Form->new(form_name => 'myform');

$form->add_fields
(
  name =>
  {
    type => 'text',
    size => 25,
  },

  type => 
  {
    type    => 'checkbox group',
    choices => [ qw(a b c) ],
  },
);

my $c1 = Rose::HTML::Object->new('p', class => 'top', children => [ 'start' ]);
my $c2 = Rose::HTML::Object->new('div', class => 'bottom', children => [ 'end' ]);
$form->unshift_child($c1);
$form->push_child($c2);

is(join(',', $form->children), join(',', $c1, $form->field('name'), $form->field('type')->checkboxes, $c2),
   'children 2');

#print join(',', $form->children);

# Pre-0.554 this caused an exception
$form->field('type')->add_checkbox(d => 'D');

# Mmm, fuzzy...
Rose::HTML::Form->default_recursive_init_fields(rand > 0.5 ? 1 : 0);

our $Have_RDBO;

$form = Rose::HTML::Form->new;
ok(ref $form && $form->isa('Rose::HTML::Form'), 'new()');

$form->add_fields(a => { type => 'text' });

my %p = (a => 'foo', b => [ 2, 3 ]);

is($form->is_empty, 1, 'is_empty 1');

# Store reference
$form->params(\%p);

$form->init_fields;
is($form->is_empty, 0, 'is_empty 2');

$form->delete_field('a');

is($form->param('a'), 'foo', 'params store ref 1');
is($form->param('b')->[0], 2, 'params store ref 2');

$p{'a'}    = 2;
$p{'b'}[0] = 5;

is($form->param('a'), 2, 'params store ref 3');
is($form->param('b')->[0], 5, 'params store ref 4');

# Return copy
my(%p2) = $form->params;

$p2{'a'}    = 'bar';
$p2{'b'}[0] = 99;

is($form->param('a'), 2, 'params return copy 1');
is($form->param('b')->[0], 5, 'params return copy 2');

# Store copy
%p = (a => 'foo', b => [ 2, 3 ]);

$form->params(%p);

is($form->param('a'), 'foo', 'params store copy 1');
is($form->param('b')->[0], 2, 'params store copy 2');

$p{'a'}    = 2;
$p{'b'}[0] = 5;

is($form->param('a'), 'foo', 'params store copy 3');
is($form->param('b')->[0], 2, 'params store copy 4');

my $fcgi = FakeCGI->new;

$form->params_from_cgi($fcgi);

is($form->param('a'), 'b', 'params_from_cgi fake 1');
is($form->param('c')->[1], 'e', 'params_from_cgi fake 2');

$fcgi->_params->{'a'} = 'x';

is($form->param('a'), 'b', 'params_from_cgi fake 3');
is($form->param('c')->[1], 'e', 'params_from_cgi fake 4');

eval { require CGI };

if($@)
{
  SKIP: { skip('missing CGI', 4) }
}
else
{
  my $cgi = CGI->new('a=b;c=d;c=e');

  $form->params_from_cgi($cgi);

  is($form->param('a'), 'b', 'params_from_cgi real 1');
  ok(($form->param('c')->[0] eq 'd' && $form->param('c')->[1] eq 'e') ||
     ($form->param('c')->[0] eq 'd' && $form->param('c')->[1] eq 'e'),
    'params_from_cgi real 2');

  $cgi->param(a => 'x');

  is($form->param('a'), 'b', 'params_from_cgi real 3');
  ok(($form->param('c')->[0] eq 'd' && $form->param('c')->[1] eq 'e') ||
     ($form->param('c')->[0] eq 'd' && $form->param('c')->[1] eq 'e'),
    'params_from_cgi real 4');
}

my $r = FakeApache->new;

$r->_params->{'a'} = 'b';
$r->_params->{'c'} = [ 'd', 'e' ];

$form->params_from_apache($r);

is($form->param('a'), 'b', 'params_from_apache 1');
is($form->param('c')->[1], 'e', 'params_from_apache 2');

$r->_params->{'a'} = 'x';

is($form->param('a'), 'b', 'params_from_apache 3');
is($form->param('c')->[1], 'e', 'params_from_apache 4');

$form->html_attr('action' => '/foo/bar');

is($form->start_html, '<form action="/foo/bar" enctype="application/x-www-form-urlencoded" method="get">', 'start_html() 1');

eval { $form->html_attr('nonesuch') };
ok($@, 'invalid attribute');

$form->error('Foo > bar');
is($form->error, 'Foo > bar', 'error()');

is($form->html_error, '<span class="error">Foo &gt; bar</span>', 'html_error()');
is($form->xhtml_error, '<span class="error">Foo &gt; bar</span>', 'xhtml_error()');

$form->escape_html(0);

is($form->html_error, '<span class="error">Foo > bar</span>', 'html_error()');
is($form->xhtml_error, '<span class="error">Foo > bar</span>', 'xhtml_error()');

my $field = Rose::HTML::Form::Field::Text->new();

is(scalar @{ $form->children }, 0, 'children scalar 1');
is(scalar(() = $form->children), 0, 'children list 1');

ok($form->add_field(foo => $field), 'add_field()');

is(scalar @{ $form->children }, 1, 'children scalar 2');
is(scalar(() = $form->children), 1, 'children list 2');

is($form->field('foo'), $field, 'field() set with field object');

$fcgi = FakeCGI->new;
$fcgi->_params->{'foo'} = 'bar';
$form->init_fields_with_cgi($fcgi);
is($form->field_value('foo'), 'bar', 'init_fields_with_cgi 1');

$r = FakeApache->new;
$fcgi->_params->{'foo'} = 'baz';
$form->init_fields_with_apache($r);
is($form->field('foo')->internal_value, 'baz', 'init_fields_with_apache 1');

my @fields = $form->fields;
is(@fields, 1, 'fields()');

$form->delete_fields();
@fields = $form->fields;
is(@fields, 0, 'delete_fields()');

my $field2 =  Rose::HTML::Form::Field::Text->new(name => 'bar');
$form->add_fields($field, $field2);

ok($form->field('foo') eq $field &&
   $form->field('bar') eq $field2,
  'add_fields() objects');

@fields = $form->fields;
is(@fields, 2, 'add_fields() objects check');

my @field_monikers = $form->field_monikers;
is(join(', ', @field_monikers), 'bar, foo', 'field_monikers()');

$form->delete_fields();
@fields = $form->fields;
is(@fields, 0, 'delete_fields()');

$form->add_fields(foo2 => $field, bar2 => $field2);

ok($form->field('foo2') eq $field && $field->name eq 'foo' &&
  $form->field('bar2')  eq $field2 && $field2->name eq 'bar',
  'add_fields() hash');

@fields = $form->fields;
is(@fields, 2, 'add_fields() hash check');

$form->params(a => 1, b => 2, c => [ 7, 8, 9 ]);
is($form->param('b'), 2, 'param()');

ok($form->param_exists('a'), 'param_exists() true');
ok(!$form->param_exists('z'), 'param_exists() false');

ok($form->param_value_exists('c' => 8), 'param_value_exists() true');
ok(!$form->param_value_exists('c' => 10), 'param_value_exists() false');

$form->delete_param('b');
ok(!$form->param_exists('b'), 'delete_param()');

$form->add_param_value('c' => 10);
ok($form->param_value_exists('c' => 10), 'add_param_value()');

$form->params(foo => 2, bar => 5);

$form->init_fields();

is($form->query_string, 'bar=5&foo=2', 'query_string() 1');

$form->clear_fields;
is($form->query_string, '', 'clear_fields()');

$form->delete_fields;

my %fields;

$fields{'name'} = Rose::HTML::Form::Field::Text->new;
$fields{'age'}  = Rose::HTML::Form::Field::Text->new(size => 2);
$fields{'bday'} = Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(name => 'bday');

$form->add_fields(map { $_ => $fields{$_} } sort keys %fields);

is_deeply(scalar $form->field_names, [ 'age', 'bday', 'name' ], 'field_names() 1');
is_deeply(scalar $form->field_monikers, [ 'age', 'bday', 'name' ], 'field_monikers() 1');

is($form->html_hidden_fields, 
   qq(<input name="age" type="hidden" value="">\n) .
   qq(<input class="day" name="bday.day" type="hidden" value="">\n) .
   qq(<input class="month" name="bday.month" type="hidden" value="">\n) .
   qq(<input class="year" name="bday.year" type="hidden" value="">\n) .
   qq(<input name="name" type="hidden" value="">),
   'html_hidden_fields() 1');

is($form->xhtml_hidden_fields, 
   qq(<input name="age" type="hidden" value="" />\n) .
   qq(<input class="day" name="bday.day" type="hidden" value="" />\n) .
   qq(<input class="month" name="bday.month" type="hidden" value="" />\n) .
   qq(<input class="year" name="bday.year" type="hidden" value="" />\n) .
   qq(<input name="name" type="hidden" value="" />),
   'xhtml_hidden_fields() 1');

$form->coalesce_hidden_fields(1);

is($form->html_hidden_fields, 
   qq(<input name="age" type="hidden" value="">\n) .
   qq(<input name="bday" type="hidden" value="">\n) . 
   qq(<input name="name" type="hidden" value="">),
   'html_hidden_fields() coalesced 1');

is($form->xhtml_hidden_fields, 
   qq(<input name="age" type="hidden" value="" />\n) .
   qq(<input name="bday" type="hidden" value="" />\n) . 
   qq(<input name="name" type="hidden" value="" />),
   'xhtml_hidden_fields() coalesced 1');

$form->params(name => 'John', age => 27, bday => '12/25/1980');

$form->init_fields();

is($form->html_hidden_fields, 
   qq(<input name="age" type="hidden" value="27">\n) .
   qq(<input name="bday" type="hidden" value="12/25/1980">\n) . 
   qq(<input name="name" type="hidden" value="John">),
   'init_fields() 1');

$form->clear_fields();

is($form->html_hidden_fields, 
   qq(<input name="age" type="hidden" value="">\n) .
   qq(<input name="bday" type="hidden" value="">\n) . 
   qq(<input name="name" type="hidden" value="">),
   'clear_fields()');

%fields = 
(
  'hobbies' =>
    Rose::HTML::Form::Field::SelectBox->new(
      multiple => 1,
      options =>
      {
        tennis  => 'Tennis',
        golf     => 'Golf',
        sleeping => 'Sleeping',
      }),

  'sex' =>
    Rose::HTML::Form::Field::RadioButtonGroup->new(
      radio_buttons => [ 'M', 'F' ],
      labels =>
      {
        M  => 'Male',
        F  => 'Female',
      }),

  'status' =>
    Rose::HTML::Form::Field::CheckboxGroup->new(
      checkboxes => [ 'married', 'kids', 'tired' ],
      labels =>
      {
        married  => 'Married',
        kids     => 'With Kids & Stuff',
        tired    => 'And tired',
      }),
);

$form->add_fields(%fields);

$form->params(name => ' John ', age => 27, bday => '1980-12-25', 
              hobbies => [ 'tennis', 'sleeping' ],
              sex => 'M', status => [ 'married', 'tired' ]);

$form->init_fields();

is($form->html_hidden_fields, 
   qq(<input name="age" type="hidden" value="27">\n) .
   qq(<input name="bday" type="hidden" value="12/25/1980">\n) . 
   qq(<input name="hobbies" type="hidden" value="sleeping">\n) . 
   qq(<input name="hobbies" type="hidden" value="tennis">\n) . 
   qq(<input name="name" type="hidden" value="John">\n) .
   qq(<input name="sex" type="hidden" value="M">\n) .
   qq(<input name="status" type="hidden" value="married">\n) .
   qq(<input name="status" type="hidden" value="tired">),
   'init_fields() 2');

$form->field('name')->default('<Anonymous>');
$form->field('age')->validator(sub { /^\d+$/ });

$form->params(age => '27d', bday => '1980-12-25', 
              hobbies => [ 'tennis', 'sleeping' ],
              sex => 'M', status => [ 'married', 'tired' ]);

$form->init_fields();

ok(!$form->validate, 'validate()');

$form->params(name => '<John>', age => 27, bday => '1980-12-25', 
              hobbies => [ 'tennis', 'sleeping' ],
              sex => 'M', status => [ 'married', 'tired' ]);

$form->init_fields();

is($form->field_value('age'), 27, 'field_value() 1');

ok($form->validate, 'validate()');

is($form->html_hidden_fields, 
   qq(<input name="age" type="hidden" value="27">\n) .
   qq(<input name="bday" type="hidden" value="12/25/1980">\n) . 
   qq(<input name="hobbies" type="hidden" value="sleeping">\n) . 
   qq(<input name="hobbies" type="hidden" value="tennis">\n) . 
   qq(<input name="name" type="hidden" value="&lt;John&gt;">\n) .
   qq(<input name="sex" type="hidden" value="M">\n) .
   qq(<input name="status" type="hidden" value="married">\n) .
   qq(<input name="status" type="hidden" value="tired">),
   'init_fields() 3');

my $html=<<"EOF";
<form action="/foo/bar" enctype="application/x-www-form-urlencoded" method="get">
<input name="age" size="2" type="text" value="27">
<span class="date"><input class="month" maxlength="2" name="bday.month" size="2" type="text" value="12">/<input class="day" maxlength="2" name="bday.day" size="2" type="text" value="25">/<input class="year" maxlength="4" name="bday.year" size="4" type="text" value="1980"></span>
<select multiple name="hobbies" size="5">
<option value="golf">Golf</option>
<option selected value="sleeping">Sleeping</option>
<option selected value="tennis">Tennis</option>
</select>
<input name="name" size="15" type="text" value="&lt;John&gt;">
<input checked name="sex" type="radio" value="M"> <label>Male</label><br>
<input name="sex" type="radio" value="F"> <label>Female</label>
<input checked name="status" type="checkbox" value="married"> <label>Married</label><br>
<input name="status" type="checkbox" value="kids"> <label>With Kids &amp; Stuff</label><br>
<input checked name="status" type="checkbox" value="tired"> <label>And tired</label>
</form>
EOF

is(join("\n", $form->start_html, 
              (map { $form->field($_)->html } sort $form->field_monikers),
              $form->end_html) . "\n", $html, 'html()');

$form->params(age => '27', 'bday.month' => 12, 'bday.day' => 25, 'bday.year' => 1980, 
              hobbies => [ 'tennis', 'sleeping' ], name => 'John',
              sex => 'M', status => [ 'married', 'tired' ]);

$form->init_fields();
my $f = $form->field('bday');

is($form->field('bday')->internal_value->strftime('%m/%d/%Y'), '12/25/1980', 'compound field init internal_value()');
is($form->field('bday')->output_value, '12/25/1980', 'compound field init output_value()');

is($form->query_string, 'age=27&bday=12/25/1980&hobbies=sleeping&hobbies=tennis&name=John&sex=M&status=married&status=tired', 'query_string() 2');

$form->coalesce_query_string_params(0);

is($form->query_string, 'age=27&bday.day=25&bday.month=12&bday.year=1980&hobbies=sleeping&hobbies=tennis&name=John&sex=M&status=married&status=tired', 'query_string() 3');

my $object = $form->object_from_form('MyObject');

is($object->name, 'John', 'object_from_form() 1');
is($object->age, 27, 'object_from_form() 2');
is($object->bday->strftime('%m/%d/%Y'), '12/25/1980', 'object_from_form() 3');

my $object2 = $form->object_from_form(class => 'MyObject');

is($object2->name, 'John', 'object_from_form() 4');

is($object2->age, 27, 'object_from_form() 5');

$object->name(undef);
$object->age(undef);

$form->object_from_form($object);

is($object->name, 'John', 'object_from_form() 6');

is($object->age, 27, 'object_from_form() 7');

$object->name('Tina');
$object->age(26);

$form->init_with_object($object);

is($form->field('name')->internal_value, 'Tina', 'init_with_object() 1');

is($form->field('age')->internal_value, 26, 'init_with_object() 2');

$form->params(age => '7', 'bday.month' => 12, 'bday.day' => 25, 'bday.year' => 1995, 
              hobbies => [ 'eating', 'snoozing' ], name => 'Huckleberry',
              sex => 'M', status => 'single');

$form->init_fields();

$form->init_object_with_form($object);

is($form->field('name')->internal_value, 'Huckleberry', 'init_object_with_form() 1');

is($form->field('age')->internal_value, 7, 'init_object_with_form() 2');

$form->method('post');

is($form->start_html, 
  '<form action="/foo/bar" enctype="application/x-www-form-urlencoded" method="post">', 
  'start_html() 2');

is($form->start_xhtml, 
  '<form action="/foo/bar" enctype="application/x-www-form-urlencoded" method="post">', 
  'start_xhtml()');

is($form->start_multipart_html, 
  '<form action="/foo/bar" enctype="multipart/form-data" method="post">', 
  'start_multipart_html()');

is($form->start_multipart_xhtml, 
  '<form action="/foo/bar" enctype="multipart/form-data" method="post">', 
  'start_multipart_xhtml()');

is($form->end_html, '</form>', 'end_html()');
is($form->end_xhtml, '</form>', 'end_xhtml()');

is($form->end_multipart_html, '</form>', 'end_multipart_html()');
is($form->end_multipart_xhtml, '</form>', 'end_multipart_xhtml()');

$form->param(a => [ 1, 2, 3, 4 ]);

$form->delete_param(a => 1);
my $a = $form->param('a');
ok(ref $a eq 'ARRAY' && @$a == 3 && $a->[0] == 2 && $a->[1] == 3 &&
   $a->[2] == 4, 'delete_param() 2');

$form->delete_param(a => [ 2, 3 ]);
$a = $form->param('a');
ok($a == 4, 'delete_param() 3');

$form->delete_param(a => 4);
$a = $form->param('a');
is($a, undef, 'delete_param() 4');
ok(!$form->param_exists('a'), 'delete_param() 5');

$form = MyForm->new();

$form->params(name    => 'John', 
              gender  => 'm',
              hobbies => undef,
              bday    => '1/24/1984');

$form->init_fields;

is($form->field_value('bday')->day, 24, 'field_value() 2');

my $vals = join(':', map { defined $_ ? $_ : '' } 
             $form->field('name')->internal_value,
             $form->field('gender')->internal_value,
             join(', ', $form->field('hobbies')->internal_value),
             $form->field('bday')->internal_value);

is($vals, 'John:m::1984-01-24T00:00:00', 'init_fields() 4');

$form->reset;

$form->params(your_name  => 'John', 
              bday  => '1/24/1984');

$form->init_fields(no_clear => 1);

$vals = join(':', map { defined $_ ? $_ : '' } 
             $form->field('name')->internal_value,
             $form->field('gender')->internal_value,
             join(', ', $form->field('hobbies')->internal_value),
             $form->field('bday')->internal_value);

is($vals, 'John:m:Chess:1984-01-24T00:00:00', 'init_fields() 5');


$form->reset;

$form->params('your_name'  => 'John',
              'bday.month' => 1,
              'bday.day'   => 24,
              'bday.year'  => 1984);

$form->init_fields();

$vals = join(':', map { defined $_ ? $_ : '' } 
             $form->field('name')->internal_value,
             $form->field('gender')->internal_value,
             join(', ', $form->field('hobbies')->internal_value),
             $form->field('bday')->internal_value);

is($vals, 'John:::1984-01-24T00:00:00', 'init_fields() 6');

$form->reset;
$form->params('bday'       => '1/24/1984',
              'bday.month' => 12,
              'bday.day'   => 25,
              'bday.year'  => 1975);

$form->init_fields();

$vals = join(':', map { defined $_ ? $_ : '' } 
             $form->field('name')->internal_value,
             $form->field('gender')->internal_value,
             join(', ', $form->field('hobbies')->internal_value),
             $form->field('bday')->internal_value);

is($vals, ':::1984-01-24T00:00:00', 'init_fields() 7');

$form->reset;
#$form->field('hobbies')->input_value('Knitting');
$form->field_value(hobbies => 'Knitting');
$form->params('hobbies' => undef);

$form->init_fields(no_clear => 1);

$vals = join(':', map { defined $_ ? $_ : '' } 
             $form->field('name')->internal_value,
             $form->field('gender')->internal_value,
             join(', ', $form->field('hobbies')->internal_value),
             $form->field('bday')->internal_value);

is($vals, ':m::', 'init_fields() 8');

$form->action('/foo/bar');
$form->uri_base('http://www.foo.com');
$form->delete_params();
is($form->self_uri, 'http://www.foo.com/foo/bar', 'self_uri()');

$form = MyForm->new(build_on_init => 0);

is(join('', $form->fields), '', 'build_on_init() 1');

$form->build_form;
@fields = $form->fields;

is(scalar @fields, 4,'build_on_init() 2');

$form = Rose::HTML::Form->new;

$form->add_field(Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(name => 'event'));
$form->params(
{
  'event.date.month'  => 10,
  'event.date.day'    => 23,
  'event.date.year'   => 2005,
  'event.time.hour'   => 15,
  'event.time.minute' => 21,
});

$form->init_fields;

my $cgi_params = {
    who                 => 'Some name',
    'event.date.month'  => 10,
    'event.date.day'    => 23,
    'event.date.year'   => 2005,
    'event.time.hour'   => 15,
    'event.time.minute' => 21,
};

$form->params( $cgi_params );
$form->init_fields;

is($form->field('event')->html, 
'<span class="datetime"><span class="date"><input class="month" maxlength="2" name="event.date.month" size="2" type="text" value="10">/<input class="day" maxlength="2" name="event.date.day" size="2" type="text" value="23">/<input class="year" maxlength="4" name="event.date.year" size="4" type="text" value="2005"></span> <span class="time"><input class="hour" maxlength="2" name="event.time.hour" size="2" type="text" value="15">:<input class="minute" maxlength="2" name="event.time.minute" size="2" type="text" value="21">:<input class="second" maxlength="2" name="event.time.second" size="2" type="text" value=""><select class="ampm" name="event.time.ampm" size="1">
<option value=""></option>
<option value="AM">AM</option>
<option value="PM">PM</option>
</select></span></span>', 
'init_fields 3-level compound');

$form = MyForm2->new;

is(join(',', $form->field_monikers), 'name,hobbies,Gender,bday', 'compare_fields() 1');
is(join(',', map { $_->name } $form->fields), 'name,hobbies,gender,bday', 'compare_fields() 2');

$form = MyForm3->new;

is(join(',', $form->field_monikers), 'name,hobbies,bday,Gender', 'field_monikers() 1');
is(join(',', map { $_->name } $form->fields), 'your_name,hobbies,bday,gender', 'field_monikers() 2');

$form = MyForm4->new;

is(join(',', $form->field_monikers), 'name,Gender,hobbies,bday', 'field rank() 1');
is(join(',', map { $_->name } $form->fields), 'your_name,gender,hobbies,bday', 'field rank() 2');
is($form->field('name')->rank, 1, 'field rank() 3');
is($form->field('bday')->rank, 4, 'field rank() 4');

#
# Test field type to class map
#

my $map = MyForm->field_type_classes;
my $i = 1;

$form = MyForm->new;

while(my($name, $class) = each(%$map))
{
  next  unless($class->isa('Rose::HTML::Form::Field'));
  my $method = ('field', 'add_fields')[$i % 2];
  ok(UNIVERSAL::isa($form->$method("test_$i" => { type => $name }), $class), 
     "$method by hash ref - $name");
  $i++;
}

$form->delete_fields;

while(my($name, $class) = each(%$map))
{
  next  unless($class->isa('Rose::HTML::Form::Field'));
  my $method = ('field', 'add_fields')[$i % 2];
  ok(UNIVERSAL::isa($form->$method("test_$i" => $name), $class),
     "$method by type name - $name");
  $i++;
}

SKIP:
{
  skip('RDBO tests', 1)  unless($Have_RDBO);

  my $form = Rose::HTML::Form->new;
  $form->add_fields(id => 'text', b => 'checkbox');
  $form->params({ b => "on", id => 123 });
  $form->init_fields;
  my $o = $form->object_from_form('MyRDBO');
  is($o->b, 1, 'checkbox to RDBO boolean column');
}

use Rose::HTML::Object::Errors qw(:form :field);

$form = MyForm->new;
$form->field('name')->required(1);
$form->validate;

$form->locale('en');
is($form->error->id, FORM_HAS_ERRORS, 'form error id 1');
is($form->error->as_string, 'One or more fields have errors.', 'form error msg 1');
is($form->field('name')->error->id, FIELD_REQUIRED, 'form field error id 1');
is($form->field('name')->error->as_string, 'This is a required field.', 'form field error message 1');
$form->locale('de');
is($form->error->as_string, 'Ein oder mehrere Felder sind fehlerhaft.', 'form error msg 2');
is($form->field('name')->error->id, FIELD_REQUIRED, 'form field error id 1');
is($form->field('name')->error->as_string, "Dies ist ein Pflichtfeld.", 'form field error message 2');
$form->locale('nonesuch');

is($form->error->as_string, 'One or more fields have errors.', 'form error msg 3');
is($form->field('name')->error->as_string, 'This is a required field.', 'form field error message 3');

$form =  Rose::HTML::Form->new;
$field = Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(name => 'event');

$form->add_field($field);

ok(!$form->param_exists_for_field('event'), 'param_exists_for_field() 1');
ok(!$form->param_exists_for_field($field), 'param_exists_for_field() 2');

$form->params({ 'event.date' => '2004-01-02' });

ok($form->param_exists_for_field('event'), 'param_exists_for_field() 3');
ok($form->param_exists_for_field($field), 'param_exists_for_field() 4');

$form->params({ 'event.date.month' => 10 });

ok($form->param_exists_for_field('event'), 'param_exists_for_field() 5');
ok($form->param_exists_for_field($field), 'param_exists_for_field() 6');

$form->params({ 'event' => '2004-01-02 12:34:56' });

ok($form->param_exists_for_field('event'), 'param_exists_for_field() 7');
ok($form->param_exists_for_field($field), 'param_exists_for_field() 8');

my $subform = Rose::HTML::Form->new;
my $subfield = Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(name => 'event');
$subform->add_field($subfield);

$form->form(sub => $subform);

eval { $form->add_field(sub => { type => 'text' }) };
ok($@, 'Illegal subfield name');

$form->params({ });

ok(!$form->param_exists_for_field('sub.event'), 'param_exists_for_field() nested 1');
ok(!$form->param_exists_for_field($subfield), 'param_exists_for_field() nested 2');

$form->params({ 'sub.event.date' => '2004-01-02' });

ok($form->param_exists_for_field('sub.event'), 'param_exists_for_field() nested 3');
ok($form->param_exists_for_field($subfield), 'param_exists_for_field() nested 4');

$form->params({ 'sub.event.date.month' => 10 });

ok($form->param_exists_for_field('sub.event'), 'param_exists_for_field() nested 5');
ok($form->param_exists_for_field($subfield), 'param_exists_for_field() nested 6');

$form->params({ 'sub.event' => '2004-01-02 12:34:56' });

ok($form->param_exists_for_field('sub.event'), 'param_exists_for_field() nested 7');
ok($form->param_exists_for_field($subfield), 'param_exists_for_field() nested 8');

$form->params({ 'sub.event' => '2004-01-02 12:34:56' });

ok(!$form->param_exists_for_field('sub'), 'param_exists_for_field() nested 9');
ok($form->param_exists_for_field('sub.event'), 'param_exists_for_field() nested 10');
ok($form->param_exists_for_field('sub.event.date'), 'param_exists_for_field() nested 11');
ok($form->param_exists_for_field('sub.event.date.month'), 'param_exists_for_field() nested 12');

$form->params({ 'sub.x' => '2004-01-02 12:34:56' });

ok(!$form->param_exists_for_field('sub'), 'param_exists_for_field() nested 13');
ok(!$form->param_exists_for_field('sub.event'), 'param_exists_for_field() nested 14');
ok(!$form->param_exists_for_field('sub.event.date'), 'param_exists_for_field() nested 15');
ok(!$form->param_exists_for_field('sub.event.date.month'), 'param_exists_for_field() nested 16');

$form = Rose::HTML::Form->new;
$form->add_field(when => { type => 'datetime split mdyhms' });

$form->params({ 'when.date' => '2004-01-02' });

ok($form->param_exists_for_field('when'), 'param_exists_for_field() nested 2.1');
ok($form->param_exists_for_field('when.date'), 'param_exists_for_field() nested 2.2');
ok($form->param_exists_for_field('when.date.month'), 'param_exists_for_field() nested 2.3');
ok(!$form->param_exists_for_field('when.time.hour'), 'param_exists_for_field() nested 2.4');

$subform = Rose::HTML::Form->new;
$subform->add_field(subwhen => { type => 'datetime split mdyhms' });

$form->add_form(subform => $subform);

$form->params({ 'subform.subwhen.date' => '2004-01-02' });

ok($form->param_exists_for_field('subform.subwhen'), 'param_exists_for_field() nested 2.5');
ok($form->param_exists_for_field('subform.subwhen.date'), 'param_exists_for_field() nested 2.6');
ok($form->param_exists_for_field('subform.subwhen.date.month'), 'param_exists_for_field() nested 2.7');
ok(!$form->param_exists_for_field('subform.subwhen.time.hour'), 'param_exists_for_field() nested 2.8');

ok(!$form->param_exists_for_field('when'), 'param_exists_for_field() nested 2.9');
ok(!$form->param_exists_for_field('when.date'), 'param_exists_for_field() nested 2.10');
ok(!$form->param_exists_for_field('when.date.month'), 'param_exists_for_field() nested 2.11');
ok(!$form->param_exists_for_field('when.time.hour'), 'param_exists_for_field() nested 2.12');

$form = Rose::HTML::Form->new(onsubmit => 'foo()');

$form->add_fields(n => { type => 'numeric', required => 1 });

$form->params({ n => '' });

$form->init_fields;

is($form->field_value('n'), undef, 'empty string numeric value'); # RT #30249

$form->params({});
$form->init_fields;

is($form->empty_is_ok, 0, 'empty_is_ok 1');
ok(!$form->validate, 'empty_is_ok 2');

$form->empty_is_ok(1);

ok($form->validate, 'empty_is_ok 3');

$form->add_field(save_button => { type => 'submit', value => 'Save' });
$form->add_field(cancel_button => { type => 'submit', value => 'Cancel' });

$form->params({ save_button => 'Save' });
$form->init_fields;

ok($form->field('save_button')->was_submitted, 'button was_submitted 1');
ok(!$form->field('cancel_button')->was_submitted, 'button was_submitted 2');

$form->params({ cancel_button => 'Cancel' });
$form->init_fields;

ok(!$form->field('save_button')->was_submitted, 'button was_submitted 3');
ok($form->field('cancel_button')->was_submitted, 'button was_submitted 4');

$form->params({ save_button => 'Save!' });
$form->init_fields;

ok(!$form->field('save_button')->was_submitted, 'button was_submitted 5');
ok(!$form->field('cancel_button')->was_submitted, 'button was_submitted 6');


BEGIN
{
  our $Have_RDBO;

  package MyRDBO;

  eval 
  {
    require Rose::DB::Object;
    require Rose::DB;
  };

  if($@)
  {
    $Have_RDBO = 0;
  }
  else
  {
    Rose::DB->register_db(driver => 'sqlite');

    $Have_RDBO = 1;
    our @ISA = qw(Rose::DB::Object);

    MyRDBO->meta->setup
    (
      table => 'foo',
      columns =>
      [
        id => { type => 'serial', primary_key => 1 },
        b  => { type => 'boolean' },
      ],
    );
  }

  package MyObject;

  sub new
  {
    bless {}, shift;
  }

  sub name
  {
    my($self) = shift;

    return $self->{'name'} = shift  if(@_);
    return $self->{'name'};
  }

  sub age
  {
    my($self) = shift;

    return $self->{'age'} = shift  if(@_);
    return $self->{'age'};
  }

  sub bday
  {
    my($self) = shift;

    return $self->{'bday'} = shift  if(@_);
    return $self->{'bday'};
  }

  package MyForm;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form 
  {
    my($self) = shift;

    my %fields;

    $fields{'name'} = 
      Rose::HTML::Form::Field::Text->new(
        name => 'name',
        size => 25);

    $fields{'gender'} = 
      Rose::HTML::Form::Field::RadioButtonGroup->new(
        name          => 'gender',
        radio_buttons => { 'm' => 'Male', 'f' => 'Female' },
        default       => 'm');

    $fields{'hobbies'} = 
      Rose::HTML::Form::Field::CheckboxGroup->new(
        name       => 'hobbies',
        checkboxes => [ 'Chess', 'Checkers', 'Knitting' ],
        default    => 'Chess');

    $fields{'bday'} = 
      Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
        name => 'bday');

    $self->add_fields(%fields);

    $self->field('name')->html_attr(name => 'your_name');
  }

  package MyForm2;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form 
  {
    my($self) = shift;

    my %fields;

    $fields{'name'} = 
      Rose::HTML::Form::Field::Text->new(
        name => 'name',
        size => 25);

    $fields{'Gender'} = 
      Rose::HTML::Form::Field::RadioButtonGroup->new(
        name          => 'gender',
        radio_buttons => { 'm' => 'Male', 'f' => 'Female' },
        default       => 'm');

    $fields{'hobbies'} = 
      Rose::HTML::Form::Field::CheckboxGroup->new(
        name       => 'hobbies',
        checkboxes => [ 'Chess', 'Checkers', 'Knitting' ],
        default    => 'Chess');

    $fields{'bday'} = 
      Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
        name => 'bday');

    $self->add_fields(%fields);

    #$self->field('name')->html_attr(name => 'your_name');
  }

  sub compare_fields { lc $_[2]->name cmp lc $_[1]->name }

  package MyForm3;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form 
  {
    my($self) = shift;

    my %fields;

    $fields{'name'} = 
      Rose::HTML::Form::Field::Text->new(
        name => 'name',
        size => 25);

    $fields{'Gender'} = 
      Rose::HTML::Form::Field::RadioButtonGroup->new(
        name          => 'gender',
        radio_buttons => { 'm' => 'Male', 'f' => 'Female' },
        default       => 'm');

    $fields{'hobbies'} = 
      Rose::HTML::Form::Field::CheckboxGroup->new(
        name       => 'hobbies',
        checkboxes => [ 'Chess', 'Checkers', 'Knitting' ],
        default    => 'Chess');

    $fields{'bday'} = 
      Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
        name => 'bday');

    $self->add_fields(%fields);

    $self->field('name')->html_attr(name => 'your_name');
  }

  sub field_monikers { wantarray ? qw(name hobbies bday Gender) : [ qw(name hobbies bday Gender) ] }

  package MyForm4;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form 
  {
    my($self) = shift;

    my %fields;

    $fields{'name'} = 
      Rose::HTML::Form::Field::Text->new(
        name => 'name',
        size => 25);

    $self->add_field(%fields); %fields = ();

    $fields{'Gender'} = 
      Rose::HTML::Form::Field::RadioButtonGroup->new(
        name          => 'gender',
        radio_buttons => { 'm' => 'Male', 'f' => 'Female' },
        default       => 'm');

    $self->add_field(%fields); %fields = ();

    $fields{'hobbies'} = 
      Rose::HTML::Form::Field::CheckboxGroup->new(
        name       => 'hobbies',
        checkboxes => [ 'Chess', 'Checkers', 'Knitting' ],
        default    => 'Chess');

    $self->add_field(%fields); %fields = ();

    $fields{'bday'} = 
      Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
        name => 'bday');

    $self->add_fields(%fields);

    $self->field('name')->html_attr(name => 'your_name');
  }

  sub compare_fields { $_[1]->rank <=> $_[2]->rank }
}

BEGIN
{
  my %params = (a => 'b', c => [ 'd', 'e' ]);

  package FakeCGI;

  sub new { bless {}, shift }

  sub param 
  {
    my($self) = shift;

    if(wantarray)
    {
      if(@_)
      {
        return ref $params{$_[0]} ? @{$params{$_[0]}} : $params{$_[0]};
      }

      return sort keys %params;
    }

    die "Sorry!";
  }

  sub _params { \%params }

  package FakeApache;
  our @ISA = qw(FakeCGI);
}

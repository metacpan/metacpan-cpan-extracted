#!/usr/bin/perl -w

use strict;

use Test::More tests => 69;

BEGIN 
{
  use_ok('Rose::HTML::Form');
  use_ok('Rose::HTML::Form::Field::Text');
  use_ok('Rose::HTML::Form::Field::SelectBox');
  use_ok('Rose::HTML::Form::Field::RadioButtonGroup');
  use_ok('Rose::HTML::Form::Field::CheckboxGroup');
  use_ok('Rose::HTML::Form::Field::DateTime::Split::MonthDayYear');
  use_ok('Rose::HTML::Form::Field::DateTime::Split::MDYHMS');
}

my $form = MyPersonAddressesForm->new;

$form->params({});
$form->init_fields;

my @fields = 
  qw(person.age person.bday person.gender person.name person.start 
     address.1.city address.1.state address.1.street address.1.zip
     address.2.city address.2.state address.2.street address.2.zip);
is_deeply([ $form->field_names ], \@fields, 'person address field names 1');

is_deeply(scalar $form->form_names, [ 'person', 'address' ], 'person addresses form names 1');

$form->params({ 'person.age' => 10, 'address.1.state' => undef, 'address.2.street' => '1 Main St.', 'address.3.zip' => 12345 });

$form->init_fields;

@fields = 
  qw(person.age person.bday person.gender person.name person.start 
     address.1.city address.1.state address.1.street address.1.zip
     address.2.city address.2.state address.2.street address.2.zip
     address.3.city address.3.state address.3.street address.3.zip);

is_deeply([ $form->field_names ], \@fields, 'person address field names 2');

$form->params({ 'person.age' => 10 });

$form->init_fields;

@fields = 
  qw(person.age person.bday person.gender person.name person.start 
     address.1.city address.1.state address.1.street address.1.zip
     address.2.city address.2.state address.2.street address.2.zip);

is_deeply([ $form->field_names ], \@fields, 'person address field names 3');

$form->form('address')->default_count(1);

$form->init_fields;

@fields = 
  qw(person.age person.bday person.gender person.name person.start 
     address.1.city address.1.state address.1.street address.1.zip);

is_deeply([ $form->field_names ], \@fields, 'person address field names 4');

$form->params({ 'person.age' => 10, 'address.1.state' => undef, 'address.2.street' => '1 Main St.', 'address.3.zip' => 12345 });

$form->init_fields;

$form->params({ 'person.age' => 10 });

$form->form('address')->default_count(0);

$form->init_fields;

@fields = qw(person.age person.bday person.gender person.name person.start);

is_deeply([ $form->field_names ], \@fields, 'person address field names 5');

$form->params({ 'person.age' => 10, 'address.1.state' => undef, 'address.2.street' => '1 Main St.', 'address.3.zip' => 12345 });

$form->init_fields;

@fields = 
  qw(person.age person.bday person.gender person.name person.start 
     address.1.city address.1.state address.1.street address.1.zip
     address.2.city address.2.state address.2.street address.2.zip
     address.3.city address.3.state address.3.street address.3.zip);

is_deeply([ $form->field_names ], \@fields, 'person address field names 6');


my $form_b = Rose::HTML::Form->new;
$form_b->add_field(b => { type => 'text' });

my $form_c = Rose::HTML::Form->new;
$form_c->add_field(c => { type => 'text' });

$form_b->add_repeatable_form(c => { form => $form_c, default_count => 2 });
#$form_b->repeatable_form('c')->default_count(2);

$form = Rose::HTML::Form->new;
$form->add_field(a => { type => 'text' });

$form->add_form(b => $form_b);

$form->init_fields;

@fields = qw(a b.b b.c.1.c b.c.2.c);
is_deeply([ $form->field_names ], \@fields, 'two-level repeat 1');

$form->params({ a => 'a', 'b.b' => 'bb', 'b.c.3.c' => 'bc3' });
$form->init_fields;
@fields = qw(a b.b b.c.3.c);
is_deeply([ $form->field_names ], \@fields, 'two-level repeat 2');

$form->params({ 'b.c.3.c' => 'bc3', 'b.c.1.c' => 'bc1' });
$form->init_fields;
@fields = qw(a b.b b.c.1.c b.c.3.c);
is_deeply([ $form->field_names ], \@fields, 'two-level repeat 3');

$form->params({ 'b.c.3.c' => 'bc3', 'b.c.2.c' => undef, 'b.c.1.c' => 'bc1' });
$form->init_fields;
@fields = qw(a b.b b.c.1.c b.c.2.c b.c.3.c);
is_deeply([ $form->field_names ], \@fields, 'two-level repeat 4');


my $form_x = Rose::HTML::Form->new;
$form_x->add_fields
(
  'x' => { type => 'text' },
  'y' => { type => 'text' },
  'z' => { type => 'text' },
);

$form_x->add_repeatable_form(f => $form);
$form_x->repeatable_form('f')->default_count(2);

$form_x->init_fields;
@fields = qw(x y z f.1.a f.1.b.b f.1.b.c.1.c f.1.b.c.2.c f.2.a f.2.b.b f.2.b.c.1.c f.2.b.c.2.c);
is_deeply([ map { $_->name } $form_x->fields_depth_first ], \@fields, 'three-level repeat 1');

my $new_form = $form_x->form('f')->make_form(1);
@fields = qw(f.1.a f.1.b.b f.1.b.c.1.c f.1.b.c.2.c f.1.b.c.3.c);
is_deeply([ map { $_->name } $new_form->fields_depth_first ], \@fields, 'make_form 1');

$new_form = $form_x->form('f')->make_form(7);
@fields = qw(f.7.a f.7.b.b f.7.b.c.1.c f.7.b.c.2.c f.7.b.c.3.c);
is_deeply([ map { $_->name } $new_form->fields_depth_first ], \@fields, 'make_form 2');

#print join(' ', map { $_->name } $form_x->fields_depth_first), "\n";

@fields = qw(x y z f.1.a f.1.b.b f.1.b.c.1.c f.1.b.c.2.c f.1.b.c.3.c f.2.a f.2.b.b f.2.b.c.1.c 
             f.2.b.c.2.c f.7.a f.7.b.b f.7.b.c.1.c f.7.b.c.2.c f.7.b.c.3.c);
is_deeply([ map { $_->name } $form_x->fields_depth_first ], \@fields, 'make_form 3');

#print join(' ', map { $_->name } $new_form->fields_depth_first), "\n";

#$DB::single = 1;
#print join(' ', map { $_->name } $form_x->fields_depth_first), "\n";
#print $form_x->xhtml_table;
#exit;

$new_form = $form_x->form('f')->make_next_form;

is($new_form->rank, 8, 'make_next_form 1');

$form = Rose::HTML::Form->new;

$form->add_forms
(
  a =>
  {
    form_spec     => { fields =>  [ x => { type => 'text' } ] },
    default_count => 0,
    repeatable    => 999,
  },
);

$new_form = $form->form('a')->make_next_form;
is($new_form->rank, 1, 'make_next_form 2');

$form = Rose::HTML::Form->new;

$form->add_forms
(
  a =>
  {
    form_spec     => { fields =>  [ x => { type => 'text' } ] },
    default_count => 0,
    repeatable    => 999,
  },
);

$form->trim_xy_params(0);
$form->params({ 'a.1.x' => 'foo' });

$form->init_fields;

ok($form->form('a.1')->field('x'), 'form spec 1');

$form = Rose::HTML::Form->new;

$form->add_forms
(
  a =>
  {
    form_class => 'EmailForm',
    form_spec  => { add_fields => [ x => { type => 'text' } ] },
    repeatable => 0,
  },
);

$form->trim_xy_params(0);
$form->params({ 'a.1.x' => 'foo' });

$form->init_fields;

ok($form->form('a.1')->field('x'), 'form spec 2');
ok($form->form('a.1')->isa('EmailForm'), 'form spec 3');

#
# POD example
#

POD_EXAMPLE:
{
  package Person;

  use base 'Rose::Object';

  use Rose::Object::MakeMethods::Generic
  (
    scalar => [ 'name', 'age' ],
    array  => 'emails',
  );

  #...  

  package Email;

  use base 'Rose::Object';

  use Rose::Object::MakeMethods::Generic
  (
    scalar => 
    [
      'address',
      'type' => { check_in => [ 'home', 'work' ] },
    ],
  );

  #...

  package EmailForm;

  use base 'Rose::HTML::Form';

  sub build_form 
  {
    my($self) = shift;

    $self->add_fields
    (
      address     => { type => 'email', size => 50, required => 1 },
      type        => { type => 'pop-up menu', choices => [ '', 'home', 'work' ],
                       required => 1, default => '' },
      save_button => { type => 'submit', value => 'Save Email' },
    );
  }

  sub email_from_form { shift->object_from_form('Email') }
  sub init_with_email { shift->init_with_object(@_) }

  #...

  package PersonEmailsForm;

  use base 'Rose::HTML::Form';

  sub build_form 
  {
    my($self) = shift;

    $self->add_fields
    (
      name        => { type => 'text',  size => 25, required => 1 },
      age         => { type => 'integer', min => 0 },
      save_button => { type => 'submit', value => 'Save Person' },
    );

    # A person can have several emails
    $self->add_repeatable_form(emails => EmailForm->new);
    $self->repeatable_form(emails => EmailForm->new);

    $self->repeatable_form('emails')->default_count(2);

    Test::More::ok($self->form('emails')->prototype_form->isa('EmailForm'), 'add_repeatable_form (name/object) 1');
    Test::More::is($self->form('emails')->default_count, 2, 'add_repeatable_form (name/object) 2');
    Test::More::is($self->repeatable_form('emails')->default_count, 2, 'add_repeatable_form (name/object) 3');

    $self->delete_repeatable_form('emails');

    $self->add_repeatable_form
    (
      emails => 
      {
        form_class    => 'EmailForm',
        default_count => 2,
      },
    );

    Test::More::ok($self->form('emails')->prototype_clone->isa('EmailForm'), 'add_repeatable_form (name/hash) 1');
    Test::More::is($self->form('emails')->default_count, 2, 'add_repeatable_form (name/hash) 2');
    Test::More::is($self->repeatable_form('emails')->default_count, 2, 'add_repeatable_form (name/hash) 3');

    $self->delete_form('emails');

    $self->add_forms
    (
      emails => 
      {
        form_class    => 'EmailForm',
        default_count => 2,
        repeatable    => undef,
      },
    );

    Test::More::ok($self->repeatable_form('emails')->prototype_clone->isa('EmailForm'), 'add_form (name/hash) 1');
    Test::More::is($self->form('emails')->default_count, 2, 'add_form (name/hash) 2');
    Test::More::is($self->repeatable_form('emails')->default_count, 2, 'add_form (name/hash) 3');

    $self->delete_repeatable_form('emails');

    $self->add_forms
    (
      emails => 
      {
        form_class => 'EmailForm',
        repeatable => { default_count => 2 },
      },
    );

    Test::More::ok($self->form('emails')->prototype_form_clone->isa('EmailForm'), 'add_form (name/hash) 4');
    Test::More::is($self->form('emails')->default_count, 2, 'add_form (name/hash) 5');
    Test::More::is($self->repeatable_form('emails')->default_count, 2, 'add_form (name/hash) 6');

    $self->delete_repeatable_form('emails');

    $self->add_repeatable_form(emails => EmailForm->new);
  }

  sub init_with_person
  {
    my($self, $person) = @_;

    $self->init_with_object($person);

    my $email_form = $self->form('emails');

    $email_form->delete_forms;

    my $i = 1;

    foreach my $email ($person->emails)
    {
      $email_form->make_form($i++)->init_with_email($email);
    }
  }

  sub person_from_form
  {
    my($self) = shift;

    my $person = $self->object_from_form(class => 'Person');

    my @emails;

    foreach my $form ($self->form('emails')->forms)
    {
      push(@emails, $form->email_from_form);
    }

    $person->emails(@emails);

    return $person;
  }

  package main;

  my $form = PersonEmailsForm->new;

  my $person = Person->new(name   => 'Cate', 
                           age    => 1, 
                           emails => 
                           [
                             'cate@cakes.com',
                             'cate@wubbler.com',
                           ]);

  $form->init_with_person($person);

  @fields = qw(name age save_button emails.1.address emails.1.type emails.1.save_button emails.2.address emails.2.type emails.2.save_button);
  is_deeply([ map { $_->name } $form->fields_depth_first ], \@fields, 'make_form 3');

  $form->params({ name => 'Joe', age => 44, 'emails.5.address' => 'x@x.com', 'emails.5.type' => 'work' });
  $form->init_fields;

  ok($form->validate, 'validate 1');

  $person = $form->person_from_form;

  is($person->name, 'Joe', 'person_from_form 1');
  is($person->age, 44, 'person_from_form 2');
  is($person->emails->[0]->address, 'x@x.com', 'person_from_form 3');
  is($person->emails->[0]->type, 'work', 'person_from_form 3');
  is(@{ $person->emails }, 1, 'person_from_form 4');

  $form->params({ name => 'Joe2', age => 44, 'emails.1.address' => 'x2@x.com', 'emails.1.type' => 'work',
                  'emails.2.address' => undef, 'emails.2.type' => 'work'});
  $form->init_fields;

  ok(!$form->validate, 'validate 2');

  $form->params({ name => 'Joe3', age => 44, 'emails.1.address' => 'x3@x.com', 'emails.1.type' => 'work',
                  'emails.2.address' => 'y3@y.com', 'emails.2.type' => 'home'});
  $form->init_fields;

  ok($form->validate, 'validate 3');

  $person = $form->person_from_form;

  is($person->name, 'Joe3', 'person_from_form 5');
  is($person->age, 44, 'person_from_form 6');
  is($person->emails->[0]->address, 'x3@x.com', 'person_from_form 7');
  is($person->emails->[0]->type, 'work', 'person_from_form 8');
  is($person->emails->[1]->address, 'y3@y.com', 'person_from_form 9');
  is($person->emails->[1]->type, 'home', 'person_from_form 10');
  is(@{ $person->emails }, 2, 'person_from_form 11');


  $form->form('emails')->default_count(1);
  $form->params({});
  $form->init_fields;

  $form->empty_is_ok(1);
  is($form->empty_is_ok, 1, 'empty_is_ok 1');

  ok($form->validate, 'empty_is_ok 2');

  $form->empty_is_ok(0);
  is($form->empty_is_ok, 0, 'empty_is_ok 3');

  ok(!$form->validate, 'empty_is_ok 4');

  #print join(' ', map { $_->name } $form->fields_depth_first), "\n";

  #$DB::single = 1;
  #print join(' ', map { $_->name } $form_x->fields_depth_first), "\n";
  #print $form_x->xhtml_table;

  #print $form->xhtml_table;
}

$form = MyFamilyForm->new;

$form->params({ 
  'parents.1.age' => 40,
  'parents.1.name' => 'John',
  'parents.1.gender' => 'M',
  'children.1.age' => 4,
  'children.1.name' => 'Tim',
  'children.1.gender' => 'M',
});

$form->init_fields;

ok(!$form->validate, 'nested validation 1');
ok($form->field('name')->has_errors, 'nested validation 2');

$new_form = $form->form('parents')->make_next_form;

is($new_form->rank, 2, 'make_next_form 3');

$form->params({ 
  'name' => 'The Smiths',
  'parents.1.age' => 40,
  'parents.1.name' => 'John',
  'parents.1.gender' => 'M',
  'children.1.age' => '',
  'children.1.name' => '',
  'children.1.gender' => '',
});

$form->init_fields;

ok($form->validate, 'nested validation 3');

$form->params({ 
  'name' => 'The Smiths',
  'parents.1.age' => 40,
  'parents.1.name' => 'John',
  'parents.1.gender' => 'M',
  'children.1.age' => 4,
  'children.1.name' => 'Tim',
  'children.1.gender' => 'M',
  'children.3.age' => 5,
  'children.3.name' => 'Jill',
  'children.3.gender' => 'F',
});

$form->init_fields;

ok($form->validate, 'nested validation 4');

my @forms = $form->form('children')->forms;

is(scalar @forms, 2, 'sparse repeated form 1');

is($form->form('children')->form(1)->field_value('name'), 'Tim', 'sparse repeated form 2');
is($form->form('children')->form(3)->field_value('name'), 'Jill', 'sparse repeated form 3');

$form->params({ 
  'name' => 'The Smiths',
  'parents.1.age' => 40,
  'parents.1.name' => 'John',
  'parents.1.gender' => 'M',
  'children.1.age' => 4,
  'children.1.name' => 'Tim',
  'children.1.gender' => 'M',
  'children.2.age' => '',
  'children.2.name' => '',
  'children.2.gender' => '',
  'children.3.age' => 5,
  'children.3.name' => 'Jill',
  'children.3.gender' => 'F',
});

$form->init_fields;

@forms = $form->form('children')->forms;

is(scalar @forms, 3, 'sparse repeated form 4');

ok($form->form('children')->form(2)->is_empty, 'sparse repeated form 5');

BEGIN
{
  package MyPerson;

  our @ISA = qw(Rose::Object);
  use Rose::Object::MakeMethods::Generic
  (
    scalar => [ qw(name age bday gender start) ],
  );

  package MyAddress;

  our @ISA = qw(Rose::Object);
  use Rose::Object::MakeMethods::Generic
  (
    scalar => [ qw(street city state zip) ],
  );

  package MyPersonForm;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form 
  {
    my($self) = shift;

    $self->add_fields
    (
      name =>
      {
        type => 'text',
        size => 25,
      },

      age =>
      {
        type     => 'integer',
        positive => 1,
      },

      gender =>
      {
        type     => 'radio group',
        choices  => { 'm' => 'Male', 'f' => 'Female' },
        default  => 'm',
      },

      bday =>
      {
        type => 'datetime split mdy', 
      },

      start =>
      {
        type => 'datetime split mdyhms',
      },
    );
  }

  sub person_from_form { shift->object_from_form('MyPerson') }

  package MyAddressForm;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form 
  {
    my($self) = shift;

    $self->add_fields
    (
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

      state => 
      {
        type => 'text',
        size => 2,
      },

      zip => 
      {
        type => 'text',
        size => 10,
      },
    );
  }

  sub validate
  {
    my($self) = shift;

    $self->SUPER::validate or return 0;
    $self->field('street')->error('Blah');
    no warnings 'uninitialized';
    return ($self->field('zip')->internal_value == 666) ? 0 : 1;
  }

  sub address_from_form { shift->object_from_form('MyAddress') }

  package MyPersonAddressesForm;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form
  {
    my($self) = shift;

    $self->add_forms
    (
      person  => MyPersonForm->new,
      address => 
      {
        form       => MyAddressForm->new,
        repeatable => 2,
      }
    );
  }

  package MyPersonAddressDogForm;

  our @ISA = qw(MyAddressForm MyPersonForm);

  sub build_form 
  {
    my($self) = shift;

    my %fields;

    $fields{'dog'} = 
      Rose::HTML::Form::Field::Text->new(
        name => 'dog',
        size => 50);

    $self->add_fields(%fields);

    $self->add_forms
    (
      person_addresses => MyPersonAddressesForm->new,
    );
  }

  package MyPersonForm2;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form
  {
    my ($self) = shift;

    $self->add_fields
    (
      name => 
      {
        type     => 'text',
        label    => 'Name',
        required => 1,
      },

      age => 
      {
        type     => 'integer',
        min      => 0,
        max      => 200,
        label    => 'Age',
        size     => 3,
        required => 1,
      },

      gender => 
      {
        type    => 'pop-up menu',
        options => ['', qw(M F)],
        labels  => 
        {
          '' => '',
          M  => 'Male',
          F  => 'Female',
        },
        default  => '',
        required => 1,
        label    => 'Gender',
      },

      create_button => 
      {
        type  => 'submit',
        value => 'Create Person',
      },
    );
  }

  package MyFamilyForm;

  our @ISA = qw(Rose::HTML::Form);

  sub build_form
  {
    my ($self) = shift;

    $self->add_forms
    (
      parents => 
      {
        form       => MyPersonForm2->new,
        repeatable => 1,
      },

      children => 
      {
        form        => MyPersonForm2->new,
        repeatable  => 1,
        empty_is_ok => 1,
      },
    );

    $self->add_fields
    (
      name => 
      {
        type     => 'text',
        label    => 'Family Name',
        required => 1,
      },

      add_child_button => 
      {
        type  => 'submit',
        value => 'Add Child',
        id    => 'add-child-button',
      },

      add_parent_button => 
      {
        type  => 'submit',
        value => 'Add Parent',
        id    => 'add-parent-button',
      },

      create_button => 
      {
        type  => 'submit',
        value => 'Create Family',
      },
    );
  }

#   sub validate
#   {
#     my ($self) = shift;
# 
#     my $ok = $self->SUPER::validate(cascade => 0);
#     return $ok unless ($ok);
# 
#     foreach my $parentform ( $self->form('parents')->forms )
#     {
#       next if ( $parentform->is_empty );
# 
#       unless ( $parentform->validate )
#       {
#         $self->add_error( 'Invalid parent: ' . $parentform->error );
#         $ok = 0;
#       }
#     }
# 
#     foreach my $childform ( $self->form('children')->forms )
#     {
#       next if ( $childform->is_empty );
# 
#       unless ( $childform->validate )
#       {
#         $self->add_error( 'Invalid child: ' . $childform->error );
#         $ok = 0;
#       }
#     }
# 
#     return $ok;
#   }
}

package Rose::HTML::Form::Repeatable;

use strict;

use Rose::HTML::Form;

use base 'Rose::HTML::Object::Repeatable';

our $VERSION = '0.616';

__PACKAGE__->default_form_class('Rose::HTML::Form');

#
# Class methods
#

sub default_form_class { shift->default_prototype_class(@_) }

#
# Object methods
#

sub prototype_form       { shift->prototype(@_) }
sub prototype_form_spec  { shift->prototype_spec(@_) }
sub prototype_form_class { shift->prototype_class(@_) }
sub prototype_form_clone { shift->prototype_clone(@_) }

sub form_class { shift->prototype_form_class(@_) }

sub is_repeatable_form { 1 }

sub prepare
{
  my($self) = shift;
  my(%args) = @_;

  my $fq_form_name = quotemeta $self->fq_form_name;

  my $re = qr(^$fq_form_name\.(\d+)\.);

  my %have_num;

  foreach my $param (keys %{$self->params})
  {
    if($param =~ $re)
    {
      my $num = $1;
      $have_num{$num}++;
      my $form = $self->form($num) || $self->make_form($num);
    }
  }

  unless(%have_num)
  {
    if($self->default_count)
    {
      foreach my $num (1 .. $self->default_count)
      {
        $self->form($num) || $self->make_form($num);
        $have_num{$num}++;
      }
    }
    else
    {
      $self->delete_forms;
    }
  }

  if(%have_num)
  {
    foreach my $form ($self->forms)
    {
      unless($have_num{$form->form_name})
      {
        $self->delete_form($form->form_name);
      }
    }
  }

  $self->SUPER::prepare(@_)  unless(delete $args{'init_only'});
}

sub init_fields
{
  my($self) = shift;
  $self->prepare(init_only => 1);
  $self->SUPER::init_fields(@_);
}

sub make_form
{
  my($self, $num) = @_;

  Carp::croak "Missing form nubmer argument"  unless(@_ > 1);
  Carp::croak "Form number argument must be greater than 0"  unless($num > 0);

  my $form = $self->prototype_form_clone;

  $form->rank($num);

  $self->form_rank_counter($num + 1)  if($num >= $self->form_rank_counter);

  $form->prepare;

  $self->add_form($num => $form);

  return $form;
}

sub make_next_form
{
  my ($self) = shift;
  $self->increment_form_rank_counter; # XXX: Remove when form_rank_counter is removed
  return $self->make_form($self->next_form_rank);
}

sub objects_from_form
{
  my($self) = shift;

  my $method = 'object_from_form';

  if(@_ > 1)
  {
    my %args = @_;
    $method = $args{'method'}  if($args{'method'});
  }

  my @objects = map { $_->$method(@_) } $self->forms;

  return wantarray ? @objects : \@objects;
}

sub init_with_objects
{
  my($self) = shift;

  my $method = 'init_with_object';

  my $objects;

  if(@_ > 1)
  {
    my %args = @_;
    $method = $args{'method'}  if($args{'method'});
    $objects = $args{'objects'};
  }

  unless($objects)
  {
    $objects = \@_;
  }

  foreach my $form ($self->forms)
  {
    $form->$method(shift(@$objects));
  }
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Repeatable - Repeatable sub-form automation.

=head1 SYNOPSIS

  package Person;

  use base 'Rose::Object';

  use Rose::Object::MakeMethods::Generic
  (
    scalar => [ 'name', 'age' ],
    array  => 'emails',
  );

  ...  

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

  ...

  package EmailForm;

  use base 'Rose::HTML::Form';

  sub build_form 
  {
    my($self) = shift;

    $self->add_fields
    (
      address     => { type => 'email', size => 50, required => 1 },
      type        => { type => 'pop-up menu', choices => [ 'home', 'work' ],
                       required => 1, default => 'home' },
      save_button => { type => 'submit', value => 'Save Email' },
    );
  }

  sub email_from_form { shift->object_from_form('Email') }
  sub init_with_email { shift->init_with_object(@_) }

  ...

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

    ##
    ## The important part happens here: add a repeatable form
    ##

    # A person can have zero or more emails
    $self->add_repeatable_form(emails => EmailForm->new);

    # Alternate ways to add the same repeatable form:
    #
    # Name/hashref pair:
    # $self->add_repeatable_form(emails => { form_class => 'EmailForm' });
    #
    # Using the generic add_form() method:
    # $self->add_form
    # (
    #   emails => 
    #   {
    #     form_class    => 'EmailForm',
    #     default_count => 0,
    #     repeatable    => 1,
    #   }
    # );
    #
    # See the documentation for Rose::HTML::Form's add_forms() and 
    # add_repeatable_forms() methods for more information.
  }

  sub init_with_person
  {
    my($self, $person) = @_;

    $self->init_with_object($person);

    # Delete any existing email forms and create 
    # the appropriate number for this $person

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

=head1 DESCRIPTION

L<Rose::HTML::Form::Repeatable> provides a convenient way to include zero or more copies of a nested form.  See the L<nested forms|Rose::HTML::Form/"NESTED FORMS"> section of the L<Rose::HTML::Form> documentation for some essential background information.

L<Rose::HTML::Form::Repeatable> works like a wrapper for an additional level of sub-forms.  The L<Rose::HTML::Form::Repeatable> object itself has no fields.  Instead, it has a list of zero or more sub-forms, each of which is named with a positive integer greater than zero.

The L<synopsis|/SYNOPSIS> above contains a full example.  In it, the C<PersonEmailsForm> contains zero or more L<EmailForm> sub-forms under the name C<emails>.  The C<emails> name identifies the L<Rose::HTML::Form::Repeatable> object, while C<emails.N> identifies each L<EmailForm> object contained within it (e.g., C<emails.1>, C<emails.2>, etc.).

Each repeated form must be of the same class.  A repeated form can be generated by cloning a L<prototype form|/prototype_form> or by instantiating a specified L<prototype form class|/prototype_form_class>.

A repeatable form decides how many of each repeated sub-form it should contain based on the contents of the query parameters (contained in the L<params|Rose::HTML::Form/params> attribute for the parent form).  If there are no L<params|Rose::HTML::Form/params>, then the L<default_count|/default_count> determines the number of repeated forms.

Repeated forms are created in response to the L<init_fields|/init_fields> or L<prepare|/prepare> methods being called.  In the L<synopsis|/SYNOPSIS> example, the C<person_from_form> method does not need to create, delete, or otherwise set up the repeated email sub-forms because it can sensibly assume that the  L<init_fields|/init_fields> and/or L<prepare|/prepare> methods have been called already.  On the other hand, the C<init_with_person> method must configure the repeated email forms based on the number of email addresses contained in the C<Person> object that it was passed.

On the client side, the usual way to handle repeated sub-forms is to make an AJAX request for new content to add to an existing form.  The L<make_form|/make_form> method is designed to do exactly that, returning a correctly namespaced L<Rose::HTML::Form>-derived object ready to have its fields serialized (usually through a template) into HTML which is then inserted into the existing form on a web page.

This class inherits from and follows the conventions of L<Rose::HTML::Form>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form> documentation for more information.

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Repeatable> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 CLASS METHODS

=over 4

=item B<default_form_class [CLASS]>

Get or set the name of the default L<Rose::HTML::Form>-derived class of the repeated form.  The default value is L<Rose::HTML::Form>.

=back

=head1 OBJECT METHODS

=over 4

=item B<default_count [INT]>

Get or set the default number of repeated forms to create in the absence of any L<parameters|Rose::HTML::Form/params>.  The default value is zero.

=item B<empty_is_ok [BOOL]>

Get or set a boolean value that indicates whether or not it's OK for a repeated form to be empty.  (That is, validation should not fail if the entire sub-form is empty, even if the sub-form has required fields.)  Defaults to false.

=item B<init_fields>

In addition to doing all the usual things that the L<base class implementation|Rose::HTML::Form/init_fields> does, this method creates or deletes repeated sub-forms as necessary to make sure they match the query L<parameters|Rose::HTML::Form/params>, if present, or the L<default_count|/default_count> if there are no L<parameters|Rose::HTML::Form/params> that apply to any of the sub-forms.

=item B<init_with_objects [ OBJECTS | PARAMS ]>

Given a list of OBJECTS or name/value pairs PARAMS, initialize each sub-form, taking one object from the list and passing it to a method called on each sub-form.  The first object is passed to the first form, the second object to the second form, and so on.  (Form order is determined by the the order forms are returned from the L<forms|Rose::HTML::Form/forms> method.)

Valid parameters are:

=over 4

=item B<objects ARRAYREF>

A reference to an array of objects with which to initialize the form(s).  This parameter is required if PARAMS are passed.

=item B<method NAME>

The name of the method to call on each sub-form.  The default value is C<init_with_object>.

=back

=item B<make_form INT>

Given an integer argument greater than zero, create, add to the form, and return a new numbered L<prototype form clone|/prototype_form_clone> object.

=item B<make_next_form>

Create, add to the form, and return a new numbered L<prototype form clone|/prototype_form_clone> object whose L<rank|Rose::HTML::Form/rank> is one greater than the the highest-ranking existing sub-form.

=item B<objects_from_form [PARAMS]>

Return a list (in list context) or reference to an array (in scalar context) of objects corresponding to the list of repeated sub-forms.  This is done by calling a method on each sub-form and collecting the return values.  Name/value parameters may be passed.  Valid parameters are:

=over 4

=item B<method NAME>

The name of the method to call on each sub-form.  The default value is C<object_from_form>.

=back

=item B<prepare>

This method does the same thing as the L<init_fields|/init_fields> method, but calls through to the L<base class prepare|Rose::HTML::Form/prepare> method rather than the  L<base class init_fields|Rose::HTML::Form/init_fields> method.

=item B<prototype_form [FORM]>

Get or set the L<Rose::HTML::Form>-derived object used as the prototype for each repeated form.

=item B<prototype_form_class [CLASS]>

Get or set the name of the L<Rose::HTML::Form>-derived class used by the L<prototype_form_clone|/prototype_form_clone> method to create each repeated sub-form.  The default value is determined by the L<default_form_class|/default_form_class> class method.

=item B<prototype_form_spec [SPEC]>

Get or set the specification for the L<Rose::HTML::Form>-derived object used as the prototype for each repeated form.  The SPEC can be a reference to an array, a reference to a hash, or a list that will be coerced into a reference to an array.  In the absence of a L<prototype_form|/prototype_form>, the SPEC is dereferenced and passed to the C<new()> method called on the L<prototype_form_class|/prototype_form_class> in order to create each L<prototype_form_clone|/prototype_form_clone>.

=item B<prototype_form_clone>

Returns a clone of the L<prototype_form|/prototype_form>, if one was set.  Otherwise, creates and returns a new L<prototype_form_class|/prototype_form_class> object, passing the L<prototype_form_spec|/prototype_form_spec> to the constructor.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

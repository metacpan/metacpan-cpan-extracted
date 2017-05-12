package Mojolicious::Plugin::FormFields;

# TODO: We're not much of a subclass now
use Mojo::Base 'Mojolicious::Plugin::ParamExpand';

our $VERSION = '0.05';

sub register
{
  my ($self, $app, $config) = @_;
  my $ns = 'formfields.fields';

  $config->{separator} = Mojolicious::Plugin::FormFields::Field->separator;
  $self->SUPER::register($app, $config);

  $app->helper(field => sub {
      my $c    = shift;
      my $name = shift || '';
      $c->stash->{$ns}->{$name} ||= Mojolicious::Plugin::FormFields::Field->new($c, $name, @_);
      $c->stash->{$ns}->{$name};
  });

  $app->helper(fields => sub {
      my $c    = shift;
      my $name = shift || '';
      $c->stash->{$ns}->{$name} ||= Mojolicious::Plugin::FormFields::ScopedField->new($c, $name, @_);
      $c->stash->{$ns}->{$name};
  });

  my $methods = $config->{methods};
  my $helper = $methods->{valid} // 'valid';
  $app->helper($helper => sub {
      my $c = shift;
      my $valid = 1;
      my $errors = {};

      # TODO: skip keys used by fields()
      while(my ($name, $field) = each %{$c->stash->{$ns}}) {
	  if(!$field->valid) {
	      $valid = 0;
	      $errors->{$name} = $field->error;
	  }
      }

      $c->stash->{"$ns.errors"} = $errors;
      $valid;
  });

  $helper = $methods->{errors} // 'errors';
  $app->helper($helper => sub {
      my ($c, $name) = @_;
      my $errors = $c->stash->{"$ns.errors"} // {};
      $name ? { $name => $errors->{$name} } : $errors;
  });
}

package Mojolicious::Plugin::FormFields::Field;

use Mojo::Base -strict;
use Scalar::Util;
use Carp ();
use Validate::Tiny;

use overload
    '@{}' => '_to_fields',
    '""'  => '_to_string',
    bool  => sub { 1 },
    fallback => 1;

my $SEPARATOR = '.';

sub new
{
    my $class = shift;
    my ($c, $name, $object) = @_;
    Carp::croak 'field name required' unless $name;

    my $self = bless {
	c       => $c,
	name    => $name,
	object  => $object,
	checks  => [],
	filters => []
    }, $class;

    Scalar::Util::weaken $self->{c};
    $self;
}

sub checkbox
{
    my $self = shift;

    my $value;
    $value = shift if @_ % 2;
    $value //= 1;

    my %options = @_;
    $options{value} = $value;

    $self->input('checkbox', %options);
}

sub file
{
    my ($self, %options) = @_;
    $options{id} //= _dom_id($self->{name});

    $self->{c}->file_field($self->{name}, %options);
}

sub input
{
    my ($self, $type, %options) = @_;
    my $value = $self->_lookup_value;

    $options{id} //= _dom_id($self->{name});
    $options{value} //= $value if defined $value;
    $options{type} = $type;

    if($type eq 'checkbox' || $type eq 'radio') {
	$options{checked} = 'checked'
	    if !exists $options{checked} && defined $value && $value eq $options{value};
    }

    $self->{c}->input_tag($self->{name}, %options);
}

sub hidden
{
    my ($self, %options) = @_;
    $self->input('hidden', %options);
}

sub radio
{
    my ($self, $value, %options) = @_;
    Carp::croak 'value required' unless defined $value;

    $options{id} //= _dom_id($self->{name}, $value);
    $options{value} = $value;

    $self->input('radio', %options);
}

sub select
{
    my $self = shift;
    my $options = @_ % 2 ? shift : [];
    my %attr = @_;
    $attr{id} //= _dom_id($self->{name});

    my $c = $self->{c};
    my $name = $self->{name};
    my $field;

    if(defined $c->param($name)) {
	$field = $c->select_field($name, $options, %attr);
    }
    else {
	# Make select_field select the value
	$c->param($name, $self->_lookup_value);
	$field = $c->select_field($name, $options, %attr);
	$c->param($name, undef);
    }

    $field;
}

sub password
{
    my ($self, %options) = @_;
    $options{id} //= _dom_id($self->{name});

    $self->{c}->password_field($self->{name}, %options);
}

sub label
{
    my $self = shift;

    my $text;
    $text = pop if ref $_[-1] eq 'CODE';
    $text = shift if @_ % 2;	# step on CODE
    $text //= _default_label($self->{name});

    my %options = @_;
    $options{for} //= _dom_id($self->{name});

    $self->{c}->tag('label', %options, $text)
}

sub text
{
    my ($self, %options) = @_;
    $self->input('text', %options);
}

sub textarea
{
    my ($self, %options) = @_;
    $options{id} //= _dom_id($self->{name});

    my $size = delete $options{size};
    if($size && $size =~ /^(\d+)[xX](\d+)$/) {
	$options{rows} = $1;
	$options{cols} = $2;
    }

    $self->{c}->text_area($self->{name}, %options, sub { $self->_lookup_value || '' });
}

sub each
{
    my $self = shift;
    my $block = pop;
    my $fields = $self->_to_fields;

    return $fields unless ref($block) eq 'CODE';

    local $_;
    $block->() for @$fields;

    return;
}

sub check
{
    my $self = shift;
    push @{$self->{checks}}, $self->{name} => shift;
    $self;
}

sub filter
{
    my $self = shift;
    my $data = ref $_[0] eq 'CODE' ? shift : Validate::Tiny::filter(@_);
    push @{$self->{filters}}, $self->{name} => $data;
    $self;
}

# Just a single value
sub error
{
    my $self = shift;
    $self->{result}->{error}->{$self->{name}};
}

sub separator { $SEPARATOR; }

sub valid
{
    my $self = shift;
    return $self->{result}->{success} if defined $self->{result};

    my $result;
    my $name  = $self->{name};
    my $value = $self->{c}->param($name);
    my $field = { $name => $value };
    my $rules = {
	fields  => [ $name ],
	checks  => $self->{checks},
	filters => $self->{filters}
    };

    # A bit of massaging For the is_equal() validation
    my $eq = $self->{eq_to_field};
    if($eq) {
	$field->{$eq} = $self->{c}->param($eq);
	push @{$rules->{fields}}, $eq;
    }

    $result = Validate::Tiny::validate($field, $rules);
    $self->{c}->param($name, $result->{data}->{$name}) if @{$self->{filters}};
    $self->{result} = $result;

    $result->{success};
}

sub is_equal
{
    my $self = shift;
    $self->{eq_to_field} = $_[0];
    push @{$self->{checks}}, $self->{name} => Validate::Tiny::is_equal(@_);
}

# Avoid AUTOLOAD call
sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self   = shift;
   (my $method = $AUTOLOAD) =~ s/[^':]+:://g;

    if($method =~ /^is_/) {
	my $check = Validate::Tiny->can($method);
	die qq|Can't locate object method "$method" via package "${ \__PACKAGE__ }"| unless $check;

	push @{$self->{checks}}, $self->{name} => $check->(@_);
    }
    else {
	# TODO: What's the use case for this?
	# field('name')->trim instead of field('name')->filter('trim')?
	push @{$self->{filters}}, $self->{name} => Validate::Tiny::filter($method);
    }

    $self->{result} = undef;	# reset previous validation
    $self;
}

sub _to_string { shift->_lookup_value; }

sub _to_fields
{
    my $self  = shift;
    my $value = $self->_lookup_value;

    my $fields = [];
    return $fields unless ref($value) eq 'ARRAY';

    my $i = -1;
    while(++$i < @$value) {
	push @$fields, $self->{c}->fields($self->_path($i), $self->{object});
    }

    $fields;
}

sub _dom_id
{
    my @name = @_;
    s/[^\w]+/-/g for @name;
    join '-', @name;
}

sub _default_label
{
    my $label = (split /\Q$SEPARATOR/, shift)[-1];
    $label =~ s/[^-a-z0-9]+/ /ig;
    ucfirst $label;
}

sub _invalid_parameter
{
    my ($field, $message) = @_;
    Carp::croak "Invalid parameter '$field': $message";
}

sub _path { "$_[0]->{name}${SEPARATOR}$_[1]" }

sub _lookup_value
{
    my $self = shift;
    return $self->{value} if defined $self->{value};

    my $name = $self->{name};
    my $object = $self->{object};
    my @path = split /\Q$SEPARATOR/, $name;

    if(!$object) {
	$object = $self->{c}->stash($path[0]);
	_invalid_parameter($name, "nothing in the stash for '$path[0]'") unless $object;
    }

    # Remove the stash key for $object
    shift @path;

    while(defined(my $accessor = shift @path)) {
	my $isa = ref($object);

	# We don't handle the case where one of these return an array
	if(Scalar::Util::blessed($object) && $object->can($accessor)) {
	    $object = $object->$accessor;
	}
	elsif($isa eq 'HASH') {
	    # If blessed and !can() do we _really_ want to look inside?
	    $object = $object->{$accessor};
	}
	elsif($isa eq 'ARRAY') {
	    _invalid_parameter($name, "non-numeric index '$accessor' used to access an ARRAY")
		unless $accessor =~ /^\d+$/;

	    $object = $object->[$accessor];
	}
	else {
	    my $type = $isa || 'type that is not a reference';
	    _invalid_parameter($name, "cannot use '$accessor' on a $type");
	}
    }

    $self->{value} = $object;
}

package Mojolicious::Plugin::FormFields::ScopedField;

use Mojo::Base -strict;
use Carp ();

our @ISA = 'Mojolicious::Plugin::FormFields::Field';

my $sep = __PACKAGE__->separator;

sub new
{
    my $class = shift;
    Carp::croak 'object name required' unless $_[1];  # 0 arg is controller instance

    my $self = $class->SUPER::new(@_);
    $self->{fields} = {};
    $self->{errors} = {};
    $self->{index} = $1 if $self->{name} =~ /\Q$sep\E(\d+)$/;

    $self;
}

sub index  { shift->{index} }

# This is the caller's view of the object, which can differ from $self->{object}.
# For example, given 'user.orders.0.id' {object} will be user and object() will be user.orders.0
sub object { shift->_lookup_value }

for my $m (qw(checkbox fields file hidden input label password radio select text textarea check filter is_equal)) {
    no strict 'refs';
    *$m = sub {
	my $self = shift;
	my $name = shift;
	Carp::croak 'field name required' unless $name;

	return $self->_fields($name) if $m eq 'fields';

	my $field = $self->_field($name);
	$self->{fields}->{$name} = 1;

	return $field->error if $m eq 'error';

	# TODO: compare things in different scopes, e.g., user.password => account.password
	return $field->$m($self->_path(shift), @_) if $m eq 'is_equal';

	$field->$m(@_);
    };
}

sub errors
{
    my ($self, $name) = @_;
    $name ? $self->_field($name)->error : $self->{errors};
}

sub valid
{
    my ($self, $name) = @_;
    return $self->_field($name)->valid if $name;

    $self->{errors} = {};

    my $valid = 1;
    for my $name (keys %{$self->{fields}}) {
	my $field = $self->_field($name);
	unless($field->valid) {
	    $valid = 0;
	    $self->{errors}->{$name} = $field->error;
	}
    }

    $valid;
}

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    my $name = shift;
    Carp::croak 'field name required' unless $name;

   (my $method = $AUTOLOAD) =~ s/[^':]+:://g;
    $self->_field($name)->$method(@_);
    # Some hacky shit going on here...
    $self->{fields}->{$name} = 1;

    $self;
}

sub _field
{
    my ($self, $name) = @_;
    $self->{c}->field($self->_path($name), $self->{object});
}

sub _fields
{
    my ($self, $name) = @_;
    $self->{c}->fields($self->_path($name), $self->{object});
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::FormFields - Lightweight form builder with validation and filtering

=head1 SYNOPSIS

  $self->plugin('FormFields');

  # In your controller
  sub edit
  {
      my $self = shift;
      my $user = $self->users->find($self->param('id'));
      $self->stash(user => $user);
  }

  sub update
  {
      my $self = shift;
      my $user = $self->params('user');

      $self->field('user.name')->is_required;
      $self->field('user.password')->is_required->is_equal('user.confirm_password');

      if($self->valid) {
	  $self->users->save($user);
	  $self->redirect_to('/profile');
	  return;
      }

      $self->stash(user => $user);
  }

  # In your view
  field('user.name')->text
  field('user.name')->error unless field('user.name')->valid

  field('user.password')->password
  field('user.age')->select([10,20,30])
  field('user.password')->password
  field('user.taste')->radio('me_gusta')
  field('user.taste')->radio('estoy_harto_de')
  field('user.orders.0.id')->hidden

  # Fields for a collection
  my $kinfolk = field('user.kinfolk');
  for my $person (@$kinfolk) {
    $person->hidden('id')
    $person->text('name')
  }

  # Or, scope it to the 'user' param
  my $user = fields('user')
  $user->hidden('id')
  $user->text('name')
  $user->error('name') unless $user->valid('name')
  $user->label('admin')
  $user->checkbox('admin')
  $user->password('password')
  $user->select('age', [ [X => 10], [Dub => 20] ])
  $user->file('avatar')
  $user->textarea('bio', size => '10x50')

  my $kinfolk = $user->fields('kinfolk')
  for my $person (@$kinfolk) {
    $person->text('name')
    # ...
  }

=head1 DESCRIPTION

C<Mojolicious::Plugin::FormFields> allows you to bind objects and data structures to form fields. It also performs validation and filtering via L<Validate::Tiny>.

=head1 CREATING FIELDS

Fields can be bound to a hash, an array, something blessed, or any combination of the three.
They are created by calling the C<< L</field> >> helper with a path to the value you want to bind,
and then calling the desired HTML input method

  field('user.name')->text

Is the same as

  text_field 'user.name', $user->name, id => 'user-name'

(though C<Mojolicious::Plugin::FormFields> sets C<type="text">).

Field names/paths are given in the form C<target.accessor1 [ .accessor2 [ .accessorN ] ]> where C<target> is an object or
data structure and C<accessor> is a method, hash key, or array index. The target must be in the stash under the key C<target>
or provided as an argument to C<< L</field> >>.

Some examples:

  field('users.0.name')->text

Is the same as

  text_field 'users.0.name', $users->[0]->name, id => 'users-0-name'

And

  field('item.orders.0.XAJ123.quantity')->text

Is equivalent to

  text_field 'item.orders.0.XAJ123.quantity', $item->orders->[0]->{XAJ123}->quantity, id => 'item-orders-0-XAJ123-quantity'

As you can see DOM IDs are always created.

Here the target key C<book> does not exist in the stash so the target is supplied

  field('book.upc', $item)->text

If a value for the flattened representation exists (e.g., from a form submission) it will be used instead of
the value pointed at by the field name (desired behavior?). This is the same as Mojolicious' Tag Helpers.

Options can also be provided

  field('user.name')->text(class => 'input-text', data => { name => 'xxx' })

See L</SUPPORTED FIELDS> for the list of HTML input creation methods.

=head2 STRUCTURED REQUEST PARAMETERS

Structured request parameters for the bound object/data structure are available via
C<Mojolicious::Controller>'s L<param method|Mojolicious::Controller#param>.
They can not be accessed via C<Mojo::Message::Request>.

A request with the parameters C<user.name=nameA&user.email=email&id=123> can be accessed in your action like

  my $user = $self->param('user');
  $user->{name};
  $user->{email};

Other parameters can be accessed as usual

  $id = $self->param('id');

The flattened parameter can also be used

  $name = $self->param('user.name');

See L<Mojolicious::Plugin::ParamExpand> for more info.

=head2 SCOPING

Fields can be scoped to a particular object/data structure via the C<< L</fields> >> helper

  my $user = fields('user');
  $user->text('name');
  $user->hidden('id');

When using C<fields> you must supply the field's name to the HTML input and validation methods, otherwise
the calls are the same as they are with C<field>.

=head2 COLLECTIONS

You can also create fields scoped to elements in a collection

  my $addresses = field('user.addresses');
  for my $addr (@$addresses) {
    # field('user.addresses.N.id')->hidden
    $addr->hidden('id');

    # field('user.addresses.N.street')->text
    $addr->text('street');

    # field('user.addresses.N.city')->select([qw|OAK PHL LAX|])
    $addr->select('city', [qw|OAK PHL LAX|]);
  }

Or, for fields that are already scoped

  my $user = fields('user')
  $user->hidden('id');

  my $addressess = $user->fields('addresses');
  for my $addr (@$addresses) {
    $addr->hidden('id')
    # ...
  }

You can also access the underlying object and its position within a collection
via the C<object> and C<index> methods.

  <% for my $addr (@$addresses) {  %>
    <div id="<%= dom_id($addr->object) %>">
      <h3>Address #<%= $addr->index + 1 %></h3>
      <%= $addr->hidden('id') %>
      ...
    </div>
  <% } %>

=head1 VALIDATING & FILTERING

Validation rules are created by calling validation and/or filter methods
on the field to be validated

  # In your controller
  my $self = shift;
  $self->field('user.name')->is_required;
  $self->field('user.name')->filter('trim');

These methods can be chained

  $self->field('user.name')->is_required->filter('trim');

To perform validation on a field call its C<valid> method

  $field = $self->field('user.name');
  $field->is_required;
  $field->valid;
  $field->error;

This will only validate and return the error for the C<user.name> field. To validate all fields and retrieve all error messages call the controller's C<valid> and C<errors> methods

  $self->field('user.name')->is_required;
  $self->field('user.age')->is_like(qr/^\d+$/);
  $self->valid;

  my $errors = $self->errors;
  $errors->{'user.name'}
  # ...

Of course the C<error>/C<errors> and C<valid> methods can be used in your view too

  <% unless(valid()) { %>
    <p>Hey, fix the below errors</p>
  <% } %>

  <%= field('name')->text %>
  <% unless(field('name')->valid) { %>
    <span class="error"><%= field('name')->error %></span>
  <% } %>

When creating validation rules for L</fields> you must pass the field name as the first argument

  my $user = fields('user');
  $user->is_required('password');
  $user->is_equal(password => 'confirm_password');
  $user->is_long_at_least(password => 8, 'Mais longo caipira');

=head2 AVAILABLE RULES & FILTERS

C<Mojolicious::Plugin::FormFields> uses C<Validate::Tiny>, see L<its docs|Validate::Tiny/filter> for a list.

=head2 RENAMING THE VALIDATION METHODS

In the event that the C<valid> and/or C<errors> methods clash with exiting methods/helpers
in your app you can rename them by specifying alternate names when loading the plugin

  $self->plugin('FormFields', methods => { valid => 'form_valid', errors => 'form_errors' });
  # ...

  $self->field('user.name')->is_required;
  $self->form_valid;
  $self->form_errors;

Note that this I<only> changes the methods B<on the controller> and does not change the methods on the object returned by C<field>.

=head1 METHODS

=head2 field

  field($name)->text
  field($name, $object)->text

=head3 Arguments

C<$name>

The field's name, which can also be the path to its value in the stash. See L</CREATING FIELDS>.

C<$object>

Optional. The object used to retrieve the value specified by C<$name>. Must be a reference to a
hash, an array, or something blessed. If not given the value will be retrieved from
the stash or, for previously submitted forms, the request parameter C<$name>.

=head3 Returns

An object than can be used to create HTML form fields, see L</SUPPORTED FIELDS>.

=head3 Errors

An error will be raised if:

=over 4

=item * C<$name> is not provided

=item * C<$name> cannot be retrieved from C<$object>

=item * C<$object> cannot be found in the stash and no default was given

=back

=head3 Collections

See L</COLLECTIONS>

=head2 fields

  $f = fields($name)
  $f->text('address')

  $f = fields($name, $object)
  $f->text('address')

Create form fields scoped to a parameter.

For example

  % $f = fields('user')
  %= $f->select('age', [10,20,30])
  %= $f->textarea('bio')

Is the same as

  %= field('user.age')->select([10,20,30])
  %= field('user.bio')->textarea

=head3 Arguments

Same as L</field>.

=head3 Returns

An object than can be used to create HTML form fields scoped to the C<$name> argument, see L</SUPPORTED FIELDS>.

=head3 Errors

Same as L</field>.

=head3 Collections

See L</COLLECTIONS>

=head1 SUPPORTED FIELDS

=head2 checkbox

  field('user.admin')->checkbox(%options)
  field('user.admin')->checkbox('yes', %options)

Creates

  <input type="checkbox" name="user.admin" id="user-admin-1" value="1"/>
  <input type="checkbox" name="user.admin" id="user-admin-yes" value="yes"/>

=head2 file

  field('user.avatar')->file(%options);

Creates

  <input id="user-avatar" name="user.avatar" type="file" />

=head2 hidden

  field('user.id')->hidden(%options)

Creates

  <input id="user-id" name="user.id" type="hidden" value="123123" />

=head2 input

  field('user.phone')->input($type, %options)

For example

  field('user.phone')->input('tel', pattern => '\d{3}-\d{4}')

Creates

  <input id="user-phone" name="user.phone" type="tel" pattern="\d{3}-\d{4}" />

=head2 label

  field('user.name')->label
  field('user.name')->label('Nombre', for => "tu_nombre_hyna")

Creates

  <label for="user-name">Name</label>
  <label for="tu_nombre_hyna">Nombre</label>

=head2 password

  field('user.password')->password(%options)

Creates

  <input id="user-password" name="user.password" type="password" />

=head2 select

  field('user.age')->select([10,20,30], %options)
  field('user.age')->select([[Ten => 10], [Dub => 20], [Trenta => 30]], %options)

Creates

  <select id="user-age" name="user.age">
    <option value="10">10</option>
    <option value="20">20</option>
    <option value="30">30</option>
  </select>

  <select id="user-age" name="user.age">
    <option value="10">Ten</option>
    <option value="20">Dub</option>
    <option value="30">Trenta</option>
  </select>

=head2 radio

  field('user.age')->radio('older_than_21', %options)

Creates

  <input id="user-age-older_than_21" name="user.age" type="radio" value="older_than_21" />

=head2 text

  field('user.name')->text(%options)
  field('user.name')->text(size => 10, maxlength => 32)

Creates

  <input id="user-name" name="user.name" value="sshaw" />
  <input id="user-name" name="user.name" value="sshaw" size="10" maxlength="32" />

=head2 textarea

  field('user.bio')->textarea(%options)
  field('user.bio')->textarea(size => '10x50')

Creates

  <textarea id="user-bio" name="user.bio">Proprietary and confidential</textarea>
  <textarea cols="50" id="user-bio" name="user.bio" rows="10">Proprietary and confidential</textarea>

=head1 AUTHOR

Skye Shaw (sshaw [AT] gmail.com)

=head1 SEE ALSO

L<Mojolicious::Plugin::TagHelpers>, L<Mojolicious::Plugin::ParamExpand>, L<Validate::Tiny>, L<Mojolicious::Plugin::DomIdHelper>

=head1 COPYRIGHT

Copyright (c) 2012-2014 Skye Shaw.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

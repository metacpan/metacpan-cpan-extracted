package Mojo::DOM::Role::Form;

use Mojo::Base -role;

requires qw{ancestors at attr find matches selector tag val};

sub target {
  my ($self, $submit) = (shift, shift);
  return () if ($self->tag // '') ne 'form';
  return ()
    unless defined($submit = $self->at($submit || _form_default_submit($self)));
  return () if $submit->matches('[disabled]');
  my $method = uc($submit->attr('formmethod') || $self->attr('method') || 'GET');
  my $action = $submit->attr('formaction') || $self->attr('action') || '#';
  my $enctyp = $submit->attr('formenctype') || $self->attr('enctype') ||
    'url-encoded';
  return $method, $action, $enctyp;
}

around val => sub {
  my ($orig, $self, @args) = @_;
  # "form"
  return
    $self->find('button, checkbox, input, radio, select, textarea')
      ->map(sub {
        my $is_image = !!$_->matches('input[type=image]');
        # ignore disabled nodes
        return () if _form_element_disabled($_);
        # ignore those without name, unless image type
        return () if !defined(my $name = $_->attr("name")) && !$is_image;
        # only continue if the clickable element matches (synthesize click)
        return () if _form_element_submits($_) && !$_->matches($_[1]);
        # client only buttons ignored
        return () if _form_element_client_only_button($_);
        # simply return name => value for all but image types
        return [$name => $_->val()] unless $is_image;
        # synthesize image click
        return _form_image_click($_, $name);
      }, $args[0] || _form_default_submit($self))
      ->reduce(sub {
        my ($key, $value) = @$b;
        $a->{$key} = defined $a->{$key} && defined($value)
          ? [ ref($a->{$key}) ? (@{$a->{$key}}, $value) : ($a->{$key}, $value) ]
          : $value;
        $a
      }, {})
  if (my $tag = $self->tag) eq 'form';

  # "option"
  return $self->{value} // $self->text if $tag eq 'option';

  # "input" ("type=checkbox" and "type=radio")
  my $type = $self->{type} // '';
  return $self->{value} // 'on'
    if $tag eq 'input' && ($type eq 'radio' || $type eq 'checkbox');

  # "textarea", "input" or "button". Give input[type=submit] default value
  return (
    $tag eq 'textarea'
    ? $self->text
    : ($self->matches('input[type=submit]')
      ? $self->{value} || 'Submit'
      : $self->{value})) if $tag ne 'select';

  # "select"
  my $v = $self->find('option:checked:not([disabled])')
    ->grep(sub { !$_->ancestors('optgroup[disabled]')->size })->map('val');
  return exists $self->{multiple} ? $v->size ? $v->to_array : undef : $v->last;
};

#
# internal
#

sub _form_default_submit {
  # filter for those submittable nodes
  return shift->find('*')->grep(sub { !!$_->_form_element_submits; })
    # only the first continues, save some cycles
    ->tap(sub { splice @$_, 1; })
    ->map(sub {
      # $_->selector;
      # get the selector and relativise to form
      (my $s = $_->selector) =~ s/^.*form[^>]*>\s//;
      return $s;
    })->first || '';
}

sub _form_element_client_only_button {
  my $s = 'input[type=button], button:matches([type=button], [type=reset])';
  return !!$_[0]->matches($s);
}

sub _form_element_disabled {
  return 1 if $_[0]->matches('[disabled]');
  return 1 if $_[0]->ancestors('fieldset[disabled]')->size &&
    !$_[0]->ancestors('fieldset legend:first-child')->size;
  return 0;
}

sub _form_element_submits {
  my $s = join ', ', 'button:not([type=button], [type=reset])',
    'button', # submit is the default
    'input:matches([type=submit], [type=image])';
  return 1 if $_[0]->matches($s) && !_form_element_disabled($_[0]);
  return 0;
}

sub _form_image_click {
  my ($self, $name) = (shift, shift);
  my ($x, $y) = map { int(rand($self->attr($_) || 1)) + 1 } qw{width height};
  # x and y if no name
  return ([x => $x], [y => $y]) unless $name;
  # named x and y, with name
  return (["$name.x" => $x], ["$name.y" => $y]);
}

1;

=encoding utf8

=head1 NAME

Mojo::DOM::Role::Form - Form data extraction

=head1 SYNOPSIS

  # description
  my $obj = Mojo::DOM::Role::Form->new();
  $obj->target('#submit-id');

=head1 DESCRIPTION

L<Role::Tiny> based role to compose additional form data extraction methods into
L<Mojo::DOM>.

=head1 METHODS

L<Mojo::DOM::Role::Form> implements the following methods.

=head2 target

  # result
  $obj->target 

Explain what the L</"target"> does.

=head1 AUTHOR

=cut

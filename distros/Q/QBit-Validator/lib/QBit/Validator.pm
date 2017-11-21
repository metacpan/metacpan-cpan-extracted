package QBit::Validator;
$QBit::Validator::VERSION = '0.011';
use qbit;

use base qw(QBit::Class);

use Exception::Validator;

__PACKAGE__->mk_ro_accessors(qw(data app));

__PACKAGE__->mk_accessors(qw(template));

my %available_fields = map {$_ => TRUE} qw(data template app throw pre_run);

sub init {
    my ($self) = @_;

    foreach (qw(data template)) {
        throw Exception::Validator gettext('Expected "%s"', $_) unless exists($self->{$_});
    }

    my @bad_fields = grep {!$available_fields{$_}} keys(%{$self});
    throw Exception::Validator gettext('Unknown options: %s', join(', ', @bad_fields))
      if @bad_fields;

    if (exists($self->{'pre_run'})) {
        throw Exception::Validator gettext('Option "pre_run" must be code')
          if !defined($self->{'pre_run'}) || ref($self->{'pre_run'}) ne 'CODE';

        $self->{'pre_run'}($self);
    }

    $self->{'__CHECK_FIELDS__'} = {};

    my $data     = $self->data;
    my $template = $self->template;

    $self->_validation($data, $template);

    $self->throw_exception() if $self->has_errors && $self->{'throw'};
}

sub _validation {
    my ($self, $data, $template, $no_check_options, @path_field) = @_;

    throw Exception::Validator gettext('Key "template" must be HASH')
      if !defined($template) || ref($template) ne 'HASH';

    $template->{'type'} //= ['scalar'];

    $template->{'type'} = [$template->{'type'}] unless ref($template->{'type'}) eq 'ARRAY';

    my $already_check;
    foreach my $type_name (@{$template->{'type'}}) {
        my $type = $self->_get_type_by_name($type_name);

        if ($type->can('get_template')) {
            my $new_template = $type->merge_templates($template, $type->get_template());

            $self->_validation($data, $new_template, TRUE, @path_field);
        }

        last unless $type->check_options($self, $data, $template, \$already_check, @path_field);
    }

    unless ($no_check_options) {
        my $all_options = $self->_get_all_options_by_types($template->{'type'});

        my $diff = arrays_difference([keys(%$template)], $all_options);

        throw Exception::Validator gettext('Unknown options: %s', join(', ', @$diff)) if @$diff;
    }
}

sub _get_type_by_name {
    my ($self, $type_name) = @_;

    unless (exists($self->{'__TYPES__'}{$type_name})) {
        my $type_class = 'QBit::Validator::Type::' . $type_name;
        my $type_fn    = "$type_class.pm";
        $type_fn =~ s/::/\//g;

        try {
            require $type_fn;
        }
        catch {
            throw Exception::Validator gettext('Unknown type "%s"', $type_name);
        };

        $self->{'__TYPES__'}{$type_name} = $type_class->new();
    }

    return $self->{'__TYPES__'}{$type_name};
}

sub super_check {
    my ($self, $type_name, @params) = @_;

    my %types = map {$_ => TRUE} $self->_get_all_types($params[2]->{'type'});

    throw Exception::Validator gettext('You can not use sub "check" of type "%s" for this template', $type_name)
      unless $types{$type_name};

    my $type = $self->_get_type_by_name($type_name);

    throw Exception::Validator gettext('Do not exists sub "check" for type "%s"', $type_name)
      unless $type->can('get_template');

    my $type_template = $type->get_template();

    throw Exception::Validator gettext('Do not exists sub "check" for type "%s"', $type_name)
      unless exists($type_template->{'check'});

    throw Exception::Validator gettext('Option "check" must be code')
      if !defined($type_template->{'check'}) || ref($type_template->{'check'}) ne 'CODE';

    $type_template->{'check'}(@params);
}

sub _get_all_types {
    my ($self, $types) = @_;

    $types //= ['scalar'];
    $types = [$types] unless ref($types) eq 'ARRAY';

    my %uniq_types = map {$_ => TRUE} @$types;

    foreach my $type_name (@$types) {
        my $type = $self->_get_type_by_name($type_name);

        if ($type->can('get_template')) {
            my $type_template = $type->get_template();

            $uniq_types{$_} = TRUE foreach $self->_get_all_types($type_template->{'type'});
        }
    }

    return sort(keys(%uniq_types));
}

sub _get_all_options_by_types {
    my ($self, $types) = @_;

    my @types_name = $self->_get_all_types($types);

    my %uniq_options = ();

    foreach my $type_name (@types_name) {
        my $type = $self->_get_type_by_name($type_name);

        $uniq_options{$_} = TRUE foreach $type->get_all_options_name();
    }

    return [keys(%uniq_options)];
}

sub throw_exception {
    my ($self) = @_;

    throw Exception::Validator $self->get_all_errors;
}

sub _add_error {
    my ($self, $template, $error, $field, %opts) = @_;

    my $key = $self->_get_key($field);

    if ($opts{'check_error'}) {
        $self->{'__CHECK_FIELDS__'}{$key}{'error'} = {
            msgs => [$error],
            path => $field // []
        };
    } elsif ($self->has_error($field)) {
        push(@{$self->{'__CHECK_FIELDS__'}{$key}{'error'}{'msgs'}}, $error)
          unless exists($template->{'msg'});
    } else {
        $self->{'__CHECK_FIELDS__'}{$key}{'error'} = {
            msgs => [exists($template->{'msg'}) ? $template->{'msg'} : $error],
            path => $field // []
        };
    }

    delete($self->{'__CHECK_FIELDS__'}{$key}{'ok'}) if exists($self->{'__CHECK_FIELDS__'}{$key}{'ok'});
}

sub get_all_errors {
    my ($self) = @_;

    my $error = '';

    $error .= join("\n", map {@{$_->{'msgs'}}} $self->get_fields_with_error());

    return $error;
}

sub get_error {
    my ($self, $field) = @_;

    my $key = $self->_get_key($field);

    my $error = '';
    foreach ($self->get_fields_with_error()) {
        $error = join("\n", @{$_->{'msgs'}}) if $key eq $self->_get_key($_->{'path'});
    }

    return $error;
}

sub get_fields_with_error {
    my ($self) = @_;

    return map {$self->{'__CHECK_FIELDS__'}{$_}{'error'}}
      grep     {$self->{'__CHECK_FIELDS__'}{$_}{'error'}} sort keys(%{$self->{'__CHECK_FIELDS__'}});
}

sub _add_ok {
    my ($self, $field) = @_;

    return if $self->checked($field) && $self->has_error($field);

    $self->{'__CHECK_FIELDS__'}{$self->_get_key($field)}{'ok'} = TRUE;
}

sub checked {
    my ($self, $field) = @_;

    return exists($self->{'__CHECK_FIELDS__'}{$self->_get_key($field)});
}

sub has_error {
    my ($self, $field) = @_;

    return exists($self->{'__CHECK_FIELDS__'}{$self->_get_key($field)}{'error'});
}

sub has_errors {
    my ($self) = @_;

    return !!$self->get_fields_with_error();
}

sub _get_key {
    my ($self, $path_field) = @_;

    $path_field //= [];

    $path_field = [$path_field] unless ref($path_field) eq 'ARRAY';

    return join(' => ', @$path_field);
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Validator - It is used for validation of input parameters.

=head1 GitHub

https://github.com/QBitFramework/QBit-Validator

=head1 Install

=over

=item *

cpanm QBit::Validator

=item *

apt-get install libqbit-validator-perl (http://perlhub.ru/)

=back

=head1 Package methods

=head2 new

create object QBit::Validator and check data using template

B<Arguments:>

=over

=item

B<data> - checking data

=item

B<template> - template for check

=item

B<pre_run> - function is executed before checking

=item

B<app> - model using in check

=item

B<throw> - throw (boolean type, throw exception if an error has occurred)

=back

B<Example:>

  my $data = {
      hello => 'hi, qbit-validator'
  };

  my $qv = QBit::Validator->new(
      data => $data,
      template => {
          type => 'hash',
          fields => {
              hello => {
                  max_len => 5,
              },
          },
      },
  );

=head2 template

get or set template

B<Example:>

  my $template = $qv->template;

  $qv->template($template);

=head2 has_errors

return boolean result (TRUE if an error has occurred or FALSE)

B<Example:>

  if ($qv->has_errors) {
      ...
  }

=head2 data

return data

B<Example:>

  $self->db->table->edit($qv->data) unless $qv->has_errors;

=head2 get_wrong_fields

return list name of fields with error

B<Example:>

  if ($qv->has_errors) {
      my @fields = $qv->get_wrong_fields;

      ldump(\@fields); # ['hello']
      # [''] - error in root
  }

=head2 get_fields_with_error

return list fields with error

B<Example:>

  if ($qv->has_errors) {
      my @fields = $qv->get_fields_with_error;

      ldump(\@fields);

      # [
      #     {
      #         msgs => ['Error'],
      #         path => ['hello']
      #     }
      # ]
      #
      # path => [''] - error in root
  }

=head2 get_error

return error by path

B<Example:>

  if ($qv->has_errors) {
      my $error = $qv->get_error('hello'); # or ['hello']

      print $error; # 'Error'
  }

=head2 get_all_errors

return all errors join "\n"

B<Example:>

  if ($qv->has_errors) {
      my $errors = $qv->get_all_errors();

      print $errors; # 'Error'
  }

=head2 throw_exception

throw Exception::Validator with error message from get_all_errors

B<Example:>

  $qv->throw_exception if $qv->has_errors;

=head1 Default types

=head2 scalar (string/number)

=over

=item

optional

=item

eq

=item

regexp

=item

min

=item

max

=item

len_min

=item

len

=item

len_max

=item

in

=back

For more information see tests

=head2 array (ref array)

=over

=item

optional

=item

size_min

=item

size

=item

size_max

=item

all

=item

contents

=back

For more information see tests

=head2 hash (ref hash)

=over

=item

optional

=item

deps

=item

fields

=item

extra

=item

one_of

=item

any_of

=back

For more information see tests

=cut

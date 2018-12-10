package QBit::Validator;
$QBit::Validator::VERSION = '0.012';
use qbit;

use base qw(QBit::Class);

use Exception::Validator;

__PACKAGE__->mk_ro_accessors(qw(app parent path));

__PACKAGE__->mk_accessors(qw(template));

my %AVAILABLE_FIELDS = map {$_ => TRUE} qw(data template app throw pre_run path path_manager parent sys_errors_handler);

our $PATH_MANAGER = 'QBit::Validator::PathManager';
our $SYS_ERRORS_HANDLER = sub { };

sub init {
    my ($self) = @_;

    foreach (qw(template)) {
        throw Exception::Validator gettext('Expected "%s"', $_) unless exists($self->{$_});
    }

    throw Exception::Validator gettext('Option "parent" must be QBit::Validator')
      if defined($self->parent) && (!blessed($self->parent) || !$self->parent->isa('QBit::Validator'));

    my @bad_fields = grep {!$AVAILABLE_FIELDS{$_}} keys(%{$self});
    throw Exception::Validator gettext('Unknown options: %s', join(', ', @bad_fields))
      if @bad_fields;

    if (exists($self->{'pre_run'})) {
        throw Exception::Validator gettext('Option "pre_run" must be code')
          if !defined($self->{'pre_run'}) || ref($self->{'pre_run'}) ne 'CODE';

        $self->{'pre_run'}($self);
    }

    local $SYS_ERRORS_HANDLER = $self->{'sys_errors_handler'} if exists($self->{'sys_errors_handler'});

    $self->_init_template();

    $self->validate($self->data) if exists($self->{'data'});

    $self->throw_exception() if $self->has_errors && $self->{'throw'};
}

sub use_errors_handler {
    my ($self, $error) = @_;

    $SYS_ERRORS_HANDLER->($error);
}

sub _init_template {
    my ($self) = @_;

    $self->{'__CHECKS__'} = [];

    my $template = $self->template;

    throw Exception::Validator gettext('Key "%s" must be HASH', 'template')
      if !defined($template) || ref($template) ne 'HASH';

    my ($type_obj, $final_template) = $self->_get_type_and_template($template);

    push(@{$self->{'__CHECKS__'}}, $type_obj->get_checks_by_template($self, $final_template, []));
}

sub data {
    my ($self, @params) = @_;

    if (@params) {
        $self->{'data'} = $params[0];
    }

    my $parent = $self->parent // $self;

    return $parent->{'data'};
}

sub _get_type_and_template {
    my ($self, $template) = @_;

    my $exists_check = exists($template->{'check'});
    my $check        = delete($template->{'check'});

    throw Exception::Validator gettext('Option "%s" must be defined', 'check')
      if $exists_check && !defined($check);

    my $type = delete($template->{'type'}) // 'scalar';

    my $type_obj = $self->_get_type_by_name($type);

    if ($type_obj->can('get_template')) {
        my $base_template = $type_obj->get_template();

        if (exists($base_template->{'check'}) && ref($base_template->{'check'}) ne 'ARRAY') {
            $base_template->{'check'} = [$base_template->{'check'}];
        }

        $template = {%$base_template, %$template};

        push(@{$template->{'check'}}, ref($check) eq 'ARRAY' ? @$check : $check) if defined($check);

        return $self->_get_type_and_template($template);
    } else {
        $template->{'type'} = $type;

        push(@{$template->{'check'}}, ref($check) eq 'ARRAY' ? @$check : $check) if defined($check);

        return ($type_obj, $template);
    }
}

sub validate {
    my ($self, $data) = @_;

    $self->data($data);

    return $self->_validate($data);
}

sub _validate {
    my ($self, $data) = @_;

    delete($self->{'__ERRORS__'});

    my @checks = @{$self->{'__CHECKS__'}};

    my $res = TRUE;
    try {
        foreach my $check (@checks) {
            last unless $check->($self, $data);
        }
    }
    catch {
        my ($exception) = @_;

        my $error;
        if ($exception->{'check_error'} || !$self->{'__CUSTOM_ERRORS__'}) {
            $error = $exception->message;
        } else {
            $error = $self->{'__CUSTOM_ERRORS__'};
        }

        $self->{'__ERRORS__'} = $error;

        $res = FALSE;
    };

    return $res;
}

sub get_errors {$_[0]->{'__ERRORS__'}}

sub _get_type_by_name {
    my ($self, $type_name) = @_;

    my $package_stash = package_stash(ref($self));

    unless (exists($package_stash->{'__TYPES__'}{$type_name})) {
        my $type_class = 'QBit::Validator::Type::' . $type_name;
        require_class($type_class);

        $package_stash->{'__TYPES__'}{$type_name} = $type_class->new();
    }

    return $package_stash->{'__TYPES__'}{$type_name};
}

sub throw_exception {
    my ($self) = @_;

    throw Exception::Validator $self->get_all_errors;
}

sub get_all_errors {
    my ($self) = @_;

    my $error = '';

    $error .= join("\n", map {$_->{'message'}} $self->get_fields_with_error());

    return $error;
}

sub get_error {
    my $error = $_[0]->path_manager->get_data_by_path($_[1] // $_[0]->path_manager->root, $_[0]->get_errors);

    return ref($error) eq '' ? $error : undef;
}

sub get_fields_with_error {
    my ($self) = @_;

    my $errors = $self->get_errors;

    if (defined($errors)) {
        my $path_manager = $self->path_manager;

        return _get_nodes($path_manager, $path_manager->root, $errors);
    } else {
        return ();
    }
}

sub _get_nodes {
    my ($path_manager, $root_path, $data) = @_;

    if (ref($data) eq 'HASH') {
        return map {
            _get_nodes($path_manager,
                $path_manager->concatenate($root_path, $path_manager->delimiter, $path_manager->hash_path($_)),
                $data->{$_})
          }
          sort keys(%$data);
    } elsif (ref($data) eq 'ARRAY') {
        my $i      = 0;
        my @result = ();
        while ($i < @$data) {
            if (defined($data->[$i])) {
                push(
                    @result,
                    _get_nodes(
                        $path_manager,
                        $path_manager->concatenate($root_path, $path_manager->delimiter, $path_manager->array_path($i)),
                        $data->[$i]
                    )
                );
            }

            $i++;
        }

        return @result;
    } else {
        return {path => $root_path, message => $data};
    }
}

sub has_error {defined($_[0]->get_error($_[1]))}

sub has_errors {
    return defined($_[0]->get_errors);
}

sub path_manager {
    my ($self) = @_;

    unless ($self->{'path_manager'}) {
        require_class($PATH_MANAGER);

        $self->{'path_manager'} = $PATH_MANAGER->new();
    }

    return $self->{'path_manager'};
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

B<pre_run> - function is executed before checking (deprecated)

=item

B<app> - model using in check

=item

B<throw> - throw (boolean type, throw exception if an error has occurred)

=item

B<sys_errors_handler> - handler for system errors in sub "check" (default empty function: sub {})

  # global set handler
  $QBit::Validator::SYS_ERRORS_HANDLER = sub {log($_[0])}; # first argument is error

  #or local set handler
  my $qv = QBit::Validator->new(template => {}, sys_errors_handler => sub {log($_[0])});

=item

B<path_manager> - path manager (default QBit::Validator::PathManager)

  # global set path_manager
  $QBit::Validator::PATH_MANAGER = 'MyPathManager::For::Data::DPath';

  #or local set path_manager
  my $qv = QBit::Validator->new(template => {}, path_manager => MyPathManager::For::Data::DPath->new()});

=item

B<path> - data path for validator (see: QBit::Validator::PathManager)

=item

B<parent> - ref to a parent validator

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

get or set template (Use only into pre_run)

B<Example:>

  my $template = $qv->template;

  $qv->template($template);

=head2 data

set or get data

B<Example:>

  $self->db->table->edit($qv->data) unless $qv->has_errors;

=head2 validate

set data and validate it

B<Example:>

  my $qv = QBit::Validator->new(
    template => {
        type => 'scalar',
        min  => 50,
        max  => 60,
    }
  );

  foreach (45 .. 65) {
      $qv->validate($_);

      print $qv->get_error() if $qv->has_errors;
  }

=head2 has_errors

return boolean result (TRUE if an error has occurred or FALSE)

B<Example:>

  if ($qv->has_errors) {
      ...
  }

=head2 has_error

return boolean result (TRUE if an error has occurred in field or FALSE)

B<Example:>

  $qv->get_error('field') if $qv->has_error('field');
  $qv->get_error('/field') if $qv->has_error('/field');

=head2 get_error

return error by path (string or array)

B<Example:>

  if ($qv->has_errors) {
      my $error = $qv->get_error('hello');
      #or '/hello'

      print $error; # 'Error'
  }

=head2 get_fields_with_error

return list fields with error

B<Example:>

  if ($qv->has_errors) {
      my @fields = $qv->get_fields_with_error;

      ldump(\@fields);

      # [
      #     {
      #         messsage => 'Error',
      #         path     => '/hello/'
      #     }
      # ]
      #
      # path => '/' - error in root
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

=head2 variable

=over

=item

conditions

=back

For more information see tests

=cut

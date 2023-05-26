package SyForm;
BEGIN {
  $SyForm::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Easy form management
$SyForm::VERSION = '0.103';
use Moo;
use Tie::IxHash;
use Module::Runtime qw( use_module );
use SyForm::Exception;

with($_) for (qw(
  MooX::Traits
  SyForm::Role::Process
  SyForm::Role::Label
));

#######################
#
# Class Default Config
#
#######################

has name => (
  is => 'ro',
  predicate => 1,
);

has fields_list => (
  is => 'ro',
  init_arg => 'fields',
  required => 1,
);

has fields => (
  is => 'lazy',
  init_arg => undef,
);
sub field { shift->fields->FETCH(@_) }

sub _build_fields {
  my ( $self ) = @_;
  my $fields = Tie::IxHash->new;
  eval {
    my $fields_list = Tie::IxHash->new(@{$self->fields_list});
    for my $name ($fields_list->Keys) {
      my %field_args = %{$fields_list->FETCH($name)};
      $fields->Push($name, $self->new_field($name, %field_args));
    }
  };
  SyForm->throw( UnknownErrorOnBuildFields => $self, $@ ) if $@;
  return $fields;
}

has field_names => (
  is => 'lazy',
);

sub _build_field_names {
  my ( $self ) = @_;
  return [map { $_->name } $self->fields->Values];
}

has field_class => (
  is => 'lazy',
);

sub _build_field_class { return 'SyForm::Field' }

has loaded_field_class => (
  is => 'lazy',
);

sub _build_loaded_field_class {
  my ( $self ) = @_;
  return use_module($self->field_class);
}

sub new_field {
  my ( $self, $name, %field_args ) = @_;
  my $field;
  my $class = delete $field_args{class} || $self->loaded_field_class;
  return $class->new(
    syform => $self,
    name => $name,
    %field_args,
  );
}

sub throw {
  my ( $class, $exception, @args ) = @_;
  SyForm::Exception->throw($exception) if scalar(@args) == 0;
  use_module('SyForm::Exception::'.$exception)->throw_with_args(@args);
}

1;

__END__

=pod

=head1 NAME

SyForm - Easy form management

=head1 VERSION

version 0.103

=head1 SYNOPSIS

  use SyForm;

  my $form = SyForm->new( fields => [
    'username' => {
      required => 1,
      label => 'Your name',
      html => 'text',
    },
    'age' => {
      decimal => 1,
      label => 'Your age',
      html => 'text',
    },
    'unchecked' => {
      label => 'Unchecked',
      html => 'textarea',
    },
  ]);

  my $view = $form->process( username => 'YoCoolCopKiller', age => 13 );

  # or ...
  # $values = $form->process_values(%args);
  # my $value = $values->value;
  # !$values->can('success'); # values are only the input
  # $results = $form->process_results(%args);
  # my $result = $results->get_result('username');
  # my $value = $results->values->get_value('username');
  # my $success = $result->success # result is after check

  for my $field_name (@{$view->field_names}) {
    my $input_value = $view->field($field_name)->value;
    if ($view->success) {
      my $verified_result = $view->field($field_name)->result;  
    } else {
      # result is filled for all valid fields, even on invalid form
      my $verified_result_if_exist = $view->field($field_name)->result;
    }
    # for access to the main SyForm::Field of the view field
    my $syform_field = $view->field($field_name)->field;
  }

  $view->html_render; # get HTML

=head1 DESCRIPTION

B<Deprecated> Please do not use!

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package SyForm::Role::Process;
BEGIN {
  $SyForm::Role::Process::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: SyForm role for processing
$SyForm::Role::Process::VERSION = '0.103';
use Moo::Role;
use Module::Runtime qw( use_module );

with qw(
  SyForm::Role::Verify
  SyForm::Role::HTML
  SyForm::Role::Bootstrap
);

##########
#
# Process
#
##########

sub process {
  my ( $self, @args ) = @_;
  my $view;
  eval { $view = $self->process_view(@args) };
  SyForm->throw( UnknownErrorOnProcess => $self,[@args], $@ || '$view is undefined' ) if $@ || !defined $view;
  return $view;
}

#################
#
# Process Values
#
#################

has values_class => (
  is => 'lazy',
);

sub _build_values_class { return 'SyForm::Values' }

has loaded_values_class => (
  is => 'lazy',
);

sub _build_loaded_values_class {
  my ( $self ) = @_;
  return use_module($self->values_class);
}

sub process_values {
  my ( $self, @args ) = @_;
  return $self->create_values_by_args(@args);
}

sub create_values_by_args {
  my ( $self, @args ) = @_;
  my %args_hash;
  my $args_count = scalar @args;
  if ($args_count == 1) {
    if (ref $args[0] eq 'HASH') {
      %args_hash = %{$args[0]};
    } else {
      SyForm->throw( UnknownArgOnCreateValuesByArgs => $self,$args[0] );
    }
  } elsif ($args_count % 2 == 0) {
    %args_hash = ( @args );
  } else {
    SyForm->throw( OddNumberOfArgsOnCreateValuesByArgs => $self,[@args] );
  }
  my $values;
  eval {
    my %values_args;
    for my $field ($self->fields->Values) {
      my %field_values_args = $field->values_args_by_process_args(%args_hash);
      $values_args{$_} = $field_values_args{$_} for keys %field_values_args;
    }
    $values = $self->create_values(%values_args);
  };
  SyForm->throw( UnknownErrorOnCreateValuesByArgs => $self,[@args], $@ ) if $@;
  return $values;
}

sub create_values {
  my ( $self, %args ) = @_;
  my %values;
  for my $field ($self->fields->Values) {
    my $name = $field->name;
    $values{$name} = delete $args{$name} if exists $args{$name};
  }
  return $self->loaded_values_class->new({
    syform => $self,
    values => { %values },
    %args,
  });
}

##########
#
# Results
#
##########

has results_class => (
  is => 'lazy',
);

sub _build_results_class {
  my ( $self ) = @_;
  return 'SyForm::Results';
}

has loaded_results_class => (
  is => 'lazy',
);

sub _build_loaded_results_class {
  my ( $self ) = @_;
  return use_module($self->results_class);
}

sub process_results {
  my ( $self, @args ) = @_;
  my $values = $self->process_values(@args);
  return $values->results;
}

#######
#
# View
#
#######

has view_class => (
  is => 'lazy',
);

sub _build_view_class { return 'SyForm::View' }

has loaded_view_class => (
  is => 'lazy',
);

sub _build_loaded_view_class {
  my ( $self ) = @_;
  return use_module($self->view_class);
}

sub process_view {
  my ( $self, @args ) = @_;
  my $results = $self->process_results(@args);
  return $results->view;
}

1;

__END__

=pod

=head1 NAME

SyForm::Role::Process - SyForm role for processing

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques;

use Reaction::Role;

use namespace::clean -except => [ qw(meta) ];


# requires qw(target_model
#            parameter_hashref
#            parameter_attributes
#           );

has _unique_constraint_results =>
  (
   isa => 'HashRef',
   is => 'rw',
   required => 1,
   default => sub { {} },
   metaclass => 'Reaction::Meta::Attribute'
  );
sub check_all_uniques {
  my ($self) = @_;
  my $source = $self->target_model->result_source;
  my %uniques = $source->unique_constraints;
  my $proto = ($self->target_model->isa('DBIx::Class::ResultSet')
                 ? $self->target_model->new_result({})
                 : $self->target_model);
  my $param_hr = $self->parameter_hashref;
  my %proto_hash = (
    map {
      my @ret;
      my $attr = $proto->meta->get_attribute($_->name);
      if ($attr) {
        my $reader = $attr->get_read_method;
        if ($reader) {
          my $value = $proto->$reader;
          if (defined($value)) {
            @ret = ($_->name => $value);
          }
        }
      }
      @ret;
    } $self->parameter_attributes
  );
  my %merged = (
    %proto_hash,
    (map {
      (defined $param_hr->{$_} ? ($_ => $param_hr->{$_}) : ());
    } keys %$param_hr),
  );
  my %ident = %{$proto->ident_condition};
  my %clashes;
  my $rs = $source->resultset;
  foreach my $unique (keys %uniques) {
    my %pass;
    my @attrs = @{$uniques{$unique}};
    next if grep { !exists $merged{$_} } @attrs;
      # skip PK before insertion if auto-inc etc. etc.
    @pass{@attrs} = @merged{@attrs};
    if (my $obj = $rs->find(\%pass, { key => $unique })) {
      my $found_ident = $obj->ident_condition;
#warn join(', ', %$found_ident, %ident);
      if (!$proto->in_storage
          || (grep { $found_ident->{$_} ne $ident{$_} } keys %ident)) {
        # if in storage and no ident conditions are different the found
        # obj is *us* :)
        $clashes{$_} = 1 for @attrs;
      }
    }
  }
  $self->_unique_constraint_results(\%clashes);
};

after sync_all => sub { shift->check_all_uniques; };

around error_for_attribute => sub {
  my $orig = shift;
  my ($self, $attr) = @_;
  if ($self->_unique_constraint_results->{$attr->name}) {
    return "Already taken, please try an alternative";
  }
  return $orig->(@_);
};

around can_apply => sub {
  my $orig = shift;
  my ($self) = @_;
  return 0 if keys %{$self->_unique_constraint_results};
  return $orig->(@_);
};



1;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques

=head1 DESCRIPTION

=head2 check_all_uniques

=head2 error_for_attribute

=head2 meta

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

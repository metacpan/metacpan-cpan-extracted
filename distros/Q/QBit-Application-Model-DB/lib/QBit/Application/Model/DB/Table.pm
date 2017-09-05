
=head1 Name
 
QBit::Application::Model::DB::Table
 
=head1 Description
 
Base class for DB tables.

=cut

package QBit::Application::Model::DB::Table;
$QBit::Application::Model::DB::Table::VERSION = '0.019';
use qbit;

use base qw(QBit::Application::Model::DB::Class);

=head1 RO accessors
 
=over
 
=item *
 
B<name>

=item *
 
B<inherits>

=item *
 
B<primary_key>

=item *
 
B<indexes>

=item *
 
B<foreign_keys>

=back
 
=cut

__PACKAGE__->mk_ro_accessors(
    qw(
      name
      inherits
      primary_key
      indexes
      foreign_keys
      collate
      engine
      )
);

=head1 Abstract methods

=over

=item

B<create_sql>

=item

B<add_multi>

=item

B<add>

=item

B<edit>

=item

B<delete>

=item

B<_get_field_object>

=item

B<_convert_fk_auto_type>

=back

=cut

__PACKAGE__->abstract_methods(
    qw(
      create_sql
      add_multi
      add
      edit
      delete
      _get_field_object
      _convert_fk_auto_type
      )
);

=head1 Package methods

=head2 init

B<No arguments.>

Method called from L</new> before return object.
 
=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    throw gettext('Required option "fields"')
      unless $self->{'fields'};

    foreach my $field (@{$self->{'fields'}}) {    # Если нет типа, ищем тип в foreign_keys
        unless (exists($field->{'type'})) {
          FT: foreach my $fk (@{$self->{'foreign_keys'} || []}) {
                for (0 .. @{$fk->[0]} - 1) {
                    if ($field->{'name'} eq $fk->[0][$_]) {
                        my $fk_table_name = $fk->[1];
                        $self->_convert_fk_auto_type($field,
                            $self->db->$fk_table_name->{'__FIELDS_HS__'}{$fk->[2][$_]});
                        last FT;
                    }
                }
            }
        }
        $field = $self->_get_field_object(%$field, db => $self->db, table => $self);
        $self->{'__FIELDS_HS__'}{$field->{'name'}} = $field;
    }
}

=head2 fields

B<No arguments.>

B<Return values:>

=over

=item *

B<$fields> - reference to array of objects (QBit::Application::Model::DB::Field)

=back

B<Example:>

  my $fields = $app->db->users->fields();
 
=cut

sub fields {
    my ($self) = @_;

    return [(map {@{$self->db->$_->fields()}} @{$self->inherits || []}), @{$self->{'fields'}}];
}

=head2 fields

B<No arguments.>

B<Return values:>

=over

=item *

B<@field_names>

=back

B<Example:>

  my @field_names = $app->db->users->field_names();
 
=cut

sub field_names {
    my ($self) = @_;

    return map {$_->{'name'}} @{$self->fields};
}

=head2 get_all

B<Arguments:>

=over

=item *

B<%opts> - options with keys

=over

=item *

B<fields>

=item *

B<filter>

=item *

B<group_by>

=item *

B<order_by>

=item *

B<limit>

=item *

B<distinct>

=item *

B<for_update>

=item *

B<all_langs>

=back

=back

For more information see QBit::Application::Model::DB::Query::get_all

B<Return values:>

=over

=item *

B<$data> - reference to array

=back

B<Example:>

  my $data = $app->db->users->get_all(
      fields => [qw(id login)],
      filter => {id => 3},
  );

=cut

sub get_all {
    my ($self, %opts) = @_;

    my $query = $self->db->query->select(
        table => $self,
        hash_transform(\%opts, [qw(fields filter)]),
    );

    $query->group_by(@{$opts{'group_by'}}) if $opts{'group_by'};

    if ($opts{'having'}) {
        throw 'Have not realized yet';
    }

    $query->order_by(@{$opts{'order_by'}}) if $opts{'order_by'};

    $query->limit($opts{'limit'}) if $opts{'limit'};

    $query->distinct() if $opts{'distinct'};

    $query->for_update() if $opts{'for_update'};

    $query->all_langs(TRUE) if $opts{'all_langs'};

    return $query->get_all();
}

=head2 get

B<Arguments:>

=over

=item *

B<$id> - scalar or hash

=item *

B<%opts> - options with keys

=over

=item *

B<fields>

=item *

B<for_update>

=item *

B<all_langs>

=back

=back

For more information see QBit::Application::Model::DB::Query::get_all

B<Return values:>

=over

=item *

B<$data> - reference to hash

=back

B<Example:>

  my $data = $app->db->users->get(3, fields => [qw(id login)],);

=cut

sub get {
    my ($self, $id, %opts) = @_;

    throw gettext("No primary key") unless @{$self->primary_key};

    if (ref($id) eq 'ARRAY') {
        $id = {map {$self->primary_key->[$_] => $id->[$_]} 0 .. @$id - 1};
    } elsif (!ref($id)) {
        $id = {$self->primary_key->[0] => $id};
    }

    throw gettext("Bad fields in id")
      if grep {!exists($id->{$_})} @{$self->primary_key};

    return $self->get_all(%opts, filter => {map {$_ => $id->{$_}} @{$self->primary_key}})->[0];
}

=head2 truncate

B<No arguments.>

Truncate table.

B<Example:>

  $app->db->users->truncate();
 
=cut

sub truncate {
    my ($self) = @_;

    $self->db->_do('TRUNCATE TABLE ' . $self->quote_identifier($self->name));
}

=head2 default_fields

You can redefine this method in your Model.
 
=cut

sub default_fields { }

=head2 default_primary_key

You can redefine this method in your Model.
 
=cut

sub default_primary_key { }

=head2 default_indexes

You can redefine this method in your Model.
 
=cut

sub default_indexes { }

=head2 default_foreign_keys

You can redefine this method in your Model.
 
=cut

sub default_foreign_keys { }

sub _fields_hs {
    my ($self) = @_;

    return {map {$_->{'name'} => $_} @{$self->fields}};
}

sub _pkeys_or_filter_to_filter {
    my ($self, $pkeys_or_filter) = @_;

    unless (blessed($pkeys_or_filter) && $pkeys_or_filter->isa('QBit::Application::Model::DB::Filter')) {
        if (ref($pkeys_or_filter) eq 'ARRAY') {
            $pkeys_or_filter = [$pkeys_or_filter] if !ref($pkeys_or_filter->[0]) && @{$self->primary_key} > 1;
        } else {
            $pkeys_or_filter = [$pkeys_or_filter];
        }

        my $filter = $self->db->filter();
        foreach my $pk (@$pkeys_or_filter) {
            if (!ref($pk) && @{$self->primary_key} == 1) {
                $pk = {$self->primary_key->[0] => $pk};
            } elsif (ref($pk) eq 'ARRAY') {
                $pk = {map {$self->primary_key->[$_] => $pk->[$_]} 0 .. @{$self->primary_key} - 1};
            }

            throw gettext('Bad primary key') if ref($pk) ne 'HASH' || grep {!defined($pk->{$_})} @{$self->primary_key};
            $filter->or({map {$_ => $pk->{$_}} @{$self->primary_key}});
        }
        $pkeys_or_filter = $filter;
    }

    return $pkeys_or_filter;
}

=head2 have_fields

B<Arguments:>

=over

=item *

B<$fields> - reference to array

=back

B<Return values:>

=over

=item *

B<$bool>

=back

B<Example:>

  my $bool = $app->db->users->have_fields([qw(id login)]);

=cut

sub have_fields {
    my ($self, $fields) = @_;

    $fields = [$fields] if ref($fields) ne 'ARRAY';

    my %field_names_hs = map {$_ => TRUE} $self->field_names;

    return @$fields == grep {$field_names_hs{$_}} @$fields;
}

TRUE;

=pod

For more information see code and test.

=cut

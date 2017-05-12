package Pinwheel::Model::Base;

=head1 NAME

Pinwheel::Model::Base - Base class for PinWheel models

=head1 SYNOPSIS

  # Given $obj which is some PinWheel model...

  $obj->has_key($column_name);
  $column_names = $obj->keys; # unordered array ref
  $value = $obj->get($key);

  $sql_param = $obj->sql_param;
  @route_params = $obj->route_param;

=head1 DESCRIPTION

=over 4

=cut

use Carp qw(confess);
use Class::ISA;

use Pinwheel::Database qw(prepare);


sub new
{
    my ($class, $model, $data) = @_;
    my ($ctx, $key, $obj);

    $ctx = Pinwheel::Context::get('Model--' . $model->{table});
    $obj = $ctx->{$key} if ($key = $data->{id});

    if ($obj) {
        $obj->{data} = {%{$obj->{data}}, %$data};
    } else {
        $obj = bless {model => $model, data => $data}, $class;
        $ctx->{$key} = $obj if ($key);
    }
    return $obj;
}

sub STORABLE_freeze
{
    my ($obj, $cloning) = @_;
    return Storable::freeze($obj->{data});
}

sub STORABLE_attach
{
    my ($class, $cloning, $data) = @_;
    return new($class, \%{"$class\::model"}, Storable::thaw($data));
}

=item $bool = $obj-E<gt>has_key($key)

Returns true iff C<$obj> has a key named C<$key>.  If the column hasn't been
fetched yet, C<has_key> returns false.

=cut

sub has_key { exists($_[0]->{data}{$_[1]}) }

=item $keys = $obj-E<gt>keys

Return an (unordered) list of the current data keys in the model object.  This
only includes the columns where data has been fetched.

=cut

sub keys { return [ keys(%{$_[0]->{data}}) ] }

=item $value = $obj-E<gt>get($key)

TODO, document me.

=cut

sub get
{
    my ($self, $key) = @_;
    my ($getter);

    $getter = $self->{model}{getters}{$key};
    return $getter ? $self->$getter() : $self->{data}{$key};
}

sub _prefetched_link
{
    my ($self, $key, $data) = @_;
    my ($pkg, $model, $obj);

    $pkg = $self->{model}{associations}{$key};
    $pkg = $self->_inherit_association($key) if !defined($pkg);
    confess "Unknown relation $key" if !defined($pkg);
    $model = $pkg->{model};
    confess "Unable to resolve relation $key" if !defined($model);

    if (defined($data->{id})) {
        $model = Pinwheel::Model::_find_inherited_model($model, $data);
        $obj = Pinwheel::Model::Base::new($model->{model_class}, $model, $data);
    }
    $self->{data}{$key} = $obj;
}

sub _inherit_association
{
    my ($self, $key) = @_;
    my ($classname, $pkg);

    foreach $classname (Class::ISA::super_path(ref($self))) {
        $pkg = \%::;
        $pkg = $pkg->{"$_\::"} foreach split(/::/, $classname);
        if (defined($pkg->{model})) {
            $pkg = $pkg->{model}{associations}{$key};
        } else {
            $pkg = undef;
        }
        last if defined($pkg);
    }
    $self->{model}{associations}{$key} = $pkg;
    return $pkg;
}

sub _fill_out
{
    my $self = shift;
    my ($data, $sth, $row, $key);

    $data = $self->{data};
    $sth = prepare("SELECT * FROM `$self->{model}{table}` WHERE id = ?");
    $sth->execute($data->{id});
    $row = $sth->fetchrow_hashref();
    foreach $key (CORE::keys %{$self->{model}{fields}}) {
        $data->{$key} = $row->{$key} unless exists($data->{$key});
    }
}

=item $sql_param = $obj-E<gt>sql_param

Turns C<$obj> into a SQL query parameter; see L<Model>.

Default: C<$obj-E<gt>id>.

=cut

sub sql_param { $_[0]->id }

=item @route_params = $obj-E<gt>route_param

Turns C<$obj> into route parameter(s); see L<Mapper>.

Default: C<$obj-E<gt>id>.

=cut

sub route_param { $_[0]->id }

sub DESTROY { }

=back

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

1;

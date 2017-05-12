# overrides for MooseX::Storage::Engine

# this adds the ability to serialize fields in an object that do not
# have attribute accessors, as well as basic handling of DBIC column
# accessors and relationships

package MooseX::Storage::DBIC::Engine::Traits::Default;

use Moose::Role;
use namespace::autoclean;
use Scalar::Util qw/reftype refaddr blessed/;
use feature 'switch';
use Data::Dump qw/ddx/;

our $DBIC_MARKER = '__DBIC_RS__';

# add metadata for DBIC resultset
sub add_dbic_marker {
    my ($class, $storage, $row) = @_;

    return unless $storage && $row && blessed($row);

    if ($storage && $row->DOES('DBIx::Class::Core')) {
        $storage->{$DBIC_MARKER} = $row->result_source->resultset->result_class;
    }
}
sub get_dbic_marker {
    my ($class, $storage, $packed) = @_;

    return unless $packed;
    $storage->{$DBIC_MARKER} = $packed->{$DBIC_MARKER}
        if exists $packed->{$DBIC_MARKER};
}

override collapse_object => sub {
    my ($self) = @_;

    my $storage = super();

    # add dbic rs name
    $self->add_dbic_marker($storage, $self->object);
    return $storage;
};

override expand_object => sub {
    my ($self, $data, %options) = @_;

    my $storage = super();

    # grab dbic rs name
    $self->get_dbic_marker($storage, $data);
    return $storage;
};

sub is_dbic_serializable {
    my ($self, $v) = @_;

    return $v && blessed($v) && $v->isa('Moose::Object') &&
        $v->DOES('MooseX::Storage::DBIC');
}

override collapse_attribute_value => sub {
    my ($self, $attr, $options) = @_;

    my $obj = $self->object;
    my $name = $attr->name;

    my $value;

    # fast path: hashref field on instance
    # instance this attribute is attached to
    #$value = $obj->{$name} if $obj && ref($obj) && reftype($obj) eq 'HASH' &&
    #    ! blessed($obj) && exists $obj->{$name};
    #return $value if defined $value;

    $value = $attr->get_value($obj);
    if (defined $value && $attr->has_type_constraint) {
        # simple moose attribute with accessor
        $value = super();
        return $value;
    } else {
        # dbic?
        if ($obj && $obj->DOES('DBIx::Class::Core')) {
            my $src = $obj->result_source;

            # relationship?
            if ($src->has_relationship($name)) {
                # get relations
                my $rel_rs = $obj->related_resultset($name);
                die "expected related rs for $name on $obj"
                    unless $rel_rs;

                # are we expecting a scalar or array?
                my $info = $obj->relationship_info($name);

                if ($info->{attrs}{accessor} eq 'multi') {
                    # have many possible related rows
                    my @rows = $obj->can($name) ? $obj->$name : $rel_rs->all;
                    $value = \@rows;
                } else {
                    # expecting single rel
                    $value = $obj->can($name) ? $obj->$name : $rel_rs->single;
                }
            } else {
                # column accessor?
                if (exists $src->columns_info->{$name}) {
                    $value = $obj->get_column($name);
                }
            }
        }

        unless (defined $value) {
            # try to call method of $name
            $value = $obj->$name if blessed($obj) && $obj->can($name);
        }
    }

    return unless defined $value;

    # recursively serialize a value, if possible
    my $serialize_obj = sub {
        my $v = shift;
        return unless defined $v;

        # have we already visited this relationship?
        if ($obj->can('result_source') && blessed($v) && $v->isa('DBIx::Class::Core')) {
            $attr->{_mxsd_engine} ||= $self;
            my $info = $obj->result_source->relationship_info($name);
            #warn "name: $name attr: " . refaddr($attr) . " self: " . refaddr($self) . " value: " . refaddr($info);
            $attr->{_mxsd_engine}->check_for_cycle_in_collapse($attr, $info) if $info;
        }

        my $ret;
        if ($self->is_dbic_serializable($v)) {
            $ret = $v->pack;

            $self->add_dbic_marker($ret, $v);
        } else {
            $ret = $v;
        }

        return $ret;
    };

    # see if what we are returning is serializable itself
    given (ref $value) {
        when ('HASH') {
            while (my ($k, $v) = each %$value) {
                if ($self->is_dbic_serializable($v)) {
                    $value->{$k} = $v->pack;
                }
            }
        }
        when ('ARRAY') {
            # serialize all objects in array
            my @serialized;
            foreach my $v (@$value) {
                push @serialized, $serialize_obj->($v);
            }

            $value = \@serialized;
        }
        when ('') {
            # not a reference, leave as-is
        }
        default {
            if (blessed $value) {
                # maybe it is serializable?
                $value = $serialize_obj->($value);
            } else {
                # some sort of reference we don't know how to serialize
                # (code, glob, etc)
                die "don't know how to serialize " . ref($value);
            }
        }
    }

    # recursive checking finished
    delete $attr->{_mxsd_engine};

    return $value;
};

1;

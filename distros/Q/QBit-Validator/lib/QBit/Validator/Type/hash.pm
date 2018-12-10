package QBit::Validator::Type::hash;
$QBit::Validator::Type::hash::VERSION = '0.012';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator;
use Exception::Validator::FailedField;

#order is important
sub get_options_name {
    qw(type deps fields one_of any_of extra);
}

sub pre_process_template {
    my ($self, $template) = @_;

    $template->{'extra'} //= FALSE;
}

sub type {
    my ($qv, $types) = @_;

    return sub {
        throw FF gettext('Data must be HASH') if ref($_[1]) ne 'HASH';

        return TRUE;
      }
}

sub deps {
    my ($qv, $depends, $template) = @_;

    throw Exception::Validator gettext('Option "%s" must be HASH', 'deps') unless ref($depends) eq 'HASH';

    throw Exception::Validator gettext('You must specify option "%s"', 'fields') unless exists($template->{'fields'});

    my $inverse_depends = $qv->{'__INVERSE_DEPENDS__'} = {};
    foreach my $field (keys(%$depends)) {
        my $deps = $depends->{$field};

        throw Exception::Validator gettext('You must specify the fields on which the field "%s"', $field)
          unless defined($deps);

        if (ref($deps) ne 'ARRAY') {
            $depends->{$field} = $deps = [$deps];
        }

        my @unknown_fields = grep {!exists($template->{'fields'}{$_})} @$deps;

        throw Exception::Validator gettext('Keys: %s do not used in option "fields"', join(', ', @unknown_fields))
          if @unknown_fields;

        foreach (@$deps) {
            push(@{$inverse_depends->{$_}}, $field);
        }
    }

    my $order = $qv->{'__FIELDS_ORDER__'} = {};
    foreach my $field (keys(%{$template->{'fields'}})) {
        $order->{$field} = _get_field_order($field, $order, $depends);
    }

    return ();
}

sub _get_field_order {
    #my ($field, $order, $deps) = @_;

    return $_[1]->{$_[0]} if defined($_[1]->{$_[0]});

    if ($_[2]->{$_[0]}) {
        return array_n_max(map {$_[1]->{$_} = _get_field_order($_, $_[1], $_[2])} @{$_[2]->{$_[0]}}) + 1;
    } else {
        return 0;
    }
}

#TODO: implement method _exists
# defined = required

sub fields {
    my ($qv, $fields, $template) = @_;

    my $parent = $qv->parent // $qv;
    my $path_manager = $parent->path_manager();

    my $path = $qv->path();

    my %validators = ();
    foreach my $field (keys(%$fields)) {
        $validators{$field} = QBit::Validator->new(
            template => $fields->{$field},
            parent   => $parent,
            path     => $path_manager->get_absolute_path($path_manager->get_path_part('hash', $field), $path),
        );
    }

    my $inverse_depends = $qv->{'__INVERSE_DEPENDS__'} // {};

    my $order = $qv->{'__FIELDS_ORDER__'} // {};
    my @sorted_fields = sort {($order->{$a} // 0) <=> ($order->{$b} // 0)} keys(%$fields);

    return sub {
        my %errors = ();
        foreach my $field (@sorted_fields) {
            next if $errors{$field};

            unless ($validators{$field}->_validate($_[1]->{$field})) {
                $errors{$field} = $validators{$field}->get_errors;

                _set_recursive_depends_errors($field, \%errors, $inverse_depends);
            }
        }

        throw FF \%errors if %errors;

        return TRUE;
      }
}

sub _set_recursive_depends_errors {
    #my ($field, $errors, $inverse_depends) = @_;

    foreach (@{$_[2]->{$_[0]} // []}) {
        $_[1]->{$_} = gettext('Field "%s" depends on "%s"', $_, $_[0]);

        _set_recursive_depends_errors($_, $_[1], $_[2]);
    }
}

sub extra {
    my ($qv, $val, $template) = @_;

    unless ($val) {
        return sub {
            my @extra_fields = grep {!$template->{'fields'}{$_}} keys(%{$_[1]});

            if (@extra_fields) {
                throw FF gettext('Extra fields: %s', join(', ', @extra_fields));
            }

            return TRUE;
          }
    }

    return ();
}

sub one_of {
    my ($qv, $list, $template) = @_;

    throw Exception::Validator gettext('Option "%s" must be ARRAY', 'one_of')
      if ref($list) ne 'ARRAY';

    my $min_size = 2;

    throw Exception::Validator gettext('Option "%s" have size "%s", but expected size equal or more than "%s"',
        'one_of', scalar(@$list), $min_size)
      if @$list < $min_size;

    my @unknow_fields = grep {!exists($template->{'fields'}{$_})} @$list;
    if (@unknow_fields) {
        throw Exception::Validator gettext('Keys: %s do not used in option "fields"', join(', ', @unknow_fields));
    }

    return sub {
        my @received_fields = ();
        foreach my $field (@$list) {
            push(@received_fields, $field) if exists($_[1]->{$field});
        }

        if (@received_fields != 1) {
            throw FF gettext('Expected one key from: %s', join(', ', $list));
        }

        return TRUE;
    };
}

sub any_of {
    my ($qv, $list, $template) = @_;

    throw Exception::Validator gettext('Option "%s" must be ARRAY', 'any_of')
      if ref($list) ne 'ARRAY';

    my $min_size = 2;

    throw Exception::Validator gettext('Option "%s" have size "%s", but expected size equal or more than "%s"',
        'any_of', scalar(@$list), $min_size)
      if @$list < $min_size;

    my @unknow_fields = grep {!exists($template->{'fields'}{$_})} @$list;
    if (@unknow_fields) {
        throw Exception::Validator gettext('Keys: %s do not used in option "fields"', join(', ', @unknow_fields));
    }

    return sub {
        my @received_fields = ();
        foreach my $field (@$list) {
            push(@received_fields, $field) if exists($_[1]->{$field});
        }

        unless (@received_fields) {
            throw FF gettext('Expected any keys from: %s', join(', ', $list));
        }

        return TRUE;
    };
}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    foreach ($self->get_options_name) {
        $self->{$_} = \&$_;
    }
}

TRUE;

package QBit::Application::Model::DBManager::_Utils::Fields;
$QBit::Application::Model::DBManager::_Utils::Fields::VERSION = '0.018';
use qbit;

use base qw(QBit::Class);

__PACKAGE__->mk_ro_accessors('model');

sub new {
    my ($class, $fields, $orders, $opt, $model, $all_locales) = @_;

    my %res_fields;

    $opt = [grep {$fields->{$_}{'default'}} keys(%$fields)] unless defined($opt);
    $opt = [$opt] if ref($opt) ne 'ARRAY';
    $opt = [keys(%$fields)] if ($opt->[0] // '') eq '*';

    my @unknown_fields = ();
    foreach my $field (@$opt) {
        unless (exists($fields->{$field})) {
            push(@unknown_fields, $field);
            next;
        }

        next if $fields->{$field}{'check_rights'} && !$model->check_rights(@{$fields->{$field}{'check_rights'}});
        $res_fields{$field} = $fields->{$field};
    }

    throw gettext('In model %s not found follows fields: %s', ref($model), join(', ', @unknown_fields))
      if @unknown_fields;

    my %need_delete = ();
    foreach my $field (keys(%res_fields)) {
        if (exists($fields->{$field}{'depends_on'}) || exists($fields->{$field}{'forced_depends_on'})) {
            foreach
              my $dep_field (@{$fields->{$field}{'depends_on'} // []}, @{$fields->{$field}{'forced_depends_on'} // []})
            {
                unless (exists($res_fields{$dep_field})) {
                    $res_fields{$dep_field}  = $fields->{$dep_field};
                    $need_delete{$dep_field} = TRUE;
                }
            }
        }
    }

    my @locale_names;
    my $cached_locales;

    my @process_fields;
    foreach my $field (sort {($orders->{$a} || 0) <=> ($orders->{$b} || 0) || $a cmp $b} keys(%res_fields)) {
        if (exists($res_fields{$field}->{'get'})) {
            push(@process_fields, {name => $field, process => $res_fields{$field}->{'get'}});
        } elsif ($all_locales && $res_fields{$field}->{'i18n'}) {
            unless ($cached_locales) {
                @locale_names = keys(%{$model->app->get_option('locales', {})});
                $cached_locales++;
            }

            push(
                @process_fields,
                {
                    name    => $field,
                    process => sub {
                        return {map {$_ => delete($_[1]->{"${field}_$_"})} @locale_names};
                      }
                }
            );
        }
    }

    my $self = $class->SUPER::new(
        __FIELDS__      => \%res_fields,
        __PROC_FIELDS__ => \@process_fields,
        __NEED_DELETE__ => [keys(%need_delete)],
        model           => $model,
    );

    weaken($self->{'model'});

    return $self;
}

sub get_fields {
    my ($self) = @_;

    return {%{$self->{'__FIELDS__'}}};
}

sub need_delete {
    return @{$_[0]->{'__NEED_DELETE__'}};
}

sub get_db_fields {
    my ($self, $table) = @_;

    my %res    = ();
    my $fields = $self->{'__FIELDS__'};

    if (defined($table)) {
        foreach my $field_name (keys(%$fields)) {
            next unless ($fields->{$field_name}{'db'} || '') eq ($table || '');
            $res{$field_name} = defined($fields->{$field_name}{'db_expr'}) ? $fields->{$field_name}{'db_expr'} : '';
        }
    } else {
        foreach my $field_name (keys(%$fields)) {
            next unless $fields->{$field_name}{'db'};
            $res{$field_name} = defined($fields->{$field_name}{'db_expr'}) ? $fields->{$field_name}{'db_expr'} : '';
        }
    }

    return \%res;
}

sub process_data {
    my ($self, $data) = @_;

    my @need_delete = $self->need_delete();

    if (@{$self->{__PROC_FIELDS__}} || @need_delete) {
        foreach my $rec (@$data) {
            foreach my $p (@{$self->{__PROC_FIELDS__}}) {
                $rec->{$p->{'name'}} = $p->{'process'}->($self, $rec);
            }

            delete($rec->{$_}) foreach @need_delete;
        }
    }

    return $data;
}

sub need {
    my ($self, $name) = @_;

    return exists($self->{'__FIELDS__'}{$name});
}

sub init_fields {
    my ($self, $original_fields) = @_;

    my $fields = clone($original_fields);

    _init_field_deps($fields, $_) foreach keys(%$fields);

    foreach my $name (keys(%$fields)) {
        my $fld = $fields->{$name};
        my @rights;

        if ($fld->{'depends_on'}) {
            @rights = map {
                defined($fields->{$_}{'check_rights'})
                  ? (
                    ref($fields->{$_}{'check_rights'}) eq 'ARRAY'
                    ? @{$fields->{$_}{'check_rights'}}
                    : $fields->{$_}{'check_rights'}
                  )
                  : ()
            } @{$fld->{'depends_on'}};
        }

        if (@rights) {
            $fld->{'check_rights'} =
              array_uniq(@rights, (defined($fld->{'check_rights'}) ? $fld->{'check_rights'} : ()));
        } elsif (defined($fld->{'check_rights'}) && ref($fld->{'check_rights'}) ne 'ARRAY') {
            $fld->{'check_rights'} = [$fld->{'check_rights'}];
        }
    }

    return $fields;
}

sub _init_field_deps {
    my ($fields, $name) = @_;

    throw gettext('Field "%s" does not exists', $name) unless exists($fields->{$name});

    my $fld         = $fields->{$name};
    my $deps        = $fld->{'depends_on'} // [];
    my $forced_deps = $fld->{'forced_depends_on'} // [];

    $deps        = [$deps]        if ref($deps)        ne 'ARRAY';
    $forced_deps = [$forced_deps] if ref($forced_deps) ne 'ARRAY';

    if (@$deps || @$forced_deps) {
        my @results = map {_init_field_deps($fields, $_)} @$deps, @$forced_deps;

        $deps        = array_uniq($deps,        map {$_->{'depends_on'}} @results);
        $forced_deps = array_uniq($forced_deps, map {$_->{'forced_depends_on'}} @results);
    }

    if (@$deps) {
        $fld->{'depends_on'} = $deps;
    } else {
        delete $fld->{'depends_on'};
    }

    if (@$forced_deps) {
        $fld->{'forced_depends_on'} = $forced_deps;
    } else {
        delete $fld->{'forced_depends_on'};
    }

    return {
        depends_on        => $deps,
        forced_depends_on => $forced_deps,
    };
}

sub init_field_sort {
    my ($self, $fields) = @_;

    my $orders = {};
    $orders->{$_} = _init_field_sort($orders, $fields, $_, 0) foreach keys(%$fields);

    return $orders;
}

sub _init_field_sort {
    my ($orders, $fields, $name, $level) = @_;

    return $orders->{$name} + $level if exists($orders->{$name});

    my @foreign_fields = (@{$fields->{$name}{'depends_on'} // []}, @{$fields->{$name}{'forced_depends_on'} // []});

    return @foreign_fields
      ? array_max(map {_init_field_sort($orders, $fields, $_, $level + 1)} @foreign_fields)
      : $level;
}

TRUE;

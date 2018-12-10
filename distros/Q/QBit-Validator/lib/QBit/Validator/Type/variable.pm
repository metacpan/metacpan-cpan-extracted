package QBit::Validator::Type::variable;
$QBit::Validator::Type::variable::VERSION = '0.012';
use qbit;

use base qw(QBit::Validator::Type);

use QBit::Validator;

use Exception::Validator;
use Exception::Validator::FailedField;

#order is important
sub get_options_name {
    qw(type conditions);
}

sub type {()}

sub conditions {
    my ($qv, $conditions) = @_;

    throw Exception::Validator gettext('Option "%s" must be a not empty ARRAY', 'conditions')
      if ref($conditions) ne 'ARRAY' or !@$conditions;

    my $count = 1;
    my $all   = @$conditions;

    my @result = ();
    foreach my $condition (@$conditions) {
        my $is_last_condition = $all == $count++;

        if (exists($condition->{'if'}) && exists($condition->{'else'}) && !$is_last_condition) {
            throw Exception::Validator gettext('Option "else" must only be in the last condition');
        }

        push(@result, _get_check_by_condition($qv, $condition, $is_last_condition));
    }

    return @result;
}

sub _get_check_by_condition {
    my ($qv, $condition, $is_last_condition) = @_;

    if (exists($condition->{'if'})) {
        my $if = $condition->{'if'};

        my $check = _get_check($qv, $if);

        my ($then, $else);
        if ($condition->{'then'}) {
            $then = QBit::Validator->new(
                template => $condition->{'then'},
                parent   => $qv->parent // $qv,
                path     => $qv->path
            );
        }

        if ($condition->{'else'}) {
            $else = QBit::Validator->new(
                template => $condition->{'else'},
                parent   => $qv->parent // $qv,
                path     => $qv->path
            );
        }

        return sub {
            my $validator = $check->(@_);

            if ($validator->has_errors) {
                if (defined($else)) {
                    if ($else->_validate($_[1])) {
                        return FALSE;
                    } else {
                        throw FF $else->get_errors;
                    }
                } else {
                    throw FF $validator->get_errors if $is_last_condition;
                }
            } else {
                if (defined($then)) {
                    if ($then->_validate($_[1])) {
                        return FALSE;
                    } else {
                        throw FF $then->get_errors;
                    }
                } else {
                    # exit with OK
                    return FALSE;
                }
            }

            return TRUE;
          }
    } else {
        #['/key' => {...}]
        #['' => {...}]
        #{min => 1}

        my $check = _get_check($qv, $condition);

        if ($is_last_condition) {
            return sub {
                my $validator = $check->(@_);

                throw FF $validator->get_errors if $validator->has_errors;

                # exit with OK
                return FALSE;
              }
        } else {
            return sub {
                my $validator = $check->(@_);

                return $validator->has_errors;
              }
        }
    }
}

sub _get_check {
    my ($qv, $condition) = @_;

    my $ref = ref($condition);

    my $parent = $qv->parent // $qv;

    my $validator = QBit::Validator->new(
        template => $ref eq 'ARRAY' ? $condition->[1] : $condition,
        parent   => $parent,
        path     => $qv->path,
    );

    if ($ref eq 'ARRAY' && $condition->[0] ne '') {
        #check field

        my $data         = $qv->data;
        my $path_manager = $parent->path_manager();

        return sub {
            my $condition_path = $path_manager->get_absolute_path($condition->[0], $qv->path);

            my $data_to_check =
              $path_manager->get_data_by_path($path_manager->get_current_node_path($condition_path), $data);

            $validator->_validate($data_to_check);

            return $validator;
          }
    } else {
        #check current node

        return sub {
            $validator->_validate($_[1]);

            return $validator;
          }
    }
}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    foreach ($self->get_options_name) {
        $self->{$_} = \&$_;
    }
}

TRUE;

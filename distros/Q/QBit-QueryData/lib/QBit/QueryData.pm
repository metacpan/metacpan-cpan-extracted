package QBit::QueryData;
$QBit::QueryData::VERSION = '0.005';
use qbit;

use base qw(QBit::Class);

__PACKAGE__->mk_accessors(qw(definition));

my $FILTER_OPERATIONS = {
    number => {
        '='      => '==',
        '!='     => '==',
        '<>'     => '==',
        '>'      => '>',
        '>='     => '>=',
        '<'      => '<',
        '<='     => '<=',
        'IN'     => '==',
        'NOT IN' => '==',
        'IS'     => '==',
        'IS NOT' => '==',
    },
    string => {
        '='        => 'eq',
        '!='       => 'eq',
        '<>'       => 'eq',
        '>'        => 'gt',
        '>='       => 'ge',
        '<'        => 'lt',
        '<='       => 'le',
        'IN'       => 'eq',
        'NOT IN'   => 'eq',
        'IS'       => 'eq',
        'IS NOT'   => 'eq',
        'LIKE'     => '=~',
        'NOT LIKE' => '=~',
    },
};

my $ORDER_OPERATIONS = {
    number => '<=>',
    string => 'cmp',
};

sub init {
    my ($self) = @_;

    $self->definition({}) unless defined($self->definition);

    $self->data($self->{'data'} // []);

    $self->fields($self->get_fields());

    $self->filter($self->{'filter'});
}

sub data {
    my ($self, $data) = @_;

    if (defined($data)) {
        delete($self->{'__EXISTS_FIELDS__'});
        delete($self->{'__ALL_FIELDS__'});

        foreach my $field (sort keys(%{$data->[0] // {}})) {
            $self->{'__EXISTS_FIELDS__'}{$field} = TRUE;
            push(@{$self->{'__ALL_FIELDS__'}}, $field);
        }

        $self->{'data'} = $data;
    }

    return $self->{'data'};
}

sub fields {
    my ($self, $fields) = @_;

    if (defined($fields)) {
        $fields = [keys(%$fields)] if ref($fields) eq 'HASH';

        if (@$fields == 0) {
            #default
            delete($self->{'__FIELDS__'});
        } else {
            #set fields
            if (exists($self->{'__EXISTS_FIELDS__'})) {
                my @not_exists = grep {!$self->{'__EXISTS_FIELDS__'}{$_}} @$fields;
                throw gettext('Unknown fields: %s', join(', ', @not_exists)) if @not_exists;
            }

            $self->{'__FIELDS__'} = $fields;
        }
    } else {
        #all fields
        delete($self->{'__FIELDS__'});
        delete($self->{'fields'});
    }

    return $self;
}

sub get_fields {
    my ($self) = @_;

    return $self->{'__FIELDS__'} // $self->{'fields'} // $self->{'__ALL_FIELDS__'};
}

sub filter {
    my ($self, $filter) = @_;

    if (defined($filter)) {
        $self->{'__FILTER__'} = eval($self->_get_filter($filter));
    } else {
        delete($self->{'__FILTER__'});
    }

    return $self;
}

sub all_langs {
    my ($self, $value) = @_;

    $self->{'__ALL_LANGS__'} = $value // TRUE;

    return $self;
}

sub distinct {
    my ($self, $value) = @_;

    $self->{'__DISTINCT__'} = $value // TRUE;

    return $self;
}

sub insensitive {
    my ($self, $value) = @_;

    $self->{'__INSENSITIVE__'} = $value // TRUE;

    return $self;
}

sub for_update { }

sub order_by {
    my ($self, @order_by) = @_;

    unless (@order_by) {
        delete($self->{'__ORDER_BY__'});

        return $self;
    }

    @order_by = map {[ref($_) ? ($_->[0], $_->[1]) : ($_, 0)]} @order_by;

    $self->{'__ORDER_BY__'} = eval($self->_get_order(@order_by));

    return $self;
}

sub limit {
    my ($self, $offset, $limit) = @_;

    if (defined($limit)) {
        $self->{'__OFFSET__'} = $offset // 0;

        $self->{'__LIMIT__'} = $limit;
    } else {
        delete($self->{'__OFFSET__'});
        delete($self->{'__LIMIT__'});
    }

    return $self;
}

sub calc_rows {
    my ($self) = @_;

    $self->{'__CALC_ROWS__'} = TRUE;

    return $self;
}

sub found_rows {
    my ($self) = @_;

    return scalar(@{$self->data});
}

sub get_all {
    my ($self, %opts) = @_;

    my @data = defined($self->{'__FILTER__'}) ? grep {$self->{'__FILTER__'}->($_)} @{$self->data} : @{$self->data};

    if (defined($self->{'__ORDER_BY__'})) {
        @data = sort {$self->{'__ORDER_BY__'}->($a, $b)} @data;
    }

    if (defined($self->{'__LIMIT__'})) {
        $self->{'__OFFSET__'} //= 0;

        return [] if $self->{'__OFFSET__'} >= @data;

        my $high = $self->{'__OFFSET__'} + $self->{'__LIMIT__'} - 1;

        $high = $#data if $high > $#data;

        @data = @data[$self->{'__OFFSET__'} .. $high];
    }

    my @result = ();

    my @fields = @{$self->get_fields() // []};
    if ($self->{'__DISTINCT__'}) {
        my %uniq = ();

        foreach my $row (@data) {
            my $str = '';

            my $new_row = {};
            foreach (@fields) {
                $str .= $row->{$_} // 'UNDEF';

                $new_row->{$_} = $row->{$_};
            }

            unless ($uniq{$str}) {
                push(@result, $new_row);

                $uniq{$str} = TRUE;
            }
        }
    } else {
        foreach my $row (@data) {
            push(@result, {map {$_ => $row->{$_}} @fields});
        }
    }

    return \@result;
}

sub _get_filter {
    my ($self, $filter) = @_;

    my $body = '';

    $self->_filter(\$body, $filter);

    return $self->_get_sub($body);
}

sub _get_sub {
    my ($self, $body) = @_;

    return "sub {\n    no warnings;\n\n    return " . $body . ";\n}";
}

sub _filter {
    my ($self, $body, $filter) = @_;

    my $operation = ' && ';

    $$body .= '(';

    my @part = ();
    if (ref($filter) eq 'HASH') {
        foreach my $field (keys(%$filter)) {
            throw gettext('Unknown field "%s"', $field)
              if exists($self->{'__EXISTS_FIELDS__'}) && !$self->{'__EXISTS_FIELDS__'}{$field};

            my $type_operation = $self->_get_filter_operation($field, '=');

            if (ref($filter->{$field}) eq 'ARRAY') {
                push(@part,
                        "(grep {\$_[0]->{$field} $type_operation \$_} ("
                      . join(', ', map {$self->_get_value($field, $_)} @{$filter->{$field}})
                      . "))");
            } else {
                my $value = $self->_get_value($field, $filter->{$field});

                push(@part, "(\$_[0]->{$field} $type_operation $value)");
            }
        }
    } elsif (ref($filter) eq 'ARRAY' && @$filter == 2) {
        $operation = ' || ' if uc($filter->[0]) eq 'OR';

        foreach my $sub_filter (@{$filter->[1]}) {
            my $sub_body = '';
            $self->_filter(\$sub_body, $sub_filter);
            push(@part, $sub_body);
        }
    } elsif (ref($filter) eq 'ARRAY' && @$filter == 3) {
        my ($field, $op, $value) = @$filter;

        throw gettext('Unknown field "%s"', $field)
          if exists($self->{'__EXISTS_FIELDS__'}) && !$self->{'__EXISTS_FIELDS__'}{$field};

        $op    = uc($op);
        $value = $$value;

        my $type_operation = $self->_get_filter_operation($field, $op);

        if (ref($value) eq 'ARRAY') {
            throw gettext('Operation "%s" is not applied to the array', $op)
              if grep {$op eq $_} ('>', '>=', '<', '<=', 'LIKE', 'NOT LIKE', 'IS', 'IS NOT');

            push(@part,
                    "("
                  . ($op eq '<>' || $op eq '!=' || $op eq 'NOT IN' ? '!' : '')
                  . "grep {\$_[0]->{$field} $type_operation \$_} ("
                  . join(', ', map {$self->_get_value($field, $_)} @$value)
                  . "))");
        } else {
            $value = $self->_get_value($field, $value, $op);

            push(@part,
                ($op eq '<>' || $op eq '!=' || $op =~ /^NOT\s|\sNOT$/i ? '!' : '')
                  . "(\$_[0]->{$field} $type_operation $value)");
        }
    }

    $$body .= join($operation, @part);

    $$body .= ')';
}

sub _get_order {
    my ($self, @order_by) = @_;

    my @part = ();
    foreach my $order (@order_by) {
        my @path = split(/\./, $order->[0]);

        throw gettext('Unknown field "%s"', $path[0])
          if exists($self->{'__EXISTS_FIELDS__'}) && !$self->{'__EXISTS_FIELDS__'}{$path[0]};

        my $type_operation = $self->_get_order_operation($order->[0]);

        my $value = '$_[%s]';
        $value .= "->{$_}" foreach @path;

        if ($order->[1]) {
            push(@part, sprintf("($value %s $value)", 1, $type_operation, 0));
        } else {
            push(@part, sprintf("($value %s $value)", 0, $type_operation, 1));
        }
    }

    my $body = join(' || ', @part);

    return $self->_get_sub($body);
}

sub _get_filter_operation {
    my ($self, $field, $op) = @_;

    my $type = $self->definition->{$field}{'type'} // 'string';

    return $FILTER_OPERATIONS->{$type}{$op} // throw gettext('Unknow operation "%s"', $op);
}

sub _get_order_operation {
    my ($self, $field) = @_;

    my $type = $self->definition->{$field}{'type'} // 'string';

    return $ORDER_OPERATIONS->{$type};
}

sub _get_value {
    my ($self, $field, $value, $op) = @_;

    return 'undef' unless defined($value);

    #TODO: REGEXP
    if (defined($op) && $op =~ /LIKE/i) {
        return 'm/' . quotemeta($value) . '/' . ($self->{'__INSENSITIVE__'} ? 'i' : '');
    }

    my $type = $self->definition->{$field}{'type'} // 'string';

    if ($type eq 'string') {
        $value =~ s/\\/\\\\/g;
        $value =~ s/'/\\'/g;
        $value = "'$value'";
    } else {
        throw gettext('%s - not number', $value) unless looks_like_number($value);
    }

    return $value;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::QueryData - Query constructor for the data.

=head1 GitHub

https://github.com/QBitFramework/QBit-QueryData

=head1 Install

=over

=item *

cpanm QBit::QueryData

=item *

apt-get install libqbit-querydata-perl (http://perlhub.ru/)

=back

=head1 Methods

=over

=item *

B<new> - created object. Params:

=over

=item *

B<data> - data.

=item *

B<fields> - default fields (optional, defualt all fields)

=item *

B<filter> - default filter (optional, default all data)

=item *

B<definition> - fields definition (optional, default 'string')

=back

B<Example:>

    my $q = QBit::QueryData->new(
        data => [
            {
                id      => 1,
                caption => 'c1',
                data    => {
                    k1 => 1.1,
                    k2 => 'd1_2'
                },
            },
            {
                id      => 2,
                caption => 'c2',
                data    => {
                    k1 => 2.1,
                    k2 => 'd2_2'
                },
            },
        ],
        fields => [qw(id caption)],
        filter => ['OR', [{id => 1}, ['caption' => '=' => \'c2']]],
        definition => {
            'id'      => {type => 'number'},
            'caption' => {type => 'string'},
            'data.k1' => {type => 'number'},
            'data.k2' => {type => 'string'},
        },
    );

=item *

B<fields> - set fields for request

B<Example:>

    $q->fields([qw(caption)]); # or $q->fields({caption => ''});
    
    $q->fields([]); # use default fields
    
    $q->fields(); # all fields

=item *

B<get_fields> - get fields

B<Example:>

    my $fields = $q->get_fields(); # ['caption', 'id']

=item *

B<filter> - set filter for request

Types:

=over

=item *

number: "=" "<>" "!=" ">" ">=" "<" "<=" "IN" "NOT IN" "IS" "IS NOT"

=item *

string: "=" "<>" "!=" ">" ">=" "<" "<=" "IN" "NOT IN" "IS" "IS NOT" "LIKE" "NOT LIKE"

=back

For list: "=" "<>" "!=" "IN" "NOT IN"

B<Example:>

    $q->filter({id => 1, caption => 'c1'}); # or ['AND', [['id' => '=' => \1], ['caption' => '=' => \'c1']]]
    
    $q->filter(['caption' => 'LIKE' => \'c']);
    
    $q->filter(); # all data

=item *

B<definition> - set fields definition

B<Example:>

    $q->definition({
        'id'      => {type => 'number'},
        'caption' => {type => 'string'},
        'data.k1' => {type => 'number'},
        'data.k2' => {type => 'string'},
    });

=item *

B<order_by> - set order sorting

B<Example:>

    # Ascending
    $q->order_by(qw(id caption data.k1)); # or (['id', 0], ['caption', 0], ['data.k1', 0])
    
    # Descending
    $q->order_by(['id', 1]);
    
=item *

B<limit> - set offset and limit

B<Example:>

    $q->limit($offset, $limit);
    
    $q->limit(); # all data

=item *

B<found_rows> - data count

B<Example:>

    my $rows = $q->found_rows(); # 2

=item *

B<distinct> - set/reset only unique elements

B<Example:>

    #set
    $q->distinct(1); # or $q->distinct();
    
    #reset
    $q->distinct(0);

=item *

B<insensitive> - set/reset insensitive mode for LIKE 

B<Example:>

    #set
    $q->insensitive(1); # or $q->insensitive();
    
    #reset
    $q->insensitive(0);

=item *

B<get_all> - get data by settings

B<Example:>

    my $data = $q->get_all();
    
    $data = $q->fields([qw(id)])->filter(['caption' => 'LIKE' => \'c'])->order_by(['id', 1])->get_all();

=item *

B<all_langs> - support interface DB::Query

=item *

B<calc_rows> - support interface DB::Query

=item *

B<for_update> - support interface DB::Query

=back

=cut

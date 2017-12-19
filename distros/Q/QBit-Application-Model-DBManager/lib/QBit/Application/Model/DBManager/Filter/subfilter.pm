package QBit::Application::Model::DBManager::Filter::subfilter;
$QBit::Application::Model::DBManager::Filter::subfilter::VERSION = '0.019';
use qbit;

use base qw(QBit::Application::Model::DBManager::Filter);

sub public_keys {return [qw(subfields)];}

sub is_simple {return FALSE;}

sub pre_process {
    my ($self, $field, $field_name, %opts) = @_;

    my $accessor_name = $field->{'model_accessor'};

    $opts{'subfilters'} ||= {};
    return FALSE if $opts{'subfilters'}->{$self->{'db_manager'}->$accessor_name};
    local ($opts{'subfilters'}->{$self->{'db_manager'}}) = TRUE;

    $opts{'ns'}           ||= [];
    $opts{'nonterminals'} ||= {};
    $opts{'tokens'}       ||= {};

    my $subfilter_fields = $self->{'db_manager'}->$accessor_name->get_db_filter_fields(
        %opts,
        ns      => [@{$opts{'ns'}}, $field_name],
        private => TRUE
    );

    my $pub_subfilter_fields =
      $opts{'private'} ? $subfilter_fields : $self->{'db_manager'}->$accessor_name->get_db_filter_fields(
        %opts,
        ns      => [@{$opts{'ns'}}, $field_name],
        private => FALSE
      );

    $field->{'subfields'} = $pub_subfilter_fields;

    $field->{'ns'} = lc(join('___', @{$opts{'ns'}}, $field_name));

    my @expr = %{
        $self->{'db_manager'}->$accessor_name->_grammar_expr(
            %opts,
            ns           => [@{$opts{'ns'}}, $field_name],
            gns          => $field->{'ns'} . '___',
            model_fields => $subfilter_fields
        )
      };

    $opts{'nonterminals'}->{$expr[0]} = $expr[1];
    push_hs(
        $opts{'nonterminals'},
        $self->{'db_manager'}->$accessor_name->_grammar_nonterminals(
            %opts,
            ns           => [@{$opts{'ns'}}, $field_name],
            model_fields => $subfilter_fields
        )
    );
    $field->{'nonterminals'} = $opts{'nonterminals'};

    push_hs(
        $opts{'tokens'},
        $self->{'db_manager'}->$accessor_name->_grammar_tokens(
            %opts,
            ns           => [@{$opts{'ns'}}, $field_name],
            model_fields => $subfilter_fields
        )
    );
    $field->{'tokens'} = $opts{'tokens'};

    return TRUE;
}

sub need_tokens {return [qw(NOT MATCH)];}

sub tokens {
    my ($self, $field_name, $field) = @_;

    return $field->{'tokens'};
}

sub nonterminals {
    my ($self, $field_name, $field) = @_;

    return $field->{'nonterminals'};
}

sub expressions {
    my ($self, $field_name, $field) = @_;

    my $uc_field_name = uc($field_name);

    return [
        $uc_field_name
          . " MATCH     '{' "
          . ($field->{'ns'} || '')
          . '___expr'
          . " '}' { [$field_name => 'MATCH'     => \$_[4]] }",
        $uc_field_name
          . " NOT MATCH '{' "
          . ($field->{'ns'} || '')
          . '___expr'
          . " '}' { [$field_name => 'NOT MATCH' => \$_[5]] }"
    ];
}

sub check {
    throw gettext('Bad data') if ref($_[1]->[2]) ne 'ARRAY';
    throw gettext('Bad operation "%s"', $_[1]->[1])
      unless in_array($_[1]->[1], ['MATCH', 'NOT MATCH']);
}

sub as_text {
    my ($self, $data, $field, %opts) = @_;

    my $accessor_name = $field->{'model_accessor'};
    return "$_[1]->[0] $_[1]->[1] {"
      . $self->{'db_manager'}->$accessor_name->_get_db_filter_from_data(
        $data->[2], %opts,
        model_fields => $opts{'model_fields'}->{$data->[0]}{'subfields'},
        type         => 'text'
      ) . '}';
}

sub as_filter {
    my ($self, $data, $field, %opts) = @_;

    my $accessor_name = $field->{'model_accessor'};

    my $tmp_rights = $self->{'db_manager'}->app->add_tmp_rights($field->{'add_tmp_rights'})
      if $field->{'add_tmp_rights'};

    return [
        ($field->{'field'} || $data->[0]) => ($data->[1] =~ /NOT/ ? '<> ALL' : '= ANY') =>
          $self->{'db_manager'}->$accessor_name->query(
            fields => $self->{'db_manager'}->$accessor_name->_get_fields_obj(
                exists($field->{'fk_field'})
                ? [$field->{'fk_field'}]
                : $self->{'db_manager'}->$accessor_name->get_pk_fields()
            ),
            filter => $self->{'db_manager'}->$accessor_name->_get_db_filter_from_data(
                $data->[2], %opts,
                model_fields => $opts{'model_fields'}->{$data->[0]}{'subfields'},
                type         => 'filter'
            )
          )
    ];
}

TRUE;

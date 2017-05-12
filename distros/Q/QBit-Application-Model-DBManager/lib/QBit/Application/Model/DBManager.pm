package Exception::DBManager::Grammar;
$Exception::DBManager::Grammar::VERSION = '0.017';
use base qw(Exception);

package QBit::Application::Model::DBManager;
$QBit::Application::Model::DBManager::VERSION = '0.017';
use qbit;

use base qw(QBit::Application::Model);

use QBit::Application::Model::DBManager::_Utils::Fields;
use QBit::Application::Model::DBManager::Filter;

use Parse::Eyapp;

__PACKAGE__->abstract_methods(qw(query add));

sub model_fields {
    my ($class, %fields) = @_;

    my $fields = \%fields;
    my $inited_fields;

    package_stash($class)->{'__MODEL_FIELDS__'} = $fields;

    package_stash($class)->{'__MODEL_FIELDS_INITIALIZED__'} = $inited_fields =
      QBit::Application::Model::DBManager::_Utils::Fields->init_fields($fields);

    package_stash($class)->{'__MODEL_FIELDS_SORT_ORDERS__'} =
      QBit::Application::Model::DBManager::_Utils::Fields->init_field_sort($inited_fields);
}

sub model_filter {
    my ($class, %opts) = @_;

    my $pkg_stash = package_stash($class);
    $pkg_stash->{'__DB_FILTER__'} = $opts{'fields'} || return;

    $pkg_stash->{'__DB_FILTER_DBACCESSOR__'} = $opts{'db_accessor'} || 'db';
    throw Exception::BadArguments gettext("Cannot find DB accessor %s, package %s",
        $pkg_stash->{'__DB_FILTER_DBACCESSOR__'}, $class)
      unless $class->can($pkg_stash->{'__DB_FILTER_DBACCESSOR__'});

}

sub get_model_fields {
    my ($self) = @_;

    return package_stash(ref($self))->{'__MODEL_FIELDS__'};
}

sub get_db_filter_fields {
    my ($self, %opts) = @_;

    my $filter_fields = package_stash(ref($self))->{'__DB_FILTER__'};

    if (exists($opts{fields})) {
        foreach my $field (@{$opts{fields}}) {
            throw Exception::BadArguments gettext('Filter by unknown field "%s" in model %s', $field, ref($self))
              unless exists($filter_fields->{$field});
        }
    }
    my @fields = exists($opts{fields}) ? (@{delete($opts{fields})}) : (keys %$filter_fields);

    foreach my $field (@fields) {
        my $fdata = $filter_fields->{$field};

        throw Exception::BadArguments gettext('Missed filter type (package: "%s", filter: "%s")', ref($self), $field)
          unless defined($fdata->{'type'});
        my $filter_class = 'QBit::Application::Model::DBManager::Filter::' . $fdata->{'type'};    #delete(
        my $filter_fn    = "$filter_class.pm";
        $filter_fn =~ s/::/\//g;
        require $filter_fn or throw $!;

        $self->{'__DB_FILTER__'}{$field} = $filter_class->new(%$fdata, field_name => $field, db_manager => $self);
    }

    my %fields = %{clone(package_stash(ref($self))->{'__DB_FILTER__'}) || {}};

    foreach my $field (@fields) {
        my $save = TRUE;

        $save = $self->{'__DB_FILTER__'}{$field}->pre_process($fields{$field}, $field, %opts)
          if $self->{'__DB_FILTER__'}{$field}->can('pre_process');

        unless ($save) {
            delete($fields{$field});
            next;
        }

        $fields{$field}->{'label'} = $fields{$field}->{'label'}()
          if exists($fields{$field}->{'label'}) && ref($fields{$field}->{'label'}) eq 'CODE';

        $fields{$field} =
          {hash_transform($fields{$field}, [qw(type label), @{$self->{'__DB_FILTER__'}{$field}->public_keys || []}])}
          unless $opts{'private'};
    }

    return \%fields;
}

sub get_db_filter_simple_fields {
    my ($self, %opts) = @_;

    $opts{'fields'} = $self->get_db_filter_fields() unless exists($opts{'fields'});

    my @res;
    while (my ($name, $value) = each(%{$opts{'fields'}})) {
        push(@res, {name => $name, label => $value->{'label'}})
          if $self->{'__DB_FILTER__'}{$name}->is_simple;
    }

    return \@res;
}

sub get_all {
    my ($self, %opts) = @_;

    $self->timelog->start(gettext('%s: get_all', ref($self)));

    my $fields = $self->_get_fields_obj($opts{'fields'}, $opts{'all_locales'});

    my $last_fields = $fields->get_fields();
    foreach ($fields->need_delete) {
        # Hide unavailable fields
        delete($last_fields->{$_});
    }

    my $query = $self->query(
        fields => $fields,
        filter => $self->get_db_filter($opts{'filter'}),
    )->all_langs($opts{'all_locales'});

    $query->distinct   if $opts{'distinct'};
    $query->for_update if $opts{'for_update'};

    if ($opts{'order_by'}) {
        my $all_fields = $self->_get_fields_obj([keys(%{$self->get_model_fields()})]);

        my %db_fields = map {$_ => TRUE} keys(%{$all_fields->get_db_fields()});

        my @order_by = map {[ref($_) ? ($_->[0], $_->[1]) : ($_, 0)]}
          grep {exists($db_fields{ref($_) ? $_->[0] : $_})} @{$opts{'order_by'}};

        $query->order_by(@order_by) if @order_by;
    }

    $query->limit($opts{'offset'}, $opts{'limit'}) if $opts{'limit'};

    $query->calc_rows(1) if $opts{'calc_rows'};

    my $result = $query->get_all();

    $self->{'__FOUND_ROWS__'} = $query->found_rows() if $opts{'calc_rows'};

    if (@$result) {
        $self->timelog->start(gettext('Preprocess fields'));
        $self->pre_process_fields($fields, $result);
        $self->timelog->finish();

        $self->timelog->start(gettext('Process data'));
        $result = $fields->process_data($result);
        $self->timelog->finish();
    }

    $self->{'__LAST_FIELDS__'} = $last_fields;

    $self->timelog->finish();

    return $result;
}

sub found_rows {
    my ($self) = @_;

    return $self->{'__FOUND_ROWS__'};
}

sub last_fields {
    my ($self) = @_;

    return $self->{'__LAST_FIELDS__'};
}

sub get_all_with_meta {
    my ($self, %opts) = @_;

    my %meta_opts = map {$_ => TRUE} @{delete($opts{'meta'}) || []};
    $opts{'calc_rows'} = TRUE if $meta_opts{'found_rows'};

    my $data = $self->get_all(%opts);

    my %meta;
    $meta{'last_fields'} = [keys(%{$self->last_fields()})] if $meta_opts{'last_fields'};
    $meta{'found_rows'}  = $self->found_rows()             if $meta_opts{'found_rows'};

    return {
        data => $data,
        meta => \%meta,
    };
}

sub get {
    my ($self, $pk, %opts) = @_;

    return undef unless defined($pk);

    my $pk_fields = $self->get_pk_fields();

    $pk = {$pk_fields->[0] => $pk} if ref($pk) ne 'HASH';

    my @missed_fields = grep {!exists($pk->{$_})} @$pk_fields;
    throw Exception::BadArguments gettext("Invalid primary key fields") if @missed_fields;

    return $self->get_all(%opts, filter => [AND => [map {[$_ => '=' => $pk->{$_}]} @$pk_fields]])->[0];
}

sub get_pk_fields {
    my ($self) = @_;

    my $fields = $self->get_model_fields();

    return [sort {$a cmp $b} grep {$fields->{$_}{'pk'}} keys(%$fields)];
}

sub get_db_filter {
    my ($self, $data, %opts) = @_;

    return undef unless defined($data);

    return ref($data) ? $self->_get_db_filter_from_data($data, %opts) : $self->_get_db_filter_from_text($data, %opts);
}

sub pre_process_fields { }

sub _get_fields_obj {
    my ($self, $fields, $all_locales) = @_;

    my $stash = package_stash(ref($self));

    return QBit::Application::Model::DBManager::_Utils::Fields->new(
        $stash->{'__MODEL_FIELDS_INITIALIZED__'},
        $stash->{'__MODEL_FIELDS_SORT_ORDERS__'},
        $fields, $self, $all_locales
    );
}

sub _db {
    my ($self) = @_;

    my $accessor_name = package_stash(ref($self))->{'__DB_FILTER_DBACCESSOR__'};

    return $self->$accessor_name;
}

sub _get_db_filter_from_data {
    my ($self, $data, %opts) = @_;

    return undef unless $data;

    return [AND => [undef]] if ref($data) && ref($data) eq 'ARRAY' && @$data == 1 && !defined($data->[0]);

    return $self->_get_db_filter_from_data([AND => [map {[$_ => '=' => $data->{$_}]} keys(%$data)]], %opts)
      if ref($data) eq 'HASH';

    if (ref($data) eq 'ARRAY' && @$data == 2 && ref($data->[1]) eq 'ARRAY') {
        throw Exception::BadArguments gettext('Unknow operation "%s"', uc($data->[0]))
          unless in_array(uc($data->[0]), [qw(OR AND)]);

        return ($opts{'type'} || '') eq 'text'
          ? '(' . join(' ' . uc($data->[0]) . ' ', map {$self->_get_db_filter_from_data($_, %opts)} @{$data->[1]}) . ')'
          : $self->_db()
          ->filter([uc($data->[0]) => [map {$self->_get_db_filter_from_data($_, %opts)->expression()} @{$data->[1]}]]);
    } elsif (ref($data) eq 'ARRAY' && @$data == 3) {
        my $field = $data->[0];
        $opts{'model_fields'}{$field} ||= $self->get_db_filter_fields(private => TRUE, fields => [$field])->{$field};
        my $model_fields = $opts{'model_fields'};

        throw Exception::BadArguments gettext('Unknown field "%s"', $field)
          unless defined($model_fields->{$field});

        $self->{'__DB_FILTER__'}{$field}->check($data, $model_fields->{$field})
          if $self->{'__DB_FILTER__'}{$field}->can('check');

        return ($opts{'type'} || '') eq 'text'
          ? $self->{'__DB_FILTER__'}{$field}->as_text($data, $model_fields->{$field}, %opts)
          : return $self->_db()->filter(
              $model_fields->{$field}{'db_filter'}
            ? $model_fields->{$field}{'db_filter'}($self, $data, $model_fields->{$field}, %opts)
            : $self->{'__DB_FILTER__'}{$field}->as_filter($data, $model_fields->{$field}, %opts)
          );

    } else {
        throw Exception::BadArguments gettext('Bad filter data');
    }
}

sub _get_db_filter_from_text {
    my ($self, $data, %opts) = @_;

    my $pkg_stash    = package_stash(ref($self));
    my $db_accessor  = $pkg_stash->{'__DB_FILTER_DBACCESSOR__'};
    my $model_fields = $opts{'model_fields'} ||= $self->get_db_filter_fields(private => TRUE);

    my $grammar = <<EOF;
%{
use qbit;
no warnings 'redefine';
%}

%whites = /([ \\t\\r\\n]*)/
EOF

    my %tokens = %{$self->_grammar_tokens(%opts, model_fields => $model_fields)};
    $tokens{$_} = QBit::Application::Model::DBManager::Filter::tokens($_) foreach qw(AND OR);

    $grammar .= "\n%token $_ = {\n    $tokens{$_}->{'re'};\n}\n"
      foreach sort {$tokens{$b}->{'priority'} <=> $tokens{$a}->{'priority'}} keys(%tokens);

    $grammar .= <<EOF;

%left OR
%left AND

%tree
#%strict

%%
start:      expr { \$_[1] }
        ;
EOF

    my @expr = %{$self->_grammar_expr(%opts, model_fields => $model_fields)};
    $grammar .= "\n$expr[0]: $expr[1]";

    my $nonterminals = $self->_grammar_nonterminals(%opts, model_fields => $model_fields);
    $grammar .= "\n\n$_: $nonterminals->{$_}" foreach keys(%$nonterminals);

    $grammar .= "\n%%";

    my $grammar_class_name = ref($self) . '::Grammar';

    my $p = Parse::Eyapp->new_grammar(
        input     => $grammar,
        classname => $grammar_class_name,
    );
    throw $p->Warnings if $p->Warnings;

    my $parser = $grammar_class_name->new();
    $parser->{'__DB__'}    = $self->$db_accessor;
    $parser->{'__MODEL__'} = $self;
    $parser->input(\$data);

    my $filter = $parser->YYParse(
        yyerror => sub {
            my $token = $_[0]->YYCurval();

            my $text = gettext(
                'Syntax error near "%s". Expected one of these tokens: %s',
                $token ? $token : gettext('end of input'),
                join(', ', $_[0]->YYExpect())
            );
            throw Exception::DBManager::Grammar $text;
        }
    );

    return $filter if ($opts{'type'} || '') eq 'json_data';

    return $self->_get_db_filter_from_data(
        $filter, %opts,
        model_fields => $model_fields,
        db_accessor  => $db_accessor
    );
}

sub _grammar_tokens {
    my ($self, %opts) = @_;

    my %tokens;

    foreach my $field_name (keys(%{$opts{'model_fields'}})) {
        $tokens{uc($field_name)} = {
            re       => "/\\G(" . uc($field_name) . ")/igc and return (" . uc($field_name) . " => \$1)",
            priority => length($field_name)
        };

        foreach my $token (@{$self->{'__DB_FILTER__'}{$field_name}->need_tokens || []}) {
            $tokens{$token} = QBit::Application::Model::DBManager::Filter::tokens($token);
        }

        push_hs(%tokens,
            $self->{'__DB_FILTER__'}{$field_name}->tokens($field_name, $opts{'model_fields'}->{$field_name}, %opts))
          if $self->{'__DB_FILTER__'}{$field_name}->can('tokens');
    }

    return \%tokens;
}

sub _grammar_nonterminals {
    my ($self, %opts) = @_;

    my %nonterminals;

    foreach my $field_name (keys(%{$opts{'model_fields'}})) {
        push_hs(%nonterminals,
            $self->{'__DB_FILTER__'}{$field_name}
              ->nonterminals($field_name, $opts{'model_fields'}->{$field_name}, %opts))
          if $self->{'__DB_FILTER__'}{$field_name}->can('nonterminals');
    }

    return \%nonterminals;
}

sub _grammar_expr {
    my ($self, %opts) = @_;

    $opts{'gns'} ||= '';

    my $res =
"$opts{'gns'}expr AND $opts{'gns'}expr { QBit::Application::Model::DBManager::Filter::__merge_expr(\$_[1], \$_[3], 'AND') }
        |   $opts{'gns'}expr OR $opts{'gns'}expr  { QBit::Application::Model::DBManager::Filter::__merge_expr(\$_[1], \$_[3], 'OR') }
        |    '(' $opts{'gns'}expr ')' { \$_[2] }\n";

    foreach my $field_name (keys(%{$opts{'model_fields'}})) {
        $res .= "        |   " . $_ . "\n"
          foreach
          @{$self->{'__DB_FILTER__'}{$field_name}->expressions($field_name, $opts{'model_fields'}->{$field_name}, %opts)
              || []};
    }

    $res .= "        ;";

    return {"$opts{'gns'}expr" => $res};
}

TRUE;

__END__

=encoding utf8

=head1 Name
 
QBit::Application::Model::DBManager - Class for smart working with DB.
 
=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-DBManager

=head1 Install

=over
 
=item *

cpanm QBit::Application::Model::DBManager

=item *

apt-get install libqbit-application-model-dbmanager-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut

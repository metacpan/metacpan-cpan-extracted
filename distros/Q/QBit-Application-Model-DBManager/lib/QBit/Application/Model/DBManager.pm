
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

=head1 Package methods

=cut

package QBit::Application::Model::DBManager;
$QBit::Application::Model::DBManager::VERSION = '0.021';
use qbit;

use base qw(QBit::Application::Model);

use QBit::Application::Model::DBManager::_Utils::Fields;
use QBit::Application::Model::DBManager::Filter;

use Parse::Eyapp;

use Exception::DBManager::Grammar;

__PACKAGE__->abstract_methods(qw(query add));

=head2 remove_model_fields

Removes the model fields. Use this method if you want to set an entirely different set of fields for the model.

B<No arguments>

B<Return value:> $model_fields (type: ref of a hash)

B<Example:>

  my $model_fields = $app->users->remove_model_fields();
  
  # set new fields.
  $app->users->model_fields(...);

=cut

sub remove_model_fields {
    my ($self) = @_;

    my $stash = package_stash(ref($self) || $self);

    delete(
        @$stash{
            qw(
              __MODEL_FIELDS_INITIALIZED__
              __MODEL_FIELDS_SORT_ORDERS__
              )
        }
    );

    return delete($stash->{'__MODEL_FIELDS__'});
}

=head2 model_fields

Set model fields. Save into package stash with key __MODEL_FIELDS__

B<Arguments:>

=over

=item *

B<%fields> - Fields (type: hash)

=back

B<Example:>

  package Sellers;

  use base qw(QBit::Application::Model::DBManager);

  __PACKAGE__->model_accessors(
      db    => 'Application::Model::DB',    # your DB model, see QBit::Application::Model::DB
      items => 'Application::Model::Items', # your model (base from QBit::Application::Model::DBManager)
  );

  __PACKAGE__->model_fields(
      id => {
          pk      => TRUE,      # primary key for this model
          db      => 'sellers', # this field is from the table
          default => TRUE,      # this field returns if fields were not requested
      },
      caption => {
          db           => 'sellers', # this field is from the table
          default      => TRUE,      # this field returns if fields were not requested
          i18n         => TRUE,      # this field depends on current locale, (in DB this field i18n too)
          check_rights => 'sellers_view_field__caption',
          # your right for "caption", see check_rights from QBit::Application
          # Try not to use this key.
      },
      id_with_caption => {
          depends_on => [qw(id caption)], # this field depends on "id" and "caption"
          get => sub {
              my $fields = shift; # object QBit::Application::Model::DBManager::_Utils::Fields
              # access to model: $fields->model

              my $row = shift; # hash from db: {id => 1, caption => 'Happy Milkman'}

              return $row->{'id'} . ': ' . $row->{'caption'};
          }
      },
      id_with_caption_db => {
          db => 'sellers',
          db_expr => {CONCAT => ['id', \': ', 'caption']}, # see QBit::Application::Model::DB::Query
      },
      name => {
          # relation "one to one". Use it if you want use join
          db => 'users', # this field is from the table, but the tables are different
      },
      items => {
          # relation "one to one", "one to many" or "many to many"
          depends_on => [qw(id)],
          get => sub {
              my $fields = shift; # object QBit::Application::Model::DBManager::_Utils::Fields
              my $row = shift; # hash from db: {id => 1}

              # $fields->{'__ITEMS__'} created in pre_process_fields
              return $fields->{'__ITEMS__'}{$row->{'id'}} // [];
          }
      }
  );

  # returns query (class: QBit::Application::Model::DB::Query)
  sub query {
      my ($self, %opts) = @_;

      my $filter = $self->db->filter($opts{'filter'});

      unless ($self->check_rights('sellers_view_all')) {
          my $cur_user = $self->cur_user();

          $filter->and({user_id => $cur_user->{'id'}};
      }

      my $query = $self->db->query->select(
          table  => $self->db->sellers,
          fields => $opts{'fields'}->get_db_fields('sellers'), # returns db expression for fields with "db" = 'sellers'
          filter => $filter
      );

      my $users_fields = $opts{'fields'}->get_db_fields('users');

      # join users only if needed (field "name" was requested)
      $query->join(
          table  => $self->db->users,
          fields => $users_fields,
      ) if %$users_fields;

      return $query;
  }

  # used for dictionaries
  sub pre_process_fields {
      my $self   = shift; # model
      my $fields = shift; # object QBit::Application::Model::DBManager::_Utils::Fields
      my $result = shift; # data from db

      if ($fields->need('items')) {
          # gets items only if needed (field "items" was requested)

          my $items = $self->items->get_all(
              fields => [qw(id seller_id caption)],
              filter => {seller_id => [map {$_->{'id'}} @$result]}, # key "id" exists because fields "items" depends on "id"
          );

          # create dictionaries {<SELLER_ID> => <ITEM>}
          $fields->{'__ITEMS__'} = {map {$_->{'seller_id'} => $_} @$items};
      }
  }

  TRUE;

  # in your code

  my $sellers = $app->sellers->get_all(fields => [qw(id id_with_caption_db name items)]);

  #$sellers = [
  #    {
  #        id => 1,
  #        id_with_caption_db => '1: Happy Milkman',
  #        name  => 'Petr Ivanovich',
  #        items => [
  #            {
  #                id        => 1,
  #                seller_id => 1,
  #                caption   => 'milk'
  #            },
  #            {
  #                id        => 2,
  #                seller_id => 1,
  #                caption   => 'cheese'
  #            },
  #        ],
  #    }
  #]

=cut

sub model_fields {
    my ($class, %fields) = @_;

    my $stash_fields = package_stash($class)->{'__MODEL_FIELDS__'} // {};
    package_stash($class)->{'__MODEL_FIELDS__'} = $stash_fields = {%$stash_fields, %fields};

    my $inited_fields;

    package_stash($class)->{'__MODEL_FIELDS_INITIALIZED__'} = $inited_fields =
      QBit::Application::Model::DBManager::_Utils::Fields->init_fields($stash_fields);

    package_stash($class)->{'__MODEL_FIELDS_SORT_ORDERS__'} =
      QBit::Application::Model::DBManager::_Utils::Fields->init_field_sort($inited_fields);
}

=head2 model_filter

Set model filters. Save into package stash with key __DB_FILTER__

B<Types:> namespace (QBit::Application::Model::DBManager::Filter)

=over

=item

boolean

=item

dictionary

=item

multistate

=item

number

=item

subfilter

=item

text

=back

B<Arguments:>

=over

=item *

B<%opts> - Options (type: hash)

=over

=item

db_accessor - name db accessor

=item

fields - filter fields

=back

=back

B<Example:>

  __PACKAGE__->model_filter(
      db_accessor => 'db', # your db accessor
      fields      => {
          id      => {type => 'number'},
          caption => {type => 'text'},
          active  => {type => 'boolean'},
          product => {
              type   => 'dictionary',
              values => sub {
                  [
                      {id => 1, label => gettext('Milk')},
                      {id => 2, label => gettext('Cheese')},
                  ];
              },
          }
          multistate => {type => 'multistate'},
          # you can filtered by field from other model
          user       => {
              type           => 'subfilter',
              model_accessor => 'users',   # accessor related model
              field          => 'user_id', # field from this model
              fk_field       => 'id',      # field from model "users"
          },
      },
  );

  # in your code

  my $items = $app->model->get_all(
      filter => [
          'OR',
          [
              ['id',      '=',    1],
              ['caption', 'LIKE', 'Nike'],
              ['active',  '=',    1],
              ['product', '=', [1, 2]],
              ['multistate', '=', 'approved and working'],
              ['user', 'MATCH', ['login', '=', 'ChuckNorris']] # login is a filter in model "users"
          ]
      ]
  );

=cut

sub model_filter {
    my ($class, %opts) = @_;

    my $pkg_stash = package_stash($class);

    $pkg_stash->{'__DB_FILTER__'} //= {};
    $pkg_stash->{'__DB_FILTER__'} = {%{$pkg_stash->{'__DB_FILTER__'}}, %{$opts{'fields'}}};

    $pkg_stash->{'__DB_FILTER_DBACCESSOR__'} = $opts{'db_accessor'} || $pkg_stash->{'__DB_FILTER_DBACCESSOR__'} || 'db';
    throw Exception::BadArguments gettext("Cannot find DB accessor %s, package %s",
        $pkg_stash->{'__DB_FILTER_DBACCESSOR__'}, $class)
      unless $class->can($pkg_stash->{'__DB_FILTER_DBACCESSOR__'});
}

=head2 get_model_fields

Returns a model fields.

B<No arguments.>

B<Return value:> $model_fields (type: ref of a hash)

B<Example:>

  my $model_fields = $app->model->get_model_fields(); # getter for method "model_fields"

=cut

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

=head2 get_all

Returns model items.

B<Arguments:>

=over

=item

B<%opts> - Options (type: hash)

=over

=item

fields

  returns "id" and "caption"
  my $data = $app->model->get_all(fields => [qw(id caption)]);

  # returns fields with key "default"
  my $data = $app->model->get_all();

  # return all fields
  my $data = $app->model->get_all(fields => ['*']);

=item

filter - see QBit::Application::Model::DB::Query. Unlike filters from the database, model filters can not use field names and scalars are used without reference.

  # mysql: name = caption
  # db:    ['name', '=', 'caption']
  # model: no way

  # mysql: id = 12
  # db:    ['id', '=', \12]
  # model: ['id', '=', 12]

  my $data = $app->model->get_all(filter => {id => 1});

=item

distinct - unique rows from table

  my $data = $app->model->get_all(fields => [qw(caption)], distinct => TRUE);

=item

for_update - get lock

  # get
  my $data = $app->model->get_all(fields => [qw(id)], filter => ["caption", "LIKE", "milk"]}, for_update => TRUE);

  # update
  $app->db->table->edit($app->db->filter({id => [map {$_->{'id'}} @$data]}), {caption => 'Milk'});

=item

order_by - set order

  my $data = $app->model->get_all(
      fields => [qw(caption)],
      order_by => [
          'caption', # asc
          [
            'price', # field
            1        # order: 0 - asc, 1 - desc
          ]
      ]
  );

=item

limit

  my $data = $app->model->get_all(limit => 100);

=item

offset

  my $data = $app->model->get_all(limit => 100, offset => 1000);

=item

calc_rows

  my $data = $app->model->get_all(limit => 100, calc_rows => TRUE);

  my $all_data = $app->model->found_rows(); # 1_000_000

=item

all_locales

  my $data = $app->model->get_all(fields => [qw(id caption)], all_locales => TRUE);

  #$data = [
  #    {
  #        id      => 1,
  #        caption => {
  #            ru => 'Веселый молочник',
  #            en => 'Happy Milkman',
  #        },
  #    },
  #    ...
  #]

=back

=back

B<Return value:> Data (type: ref of a array)

B<Example:>

  my $data = $app->model->get_all(
      fields => [qw(id caption)],
      filter => ['OR', [
        ['id', '=', 10],
        ['caption', '=', 'milk']
      ]],
      limit    => 100,
      offset   => 10_000,
      order_by => ['caption']
  );

=cut

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

=head2 found_rows

Returns count of a rows.

B<No arguments.>

B<Return value:> $found_rows (type: scalar or undef)

B<Example:>

  my $data = $app->model->get_all(limit => 3, calc_rows => TRUE);

  my $found_rows = $app->model->found_rows();

=cut

sub found_rows {
    my ($self) = @_;

    return $self->{'__FOUND_ROWS__'};
}

=head2 last_fields

Returns a last fields was requested.

B<No arguments.>

B<Return value:> $last_fields (type: scalar or undef)

B<Example:>

  my $data = $app->model->get_all(fields => [qw(id caption)]);

  my $last_fields = $app->model->last_fields();

  # $last_fields = {
  #     id      => '',
  #     caption => '',
  # };

=cut

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

=head2 get

Returns row by primary key.

B<Arguments:>

=over

=item

B<$pk> - primary key (type: scalar or hash)

=item

B<%opts> - options (type: hash; see get_all)

=back

B<Return value:> Row (type: ref of a hash or undef)

B<Example:>

  my $item = $app->model->get(1, fields => [qw(id caption)]);

  # or
  my $item = $app->model->get({id => 1}, fields => [qw(id caption)]);

=cut

sub get {
    my ($self, $pk, %opts) = @_;

    return undef unless defined($pk);

    my $pk_fields = $self->get_pk_fields();

    $pk = {$pk_fields->[0] => $pk} if ref($pk) ne 'HASH';

    my @missed_fields = grep {!exists($pk->{$_})} @$pk_fields;
    throw Exception::BadArguments gettext("Invalid primary key fields") if @missed_fields;

    return $self->get_all(%opts, filter => [AND => [map {[$_ => '=' => $pk->{$_}]} @$pk_fields]])->[0];
}

=head2 get_pk_fields

Returns primary keys.

B<No arguments.>

B<Return value:> fields (type: ref of a array)

B<Example:>

  my $pk = $app->model->get_pk_fields(); # ['id']

=cut

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

=head2 pre_process_fields

used for dictionaries.

B<No arguments.>

B<Return value:> undef

B<Example:>

  # see method: model_fields
  $app->model->pre_process_fields();

=cut

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

    return [AND => [\undef]] if ref($data) && ref($data) eq 'ARRAY' && @$data == 1 && !defined($data->[0]);

    return $self->_get_db_filter_from_data([AND => [map {[$_ => '=' => $data->{$_}]} keys(%$data)]], %opts)
      if ref($data) eq 'HASH';

    if (ref($data) eq 'ARRAY' && @$data == 2 && ref($data->[1]) eq 'ARRAY') {
        throw Exception::BadArguments gettext('Unknow operation "%s"', uc($data->[0]))
          unless in_array(uc($data->[0]), [qw(OR AND)]);

        return ($opts{'type'} || '') eq 'text'
          ? '('
          . join(' ' . uc($data->[0]) . ' ', map {$self->_get_db_filter_from_data($_, %opts)} @{$data->[1]}) . ')'
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

package Mojo::DB::Results::Role::MoreMethods;
use Mojo::Base -role;
use Mojo::Collection;
use Mojo::Util ();

with 'Mojo::DB::Results::Role::Struct';

our $VERSION = '0.04';

requires qw(array arrays columns hash hashes);

sub get {
    my $self = shift;

    my $options = ref $_[0] eq 'HASH' ? shift : {};
    my $die = delete $options->{die};
    my $one = delete $options->{one};
    my @indexes = @_;

    if ($one) {
        Carp::confess 'no rows returned' if $self->rows == 0;
        Carp::confess 'multiple rows returned' if $self->rows > 1;
    }

    my $wantarray = wantarray;
    if (not defined $wantarray) {
        Carp::cluck 'get or get variant called without using return value';

        if ($die or $one) {
            Carp::croak 'no results' unless $self->array;
        } else {
            $self->array;
            return;
        }
    } elsif ($wantarray) {
        my $array = $self->array;
        unless ($array) {
            Carp::confess 'no results' if $die or $one;
            return;
        }

        if (@indexes) {
            $self->_assert_indexes(@indexes);

            return @$array[@indexes];
        } else {
            return @$array;
        }
    } else {
        Carp::confess 'multiple indexes passed for single requested get value' if @indexes > 1;

        my $array = $self->array;
        unless ($array) {
            Carp::confess 'no results' if $die or $one;
            return;
        }

        my $index = $indexes[0] // 0;
        $self->_assert_indexes($index);

        return $array->[$index];
    }
}

sub get_by_name {
    my $self = shift;

    my $options = ref $_[0] eq 'HASH' ? shift : {};
    my @names = @_;
    Carp::croak 'names required' unless @names;

    return $self->get($options, $self->_find_column_indexes(@names));
}

sub c {
    return shift->get(@_) if not defined wantarray;

    my @values = shift->get(@_);
    return @values ? Mojo::Collection->new(@values) : undef;
}

sub c_by_name {
    return shift->get_by_name(@_) if not defined wantarray;

    my @values = shift->get_by_name(@_);
    return @values ? Mojo::Collection->new(@values) : undef;
}

sub collections { Mojo::Collection->new(map { Mojo::Collection->new(@$_) } @{ shift->arrays }) }

sub flatten { shift->arrays->flatten }

sub hashify {
    my $self = shift;
    my ($collection, $get_keys, $get_value) = $self->_parse_transform_options({}, @_);

    return $collection->with_roles('+Transform')->hashify($get_keys, $get_value);
}

sub hashify_collect {
    my ($collection, $get_keys, $get_value, $flatten) = shift->_parse_transform_options({flatten_allowed => 1}, @_);

    return $collection->with_roles('+Transform')->hashify_collect({flatten => $flatten}, $get_keys, $get_value);
}

sub collect_by {
    my ($collection, $get_keys, $get_value, $flatten) = shift->_parse_transform_options({flatten_allowed => 1}, @_);

    return $collection->with_roles('+Transform')->collect_by({flatten => $flatten}, $get_keys, $get_value);
}

sub _parse_transform_options {
    my $self = shift;
    my $private_options = shift;
    my $options = ref $_[0] eq 'HASH' ? shift : {};

    my ($key, $key_ref)                       = _parse_and_validate_transform_key(shift);
    my ($value, $value_is_column, $value_ref) = _parse_and_validate_transform_value(@_);

    my ($type, $flatten) = _parse_and_validate_transform_options($private_options, $options);

    # if user will not access the rows and the type won't be used, default rows to arrays for speed
    if (($value_is_column or $flatten) and $key_ref ne 'CODE' and $value_ref ne 'CODE') {
        if ($type and $type ne 'array') {
            Carp::cluck 'Useless type option provided. array will be used for performance.';
        }
        $type = 'array';
    } elsif (not $type) {
        $type = 'hash';
    }

    my $get_keys   = $key_ref eq 'CODE'   ? $key : $self->_create_get_keys_sub($type, $key);
    my $get_value  = $value_ref eq 'CODE' ? $value
                   : $value_is_column     ? $self->_create_column_value_getter($type, $value)
                   : $flatten             ? $self->_create_flatten_value_getter($type)
                   : sub { $_ }
                   ;
    my $collection = $type eq 'array' ? $self->arrays
                   : $type eq 'c'     ? $self->collections
                   : $type eq 'hash'  ? $self->hashes
                   : $self->structs
                   ;

    return $collection, $get_keys, $get_value, $flatten;
}

sub _parse_and_validate_transform_key {
    my ($key) = @_;

    my $key_ref = ref $key;
    if ($key_ref) {
        Carp::confess qq{key must be an arrayref, a sub or a non-empty string, but had ref '$key_ref'}
            unless $key_ref eq 'ARRAY' or $key_ref eq 'CODE';

        if ($key_ref eq 'ARRAY') {
            Carp::confess 'key array must not be empty' unless @$key;
            Carp::confess 'key array elements must be defined and non-empty' if grep { not defined or $_ eq '' } @$key;
        }
    } else {
        Carp::confess 'key was undefined or an empty string' unless defined $key and $key ne '';
        $key = [$key];
    }

    return $key, $key_ref;
}

sub _parse_and_validate_transform_value {
    my ($value, $value_is_column);

    my $value_ref;
    if (@_ == 1) {
        $value = shift;

        $value_ref = ref $value;
        if ($value_ref) {
            Carp::confess qq{value must be a sub or non-empty string, but was '$value_ref'} unless $value_ref eq 'CODE';
        } elsif (not defined $value or $value eq '') {
            Carp::confess 'value must not be undefined or an empty string';
        } else {
            $value_is_column = 1;
        }
    } elsif (@_ > 1) {
        Carp::confess 'too many arguments provided (more than one value)';
    }

    return $value, $value_is_column, $value_ref // '';
}

sub _parse_and_validate_transform_options {
    my ($private_options, $options) = @_;

    my $flatten;
    if ($private_options->{flatten_allowed}) {
        $flatten = delete $options->{flatten};
    } else {
        Carp::confess 'flatten not allowed' if exists $options->{flatten};
    }

    my $flatten_allowed_text = $private_options->{flatten_allowed} ? 'In addition to flatten, ' : '';
    Carp::confess "${flatten_allowed_text}one key/value pair is allowed for options"
        if keys %$options > 1;

    my $type;
    if (%$options) {
        ($type) = keys %$options;

        my @valid_types = qw(array c hash struct);
        Carp::confess "${flatten_allowed_text}option must be one of: @{[ join ', ', @valid_types ]}"
            unless grep { $type eq $_ } @valid_types;
    }

    return $type, $flatten;
}

sub _create_get_keys_sub {
    my ($self, $type, $key) = @_;

    if ($type eq 'array' or $type eq 'c') {
        my @key_indexes = $self->_find_column_indexes(@$key);
        return sub { @{$_}[@key_indexes] };
    } elsif ($type eq 'hash') {
        # assert columns exist
        $self->_find_column_indexes(@$key);

        return sub { @{$_}{@$key} };
    } else {
        # assert columns exist
        $self->_find_column_indexes(@$key);

        return sub {
            map { $_[0]->${\$_} } @$key
        };
    }
}

sub _create_column_value_getter {
    my ($self, $type, $value) = @_;

    if ($type eq 'array' or $type eq 'c') {
        my $column_index = $self->_find_column_indexes($value);
        return sub { $_->[$column_index] };
    } elsif ($type eq 'hash') {
        # assert that column exists
        $self->_find_column_indexes($value);

        return sub { $_->{$value} };
    } else {
        # assert that column exists
        $self->_find_column_indexes($value);

        return sub { $_->${\$value} };
    }
}

sub _create_flatten_value_getter {
    my ($self, $type) = @_;

    if ($type eq 'array' or $type eq 'c') {
        return sub { @$_ };
    } elsif ($type eq 'hash') {
        my $columns = $self->columns;
        return sub { @{$_}{@$columns} };
    } else {
        my $columns = $self->columns;
        return sub {
            my $struct = $_;
            map { $struct->${\$_} } @$columns;
        };
    }
}

sub get_or_die { shift->get({die => 1}, @_) }

sub get_by_name_or_die { shift->get_by_name({die => 1}, @_) }

sub c_or_die { shift->c({die => 1}, @_) }

sub c_by_name_or_die { shift->c_by_name({die => 1}, @_) }

sub struct_or_die { $_[0]->_type_or_die('struct') }

sub array_or_die { $_[0]->_type_or_die('array') }

sub hash_or_die { $_[0]->_type_or_die('hash') }

sub _type_or_die {
    my ($self, $type) = @_;
    if (not defined wantarray) {
        Carp::cluck "${type}_or_die called without using return value";
    }

    Carp::croak 'no results' unless my $value = shift->$type;
    return $value;
}

sub one { shift->get({one => 1}, @_) }

sub one_by_name { shift->get_by_name({one => 1}, @_) }

sub one_c { shift->c({one => 1}, @_) }

sub one_c_by_name { shift->c_by_name({one => 1}, @_) }

sub one_struct { $_[0]->_one_type('struct') }

sub one_array { $_[0]->_one_type('array') }

sub one_hash { $_[0]->_one_type('hash') }

sub _one_type {
    my ($self, $type) = @_;

    Carp::confess 'no rows returned' if $self->rows == 0;
    Carp::confess 'multiple rows returned' if $self->rows > 1;

    return $self->$type;
}

sub _find_column_indexes {
    my $columns = shift->columns;

    return map { _find_column_index($columns, $_) } @_;
}

sub _find_column_index {
    my ($columns, $column) = @_;

    my @indexes = grep { $columns->[$_] eq $column } 0..$#$columns;
    Carp::confess "could not find column '$column' in returned columns" unless @indexes;
    Carp::confess "more than one column named '$column' in returned columns" if @indexes > 1;

    return $indexes[0];
}

sub _assert_indexes {
    my ($self, @indexes) = @_;

    my $num_columns = @{ $self->columns };
    Carp::croak 'cannot index into a size zero results array' if $num_columns == 0;

    for my $index (@indexes) {
        Carp::croak "index out of valid range -$num_columns to @{[ $num_columns - 1 ]}"
            unless $index >= -$num_columns and $index < $num_columns;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::DB::Results::Role::MoreMethods - More methods for DB Results, like Mojo::Pg::Results and Mojo::mysql::Results

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-DB-Results-Role-MoreMethods"><img src="https://travis-ci.org/srchulo/Mojo-DB-Results-Role-MoreMethods.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Results-Role-MoreMethods?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Results-Role-MoreMethods/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  my $db = Mojo::Pg->new(...)

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123})->with_roles('+MoreMethods');
  my $name    = $results->get;
  my $name    = $results->get(0);
  my $name    = $results->get(-3);
  my ($name)  = $results->get;

  my ($name, $age, $favorite_food)  = $results->get;
  my ($name, $age, $favorite_food)  = $results->get(0..2);
  my ($name, $favorite_food)        = $results->get(0, 2);
  my ($name, $favorite_food)        = $results->get(-3, -1);

  my $name   = $results->get_by_name('name');
  my ($name) = $results->get_by_name('name');
  my ($name, $favorite_food) = $results->get_by_name('name', 'favorite_food');

  while (my ($name, $favorite_food) = $results->get('name', 'favorite_food')) {
      say qq{$name's favorite food is $favorite_food};
  }

  # get the next row as a Mojo::Collection
  my $results   = $db->select(people => ['first_name', 'middle_name', 'last_name'])->with_roles('+MoreMethods');
  my $full_name = $results->c->join(' ');

  # or get collection values by name
  my $first_and_last_name = $results->c_by_name('first_name', 'last_name')->join(' ');

  # get all rows as collections in a Mojo::Collection
  my $full_names = $results->collections->map(sub { $_->join(' ') });

  # assert that exactly one row is returned where expected (not 0, not more than one)
  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123})->with_roles('+MoreMethods');
  my $name    = $results->one;
  my ($name, $age, $favorite_food) = $results->one;
  my ($name, $favorite_food)       = $results->one_by_name('name', 'favorite_food');

  # Flatten results into one Mojo::Collection with names of all people who like Pizza
  my $results = $db->select(people => ['name'] => {favorite_food => 'Pizza'})->with_roles('+MoreMethods');
  my $names   = $results->flatten;
  say 'Pizza lovers:';
  say for $names->each;

  # access results by a key
  my $results = $db->select(people => '*')->with_roles('+MoreMethods');
  my $results_by_name = $results->hashify('name');

  # $alice_row is a hash
  my $alice_row = $results_by_name->{Alice};

  # access results by multiple keys with a multilevel hash
  my $results_by_full_name = $results->hashify(['first_name', 'last_name']);

  # $alice_smith_row is a hash
  my $alice_smith_row = $results_by_full_name->{Alice}{Smith};

  # collect results by a key in a Mojo::Collection behind a hash
  my $results = $db->select(people => '*')->with_roles('+MoreMethods');
  my $collections_by_name = $results->hashify_collect('name');

  # $alice_collection is a Mojo::Collection of all rows with the name 'Alice' as hashes
  my $alice_collection = $collections_by_name->{Alice};

  # collect results by multiple keys in a Mojo::Collection behind a multilevel hash
  my $collections_by_full_name = $results->hashify_collect(['first_name', 'last_name']);

  # $alice_smith_row is a hash
  my $alice_smith_collection = $collections_by_full_name->{Alice}{Smith};

  # create a Mojo::Collection of Mojo::Collection's, where all results that share the same key
  # are grouped in the same inner Mojo::Collection
  my $results = $db->select(people => '*')->with_roles('+MoreMethods');
  my $name_collections = $results->collect_by('name');

  for my $name_collection ($name_collections->each) {

    say 'Ages for ' . $name_collection->[0]{name};
    for my $row ($name_collection->each) {
      say "$row->{name} is $row->{age} years old";
    }
  }

=head1 DESCRIPTION

L<Mojo::DB::Results::Role::MoreMethods> is a role that that provides additional methods for results classes
like L<Mojo::Pg::Results> or L<Mojo::mysql::Results>.

L<Mojo::DB::Results::Role::MoreMethods> requires a results class that has at least these methods:

=over 4

=item

array

=item

arrays

=item

columns

=item

hash

=item

hashes

=back

=head1 HOW TO APPLY ROLE

=head2 with_roles

  # apply Mojo::Pg::Results::Role::MoreMethods
  my $pg      = Mojo::Pg->new(...);
  my $results = $pg->db->select(people => ['name'] => {id => 123})->with_roles('+MoreMethods');
  my $name    = $results->get;

  # apply Mojo::mysql::Results::Role::MoreMethods
  my $mysql   = Mojo::mysql->new(...);
  my $results = $mysql->db->select(people => ['name'] => {id => 123})->with_roles('+MoreMethods');
  my $name    = $results->get;

  # apply using any results class
  my $pg      = Mojo::Pg->new(...);
  my $results = $pg->db->select(people => ['name'] => {id => 123})->with_roles('Mojo::DB::Results::Role::MoreMethods');
  my $name    = $results->get;

You may use L<Mojo::Base/with_roles> to apply L<Mojo::DB::Results::Role::MoreMethods> to your results classes.

These roles are also available to take advantage of C<with_role>'s shorthand C<+> notation when using L<Mojo::Pg::Results>
or L<Mojo::mysql::Results>:

=over 4

=item *

L<Mojo::Pg::Results::Role::MoreMethods>

=item *

L<Mojo::mysql::Results::Role::MoreMethods>

=back

These two roles are essentially just aliases for L<Mojo::DB::Results::Role::MoreMethods>. They are just empty roles with only this line:

  with 'Mojo::DB::Results::Role::MoreMethods';

=head2 Mojo::DB::Role::ResultsRoles

  # example from Mojo::DB::Role::ResultsRoles

  use Mojo::Pg;
  my $pg = Mojo::Pg->new(...)->with_roles('Mojo::DB::Role::ResultsRoles');
  push @{$pg->results_roles}, 'Mojo::DB::Results::Role::MoreMethods';
  my $results = $pg->db->query(...);
  # $results does Mojo::DB::Results::Role::MoreMethods

L<Mojo::DB::Role::ResultsRoles> allows roles to be applied to the results objects returned by database APIs like L<Mojo::Pg> or
L<Mojo::mysql>. See its documentation for more information.

You may take advantage of C<with_role>'s shorthand C<+> notation when using L<Mojo::Pg>
or L<Mojo::mysql> objects:

  # short hand with_roles syntax supported for Mojo::Pg and Mojo::mysql objects
  push @{$pg->results_roles}, '+MoreMethods';

=head1 METHODS

=head2 get

Be sure to call C<finish>, such as L<Mojo::Pg::Results/finish> or L<Mojo::mysql::Results/finish>,
if you are not fetching all of the possible rows.

L</get> will fetch the next row from C<sth>.

=head3 SCALAR CONTEXT

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # return the first column
  my $name = $results->get;

  # same as above but specifying index
  my $name = $results->get(0);

  # negative indexes may be used
  my $name = $results->get(-3);

  # any column may be gotten with an index
  my $age = $results->get(1);

When L</get> is called in scalar context with no index, it will fetch the next row from C<sth> and return the first column requested in your query.
If an index is specified, the value corresponding to the column at that index in the query will be used instead.
A negative index may be used just like indexing into Perl arrays.

=head4 WHILE LOOPS

  # THIS IS WRONG DO NOT DO THIS.
  while (my $name = $results->get) {
    # broken loop...
  }

Because L</get> in scalar context may return C<undef>, an empty string or a C<0> as values for a column, it
cannot be reliably used in while loops (unless used in L</"LIST CONTEXT">).
If you expect one row to be returned, considering using L</one> instead.

If you would like to use while loops with L</get>, consider using a while loop in L</"LIST CONTEXT">:

  while (my ($name) = $results->get) {
    say $name;
  }

=head3 LIST CONTEXT

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # return the first column
  my ($name) = $results->get;

  # same as above but specifying index
  my ($name) = $results->get(0);

  # multiple indexes may be used
  my ($name, $favorite_food) = $results->get(0, 2);

  # negative indexes may be used
  my ($name, $favorite_food) = $results->get(-3, -1);

  # get all column values
  my ($name, $age, $favorite_food) = $results->get;
  my @person = $results->get;

  # iterate
  while (my ($name, $age, $favorite_food) = $results->get) {
    say qq{$name is $age years old and their favorite food is $favorite_food};
  }

When L</get> is called in list context with no index, it will fetch the next row from C<sth> and return all values for the row as a list.
Individual column values may be requested by providing indexes. Negative indexes may also be used just like
indexing into Perl arrays.

=head3 OPTIONS

You may provide options to L</get> by providing an options hashref as the first
argument.

=head4 die

  # dies if no next row exists
  my $name = $results->get({die => 1});
  my $name = $results->get({die => 1}, 0);

Dies unless there is a next row to be retrieved.
See L</get_or_die> for this same behavior without needing to provide the die option.

The L</die> option does nothing if L</one> is provided, as L</one> is a superset of the functionality of L</die>.

=head4 one

  # dies unless exactly one row was returned in the results
  my $name = $results->get({one => 1});
  my $name = $results->get({one => 1}, 0);

Dies unless exactly one row was returned in the results.
See L</one> for this same behavior without needing to provide the one option.

=head2 get_by_name

Be sure to call C<finish>, such as L<Mojo::Pg::Results/finish> or L<Mojo::mysql::Results/finish>,
if you are not fetching all of the possible rows.

L</get_by_name> will fetch the next row from C<sth>.

=head3 SCALAR CONTEXT

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # return the name column
  my $name = $results->get_by_name('name');

L</get_by_name> called in scalar context will fetch the next row from C<sth> and returns the individual value for the column corresponding
to the provided name.

=head4 WHILE LOOPS

  # THIS IS WRONG DO NOT DO THIS.
  while (my $name = $results->get_by_name('name')) {
    # broken loop...
  }

Because L</get_by_name> in scalar context may return C<undef>, an empty string or a C<0> as values for a column, it
cannot be reliably used in while loops (unless used in L<"LIST CONTEXT"|/"LIST CONTEXT1">).
If you expect one row to be returned, considering using L</one_by_name> instead.

If you would like to use while loops with L</get_by_name>, consider using a while loop in L<"LIST CONTEXT"|/"LIST CONTEXT1">:

  while (my ($name) = $results->get_by_name('name')) {
    say $name;
  }

=head3 LIST CONTEXT

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # return the name column
  my ($name) = $results->get_by_name('name');

  # multiple names may be used
  my ($name, $favorite_food) = $results->get('name', 'favorite_food');

  # get all column values
  my ($name, $age, $favorite_food) = $results->get_by_name('name', 'age', 'favorite_food');

  # iterate
  while (my ($name, $age, $favorite_food) = $results->get_by_name('name', 'age', 'favorite_food')) {
    say qq{$name is $age years old and their favorite food is $favorite_food};
  }

L</get_by_name> fetches the next row from C<sth> and returns the list of values corresponding to the list of column names provided.

=head3 OPTIONS

You may provide options to L</get_by_name> by providing an options hashref as the first
argument.

=head4 die

  # dies if no next row exists
  my $name = $results->get_by_name({die => 1});
  my $name = $results->get_by_name({die => 1}, 0);

Dies unless there is a next row to be retrieved.
See L</get_by_name_or_die> for this same behavior without needing to provide the die option.

The L<"die"|/die1> option does nothing if L<"one"|/one1> is provided, as L<"one"|/one1> is a superset of the functionality of L<"die"|/die1>.

=head4 one

  # dies unless exactly one row was returned in the results
  my $name = $results->get({one => 1});
  my $name = $results->get({one => 1}, 0);

Dies unless exactly one row was returned in the results.
See L</one_by_name> for this same behavior without needing to provide the one option.

=head2 c

Be sure to call C<finish>, such as L<Mojo::Pg::Results/finish> or L<Mojo::mysql::Results/finish>,
if you are not fetching all of the possible rows.

L</c> will fetch the next row from C<sth>.

  my $results   = $db->select(people => ['first_name', 'middle_name', 'last_name']);
  my $full_name = $results->c->join(' ');

  # iterate
  while (my $c = $results->c) {
    my $full_name = $c->join(' ');
    say "Full name is $full_name";
  }

L</c> fetches the next row from C<sth> and returns the row as a L<Mojo::Collection>. If there is no next row available, C<undef> is returned.

You may provide indexes to get just those values in the L<Mojo::Collection>, just as you can do with L</get>:

  my $results   = $db->select(people => ['first_name', 'middle_name', 'last_name']);
  my $full_name = $results->c(0, 2)->join(' ');

  # prints "$first_name $last_name"
  say $full_name;

=head3 OPTIONS

You may provide options to L</c> by providing an options hashref as the first
argument.

=head4 die

  # dies if no next row exists
  my $person = $results->c({die => 1});
  my $person = $results->c({die => 1}, 0, 2);

Dies unless there is a next row to be retrieved.
See L</c_or_die> for this same behavior without needing to provide the die option.

The L<"die"|/die2> option does nothing if L<"one"|/one2> is provided, as L<"one"|/one2> is a superset of the functionality of L<"die"|/die2>.

=head4 one

  # dies unless exactly one row was returned in the results
  my $person = $results->c({one => 1});
  my $person = $results->c({one => 1}, 0, 2);

Dies unless exactly one row was returned in the results.
See L</one_c> for this same behavior without needing to provide the one option.

=head2 c_by_name

Be sure to call C<finish>, such as L<Mojo::Pg::Results/finish> or L<Mojo::mysql::Results/finish>,
if you are not fetching all of the possible rows.

L</c_by_name> will fetch the next row from C<sth>.

  my $results   = $db->select(people => ['first_name', 'middle_name', 'last_name']);
  my $full_name = $results->c_by_name('first_name', 'middle_name', 'last_name')->join(' ');

  # iterate
  while (my $c = $results->c_by_name('first_name', 'middle_name', 'last_name')) {
    my $full_name = $c->join(' ');
    say "Full name is $full_name";
  }

L</c_by_name> fetches the next row from C<sth> and returns the values corresponding to the provided columns for the next
row as a L<Mojo::Collection>. If there is no next row available, C<undef> is returned.

=head3 OPTIONS

You may provide options to L</c_by_name> by providing an options hashref as the first
argument.

=head4 die

  # dies if no next row exists
  my $person = $results->c_by_name({die => 1}, 'first_name', 'middle_name', 'last_name');

Dies unless there is a next row to be retrieved.
See L</c_by_name_or_die> for this same behavior without needing to provide the die option.

The L<"die"|/die3> option does nothing if L<"one"|/one3> is provided, as L<"one"|/one3> is a superset of the functionality of L<"die"|/die3>.

=head4 one

  # dies unless exactly one row was returned in the results
  my $person = $results->c({one => 1}, 'first_name', 'middle_name', 'last_name');

Dies unless exactly one row was returned in the results.
See L</one_c_by_name> for this same behavior without needing to provide the one option.

=head2 collections

  my $results    = $db->select(people => ['first_name', 'middle_name', 'last_name']);
  my $full_names = $results->collections->map(sub { $_->join(' ') });

L</collections> returns a L<Mojo::Collection> of L<Mojo::Collection>s. Each inner L<Mojo::Collection>
corresponds to one array returned by the results.

This is similar to L<Mojo::Pg::Results/arrays> or L<Mojo::mysql::Results/arrays>, but each arrayref
is a L<Mojo::Collection> instead.

=head2 flatten

  # Mojo::Collection with names of all people who like Pizza
  my $results = $db->select(people => ['name'] => {favorite_food => 'Pizza'});
  my $names   = $results->flatten; # equivalent to $results->arrays->flatten

  say 'Pizza lovers:';
  say for $names->each;

L</flatten> returns a L<Mojo::Collection> with all result arrays flattened to return a
L<Mojo::Collection> with all elements. This is equivalent to calling L<Mojo::Collection/flatten> on
the C<arrays> method.

=head2 struct

  my $struct = $results->struct;

Fetch next row from the statement handle with the result object's array method, and return it as a struct.

This method is composed from L<Mojo::DB::Results::Role::Struct>.

=head2 structs

  my $collection = $results->structs;

Fetch all rows from the statement handle with the result object's C<arrays> method, and return them as a L<Mojo::Collection> object containing structs.

This method is composed from L<Mojo::DB::Results::Role::Struct>.

=head2 TRANSFORM METHODS

L</"TRANSFORM METHODS"> is a group of methods that build on top of L<Mojo::Collection::Role::Transform> that allow
you to transform your results in meaningful and convenient ways. These are:

=over 4

=item

L</hashify>

=item

L</hashify_collect>

=item

L</collect_by>

=back

=head2 hashify

  # access results by a key
  my $results         = $db->select(people => '*');
  my $results_by_name = $results->hashify('name');

  # $alice_row is a hash
  my $alice_row = $results_by_name->{Alice};

  # access by multiple keys with a multilevel hash
  my $results_by_full_name = $results->hashify(['first_name', 'last_name']);

  # $alice_smith_row is a hash
  my $alice_smith_row = $results_by_full_name->{Alice}{Smith};

  # store the value as a struct instead of a hash
  my $results_by_name = $results->hashify({struct => 1}, 'name');
  my $alice_struct = $results_by_name->{Alice};

  say 'Alice is ' . $alice_struct->age . ' years old';

L</hashify> transforms your results into a hash that stores single rows or values (usually a column value) behind a key or
multiple keys (usually column values).

L</hashify> builds on L<Mojo::Collection::Role::Transform/hashify> and adds useful functionality specific to DB results.

=head3 OPTIONS

=head4 array

  my $results         = $db->select(people => '*');
  my $results_by_name = $results->hashify({array => 1}, 'name');

  my $alice_array = $results_by_name->{Alice};

L</array> allows you to store the value as an array instead of the default L</hash>.
This also means the value provided to the L</KEY> L</SUB> or the L</VALUE> L<"SUB"|/SUB1>, if used, will be an array.

=head4 c

  my $results         = $db->select(people => '*');
  my $results_by_name = $results->hashify({c => 1}, 'name');

  my $alice_collection = $results_by_name->{Alice};

L<"c"|/c1> allows you to store the value as a L<Mojo::Collection> instead of the default L</hash>.
This also means the value provided to the L</KEY> L</SUB> or the L</VALUE> L<"SUB"|/SUB1>, if used, will be a L<Mojo::Collection>.

=head4 hash

  my $results         = $db->select(people => '*');
  my $results_by_name = $results->hashify({hash => 1}, 'name'); # default

  my $alice_hash = $results_by_name->{Alice};

L</hash> allows you to store the value as a hash. This is the default and is the same as providing no option hash:

  my $results_by_name = $results->hashify('name');

This also means the value provided to the L</KEY> L</SUB> or the L</VALUE> L<"SUB"|/SUB1>, if used, will be a hash.

=head4 struct

  my $results         = $db->select(people => '*');
  my $results_by_name = $results->hashify({struct => 1}, 'name');

  my $alice_struct = $results_by_name->{Alice};

L<"struct"|/struct1> allows you to store the value as a readonly struct provided by L<Mojo::DB::Results::Role::Struct> instead of the default L</hash>.
This also means the value provided to the L</KEY> L</SUB> or the L</VALUE> L<"SUB"|/SUB1>, if used, will be a readonly struct.

=head3 KEY

=head4 SINGLE KEY

  my $results_by_name = $results->hashify('name');
  my $alice_row       = $results_by_name->{Alice};

A single key may be used to access values. This key should be the name of a returned column.

=head4 MULTIPLE KEYS

  my $results_by_full_name = $results->hashify(['first_name', 'last_name']);
  my $alice_smith_row      = $results_by_full_name->{Alice}{Smith};

Multiple keys may be used to access values. Multiple keys should be provided as an arrayref of names of returned columns.

=head4 SUB

  # single key
  my $results_by_name = $results->hashify(sub { $_->{name} });
  my $alice_row       = $results_by_name->{Alice};

  # multiple keys
  my $results_by_full_name = $results->hashify(sub { @{ $_ }{qw(first_name last_name)} });
  my $alice_smith_row      = $results_by_full_name->{Alice}{Smith};

Providing a subroutine for the key allows you to create the key (or keys) with the returned row.
The row is available either as C<$_> or as the first argument to the subroutine. The type of the row
(L</array>, L<"c"|/c1>, L</hash>, L<"struct"|/struct1>) that is passed to the subroutine depends on any
L<"OPTIONS"|/OPTIONS4> value that is passed (default is L</hash>).

If the subroutine returns one key, the hash will be a L</"SINGLE KEY"> hash. If multiple keys are returned
as a list, the hash with be a L</"MULTIPLE KEYS"> hash.

=head3 VALUE

=head4 DEFAULT

  # values are hashes
  my $results_by_name = $results->hashify('name');
  my $alice_hash      = $results_by_name->{Alice};

  # values are still hashes
  my $results_by_name = $results->hashify({hash => 1}, 'name');
  my $alice_hash      = $results_by_name->{Alice};

  # values are arrays
  my $results_by_name = $results->hashify({array => 1}, 'name');
  my $alice_array     = $results_by_name->{Alice};

  # values are Mojo::Collection's
  my $results_by_name  = $results->hashify({c => 1}, 'name');
  my $alice_collection = $results_by_name->{Alice};

  # values are readonly structs
  my $results_by_name = $results->hashify({struct => 1}, 'name');
  my $alice_struct    = $results_by_name->{Alice};

If no value argument is provided, the default is to use the row as the value according to the type
specified in L<"OPTIONS"|/OPTIONS4> (L</array>, L<"c"|/c1>, L</hash>, L<"struct"|/struct1>). The default is L</hash>.

=head4 COLUMN

  # value will be age
  my $results_by_name = $results->hashify('name', 'age');
  my $alice_age       = $results_by_name->{Alice};

The value can be provided as a column returned in the results and will be used as the
final value in the hash.

=head4 SUB

  # value will be the age squared
  my $results_by_name   = $results->hashify('name', sub { $_->{age} * $_->{age} });
  my $alice_age_squared = $results_by_name->{Alice};

Providing a subroutine for the value allows you to create the value with the returned row.
The row is available either as C<$_> or as the first argument to the subroutine. The type of the row
(L</array>, L<"c"|/c1>, L</hash>, L<"struct"|/struct1>) that is passed to the subroutine depends on any
L<"OPTIONS"|/OPTIONS4> value that is passed (default is L</hash>).

=head2 hashify_collect

  # group results by a key in a hash
  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->hashify_collect('name');

  # $alice_collection is a Mojo::Collection with all rows with the name Alice as hashes
  my $alice_collection = $collections_by_name->{Alice};

  # group by multiple keys with a multilevel hash
  my $collections_by_full_name = $results->hashify_collect(['first_name', 'last_name']);

  # $alice_smith_collection is a Mojo::Collection with all rows with
  # the first name Alice and last name Smith as hashes
  my $alice_smith_collection = $collections_by_full_name->{Alice}{Smith};

  # group the values as structs instead of hashes
  my $structs_by_name = $results->hashify_collect({struct => 1}, 'name');
  my $alice_structs   = $structs_by_name->{Alice};

  $alice_structs->each(sub {
    say 'Alice is ' . $_->age . ' years old';
  });

  # collect a single column value
  my $ages_by_name = $results->hashify_collect('name', 'age');

  # contains all ages in one Mojo::Collection for all rows with the name Alice
  my $alice_ages = $ages_by_name->{Alice};

  # flatten grouped results
  my $results               = $db->select(people => '*');
  my $column_values_by_name = $results->hashify_collect({flatten => 1}, 'name');

  # contains all column values in one Mojo::Collection for all rows with the name Alice
  my $alice_all_column_values = $column_values_by_name->{Alice};

L</hashify_collect> allows you to group rows behind a key or multiple keys in a hash.

L</hashify_collect> builds on L<Mojo::Collection::Role::Transform/hashify_collect> and adds useful functionality specific to DB results.

=head3 OPTIONS

=head4 array

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->hashify_collect({array => 1}, 'name');

  my $alice_collection = $collections_by_name->{Alice};
  my $alice_array      = $alice_collection->first;

L<"array"|/array1> allows you to group rows as arrays instead of the default L<"hash"|/hash1>.
This also means the value provided to the L<"KEY"|/KEY1> L<"SUB"|/SUB2> or the L<"VALUE"|/VALUE1> L<"SUB"|/SUB3>, if used, will be an array.

=head4 flatten

  my $results = $db->select(people => ['name', 'age']);

  # trivial example returning arrayref to demonstrate flatten
  my $age_collections_by_name = $results->hashify_collect({flatten => 1}, 'name', sub { [$_->{age}] });

  my $alice_ages_collection = $age_collections_by_name->{Alice};
  my $age_sum               = $alice_ages_collection->reduce(sub { $a + $b }, 0);

  say "Collective age of Alices is $age_sum years old";

L<"flatten"|/flatten1> flattens all values for a key into the same L<Mojo::Collection>.

L<"flatten"|/flatten1> may be combined with the other type options to specify the type of the rows that will be passed to the
L<"KEY"|/KEY1> L<"SUB"|/SUB2> or the L<"VALUE"|/VALUE1> L<"SUB"|/SUB3>.

If no L<"VALUE"|/VALUE1> is specified, all returned column values for a row will be returned in the order they were requested
and flattened into the resulting L<Mojo::Collection>. This works regardless of any type option that is specified:

  my $results = $db->select(people => ['name', 'age']);

  # both contain name and age flattened into the collections
  my $collections_by_name = $results->hashify_collect({hash => 1, flatten => 1}, sub { $_->{name} });
  my $collections_by_name = $results->hashify_collect({struct => 1, flatten => 1}, sub { $_->name });

Any value returned by a L<"VALUE"|/VALUE1> L<"SUB"|/SUB3> should be an arrayref or list of values and all values will be
added to the L<Mojo::Collection>:

  my $collections_by_name = $results->hashify_collect({flatten => 1}, 'name', sub { $_->{age} }); # flatten not needed in this specific case because it's a list of 1
  my $collections_by_name = $results->hashify_collect({flatten => 1}, 'name', sub { [$_->{age}] });

=head4 c

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->hashify_collect({c => 1}, 'name');

  my $alice_collections = $collections_by_name->{Alice};
  $alice_collections->each(sub {
    say 'Random column value is ' . $_->shuffle->first;
  });

L<"c"|/c2> allows you to group rows as L<Mojo::Collection>s instead of the default L<"hash"|/hash1>.
This also means the value provided to the L<"KEY"|/KEY1> L<"SUB"|/SUB2> or the L<"VALUE"|/VALUE1> L<"SUB"|/SUB3>, if used, will be a L<Mojo::Collection>.

=head4 hash

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->hashify_collect({hash => 1}, 'name'); # default

  my $alice_collection = $collections_by_name->{Alice};

L<"hash"|/hash1> allows you to group the rows as hashes. This is the default and is the same as providing no option hash:

  my $collections_by_name = $results->hashify_collect('name');

This also means the value provided to the L<"KEY"|/KEY1> L<"SUB"|/SUB2> or the L<"VALUE"|/VALUE1> L<"SUB"|/SUB3>, if used, will be a hash.

=head4 struct

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->hashify_collect({struct => 1}, 'name');

  my $alice_collection = $collections_by_name->{Alice};
  say q{First Alice's age is } . $alice_collection->first->age;

L<"struct"|/struct2> allows you to group the rows as readonly structs provided by L<Mojo::DB::Results::Role::Struct> instead of the default L<"hash"|/hash1>.
This also means the value provided to the L<"KEY"|/KEY1> L<"SUB"|/SUB2> or the L<"VALUE"|/VALUE1> L<"SUB"|/SUB3>, if used, will be a readonly struct.

=head3 KEY

=head4 SINGLE KEY

  my $collections_by_name = $results->hashify_collect('name');
  my $alice_collection    = $collections_by_name->{Alice};

A single key may be used to access collections. This key should be the name of a returned column.

=head4 MULTIPLE KEYS

  my $collections_by_full_name = $results->hashify_collect(['first_name', 'last_name']);
  my $alice_smith_collection   = $collections_by_full_name->{Alice}{Smith};

Multiple keys may be used to access collections. Multiple keys should be provided as an arrayref of names of returned columns.

=head4 SUB

  # single key
  my $collections_by_name = $results->hashify_collect(sub { $_->{name} });
  my $alice_collection    = $collections_by_name->{Alice};

  # multiple keys
  my $collections_by_full_name = $results->hashify_collect(sub { @{ $_ }{qw(first_name last_name)} });
  my $alice_smith_collection   = $collections_by_full_name->{Alice}{Smith};

Providing a subroutine for the key allows you to create the key (or keys) with the returned row.
The row is available either as C<$_> or as the first argument to the subroutine. The type of the row
(L<"array"|/array1>, L<"c"|/c2>, L<"hash"|/hash1>, L<"struct"|/struct2>)
that is passed to the subroutine depends on any L<"OPTIONS"|/OPTIONS5> value that is passed (default is L<"hash"|/hash1>).

If the subroutine returns one key, the hash will be a L<"SINGLE KEY"|/"SINGLE KEY1"> hash. If multiple keys are returned
as a list, the hash with be a L<"MULTIPLE KEYS"|/"MULTIPLE KEYS1"> hash.

=head3 VALUE

=head4 DEFAULT

  # collections contain hashes
  my $collections_by_name        = $results->hashify_collect('name');
  my $alice_collection_of_hashes = $collections_by_name->{Alice};

  # collections still contain hashes
  my $collections_by_name        = $results->hashify_collect({hash => 1}, 'name');
  my $alice_collection_of_hashes = $collections_by_name->{Alice};

  # collections contain arrays
  my $collections_by_name        = $results->hashify_collect({array => 1}, 'name');
  my $alice_collection_of_arrays = $collections_by_name->{Alice};

  # collections contain Mojo::Collection's
  my $collections_by_name             = $results->hashify_collect({c => 1}, 'name');
  my $alice_collection_of_collections = $collections_by_name->{Alice};

  # collections contain readonly structs
  my $collections_by_name         = $results->hashify_collect({struct => 1}, 'name');
  my $alice_collection_of_structs = $collections_by_name->{Alice};

If no value argument is provided, the default is to collect the rows as the value according to the type
specified in L<"OPTIONS"|/OPTIONS5> (L<"array"|/array1>, L<"c"|/c2>, L<"hash"|/hash1>, L<"struct"|/struct2>).
The default is L<"hash"|/hash1>.

=head4 COLUMN

  # age will be collected
  my $collections_by_name      = $results->hashify_collect('name', 'age');
  my $alice_collection_of_ages = $collections_by_name->{Alice};

The value can be provided as a column returned in the results, and this column value for
each row will be collected into the corresponding L<Mojo::Collection> based on the key(s).

=head4 SUB

  # collected value will be the age squared
  my $collections_by_name              = $results->hashify_collect('name', sub { $_->{age} * $_->{age} });
  my $alice_collection_of_ages_squared = $collections_by_name->{Alice};

Providing a subroutine for the value allows you to create the collected values for each returned row.
The row is available either as C<$_> or as the first argument to the subroutine. The type of the row
(L<"array"|/array1>, L<"c"|/c2>, L<"hash"|/hash1>, L<"struct"|/struct2>)
that is passed to the subroutine depends on any L<"OPTIONS"|/OPTIONS5> value that is passed (default is L<"hash"|/hash1>).

You may return a single value, or a list of values to be collected:

  my $collections_by_name = $results->hashify_collect('name', sub { $_->{age}, $_->{favorite_food} });

=head2 collect_by

  # group results by a key in Mojo::Collection's inside of a Mojo::Collection
  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->collect_by('name');
  say 'First collection contains rows with name', $collections_by_name->first->first->{name};

  # group results by multiple keys
  my $collections_by_full_name = $results->collect_by(['first_name', 'last_name']);
  my $first_collection = $collections_by_name->first;
  say
    'First collection contains rows with first name',
    $first_collection->first->{first_name},
    ' and last name ',
    $first_collection->first->{last_name};

  # group the values as structs instead of hashes
  my $structs_by_name = $results->collect_by({struct => 1}, 'name');

  $structs_by_name->first->each(sub {
    say $_->name, ' is ' . $_->age . ' years old';
  });

  # collect a single column value
  my $ages_by_name = $results->collect_by('name', 'age');
  say 'First collection contains ages for name', $ages_by_name->first->first->{name};

  # flatten grouped results
  my $results = $db->select(people => '*');
  # each inner Mojo::Collection is flattened
  my $column_values_by_name = $results->collect_by({flatten => 1}, 'name');

L</collect_by> allows you to group rows/values that share the same key or multiple keys in L<Mojo::Collection>s inside of a L<Mojo::Collection>.

L</collect_by> builds on L<Mojo::Collection::Role::Transform/collect_by> and adds useful functionality specific to DB results.

=head3 OPTIONS

=head4 array

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->collect_by({array => 1}, 'name');

L<"array"|/array2> allows you to group rows as arrays instead of the default L<"hash"|/hash2>.
This also means the value provided to the L<"KEY"|/KEY2> L<"SUB"|/SUB4> or the L<"VALUE"|/VALUE2> L<"SUB"|/SUB5>, if used, will be an array.

=head4 flatten

  my $results = $db->select(people => ['name', 'age']);

  # trivial example returning arrayref to demonstrate flatten
  my $age_collections_by_name = $results->collect_by({flatten => 1}, 'name', sub { [$_->{age}] });

L<"flatten"|/flatten2> flattens all values for each inner L<Mojo::Collection>.

L<"flatten"|/flatten2> may be combined with the other type options to specify the type of the rows that will be passed to the
L<"KEY"|/KEY2> L<"SUB"|/SUB4> or the L<"VALUE"|/VALUE2> L<"SUB"|/SUB5>.

If no L<"VALUE"|/VALUE2> is specified, all returned column values for a row will be returned in the order they were requested
and flattened into the resulting L<Mojo::Collection>. This works regardless of any type option that is specified:

  my $results = $db->select(people => ['name', 'age']);

  # both contain name and age flattened into the inner collections
  my $collections_by_name = $results->collect_by({hash => 1, flatten => 1}, sub { $_->{name} });
  my $collections_by_name = $results->collect_by({struct => 1, flatten => 1}, sub { $_->name });

Any value returned by a L<"VALUE"|/VALUE2> L<"SUB"|/SUB5> should be an arrayref or list of values and all values will be
added to the inner L<Mojo::Collection>s:

  my $collections_by_name = $results->collect_by({flatten => 1}, 'name', sub { $_->{age} }); # flatten not needed in this specific case because it's a list of 1
  my $collections_by_name = $results->collect_by({flatten => 1}, 'name', sub { [$_->{age}] });

=head4 c

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->collect_by({c => 1}, 'name');

  $collections_by_name->first->first->each(sub {
    say 'Random column value is ' . $_->shuffle->first;
  });

L<"c"|/c3> allows you to group rows as L<Mojo::Collection>s instead of the default L<"hash"|/hash2>.
This also means the value provided to the L<"KEY"|/KEY2> L<"SUB"|/SUB4> or the L<"VALUE"|/VALUE2> L<"SUB"|/SUB5>, if used, will be a L<Mojo::Collection>.

=head4 hash

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->collect_by({hash => 1}, 'name'); # default

L<"hash"|/hash2> allows you to group the rows as hashes. This is the default and is the same as providing no option hash:

  my $collections_by_name = $results->collect_by('name');

This also means the value provided to the L<"KEY"|/KEY2> L<"SUB"|/SUB4> or the L<"VALUE"|/VALUE2> L<"SUB"|/SUB5>, if used, will be a hash.

=head4 struct

  my $results             = $db->select(people => '*');
  my $collections_by_name = $results->collect_by({struct => 1}, 'name');

  my $first_collection = $collections_by_name->first;
  say $first_collection->first->name, ' is ', $first_collection->first->age, ' years old';

L<"struct"|/struct3> allows you to group the rows as readonly structs provided by L<Mojo::DB::Results::Role::Struct> instead of the default L<"hash"|/hash2>.
This also means the value provided to the L<"KEY"|/KEY2> L<"SUB"|/SUB4> or the L<"VALUE"|/VALUE2> L<"SUB"|/SUB5>, if used, will be a readonly struct.

=head3 KEY

=head4 SINGLE KEY

  my $collections_by_name = $results->collect_by('name');

A single key may be used to group rows/values into inner L<Mojo::Collection>s. This key should be the name of a returned column.

=head4 MULTIPLE KEYS

  my $collections_by_full_name = $results->collect_by(['first_name', 'last_name']);

Multiple keys may be used to group rows/values into inner L<Mojo::Collection>s. Multiple keys should be provided as an arrayref of names of returned columns.

=head4 SUB

  # single key
  my $collections_by_name = $results->collect_by(sub { $_->{name} });

  # multiple keys
  my $collections_by_full_name = $results->collect_by(sub { @{ $_ }{qw(first_name last_name)} });

Providing a subroutine for the key allows you to create the key (or keys) with the returned row.
The row is available either as C<$_> or as the first argument to the subroutine. The type of the row
(L<"array"|/array2>, L<"c"|/c3>, L<"hash"|/hash2>, L<"struct"|/struct3>)
that is passed to the subroutine depends on any L<"OPTIONS"|/OPTIONS6> value that is passed (default is L<"hash"|/hash2>).

If the subroutine returns one key, the hash will be a L<"SINGLE KEY"|/"SINGLE KEY2"> hash. If multiple keys are returned
as a list, the hash with be a L<"MULTIPLE KEYS"|/"MULTIPLE KEYS2"> hash.

=head3 VALUE

=head4 DEFAULT

  # collections contain hashes
  my $collections_by_name = $results->collect_by('name');

  # collections still contain hashes
  my $collections_by_name = $results->collect_by({hash => 1}, 'name');

  # collections contain arrays
  my $collections_by_name = $results->collect_by({array => 1}, 'name');

  # collections contain Mojo::Collection's
  my $collections_by_name = $results->collect_by({c => 1}, 'name');

  # collections contain readonly structs
  my $collections_by_name = $results->collect_by({struct => 1}, 'name');

If no value argument is provided, the default is to collect the rows as the value according to the type
specified in L<"OPTIONS"|/OPTIONS6> (L<"array"|/array2>, L<"c"|/c3>, L<"hash"|/hash2>, L<"struct"|/struct3>).
The default is L<"hash"|/hash2>.

=head4 COLUMN

  # age will be collected
  my $collections_by_name = $results->collect_by('name', 'age');

The value can be provided as a column returned in the results, and this column value for
each row will be collected into the corresponding inner L<Mojo::Collection> based on the key(s).

=head4 SUB

  # collected value will be the age squared
  my $collections_by_name = $results->collect_by('name', sub { $_->{age} * $_->{age} });

Providing a subroutine for the value allows you to create the collected values for each returned row.
The row is available either as C<$_> or as the first argument to the subroutine. The type of the row
(L<"array"|/array2>, L<"c"|/c3>, L<"hash"|/hash2>, L<"struct"|/struct3>)
that is passed to the subroutine depends on any L<"OPTIONS"|/OPTIONS6> value that is passed (default is L<"hash"|/hash2>).

You may return a single value, or a list of values to be collected:

  my $collections_by_name = $results->collect_by('name', sub { $_->{age}, $_->{favorite_food} });

=head2 DIE METHODS

L</"DIE METHODS"> are equivalent to the L</get>, L</get_by_name>, L</c>, and L</c_by_name> methods above, however,
the C<die> option for these methods is passed as C<true> for you and the method will die if there is no next row to be
retrieved.

Additionally, L</struct_or_die>, L</array_or_die>, and L</hash_or_die> are provided.

=head3 get_or_die

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # all of these die if there is no next row to be retrieved

  # return the first column
  my $name = $results->get_or_die;

  # same as above but specifying index
  my $name = $results->get_or_die(0);

  # negative indexes may be used
  my $name = $results->get_or_die(-3);

  # any column may be gotten with an index
  my $age = $results->get_or_die(1);

Same as L</get>, but dies if there is no next row to be retrieved.

=head3 get_by_name_or_die

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # dies if there is no next row to be retrieved
  my $name = $results->get_by_name_or_die('name');

Same as L</get_by_name>, but dies if there is no next row to be retrieved.

=head3 c_or_die

  my $results = $db->select(people => ['first_name', 'middle_name', 'last_name']);

  # dies if there is no next row to be retrieved
  my $full_name = $results->c_or_die->join(' ');

Same as L</c>, but dies if there is no next row to be retrieved.

=head3 c_by_name_or_die

  my $results = $db->select(people => ['first_name', 'middle_name', 'last_name']);

  # dies if there is no next row to be retrieved
  my $full_name = $results->c_by_name_or_die('first_name', 'middle_name', 'last_name')->join(' ');

Same as L</c_by_name>, but dies if there is no next row to be retrieved.

=head3 struct_or_die

  my $results = $db->select(people => '*' => {id => 123});

  # dies if there is no next row to be retrieved
  my $person_struct = $results->struct_or_die;

L</struct_or_die> is the same as L</struct>, but dies if there is no next row to be retrieved.

=head3 array_or_die

  my $results = $db->select(people => ['first_name', 'middle_name', 'last_name'] => {id => 123});

  # dies if there is no next row to be retrieved
  my $full_name = join ' ', @{ $results->array_or_die };

L</array_or_die> is similar to L<Mojo::Pg::Results/array> or L<Mojo::mysql::Results/array>, but dies
if there is no next row to be retrieved.

=head3 hash_or_die

  my $results = $db->select(people => '*' => {id => 123});

  # dies if there is no next row to be retrieved
  my $person = $results->hash_or_die;

L</hash_or_die> is similar to L<Mojo::Pg::Results/hash> or L<Mojo::mysql::Results/hash>, but dies
if there is no next row to be retrieved.

=head2 ONE METHODS

L</"ONE METHODS"> are equivalent to the L</get>, L</get_by_name>, L</c>, L</c_by_name>, and L</struct> methods above, however,
the C<one> option for these methods is passed as C<true> for you and the method will die unless exactly one row was returned.

Additionally, L</one_struct>, L</one_array> and L</one_hash> are provided.

=head3 one

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # all of these die unless exactly one row was returned

  # return the first column
  my $name = $results->one;

  # same as above but specifying index
  my $name = $results->one(0);

  # negative indexes may be used
  my $name = $results->one(-3);

  # any column may be gotten with an index
  my $age = $results->one(1);

Same as L</get>, but dies unless exactly one row was returned.

=head3 one_by_name

  my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 123});

  # dies unless exactly one row was returned
  my $name = $results->one_by_name('name');

Same as L</get_by_name>, but dies unless exactly one row was returned.

=head3 one_c

  my $results = $db->select(people => ['first_name', 'middle_name', 'last_name'] => {id => 123});

  # dies unless exactly one row was returned
  my $full_name = $results->one_c->join(' ');

Same as L</c>, but dies unless exactly one row was returned.

=head3 one_c_by_name

  my $results = $db->select(people => ['first_name', 'middle_name', 'last_name'] => {id => 123});

  # dies unless exactly one row was returned
  my $full_name = $results->one_c_by_name('first_name', 'middle_name', 'last_name')->join(' ');

Same as L</c_by_name>, but dies unless exactly one row was returned

=head3 one_struct

  my $results = $db->select(people => '*' => {id => 123});

  # dies unless exactly one row was returned
  my $person_struct = $results->one_struct;

L</one_struct> is the same as L</struct>, but dies unless exactly one row was returned.

=head3 one_array

  my $results = $db->select(people => ['first_name', 'middle_name', 'last_name'] => {id => 123});

  # dies unless exactly one row was returned
  my $full_name = join ' ', @{ $results->one_array };

L</one_array> is similar to L<Mojo::Pg::Results/array> or L<Mojo::mysql::Results/array>, but dies
unless exactly one row was returned.

=head3 one_hash

  my $results = $db->select(people => '*' => {id => 123});

  # dies unless exactly one row was returned
  my $person = $results->one_hash;

L</one_hash> is similar to L<Mojo::Pg::Results/hash> or L<Mojo::mysql::Results/hash>, but dies
unless exactly one row was returned.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item

L<Mojo::Pg::Results>

=item

L<Mojo::mysql::Results>

=item

L<Mojo::DB::Role::ResultsRoles>

=item

L<Mojo::DB::Results::Role::Struct>

=item

L<Role::Tiny>

=item

L<Mojo::Base>

=back

=cut

package Pinwheel::Model;

use strict;
use warnings;

use Carp;
use DBI qw(SQL_INTEGER);
use Time::Local qw(timegm_nocheck);

use Pinwheel::Context;
use Pinwheel::Database qw(prepare describe fetchone_tables fetchall_tables);
use Pinwheel::Model::Base;
use Pinwheel::Model::Date;
use Pinwheel::Model::Time;

# Terminology in the code below:
# "class" - a class (package) name
# "stash" - the hash ref representing a class (see 'perlguts')
# $base_class / $base_stash - usually the "Model" class, i.e. us
# $model_class / $model_stash - the relevant Models::Foo class

our $AUTOLOAD;

my (%inheritance_keys, %inheritance);


sub import
{
    my ($base_class, $table, @args) = @_;
    return unless defined($table);
    my $base_stash = _get_stash($base_class);
    my $model_class = caller();
    _export_functions($base_stash, $table, $model_class, @args);
}

sub _export_functions
{
    my ($base_stash, $table, $model_class, $ikey, $ivalue) = @_;
    my ($model_stash, $fields, $column, $model, $getter);

    $model_stash = _get_stash($model_class);
    $fields = describe($table);
    $model = {
        table => $table,
        fields => $fields,
        model_class => $model_class,
        model_stash => $model_stash,
        getters => {},
        inheritance_key => $ikey,
        inheritance_value => $ivalue,
        associations => {},
    };

    if ($ikey) {
        $inheritance_keys{$table} = $ikey;
        $inheritance{$table}{$ivalue} = $model;
    }

    # Export these to the models class
    $model_stash->{$_} = $base_stash->{$_}
        for qw( query belongs_to has_one has_many );

    # Column accessors
    _export_accessors($model) unless $ikey;

    $getter = sub {
        my ($fn);
        $fn = _make_finder($model, $1, $2)
            if $AUTOLOAD =~ /::find(_all)?(?:_by_(\w+))?$/;
        $fn = _make_finder($model, 'prefetch', 'id')
            if $AUTOLOAD =~ /::prefetch$/;
        croak "Can't locate $AUTOLOAD" unless $fn;
        no strict 'refs';
        *$AUTOLOAD = $fn;
        goto &$fn;
    };

    no strict 'refs';
    # find, find_by_<column>, find_all_by_<column>, and prefetch
    *{"$model_class\::AUTOLOAD"} = $getter;
    # Private model information
    *{"$model_class\::model"} = $model;
}

sub _export_accessors
{
    my ($model) = @_;
    my ($fields, $model_class, $column, $getter);

    $fields = $model->{fields};
    $model_class = $model->{model_class};

    foreach $column (keys %$fields) {
        if ($fields->{$column}{type} =~ /^date(time)?/) {
            my $class = $1 ? 'Pinwheel::Model::Time' : 'Pinwheel::Model::Date';
            # Time/date column: wrap value in a Pinwheel::Model::Time/Date class
            $getter = sub {
                my $data = $_[0]->{data};
                $_[0]->_fill_out() if (!exists($data->{$column}));
                my $t = $data->{$column};
                return $t if (!defined($t) || ref($t));
                return $data->{$column} = undef if ($t =~ /^0000-00-00/);
                # Convert timestamp/date to seconds-since-epoch (assumption:
                # database handle timezone is GMT) and construct the wrapper
                $t =~ /^(....)-(..)-(..)(?: (..):(..):(..))?/;
                $t = timegm_nocheck($6 || 0, $5 || 0, $4 || 0, $3, $2 - 1, $1);
                return $data->{$column} = $class->new($t);
            };
        } else {
            # Not a time/date column: just return value untouched
            $getter = sub {
                my $data = $_[0]->{data};
                $_[0]->_fill_out() if (!exists($data->{$column}));
                return $data->{$column};
            };
        }
        $model->{getters}{$column} = $getter;
        no strict 'refs';
        *{"$model_class\::$column"} = $getter;
    }
}


sub belongs_to { _add_association(_get_stash(caller), 'belongs_to', @_) }
sub has_one { _add_association(_get_stash(caller), 'has_one', @_) }
sub has_many { _add_association(_get_stash(caller), 'has_many', @_) }
sub query { _add_query(scalar(caller), @_) }

sub _add_query
{
    my ($model_class, $name, %opts) = @_;
    my ($model, $wrapfn, $queryfn, $sqldata);

    $model = _get_stash($model_class)->{model};
    $wrapfn = _get_type_wrapper($opts{type}, $name);
    croak 'Unknown query result type' unless $wrapfn;

    $queryfn = sub {
        $sqldata = _parse_sql($model->{model_stash}{sql}{$name}) unless $sqldata;
        return _do_sql($sqldata, $model, $wrapfn, \%opts, @_);
    };

    no strict 'refs';
    *{"$model_class\::$name"} = $queryfn;
}

sub _get_type_wrapper
{
    my ($type, $name) = @_;
    my $fn;

    return if (!$type && !$name);

    if (!$type) {
        $type = '[-]';
        $type = '-' if $name =~ /^find(?!_all)/;
        $type = '1' if $name =~ /^count/;
        $type = 'x' if $name =~ /^
            (?:set|add|remove|create|replace|update|delete)
            (?:$|_)
        /x;
    }

    # [-] = List of rows (wrapped as a list of model objects)
    #  -  = One row (wrapped as a model object)
    # [1] = List of single values
    #  1  = Single value
    #  x  = No result
    if ($type eq '[-]') {
        $fn = \&_wrap_all_rows;
    } elsif ($type eq '-') {
        $fn = \&_wrap_one_row;
    } elsif ($type eq '[1]') {
        $fn = \&_wrap_all_column;
    } elsif ($type eq '1') {
        $fn = \&_wrap_one_value;
    } elsif ($type eq 'x') {
        $fn = \&_wrap_nothing;
    }

    return $fn;
}

sub _add_association
{
    my ($model_stash, $type, $name, %opts) = @_;
    my ($associated_class, $finder, $key) = @opts{qw(package finder key)};
    my $fn;

    if (!$associated_class) {
        $associated_class = make_package_name($name);
    }
    if (!$finder) {
        $finder = 'find';
        if ($type eq 'has_many') {
            $finder .= '_all';
        }
        if ($type ne 'belongs_to') {
            $finder .= '_by_' . _make_singular($model_stash->{model}{table});
        }
    }
    $key = (($type eq 'belongs_to') ? $name . '_id' : 'id') unless $key;

    $fn = sub {
        my $data = $_[0]->{data};
        return $data->{$name} if exists($data->{$name});
        $_[0]->_fill_out() if (!exists($data->{$key}));
        return $data->{$name} = $associated_class->$finder($data->{$key});
    };

    no strict 'refs';
    $model_stash->{model}{associations}{$name} = *{"$associated_class\::"};
    *{$model_stash->{model}{model_class} . "::$name"} = $fn;
}


sub _parse_sql
{
    my ($sql) = @_;
    my ($i, @dynamic, @static, $d);

    $sql =~ s[/\* .*? \*/][ ]gx;

    $i = 0;
    foreach ($sql =~ /\?(?:\$(.*?)\$)?/g) {
        if (defined($_)) {
            push @dynamic, [$i++, qr/^$_$/];
        } else {
            push @static, $i++;
        }
    }

    $d = (scalar(@dynamic) > 0) ? \@dynamic : undef;
    return [$sql, $i, $d, \@static];
}

sub _gather_static_params
{
    my ($sql, $info, $params) = @_;
    my ($pos, $i, @static_params);
    
    @static_params = ();
    $pos = -1;
    $i = 0;
    while (($pos = index($sql,'?',$pos+1)) > 0)
    {
        my $pnum = $info->[$i];
        croak "not enough parameters given" unless (defined $pnum);
        my $value = $params->[$pnum];
        if (!defined $value) {
            if (substr($sql,$pos-4,5) =~ /(\s*!=\s*\?)$/) {
                substr($sql,$pos-(length($1)-1),length($1)) = ' IS NOT NULL';
            } elsif (substr($sql,$pos-4,5) =~ /(\s*=\s*\?)$/) {
                substr($sql,$pos-(length($1)-1),length($1)) = ' IS NULL';
            } else {
                push(@static_params, [undef]);
            }
        } elsif (ref($value) eq 'HASH') {
            push(@static_params, [each(%$value)]);
        } elsif (ref($value)) {
            push(@static_params, [$value->sql_param]);
        } else {
            push(@static_params, [$value]);
        }
        $i++;
    }
    
    return ($sql, @static_params);
}


sub _insert_dynamic_params
{
    my ($sql, $info, $params) = @_;
    my (@inserts, $i, $regex, $value);

    foreach (@$info) {
        ($i, $regex) = @$_;
        $value = $params->[$i++] || '';
        push @inserts, $value;
        croak "Parameter $i does not match requirement: $value"
            unless ($value =~ /$regex/);
    }
    $i = 0;
    $sql =~ s/\?\$.*?\$/$inserts[$i++]/ge;

    return $sql;
}

sub _do_sql
{
    my ($sqldata, $model, $wrapfn, $opts, @params) = @_;
    my ($tables, $sql, @static_params, %args, $order, $sth, $i, $result);
    
    $tables = $opts->{include};
    if ($opts->{fn}) {
        # Function was provided to munge the input parameters before running
        # the SQL; can also declare the list of relations being fetched
        # alongside the primary table.
        @params = $opts->{fn}(@params);
        if (@params && ref($params[0]) eq 'ARRAY') {
            $tables = shift(@params);
        }
    } else {
        # If no fn is specified, throw away the first param
        # if it's the class name.
        shift @params if !ref($params[0]);
    }

    $sql = $sqldata->[0];

    # Fill in dynamic parameters
    if ($sqldata->[2]) {
        $sql = _insert_dynamic_params($sql, $sqldata->[2], \@params);
    }

    # Gather bind parameters and rewrite "= ?" to "IS NULL" if the value is undef
    ($sql, @static_params) = _gather_static_params($sql, $sqldata->[3], \@params);

    %args = @params[$sqldata->[1] ... $#params];
    $order = $args{'order'};
    croak 'Invalid sort order'
        if ($order && $order !~ /^ *\w+(?:\.\w+)?(?: +(?:asc|desc))? *$/i);
    $sql .= " ORDER BY $order" if $order;
    $sql .= ' LIMIT ?' if $args{'limit'};
    $sql .= ' OFFSET ?' if $args{'offset'};

    # Fill in static parameters
    $i = 1;
    $sth = prepare($sql, defined($sqldata->[2]));
    foreach (@static_params) {
        $sth->bind_param($i++, @$_);
    }
    $sth->bind_param($i++, $args{'limit'}, SQL_INTEGER) if $args{'limit'};
    $sth->bind_param($i++, $args{'offset'}, SQL_INTEGER) if $args{'offset'};

    $sth->execute();
    $result = &$wrapfn($model, $sth, $tables);
    $result = $opts->{postfn}(\@params,$result) if $opts->{postfn};
    return $result;
}


sub _wrap_one_row
{
    my ($model, $sth, $tables) = @_;
    my $data = fetchone_tables($sth, $tables);
    return _make_model_object($model, $data, $tables) if $data;
}

sub _wrap_all_rows
{
    my ($model, $sth, $tables) = @_;
    my (@objects, $data);
    foreach $data (@{fetchall_tables($sth, $tables)}) {
        push @objects, _make_model_object($model, $data, $tables);
    }
    return \@objects;
}

sub _wrap_all_column
{
    my $sth = $_[1];
    return [map { $_->[0] } @{$sth->fetchall_arrayref([0])}];
}

sub _wrap_one_value
{
    return $_[1]->fetchrow_arrayref()->[0];
}

sub _wrap_nothing
{
    return;
}

sub _find_inherited_model
{
    my ($model, $data) = @_;
    my ($table, $key);

    $table = $model->{table};
    $key = $inheritance_keys{$table};
    if ($key) {
        $key = $data->{$key};
        croak 'Missing inheritance key' unless $key;
        $model = $inheritance{$table}{$key};
        croak "No model found for subclass $key" unless $model;
    }
    return $model;
}

sub _make_model_object
{
    my ($model, $data, $tables) = @_;
    my ($root, $parent, @parts, $key);

    $model = _find_inherited_model($model, $data->{''});
    $root = Pinwheel::Model::Base::new($model->{model_class}, $model, delete $data->{''});

    foreach $key (@$tables) {
        @parts = split(/\./, $key);
        $parent = $root;
        $parent = $parent->$_ foreach (@parts[0 .. $#parts - 1]);
        $parent->_prefetched_link($parts[-1], $data->{$key}) if ($parent);
    }
    return $root;
}

sub _make_finder
{
    my ($model, $all, $column) = @_;
    my ($sql, $null, $ikey, $sqldata, $wrapfn, @conditions);

    $column = 'id' if (!$all && !$column);
    $sql = "SELECT * FROM `$model->{table}`";

    if ($column) {
        $column .= '_id' unless exists($model->{fields}{$column});
        return unless exists($model->{fields}{$column});
    }

    $null = ($column && $model->{fields}{$column}{null});
    $ikey = $model->{inheritance_key};

    if ($ikey) {
        push @conditions, "`$ikey` = '" . $model->{inheritance_value} . "'";
    }

    if ($all && $all eq 'prefetch') {
        push @conditions, "`$column` IN (?\$(?:[0-9]+,?)+\$)";
    } elsif ($column) {
        push @conditions, "`$column` = ?";
    }

    $sql .= " WHERE " . join(" AND ", @conditions)
        if @conditions;

    $sqldata = _parse_sql($sql);
    $wrapfn = $all ? \&_wrap_all_rows : \&_wrap_one_row;
    if (!$column) {
        return sub { _do_sql($sqldata, $model, $wrapfn, {}, @_) };
    } elsif (!$all && !$null && $column eq 'id') {
        return sub {
            my ($ctx, $obj);
            my $class = shift;
            return if !defined($_[0]);
            $ctx = Pinwheel::Context::get('Model--' . $model->{table});
            return $obj if $obj = $ctx->{$_[0]};
            return _do_sql($sqldata, $model, $wrapfn, {}, $class, @_);
        };
    } elsif ($all && $all eq 'prefetch') {
        return sub {
            my $class = shift;
            my ($ctx, %ids, @keys);
            $ctx = Pinwheel::Context::get('Model--' . $model->{table});
            map { $ids{$_} = 1 unless exists($ctx->{$_}) } @_;
            @keys = keys %ids;
            return 0 if scalar(@keys) == 0;
            _do_sql($sqldata, $model, $wrapfn, {}, $class, join(',', @keys));
            return scalar(@keys);
        }
    } elsif (!$null) {
        return sub {
            my $class = shift;
            return if !defined($_[0]);
            return _do_sql($sqldata, $model, $wrapfn, {}, $class, @_);
        };
    } else {
        return sub {
            my $class = shift;
            return _do_sql($sqldata, $model, $wrapfn, {}, $class, @_);
        };
    }
}


sub make_package_name
{
    my $name = shift;
    $name =~ s/_+/ /g;
    $name =~ s/\b(\w)/\U$1/g;
    $name =~ s/ +//g;
    return 'Models::' . _make_singular($name);
}

sub _make_singular
{
    my $s = shift;
    $s =~ s/ories$/ory/;
    $s =~ s/ities/ity/;
    $s =~ s/(?<=[^s])s$// unless $s =~ /ies$/;
    return $s;
}

sub _get_stash
{
    my $class = shift;
    my $stash = \%::;
    $stash = $stash->{"$_\::"} foreach split(/::/, $class);
    return $stash;
}

1;

__DATA__ 

=head1 NAME 

Model - simple ORM based on a mix of iBATIS and ActiveRecord

=head1 SYNOPSIS

    package Models::Service;

    use Model 'services';
    our @ISA = qw(Pinwheel::Model::Base);

    BEGIN {
        belongs_to 'parent', package => 'Models::Service';
        has_many 'broadcasts';
        query 'find_by_directory';
    }

    our %sql = (
        find_by_directory => q{
            SELECT * FROM services WHERE directory=?
        },
    );

=head1 DESCRIPTION

C<Model> uses simple schema conventions (adopted from ActiveRecord) to provide
lightweight object wrappers around database tables.  It deliberately avoids
trying to generate SQL statements (with the exception of "find by id").

Each table is represented by a class under C<Models::> and inherits from
C<Pinwheel::Model::Base>.  The table name is supplied by the C<use> statement, and
relations and query functions/methods are declared with one of C<belongs_to>,
C<has_one>, C<has_many>, and C<query>.

All database access is performed via the Database module (which uses DBI).
Only mysql data sources are supported.

=head1 CONVENTIONS

This module works best with a database schema that uses these
ActiveRecord-derived naming conventions:

=over 4

=item Table names

Use plural nouns, eg B<people> and B<contracts>, and separate words with
underscores, eg B<line_items>.

=item Keys

Each table with a model class should have a primary key called B<id>.

Foreign keys should use a clean, descriptive name followed by B<_id>.  For
example, a singular version of the foreign table name such as B<contract_id> or
B<line_item_id>, or a description of the relationship, such as B<parent_pip_id>
or B<child_pip_id>.

=item Column names

Avoid putting the table name or a data type in column names, eg
B<customers.name> rather than B<customers.customer_name>, and B<created_at>
rather than B<created_date>.

=back

=head1 RELATIONSHIPS

=over 4

=item belongs_to

Declare a one-to-one or many-to-one relationship where the foreign key is in
the table containing the C<belongs_to>.  For example:
  
    package Models::Broadcast;
    ...
    belongs_to 'service';

This states that the B<broadcasts> table contains a B<service_id> column
referencing the B<services> table.  Each instance of C<Models::Broadcast> 
will have a C<service> method which returns the linked C<Models::Service> 
object.

=item has_one

Declare a one-to-one or many-to-one relationship where the foreign key is in a
different table. For example:

    package Models::Episode;
    ...
    has_one 'brand';

With the above, each instance of C<Models::Episode> will have a C<brand> method
which returns the linked C<Models::Brand> object.

=item has_many

Declare a many-to-one relationship.  For example:

    package Models::Brand;
    ...
    has_many 'episodes';

With the above, each instance of C<Models::Brand> will have an C<episodes>
method which returns a list of linked C<Models::Episode> objects.

=back

Each of the relation functions takes three named arguments, C<package>,
C<finder> and C<key>:

=over 4

=item C<package>

The package name of the class at the other end of the relation.  When omitted,
the relation name is changed to the singular (by removing 's' from the end
except when it ends with 'ies'), converted to a MixedCaseName, and prefixed
with B<Models::>.  For example, C<belongs_to 'service'> generates a C<package>
value of C<Models::Service>.

In the following, the C<package> value is the same as the default:

    belongs_to 'service', package => 'Models::Service';
    has_one 'brand', package => 'Models::Brand';
    has_many 'series', package => 'Models::Series';

=item C<finder>

The name of the query function to call in C<package> to retrieve the object.
For a C<belongs_to> this defaults to C<find>.  For a C<has_many> this defaults
to C<find_all_by_> followed by the singular version of the table name, eg
C<find_all_by_service>.  And for a C<has_one> this defaults to C<find_by_>
followed by the singular version of the table name, eg C<find_by_broadcast>.

In the following, the C<finder> value is the same as the default:

    belongs_to 'service', finder => 'find';
    has_one 'brand', finder => 'find_by_episode';
    has_many 'series', finder => 'find_all_by_series';

=item C<key>

The attribute to pass to the C<finder> function.  For C<has_one> and
C<has_many> relations this is C<id>.  For C<belongs_to> it is the relation name
followed by C<_id>.

In the following, the C<key> value is the same as the default:

    belongs_to 'service', key => 'service_id';
    has_one 'brand', key => 'id';
    has_many 'series', key => 'id';

=back

=head1 QUERIES

The C<query> function makes SQL from the package's C<%sql> hash callable as a
class or instance method, with parameters passed on as bind variables (model
objects parameters are converted to keys via their C<id> method).  For example:

    package Models::Service;

    ...

    query 'find_by_directory';
    our %sql = (
        find_by_directory => q{
            SELECT * FROM services WHERE directory=?
        },
    );

    ...

    $service = Models::Service->find_by_directory('radio1');

This would execute the following SQL and return an instance of the
C<Models::Service> class.

    SELECT * FROM services WHERE directory='radio1'

=head2 Query Options

C<query> also allows additional options to be passed:

    query 'name_of_query', %opts;

The following options are recognised:

=over 4

=item type

The type of value returned by the query can be varied with the C<type>
option, which must have one of the following values:

=over 4

=item C<->

Fetch a single row and return it wrapped as an instance of this model class.

=item C<[-]>

Fetch all the available rows and return a list of model objects.

=item C<1>

Fetch a single row and return just the first column as a scalar.

=item C<[1]>

Fetch all the rows and return a list containing just the first column from
each as a scalar.

=item C<x>

No return value.

=back

The default is C<1> if the query name begins with "count", C<-> if it begins
with "find" (but not "find_all"), C<x> if it begins with any of: set, add,
remove, create, replace, update, delete; or C<[-]> otherwise.

Some examples:

    # Return the number of rows
    query 'count', type => '1';
    # Return a list of the first column from each result row
    query 'scheduled_days', type => '[1]';
    # Return a single row, wrapped as a model object
    query 'find_by_directory', type => '-';
    # Return a list of model objects
    query 'find_all_by_series', type => '[-]';

=item fn

The C<fn> parameter provides a function to convert the provided arguments into a
list of bind variables, and optionally also to declare which (if any) of the
model relations will be in the result set.  The function is called in list
context with the provided arguments, including the leading class or object.
The function should return a list of bind variables, optionally preceded by
an array reference indicating the list of relations to be filled in from the
result set.

=item postfn

TODO, document me.

=item include

TODO, document me.

=back

=head1 METHODS

Columns are automatically exposed as methods on a model object, eg:

    $brand = Models::Brand->find(1);
    print $brand->name . "\n";

Model classes also gain the following methods (which also happen to work as
object methods):

=over 4

=item $foo = Models::Foo-E<gt>find($id)

Return the row identified by the supplied primary key.

=item @foos = @{ Models::Foo-E<gt>find_all }

Return all the rows in the table.

=item $foo = @foos = @{ Models::Foo-E<gt>find_all_by_COLUMN($value) }

Return all rows where the given COLUMN matches the value.

=item $foo = Models::Foo-E<gt>find_by_COLUMN($value)

Return the row where the given COLUMN matches the value.

=back

See L<Pinwheel::Model::Base> for additional methods gained by model objects.

=head1 BUGS

TODO, document the following: sql_param, hash refs as query parameters, the
C<?$...$> syntax, prefetch, inheritance key/value, how 'describe' is used at
import time, wrapping of dates and times, caching.
Plus anything marked as "TODO" above.

C<import> should make use of Exporter, so the caller can avoid importing
C<query> etc. if they so wish.

The query type values ("-", "[-]", etc) should probably be made available as
constants (e.g. QUERY_RETURN_ONE_MODEL, QUERY_RETURN_MANY_MODELS, etc).

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

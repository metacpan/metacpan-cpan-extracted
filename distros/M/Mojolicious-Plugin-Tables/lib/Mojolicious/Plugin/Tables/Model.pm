package Mojolicious::Plugin::Tables::Model;

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;
use DBIx::Class::Schema::Loader::Dynamic;

__PACKAGE__->mk_group_accessors(inherited => qw/log connect_info model/);

sub setup {
    my ($class, $conf) = @_;
    if (my $connect_info = $conf->{connect_info}) {
        $class->connect_info($connect_info)
    } else {
        die "Provide connect_info either as a config value or an override"
            unless $class->connect_info
    }

    # to return a schema object-ref here say 'connect' instead of 'connection'.
    my $schema = $class->connection(@{$class->connect_info});

    DBIx::Class::Schema::Loader::Dynamic->new(
        left_base_classes   => $class->row_base,
        rel_name_map        => $class->rel_name_map,
        custom_column_info  => sub { $class->custom_column_info(@_) },
        naming              => 'v8',
        use_namespaces      => 0,
        schema              => $schema,
        %{$conf->{loader_opts}||{}},
    )->load;

    $schema->model($schema->_model);

    return $schema;
}

sub row_base { 'Mojolicious::Plugin::Tables::Model::Row' }

sub glossary { +{ id => 'Identifier' } }

sub input_attrs { +{ name => { size=>80 } } }

sub make_label {
    my $self = shift;
    my $name = shift;
    my @label = split '_', $name;
    for (@label) {
        $_ = $self->glossary->{$_}, next if $self->glossary->{$_};
        $_ = ucfirst
    }
    join(' ', @label)
}

sub custom_column_info {
    my ($class, $table, $column, $column_info) = @_;
    my $info = { label => $class->make_label($column) };
    my $attrs1;
    for ($column_info->{data_type}) {
        $attrs1 =
            /numeric|integer/ ? {type=>'number'} :
            /timestamp/       ? {type=>'datetime-local'} :
            /date|time/       ? {type=>$_} :
            {};
    }
    my $attrs2 = $class->input_attrs->{$column} || {};
    $info->{input_attrs} = {%$attrs1, %$attrs2} if keys(%$attrs1) || keys(%$attrs2);
    $info
};

sub rel_name_map { +{} }

sub _model {
    my $schema  = shift;

    my @tablist = ();
    my %bytable = ();
    #my $log     = $schema->log;
    #$log->debug("$schema is building its model");
    for my $source (sort $schema->sources) {
        my $s = $schema->source($source);
        my @has_a;
        my %has_many;
        for my $rel ($s->relationships) {
            my $info   = $s->relationship_info($rel);
            my $ftable = $info->{class}->table;
            my $attrs  = $info->{attrs};
            my $card   = $attrs->{accessor};
            if ($card eq 'single') {
                my $fks = $attrs->{fk_columns};
                my @fks = keys %$fks;
                push @has_a, { fkey=>$fks[0], parent=>$rel, label=>$schema->make_label($rel), ptable=>$ftable }
                    if @fks == 1
            } elsif ($card eq 'filter') {
                my @ffkeys = keys %{$info->{cond}};
                if (@ffkeys == 1) {
                    (my $cfkey = $ffkeys[0]) =~ s/^foreign\.//;
                    push @has_a, { fkey=>$cfkey, parent=>$rel, label=>$schema->make_label($rel), ptable=>$ftable }
                } else {
                    warn __PACKAGE__." model: $source: $rel: multi-barrelled M-1 keys not supported\n"
                }
            } elsif ($card eq 'multi') {
                my $fsource_name = $info->{source};
                my $fsource      = $schema->source($fsource_name);
                my $fpkey        = join(',', $fsource->primary_columns);
                my @ffkeys       = keys %{$info->{cond}};
                if (@ffkeys == 1) {
                    (my $cfkey = $ffkeys[0]) =~ s/^foreign\.//;
                    $has_many{$rel} = {ctable=>$ftable, cpkey=>$fpkey, cfkey=>$cfkey, label=>$schema->make_label($rel)};
                } else {
                    warn __PACKAGE__." model: $source: $rel: multi-barrelled 1-M keys not supported\n"
                }
            } else {
                warn __PACKAGE__." model: $source: $rel: strange cardinality: $card\n";
            }
        }
        my %bycolumn = map {
                          my %info = %{$s->column_info($_)};
                          delete $info{name};
                          /^_/ && delete $info{$_} for keys %info;
                          ( $_ => \%info )
                      } $s->columns;
        for (@has_a) {
            my $fkey = $_->{fkey};
            my $parent = delete $_->{parent};
            $bycolumn{$fkey}->{parent} = $parent if $bycolumn{$fkey};
            $bycolumn{$parent} = $_; # gets {fkey=>, label=>, ptable=>,}
        }
        my $pkeys   = [$s->primary_columns];
        my $pknum   = 0;
        for (@$pkeys) {
            $bycolumn{$_}{is_primary_key} = ++$pknum
        }
        my @columns = map { $_, $bycolumn{$_}{parent}? ($bycolumn{$_}{parent}): () }
                      $s->columns;
        my $label   = $schema->make_label($s->name);
        my $tabinfo = {
                source   => $source,
                columns  => \@columns,
                bycolumn => \%bycolumn,
                has_many => \%has_many,
                label    => $label,
                pkeys    => $pkeys,
        };
        push @tablist, $s->name;
        $bytable{$s->name} = $tabinfo;
    }
    return {schema=>$schema, tablist=>\@tablist, bytable=>\%bytable};
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Tables::Model -- Customize the default generated Tables Model

=head1 SYNOPSIS

    $app->plugin( Tables => {model_class => 'StuffDB'} );

=head1 DESCRIPTION

By supplying your own Model Class you can override most of the default behaviours
and build an enterprise-ready rdbms-based web app.

Your model_class must inherit from Mojolicious::Plugin::Tables::Model.  So, e.g.

    package StuffDB;

    use strict;
    use warnings;

    use base qw/Mojolicious::Plugin::Tables::Model/;

    ...

=head2 model_class METHODS

Your model_class optionally implements any of the following methods to override the default behaviour.

=head3 connect_info

A sub returning an arrayref supplying your locally declared DBI parameters. e.g.

    sub connect_info { [ 'dbi:Pg:dbname="stuff"', '', '' ] }

which works for a Postgres database called 'stuff' accepting IDENT credentials.

=head3 glossary

A sub returning a hashref which maps "syllables" to displaynames.  "Syllables" are all the abbreviated words that
are separated by underscores in your database table and column names.  Any syllable by default is made into a nice
word by simply init-capping it, so the glossary only needs to supply non-obvious displaynames.
The mapping 'id=>Identifier' is built-in.
So for example with table or column names such as "stock", "active_stock", "stock_id", "stock_name",
"dyngrp_id", "mkt_ldr", "ccld_ts" we would supply just this

    sub glossary { +{
        ccld   => 'Cancelled',
        dyngrp => 'Dynamic Group',
        mkt    => 'Market',
        ldr    => 'Leader',
        ts     => 'Timestamp',
    } }

.. and we will see labels "Stock", "Active Stock", "Stock Identifier", "Stock Name",
"Dynamic Group Identifier", "Market Leader", "Cancelled Timestamp" in the generated application.
 
=head3 input_attrs

A sub returning a hashref giving appropriate html5 form-input tag attributes for any fieldname.  By default these
attributes are derived depending on field type and database length. But these can be overriden here, e.g.

    sub input_attrs { +{
        var_pct => { min=>-100, max=>100 },
        vol_pct => { min=>-100, max=>500 },
        name    => { size=>80 },
        picture => { size=>80, type=>'url' },
        email   => { size=>40, type=>'email' },
        email_verified => { type=>'checkbox' },
        ts      => { step=>1 },
    } }

=head3 rel_name_map

A sub returning a hashref which maps default generated relationship names to more appropriate choices.  More detail
in L<DBIx::Class::Schema::Loader>.  e.g.

    sub rel_name_map { +{
        AssetRange => { range_age => 'range' },
        Asset      => { symbol    => 'lse_security' },
        Dyngrp     => { dyngrps   => 'subgroups' },
        Trader     => { authority_granters => 'grants_to',
                        authority_traders  => 'audit_trail' },
    } }

=head2 ResultClass Methods

After creating a model_class as described above you will automatically be able to introduce 'ResultClass' classes
for any of the tables in your database.  Place these directly 'under' your model_class, e.g. if StuffDB is
your model_class and you want to introduce a nice stringify rule for the table 'asset', then you can
create the class StuffDB::Asset and give it just the stringify method. e.g. from http://octalfutures.com :

    package StuffDB::Asset;

    use strict;
    use warnings;

    sub stringify {
        my $self = shift;
        my $latest_str = '';
        if (my $latest = $self->latest) {
            $latest_str = " $latest";
            if (my $var_pct = $self->var_pct) {
                $latest_str .= sprintf ' (%+.2f%%)', $var_pct
            }
        }
        return sprintf '%s (%s)%s', $self->name, $self->dataset_code, $latest_str
    }

    1;

Any of these ResultClasses will inherit all methods of DBIx::Class::Row.
In addition these methods inherit all methods of Mojolicious::Plugin::Tables::Model::Row, namely:

=head3 stringify

It's recommended to implement this.  The stringification logic for this table.  The default implementation 
tries to use any columns such as 'cd' or 'description', and falls back to joining the primary keys.

=head3 present

Generate a presentation of a row->column value, formatted depending on type.  Args: column_name, a hash-ref containing schema info about that column, and a hashref containing context info (currently just 'foredit=>1').

=head3 options

Given: column_name, a hash-ref containing schema info about that column, a hash-ref containing info about the parent table, the full DBIX::Class schema, and a hash-ref containing schema information about all tables..

Generate the full pick-list that lets the fk $column pick from its parent,
in a structure suitable for the Mojolicious 'select_field' tag.  The default version simply lists all choices
(limited by safety row-count of 200) but inherited versions are expected to do more
context-sensitive filtering.  Works as a class method to support the 'add' context.

=head3 nuke

Perform full depth-wise destruction of a database record.  The default implementation runs an alghorithm to delete
all child records and finally delete $self.  Override this to prohibit (by dieing) or perform additional work.

=head3 all the rest

Of course, all the methods described at L<DBIx::Class::Row> can be overriden here.

=head1 SEE ALSO

L<Mojolicious::Plugin::Tables>

=cut


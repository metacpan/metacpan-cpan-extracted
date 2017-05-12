package Mojolicious::Plugin::QuickPg;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Pg;
use Carp;

our $VERSION = '1.6';
our $Debug = 0;
has pg => sub { +{} };

sub register {
    my ($plugin, $app, $conf) = @_;
    my $version = undef;
    croak qq{DSN is empty! See perldoc...\n} unless $conf->{dsn};
    
    $plugin->pg(Mojo::Pg->new($conf->{dsn}));
    $Debug = $conf->{debug};
    
    eval {
      $version =  $plugin->pg->db->query('select version()')->hash;
    };
    croak qq{Invalid dsn: $@ \n} if $@;
    $app->log->info($version->{version}) if ($conf->{debug});
    
    $app->helper( qselect => sub {$plugin->_quick_select(@_)});
    $app->helper( qinsert => sub {$plugin->_quick_insert(@_)});
    $app->helper( qupdate => sub {$plugin->_quick_update(@_)});
    $app->helper( qdelete => sub {$plugin->_quick_delete(@_)});
    $app->helper( qcount  => sub {$plugin->_quick_count(@_)});
    $app->helper( qcustom => sub {
        my ($self, $sql, @params) = @_;
        say "DEBUG: $sql" if $Debug;
        eval {
            local $SIG{__WARN__} = sub {};
            return $plugin->pg->db->query($sql,@params);
        };
        
        });
    $app->helper( qerror  => sub { return $@ });
}

sub _quick_insert {
    my ($plugin, $self, $table_name, $data) = @_;
    return $plugin->_quick_query('INSERT', $table_name, $data);
}

#
sub _quick_update {
    my ($plugin, $self, $table_name, $where, $data) = @_;
    return $plugin->_quick_query('UPDATE', $table_name, $data, $where);
}
# 
# 
sub _quick_delete {
    my ($plugin, $self, $table_name, $where) = @_;
    return $plugin->_quick_query('DELETE', $table_name, undef, $where);
}
 
sub _quick_select {
    my ($plugin, $self, $table_name, $where, $opts) = @_;
    $where = $where || {};
    return $plugin->_quick_query('SELECT', $table_name, $opts, $where);
}

 
sub _quick_count {
    my ($plugin, $self, $table_name, $where) = @_;
    $where = $where || {};
    my $opts = {}; #Options are irrelevant for a count.
    return $plugin->_quick_query('COUNT', $table_name, $opts, $where);
}

#############
sub _quick_query {
    my ($self, $type, $table_name, $data, $where) = @_;
    # Basic sanity checks first...
    if ($type !~ m{^ (SELECT|INSERT|UPDATE|DELETE|COUNT) $}x) {
        carp "Unrecognised query type $type!";
        return;
    }
    if (!$table_name || ref $table_name) {
        carp "Expected table name as a straight scalar";
        return;
    }
    if (($type eq 'INSERT' || $type eq 'UPDATE')
        && (!$data || ref $data ne 'HASH')) 
    {
        carp "Expected a hashref of changes";
        return;
    }
    if (($type =~ m{^ (SELECT|UPDATE|DELETE|COUNT) $}x)
        && (!$where)) {
        carp "Expected where conditions";
        return;
    }
    
    my ($sql, @bind_params) = $self->_generate_sql(
        $type, $table_name, $data, $where
    );
    say "DEBUG: $sql" if $Debug;
    
    if ($type eq 'SELECT') {
        return $self->pg->db->query($sql, @bind_params)->hash unless wantarray;
        return $self->pg->db->query($sql, @bind_params)->hashes->to_array;
    } elsif ($type eq 'COUNT') {
        my $row = $self->pg->db->query($sql, @bind_params)->hash;
        return $row->{count};
    } else {
        # INSERT (default field name = id)
        if ($type eq 'INSERT') {
        # get primary key from table
        my $PK = 'id'; # default PK column is 'id'
        my $pkey =  $self->pg->db->query(qq{SELECT a.attname FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid
                                         AND a.attnum = ANY(i.indkey) WHERE  i.indrelid = '$table_name'::regclass AND i.indisprimary
                                         ORDER BY a.attnum DESC});
        # if id exists in PKeys get it, else - get last elem
        while (my $next = $pkey->hash) {
             if ( $next->{attname} eq 'id' ) {
                $PK = $next->{attname};
                # Note that "finish" needs to be called if you are not fetching all the possible rows
                $pkey->finish;
                last;
             }
             else {
                $PK = $next->{attname};
             }
        }
        
        $sql .= ' returning ' . $PK;
        
            eval {
            return $self->pg->db->query($sql, @bind_params)->hash->{$PK};
            };
        } else {
        # delete/update
            eval {
            return $self->pg->db->query($sql, @bind_params)->rows;
            };
        }
        
    }
}
 
sub _generate_sql {
    my ($self, $type, $table_name, $data, $where) = @_;
 
    my $which_cols = '*';
    my $opts = $type eq 'SELECT' && $data ? $data : {};
    if ($opts->{columns}) {
        my @cols = (ref $opts->{columns}) 
            ? @{ $opts->{columns} }
            :    $opts->{columns} ;
        $which_cols = join(',', map { $self->_quote_identifier($_) } @cols);
    }
 
    $table_name = $self->_quote_identifier($table_name);
    my @bind_params;
 
    my $sql = {
        SELECT => "SELECT $which_cols FROM $table_name",
        INSERT => "INSERT INTO $table_name ",
        UPDATE => "UPDATE $table_name SET ",
        DELETE => "DELETE FROM $table_name ",
        COUNT => "SELECT COUNT(*) FROM $table_name",
    }->{$type};
    
    if ($type eq 'INSERT') {
        my (@keys, @values);
        for my $key (sort keys %$data) {
            my $value = $data->{$key};
            push @keys, $self->_quote_identifier($key);
            if (ref $value eq 'SCALAR') {
                # If it's a scalarref it goes in the SQL as it is; this is a
                # potential SQL injection risk, but is documented as such - it
                # allows the user to include arbitrary SQL, at their own risk.
                push @values, $$value;
            } else {
                push @values, "?";
                push @bind_params, $value;
            }
        }
 
        $sql .= sprintf "(%s) VALUES (%s)",
            join(',', @keys), join(',', @values);
    }
 
    if ($type eq 'UPDATE') {
        my @sql;
        for (sort keys %$data) {
          push @sql, $self->_quote_identifier($_) . '=' .
            (ref $data->{$_} eq 'SCALAR' ? ${$data->{$_}} : "?");
          push @bind_params, $data->{$_} if (ref $data->{$_} ne 'SCALAR');
        }
        $sql .= join ',', @sql;
    }
 
    if ($type eq 'UPDATE' || $type eq 'DELETE' || $type eq 'SELECT' || $type eq 'COUNT')
    {
        if ($where && !ref $where) {
            $sql .= " WHERE " . $where;
        } elsif ( ref $where eq 'HASH' ) {
            my @stmts;
            foreach my $k ( sort keys %$where ) {
                my $v = $where->{$k};
                if ( ref $v eq 'HASH' ) {
                    my $not = delete $v->{'not'};
                    while (my($op,$value) = each %$v ) {
                        my ($cond, $add_bind_param) 
                            = $self->_get_where_sql($op, $not, $value);
                        push @stmts, $self->_quote_identifier($k) . $cond; 
                        push @bind_params, $v->{$op} if $add_bind_param;
                    }
                } else {
                    my $clause .= $self->_quote_identifier($k);
                    if ( ! defined $v ) {
                        $clause .= ' IS NULL';
                    }
                    elsif ( ! ref $v ) {
                        $clause .= '=?';
                        push @bind_params, $v;
                    }
                    elsif ( ref $v eq 'ARRAY' ) {
                        $clause .= ' IN (' . (join ',', map { '?' } @$v) . ')';
                        push @bind_params, @$v;
                    }
                    push @stmts, $clause;
                }
            }
            $sql .= " WHERE " . join " AND ", @stmts if keys %$where;
        } elsif (ref $where) {
            carp "Can't handle ref " . ref $where . " for where";
            return;
        }
    }
 
    # Add an ORDER BY clause, if we want to:
    if (exists $opts->{order_by} and defined $opts->{order_by}) {
        $sql .= ' ' . $self->_build_order_by_clause($opts->{order_by});
    }
 
 
    # Add a LIMIT clause if we want to:
    if ((exists $opts->{limit} and defined $opts->{limit}) and (exists $opts->{offset} and defined $opts->{offset})) {
        my $limit = $opts->{limit};
        my $offset = $opts->{offset};
        $offset =~ s/\s+//g;
        $limit =~ s/\s+//g;
        die "Invalid OFFSET param $opts->{offset} !" unless ($offset =~ /^\d+$/);
        if ($limit =~ m{ ^ \d+ (?: , \d+)? $ }x) {
            # Checked for sanity above so safe to interpolate
            $sql .= " LIMIT $limit OFFSET $offset";
        } else {
            die "Invalid LIMIT param $opts->{limit} !";
        }
    } elsif ($type eq 'SELECT' && !wantarray) {
        # We're only returning one row in scalar context, so don't ask for any
        # more than that
        $sql .= " LIMIT 1 OFFSET 0";
    }
     
    return ($sql, @bind_params);
}
 
sub _get_where_sql {
    my ($self, $op, $not, $value) = @_;
 
    $op = lc $op;
 
    # "IS" needs special-casing, as it will be either "IS NULL" or "IS NOT NULL"
    # - there's no need to return a bind param for that.
    if ($op eq 'is') {
        return $not ? 'IS NOT NULL' : 'IS NULL';
    }
 
    my %st = (
        'like' => ' LIKE ?',
        'is' => ' IS ?',
        'ge' => ' >= ?',
        'gt' => ' > ?',
        'le' => ' <= ?',
        'lt' => ' < ?',
        'eq' => ' = ?',
        'ne' => ' != ?',
    );
 
    # Return the appropriate SQL, and indicate that the value should be added to
    # the bind params
    return (($not ? ' NOT' . $st{$op} : $st{$op}), 1);
}
 
# Given either a column name, or a hashref of e.g. { asc => 'colname' },
# or an arrayref of either, construct an ORDER BY clause (quoting col names)
# e.g.:
# 'foo'              => ORDER BY foo
# { asc => 'foo' }   => ORDER BY foo ASC
# ['foo', 'bar']     => ORDER BY foo, bar
# [ { asc => 'foo' }, { desc => 'bar' } ]
#      => 'ORDER BY foo ASC, bar DESC
sub _build_order_by_clause {
    my ($self, $in) = @_;
 
    # Input could be a straight scalar, or a hashref, or an arrayref of either
    # straight scalars or hashrefs.  Turn a straight scalar into an arrayref to
    # avoid repeating ourselves.
    $in = [ $in ] unless ref $in eq 'ARRAY';
 
    # Now, for each of the fields given, add them to the clause
    my @sort_fields;
    for my $field (@$in) {
        if (!ref $field) {
            push @sort_fields, $self->_quote_identifier($field);
        } elsif (ref $field eq 'HASH') {
            my ($order, $name) = %$field;
            $order = uc $order;
            if ($order ne 'ASC' && $order ne 'DESC') {
                die "Invalid sort order $order used in order_by option!";
            }
            # $order has been checked to be 'ASC' or 'DESC' above, so safe to
            # interpolate
            push @sort_fields, $self->_quote_identifier($name) . " $order";
        }
    }
 
    return "ORDER BY " . join ', ', @sort_fields;
}

# A wrapper around DBI's quote_identifier which first splits on ".", so that
# e.g. database.table gets quoted as `database`.`table`, not `database.table`
sub _quote_identifier {
    my ($self, $identifier) = @_;
    return join '.', map { 
        $self->pg->db->dbh->quote_identifier($_) 
    } split /\./, $identifier;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::QuickPg - Mojolicious Plugin that provided quick access methods for Mojo::Pg

=head1 SYNOPSIS

  # Mojolicious::Lite
  
  plugin 'QuickPg' => {dsn => 'postgresql://sri:123456@localhost/testdb'};
  
  # Mojolicious (not Lite)
  # in startup
  
  $self->plugin('Mojolicious::Plugin::QuickPg' =>
                { dsn => 'postgresql://sri:123456@localhost/testdb',
                  debug => 1 } );
                                                   
  # in controller
  # quick select
  # returns array of hashes [{},{}]
  
  my ($all_table) = $c->qselect('table_name');
  
  # returns hash {}
  
  my $one_row = $c->qselect('table_name');
  # example with offset and limits
  my ($array_ref) = $c->qselect('models', {},{
                                       limit => 10,
                                       offset => 0 }
                                );
  
  # quick count
  $c->qcount('table_name', {name => {like => 'Mos%'} } );
  
  # quick insert
  # returns value of primary key (like as last_insert_id on MySQL)
  
  my $id = $c->qinsert('models', { name => 'Moscow',
                                   foto => 'https://www.flickr.com/search/?text=Moscow' } );
  # or you can do like this
  
  my $params = $c->req->json;
  
  # Do not forget to validate $params before it:
  
  my $id = $c->insert('models', $params);
  
  # quick update
  # returns numbers of updated rows
  
  $c->qupdate('models', {id => $id}, { name => 'New York',
                                       foto => 'https://www.flickr.com/search/?text=New%20York'
                                      } );
  
  # quick delete
  # returns numbers of deleted rows
  
  $c->qdelete('models', { id => $id });
  
  # catch the errors on insert/delete methods
  
  $c->qerror; # returns $@ value
  
  # custom requests - returns Mojo::Pg::Results object
  
  my $result = $s->qcustom('SELECT a.id, b.name
                            FROM table1 a, table2 b
                            WHERE a.id = b.id AND b.name = ?', $name);
  my $arrays = $result->hashes->to_array;                              


=head1 DESCRIPTION

L<Mojolicous::Plugin::QuickPg> is a plugin for Mojolicious apps thas provide simple access to L<Mojo::Pg>.
The most part of the code for plugin is taken from L<Dancer::Plugin::Database::Core::Handle> (under Artistic License)

=head1 HELPERS

L<Mojolicious::Plugin::QuickPg> contains next helpers: I<qselect>, I<qinsert>, I<qupdate>, I<qdelete>, I<qcustom>, I<qerror>,
I<qcount>.

=head2 C<qselect>

my $one_row = $c->qselect('table_name', {id => 1},
                         { order_by => {desc => 'id'}, limit => 10, offset => 5, columns => qw[id name]});

For more examples see /examples/*

=head2 C<qinsert>

For examples see /examples/* 

=head2 C<qupdate>

For examples see /examples/*

=head2 C<qdelete>

For examples see /examples/*

=head2 C<qcustom>

For examples see /examples/*

=head2 C<qcount>

For examples see /examples/* 

=head2 C<qerror>

For more examples see /examples/* 

=head1 CONFIG

L<Mojolicious::Plugin::QuickPg> configuration support two keys.

=over 2

=item * dsn

 $self->plugin('Mojolicious::Plugin::QuickPg' =>
                            {dsn => 'postgresql://sri:123456@localhost/testdb'} );

Set connection string

=item * debug

  # Lite
  
  plugin 'QuickPg' => {dsn => 'postgresql://sri:123456@localhost/testdb', debug => 1};
  
  # Adults App :)
  
  $self->plugin('Mojolicious::Plugin::QuickPg' =>
                                    { dsn   => 'postgresql://sri:123456@localhost/testdb',
                                      debug => 1 } );
                                                   
This key switches on|off printing on console SQL requests.

=back

=head1 SEE ALSO

L<Mojo::Pg> L<Mojolicious> L<Mojolicious::Guides> L<http://mojolicious.org>.

=head1 AUTHOR

Pavel Kuptsov <pkuptsov@gmail.com>

=head1 THANKS

Alberto Simões <ambs@perl-hackers.net>
Sebastian Riedel <sri@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-quickpg at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-QuickPg>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Bitbucket

L<https://bitbucket.org/pkuptsov/mojolicious-plugin-quickpg>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-QuickPg>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-QuickPg>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Mojolicious-Plugin-QuickPg>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-QuickPg>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-QuickPg>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2016 by Pavel Kuptsov.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


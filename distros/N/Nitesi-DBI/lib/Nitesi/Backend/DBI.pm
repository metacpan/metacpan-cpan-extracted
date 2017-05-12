package Nitesi::Backend::DBI;

use Moo::Role;
use Nitesi::Provider::Object qw/api_object/;

=head1 NAME

Nitesi::Backend::DBI - DBI backend for Nitesi Shop Machine

=head1 ATTRIBUTES

=head2 dbh

DBI database handle.

=head2 log_queries

Subroutine to log database queries.

=head2 query

L<Nitesi::Query::DBI> object.

=cut

with 'Nitesi::Provider::Role';

has dbh => (
    is => 'rw',
);

has log_queries => (
    is => 'rw',
);

has query => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my %args = (dbh => $self->dbh);

        if (ref($self->log_queries) eq 'CODE') {
            $args{log_queries} = $self->log_queries;
        }

        Nitesi::Query::DBI->new(%args);
    },
);

=head1 METHODS

=head2 attributes

Provides attributes for current object.

=cut

sub attributes {
    my $self = shift;
    my ($name, $value, @attributes, $class);

    my @classes = grep {$_ ne 'WITH' && $_ ne 'AND'} split(/__/, ref($self));
    my $map_ref = $self->attribute_map;

    while (($name, $value) = each %$map_ref) {
        if ($value->{role} eq $classes[0]) {
            push (@attributes, $name);
        }
    }

    return @attributes;
}

=head2 create

Creates a record.

=cut

sub create {
    my ($self, %data) = @_;
    my ($info, $key, $name, $value, $q, @ret);

    $info = $self->api_info->{$self->base_role};
    $key = $info->{key};

    $q = $self->_build_query('create', %data);

    for my $insert (@$q) {
        push @ret, $self->query->insert(@$insert);
    }

    unless ($self->$key) {
        $self->$key($ret[0]);
    }

    return $self;
}

=head2 update

Updates a record.

=cut

sub update {
    my ($self, %data) = @_;
    my ($key, $name, $value, $ret, $map_ref, %updates);

    my $sql = $self->_build_query('update', %data);

    $map_ref = $self->attribute_map;

    # populate product data from input
    while (($name, $value) = each %data) {
        next unless defined $value;
        if (exists $map_ref->{$name}->{foreign}) {
            $updates{$map_ref->{$name}->{foreign}->{table}}->{$name} = $value;
        }
        else {
            $updates{$map_ref->{$name}->{role}}->{$name} = $value;
        }
        $self->$name($value);
    }

    while (($name, $value) = each %updates) {
        %data = %{$updates{$name}};

        # map data to our setup
        if ($self->{field_map}) {
            my ($orig, $mapped);

            while (($orig, $mapped) = each %{$self->{field_map}}) {
                if ($mapped && exists $data{$orig}) {
                    $data{$mapped} = delete $data{$orig};
                }
                delete $data{$orig};
            }
        }

        # primary or secondary table ?
        my $info = $self->api_info->{$name};

        if ($name =~ /::/) {
            $key = $info->{key};
        }
        else {
            $key = $self->api_info->{$self->base_role}->{key};

            # loop over fields in data
            my ($d_name, $d_value, $d_key, $d_field, $d_code, %d_where);

            while (($d_name, $d_value) = each %data) {
                %d_where = %{$map_ref->{$d_name}->{foreign}->{where}};
                $d_where{$key} = $self->$key;

                # key in secondary table
                $d_key = $map_ref->{$d_name}->{foreign}->{key};
                $d_field = $map_ref->{$d_name}->{foreign}->{field};

                if ($d_code = $self->query->select_field(table => $name,
                                                        where => \%d_where,
                                                        field => $d_key)) {
                    $self->query->update(table => $name,
                                         where => {$d_key => $d_code},
                                         set => {$d_field => $d_value},
                                         );
                }
                else {
                    $d_code = $self->query->insert($name,
                                                   {$key => $d_where{$key},
                                                    $d_field => $d_value,
                                                    @{$map_ref->{$d_name}->{foreign}->{set} || []},
                                                }
                                        );
                }
            }

            next;
        }

        if ($name eq $self->base_role || ! $info->{sparse}) {
            # populate product data from input
            $ret = $self->query->update(table => $info->{table},
                                        where => {$key => $self->$key},
                                        set => \%data);
        }
        else {
            # check whether we need update or insert
            $key = $info->{key};

            $ret = $self->query->select_field(table => $info->{table},
                                              field => $key,
                                              where => {$key => $self->$key},
                                             );

            if ($ret) {
                $ret = $self->query->update(table => $info->{table},
                                            where => {$key => $self->$key},
                                            set => \%data);
            }
            else {
                $data{$key} = $self->$key;

                $ret = $self->query->insert($info->{table}, \%data);
            }
        }
    }

    return $self;
}

=head2 delete

Delete a record.

=cut

sub delete {
    my $self = shift;
    my ($code, $info, $key);

    $info = $self->api_info->{$self->base_role};
    $key = $info->{key};

    unless ($code = $self->$key) {
        die "Cannot delete product without key $key.\n";
    }

    # delete product
    my $ret = $self->query->delete(table => $info->{table},
			 where => {$key => $code});

    # delete foreign records
    if ($info->{foreign}) {
        my ($name, $value);

        while (($name, $value) = each %{$info->{foreign}}) {
             $self->query->delete(table => $value->{table},
                                  where => {$key => $code});
        }
    }

    return $ret;
}

=head2 search

Searches records.

=cut

sub search {
    my ($self, %args) = @_;
    my ($info, $field_ref, $virt_ref, $set, $name, $map, $sql);

    $info = $self->api_info->{$self->base_role};
    $field_ref = $self->_db_fields;
    $virt_ref = $self->_virtual_fields;

    $sql = $self->_build_query('select', %args);

    # search database
    $set = $self->query->select(%$sql);

    my @oo_list;
    
    for my $record (@$set) {
        while (($name, $map) = each %$field_ref) {
            if ($map) {
                $record->{$map} = delete $record->{$name};
            }
        }

        push @oo_list, api_object(backend => 'DBI',
                                  class => $self->base_role,
                                  name => $self->api_info->{$self->base_role}->{table},
                                  record => $record);
    }

    return \@oo_list;
}

=head2 load

Loads a record

=cut

sub load {
    my ($self) = shift;
    my ($info, $set, $key, $field_ref, $sql);

    $info = $self->api_info->{$self->base_role};
    $key = $info->{key};

    return unless $self->$key;

    $field_ref = $self->_db_fields;

    $sql = $self->_build_query('select',
                               where => {$key => $self->$key});

    # search database
    $set = $self->query->select(%$sql);

    if (@$set) {
        if (exists $info->{foreign}) {
            unless ($set = $self->_merge_query($set)) {
                die "Failed to merge results.\n";
            }
        }

        if (@$set > 1) {
            die "Multiple records returned.\n";
        }

        my ($name, $map, $record);

        $record = $set->[0];

        while (($name, $map) = each %$field_ref) {
            if ($map) {
                $self->$map($record->{$name});
            }
            else {
                $self->$name($record->{$name});
            }
        }

        return $self;
    }

    return;
}

=head2 save

Saves a record.

=cut

sub save {
    my ($self) = @_;
    my (%data);

    # gather data 
    %data = (sku => $self->sku,
	     name => $self->name);

    if ($self->{field_map}) {
	my ($orig, $mapped);

	while (($orig, $mapped) = each %{$self->{field_map}}) {
	    if ($mapped) {
		$data{$mapped} = delete $data{$orig};
	    }
	    delete $data{$orig};
	}
    }

    # save product to database
    $self->query->insert($self->api_name, \%data);
}

=head2 dump

Dumps a record.

=cut

sub dump {
    my $self = shift;
    my ($field_ref, %data);

    $self->load();

    for my $name ($self->attributes) {
        $data{$name} = $self->$name;
    }

    # add virtual fields
    $field_ref = $self->_virtual_fields();

    for my $field (keys %$field_ref) {
        $self->$field;
    }

    return \%data;
}

# determines fields to be retrieved from database
# based on attributes and mapping

sub _db_fields {
    my $self = shift;
    my (%fields, $name, $ref);
    my @classes = grep {$_ ne 'WITH' && $_ ne 'AND'} split(/__/, ref($self));

    while (($name, $ref) = each %{$self->attribute_map}) {
        next unless $ref->{role} eq $classes[0];
        next if $ref->{virtual};

        if (exists $ref->{map}) {
            next unless $ref->{map};
            $fields{$ref->{map}} = $name;
        }
        else {
            $fields{$name} = '';
        }
    }

    return \%fields;
}

sub _virtual_fields {
    my $self = shift;
    my (%fields, $name, $ref);
    my @classes = grep {$_ ne 'WITH' && $_ ne 'AND'} split(/__/, ref($self));

    while (($name, $ref) = each %{$self->attribute_map}) {
        next unless $ref->{role} eq $classes[0];
        next unless $ref->{virtual};

        $fields{$name} = '';
    }

    return \%fields;
}

sub _merge_query {
    my ($self, $set) = @_;
    my ($info, $key, $field_ref, $f_field, $f_name, $f_value, %f_select, $result, %extra);

    $info = $self->api_info->{$self->base_role};
    $key = $info->{key};

    $field_ref = $self->_db_fields;

    if (exists $info->{foreign}) {
        my ($f_name, $f_value);

        while (($f_name, $f_value) = each %{$info->{foreign}}) {
            if ($f_name !~ /::/) {
                if ($f_value->{unique}) {
                    if ($f_value->{where}) {
                        for my $w_name (keys %{$f_value->{where}}) {
                            push @{$f_select{$w_name}}, $f_value->{where}->{$w_name};
                        }
                        $f_field = $f_value->{field};
                    }
                    delete $field_ref->{$f_name};
                }
            }
        }

        for my $ref (@$set) {
            for my $w_name (keys %f_select) {
                if (exists $ref->{$w_name} &&
                    defined $ref->{$w_name}) {
                    for my $w_value (@{$f_select{$w_name}}) {
                        if ($ref->{$w_name} eq $w_value) {
                            $extra{$w_value} = $ref->{$f_field};
                        }
                    }
                }
                delete $ref->{$w_name};
                delete $ref->{$f_field};
            }
        }

        if (keys %extra) {
            $result = [{%{$set->[0]}, %extra}];
            return $result;
        }

        # foreign results not present
        return $set;
    }

    return;
}

sub _build_query {
    my ($self, $function, %args) = @_;
    my ($info, $key, $field_ref, $sql, $left_join, $join_table, @join_fields,
        %f_set, %f_select, @foreign_names);

    $info = $self->api_info->{$self->base_role};
    $key = $info->{key};

    $field_ref = $self->_db_fields;

    if (exists $info->{foreign}) {
        my ($f_name, $f_value);

        while (($f_name, $f_value) = each %{$info->{foreign}}) {
            if ($f_name !~ /::/) {
                if ($f_value->{unique}) {
                    $left_join = 1;
                    $join_table = $f_value->{table};
                    push @join_fields, $f_value->{field};
                    if ($f_value->{set}) {
                        $f_set{$f_name} = $f_value->{set};
                    }
                    if ($f_value->{where}) {
                        for my $w_name (keys %{$f_value->{where}}) {
                            $f_select{$w_name} = 1;
                        }
                    }
                    push @foreign_names, $f_name;
                    delete $field_ref->{$f_name};
                }
            }
        }
    }

    if ($function eq 'create') {
        # get data to be inserted from %args
        my ($name, $value, $ret, $db, $mapped, %attr, @inserts);

        while (($name, $value) = each %args) {
            next unless defined $value;
            $ret = $self->$name($value);
        }

        # map to current database schema
        while (($db, $mapped) = each %$field_ref) {
            if ($mapped) {
                if (exists $args{$mapped}) {
                    $attr{$db} = $args{$mapped};
                }
                else {
                    $attr{$db} = $self->$mapped;
                }
            }
            elsif (defined $mapped) {
                if (exists $args{$db} && defined $args{$db}) {
                    $attr{$db} = $args{$db};
                }
                else {
                    $attr{$db} = $self->$db;
                }
            }
        }

        push @inserts, [$info->{table} => \%attr];

        if ($join_table) {
            for my $name (@foreign_names) {
                my (%insert);

                if (exists $f_set{$name}) {
                    %insert = @{$f_set{$name}};
                }

                $insert{$join_fields[0]} = $self->$name;

                next unless defined $insert{$join_fields[0]};

                # connecting key
                $insert{$key} = $self->$key;

                push @inserts, [$join_table => \%insert];
            }


        }

        return \@inserts;
    }

    if ($function eq 'update') {
        # get data to be inserted from %args
        my ($name, $value, $ret, $db, $mapped, %attr, @inserts);

        while (($name, $value) = each %args) {
            next unless defined $value;
            $ret = $self->$name($value);
        }

        # map to current database schema
        while (($db, $mapped) = each %$field_ref) {
            if ($mapped && exists $args{$mapped}) {
                $attr{$db} = $args{$mapped};
            }
            elsif (defined $mapped && exists $args{$db}) {
                $attr{$db} = $args{$db};
            }
        }

        push @inserts, [$info->{table} => \%attr];

        if ($join_table) {
            for my $name (@foreign_names) {
                my (%insert);

                if (exists $f_set{$name}) {
                    %insert = @{$f_set{$name}};
                }

                $insert{$join_fields[0]} = $self->$name;

                # connecting key
                $insert{$key} = $self->$key;

                push @inserts, [$join_table => \%insert];
            }


        }

        return \@inserts;
    }


    if ($left_join) {
        if ($args{where}) {
            my ($name, $value);

            while (($name, $value) = each %{$args{where}}) {
                if ($name =~ /^\w+$/) {
                    # prefix with base table
                    $args{where}->{"$info->{table}.$name"}
                        = delete $args{where}->{$name};
                }
            }
        }

        $sql = {join => "$info->{table} =>{$key=$key} $join_table",
                fields => [(map {"$info->{table}.$_"} keys %$field_ref), (map {"$join_table.$_"} (@join_fields, keys %f_select))],
                where => $args{where} || {},
                limit => $args{limit},
                order => $args{order},
                };
    }
    else {
        $sql = {table => $info->{table},
                fields => [keys %$field_ref],
                where => $args{where} || {},
                limit => $args{limit},
                order => $args{order},
               };
    }

    return $sql;
}

sub _map_reverse {
}

=head2 navigation

Dummy method, will removed later.

=cut

sub navigation {
}

=head2 assign

Assigns object to the current one.

=cut

sub assign {
    my ($self, $object) = @_;

    return $self->_manage_assignments($object, 'create');
}

=head2 unassign

Unassigns object from the current one.

=cut

sub unassign {
    my ($self, $object) = @_;

    return $self->_manage_assignments($object, 'delete');
}

=head2 assigned

Returns list of assigned objects.

=cut

sub assigned {
    my ($self, $object) = @_;

    return $self->_manage_assignments($object, 'list');
}

sub _manage_assignments {
    my ($self, $object, $function) = @_;
    my ($role_to, $role_from, $assign_info, $info, $key, $info_from, $key_from, $ret);

    $role_to = $self->base_role;
    $role_from = $object->base_role;

    $info = $self->api_info->{$self->base_role};
    $key = $info->{key};

    $info_from = $object->api_info->{$object->base_role};
    $key_from = $info_from->{key};

    # handle subclassed Nitesi roles
    if (exists $info_from->{base}) {
        if (exists $info->{assign}->{$info_from->{base}}) {
            $role_from = $info_from->{base};
        }
        else{
            $role_from = $info_from->{inherit};
        }
    }

    # determine assignment parameters
    unless (exists $info->{assign}->{$role_from}
            && ($assign_info = $info->{assign}->{$role_from})) {
        die "No assignment info for $role_from with $role_to.\n";
    }

    if ($function eq 'create') {
        $ret = $self->query->insert($assign_info->{table}, 
                                    {$assign_info->{key}->[0] => $object->$key_from,
                         $assign_info->{key}->[1] => $self->$key});
    }
    elsif ($function eq 'delete') {
        if ($self->$key) {
            # delete specific assignment
            $ret = $self->query->delete($assign_info->{table}, {$assign_info->{key}->[0] => $object->$key_from,
                         $assign_info->{key}->[1] => $self->$key});
        }
        else {
            # delete all assignments
            $ret = $self->query->delete($assign_info->{table}, {$assign_info->{key}->[0] => $object->$key_from});
        }
    }
    elsif ($function eq 'list') {
        my @list;

        if ($self->$key) {
            @list = $self->query->select_list_field(table => $assign_info->{table},
                                                    field => $key_from,
                                                    where => {$assign_info->{key}->[1] => $self->$key});
        }
        elsif ($object->$key_from) {
             @list = $self->query->select_list_field(table => $assign_info->{table},
                                                     field => $assign_info->{key}->[1],
                                                     where => {$assign_info->{key}->[0] => $object->$key_from})
        }

        $ret = \@list;
    }

    return $ret;
}

1;

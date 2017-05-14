require 5.001;

package Pilot::DB;

$RECORD_UNCHANGED = 0x00;
$RECORD_NEW       = 0x01;
$RECORD_CHANGED   = 0x02;
$RECORD_DONT_USE  = 0x04;       # jww: ???
$RECORD_DELETED   = 0x80;

$FIELD_DWORD   = 1;
$FIELD_DATE    = 3;
$FIELD_STRING  = 5;
$FIELD_BOOL    = 6;
$FIELD_REPEAT  = 8;

sub new {
    my $self = { };
    bless $self;
    return $self;
}

sub Reconcile {
    my ($self, $base, $ref, $removed, $added, $changed) = @_;

    if (ref $base ne "HASH" or ref $ref ne "HASH") {
        die "only supports reconciliation between hashes\n";
    }

    my $key;
    foreach $key (sort keys %$base) {
        if (not exists $ref->{$key}) {
#           print "r $key\n";
            push @$removed, $key;
        }
    }

    foreach $key (sort keys %$ref) {
        if (not exists $base->{$key}) {
#           print "a $key\n";
            push @$added, $key;
        }
        elsif (flatten_record($base->{$key}) ne flatten_record($ref->{$key})) {
#           print "c $key\n";
            push @$changed, $key;
        }
    }
}

# merge between primary and alternate

sub gen_merge_list {
    my ($self, $base, $ref, $key_hash) = @_;

    my (@removed, @added, @changed) = ();
    $self->Reconcile($base, $ref, \@removed, \@added, \@changed);

    if ($key_hash) {
        foreach $elem (@removed, @added, @changed) {
            $key_hash->{$elem} = 1;
        }
    }

    return (\@removed, \@added, \@changed);
}

sub Merge {
    my ($self, $base_p, $ref_p, $base_a, $ref_a, $notify) = @_;

    my %key_hash_p = ();
    my ($removed_p, $added_p, $changed_p) =
        $self->gen_merge_list($base_p, $ref_p, \%key_hash_p);

    print "merging ...\n" if $notify;

    my ($removed_a, $added_a, $changed_a) =
        $self->gen_merge_list($base_a, $ref_a);

    my $elem;
    foreach $elem (@$removed_a) {
        if (not exists $key_hash_p{$elem}) {
            $self->Remove($ref_p, $elem);
        }
    }

    foreach $elem (@$added_a) {
        $self->Add($ref_p, $elem, $ref_a->{$elem});
    }

    foreach $elem (@$changed_a) {
        if (not exists $key_hash_p{$elem}) {
            $self->Change($ref_p, $elem, $ref_a->{$elem});
        } else {
            $self->Add($ref_p, $elem, $ref_a->{$elem});
        }
    }
}

sub Add {
    my ($self, $db, $key, $ref) = @_;

    $ref->{"Link"}   = 0;
    $ref->{"Flags"} |= $RECORD_NEW;

    if (exists $db->{$key}) {
        $db->{$key . 'A'} = $ref;
    } else {
        $db->{$key} = $ref;
    }
}

sub Remove {
    my ($self, $db, $key) = @_;

    $db->{$key}{"Flags"} |= $RECORD_DELETED;
}

sub Change {
    my ($self, $db, $key, $ref) = @_;

    $ref->{"Flags"} |= $RECORD_CHANGED;

    $db->{$key} = $ref;
}

sub db_warn {
    my ($msg) = @_;
    warn sprintf("problem at pos %x: %s\n", tell PILOT_DB, $msg);
}

sub read_db {
    my $data = 0;
    if (! read PILOT_DB, $data, $_[0]) {
        db_warn("failed to read data");
        return 0;
    }
    return $data;
}

sub read_byte {
    return unpack('C', read_db 1);
}

sub read_word {
    return unpack('S', read_db 2);
}

sub read_dword {
    return unpack('L', read_db 4);
}

sub read_length {
    my $len = $_[0] || read_byte;
    
    if ($len == 0xff) {
        $len = read_word;
    }
    return $len;
}

sub read_string {
    my $len = read_length $_[0];
    
    if ($len != 0) {
        my $data = unpack(sprintf("a%d", $len), read_db $len);
        $data = "" if ! $data;
        return $data;
    }
    return 0;
}

sub read_field {
    my $type = read_dword;

    if ($type == $FIELD_DWORD) {
        return read_dword;
    }
    elsif ($type == $FIELD_REPEAT) {
        return read_dword;
    }
    elsif ($type == $FIELD_DATE) {
        return read_dword;
    }
    elsif ($type == $FIELD_STRING) {
        db_warn("string field dword != 0") if read_dword != 0;
        return read_string;
    }
    elsif ($type == $FIELD_BOOL) {
        return read_dword;
    }
    else {
        db_warn("unknown type code $type");
    }
    return 0;
}

sub start_record {
    my ($self) = @_;

    my $ref = { };

    # link; 0 if record has never been sync'd

    $ref->{"Link"}  = read_field;
    
    # flags; only has a value for unsync'd databases
    
    $ref->{"Flags"} = read_field;
    $ref->{"Other"} = read_field;

    return $ref;
}

sub finish_record {
    my ($self, $descriptor, $ref) = @_;

    return 0 if (! $descriptor or
                 $ref->{"Flags"} & ($RECORD_DELETED | $RECORD_DONT_USE));

    $self->cleanup_record($descriptor, $ref);

    return ($descriptor, $ref);
}

sub read_note {
    my $data = read_field;
    if ($data) {
        return [ split /\015\012/, $data ];
    }
    return 0;
}

sub read_category {
    my ($self, $descriptors, $ref) = @_;

    my $index = read_field;
    if ($index > @{$self->{"Categories"}}) {
        db_warn("category index too high at $index");
    }
    $ref->{"Category"} = [ $self->{"Categories"}[$index - 1] ];

    return $self->find_descriptor($descriptors, $ref);
}

sub Read {
    my ($self, $path, %descriptors) = @_;

    open(PILOT_DB, $path) ||
        warn "Can't open database '$path'\n", return 0;
    binmode PILOT_DB;

    $self->{"Magic"} = read_dword;              # magic dword

    # read in the name of address database

    read_string;

    # skip the variable length header fields

    $self->{"Header"} = [ split /\012/, read_string $len ];

    # read in the categories

    $self->{"CatDWORD1"}  = [ ];
    $self->{"CatDWORD2"}  = [ ];
    $self->{"Categories"} = [ ];
    $self->{"Categori"}   = [ ];

    $self->{"CatDWORD0"}  = read_dword;
    $count = read_dword;
    db_warn("category count too high at $count") if $count > 20;

    for ($i = 0; $i < $count; $i++) {
        db_warn("index dword is off") if $i + 1      != read_dword;
        $self->{"CatDWORD1"}[$i]  = read_dword;          # jww: ???
        $self->{"CatDWORD2"}[$i]  = read_dword;          # jww: ???
        $self->{"Categories"}[$i] = read_string;
        $self->{"Categori"}[$i]   = read_string;    # 8-char version
    }

    $self->before_records();

    while (not eof PILOT_DB) {
        my ($descriptor, $ref) = $self->read_record(\%descriptors);
        if ($descriptor) {
            $self->add_record_to_object($descriptor, $ref);
        }
    }
    close PILOT_DB;

    return 1;
}

sub add_record_to_object {
    my ($self, $descriptor, $ref) = @_;

    if (ref $descriptor->{"Object"} eq "ARRAY") {
        push @{$descriptor->{"Object"}}, $ref;
    }
    elsif (ref $descriptor->{"Object"} eq "HASH") {
        # construct key field

        my $first = 1;
        my $key   = "";

        if (exists $descriptor->{"Keyfields"}) {
            my $field;
            foreach $field (@{$descriptor->{"Keyfields"}}) {
                if ($ref->{$field}) {
                    if (! $first) {
                        $key .= ' ' . $ref->{$field};
                    } else {
                        $first = 0;
                        $key = $ref->{$field};
                    }
                }
            }
            my $keysep = $descriptor->{"Keysep"};
            $key =~ s/ /$keysep/g;
        } else {
            $key = $ref->{"Last"};
        }

        # add record to hash

        if (exists $descriptor->{"Object"}{$key}) {
            warn "Key '", $key, "' already processed\n";
        } else {
            $descriptor->{"Object"}{$key} = $ref;
        }
    } else {
        warn "unsupported object type (", ref $descriptor->{"Object"}, ")\n";
    }
}

sub handle_array_fields {
    my ($self, $descriptor, $ref) = @_;

    # convert any custom fields that are array fields into arrays
    # before processing the extendend fields

    my $field;
    foreach $field (@{$descriptor->{"ArrayFields"}}) {
        next unless $ref->{"Custom"}{$field};
        if (ref $ref->{"Custom"}{$field} ne "ARRAY") {
            $ref->{"Custom"}{$field} = [ $ref->{"Custom"}{$field} ];
        }
    }
}

sub add_to_field {
    my ($ref, $kind, $field, $data) = @_;

    if ($kind eq "a") {             # address
        if (ref $data ne "ARRAY") {
            warn "need valid array for custom address field in '",
                $ref->{"First"}, " ", $ref->{"Last"}, "'\n";
        } else {
            my $part;

            my $addr = { };
            my $data = pop @$data;
            if ($data =~ /^([^,]*),\s*(\S+)\s+(.*)/) {
                $addr->{"City"}  = $1;
                $addr->{"State"} = $2;
                $addr->{"Zip"}   = $3;
            }

            my $street = [ ];
            foreach $part (@$data) {
                push @$street, $part;
            }
            $addr->{"Street"} = $street;

            if (! $ref->{"Address"}) {
                $ref->{"Address"} = [ ];
            }
            push @{$ref->{"Address"}}, [ $field, $addr ];
        }
    }
    elsif ($kind eq "c") {          # contact
        if (ref $data eq "ARRAY") {
            warn "what does an array contact mean in '",
                $ref->{"First"}, " ", $ref->{"Last"}, "'\n";
        } else {
            if (! $ref->{"Contact"}) {
                $ref->{"Contact"} = [ ];
            }
            push @{$ref->{"Contact"}}, [ $field, $data ];
        }
    }
    elsif ($kind eq "f") {          # field
        if (ref $data eq "ARRAY") {
            if (! $ref->{$field}) {
                $ref->{$field} = [ ];
            }
            if (ref $ref->{$field} eq "ARRAY") {
                push @{$ref->{$field}}, @$data;
            } else {
                $ref->{$field} .= " / " . join(" / ", @$data);
            }
        } else {
            if (ref $ref->{$field} eq "ARRAY") {
                push @{$ref->{$field}}, $data;
            } else {
                $ref->{$field} = $data;
            }
        }
    }
    elsif ($kind eq ":") {          # custom field
        if (ref $data eq "ARRAY") {
            if (! $ref->{"Custom"}{$field}) {
                $ref->{"Custom"}{$field} = [ ];
            }
            if (ref $ref->{"Custom"}{$field} eq "ARRAY") {
                push @{$ref->{"Custom"}{$field}}, @$data;
            } else {
                warn "array for non-array contact field in '",
                    $ref->{"First"}, " ", $ref->{"Last"}, "'\n";
            }
        } else {
            if (ref $ref->{"Custom"}{$field} eq "ARRAY") {
                push @{$ref->{"Custom"}{$field}}, $data;
            } else {
                $ref->{"Custom"}{$field} = $data;
            }
        }
    }
}

sub handle_extended_fields_in_note {
    my ($self, $ref) = @_;

    # process any extended custom fields in the note

    my @data  = ();
    my @copy  = ();

    my $line;
    my $in_field;
    my $field;
    my $kind;
    my $data;

    foreach $line (@{$ref->{"Note"}}) {
        my $cmd = 0;
        if ($line =~ /^\s*<([^>]+)>\s*$/) {
            $cmd = $1;
        }
        elsif (! $in_field) {
            push @copy, $line;
            next;
        }

        if ($in_field) {
            if ($cmd) {
                if ($cmd =~ /^e$/) {
                    $in_field = 0;
                    add_to_field $ref, $kind, $field, \@data;
                } else {
                    warn "found strange command in extended field '", $cmd, "'\n";
                }
            } else {
                push @data, $line;
            }
        } else {
            if ($cmd =~ /^(.)\s+(\S+)\s+(.+)$/) {
                add_to_field $ref, $1, $2, $3;
            }
            elsif ($cmd =~ /^(.)\s+(.+)$/) {
                $in_field = 1;
                $kind     = $1;
                $field    = $2;
                @data     = ();
            } else {
                warn " -- bad extended field syntax '", $cmd, "'\n";
            }
        }
    }
    $ref->{"Note"} = \@copy;
}

sub handle_reference_fields {
    my ($self, $descriptor, $ref) = @_;

    # Convert ref fields to hold true key values

    my $field;
    foreach $field (@{$descriptor->{"RefFields"}}) {
        next unless $ref->{"Custom"}{$field};
        if (ref $ref->{"Custom"}{$field} eq "ARRAY") {
            my $item;
            foreach $item (@{$ref->{"Custom"}{$field}}) {
                $item =~ s/ /_/g;
            }
        } else {
            $ref->{"Custom"}{$field} =~ s/ /_/g;
        }
    }
}

sub find_descriptor {
    my ($self, $descriptors, $ref) = @_;

    # now that we have the category, find the descriptor for this
    # record

    my $desc;
    my $descriptor = 0;

  OUTER:
    foreach $desc (keys %$descriptors) {
      INNER:
        foreach $category (@{$ref->{"Category"}}) {
            if ($category =~ /$desc/) {
                $descriptor = $descriptors->{$desc};
                last OUTER;
            }
        }
    }
    return $descriptor;
}

sub cleanup_record {
    my ($self, $descriptor, $ref) = @_;

    if ($descriptor->{"ArrayFields"}) {
        $self->handle_array_fields($descriptor, $ref);
    }

    if ($ref->{"Note"}) {
        $self->handle_extended_fields_in_note($ref);
    }
    
    if ($descriptor->{"RefFields"}) {
        $self->handle_reference_fields($descriptor, $ref);
    }
}

sub flatten_record {
    my ($ref) = @_;
    my $text  = "";

    if (ref $ref eq "HASH") {
        my $key;
        foreach $key (sort keys %$ref) {
            $text .= flatten_record($ref->{$key});
        }
    }
    elsif (ref $ref eq "ARRAY") {
        my $elem;
        foreach $elem (@$ref) {
            $text .= flatten_record($elem);
        }
    }
    else {
        $text .= $ref;
    }
    return $text;
}

sub write_byte {
    write pack('C', $_[0]);
}

sub write_word {
    write pack('S', $_[0]);
}

sub write_dword {
    write pack('L', $_[0]);
}

sub write_length {
    my $len = $_[0];

    if ($len >= 0xff) {
        write_byte 0xff;
        write_word $len;
    } else {
        write_byte $len;
    }
}

sub write_string {
    my $len = length $_[0];
    write_length $len;
    write pack(sprintf("a%d", $len), $_[0]);
}

sub write_field {
    my $type = $_[0];
    write_dword $type;

    if ($type == $FIELD_DWORD) {
        write_dword $_[1];
    }
    elsif ($type == $FIELD_STRING) {
        write_dword 0;
        write_string $_[1];
    }
    elsif ($type == $FIELD_BOOL) {
        write_dword $_[1] ? 1 : 0;
    }
    else {
        db_warn("unknown type code $type");
    }
}

sub Write {
    my ($self, $path, $object) = @_;

    open(PILOT_DB, "> $path") ||
        warn "Can't write to database '$path'\n", return 0;
    binmode PILOT_DB;

    write_dword $self->{"Magic"};              # magic dword

    # read in the name of address database

    write_string $path;

    # skip the variable length header fields

    my $len = 0;
    foreach $header (@{$self->{"Header"}}) {
        $len = length $header + 1;
    }
    write_length $len;

    foreach $header (@{$self->{"Header"}}) {
        write pack(sprintf("a%d", length($header) + 1), $header . "\012");
    }

    # read in the categories

    write_dword $self->{"CatDWORD0"};
    write_dword scalar @{$self->{"Categories"}};

    my $i;
    for ($i = 0; $i < @{$self->{"Categories"}}; $i++) {
        write_dword($i + 1);
        write_dword $self->{"CatDWORD1"}[$i];
        write_dword $self->{"CatDWORD2"}[$i];
        write_string $self->{"Categories"}[$i];
        write_string $self->{"Categori"}[$i];
    }

    # jww: skip some unknown data; length is given

    write_dword $self->{"MiscLength"};
    write $self->{"MiscData"};

    # jww: what do these mean?

    write_dword $self->{"MiscDWORD1"};
    write_dword $self->{"MiscDWORD2"};

    # read in the database records

    my %sorted_records;
    my $ref;
    my $records;

    if (ref $object eq "HASH") {
        $records = [ values %$object ];
    } else {
        $records = $object;
    }

    foreach $ref (@$records) {
        $sorted_records{$ref->{"Last"} . $ref->{"First"} .
                          Address::flatten_record($ref)} = $ref;
    }

    my $key;
    foreach $key (sort keys %sorted_records) {
        $self->write_record($sorted_records{$key});
    }
    close PILOT_DB;

    return 1;
}

1;

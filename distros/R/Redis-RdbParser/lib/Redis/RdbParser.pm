package Redis::RdbParser;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.05';

use Carp;

use constant REDIS_RDB_6BITLEN              => 0;
use constant REDIS_RDB_14BITLEN             => 1;
use constant REDIS_RDB_32BITLEN             => 2;
use constant REDIS_RDB_ENCVAL               => 3;
use constant REDIS_RDB_OPCODE_EXPIRETIME_MS => 252;
use constant REDIS_RDB_OPCODE_EXPIRETIME    => 253;
use constant REDIS_RDB_OPCODE_SELECTDB      => 254;
use constant REDIS_RDB_OPCODE_EOF           => 255;
use constant REDIS_RDB_TYPE_STRING          => 0;
use constant REDIS_RDB_TYPE_LIST            => 1;
use constant REDIS_RDB_TYPE_SET             => 2;
use constant REDIS_RDB_TYPE_ZSET            => 3;
use constant REDIS_RDB_TYPE_HASH            => 4;
use constant REDIS_RDB_TYPE_HASH_ZIPMAP     => 9;
use constant REDIS_RDB_TYPE_LIST_ZIPLIST    => 10;
use constant REDIS_RDB_TYPE_SET_INTSET      => 11;
use constant REDIS_RDB_TYPE_ZSET_ZIPLIST    => 12;
use constant REDIS_RDB_TYPE_HASH_ZIPLIST    => 13;
use constant REDIS_RDB_ENC_INT8             => 0;
use constant REDIS_RDB_ENC_INT16            => 1;
use constant REDIS_RDB_ENC_INT32            => 2;
use constant REDIS_RDB_ENC_LZF              => 3;

my %DATA_TYPE_MAPPING = (
    0   => 'string',
    1   => 'list',
    2   => 'set',
    3   => 'sortedset',
    4   => 'hash',
    9   => 'hash',
    10  => 'list',
    11  => 'set',
    12  => 'sortedset',
    13  => 'hash');

my %def_callbacks = (
    "start_rdb"         => \&def_start_rdb,
    "start_database"    => \&def_start_database,
    "key"               => \&def_key,
    "set"               => \&def_set,
    "start_hash"        => \&def_start_hash,
    "hset"              => \&def_hset,
    "end_hash"          => \&def_end_hash,
    "start_set"         => \&def_start_set,
    "sadd"              => \&def_sadd,
    "end_set"           => \&def_end_set,
    "start_list"        => \&def_start_list,
    "rpush"             => \&def_rpush,
    "end_list"          => \&def_end_list,
    "start_sorted_set"  => \&def_start_sorted_set,
    "zadd"              => \&def_zadd,
    "end_sorted_set"    => \&def_end_sorted_set,
    "end_database"      => \&def_end_database,
    "end_rdb"           => \&def_end_rdb,
);

sub new {
    my ($class, $callbacks) = @_;
    $callbacks ||= \%def_callbacks;

    my $self = bless {}, $class;
    $self->{callback} = $callbacks;
    $self->{expiry} = undef;
    $self->{key} = undef;
    $self->{filename} = undef;
    $self;
}

#=================================================================
# Parse a redis rdb dump file, and call methods in the callback
# hash reference during the parsing operation.
#
# filter's structure is a hash, whose member value is of array type,
# the key is processed as regular expression.
# i.e.
#   filter = {
#       "dbs" => [0, 1],
#       "keys" => ['^foo$', 'bar'],
#       "types" => ["hash", "set", "sortedset", "list", "string"],
#   }
#   
#   If filter is undef, results will not be filtered.
#   If dbs, keys or type is undef, no filtering will be done on the
#   result.
#   You can also use appropriate callback to filter keys.
#   All the 3 conditions must be satified.
#=================================================================
sub parse {
    my $self = shift;
    my $filename = shift;
    my $filter = shift;

    unless (defined($filename)) {
        croak "Expected a Redis dump file name";
    }
    $self->{filename} = $filename;

    my $buffer;
    open my $INFH, $filename or 
        croak "Open $filename for reading failed: $!";
    binmode $INFH;

    read($INFH, $buffer, 5) or croak "Read $filename failed: $!";
    $self->verify_magic($buffer);

    read($INFH, $buffer, 4) or croak "Read $filename failed: $!";
    $self->verify_version($buffer);

    $self->invoke_callback("start_rdb", $filename);

    my $db_number = 0;
    my $is_first_database = 1;

    while (1) {
        $self->{expiry} = undef;
        my $data_type = &read_unsigned_char($INFH);

        if ($data_type == REDIS_RDB_OPCODE_EXPIRETIME_MS) {
            $self->{expiry} = &read_unsigned_long($INFH);
            $data_type = &read_unsigned_char($INFH);
        } elsif ($data_type == REDIS_RDB_OPCODE_EXPIRETIME) {
            $self->{expiry} = &read_unsigned_int($INFH) * 1000; # change to ms
            $data_type = &read_unsigned_char($INFH);
        } 

        if ($data_type == REDIS_RDB_OPCODE_SELECTDB) {
            unless ($is_first_database) {
                $self->invoke_callback("end_database", $db_number);
            }
            $is_first_database = 0;
            $db_number = &read_length($INFH);

            $self->invoke_callback("start_database", $db_number);
            next;
        }

        if ($data_type == REDIS_RDB_OPCODE_EOF) {
            unless ($is_first_database) {
                $self->invoke_callback("end_database", $db_number);
            }
            $self->invoke_callback("end_rdb", $filename);
            last;
        }

        if (defined($filter)) {
            if (&match_db($filter, $db_number)) {
                my $key = &read_string($INFH);
                $self->{key} = $key;
                $self->invoke_callback("key", $key);
                if (match_filter($filter, $key, $data_type)) {
                    $self->read_object($INFH, $data_type);
                } else {
                    &skip_object($INFH, $data_type);
                }
            } else {
                &skip_key_and_object($INFH, $data_type);
            }
        } else {
            my $key = &read_string($INFH);
            $self->{key} = $key;
            $self->invoke_callback("key", $key);
            $self->read_object($INFH, $data_type);
        }
    }
    
    close $INFH or croak "Close $filename failed: $!";
}

sub match_db {
    my ($filter, $db_number) = @_;
    return 1 unless (defined($filter->{dbs}));
    if (&in_array($db_number, @{$filter->{dbs}})) {
        return 1;
    }
    return 0;
}

sub match_filter {
    my ($filter, $key, $data_type) = @_;
    my $ret1 = 0;
    my $ret2 = 0;
    
    if (defined($filter->{"keys"})) {
        foreach (@{$filter->{"keys"}}) {
            if ($key =~ m/$_/) {
                $ret1 = 1;
                last;
            }
        }
    } else {
        $ret1 = 1;
    }

    if (defined($filter->{"types"})) {
        foreach (@{$filter->{"types"}}) {
            if ($DATA_TYPE_MAPPING{$data_type} eq $_) {
                $ret2 = 1;
                last;
            }
        }
    } else {
        $ret2 = 1;
    }

    return $ret1 & $ret2;
}

sub in_array {
    my ($needle, @haystack) = @_;
    foreach (@haystack) {
        if ($needle == $_) {
            return 1;
        }
    }
    return 0;
}

sub invoke_callback {
    my $self = shift;
    my $method = shift;
    my @args = @_;

    if (defined($self->{callback}->{$method})) {
        my $func = $self->{callback}->{$method};
        &$func(@args);
    }
}

sub verify_magic {
    my ($self, $magic) = @_;

    if ($magic ne 'REDIS') {
        croak "Invalid File Format for file " . $self->{filename};
    }
}

sub verify_version {
    my ($self, $version) = @_;

    $version = int($version);

    if ($version < 1 or $version > 6) {
        croak "Invalid RDB version $version for file " . $self->{filename};
    }
}

sub read_signed_char {
    my ($fh) = @_;
    my $buffer;

    read($fh, $buffer, 1) or croak "read failed: $!";
    return unpack('c', $buffer);
}

sub read_signed_char_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 1);
    return (unpack('c', $temp), $off + 1);
}

sub read_unsigned_char {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 1) or croak "read failed: $!";
    return unpack('C', $buffer);
}

sub read_unsigned_char_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 1);
    return (unpack('C', $temp), $off + 1);
}

sub read_signed_short {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 2) or croak "read failed: $!";
    return unpack('s', $buffer);
}

sub read_signed_short_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 2);
    return (unpack('s', $temp), $off + 2);
}

sub read_unsigned_short {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 2) or croak "read failed: $!";
    return unpack('S', $buffer);
}

sub read_unsigned_short_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 2);
    return (unpack('S', $temp), $off + 2);
}

sub read_signed_int {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 4) or croak "read failed: $!";
    return unpack('i', $buffer);
}

sub read_signed_int_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 4);
    return (unpack('i', $temp), $off + 4);
}

sub read_unsigned_int {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 4) or croak "read failed: $!";
    return unpack('I', $buffer);
}

sub read_unsigned_int_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 4);
    return (unpack('i', $temp), $off + 4);
}

sub read_big_endian_unsigned_int {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 4) or croak "read failed: $!";
    return unpack('N', $buffer);
}

sub read_big_endian_unsigned_int_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 4);
    return (unpack('N', $temp), $off + 4);
}

sub read_24bit_signed_number {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 3) or croak "read failed: $!";
    $buffer .= '0' . $buffer;
    return unpack('i', $buffer) >> 8;
}

sub read_24bit_signed_number_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 3);
    $temp .= '0' . $temp;
    return (unpack('i', $temp) >> 8, $off + 3);
}

sub read_signed_long {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 8) or croak "read failed: $!";
    return unpack('q', $buffer);
}

sub read_signed_long_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 8);
    return (unpack('q', $temp), $off + 8);
}

sub read_unsigned_long {
    my ($fh) = @_;
    my $buffer;
    read($fh, $buffer, 8) or croak "read failed: $!";
    return unpack('Q', $buffer);
}

sub read_unsigned_long_str {
    my ($str, $off) = @_;
    my $temp = substr($str, $off, 8);
    return (unpack('Q', $temp), $off + 8);
}

sub skip {
    my ($fh, $free) = @_; 
    my $dummy;
    if ($free > 0) {
        read($fh, $dummy, $free);
    }
}

sub ntohl {
    my ($fh) = @_;
    my $val = &read_unsigned_int($fh);
    my $new_val = 0;
    $new_val |= (($val & 0x000000ff) << 24);
    $new_val |= (($val & 0xff000000) >> 24);
    $new_val |= (($val & 0x0000ff00) << 8);
    $new_val |= (($val & 0x00ff0000) >> 8);
    return $new_val;
}

sub read_length_with_encoding {
    my ($fh) = @_;
    my $length = 0;
    my $is_encoded = 0;
    my $buffer;
    
    my $first = &read_unsigned_char($fh);
    my $enc_type = ($first & 0xc0) >> 6;

    if ($enc_type == REDIS_RDB_ENCVAL) {
        $is_encoded = 1;
        $length = $first & 0x3f;
    } elsif ($enc_type == REDIS_RDB_6BITLEN) {
        $length = $first & 0x3f;
    } elsif ($enc_type == REDIS_RDB_14BITLEN) {
        my $second = &read_unsigned_char($fh);
        $length = (($first & 0x3f) << 8) | $second;
    } else {
        $length = ntohl($fh);
    }
    return ($length, $is_encoded);
}

sub read_length {
    return (&read_length_with_encoding(@_))[0];
}

sub read_string {
    my ($fh) = @_;
    my ($length, $is_encoded) = &read_length_with_encoding($fh);
    my $val;

    if ($is_encoded) {
        if ($length == REDIS_RDB_ENC_INT8) {
            $val = &read_signed_char($fh);
        } elsif ($length == REDIS_RDB_ENC_INT16) {
            $val = &read_signed_short($fh);
        } elsif ($length == REDIS_RDB_ENC_INT32) {
            $val = &read_signed_int($fh);
        } elsif ($length == REDIS_RDB_ENC_LZF) {
            my $clen = &read_length($fh);
            my $len = &read_length($fh);
            my $buffer;
            read($fh, $buffer, $clen);
            $val = &lzf_decompress($buffer, $len);
        }
    } else {
        read($fh, $val, $length);
    }
    return $val;
}

#==================================================================
# Read an object from the stream, and invoke callbacks.
#==================================================================
sub read_object {
    my ($self, $fh, $enc_type) = @_;
    my $val;
    my $length;

    if ($enc_type == REDIS_RDB_TYPE_STRING) {
        $val = &read_string($fh); 
        $self->invoke_callback("set", $self->{key}, $val,  
            $self->{expiry}, {'encoding' => 'string'});
    } elsif ($enc_type == REDIS_RDB_TYPE_LIST) {
        #=================================================================
        # A redis list is just a sequence of strings
        # We successively read strings from the string and create a list
        # from it.
        # The lists are in order i.e. the first string is the head,
        # and the last string is the tail of the list.
        #=================================================================
        $length = &read_length($fh);
        $self->invoke_callback("start_list", 
            $self->{key}, $length, $self->{expiry}, 
            {'encoding' => 'linkedlist'});
        for (my $i = 0; $i < $length; ++$i) {
            $val = &read_string($fh);
            $self->invoke_callback("rpush", $self->{key}, $val);
        }
        $self->invoke_callback("end_list", $self->{key});
    } elsif ($enc_type == REDIS_RDB_TYPE_SET) {
        #================================================================
        # A redis set is just a sequence of strings.
        # We successively read strings from the stream and create a set
        # from it. Note that the order of strings is non-deterministic.
        #================================================================
        $length = &read_length($fh);
        $self->invoke_callback("start_set",
            $self->{key}, $length, $self->{expiry},
            {'encoding' => 'hashtable'});

        for (my $i = 0; $i < $length; ++$i) {
            $val = &read_string($fh);
            $self->invoke_callback("sadd", $self->{key}, $val);
        }
        $self->invoke_callback("end_set", $self->{key});
    } elsif ($enc_type == REDIS_RDB_TYPE_ZSET) {
        $length = &read_length($fh);
        $self->invoke_callback("start_sorted_set", 
            $self->{key}, $length, $self->{expiry},
            {'encoding' => 'skiplist'});
        for (my $i = 0; $i < $length; ++$i) {
            $val = &read_string($fh);
            my $dbl_length = &read_unsigned_char($fh);
            read($fh, my $score, $dbl_length);
            $self->invoke_callback("zadd", $self->{key}, $score, $val);
        }
        $self->invoke_callback("end_sorted_set", $self->{key});
    } elsif ($enc_type == REDIS_RDB_TYPE_HASH) {
        $length = &read_length($fh);

        $self->invoke_callback("start_hash", 
            $self->{key}, $length, $self->{expiry}, 
            {'encoding' => 'hashtable'});
        for (my $i = 0; $i < $length; ++$i) {
            my $field = &read_string($fh);
            my $value = &read_string($fh);
            $self->invoke_callback("hset", $self->{key}, $field, $value);
        }
        $self->invoke_callback("end_hash", $self->{key});
    } elsif ($enc_type == REDIS_RDB_TYPE_HASH_ZIPMAP) {
        $self->read_zipmap($fh);
    } elsif ($enc_type == REDIS_RDB_TYPE_LIST_ZIPLIST) {
        $self->read_ziplist($fh);
    } elsif ($enc_type == REDIS_RDB_TYPE_SET_INTSET) {
        $self->read_intset($fh);
    } elsif ($enc_type == REDIS_RDB_TYPE_ZSET_ZIPLIST) {
        $self->read_zset_from_ziplist($fh);
    } elsif ($enc_type == REDIS_RDB_TYPE_HASH_ZIPLIST) {
        $self->read_hash_from_ziplist($fh);
    } else {
        croak "Invalid object type $enc_type";
    }
}

sub read_intset {
    my ($self, $fh) = @_;
    my $seek = 0;
    my $entry;
    my $encode;
    my $num_entries;

    my $raw_string = &read_string($fh);

    ($encode, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($num_entries, $seek) = &read_unsigned_int_str($raw_string, $seek);

    $self->invoke_callback("start_set", 
        $self->{key}, $num_entries, $self->{expiry}, 
        {'encoding' => 'intset', 'sizeof_value' => length($raw_string)});

    for (my $i = 0; $i < $num_entries; ++$i) {
        if ($encode == 8) {
            ($entry, $seek) = &read_unsigned_long_str($raw_string, $seek);
        } elsif ($encode == 4) {
            ($entry, $seek) = &read_unsigned_int_str($raw_string, $seek);
        } elsif ($encode == 2) {
            ($entry, $seek) = &read_unsigned_short_str($raw_string, $seek);
        } else {
            croak "Invalid encoding $encode";
        }
        $self->invoke_callback("sadd", $self->{key}, $entry);
    }
    $self->invoke_callback("end_set", $self->{key});
}

sub read_ziplist_entry_str {
    my ($str, $off) = @_;
    my ($length, $value, $prev_length, $entry_header);
    
    ($prev_length, $off) = &read_unsigned_char_str($str, $off);
    if ($prev_length == 254) {
        ($prev_length, $off) = &read_unsigned_int_str($str, $off);
    }

    ($entry_header, $off) = &read_unsigned_char_str($str, $off);

    if ($entry_header >> 6 == 0) {
        $length = $entry_header & 0x3f;
        $value = substr($str, $off, $length);
        $off += $length;
    } elsif ($entry_header >> 6 == 1) {
        ($length, $off) = &read_unsigned_char_str($str, $off);
        $length |= (($entry_header & 0x3f) << 8);
        $value = substr($str, $off, $length);
        $off += $length;
    } elsif ($entry_header >> 6 == 2) {
        ($length, $off) = &read_big_endian_unsigned_int_str($str, $off);
        $value = substr($str, $off, $length);
        $off += $length;
    } elsif ($entry_header >> 4 == 12) {
        ($value, $off) = &read_signed_short_str($str, $off);
    } elsif ($entry_header >> 4 == 13) {
        ($value, $off) = &read_signed_int_str($str, $off);
    } elsif ($entry_header >> 4 == 14) {
        ($value, $off) = &read_signed_long_str($str, $off);
    } elsif ($entry_header == 240) {
        ($value, $off) = &read_24bit_signed_number_str($str, $off);
    } elsif ($entry_header == 254) {
        ($value, $off) = &read_signed_char_str($str, $off);
    } elsif ($entry_header >= 241 and $entry_header <= 253) {
        $value = $entry_header - 241;
    } else {
        croak "Invalid entry_header $entry_header";
    }

    return ($value, $off);
}

sub read_ziplist_entry {
    my ($fh) = @_;
    my ($length, $value);

    my $prev_length = &read_unsigned_char($fh);
    if ($prev_length == 254) {
        $prev_length = &read_unsigned_int($fh);
    }

    my $entry_header = &read_unsigned_char($fh);
    if ($entry_header >> 6 == 0) {
        $length = $entry_header & 0x3f;
        read($fh, $value, $length);
    } elsif ($entry_header >> 6 == 1) {
        $length = (($entry_header & 0x3f) << 8) | &read_unsigned_char($fh);
        read($fh, $value, $length);
    } elsif ($entry_header >> 6 == 2) {
        $length = &read_big_endian_unsigned_int($fh);
        read($fh, $value, $length);
    } elsif ($entry_header >> 4 == 12) {
        $value = &read_signed_short($fh);
    } elsif ($entry_header >> 4 == 13) {
        $value = &read_signed_int($fh);
    } elsif ($entry_header >> 4 == 14) {
        $value = &read_signed_long($fh);
    } elsif ($entry_header == 240) {
        $value = &read_24bit_signed_number($fh);
    } elsif ($entry_header == 254) {
        $value = &read_signed_char($fh);
    } elsif ($entry_header >= 241 and $entry_header <= 253) {
        $value = $entry_header - 241;
    } else {
        croak "Invalid entry_header $entry_header";
    }

    return $value;
}

sub read_ziplist {
    my ($self, $fh) = @_;
    my $seek = 0;
    my ($entry, $zlbytes, $zltail, $num_entries, $value, $zlist_end);
    my $raw_string = &read_string($fh);

    ($zlbytes, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($zltail, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($num_entries, $seek) = &read_unsigned_short_str($raw_string, $seek);

    $self->invoke_callback("start_list", 
        $self->{key}, $num_entries, $self->{expiry}, 
        {'encoding' => 'ziplist', 'sizeof_value' => length($raw_string)});
    for (my $i = 0; $i < $num_entries; ++$i) {
        ($value, $seek) = &read_ziplist_entry_str($raw_string, $seek);
        $self->invoke_callback("rpush", $self->{key}, $value);
    }
    ($zlist_end, $seek) = &read_unsigned_char_str($raw_string, $seek);
    if ($zlist_end != 255) {
        croak "Invalid zip list end $zlist_end";
    }
    $self->invoke_callback("end_list", $self->{key});
}

sub read_zset_from_ziplist {
    my ($self, $fh) = @_;
    my $seek = 0;
    my ($entry, $zlbytes, $zltail, $num_entries, $member, $score, $zlist_end);
    my $raw_string = &read_string($fh);

    ($zlbytes, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($zltail, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($num_entries, $seek) = &read_unsigned_short_str($raw_string, $seek);

    if ($num_entries % 2) {
        croak "Expected even number of elements but found $num_entries";
    }

    $num_entries /= 2;

    $self->invoke_callback("start_sorted_set", 
        $self->{key}, $num_entries, $self->{expiry}, 
        {'encoding' => 'ziplist', 'sizeof_value' => length($raw_string)});
    for (my $i = 0; $i < $num_entries; ++$i) {
        ($member, $seek) = &read_ziplist_entry_str($raw_string, $seek);
        ($score, $seek) = &read_ziplist_entry_str($raw_string, $seek);
        $self->invoke_callback("zadd", $self->{key}, $score, $member);
    }
    ($zlist_end, $seek) = &read_unsigned_char_str($raw_string, $seek);
    if ($zlist_end != 255) {
        croak "Invalid zip list end $zlist_end";
    }

    $self->invoke_callback("end_sorted_set", $self->{key});
}

sub read_hash_from_ziplist {
    my ($self, $fh) = @_;
    my $seek = 0;
    my ($entry, $zlbytes, $zltail, $num_entries, $field, $value, $zlist_end);
    my $raw_string = &read_string($fh);

    ($zlbytes, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($zltail, $seek) = &read_unsigned_int_str($raw_string, $seek);
    ($num_entries, $seek) = &read_unsigned_short_str($raw_string, $seek);

    if ($num_entries % 2) {
        croak "Expected even number of elements but found $num_entries";
    }

    $num_entries /= 2;

    $self->invoke_callback("start_hash", 
        $self->{key}, $num_entries, $self->{expiry},
        {'encoding' => 'ziplist', 'sizeof_value' => length($raw_string)});

    for (my $i = 0; $i < $num_entries; ++$i) {
        ($field, $seek) = &read_ziplist_entry_str($raw_string, $seek);
        ($value, $seek) = &read_ziplist_entry_str($raw_string, $seek);
        $self->invoke_callback("hset", $self->{key}, $field, $value);
    }
    ($zlist_end, $seek) = &read_unsigned_char_str($raw_string, $seek);
    if ($zlist_end != 255) {
        croak "Invalid zip list end $zlist_end";
    }
    $self->invoke_callback("end_hash", $self->{key});
}

sub read_zipmap_next_length {
    my ($str, $off) = @_;
    my $length;
    ($length, $off) = &read_unsigned_char_str($str, $off);

    if ($length < 254) {
        return ($length, $off);
    } elsif ($length == 254) {
        return &read_unsigned_int_str($str, $off);
    } else {
        return (undef, $off);
    }
}

sub read_zipmap {
    my ($self, $fh) = @_;
    my $seek = 0;
    my ($num_entries, $next_length, $key, $free, $value);
    my $raw_string = &read_string($fh);

    ($num_entries, $seek) = &read_unsigned_char_str($raw_string, $seek);

    $self->invoke_callback("start_hash", 
        $self->{key}, $num_entries, $self->{expiry}, 
        {'encoding' => 'zipmap', 'sizeof_value' => length($raw_string)});
    while (1) {
        ($next_length, $seek) = &read_zipmap_next_length($raw_string, $seek);
        last unless defined($next_length);
        $key = substr($raw_string, $seek, $next_length);
        $seek += $next_length;

        ($next_length, $seek) = &read_zipmap_next_length($raw_string, $seek);
        unless (defined($next_length)) {
            croak "Unexpected end of zip map";
        }

        ($free, $seek) = &read_unsigned_char_str($raw_string, $seek);
        $value = substr($raw_string, $seek, $next_length);
        $seek += $next_length;

        $seek += $free;

        $self->invoke_callback("hset", $self->{key}, $key, $value);
    }

    $self->invoke_callback("end_hash", $self->{key});
}

sub skip_string {
    my ($fh) = @_;

    my $bytes_to_skip = 0;

    my ($length, $is_encoded) = &read_length_with_encoding($fh);
    if ($is_encoded) {
        if ($length == REDIS_RDB_ENC_INT8) {
            $bytes_to_skip = 1;
        } elsif ($length == REDIS_RDB_ENC_INT16) {
            $bytes_to_skip = 2;
        } elsif ($length == REDIS_RDB_ENC_INT32) {
            $bytes_to_skip = 4;
        } elsif ($length == REDIS_RDB_ENC_LZF) {
            my $clen = &read_length($fh);
            &read_length($fh);
            $bytes_to_skip = $clen;
        } else {
            croak "Never get here";
        }
    } else {
        $bytes_to_skip = $length;
    }

    &skip($fh, $bytes_to_skip);
}

sub skip_object {
    my ($fh, $enc_type) = @_;

    my $skip_strings = 0;
    if ($enc_type == REDIS_RDB_TYPE_STRING) {
        $skip_strings = 1;
    } elsif ($enc_type == REDIS_RDB_TYPE_LIST) {
        $skip_strings = &read_length($fh);
    } elsif ($enc_type == REDIS_RDB_TYPE_SET) {
        $skip_strings = &read_length($fh);
    } elsif ($enc_type == REDIS_RDB_TYPE_ZSET) {
        $skip_strings = &read_length($fh) * 2;
    } elsif ($enc_type == REDIS_RDB_TYPE_HASH) {
        $skip_strings = &read_length($fh) * 2;
    } elsif ($enc_type == REDIS_RDB_TYPE_HASH_ZIPMAP) {
        $skip_strings = 1;
    } elsif ($enc_type == REDIS_RDB_TYPE_LIST_ZIPLIST) {
        $skip_strings = 1;
    } elsif ($enc_type == REDIS_RDB_TYPE_SET_INTSET) {
        $skip_strings = 1;
    } elsif ($enc_type == REDIS_RDB_TYPE_ZSET_ZIPLIST) {
        $skip_strings = 1;
    } elsif ($enc_type == REDIS_RDB_TYPE_HASH_ZIPLIST) {
        $skip_strings = 1;
    } else {
        croak "Invalid object type $enc_type\n";
    }

    for (my $i = 0; $i < $skip_strings; ++$i) {
        &skip_string($fh);
    }
}

sub skip_key_and_object {
    my ($fh, $data_type) = @_;

    &skip_string($fh);
    &skip_object($fh, $data_type);
}

sub lzf_decompress {
    my ($compressed, $expected_length) = @_;

    my $in_len = length($compressed);
    my $in_index = 0;
    my @out_bytes;
    my $out_index = 0;
    my $ref;

    while ($in_index < $in_len) {
        my $ctrl = unpack('C', substr($compressed, $in_index, 1));
        ++$in_index;

        if ($ctrl < 32) {
            for (my $i = 0; $i < $ctrl + 1; ++$i) {
                $out_bytes[$out_index] = substr($compressed, $in_index, 1);
                ++$in_index;
                ++$out_index;
            }
        } else {
            my $length = $ctrl >> 5;

            if ($length == 7) {
                $length += unpack('C', substr($compressed, $in_index, 1));
                ++$in_index;
            }

            $ref = $out_index - (($ctrl & 0x1f) << 8) -
                unpack('C', substr($compressed, $in_index, 1)) - 1;
            ++$in_index;

            for (my $i = 0; $i < $length + 2; ++$i) {
                $out_bytes[$out_index] = $out_bytes[$ref];
                ++$ref;
                ++$out_index;
            }
        }
    }

    if ($out_index != $expected_length) {
        croak "Expected lengths do not match: $out_index != $expected_length\n";
    }
    return join("", @out_bytes);
}

#==========================================
# default callbacks
#==========================================
sub def_start_rdb {
    my $filename = shift;
    print '[';
}

sub def_start_database {
    my $db_number = shift;
    print "{";
}

sub def_key {
    my $key = shift;
    ### do nothing
}

sub def_set {
    my ($key, $value, $expiry) = @_;
    print "\"$key\" : \"$value\", ";
}

sub def_start_hash {
    my ($key, $length, $expiry) = @_;
    print "\"$key\" : {";
}

sub def_hset {
    my ($key, $field, $value) = @_;
    print "\"$field\" : \"$value\", ";
}

sub def_end_hash {
    my $key = shift;
    print '}, ';
}

sub def_start_set {
    my ($key, $cardinality, $expiry) = @_;
    print "\"$key\" : [";
}

sub def_sadd {
    my ($key, $member) = @_;
    print "\"$member\", ";
}

sub def_end_set {
    my ($key) = @_;
    print "], ";
}

sub def_start_list {
    my ($key, $length, $expiry) = @_;
    print "\"$key\" : [";
}

sub def_rpush {
    my ($key, $value) = @_;
    print "\"$value\", ";
}

sub def_end_list {
    my ($key) = @_;
    print "], ";
}

sub def_start_sorted_set {
    my ($key, $length, $expiry) = @_;
    print "\"$key\" : {";
}

sub def_zadd {
    my ($key, $score, $member) = @_;
    print "\"$member\" : \"$score\", ";
}

sub def_end_sorted_set {
    my ($key) = @_;
    print "}, ";
}

sub def_end_database {
    my $db_number = shift;
    print "}, ";
}

sub def_end_rdb {
    my $filename = shift;
    print "], ";
}

1;

__END__

=head1 NAME

Redis::RdbParser - Redis rdb dump file parser

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Redis::RdbParser;

 $parser = new Redis::RdbParser;
 #
 # or
 #
 my $callbacks = {
     "start_rdb"         => \&start_rdb,
     "start_database"    => \&start_database,
     "key"               => \&key,
     "set"               => \&set,
     "start_hash"        => \&start_hash,
     "hset"              => \&hset,
     "end_hash"          => \&end_hash,
     "start_set"         => \&start_set,
     "sadd"              => \&sadd,
     "end_set"           => \&end_set,
     "start_list"        => \&start_list,
     "rpush"             => \&rpush,
     "end_list"          => \&end_list,
     "start_sorted_set"  => \&start_sorted_set,
     "zadd"              => \&zadd,
     "end_sorted_set"    => \&end_sorted_set,
     "end_database"      => \&end_database,
     "end_rdb"           => \&end_rdb,
 };
 $parser = new Redis::RdbParser($callbacks);

 $parser->parse($filename);
 #
 # or 
 #
 my $filter = {
     'dbs' => [0, 1],
     'keys' => ['^foo$', '^bar'],
     'types' => ["hash", "set"],
 };
 $parser->parse($filename, $filter);

=head1 DESCRIPTION

Redis::RdbParser is a parser for Redis' rdb dump files. 
The parser generates events similar to an xml sax parser. 

=head2 callbacks

The dump file is parsed sequentially. As and when
objects are discovered, appropriate callbacks 
would be invoked. You can set the callback item `undef`
if you don't care it.

=over 4

=item start_rdb

    sub start_rdb {
        my $filename = shift;
        # fill your code
    }

Called once we know we are dealing with a valid Redis dump file.

=item start_database

    sub start_database {
        my $db_number = shift;
        # fill your code
    }

Called to indicate the start of database `db_number`.
Once a database starts, another database cannot start 
unless the first one completes and then `end_database` 
callback is called.

=item key

    sub key {
        my $key = shift;
        # fill your code
    }

Called to indicate a key readed in the parsing process.

=item set

    sub set {
        my ($key, $value, $expiry) = @_;
        # fill your code
    }

Callback to handle a key with a string value and an optional expiry.

=item start_hash

    sub start_hash {
        my ($key, $length, $expiry, $info) = @_;
        # fill your code
    }

Callback to handle the start of a hash.

After `start_hash`, the callback `hset` will be called with this `key` exactly
`length` times.

After that, the `end_hash` callback will be called.


=item hset

    sub hset {
        my ($key, $field, $value) = @_;
        # fill your code
    }

Callback to insert a field=value pair in an existing hash.

=item end_hash

    sub end_hash {
        my $key = shift;
        # fill your code
    }

Called when there are no more elements in the hash.

=item start_set

    sub start_set {
        my ($key, $length, $expiry, $info) = @_;
        # fill your code
    }

Callback to handle the start of the set.

After `start_set`, the callback `sadd` will be called with `key` 
exactly `length` times.

After that, the callback `end_set` will be called to indicate the end
of the set.

=item sadd

    sub sadd {
        my ($key, $member) = @_;
        # fill your code
    }

Callback to insert a new member to this set.

=item end_set

    sub end_set {
        my ($key) = @_;
        # fill your code
    }

Called when there are no more elements in this set.

=item start_list

    sub start_list {
        my ($key, $length, $expiry, $info) = @_;
        # fill your code
    }

Callback to handle the start of a list.

After `start_list`, the callback `rpush` will be called with `key` exactly
`length` times.

After that, the `end_list` method will be called to indicate the end of
the list.

=item rpush

    sub rpush {
        my ($key, $value) = @_;
        # fill your code
    }

Callback to insert a new value into this list.

=item end_list

    sub end_list {
        my ($key) = @_;
        # fill your code
    }

Called when there are no more elements in this list.

=item start_sorted_set

    sub start_sorted_set {
        my ($key, $length, $expiry) = @_;
        # fill your code
    }

Callback to handle the start of a sorted set.

After `start_sorted_set`, the callback `zadd' will called with `key` exactly
`length` times.

Also, `zadd` will be called in a sorted order, so as to preserve the ordering
of this sorted set.

After that, the callback `end_sorted_set` will be called to indicate the end
of this sorted set.

=item zadd

    sub zadd {
        my ($key, $score, $member) = @_;
        # fill your code
    }

Callback to insert a new value into this sorted set.

=item end_sorted_set

    sub end_sorted_set {
        my ($key) = @_;
        # fill your code
    }

Called when there are no more elements in this sorted set.

=item end_database

    sub end_database {
        my $db_number = shift;
        # fill your code
    }

Called when the current database ends

After `end_database`, one of the callbacks are called:

1) `start_database` with a new database number

2) `end_rdb` to indicate we have reached the end of the file

=item end_rdb

    sub end_rdb {
        my $filename = shift;
        # fill your code
    }

Called to indicate we have completed parsing of the dump file.

=back

=head2 filter 

filter is a reference with the following keys:

=over 4

    $filter = {
        "dbs"   => [0, 1],              # db number
        "keys"  => ['^foo$', '^bar'],   # keys regular expression
        "types" => ["string", "hash", "list", "set", "sorted set"],
    }


=back

=head3 NOTE:
    
The filter will NOT affect `start_rdb`, `end_rdb`, `start_database`, `end_database`, and `key` callbacks.

If filter is undef, results will not be filtered.

The keys in filter is processed as regular expression.

If dbs, keys or types is undef, no filtering will be done on the axis.

=head1 REPOSITORY

https://github.com/flygoast/Redis-RdbParser

=head1 AUTHOR

FengGu, E<lt>flygoast@126.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by FengGu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

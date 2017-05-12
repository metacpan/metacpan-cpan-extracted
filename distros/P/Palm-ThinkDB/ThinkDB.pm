# Palm::ThinkDB by Erik Arneson <erik@aarg.net>
# 
# Perl class for dealing with ThinkDB databases.
#
#	Copyright (C) 2001 Erik Arneson
#	You may distribute this file under the terms of the Artistic
#	License, as specified in the README file.
#
# $Id: ThinkDB.pm,v 1.8 2001/06/12 20:11:10 erik Exp $

package Palm::ThinkDB;

use strict;
use Palm::Raw ();
use Palm::StdAppInfo ();

our $VERSION = '0.02';
our $DEBUG = 0;
our (@ISA);

@ISA = qw(Palm::PDB Palm::Raw Palm::StdAppInfo);

sub import {
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
                                    [qw(THNK data)]);
}

# Can't really create a new DB yet.
sub new {
    return {};
}

sub new_Record {
    my $class = shift;
    my $record = $class->SUPER::new_Record(@_);

    # What exactly do we need to initialize?
    $record->{category} = 0;
    $record->{data}     = '';
    # This has to be a database record type, as we can't really handle
    # anything else.
    $record->{type} = 87;

    return $record;
}

sub ParseRecord {
    my $self = shift;
    my %record = @_;
    my $data = $record{data};

    delete $record{offset};  # apparently this is useless!
    #delete $record{data};

    my ($record_type, $rec);
    
    $record_type = unpack "C", $data;
    
    # Column names!  Yowch.
    if ($record_type == 1) {
        my ($numcols, @trash, $tcnum, $tctype, $tcname, $tidx);
        _debug_print("Columns:\n");
        $data = substr $data, 1;
        ($numcols, @trash) = unpack("C13", $data);
        $data = substr($data, index($data, "\000", 14));
        $numcols--;
        for (my $i = 1; $i <= $numcols; $i++) {
            (@trash[0..1], $tcnum, $tctype, @trash[0..9]) = unpack("C13", $data);
            $tidx = index($data, "\000", 14);
            $tcname = substr($data, 14, $tidx - 14);
            _debug_printf(" i: $i  colnum: %03d  coltype: %02d  colname: '%s'\n", $tcnum, $tctype, $tcname);
            $self->{cols}[$tcnum]{type} = $tctype;
            $self->{cols}[$tcnum]{name} = $tcname;

            $data = substr $data, $tidx;
        }
        _debug_print("\n");
    }
    # List items
    elsif ($record_type > 2 &&
           $record_type < 82) {
        my (@list, $colid, $num, @order);
        $data = substr $data, 1;
        $colid = $record_type - 2;
        ($num) = unpack("C", $data);
        if ($num > 0) {
            (@order) = unpack("C$num", $data);
            (@list)  = split("\000", substr($data, $num + 1), $num + 1);
            # get rid of trailing garbage!
            pop @list;
            # Sort according to order?  Not needed -- only for aesthetics
            #(@list) = @list[sort { $order[$a] <=> $order[$b] } 0 .. $#list];

            $self->{list}{$colid} = \@list;
            
            _debug_print("Record ID: ", $record{id}, "\n",
                         " List Record for Column $colid\n",
                         " Ordering: ", join(", ", @order), "\n",
                         " Items:    ", join(", ", @list), "\n",
                         " Data: ", safestr($data), "\n");
        }
    }
    # The big one:  a database record.
    elsif ($record_type == 87) {
        _debug_print( "Record ID: ", $record{id}, "\n");
        _debug_print( " Record Cat: ", $record{category}, "\n");

        # Unpack a record
        my $foo;
        my ($type, $id) = unpack "CxN", $data;
        _debug_printf(" type: %d  id: %d\n", $type, $id);
        $data = substr $data, 6;

        $record{idnum} = $id;
        if ($id > $self->{high_id}) {
          $self->{high_id} = $id;
        }
        
        while (length($data) > 0) {
            my ($ctype, $cid) = unpack "C2", $data;
            $data = substr $data, 2;
            # First are normal string types.
            if ($ctype == 1) {
                #my ($slen) = unpack "C", $data;
                my ($sdat) = unpack "C/a", $data;
                my $slen = length($sdat);
                _debug_printf(" (text)col: %02d  strlen: %02d  data: '%s'\n", $cid, $slen, $sdat);
                $record{col}{$cid} = $sdat;
                $data = substr $data, $slen+2;
            }
            # Integer types.
            elsif ($ctype == 2) {
                # Integer
                my ($val) = unpack("n", $data);
                _debug_printf(" col: %02d  data: %d\n", $cid, $val);
                $record{col}{$cid} = $val;
                $data = substr $data, 2;
            }
            # Long
            elsif ($ctype == 3) {
                my ($val) = unpack("N", $data);
                _debug_printf(" col: %02d  data: %d\n", $cid, $val);
                $record{col}{$cid} = $val;
                $data = substr $data, 4;
            }
            # Float
            elsif ($ctype == 4) {
                my (@val) = unpack("s2", $data);
                _debug_printf(" col: %02d  data: %s\n", $cid, join(',', @val));
                $record{col}{$cid} = $val[0];
                $record{raw}{$cid} = substr $data, 0, 4;
                $data = substr $data, 4;
            }
            # List!
            elsif ($ctype == 5) {
                my ($val) = unpack("C", $data);
                $record{col}{$cid} = $self->{list}{$cid}[$val - 1];
                _debug_printf(" col: %02d  idx: %d  val: '%s'\n",
                              $cid, $val, $record{col}{$cid});
                $data = substr $data, 1;
            }
            # Checkbox
            elsif ($ctype == 6) {
                my ($val) = unpack("C", $data);
                _debug_printf(" col: %02d  checked: %s\n", $cid, ($val) ? 'yes' : 'no');
                $record{col}{$cid} = $val;
                $data = substr $data, 1;
            }
            # Date
            elsif ($ctype == 7) {
                my ($year, $month, $day) = unpack "nCC", $data;
                _debug_print(" col: $cid  date: $day/$month/$year\n");
                $record{col}{$cid} = sprintf("%02d/%02d/%04d",
                                             $day, $month, $year);
                $data = substr $data, 4;
            }
            # Time
            elsif ($ctype == 8) {
                # Meridian doesn't seem to get used.  Just a null byte?
                my ($meridian, $hour, $minute, $second) = unpack("C4", $data);
                _debug_printf(" col: %02d  time: %02d:%02d:%02d %d\n", $cid,
                              $hour, $minute, $second, $meridian);
                $record{col}{$cid} = sprintf("%02d:%02d:%02d", $hour, $minute, $second);
                $data = substr $data, 4;
            }
            # Equation type
            elsif ($ctype == 9) {
                # We aren't going to do anything with these.
                _debug_printf(" * equation type found\n");
                $record{raw}{$cid} = substr $data, 0, 4;
                $data = substr $data, 4;
            }
            # Memo field types.
            elsif ($ctype == 10) {
                my ($sdat, $slen);
                ($sdat) = unpack "n/a", $data;
                $slen = length($sdat);
                _debug_printf(" col: %02d  strlen: %02d  data: '%s'\n",
                              $cid, $slen, $sdat);
                $record{col}{$cid} = $sdat;
                $data = substr $data, $slen+3;
            }
            # Foreign link types.
            elsif ($ctype == 12) {
                my ($ltype, $slen, $sdat);
                ($ltype) = unpack "C", $data;
                if ($ltype == 1) {
                    # Link is stored as text!
                    ($ltype, $sdat) = unpack "CC/a", $data;
                    $slen = length($sdat);
                    _debug_printf(" col: %02d  strlen: %02d  foo: %02d  data: '%s'\n",
                                  $cid, $slen, $ltype, $sdat);
                    $record{col}{$cid} = $sdat;
                    $record{raw}{$cid} = substr $data, 0, $slen + 3;
                    $data = substr $data, $slen+3;
                } elsif ($ltype == 11) {
                    # What does this signify?  Addressbook link?
                    ($ltype, $sdat) = unpack "C N", $data;
                    _debug_printf(" col: %02d  ltype: %02d  data: '%s'\n", $cid, $ltype, $sdat);
                    $record{col}{$cid} = $sdat;
                    $record{raw}{$cid} = substr $data, 0, 5;
                    $data = substr $data, 5;
                } else {
                    _debug_print(" Column type: $ctype  Column ID:   $cid\n",
                                 " Link Type:   $ltype\n",
                                 " Record data: ", safestr($data), "\n");
                    $data = '';
                }
            }
            # Addressbook link
            elsif ($ctype == 15) {
                my (@foo, $slen, $sdat);
                (@foo[0 .. 3], $sdat) = unpack "C4C/a", $data;
                $slen = length($sdat);
                _debug_printf(" col: %02d  foo: [%s]  data: '%s'\n", $cid, join(',',@foo), $sdat);
                $record{col}{$cid} = $sdat;
                $record{raw}{$cid} = substr $data, 0, $slen + 6;
                $data = substr $data, $slen+6;
            }
            # Another equation sort of thing.
            elsif ($ctype == 19) {
                # We can't do anything with these, either.
                _debug_printf(" * type 19 thingie found\n");
                $record{raw}{$cid} = substr $data, 0, 5;
                $data = substr($data, 5);
            } else {
                _debug_print(" Column type: $ctype\n",
                             " Column ID:   $cid\n",
                             " Record data: ", safestr($data), "\n");
                $data = '';
            }
        }
        push @{$self->{db_records}}, \%record;
    } else {
        #_debug_print " Column type: $ctype\n";
        #_debug_print " Column ID:   $cid\n";
        _debug_print(" Record data: ", safestr($record{data}), "\n");
        $data = '';
    }

    $record{type} = $record_type;

    return \%record;
}

# This one is going to be tricky!
sub PackRecord {
    my $self   = shift @_;
    my $record = shift @_;
    my ($retval, $ctype);

    # Create/pack our list record.
    if ($record->{type} > 2 && $record->{type} < 82) {
        my $cid = $record->{type} - 2;
        if (defined $self->{list_mod}{$cid} &&
            $self->{list_mod}{$cid} == 1) {
            _debug_print("modified\n");
            my $num = scalar(@{$self->{list}{$cid}});
            $retval = pack("C*", $record->{type}, $num, 1 .. $num);
            $retval .= join("\000", @{$self->{list}{$cid}});
            $retval .= "\000\000";
            _debug_print("RETVAL: ", safestr($retval), "\n");
            _debug_print("DATA:   ", safestr($record->{data}), "\n");
        } else {
            $retval = $record->{data};
        }
    }
    # Initialize data type.
    elsif ($record->{type} == 87) {
        if (!defined $record->{idnum}) {
            $record->{idnum} = ++$self->{high_id};
        }
        
        $retval = pack("CxN", 87, $record->{idnum});
        foreach my $field (sort { $a <=> $b } keys %{$record->{col}}) {
            $ctype = $self->{cols}[$field]{type};

            # Pack type for this column.
            $retval .= pack("C2", $ctype, $field);

            # Pack column data.
            # Normal text.
            if ($ctype == 1) {
                $retval .= pack("C/a*x", $record->{col}{$field});
            }
            # Integer
            elsif ($ctype == 2) {
                $retval .= pack("n", $record->{col}{$field});
            }
            # Long
            elsif ($ctype == 3) {
                $retval .= pack("N", $record->{col}{$field});
            }
            # List
            elsif ($ctype == 5) {
                $retval .= pack("C", $self->list_lookup($field, $record->{col}{$field}));
            }
            # Checkbox
            elsif ($ctype == 6) {
                $retval .= pack("C", ($record->{col}{$field}) ? 1 : 0);
            }
            # Date 
            elsif ($ctype == 7) {
                my (@date) = split('/',$record->{col}{$field});
                $retval .= pack("nCC", int($date[2]), int($date[1]), int($date[0]));
            }
            # Time
            elsif ($ctype == 8) {
                # Why the null byte here?
                my (@time) = split(':', $record->{col}{$field});
                $retval .= pack("xC3", @time);
            }
            # Memo
            elsif ($ctype == 10) {
                $retval .= pack("n/a*x", $record->{col}{$field});
            }
            # Something we don't know about yet.
            else {
                # What do we do with 9, 12, 15, and 19?  Especially 12 and 15.
                # We can't handle it, so we just pass the data through.
                _debug_print("Found record I don't know, $field, $ctype\n");
                $retval .= $record->{raw}{$field};
            }
        }

        if ($retval ne $record->{data}) {
            $retval .= "\000\000\000";  # Signals end of record, or something?
        }
        
        _debug_print("RETVAL: ", safestr($retval), "\n",
                     "DATA:   ", safestr($record->{data}), "\n");
    } else {
        _debug_print("*RETVAL: ", safestr($record->{data}), "\n");
        $retval = $record->{data};
    }

    return $retval;

}

# Special stuff.
sub db_records {
    my $self = shift;

    return @{$self->{db_records}};
}

sub get_colnum {
    my $self = shift;
    my $name = shift;

    for (my $i = 1; $i <= $#{$self->{cols}}; $i++) {
        if ($self->{cols}[$i]{name} eq $name) {
            return $i;
        }
    }

    return -1;
}

sub get_colarray {
    my $self = shift;
    my $name = shift;
    my $cid  = $self->get_colnum($name);
    my @ret;

    foreach my $rec (@{$self->{records}}) {
        if ($rec->{type} == 87) {
            push @ret, $rec->{col}{$cid}
              unless $rec->{attributes}{deleted};
        }
    }

    return @ret;
}

sub columns {
    my $self = shift;
    my @ret;
    
    for (my $i = 0; $i <= $#{$self->{cols}}; $i++) {
        if (defined $self->{cols}[$i]) { 
            push @ret, $self->{cols}[$i]{name};
        }
    }

    return @ret;
}

# Modify lists
sub list_lookup {
    my $self = shift;
    my $cid  = shift;
    my $txt  = shift;

    for (my $i = 0; $i <= $#{$self->{list}{$cid}}; $i++) {
        if ($self->{list}{$cid}[$i] eq $txt) {
            return $i + 1;
        }
    }
    return 0;
}

sub add_to_list {
    my $self = shift;
    my $cid  = shift;
    my $item = shift;

    _debug_print("Adding $item to $cid\n");
    push @{$self->{list}{$cid}}, $item;
    $self->{list_mod}{$cid} = 1;
}

# Messy.  Called as $self->set($record, $column_name, $value);
sub set {
    my $self   = shift;
    my $record = shift;
    my $column = shift;
    my $data   = shift;

    my $cnum   = $self->get_colnum($column);

    if ($cnum > 0) {
        $record->{col}{$cnum} = $data;
    }
}

sub get {
    my $self   = shift;
    my $record = shift;
    my $column = shift;

    my $cnum = $self->get_colnum($column);

    if ($cnum > 0) {
        if (defined $record->{col}{$cnum}) {
            return $record->{col}{$cnum};
        } else {
            return '';
        }
    } else {
        return undef;
    }
}


sub _debug_printf {
    printf STDERR @_ if $DEBUG;
}

sub _debug_print {
    print STDERR @_ if $DEBUG;
}

sub safestr ($) {
    my $tmp = shift;
    
    $tmp =~ s/([^a-zA-Z0-9\!\?\+\'\" ])/unpack("C", $1) . '.'/eg;

    return $tmp;
}

1;
__END__

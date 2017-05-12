#! perl

package Palm::ListDB::Writer;

# ListDB.pm -- Create databases for Palm List application.

# Author          : Johan Vromans
# Created On      : Sun Aug 31 20:18:31 2003
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr 11 12:01:23 2017
# Update Count    : 87
# Status          : Unknown, Use with caution!

use strict;
use warnings;
use Carp;

our $VERSION = "1.13";

=head1 NAME

Palm::ListDB::Writer - Create databases for Palm List application

=head1 SYNOPSIS

  use Palm::ListDB::Writer;
  my $db = new Palm::ListDB::Writer
    "MyDataBase",
    "label1" => "Name",
    "label2" => "Address");
  $db->add("Private", "Wife", "16 Localstreet, Netcity", "Some comments");
  $db->add("Public", "John Doe", "1 Main St., Connecticut", "Blah blah");
  $db->write("addr.pdb");

=head1 ABSTRACT

  Palm::ListDB::Writer creates databases for the Palm utility List.

=head1 DESCRIPTION

Palm::ListDB::Writer can be used to create databases for the Palm
utility List, a simple but convenient database application. List is
written by Andrew Low (roo@magma.ca, http://www.magma.ca/~roo).

List databases consist of a collection of records, each having two
label fields and one note field (arbitrary data).

The basic usage is to create a Palm::ListDB::Writer object with
attributes like the name of the database, the primary and secondary
field labels, and then add records by calling its add() method.

The write() method writes the collected data out in the form of a Palm
database.

Limitations posed by the Palm operating system and/or the List
application: database name - 31 characters; field names - 15
characters; category names - 15 characters; 15 categories excluding
the default (Unfiled) catagory; field values - 63 characters; length
of note data - 1023 characters.

This module is not related to L<Palm::ListDB>; the latter can also
import Palm List databases, and requires some knowledge about Palm
databases.

=cut

my @_atts = qw(cat truncate readonly private backup
	       autocat label1 label2);

=head1 METHODS

=over 4

=item new I<database>, [ I<attributes> ]

Default constructor for a new database object.

new() requires one argument, the name of the database.

Initial attributes for the database can be specified after the
database name in the form of key => value pairs:

=over 4

=item label1

The name for the primary record field, max. 15 characters.

=item label2

The name for the secondary record field, max. 15 characters.

=item cat

An array reference with the names of the categories. Max. 15
categories are allowed, and category names must not exceed 15
characters in length.

=item autocat

If non-zero, new categories are automatically added when records are
added. Defaults to true if no initial category names were supplied.

Additional methods can be added later with the add_cat() method.

=item readonly

If true, the database will be readonly and cannot be modified by the
List application.

=item backup

If false, the database will not be backupped upon the next HotSync.
Note that the List application may change this, for example when
modifications are made.

=item private

If true, the database is private and cannot be beamed.

=item truncate

Controls truncation of names and fields that are too long.
If zero, no truncation takes place (the program is terminated).
If one, excess data for the record fields is truncated.
If two, also truncates names for categories and fields.
If three, also truncates the name of the database if needed.

=back

=cut

sub new($;@) {
    my ($pkg, $name, %opts) = @_;
    my $self =
      { name	  => $name,
	cat	  => [],
	_cat	  => {},
	truncate  => 0,
	readonly  => 0,
	private	  => 0,
	backup    => 1,
	autocat	  => undef,
	label1	  => "Field1",
	label2	  => "Field2",
	_data	  => [],
      };
    bless($self, $pkg);

    $self->{name} = $self->_checklen("Database name", $name, 31, 2);

    foreach my $att ( @_atts ) {
	if ( exists($opts{$att}) ) {
	    $self->{$att} = delete($opts{$att});
	}
    }
    croak(__PACKAGE__.": Unknown constructor attributes: ".
	  join(" ", sort(keys(%opts)))) if %opts;

    $self->{autocat} = @{$self->{cat}} ? 0 : 1
      unless defined $self->{autocat};
    unshift(@{$self->{cat}}, "Unfiled");
    my @a = @{$self->{cat}};
    $self->{cat} = [];
    foreach my $cat ( @a ) {
	$self->_addcat($cat);
    }
    $self->{label1} = $self->_checklen("Label1", $self->{label1}, 15, 1);
    $self->{label2} = $self->_checklen("Label2", $self->{label2}, 15, 1);
    $self->{ctime} = $self->{mtime} = $self->{btime} = time;
    $self;
}

sub _checklen {
    my ($self, $name, $value, $max, $lvl) = @_;
    if ( length($value) > $max ) {
	my $v = substr($value,0,30);
	$v =~ s/[^\040-\177]/./g;
	my $msg = __PACKAGE__.": $name (".
	  $v.") too long (".
	  length($value)." > $max)";
	if ( $self->{truncate} > $lvl ) {
	    warn("$msg, truncated\n");
	    substr($value, $max) = "";
	}
	else {
	    croak($msg);
	}
    }
    $value;
}

sub _addcat {
    my ($self, $value) = @_;
    $value = $self->_checklen("Category name", $value, 15, 1);
    return $self->{_cat}->{$value}
      if defined($self->{_cat}->{$value});
    if ( @{$self->{cat}} == 16 ) {
	croak(__PACKAGE__.": Too many categories ($value)");
    }
    push(@{$self->{cat}}, $value);
    $self->{_cat}->{$value} = @{$self->{cat}};
}

=item add I<category>, I<field1>, I<field2>, I<note data>

As the name suggests, add() adds records to the database.

Add() takes exactly four arguments: the category for the record, its
first field, its second field, and the note data. Fields may be left
empty (or undefined), but not all of them.

If the named category does not exists, and autocat is in effect, it is
automatically added to the list of categories.

Add() returns true if the record was successfully added.

=cut

sub add($$$$$) {
    my ($self, $cat, $f1, $f2, $note) = @_;

    if ( $self->{_cat}->{$cat} ) {
	$cat = $self->{_cat}->{$cat};
    }
    elsif ( $self->{autocat} ) {
	$cat = $self->_addcat($cat);
    }
    else {
	carp(__PACKAGE__.": Unknown category ($cat)");
	return 0;
    }
    if ( $f1 eq "" && $f2 eq "" && $note eq "" ) {
	carp(__PACKAGE__.": Record needs data");
	return 0;
    }
    push(@{$self->{_data}},
	 [$cat,
	  $self->_checklen("field1", $f1||"", 63, 1),
	  $self->_checklen("field2", $f2||"", 63, 1),
	  $self->_checklen("note", $note||"", 1023, 0)]);
    1;
}

=item add_cat I<name>

Adds a new category. One parameter, the name of the category to be
added. If the category already exists, nothing happens.

=cut

sub add_cat($$) {
    my ($self, $cat) = @_;
    my $catcode = $self->{_cat}->{$cat};
    return $catcode if $catcode;
    $self->_addcat($cat);
}

=item categories

Returns an array with the current set of categories.
Note that this excludes the (default) 'Unfiled' category.

=cut

sub categories($) {
    my ($self) = @_;
    my @a = @{$self->{cat}};
    shift(@a);
    @a;
}

=item write I<filename>

Write() takes one argument: the file name for the database.

Returns true if the database was successfully written.

=cut

sub write($$) {
    my ($self, $file) = @_;
    unless ( @{$self->{_data}} ) {
	carp(__PACKAGE__.": No records to write to $file");
	return 0;
    }

    # Based on information derived from code by Gustaf Naeser and
    # Darren Dunham.

    my $n_records = scalar(@{$self->{_data}});
    my $dbname = $self->{name};
    my $field1label = $self->{label1};
    my $field2label = $self->{label2};
    my $numcats = @{$self->{cat}};

    # Pre-sort the records. This eliminates the need for List to resort,
    # which makes opening the database very fast.
    use locale;
    my @records = sort {
	lc($a->[1]) cmp lc($b->[1])
	  ||
	lc($a->[2]) cmp lc($b->[2])
	  ||
	$a->[0] <=> $b->[0]
	} @{$self->{_data}};

    my $fh;
    open($fh, ">$file")
      || croak(__PACKAGE__.": $file: $!");
    binmode($fh);

    # Structure of the database
    #
    # - Database header (78 bytes)
    # - Index table ($n_records * 8 bytes + 0x8000 padding)
    # - Application info (512 bytes)
    # - Data (records)

    # The database header (78 bytes)
    #  32 bytes database name, nul filled, nul terminated
    #   2 bytes of attributes, set to 0x0008 (backup)
    #   2 bytes of version information, set to 0x0000
    #  12 bytes dates (creation, modification, last backup; 4 bytes each)
    #   4 bytes modification number, set to 0x00000000
    #   4 bytes offset to application info
    #   4 bytes offset to sort info (set to 0x00000000)
    #   4 bytes type = "DATA"
    #   4 bytes creator = "LSdb"
    #   4 bytes unique seed, set to 0x00000000
    #   4 bytes next record list, set to 0x00000000
    #   2 bytes number of records

    my $headerfmt = "Z32 n n NNN N N N A4 A4 N N n";
    my $hdr = pack($headerfmt,
		   $dbname,
		   0 | ($self->{backup}  ? 0x0008 : 0x0)
		     | ($self->{private} ? 0x0040 : 0x0),
		   0x0000,
		   $self->{ctime},
		   $self->{mtime},
		   $self->{btime},
		   0,
		   78 + ($n_records * 8) + 2,
		   0,
		   "DATA",
		   "LSdb",
		   0,
		   0,
		   $n_records);
    croak(__PACKAGE__.": Header is ".length($hdr)." instead of 78")
      unless length($hdr) == 78;
    print $fh ($hdr);

    # Index table (8 bytes/record + 0x8000 padding)
    #   4 bytes offset to record data
    #   1 byte attributes = index of the category the record belongs to
    #   3 bytes unique id = index of the record (counting from 0)

    my $offset = (78 + ($n_records * 8) + 512 + 2);
    my $index = 0;
    foreach my $record ( @records ) {
	my ($cat, $field1, $field2, $note, $len) = @$record;
	$len = 3;
	$len += length($field1)+1 if $field1 ne "";
	$len += length($field2)+1 if $field2 ne "";
	$len += length($note)+1   if $note ne "";
	$len++ if $len == 3;
	print $fh (pack("NN", $offset, $index | (($cat-1) << 24)));
	$offset += $len;
	$index++;
    }
    # Padding.
    print $fh (pack("n", 0x8000));

    # Application info (size = 512 bytes)
    #   2 bytes renamed categories, set to 0x000e
    #  16 * 16 bytes of category labels, nul padded, nul terminated
    #  16 * 1 byte of category unique ids
    #     (first (Unfiled)) = 0x00
    #     (rest) index + 0x0f if used, index otherwise
    #     E.g. 00 10 11 12 14 15 06 07 08 09 0a 0b 0c 0d 0e 0f
    #   1 byte last unique id, set to the highest category unique id
    #   1 byte display style, set to 0x00 (no resort, field1/field2)
    #   1 byte write protect, 0x00 for off, 0x01 for on
    #   1 byte last category, 0xff for all, 0x00 for Unfiled
    #     (The category view the DB opens with)
    #  16 bytes custom field 1 label, nul padded, nul terminated
    #  16 bytes custom field 2 label, as above
    # 202 bytes padding to make the size 512 bytes

    # Note: repeat groups ups the requirement to 5.8. Not needed.
    my $appinfofmt = "n ".("Z16" x 16)." C16 C C C C Z16Z16 x202";
    my $appinfo = pack($appinfofmt,
		       0x000e,
		       (map { $self->{cat}->[$_] || '' } 0..15),
		       (map { $_ && $_ < $numcats ? $_ + 0x0f : $_ } 0..15),
		       $numcats - 1 + 0x0f,
		       0x00,	# no resort, field1/field2
		   #   0x80,	# force resort, field1/field2
		   #   0x81,	# force resort, field2/field1
		       $self->{readonly} ? 0x01 : 0x00,
		       0xff,	# last category -- all
		       $field1label, $field2label);
    croak(__PACKAGE__.": AppInfo is ".length($appinfo)." instead of 512")
      unless length($appinfo) == 512;
    print $fh ($appinfo);

    # Records
    #   1 byte offset to field 1, 0 if no data in field
    #   1 byte offset to field 2, 0 if no data in field
    #   1 byte offset to note, 0 if no data in field
    #   up to 3 0x00 terminated fields of max length 63, 63, 1023
    #   If no fields, then a nul pad is necessary (though this will never
    #   be the case since we disallow that).

    foreach my $record ( @records ) {
	my ($cat, $field1, $field2, $note) = @$record;
	$offset = 3;
	foreach ( $field1, $field2, $note ) {
	    my $len = length($_);
	    if ( $len ) {
		print $fh (pack("C", $offset));
		$offset += $len + 1;
	    }
	    else {
		print $fh (pack("C", 0));
	    }
	}
	foreach ( $field1, $field2, $note ) {
	    next unless length($_);
	    print $fh (pack("a*x", $_));
	}
    }

    # Everything has been written
    close($fh);

    1;
}

1;
__END__

=head1 SEE ALSO

http://www.magma.ca/~roo web site for the Palm List application.

L<Palm::ListDB>.

=head1 AUTHOR

Johan Vromans, E<lt>jvromans@squirrel.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003,2017 by Squirrel Consultancy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Sys::Export::VFAT::Directory;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Represents a case-folded directory in VFAT


use v5.26;
use warnings;
use experimental qw( signatures );
use Sys::Export::LogAny '$log';
use Encode ();
use Sys::Export::VFAT;
use Scalar::Util qw( weaken );
use List::Util qw( min max );
use Carp;
our @CARP_NOT= qw( Sys::Export::VFAT );


sub new($class, %attrs) {
   my $self= bless {
      name        => delete $attrs{name},
      parent      => delete $attrs{parent},
      file        => delete $attrs{file},
      entries     => delete $attrs{entries} // [],
      ent_by_name => {},
   }, $class;
   croak "Unknown constructor option ".join(', ', keys %attrs) if keys %attrs;
   weaken($self->{parent}) if $self->{parent};
   for ($self->entries->@*) {
      $self->ent_by_name->{$_->{name}}= $_->{name};
      $self->ent_by_name->{$_->{shortname}}= $_->{shortname} if defined $_->{shortname};
   }
   $self;
}


sub name        { $_[0]{name} }
sub parent      { $_[0]{parent} }
sub is_root     { !defined $_[0]{parent} }
sub file        { $_[0]{file} }
sub entries     { $_[0]{entries} }
sub ent_by_name { $_[0]{ent_by_name} }


sub entry {
   $_[0]{ent_by_name}{lc $_[1]}
}


sub add($self, $name, $file, %attrs) {
   croak "Invalid long name" unless $self->is_valid_name($name);
   $attrs{name}= $name;
   $attrs{file}= $file;
   $attrs{shortname} //= $name if $self->is_valid_shortname($name);
   # any conflict?
   my $by_name= $self->ent_by_name;
   croak "Path ".$self->name."/$name already exists"
      if defined $by_name->{lc $name};
   if (defined $attrs{shortname}) {
      utf8::downgrade($attrs{shortname}); # must be bytes
      my $slot= \$by_name->{lc $attrs{shortname}};
      croak "Path ".$self->name."/$name short name '$attrs{shortname}' conflicts with "
         . $self->name."/".$$slot->{name}
         if $$slot;
      $$slot= \%attrs;
   }
   $by_name->{lc $name}= \%attrs;
   push $self->entries->@*, \%attrs;
   \%attrs;
}


# These 3 can be overridden for ISO9660 subclass
sub is_valid_name($self, $name) {
   Sys::Export::VFAT::is_valid_longname($name)
}
sub is_valid_shortname($self, $name) {
   Sys::Export::VFAT::is_valid_shortname($name)
}
sub remove_invalid_shortname_chars($self, $name, $repl) {
   Sys::Export::VFAT::remove_invalid_shortname_chars($name, $repl)
}


sub find_unused_shortname($self, $name) {
   length $name or croak "name cannot be empty";
   my $by_name= $self->ent_by_name;
   my $ext_pos= rindex($name, '.');
   my $base= $ext_pos < 0? $name : substr($name, 0, $ext_pos);
   my $ext=  $ext_pos < 0? ''    : substr($name, $ext_pos+1);
   for ($base, $ext) {
      $_= $self->remove_invalid_shortname_chars($_, '_');
      # Now that all high characters have been removed, optimize these as bytes
      utf8::downgrade($_);
   }
   $ext= '.'.substr($ext,0,3) if length $ext;
   my ($iter, $iter_len, $base_len)= (0,0, length $base);
   if (!$base_len || $base_len > 8) {
      substr($base, min($base_len,6), $base_len, '~1');
      ($iter, $iter_len)= (1, 2);
   }
   while ($by_name->{lc $base.$ext}) {
      my $next_iter_len= 1 + length ++$iter;
      my $iter_pos= min($base_len, 8 - $next_iter_len);
      croak "Can't find available ~N suffix for '$name'"
         if $iter_pos < 0;
      substr($base, $iter_pos, $next_iter_len, '~'.$iter);
      $iter_len= $next_iter_len;
   }
   $self->is_valid_shortname($base.$ext) or die "BUG: '$base$ext' is not a valid shortname";
   return $base.$ext;
}


sub build_shortnames($self) {
   my $by_name= $self->ent_by_name;
   for (sort { lc $a->{name} cmp lc $b->{name} } $self->entries->@*) {
      unless (defined $_->{shortname}) {
         $_->{shortname}= $self->find_unused_shortname($_->{name});
         $by_name->{lc $_->{shortname}}= $_;
      }
   }
   return $self;
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::VFAT::Directory::}{qw( carp confess croak min max weaken )};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::VFAT::Directory - Represents a case-folded directory in VFAT

=head1 DESCRIPTION

Both Microsoft VFAT and ISO9660 filesystems use case-insensitive filenames with a secondary
"short" name limited to 8.3 characters, though they differ slightly in what characters are
allowed in a filename.  This object represents one of those directories as it is being
assembled, with short names added automatically for a set of long names.

The "case folding" function is C<lc>, rather than C<fc>, since C<lc> is the closest Perl
approximation to the folding that Microsoft uses.

=head1 CONSTRUCTORS

=head2 new

  my $dir= Sys::Export::VFAT::Directory->new(%attrs);

Accepts attributes C<name>, C<parent>, C<file>, and C<entries>.

=head1 ATTRIBUTES

=head2 name

Path string or other identifier for debugging purposes.

=head2 parent

A weak reference to the parent directory, or C<undef> at the root.

=head2 is_root

True if C<parent> is C<undef>.

=head2 file

A reference to the File object which holds (or will hold) the encoding of this directory.

=head2 entries

An arrayref of directory entry hashrefs.  This does not include '.' and '..' entries.

=head2 ent_by_name

A hashref of case-folded unicode long filename to entries.  If the short name of an entry is
defined, it is also added to this hash to ensure that long and short names do not conflict.

=head1 METHODS

=head2 entry

  my $ent= $dir->entry($name);

Return a directory entry by case-folded name.

=head2 add

  $ent= $dir->add($name, $file, %other_attrs);

Add a new name / file pair to the list of directory entries, along with any additional
attributes you want to be part of the directory entry.  If the name is valid as a short
filename, this automatically sets the ->{shortname} attribute.

Croaks if the filename is invalid, or if the name is already used.

Returns the hashref storing the directory entry.

=head2 is_valid_name

  $bool= $dir->is_valid_name($name)

Returns true if the name is valid for the filesystem type.

=head2 is_valid_shortname

  $bool= $dir->is_valid_shortname($name)

Returns true if the name is valid as a short 8.3 filename.

=head2 remove_invalid_shortname_chars

  $name= $dir->remove_invalid_shortname_chars($name, $replacement);

Perform a C<< s/[invalid]/$replacement/gr >> on the name, using the set of invalid characters
for this filesystem's short filenames.

=head2 find_unused_shortname

  $short= $dir->find_unused_shortname($longname);

Given a unicode "long name", calculate a 8.3 "short name" which doesn't conflict with any of
the existing names.

=head2 build_shortnames

For every directory entry lacking a shortname, calculate one and update the directory entry and
the L</ent_by_name> hash.

=head1 Directory Entries

Directory entries can have the following hash keys:

=over

=item name

A unicode "long" name

=item shortname

A FAT "short" name in 8.3 notation.  This must be bytes, and is fairly restricted in the ASCII
range, but may contain high-bit bytes for an unspecified BIOS character encoding.

=item file

A reference to a File object (L<::VFAT::File|Sys::Export::VFAT::File> or
L<::ISO9660::File|Sys::Export::ISO9660::File>).

=back

They may also contain other keys specific to the filesystem type.

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

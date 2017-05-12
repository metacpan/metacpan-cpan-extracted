package VCP::DB_File::sdbm;

=head1 NAME

VCP::DB_File::sdbm - Subclass providing SDBM_File storage

=head1 SYNOPSIS

    use VCP::DB_File;
    VCP::DB_File->new;

=head1 DESCRIPTION

To write your own DB_File filetype, copy this file and alter it.  Then
ask us to add an option to the .vcp file parsing to enable it.

=over

=for test_script t/01db_file_sdbm.t

=cut

$VERSION = 1 ;

use strict ;

use VCP::Debug qw( :debug );
use Fcntl;
use File::Spec;
use SDBM_File;
use VCP::Debug qw( :debug );
use VCP::Logger qw( BUG );

use base qw( VCP::DB_File );

use fields (
   'Hash',  ## The hash we tie
);

sub db_file {
   my VCP::DB_File::sdbm $self = shift;
   return File::Spec->catfile(
      $self->store_loc,
      "db"
   );
}


sub close_db {
   my VCP::DB_File::sdbm $self = shift;

   return unless $self->{Hash};

   $self->SUPER::close_db;

   $self->{Hash} = undef;
}


sub delete_db {
   my VCP::DB_File::sdbm $self = shift;

   my $store_files_pattern = $self->store_loc . "/*";

   my $has_store_files = -e $self->store_loc;
   if ( $has_store_files ) {
      my @store_files = glob $store_files_pattern;
      $has_store_files &&= @store_files;
   }

   return
      unless $has_store_files;

   $self->SUPER::delete_db;
   $self->rmdir_store_loc;
}


sub open_db {
   my VCP::DB_File::sdbm $self = shift;

   $self->SUPER::open_db;
   $self->mkdir_store_loc;

   $self->{Hash} = {};

   my $fn = $self->db_file;

   tie %{$self->{Hash}}, "SDBM_File", $fn, O_RDWR|O_CREAT, 0660
      or die "$! while opening DB_File SDBM file '$fn'";
}


sub open_existing_db {
   my VCP::DB_File::sdbm $self = shift;

   $self->SUPER::open_db;
   $self->mkdir_store_loc;

   $self->{Hash} = {};

   my $fn = $self->db_file;

   tie %{$self->{Hash}}, "SDBM_File", $fn, O_RDWR, 0
      or die "$! while opening DB_File SDBM file '$fn'";
}


sub set {
   my VCP::DB_File::sdbm $self = shift;
   my $key_parts = shift;
   BUG "key must be an ARRAY reference"
      unless ref $key_parts eq "ARRAY";

   debug "setting ",
      ref $self, " ",
      join( ",", @$key_parts ), " => ",
      join( ",", @_ )
      if debugging;

   my $key = $self->pack_values( @$key_parts );

   $self->{Hash}->{$key} = $self->pack_values( @_ );
}


sub get {
   my VCP::DB_File::sdbm $self = shift;
   my $key_parts = shift;
   BUG "key must be an ARRAY reference"
      unless ref $key_parts eq "ARRAY";
   BUG "extra args found"
      if @_;
   BUG "called in scalar context"
      if defined wantarray && !wantarray;

   my $key = $self->pack_values( @$key_parts );

   my $v = $self->{Hash}->{$key};

   return unless defined $v;

   $self->unpack_values( $v );
}


sub exists {
   my VCP::DB_File::sdbm $self = shift;
   my $key_parts = shift;
   BUG "key must be an ARRAY reference"
      unless ref $key_parts eq "ARRAY";

   my $key = $self->pack_values( @$key_parts );

   return $self->{Hash}->{$key} ? 1 : 0;
}

=item dump

   $db->dump( \*STDOUT );
   my $s = $db->dump;
   my @l = $db->dump;

Dumps keys and values from a DB, in lexically sorted key order.
If a filehandle reference is provided, prints to that filehandle.
Otherwise, returns a string or array containing the entire dump,
depending on context.


=cut

sub dump {
   my VCP::DB_File::sdbm $self = shift;
   my $fh = @_ ? shift : undef;

   my( @keys, %vals );
   my @w;

   while ( my ( $k, $v ) = each %{$self->{Hash}} ) {
      my @key = $self->unpack_values( $k );

      for ( my $i = 0; $i <= $#key; ++$i ) {
         $w[$i] = length $key[$i]
            if ! defined $w[$i] || length $key[$i] > $w[$i];
      }

      push @keys, $k;
      $vals{$k} = [ $self->unpack_values( $v ) ];
   }

   ## This does not take file separators in to account, but that's ok
   ## for a debugging tool and the ids that are used as key values
   ## are supposed to be opaque anyway
   @keys = sort @keys;

   # build format string
   my $f = join( " ", map "%-${w[$_]}s", 0..$#w ) . " => %s\n";

   my @lines;
   while ( @keys ) {
      my $k = shift @keys;

      my @v = map { "'$_'" } @{$vals{$k}};

      my $s = sprintf $f,
         $self->unpack_values( $k ),
         @v == 1 ? $v[0] : join join( ",", @v ), "(", ")";

      if( defined $fh ) {
         print $fh $s;
      }
      else {
         push @lines, $s;
      }
   }

   unless( defined $fh ) {
      if( wantarray ) {
         chomp @lines;
         return @lines;
      }
      return join "", @lines;
   }
}

=back

=head1 LIMITATIONS

There is no way (yet) of telling the mapper to continue processing the
rules list.  We could implement labels like C< <<I<label>>> > to be
allowed before pattern expressions (but not between pattern and result),
and we could then impelement C< <<goto I<label>>> >.  And a C< <<next>>
> could be used to fall through to the next label.  All of which is
wonderful, but I want to gain some real world experience with the
current system and find a use case for gotos and fallthroughs before I
implement them.  This comment is here to solicit feedback :).

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1

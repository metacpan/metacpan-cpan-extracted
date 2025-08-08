package Sys::Export::ELF;

# ABSTRACT: Unpack various data structures of an ELF binary
our $VERSION = '0.002'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use Carp;
use Scalar::Util 'dualvar';

sub _make_enum {
   my $i= 0;
   map +(defined? dualvar($i++, $_) : undef), @_;
}

our $elf_common_header_packstr= 'a4 C C C C C a7';
our @elf_common_header_fields= qw( magic class data header_version osabi osabi_version padding );

our @elf_header_fields= qw( type machine version entry_point segment_table_ofs section_table_ofs
      flags elf_header_len segment_header_elem_len segment_count
      section_header_elem_len section_count section_name_string_table_idx );
our @elf_header_packstr= (
   'a16 v v V V V V V v v v v v v', # 32-bit LE
   'a16 n n N N N N N n n n n n n', # 32-bit BE
   'a16 v v V Q< Q< Q< V v v v v v v', # 64-bit LE
   'a16 n n N Q> Q> Q> N n n n n n n', # 64-bit BE
);
our @segment_header_len= ( 32, 32, 56, 56 );
# 'flags' moves depending on 32 vs 64 bit, so changing the pack string isn't enough
our @segment_header_fields= (
   [ qw( type offset virt_addr phys_addr filesize memsize flags align ) ],
   [ qw( type offset virt_addr phys_addr filesize memsize flags align ) ],
   [ qw( type flags offset virt_addr phys_addr filesize memsize align ) ],
   [ qw( type flags offset virt_addr phys_addr filesize memsize align ) ],
);
our @segment_header_packstr= (
   'V V V V V V V V',
   'N N N N N N N N',
   'V V Q< Q< Q< Q< Q< Q<',
   'N N Q> Q> Q> Q> Q> Q>',
);
our @segment_header_type= _make_enum qw( NULL LOAD DYNAMIC INTERP NOTE SHLIB PHDR TLS );

our @section_header_len= ( 40, 40, 64, 64 );
our @section_header_fields= qw( name type flags addr offset size link info align entry_size );
our @section_header_packstr= (
   'V V V V V V V V V V',
   'N N N N N N N N N N',
   'V V Q< Q< Q< Q< V V Q< Q<',
   'N N Q> Q> Q> Q> N N Q> Q>',
);

our @dynamic_link_entry_len= ( 8, 8, 16, 16 );
our @dynamic_link_entry_fields= qw( tag val );
our @dynamic_link_entry_packstr= (
   'V V',
   'N N',
   'Q< Q<',
   'Q> Q>',
);
our @dynamic_link_entry_tag= _make_enum qw( NULL NEEDED PLTRELSZ PLTGOT HASH STRTAB SYMTAB RELA
   RELASZ RELAENT STRSZ SYMENT INIT FINI SONAME RPATH SYMBOLIC REL RELSZ RELENT PLTREL DEBUG
   TEXTREL JMPREL BIND_NOW INIT_ARRAY FINI_ARRAY INIT_ARRAYSZ FINI_ARRAYSZ RUNPATH FLAGS
   ENCODING PREINIT_ARRAY PREINIT_ARRAYSZ SYMTAB_SHNDX RELRSZ RELR RELRENT NUM );

our @symbol_table_fields= (
   [qw( name value size info other shndx )],
   [qw( name value size info other shndx )],
   [qw( name info other shndx value size )],
   [qw( name info other shndx value size )],
);
our @symbol_table_packstr= (
   'V V V C C v',
   'N N N C C n',
   'V C C v Q< Q<',
   'N C C n Q> Q>',
);

our @relocation_fields= qw( offset info );
our @relocation_packstr= (
   'V V',
   'N N',
   'Q< Q<',
   'Q> Q>',
);

our @relocation_addend_fields= qw( offset info addend );
our @relocation_addend_packstr= (
   'V V V',
   'N N N',
   'Q< Q< Q<',
   'Q> Q> Q>',
);

sub _strz_from_offset {
   return undef unless 0 <= $_[1] < length $_[0];
   pos $_[0] = $_[1];
   $_[0] =~ /\G([^\0]*)/? $1 : undef;
}


sub unpack {
   my %elf;

   # Start with the encoding-independent fields
   @elf{@elf_common_header_fields}= unpack($elf_common_header_packstr, $_[0]);
   $elf{magic} eq "\x7FELF" or return undef;
   die "Unsupported 'class'" unless 1 <= $elf{class} <= 2;
   die "Unsupported 'data'" unless 1 <= $elf{data} <= 2;
   my $encoding_idx= ($elf{class}-1)*2 + ($elf{data}-1);

   # Now decode the endian and bit-length-varying fields
   (undef, @elf{@elf_header_fields})= unpack $elf_header_packstr[$encoding_idx], $_[0];
   my $lim= length $_[0];
   
   # parse segments
   my @segments;
   # sanity check on table size
   my $elem_len= $elf{segment_header_elem_len};
   if ($elf{segment_count} > 0) {
      $elf{segment_table_ofs} < $lim
         or croak "Segment table beyond end of file";
      $elem_len >= $segment_header_len[$encoding_idx]
         or croak "Segment records are shorter than expected";
      $elf{segment_count} <= (($lim - $elf{segment_table_ofs}) / $elem_len)
         or croak "Segment table extends past end of file";

      for (my $i= 0; $i < $elf{segment_count}; $i++) {
         my $ofs= $elf{segment_table_ofs} + $i * $elem_len;
         my %segment;
         @segment{@{$segment_header_fields[$encoding_idx]}}
            = unpack $segment_header_packstr[$encoding_idx],
                  substr($_[0], $ofs, $elem_len);
         $segment{type}= $segment_header_type[$segment{type}]
            if $segment{type} > 0 && $segment{type} < @segment_header_type;
         push @segments, \%segment;
      }
   }
   $elf{segments}= \@segments;

   $elem_len= $elf{section_header_elem_len};
   my @sections;
   my $dynamic_section;
   if ($elf{section_count} > 0) {
      $elf{section_table_ofs} < $lim
         or croak "Section table beyond end of file";
      $elem_len >= $section_header_len[$encoding_idx]
         or croak "Section records are shorter than expected";
      $elf{section_count} <= (($lim - $elf{section_table_ofs}) / $elem_len)
         or croak "Section table extends past end of file";

      for (my $i= 0; $i < $elf{segment_count}; $i++) {
         my $ofs= $elf{section_table_ofs} + $i * $elem_len;
         my %section;
         @section{@section_header_fields}
            = unpack $section_header_packstr[$encoding_idx],
                  substr($_[0], $ofs, $elem_len);
         push @sections, \%section;
      }
   }
   $elf{sections}= \@sections;

   for my $seg (@segments) {
      if ($seg->{type} eq 'DYNAMIC') {
         $elf{dynamic} and croak "Found multiple PT_DYNAMIC sections?";
         $seg->{offset} >= 0 && $seg->{offset} + $seg->{filesize} < $lim
            or croak "Dynamic section extends beyond end of file";
         my @dynamic_entries;
         for (my $ofs= 0; $ofs < $seg->{filesize}; $ofs += $dynamic_link_entry_len[$encoding_idx]) {
            my %dynamic;
            @dynamic{@dynamic_link_entry_fields}
               = unpack $dynamic_link_entry_packstr[$encoding_idx],
                  substr($_[0], $seg->{offset}+$ofs, $dynamic_link_entry_len[$encoding_idx]);
            $dynamic{tag}= $dynamic_link_entry_tag[$dynamic{tag}]
               if $dynamic{tag} > 0 && $dynamic{tag} < @dynamic_link_entry_tag;

            last if $dynamic{tag} == 0;

            push @dynamic_entries, \%dynamic;
            if ($dynamic{tag} eq 'STRTAB') {
               defined $elf{string_table_offset}
                  and croak "Found multiple STRTAB?";
               $elf{string_table_offset}= $dynamic{val};
            }
         }
         if (defined $elf{string_table_offset}) {
            # now that string table is known, decode the libraary_needed
            my @needed;
            for (@dynamic_entries) {
               if ($_->{tag} eq 'NEEDED') {
                  # Read a NUL-terminated string from this offset in the string table
                  my $str= _strz_from_offset($_[0], $elf{string_table_offset} + $_->{val});
                  push @needed, $str if length $str;
               }
               elsif ($_->{tag} eq 'RPATH' || $_->{tag} eq 'RUNPATH') {
                  my $str= _strz_from_offset($_[0], $elf{string_table_offset} + $_->{val});
                  $elf{rpath}= $str if length $str;
               }
               elsif ($_->{tag} eq 'SONAME') {
                  my $str= _strz_from_offset($_[0], $elf{string_table_offset} + $_->{val});
                  $elf{soname}= $str if length $str;
               }
            }
            $elf{needed_libraries}= \@needed;
         }
         $elf{dynamic}= \@dynamic_entries;
      }
      elsif ($seg->{type} eq 'INTERP') {
         my $str= _strz_from_offset($_[0], $seg->{offset});
         $elf{interpreter}= $str if length $str;
      }
   }

   \%elf;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::ELF - Unpack various data structures of an ELF binary

=head1 DESCRIPTION

This module is a minimalist approach to parsing ELF files.  You read or memory-map the file,
then call C<unpack> on the bytes to get a data structure describing the most useful bits of
the file, such as the libraries it depends on, or its dynamic-linking interpreter.

This module is careful to not make copies of that input scalar, so you can pass a memory-mapped
file (via L<File::Map>) and actually avoid mapping the whole file.

=head1 EXPORTS

=head2 unpack

  my $elf_info= unpack($elf_file_bytes);
  # {
  #    segments            => [ ... ],
  #    sections            => [ ... ],
  #    string_table_offset => $ofs,
  #    dynamic             => [ ... ],  # dynamic link table entries
  #    needed_libraries    => [ ... ],
  #    interpreter         => $path,
  # }

=head1 VERSION

version 0.002

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

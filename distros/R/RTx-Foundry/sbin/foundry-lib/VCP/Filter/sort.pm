package VCP::Filter::sort;

=head1 NAME

VCP::Filter::sort - Sort revs by field, order

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> sort: name ascending rev_id ascending -- <dest>

  ## In a .vcp file:

    Sort:
       name     ascending
       rev_id   ascending

=head1 DESCRIPTION

Useful with the revml: destination to get RevML output in a
desired order.  Otherwise the sorting built in to the change
aggregator should suffice.

The default sort spec is "name,rev_id" which is what is handy to
VCP's test suite as it puts all revisions in a predictable order
so the output revml can be compared to the input revml.

NOTE: this is primarily for development use; not all fields may work
right.  All plain string fields should work right as well as name,
rev_id, change_id and their source_... equivalents (which are parsed and
compared piece-wise) and time, and mod_tome (which are stored as
integers internally).

Plain case sensitive string comparison is used for all fields other than
those mentioned in the preceding paragraphs.

This sort may be slow for extremely large data sets; it sorts things
by comparing revs to eachother field by field instead of by generating
indexes and VCP::Rev is not designed to be super fast when accessing
fields one by one.  This can be altered if need be.

=head1 How rev_id and change_id are sorted

C<change_id> or C<rev_id> are split in to segments
suitable for sorting.

The splits occur at the following points:

   1. Before and after each substring of consecutive digits
   2. Before and after each substring of consecutive letters
   3. Before and after each non-alpha-numeric character

The substrings are greedy: each is as long as possible and non-alphanumeric
characters are discarded.  So "11..22aa33" is split in to 5 segments:
( 11, "", 22, "aa", 33 ).

If a segment is numeric, it is left padded with 10 NUL characters.

This algorithm makes 1.52 be treated like revision 1, minor revision 52, not
like a floating point C<1.52>.  So the following sort order is maintained:

   1.0
   1.0b1
   1.0b2
   1.0b10
   1.0c
   1.1
   1.2
   1.10
   1.11
   1.12

The substring "pre" might be treated specially at some point.

(At least) the following cases are not handled by this algorithm:

   1. floating point rev_ids: 1.0, 1.1, 1.11, 1.12, 1.2
   2. letters as "prereleases": 1.0a, 1.0b, 1.0, 1.1a, 1.1

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg );
use VCP::Debug qw( :debug );
use VCP::Utils qw( empty );
use VCP::Filter;
use base qw( VCP::Filter );

use fields (
   'SORT_SPEC',  ## The parse sort spec as an ARRAY
);

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->{SORT_SPEC} =
      $self->parse_rules_list( $options, "Field", "Order",
         [
            [ "name",   "ascending" ],
            [ "rev_id", "ascending" ],
         ]
      );

   return $self ;
}


sub is_sort_filter { 1 }


sub handle_header {
   my VCP::Filter::sort $self = shift;
   $self->revs->set;  ## clear the list
   $self->SUPER::handle_header( @_ );
}


sub handle_rev {
   my VCP::Filter::sort $self = shift;
   $self->revs->add( shift );
}


sub handle_footer {
   my VCP::Filter::sort $self = shift;
   my %cmps = (
       name             => "VCP::Rev->cmp_name( \$a->name, \$b->name )",
       source_name      =>
          "VCP::Rev->cmp_name( \$a->source_name, \$b->source_name )",
       rev_id           => "VCP::Rev->cmp_id( \$a->rev_id, \$b->rev_id )",
       source_rev_id    =>
          "VCP::Rev->cmp_id( \$a->source_rev_id, \$b->source_rev_id )",
       change_id        => "VCP::Rev->cmp_id( \$a->change_id, \$b->change_id )",
       source_change_id =>
          "VCP::Rev->cmp_id( \$a->source_change_id, \$b->source_change_id )",
       time      => "\$a->time     <=> \$b->time",
       modtime   => "\$a->mod_time <=> \$b->mod_time",
   );

   my @cmps = map {
      my $field_name = lc $_->[0];
      my $order      = lc $_->[1];
      my $cmp = $cmps{$field_name};
      $cmp = "(\$a->$field_name cmp \$b->$field_name )" unless defined $cmp;
      $order =~ /^desc/i ? "- $cmp\n" : "$cmp\n";
   } @{$self->{SORT_SPEC}};

   my @code = ( <<PREAMBLE, join( "|| ", @cmps ), <<POSTAMBLE );
#line 1 VCP::Filter::sort::cmp_sub()
sub {
PREAMBLE
}
POSTAMBLE

   my $sub = eval join "", @code or die "$@:\n@code";

   $self->SUPER::handle_rev( $_ ) for sort $sub $self->revs->get;
   $self->SUPER::handle_footer( @_ );
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1

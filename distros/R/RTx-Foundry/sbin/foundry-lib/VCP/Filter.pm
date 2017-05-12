package VCP::Filter ;

=head1 NAME

VCP::Filter - A base class for filters

=head1 SYNOPSIS

   use VCP::Filter;
   @ISA = qw( VCP::Filter );
   ...

=head1 DESCRIPTION

A VPC::Filter is a VCP::Plugin that is placed between the source
and the destination and allows the stream of revisions to be altered.

For instance, the Map: option in vcp files is implemented by
VCP::Filter::Map

By default a filter is a pass-through.

=cut

$VERSION = 0.1 ;

use strict;
use Carp ();
use VCP::Debug qw( :debug );
use VCP::Logger qw( lg BUG );
use VCP::Utils qw( shell_quote );

use base "VCP::Plugin";
use fields (
    'DEST',   ## Points to the next filter.
);

sub dest {
   my VCP::Filter $self = shift;

   $self->{DEST} = shift if @_;
   return $self->{DEST};
}

###############################################################################

=head1 SUBCLASSING

This class uses the fields pragma, so you'll need to use base and 
possibly fields in any subclasses.

=over

=item parse_rules_list

Used in VCP::Filter::*map and VCP::Filter::*edit to parse lists of rules
where every rule is a set of N "words".  The value of N is computed from
the number of labels passed in and the labels are used when printing an
error message:

    @rules = $self->parse_rules( $options, "Pattern", "Replacement" );

=cut

sub parse_rules_list {
   my $self = shift;
   my $options = shift;
   my $default = @_ && ref $_[-1] ? pop : [];

   my @labels  = @_;
   my $expression_count = @labels;
   BUG "No expression labels passed" unless $expression_count;
   BUG "No options " unless $options;

   my @rule;
   my $rules;
   while ( @$options ) {
      my $v = shift @$options;
      last if $v eq "--";
      
      push @rule, $v;
      push @$rules, [splice @rule] if @rule == $expression_count;
   }
   push @$rules, \@rule if @rule;

   $rules = $default unless $rules || @rule;

   my @out = map [
      map shell_quote( $_ ), @$_
   ], @$rules;

   my @w;
   for ( \@labels, @out ) {
      for my $i (0..$#$_) {
         $w[$i] = length $_->[$i]
            if ! defined $w[$i] || length $_->[$i] > $w[$i];
      }
   }

   ( my $filter_type = ref $self ) =~ s/.*://;
   my $format = join " ", map "%-${_}s", @w;
   my @msg = (
      sprintf( "#   $format\n", @labels ),
      sprintf( "#   $format\n", map "=" x $_, @w ),
      map(
         sprintf( "    $format\n", map defined $_ ? $_ : "", @$_ ),
         @out
      )
   );

   die "incomplete rule in $filter_type:\n\n", @msg, "\n" if @rule;

   lg "$filter_type rules:\n", @msg;

   return $rules;
}

=item last_rev_in_filebranch

(passthru; see L<VCP::Dest|VCP::Dest>)

=cut

sub last_rev_in_filebranch {
   shift->dest->last_rev_in_filebranch( @_ );
}

=item backfill

(passthru; see L<VCP::Dest|VCP::Dest>)

=cut

sub backfill {
   shift->dest->backfill( @_ );
}

=item is_sort_filter

Sort filters should return a 1 in this method, see L<VCP::Plugin> for details.

=cut

## inherited

=item handle_header

(passthru)

=cut

sub handle_header {
   shift->dest->handle_header( @_ );
}

=item handle_rev

(passthru)

=cut

sub handle_rev {
   shift->dest->handle_rev( @_ );
}

=item handle_footer

(passthru)

=cut

sub handle_footer {
   shift->dest->handle_footer( @_ );
}

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1

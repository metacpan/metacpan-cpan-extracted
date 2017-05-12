package VCP::Filter::changesets;

=head1 NAME

VCP::Filter::changesets - Group revs in to changesets

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> changesets: ...options... -- <dest>

  ## In a .vcp file:

    ChangeSets:
       time                     <=60   ## seconds
       user_id                  equal  ## case-sensitive equality
       comment                  equal  ## case-sensitive equality
       branched_rev_branch_id   equal  ## change only one branch at a time

=head1 DESCRIPTION

This filter is automatically loaded when there is no sort filter loaded
(both this and L<VCP::Filter::sort|VCP::Filter::sort> count as sort
filters, more may be added).

When all revs from the source have change numbers, this filter sorts by
change_id and only by change_id, regardless of the rules set.

If at least one revision arrives from the source with an empty
change_id, the rules for this filter establish the conditions that
determine what revisions may be grouped in to each change.

In this case, this filter rewrites all change_id fields so that the
(eventual) destination can use the change_id field to break the
revisions in to changes.  This is sometimes used by non-changeset
oriented destinations to aggregate "changes" as though a user were
performing them and to reduce the number of individual operations the
destination driver must perform (for instance: VCP::Dest::cvs prefers
to not call cvs commit all the time; cvs commit is slow).

If you don't specify any conditions, a set of default conditions are
used.  If you specify any conditions at all, none of the default
conditions are used.  The default conditions are:

    time                     <=60   ## seconds
    user_id                  equal  ## case-sensitive equality
    comment                  equal  ## case-sensitive equality
    branched_rev_branch_id   equal  ## change only one branch at a time

The C<time <=60> condition sets a maximum allowable difference between two
revisions; revisions that are more than this number of seconds apart are
considered to be in different changes.  You may use "equal", "<#"
or "<=#" when comparing time and mod_time.  If a plain number is
provided, <= is assumed.

The C<user_id equal> and C<comment equal> conditions assert that two
revisions must be by the same user and have the same comment in order to
be in the same change.

The C<branched_rev_branch_id equal> condition is a special case to handle
repositories like CVS which don't record branch creation times.  This
condition kicks in when a user creates several branches before changing
any files on any of them then all of the branches get created at the
same time.  This condition also kicks in when multiple CVS branches
exist with no changes on them.  In this case, VCP::Source::cvs groups
all of the branch creations after the last "real" edit.

The C<branched_rev_branch_id> condition only applies to revisions
branching from one branch in to another.

For all fields but C<time> and C<mod_time>, you may (for now) only use
the C<equal> condition, which is case sensitive equality.

An implicit condition is that a parent and a child may not both be
altered in the same change.

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg pr );
use VCP::Debug qw( :debug );
use VCP::Utils qw( empty );
use VCP::Filter;
use VCP::Rev;
use base qw( VCP::Filter );

use fields (
   'CMP_SUB',         ## Compare two revs for changeset equality
   'COMMENT_TIMES',   ## The average time of all instances of a comment
   'HAS_CHANGE_IDS', ## set if all revs have nonempty change_ids
);

sub _eq {
    defined $_[0] 
       ? defined $_[1]
           ? $_[0] eq $_[1]
           : 0
       : ! defined $_[1];
}


sub _compile_cmp_sub {
   my VCP::Filter::changesets $self = shift;
   my ( $rules ) = @_;

   my @cmps = join "\n   && ", map {
      my ( $field, $cond ) = map lc, @$_;
      my $cmp;
      if (
         ( $field eq "time" || $field eq "mod_time" )
         && $cond =~ /\A(<|<=)?\d+\z/
      ) {
         $cond = "<= $cond" unless defined $1;
         $cmp = "abs( ( \$ra->time || 0 ) - ( \$rb->time || 0 ) ) $cond";
      }
      elsif ( $field eq "branched_rev_branch_id"
         && $cond eq "equal"
      ) {
         $cmp = <<'CMP';
   (_eq( $ra->branch_id, $rb->branch_id ) ?
    $ra->is_placeholder_rev ? $rb->is_placeholder_rev ? 1 : 0
 : !$rb->is_placeholder_rev : 0)
CMP
         chomp $cmp;
      }
      elsif ( $cond eq "equal" ) {
         $cmp = "_eq( \$ra->$field, \$rb->$field )";
      }
      else {
         die "unknown condition in ChangeSets: rule: $field $cond\n";
      }

      $cmp;
   } @$rules;

   my @code = ( <<PREAMBLE, "   ", @cmps, <<POSTAMBLE );
#line 1 VCP::Filter::changesets::in_same_change()
sub {
   my ( \$ra, \$rb ) = \@_;
PREAMBLE
;
}
POSTAMBLE

   debug @code if debugging;

   $self->{CMP_SUB} = eval join "", @code
      or die "$@ in ChangeSets filter:\n@code";
}


sub new {
   my $class = ref $_[0] ? ref shift : shift;
   my $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $options ||= [];

   $self->_compile_cmp_sub(
      $self->parse_rules_list(
         $options, "Field", "Condition",
         [
            [qw( time                   60    )],
            [qw( user_id                equal )],
            [qw( comment                equal )],
            [qw( branched_rev_branch_id equal )],
         ]
      )
   );


   return $self ;
}


sub is_sort_filter { 1 }


sub handle_header {
   my VCP::Filter::changesets $self = shift;
   $self->revs->set;  ## clear the list
   $self->SUPER::handle_header( @_ );
   $self->{HAS_CHANGE_IDS}      = 1;
}


sub handle_rev {
   my VCP::Filter::changesets $self = shift;
   $self->{HAS_CHANGE_IDS} &&= !empty $_[0]->change_id;
   $self->revs->add( shift );
}


sub _compile_sort_rec_bulk_indexer {
   my ( $rev, $spec ) = @_ ;

   my $code = join "",
      q[sub { my $revs = shift; my $r; for my $sr ( @$revs ) { $r = $sr->[0]; $sr->[1] = pack '],
      map( $rev->pack_format( $_ ), @$spec ),
      q[', ],
      join( ", ", map $rev->index_value_expression( $_ ), @$spec ),
      q[}}];

   return ( eval $code or die $@ );
}


sub _calc_sort_recs {
   my VCP::Filter::changesets $self = shift ;
   my ( $sort_recs, $spec ) = @_;

   return unless @$sort_recs;

   lg "sort key: ", join ", ", map "'$_'", @$spec;

   if ( grep /avg_comment_time/, @$spec ) {
      $self->{COMMENT_TIMES} = {};
      for ( @$sort_recs ) {
         my $r = $_->[0];
         my $comment = defined $r->comment
             ? $r->comment
             : $r->is_base_rev ? "" : undef;
         my $time = defined $r->sort_time
             ? $r->sort_time
             : $r->is_base_rev ? 0 : undef;
         next unless defined $comment && defined $time;
         push @{$self->{COMMENT_TIMES}->{$comment}}, $time;
      }

      for ( values %{$self->{COMMENT_TIMES}} ) {
         next unless @$_;
         my $sum;
         $sum += $_ for @$_;
         $_ = $sum / @$_;
      }
   }

   my $indexer = _compile_sort_rec_bulk_indexer( $sort_recs->[0]->[0], $spec );
   $indexer->( $sort_recs );
}


sub sort_revs_by_change_id {
   my VCP::Filter::changesets $self = shift;

   ## TODO: see if we can make this more efficient by preindexing all
   ## the change_ids and using <=> to sort them.
   pr "sorting revisions by change_id";
   $self->revs->set(
      sort { VCP::Rev->cmp_id( $a->change_id, $b->change_id ) }
         $self->revs->get
   );
}


sub sort_revs {
   my VCP::Filter::changesets $self = shift;

   ## Use the ->previous references to find the roots and then
   ## reorder the revs by growing up from the roots.

   my %rev_kids;
   my @roots;
   my @sort_recs;

   pr "aggregating changes\n";

   lg "creating revision trees";

   for my $r ( $self->revs->get ) {
      ## the undef is so the sort keys can be filled in later
      ## without needing to increase the memory size.
      my $sort_rec = [ $r, undef ];
      push @sort_recs, $sort_rec;

      if ( $r->previous ) {
         push @{$rev_kids{int $r->previous}}, $sort_rec;
      }
      else {
         push @roots, $sort_rec;
      }
   }

   lg "generating index";
   my @spec = qw( time user_id comment branch_id name );

   VCP::Rev::preindex;

   $self->_calc_sort_recs( \@sort_recs, \@spec );

   lg "doing change aggregation";
   my @result;
   @roots = sort { $a->[1] cmp $b->[1] } @roots;

   my $change_number = 0;

   my $in_same_change = sub {
	no warnings 'uninitialized';
	(($_[0]->rev_id eq $_[1]->rev_id) && $_[0]->rev_id eq '1.1' &&
         ($_[0]->action eq $_[1]->action) && $_[0]->action eq 'delete') ||
	&{$self->{CMP_SUB}} (@_);
	};

   while ( @roots ) {
      ++$change_number;
      my @change;
      my @kids;

      ## Extract one change and then add in all children of the
      ## extracted revisions.
      do {
         my ( $r, undef ) = @{shift @roots};  ## discard sort key
         push @change, $r;
         my $kids = delete $rev_kids{int $r};
         push @kids, @$kids if $kids;
      } while ( @roots
         && $in_same_change->( $change[-1], $roots[0]->[0] )
      );

      lg "...change $change_number: " . @change . " revs";

      $_->change_id( $change_number ) for @change;

      push @result, @change;

      if ( @kids ) {
         ## This is the slow but guaranteed perfect way to sort:
         #@roots = sort { $a->[1] cmp $b->[1] } @roots, @kids;
         #next;

         ## This is the faster but more comples production sorting.
         ## It's a merge sort with some common cases short circuited
         ## out.
         @kids = sort { $a->[1] cmp $b->[1] } @kids
            if @kids > 1;

         if ( @roots ) {
            if ( $kids[0]->[1] ge $roots[-1]->[1] ) {
               push @roots, @kids;
            }
            elsif ( $kids[-1]->[1] le $roots[0]->[1] ) {
               unshift @roots, @kids;
            }
            else {
               my @result;

               ## 5 is just a guess.
               if ( @roots > 5 ) {
                  ## Find the first root that is greater than the first
                  ## kid and splice all preceding roots out.
                  my $i = 0;
                  my $k = $kids[0]->[1];
                  ++$i while $i <= $#roots && $k ge $roots[$i]->[1];
                  @result = splice @roots, 0, $i;
               }

               ## This is the slowest bit.
               while ( @roots && @kids ) {
                  my $w = $roots[0]->[1] cmp $kids[0]->[1];
                  if    ( $w < 0 ) { push @result, shift @roots }
                  elsif ( $w > 0 ) { push @result, shift @kids  }
                  else             { push @result, shift @roots, shift @kids  }
               }

               @roots = ( @result, @roots, @kids );
            }
         }
         else {
            @roots = @kids;
         }
      }
   }

   pr $change_number, " changes found",
      $change_number
         ? sprintf " (%.2f mean revs/change)", $self->revs->get / $change_number
         : (),
      "\n";

   $self->revs->set( @result );
}

sub handle_footer {
   my VCP::Filter::changesets $self = shift;
   $self->{HAS_CHANGE_IDS}
      ? $self->sort_revs_by_change_id
      : $self->sort_revs;
   $self->SUPER::handle_rev( $_ ) for $self->revs->get;
   $self->revs->remove_all;
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

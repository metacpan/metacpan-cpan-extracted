package VCP::Rev;

=head1 NAME

VCP::Rev - VCP's concept of a revision

=head1 SYNOPSIS

   use VCP::Rev;

   use VCP::Rev qw( iso8601format );

   my $r = VCP::Rev->new;

=head1 DESCRIPTION

A data structure that represents a revision to a file (but, technically,
not a version of a file, though the two are often synonymous).

=head1 METHODS

=over

=cut

$VERSION = 1 ;

@EXPORT_OK = qw( iso8601format );
use Exporter ();
*import = \&Exporter::import;
*import = \&Exporter::import;

use strict ;

use Carp ;
use VCP::Logger qw( lg pr );
use VCP::Debug ':debug' ;
use VCP::Utils 'empty' ;

# Because names and comments have so much duplication, we store them
# in hashes and refer to those hashes.  Each element is actually
# an ARRAY in which we store both the name and a rank.  Once all names
# have been read, we sort the names and assign the first name the
# rank of 0, etc.  This allows for very fast sorting.

# Same goes for rev_ids and change_ids, which are not really much of
# a space savings over storing the strings, but this allows us to
# process each ..._id once in to an index for sorting, instead of
# once per file,
# for instance, which is valuable when many files can have the same
# rev_id.  This saves both processor and memory.

## ranked strings (these may be sorted on)
## see the field definitions, the autogenned accessors and sub preindex.
my %names;
my %user_ids;
my %branch_ids;
my %rev_ids;
#my %change_ids;
my %comments;

## shared strings
## see the field definitions, the autogenned accessors and sub preindex.
my %vcp_source_scm_fns;
my @vcp_source_scm_fns;

## this tells new() how much to preallocate and how.
my $array_slots;
my $pack_init;  ## A string to copy in to $self->[0]

## this tells where to get each non-pack()ed field
my %field_pos;

BEGIN {
## VCP::Revs are blessed arrays that contain a series of unpacked fields
## (the references to shared strings above) and a packed string.  The
## accessors for the packed strings unpack as needed.  The packing is
## to save overhead for "payload" fields that are not used for sorting.
##
my @fields = (
   ##
   ## RevML fields and their types.
   ##    s=string, the default
   ##    i=integer
   ##    R=a ranked string, which are indexed for sorting
   ##    S=a shared string, which are shared to conserve space
   ##    _=build private accessors (prefixed with an "_") for a packed
   ##      field; allows public wrappers around packed fields.
   ##    x=store as-is, don't share or pack.
   ##
   'ID:_',                 ## A unique identifier for the rev
   'NAME:R',               ## The file name, relative to REV_ROOT
   'SOURCE_NAME',          ## immutable field, initialized to NAME
   'SOURCE_FILEBRANCH_ID', ## immutable field, initialized to
                           ## NAME or NAME<branch_number> for cvs
   'SOURCE_REPO_ID',       ## immutable field, initialized to
                           ## <repo_type>:<repo_server>
   'TYPE',                 ## Type.  Binary/text.
   'BRANCH_ID:R',          ## What branch this revision is on
   'SOURCE_BRANCH_ID',     ## immutable field initialized to BRANCH_ID
   'REV_ID:R',             ## The source repositories unique ID for this revision
   'SOURCE_REV_ID',        ## immutable field initialized to REV_ID
   'CHANGE_ID',            ## The unique ID for the change set, if any
   'SOURCE_CHANGE_ID',     ## immutable field initialized to CHANGE_ID
   'P4_INFO',              ## p4-specific info.
   'CVS_INFO',             ## cvs-specific info.
   'SVN_INFO:x',	   ## svn-specific info.
   'TIME:i',               ## The commit/submit time, in seconds-since-the-epoch
   'MOD_TIME:i',           ## The last modification time, if available
   'USER_ID:R',            ## The submitter/commiter of the revision
   'LABELS:_',             ## A bit vector of tags/labels assoc. with this rev.
   'COMMENT:R',            ## The comment/message for this rev.
   'ACTION',               ## What was done ('edit', 'move', 'delete', etc.)
   'PREVIOUS_ID',          ## The id of the preceding version
   
   ##
   ## Internal fields: used by VCP::* modules, but not present in RevML files.
   ##
   'WORK_PATH:_',         ## Where to find the revision on the local filesys
   'DEST_WORK_PATH:_',    ## Where to find the rev on local fs if it was backfilled
   'VCP_SOURCE_SCM_FN:S', ## Non-normalized name of the file, meaningful only to
                          ## a specific VCP::Source
   'PREVIOUS:_x',         ## A reference to the preceding version, if any

   'AVG_COMMENT_TIME:i', ## Calculated by VCP::Dest for sorting purposes
   'SORT_TIME:i',        ## When TIME is missing (think VSS), we need
                         ## to kludge in a time without passing that
                         ## time to the dest repository.
   'IS_FOUNDING_REV',    ## Set to indicate that this is the first revision
                         ## in a line of code (not the result of a branch;
                         ## rather an initial checkin with *no* predecessors).
                         ## This is for use only in VCP::Source::* and is
                         ## not to be used elsewhere.
);

##
## Compile the fields' accessors
##

## build a more accessible structure from the above:
my $field_pos = 2;        ## The index of the next non-packed field to be built
                          ## Leave [0] for the packed string and [1] for the
                          ## defined indicator.

$array_slots = $field_pos;

my $packed_field_pos = 0; ## The index of the next packed field to be built
my @pack_format;
my @pack_init;

my %call_count;
END {
    lg "$_: $call_count{$_}\n" for sort keys %call_count;
}

my %fields = map {
   my $key = $_;
   my ( $name, $type ) = split /:/;
   my $is_private = $type ? $type =~ s/_// : undef;
   $type = "s" unless $type;
   my $pack_format = 
      $type eq "s" ? "w/a*" :
      $type eq "i" ? "l1"   :
      $type eq "u" ? "L1"   :
      undef;  ## Other formats may not be packed.

   my $pack_undef_as;

   if ( $pack_format ) {
      push @pack_format, $pack_format if $pack_format;
      $pack_undef_as = $type eq "i" ? 0 : $type eq "u" ? 0 : "";
      push @pack_init, $pack_undef_as;
   }

   $field_pos{$name} = $field_pos unless $pack_format;

   (
      $key => {
         NAME          => $name,
         public_name   => lc $name,
         name          => ( $is_private ? "_" : "" ) . lc $name,
         set_name      => ( $is_private ? "_" : "" ) . "set_" . lc $name,
         type          => $type,
         pack_format   => $pack_format,
         pack_undef_as => $pack_undef_as,
         pack_pos      => $pack_format ? $packed_field_pos++ : undef,
         pos           => $pack_format ? undef : $field_pos++,
      }
   );
} @fields;

my $pack_format = join " ", @pack_format;
$pack_init = pack $pack_format, @pack_init;

## Only need the number of slots *after* the ones used for packing.
$array_slots = $field_pos - $array_slots;

my @code;

my @packed_fields;

for ( map $fields{$_}, @fields ) {
   if ( $_->{pack_format} ) {
      push @packed_fields, $_;
      my $unpack_format = join " ", @pack_format[0..$_->{pack_pos}];
      my $name = $_->{name};
      my $set_name = $_->{set_name};

      my $pack_undef_as = $_->{pack_undef_as};
      $pack_undef_as = '""' if empty $pack_undef_as;

      push @code, <<ACCESSOR;
#line 1 VCP::Rev::$name()
sub $name {
   goto &$set_name if \@_ > 1;
\$call_count{$name}++;
   return undef unless vec \$_[0]->[1], $_->{pack_pos}, 1;
   return (unpack "$unpack_format", \$_[0]->[0] )[-1];
}


#line 1 VCP::Rev::$set_name()
sub $set_name {
   my \$self = shift;
\$call_count{$set_name}++;
   my \@guts = unpack "$pack_format", \$self->[0];
   my \$is_defined = defined \$_[0];
   vec( \$self->[1], $_->{pack_pos}, 1 ) = \$is_defined;
   \$guts[$_->{pack_pos}] = \$is_defined ? shift : $pack_undef_as;
   \$self->[0] = pack "$pack_format", \@guts;

   Carp::cluck "$set_name called in non-void context" if defined wantarray;
}
ACCESSOR
   }
   elsif ( $_->{type} eq "x" ) {
      ## store as-is.
      my $name = $_->{name};
      my $set_name = $_->{set_name};

      push @code, <<ACCESSOR;
#line 1 VCP::Rev::$name()
sub $name {
   goto &$set_name if \@_ > 1;
   return \$_[0]->[$_->{pos}];
}


#line 1 VCP::Rev::$set_name()
sub $set_name {
   my \$self = shift;
   confess "too many parameters passed" if \@_ > 1 ;
   \$self->[$_->{pos}] = shift;
   Carp::cluck "$set_name called in non-void context" if defined wantarray;
}
ACCESSOR
   }
   elsif ( $_->{type} eq "R" ) {
      ## shared, ranked strings
      my $name = $_->{name};
      my $set_name = $_->{set_name};

      push @code, <<ACCESSOR;
#line 1 VCP::Rev::$name()
sub $name {
   goto &$set_name if \@_ > 1;
   return defined \$_[0]->[$_->{pos}]
      ? \$_[0]->[$_->{pos}]->[0]
      : undef;
}


#line 1 VCP::Rev::$set_name()
sub $set_name {
   my \$self = shift;
   confess "too many parameters passed" if \@_ > 1 ;
   \$self->[$_->{pos}] = defined \$_[0]
      ? \$${name}s{\$_[0]} ||= [ \$_[0], undef ]
      : undef;
   Carp::cluck "$set_name called in non-void context" if defined wantarray;
}
ACCESSOR
   }
   elsif ( $_->{type} eq "S" ) {
      ## shared, unranked strings
      my $name = $_->{name};
      my $set_name = $_->{set_name};
      my $n = $name . "s";

      push @code, <<ACCESSOR;
#line 1 VCP::Rev::$name()
sub $name {
   goto &$set_name if \@_ > 1;
   return defined \$_[0]->[$_->{pos}]
      ? \$$n\[ \$_[0]->[$_->{pos}] ]
      : undef;
}


#line 1 VCP::Rev::$set_name()
sub $set_name {
   my \$self = shift;
   confess "too many parameters passed" if \@_ > 1 ;
   my ( \$v ) = \@_;
   unless ( defined \$v ) {
      \$self->[$_->{pos}] = undef;
   }
   elsif ( !exists \$$n\{\$v} ) {
      push \@$n, \$v;
      die "Too many $n" if \$#$n >= 2**31;
      \$$n\{\$v} = \$#$n;
      \$self->[$_->{pos}] = \$$n\{\$v};
   }
   else {
      \$self->[$_->{pos}] = \$$n\{\$v};
   }
   Carp::cluck "$set_name called in non-void context" if defined wantarray;
}
ACCESSOR
   }
}

##
## These fields have special set_...() wrappers that should be called on
## startup.
$_->{force_set} = 1 for grep $_->{public_name} =~ m{\A(
   labels
   |work_path
   |dest_work_path
)\z}x, values %fields;

push(
   @code,

   <<FAST_NEW_START,
#line 1 VCP::Rev::new()
sub new {
   my \$class = ref \$_[0] ? ref shift : shift;
   my \%h = \@_;
   my \$self = bless [
      pack(
         "$pack_format",
FAST_NEW_START

   (map {
      my $pack_undef_as = $_->{pack_undef_as};
      $pack_undef_as = '""' if empty $pack_undef_as;
      $_->{force_set}
         ? "         $pack_undef_as, ## $_->{public_name}\n"
         :
"         defined \$h{$_->{public_name}} ? \$h{$_->{public_name}} : $pack_undef_as,\n";
   } @packed_fields),

   <<FAST_NEW_PACK_END,
      ),
FAST_NEW_PACK_END

   <<FAST_NEW_VEC,
      pack(
FAST_NEW_VEC

   qq{      "} . ( "b" . @packed_fields ) . qq{", join "",\n}, 

   map( "         defined \$h{$_->{public_name}} ? 1 : 0,\n", @packed_fields),

   <<FAST_NEW_VEC_END,
      ),
FAST_NEW_VEC_END

   "      undef,\n" x ( $array_slots ),

   "   ], \$class;\n",
   
   map(
      "   \$self->set_$_( \$h{$_} ) if defined \$h{$_};\n",
      map $_->{public_name}, grep defined $_->{pos} || $_->{force_set}, map $fields{$_}, @fields
   ),

   <<FAST_NEW_END,

Carp::cluck if ( \$self->action || "" ) eq "branch";

   return \$self;
}
FAST_NEW_END
);

eval join "", @code, 1 or do {
    my $line = 1;
    ( my $msg = join "", @code ) =~ s/^/sprintf "%3d|", $line++/mge;
    die "$@:\n$msg";
};

}

## Labels get applied to lots and lots of revs, especially in the xfree
## code we're testing with, and they aren't used in the sorting alg, so
## it makes sense to store labels once and then refer to them with
## packed integers.
my @labels;  ## array of labels
my %labels;  ## $label => $index_in_labels_array

sub set_labels {
   my VCP::Rev $self = shift ;
   my ( $labels ) = @_;

   push( @labels, $_ ), $labels{$_} = $#labels
       for grep ! exists $labels{$_}, @$labels;

   my %seen;
   $self->_set_labels(
      pack "L*", grep !$seen{$_}++, map $labels{$_}, @$labels
   );
}


sub labels {
   Carp::confess "call set_labels instead!" if @_ > 1;

   my VCP::Rev $self = shift ;
   my $l = $self->_labels;
   return if empty $l;
   return sort map $labels[$_], unpack "L*", $l;
}


sub split_name {
   shift;
   local $_ = $_[0];
   return ()     unless defined ;
   return ( "" ) unless length ;

   s{\A[\\/]+}{};
   s{[\\/]+\z}{};

   return split qr{[\\/]+};
}

sub cmp_name {
   my $self = shift;
   Carp::confess unless UNIVERSAL::isa( $self, __PACKAGE__ );

   my @a = ref $_[0] ? @{$_[0]} : $self->split_name( $_[0] );
   my @b = ref $_[1] ? @{$_[1]} : $self->split_name( $_[1] );

   my $r = 0;
   $r = shift( @a ) cmp shift( @b )
      while ! $r && @a && @b;

   $r || @a <=> @b;
}

=item split_id

   VCP::Rev->split_id( $id );

Splits an id in to chunks on punctuation and number/letter boundaries.

   Id           Result
   ==           ======
   1            ( 1 )
   1a           ( 1, "a" )
   1.2          ( 1, "", 2 )
   1a.2         ( 1, "a", 2 )

This oddness is to facilitate manually named revisions that use a
lettering scheme.  Note that the sort algorithms make an assumption that
"1.0a" is after "1.0".  This prevents kind of naming like "1.2pre1".

=cut

sub split_id {
   shift;
   for ( $_[0] ) {
      return ()     unless defined ;
      return ( "" ) unless length ;

      my @r = map /(\d*)(\D*)/, split /[^[:alnum:]]+/;
      pop @r while @r && ! length $r[-1];
      return @r;
   }
}

=item join_id

   VCP::Rev->join_id( @id );

Joins an id's chunks back to being an id in dotted format.

=cut

sub join_id {
   shift;
   my @in = ref $_[0] ? @{shift()} : @_;
   my @out;
   while ( @in ) {
      my $num = shift @in;
      $num .= shift @in if @in;
      push @out, $num;
   }

   return join ".", @out;
}

=item is_founding_rev

Set if and only if this revision has no predecessors.  This is used
only in VCP::Source::* (in fact, only VCP::Source::cvs at the time
of this writing) as a bookkeeping field that prevents the source from
trying to emit base revisions for founding revision

=cut

## Autogenerated.

=item cmp_id

   VCP::Rev->cmp_id( $id1, $id2 );
   VCP::Rev->cmp_id( \@id1, \@id2 );  # for presplit ids

splits $id1 and $id2 if necessary and compares them using C<< <=> >> on
even numbered elements and C<cmp> on odd numbered elements.

=cut

sub cmp_id {
   my $self = shift;
   Carp::confess unless UNIVERSAL::isa( $self, __PACKAGE__ );

   my @a = ref $_[0] ? @{$_[0]} : $self->split_id( $_[0] );
   my @b = ref $_[1] ? @{$_[1]} : $self->split_id( $_[1] );

   my ( $A, $B, $r );
   while ( 1 ) {
      last unless @a && @b;
      ( $A, $B ) = ( shift @a, shift @b );
      $r = $A <=> $B;
      return $r if $r;

      last unless @a && @b;
      ( $A, $B ) = ( shift @a, shift @b );
      $r = $A cmp $B;
      return $r if $r;
   }

   return @a <=> @b;
}



=item sort_time

When some revisions come without a time field, as in VSS, the sort
algorithm needs to plug in a "best guess" time to facilitate sorting.

If no time (or a time of 0) is set, the sort_time field is used instead,
if set.

=cut

# sort_time is autogenerated


=item preindex

NOTE: A function.

This is called from sort_revs() to rank certain fields by sorting them
and using numbers to represent their sort order.  This is both a speed
and a memory optimization.

=cut

# Called after last rev is added, before doing any sorting.
sub preindex {
   my $rank = 0;
   $comments{$_}->[1]    = $rank++ for sort keys %comments;

   {
      # names are more work: we split them in to segments and do a segment
      # oriented sort.
      my @names = values %names;
      $_->[1] = [ VCP::Rev->split_name( $_->[0] ) ] for @names;
      $rank = 0;
      $_->[1] = $rank++ for sort {
         my @a = @{$a->[1]};
         my @b = @{$b->[1]};

         my $r = 0;
         $r = shift( @a ) cmp shift( @b )
            while ! $r && @a && @b;

         $r || @a <=> @b;
      } @names;
   }

   {
      $rank = 0;
      $_->[1] = $rank++ for sort { $a->[0] cmp $b->[0] } values %branch_ids;
   }

   {
      $rank = 0;
      $_->[1] = $rank++ for sort { $a->[0] cmp $b->[0] } values %user_ids;
   }

   {
      # ids are more work yet: we split them in to segments, pack()
      # all segments back in to a single string, and use that string
      # as the sort criterion, then replace the sort criterion with
      # the rank.
      # NOTE: these are rev and change_ids, not ids.
      my @max_lengths;
      my @ids = ( values %rev_ids ) ;#, values %change_ids );
      for ( @ids ) {
         ## TODO: Store the revision type somewhere and use it instead of
         ## VCP::Rev
         my @segments = VCP::Rev->split_id( $_->[0] );
         $_->[1] = \@segments;
         for ( my $i = 0; $i <= $#segments; ++$i ) {
            my $l = length $segments[$i];
            $max_lengths[$i] = $l
               if ! defined $max_lengths[$i] || $l > $max_lengths[$i];
         }
      }

      # even segments are assumed to be numeric, odd to be alphabetic
      my $seg_num = 0;
      my $fmt = join "",
         map
            $seg_num++ % 2 ? "Z" . ( $_ + 1 ) : "N",
            @max_lengths;

      $_->[1] = pack $fmt, @{$_->[1]}
         for map {
            for ( my $seg_num = 0; $seg_num <= $#max_lengths; ++$seg_num ) {
               for ( $_->[1]->[$seg_num] ) {
                  $_ = $seg_num % 2 ? "\000" : 0
                     if empty $_ ;
               }
            }

            $_;
         } @ids;

      $rank = 0;
      $_->[1] = $rank++ for sort { $a->[1] cmp $b->[1] } @ids;
   }
}

=item pack_format

Returns the pack format for a field.  Only sortable fields are supported.

=cut

sub pack_format {
    "N";  ## All string fields are ranked as above so they're simple ints
          ## and the few other fields (time, mainly) are simeple ints to
          ## begin with.
}

=item index_value_expression

Returns an expression that, given "$_", returns the packable code for a field.
Only sortable fields are supported.

=cut

{
   my %ranked_fields = (
       NAME      => undef,
       COMMENT   => undef,
       REV_ID    => undef,
#       CHANGE_ID => undef,
       USER_ID   => undef,
       BRANCH_ID => undef,
   );

   sub index_value_expression {
      my VCP::Rev $self = shift;
      my ( $field_name ) = @_;

      $field_name = uc $field_name;
      my $meth_name = lc $field_name;

      if ( $field_name eq "TIME" ) {
         return "(\$r->time || \$r->sort_time || 0 )";
      }
      if ( exists $ranked_fields{$field_name} ) {
         return "(\$r->[$field_pos{$field_name}]->[1] || 0)";
      }
      return "\$r->$meth_name || 0";
   }
}


## We never, ever want to delete a file that has revs referring to it.
## So, we put a cleanup object in %files_to_delete and manually manage a
## reference count on it.  The hash is keyed on filename and contains
## a count value.  When the count reaches 0, it is cleaned.  We add a warning
## about undeleted files, which is a great PITA.  The reason there's a
## warning is that we could be using gobs of disk space for temporary files
## if there's some bug preventing VCP::Rev objects from being DESTROYed
## soon enough.  It's a PITA because it means that the source and
## destination object really must be dereferenced ASAP, so their SEEN
## arrays get cleaned up, and every once in awhile I screw it up somehow.
my %files_to_delete ;

END {
   if ( debugging && ! $ENV{VCPNODELETE} ) {
      for ( sort keys %files_to_delete ) {
	 if ( -e $_ ) {
	    pr "$_ not deleted" ;
	 }
      }
   }
}


=item new

Creates an instance, see subclasses for options.

   my VCP::Rev $rev = VCP::Rev->new(
      name => 'foo',
      time => $commit_time,
      ...
   ) ;

=cut

## Autogenerated

=item is_base_rev

Returns TRUE if this is a base revision.  This is the case if no action
is defined.  A base revision is a revision that is being transferred
merely to check it's contents against the destination repository's
contents. Base revisions contain no action and contain a <digest> but no
<delta> or <content>.

When a VCP::Dest::* receives a base revision, the actual body of the
revision is 'backfilled' from the destination repository and checked
against the digest.  This cuts down on transfer size, since the full
body of the file never need be sent with incremental updates.

See L<VCP::Dest/backfill> as well.

=cut

sub is_base_rev {
   my VCP::Rev $self = shift ;

   return ! defined $self->action;
}


=item is_placeholder_rev

Returns TRUE if this is a placeholder revision.  Placeholder revisions
are used to record branch points for files that have not been altered on
their branches.

This occurse when reading CVS repositories and finding files that have
branch tags but no revisions on the branch.

A placeholder revision has an action of "placeholder".

Note that placeholders may have rev_id and change_id fields, but they
may be malformed; they are present for sorting purposes only and should
be ignored by the destination repository.

Placeholders may not be present for branches which have files on them.

=cut

sub is_placeholder_rev {
   my VCP::Rev $self = shift ;

   my $a = $self->action;

   return defined $a && $a eq "placeholder" ;
}


sub previous {
   goto &set_previous if @_ > 1;
   return $_[0]->_previous;
}

sub set_previous {
   my VCP::Rev $self = shift;

   confess "too many parameters passed" if @_ > 1 ;
   my $n = shift;
   $self->_set_previous( $n );
   return;  ## The rest is for debugging infinite loops.

   my %seen = ( int $self => undef );
   my @seen;
   while ( $n ) {
      push @seen, $n;
      confess "\$rev->previous_id loop detected:\n", map "   " . $_->as_string . "\n", @seen
         if exists $seen{int $n};
      $seen{int $n} = undef;
      $n = $n->_previous;
   }
}


=item base_revify

Converts a "normal" rev in to a base rev.

=cut

sub base_revify {
   my VCP::Rev $self = shift ;

   $self->{$_} = undef for qw(
      P4_INFO
      CVS_INFO
      SVN_INFO
      STATE
      TIME
      MOD_TIME
      USER_ID
      LABELS
      COMMENT
      ACTION
   );
}

=item id

Sets/gets the id.  Returns "$name#$rev_id" by default, which should work
for most systems.

=cut

sub id {
   goto &_set_id if @_ > 1;
   my VCP::Rev $self = shift;

   my $id = $self->_id;

   return defined $id
      ? $id
      : $self->name . "#" . $self->source_rev_id;
}


sub set_id {
   goto &_set_id;
}


=item work_path, dest_work_path

These set/get the name of the working file for sources and destinations,
respectively.  These files are automatically cleaned up when all VCP::Rev
instances that refer to them are DESTROYED or have their work_path or
dest_work_path set to other files or undef.

=cut

sub _change_work_path {
   my VCP::Rev $self = shift ;

   my ( $old_fn, $new_fn ) = @_ ;

   if ( defined $old_fn
      && $files_to_delete{$old_fn}
      && --$files_to_delete{$old_fn} < 1
      && -e $old_fn
   ) {
      if ( debugging ) {
         my @details ;
	 my $i = 2 ;
	 do { @details = caller($i++) } until $details[0] ne __PACKAGE__ ;
	 debug "$self unlinking '$old_fn' in "
	    . join( '|', @details[0,1,2,3]) ;
      }
      unlink $old_fn or pr "$! unlinking $old_fn\n"
         unless $ENV{VCPNODELETE};
   }

   ++$files_to_delete{$new_fn} unless empty $new_fn;
}


sub work_path {
   goto &set_work_path if @_ > 1;
   return $_[0]->_work_path;
}


sub set_work_path {
   my VCP::Rev $self = shift ;
   confess "too many parameters passed" if @_ > 1 ;
   my ( $new_fn ) = @_;
   $self->_change_work_path( $self->_work_path, $new_fn ) if @_ ;
   $self->_work_path( $new_fn );
}


sub dest_work_path {
   goto &set_dest_work_path if @_ > 1;
   return $_[0]->_dest_work_path;
}


sub set_dest_work_path {
   my VCP::Rev $self = shift ;
   confess "too many parameters passed" if @_ > 1 ;
   my ( $new_fn ) = @_;
   $self->_change_work_path( $self->_dest_work_path, $new_fn ) if @_ ;
   $self->_dest_work_path( $new_fn );
}


=item labels

   $r->set_labels( \@labels ) ;  ## pass an array ref for speed
   @labels = $r->labels ;

Sets/gets labels associated with a revision.  If a label is applied multiple
times, it will only be returned once.  This feature means that the automatic
label generation code for r_... revision and ch_... change labels won't add
additional copies of labels that were already applied to this revision in the
source repository.

Returns labels in an unpredictible order, which happens to be sorted for
now.  This sorting is purely for logging purposes and may disappear at
any moment.

=item add_label

  $r->add_label( $label ) ;
  $r->add_label( @labels ) ;

Marks one or more labels as being associated with this revision of a file.

=cut

sub add_label {
   my VCP::Rev $self = shift ;
   $self->set_labels( [ $self->labels, @_ ] );
   return ;
}


sub _branch_id {
    my VCP::Rev $self = shift;

    for ( $self->branch_id ) {
        return "" if empty $_;
        return "($_)";
    }
}


sub _name_branch_id {
    my VCP::Rev $self = shift;

    $self->name . $self->_branch_id;
}

=item iso8601format

   VCP::Rev::iso8601format( $time );

Takes a seconds-since-the-epoch time value and converts it to
an ISO8601 formatted date.  Exportable:

   use VCP::Rev qw( iso8601format );

=cut

sub iso8601format {
   die "time parameter missing" unless @_;
   my @f = reverse( (gmtime shift)[0..5] ) ;
   $f[0] += 1900 ;
   $f[1] ++ ; ## Month of year needs to be 1..12
   return sprintf( "%04d-%02d-%02d %02d:%02d:%02dZ", @f ) ;
}


=item as_string

Prints out a string representation of the name, rev_id, change_id, type,
time, and a bit of the comment.  base revisions are flagged as such (and
don't have fields like time and comment).

=cut

sub as_string {
   my VCP::Rev $self = shift ;

   my @v = map(
      defined $_ ? $_ : "<undef>",
      map(
         $_ eq 'time' && defined $self->$_()
             ? iso8601format $self->$_()
         : $_ eq 'comment' && defined $self->$_()
             ? do {
                my $c = $self->$_();
                $c =~ s/\n/\\n/g;
                $c =~ s/\r/\\r/g;
                $c =~ s/\t/\\t/g;
                $c =~ s/\l/\\l/g;
                $c = substr( $c, 0, 32 )
                   if length( $c ) > 32;
                $c;
             }
         : $_ eq 'action' && defined $self->$_()
             ? sprintf "%-6s", $self->$_() # 6 == length "delete"
             : $self->$_(),
         (
            qw( name _branch_id rev_id change_id type ),
            $self->is_base_rev || $self->is_placeholder_rev
               ? qw( time user_id )
               : qw( action time user_id comment )
         )
      )
   ) ;

   return
      $self->is_base_rev
         ? sprintf( qq{%s%s#%s @%s (%s) -- base rev --}, @v )
      : $self->is_placeholder_rev
         ? sprintf( qq{%s%s#%s @%s (%s) %s -- %s -- placeholder rev --}, @v )
         : sprintf( qq{%s%s#%s @%s (%s) %s %s %s "%s"}, @v ) ;
}

sub DESTROY {
   return if $ENV{VCPNODELETE};
   my VCP::Rev $self = shift ;
   my $doomed = $self->_work_path ;
   $self->set_work_path( undef ) if defined $doomed;
   $self->set_dest_work_path( undef ) if defined $self->_dest_work_path;
   if ( defined $doomed && -e $doomed ) {
      debug "$self unlinking '$doomed'" if debugging;
      unlink $doomed or pr "$! unlinking $doomed\n";
   }
}


=back

=head1 SUBCLASSING

This class uses the fields pragma, so you'll need to use base and 
possibly fields in any subclasses.

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1

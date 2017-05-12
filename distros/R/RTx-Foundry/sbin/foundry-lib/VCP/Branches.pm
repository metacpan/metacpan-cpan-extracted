package VCP::Branches ;

=head1 NAME

VCP::Branches - A collection of VCP::Rev objects.

=head1 SYNOPSIS

=head1 DESCRIPTION

Right now, all branches are kept in memory, but we will enable storing them to
disk and recovering them at some point so that we don't gobble huge
tracts of RAM.

=head1 METHODS

=over

=cut

$VERSION = 1 ;

use strict ;

use Carp ;
use VCP::Debug ":debug" ;
use VCP::Rev ;

use fields (
   'BRANCHES',        ## The branches, sorted or not
   'SEEN',            ## Oh, the branches we've seen
) ;


=item new

=cut

sub new {
   my $class = CORE::shift ;
   $class = ref $class || $class ;

   my $self ;

   {
      no strict 'refs' ;
      $self = bless [ \%{"$class\::FIELDS"} ], $class ;
   }

   $self->{BRANCHES} = [] ;
   $self->{SEEN} = {} ;

   return $self ;
}


=item add

   $branches->add( $branch ) ;
   $branches->add( $branch1, $branch2, ... ) ;

Adds a branch or branches to the collection, unless they are already present.

=cut

sub add {
   my VCP::Branches $self = CORE::shift ;

   for my $b ( @_ ) {
      my $key = $b->branch_id;
      next
         if $self->{SEEN}->{$key} ;

      debug "queuing ", $b->as_string if debugging;

      $self->{SEEN}->{$key} = 1 ;
      push @{$self->{BRANCHES}}, $b ;
   }
}


=item get

   @branches = $branches->get ;

Gets the list of branches in alphabetical order.

=cut

sub get {
   my VCP::Branches $self = CORE::shift ;

   # the @b is to work around a bug that seems to happen in perl5.6.1:
   # sort() called in a scalar context doesn't return TRUE, not sure
   # why.
   my @b = sort { $a->branch_id cmp $b->branch_id } @{$self->{BRANCHES}} ;
   return @b;
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

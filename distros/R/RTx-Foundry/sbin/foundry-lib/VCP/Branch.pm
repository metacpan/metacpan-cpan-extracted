package VCP::Branch ;

=head1 NAME

VCP::Branch - VCP's concept of a branch.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

$VERSION = 1 ;

use strict ;

use Carp ;
use VCP::Debug ':debug' ;
use vars qw( %FIELDS ) ;

use fields (
## BranchML fields:
   'BRANCH_ID',  ## The tag or path-to-branch from the source
   'DEST_BRANCH_ID',    ## The tag or path-to-branch to be written to
   'P4_BRANCH_SPEC',    ## The branch spec from the source repo if it
                        ## Happens to be p4.
) ;

BEGIN {
   ## Define accessors.
   for ( keys %FIELDS ) {
#      next if $_ eq 'WORK_PATH' ;
#      next if $_ eq 'DEST_WORK_PATH' ;
      my $f = lc( $_ ) ;
#      if ( $f eq 'labels' ) {
#	 eval qq{
#	    sub $f {
#	       my VCP::Branch \$self = shift ;
#	       if ( \@_ ) {
#	          \$self->{$_} = {} ;
#		  \@{\$self->{$_}}{\@_} = (undef) x \@_ ;
#	       }
#	       return \$self->{$_} ? sort keys \%{\$self->{$_}} : () ;
#	    }
#	 } ;
#      }
#      else {
	 eval qq{
	    sub $f {
	       my VCP::Branch \$self = shift ;
	       confess "too many parameters passed" if \@_ > 1 ;
	       \$self->{$_} = shift if \@_ == 1 ;
	       return \$self->{$_} ;
	    }
	 } ;
#      }
      die $@ if $@ ;
   }
}


=item new

Creates an instance, see subclasses for options.

   my VCP::Branch $branch = VCP::Branch->new(
      branch_id => 'foo',
      dest_branch_id   => 'bar',
      ...
   ) ;

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Branch $self ;

   {
      no strict 'refs' ;
      $self = bless [ \%{"$class\::FIELDS"} ], $class ;
   }

   while ( @_ ) {
      my $key = shift ;
      $self->{uc($key)} = shift ;
   }

   return $self ;
}


sub as_string {
   my VCP::Branch $self = shift ;

   my @v = map(
      defined $_ ? $_ : "<undef>",
	 map $self->$_(), qw( branch_id dest_branch_id )
   ) ;

   return sprintf( qq{branch %s => %s}, @v )
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

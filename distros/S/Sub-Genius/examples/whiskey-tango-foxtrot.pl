#!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';

use Sub::Genius ();

my $plan = q{
# Plan Summary:
#                                           (note: all comments and empty lines are removed prior to parsing)
#  'init' is called first, then 4 out of
#  potentially 8 are called; uses
#  the "union" RE operator, i.e., "or");
#  then 'fin' is called last

  init                       # always first
  (
    (alpha   | foxtrot)  &   # L1  - 'alpha'   or 'foxtrot'
    (whiskey | delta)    &   # L2  - 'whiskey' or 'delta'
    (bravo   | charlie)  &   # L3  - 'bravo'   or 'charlie'
    (tango   | zulu)         # L4  - 'tango'   or 'zulu'       (no '&' since it's last in the chain)
  )
  fin                        # always last
};

## intialize hash ref as container for global memory
my $GLOBAL = {};


## initialize Sub::Genius
my $sq = Sub::Genius->new(preplan => $plan );
$sq->init_plan;
my $final_scope = $sq->run_once( scope => {}, ns => q{main}, verbose => 1);


 
              ##########
             ############ 
#    |      ##############
#CCC##|#Subroutines>>>####
#    |      ##############
             ############
              ##########

sub init {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub init: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub fin {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub fin: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub alpha {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub alpha: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub foxtrot {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub foxtrot: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub whiskey {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub whiskey: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub delta {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub delta: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub bravo {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub bravo: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub charlie {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub charlie: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub tango {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub tango: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

sub zulu {
  my $scope      = shift;    # execution context passed by Sub::Genius::run_once
  state $mystate = {};       # sticks around on subsequent calls
  my    $myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub zulu: ELOH! Replace me, I am just placeholder!\n};
  
  # return $scope, which will be passed to next subroutine
  return $scope;
}

exit;
__END__

=head1 NAME

nameMe -

=head1 SYNAPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item * C<init>

=item * C<fin>

=item * C<alpha>

=item * C<foxtrot>

=item * C<whiskey>

=item * C<delta>

=item * C<bravo>

=item * C<charlie>

=item * C<tango>

=item * C<zulu>

=back

=head1 SEE ALSO

L<Sub::Genius>

=head1 COPYRIGHT AND LICENSE

Same terms as perl itself.

=head1 AUTHOR

Rosie Tay Robert E<lt>???@??.????<gt>


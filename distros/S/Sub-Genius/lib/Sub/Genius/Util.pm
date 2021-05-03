package Sub::Genius::Util;

use strict;
use warnings;

use parent q{Sub::Genius};

# dispatch for invocation method
my $invocation = {
  once => \&_as_once,    # invoke plan with run_once
   any => \&_as_any,     # invoke plan with run_any
   all => \&_as_all,     # invoke plan with loop using `next` + run_once
};

sub _as_once {
  return qq{
## initialize Sub::Genius
my \$sq = Sub::Genius->new(preplan => qq{\$pre} );
\$sq->init_plan;
my \$final_scope = \$sq->run_once( scope => {}, ns => q{main}, verbose => 1);};
}

sub _as_any {
  return qq{
## initialize Sub::Genius
my \$final_state = Sub::Genius->new(preplan => qq{\$pre})->run_any( scope => {}, ns => q{main}, verbose => 1);};
}

sub _as_all {
  return qq/
## initialize Sub::Genius
my \$sq = Sub::Genius->new(preplan => qq{\$pre} );
\$sq->init_plan;
do {
  my \$final_scope = \$sq->run_once( scope => {}, ns => q{main}, verbose => 1);
}
while (\$sq->next);
/
}

sub subs2perl {
    my ( $self, %opts ) = @_;
    my @subs       = ();
    my @pre_tokens = ();
    my @perlsubpod = ();

    # make sure subs are not repeated
    my %uniq = ();
    foreach my $sub (@{$opts{subs}}) {
      ++$uniq{$sub};
    } 
    foreach my $sub (keys %uniq) {
      push @subs, $sub;
      push @pre_tokens, $sub;
      push @perlsubpod, qq{=item * C<$sub>\n};
    } 

    my $perlsub    = $self->_dump_subs(\@subs);
    my $perlpre    = join(qq{\n}, @pre_tokens);
    my $perlsubpod = join(qq{\n}, @perlsubpod);
    my $invokemeth = $invocation->{$opts{q{with-run}}}->();

    my $perl = qq{
#!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';

use Sub::Genius ();

# vvv---- PRE - #xxxx NOT COMPLETE, NEED TO MANUALLY ADD PARALLEL SEMANTIC
my \$pre = q{
$perlpre
};
# ^^^---- PRE - #xxxx NOT COMPLETE, NEED TO MANUALLY ADD PARALLEL SEMANTIC

## intialize hash ref as container for global memory
my \$GLOBAL = {};

$invokemeth

$perlsub
exit;
__END__

=head1 NAME

nameMe -

=head1 SYNAPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

$perlsubpod
=back

=head1 SEE ALSO

L<Sub::Genius>

=head1 COPYRIGHT AND LICENSE

Same terms as perl itself.

=head1 AUTHOR

Rosie Tay Robert E<lt>???@??.????<gt>

};

    return $perl;
}

sub _dump_subs {
    my ( $self, $symbols ) = @_;

    my $perl = q{
 
              ##########
             ############ 
#    |      ##############
#CCC##|#Subroutines>>>####
#    |      ##############
             ############
              ##########
};

    foreach my $sub (@$symbols) {
        $perl .= qq/
sub $sub {
  my \$scope      = shift;    # execution context passed by Sub::Genius::run_once
  state \$mystate = {};       # sticks around on subsequent calls
  my    \$myprivs = {};       # reaped when execution is out of sub scope
   
  #-- begin subroutine implementation here --#
  print qq{Sub $sub: ELOH! Replace me, I am just placeholder!\\n};
  
  # return \$scope, which will be passed to next subroutine
  return \$scope;
}
/;
    }
    return $perl;
}

#
# ####
#

sub plan2noSS {
    my ( $self, %opts ) = @_;
    my $SS = $self->new(%opts);

    my $pre = $SS->pre;

    my $perl = qq{
use strict;
use warnings;
use feature 'state';

## intialize hash ref as container for global memory
my \$GLOBAL = {};
my \$scope  = { thing => 0, };

# Sub::Genius is not used, but this call list has been generated
# using Sub::Genius::Util::plan2noSS,
#
#  perl -MSub::Genius::Util -e 'print Sub::Genius::Util->plan2noSS(plan => q{$pre})'
#
};

    my @symbols = $SS->{_regex}->as_pfa->as_nfa->as_dfa->alphabet;
    foreach my $sub (@symbols) {
        $perl .= qq{\$scope = $sub(\$scope);\n};
    }

    $perl .= $self->_dump_subs( \@symbols );

    return $perl;
}

1;

=head1 NAME

Sub::Genius::Util - assortment of utility methods that might make
dealing with creating programs using <Sub::Genius> a little more
convenient.

=head1 SYNOPSIS

As a one-liner,

    $ perl -MSub::Genius::Util -e 'print plan2perl("A&B&C&D")' > my-script.pl

In a script;

    use Sub::Genius::Util ();
    open my $fh, q{>}, q{./my-script.pl} or die $!;
    print $fh Sub::Genius::Util->plan2perl(plan => 'A&B&C&D');

=head1 DESCRIPTION

Useful for dumping a Perl code for starting a module or script that implements
the subroutines that are involved in the execution of a C<plan>. 

Given a PRE, dumps a Perl script with the subroutines implied by the symbols
in the PREs as subroutines. It might be most effective when called as a one
liner,

    $ perl -MSub::Genius::Util -e 'print Sub::Genius::Util->plan2perl(plan => q{A&B&C&D})' > my-script.pl
     
This could get unweildy if you have a concurrent model in place, but anyone
reviewing this POD should be able to figure out the best way to leverage C<plan2perl>.

Each subroutine takes the approximate form,

    sub C {
      my $scope      = shift;    # execution context passed by Sub::Genius::run_once
      state $mystate = {};       # sticks around on subsequent calls
      my    $myprivs = {};       # reaped when execution is out of sub scope
    
      #-- begin subroutine implementation here --#
      print qq{Sub C: ELOH! Replace me, I am just placeholder!\n};
    
      # return $scope, which will be passed to next subroutine
      return $scope;
    }

=head1 METHODS

C<subs2perl>

Implemented to support the accompanying utility used for initialing a script with
L<Sub::Genius>.

C<plan2noSS>

Given a PRE, dumps a Perl script that can be run without loading L<Sub::Genius>
by providing explicit calls, that also pass along a C<$scope> variable.

    $ perl -MSub::Genius::Util -e 'print Sub::Genius::Util->plan2noSS(plan => q{A&B&C&D&E&F&G})' > my-script.pl
    
    # does explicitly what Sub::Genius::run_once does, give a sequentialized plan
    # generated from the PRE, 'A&B&C&D&E&F&G'
    
    my $scope = { };
    $scope    = G($scope);
    $scope    = D($scope);
    $scope    = F($scope);
    $scope    = B($scope);
    $scope    = E($scope);
    $scope    = H($scope);
    $scope    = C($scope);
    $scope    = A($scope);

=head1 SEE ALSO

L<Sub::Genius>

=head1 COPYRIGHT AND LICENSE

Same terms as perl itself.

=head1 AUTHOR

OODLER 577 E<lt>oodler@cpan.orgE<gt>


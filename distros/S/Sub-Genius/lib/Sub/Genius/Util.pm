package Sub::Genius::Util;

use strict;
use warnings;

use parent q{Sub::Genius};

# dispatch for invocation method
my $invocation = {
    any  => \&_as_any,     # invoke plan with run_any
    all  => \&_as_all,     # invoke plan with loop using `next` + run_once
    once => \&_as_once,    # invoke plan without dependency on Sub::Genius
};

sub _as_once {
    return qq{
 ## initialize Sub::Genius (caching 'on' by default)
 my \$sq = Sub::Genius->new(preplan => qq{\$preplan} );
 \$sq->init_plan;
 my \$final_scope = \$sq->run_once( scope => {}, ns => q{main}, verbose => 1);};
}

sub _as_any {
    return qq{
 ## initialize Sub::Genius (caching 'on' by default)
 my \$final_state = Sub::Genius->new(preplan => qq{\$preplan})->run_any( scope => {}, ns => q{main}, verbose => 1);};
}

sub _as_all {
    return qq/
 ## initialize Sub::Genius (caching 'on' by default)
 my \$sq = Sub::Genius->new(preplan => qq{\$preplan} );
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
    foreach my $sub ( @{ $opts{subs} } ) {
        ++$uniq{$sub};
    }

  SUBS:
    foreach my $sub ( keys %uniq ) {
        next SUBS if $sub =~ m/^ *$/;
        push @subs,       $sub;
        push @pre_tokens, $sub;
        push @perlsubpod, qq{ =item * C<$sub>\n};
    }

    my $perlsub    = $self->_dump_subs( \@subs );
    my $perlpre    = join( qq{\n}, @pre_tokens );
    my $perlsubpod = join( qq{\n}, @perlsubpod );
    my $invokemeth = $invocation->{ $opts{q{with-run}} }->();

    my $perl = qq{#!/usr/bin/env perl
 use strict;
 use warnings;
 use feature 'state';

 use Sub::Genius ();

 my \$preplan = q{
 # TODO - add concurrent semantics (e.g., '&', etc)
 # [note: this comment is ignored by S::G]
$perlpre
 };

 ## intialize hash ref as container for global memory
 my \$GLOBAL = {};
 
$invokemeth

$perlsub
 exit;
 __END__

 =head1 NAME

 nameMe - something click bait worthy for CPAN

 =head1 SYNAPSIS

 ..pithy example of use

 =head1 DESCRIPTION

 ..extended wordings on what this thing does

 =head1 METHODS

 =over 4

$perlsubpod
 =back

 =head1 SEE ALSO

 L<Sub::Genius>, L<FLAT>

 =head1 COPYRIGHT AND LICENSE

 Same terms as perl itself.

 =head1 AUTHOR

 Rosie Tay Robert E<lt>rtr\@example.tldE<gt>
};
    $perl =~ s/^ //gm;
    return $perl;
}

sub _dump_subs {
    my ( $self, $subs ) = @_;

    my $perl = q{
 #
 # S U B R O U T I N E S
 #
};

    foreach my $sub (@$subs) {
        $perl .= qq/
 #TODO - implement the logic!
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

sub plan2nodeps {
    my ( $self, %opts ) = @_;
    my $sq = $self->new(%opts);

    my $preplan = $sq->preplan;

    my $perl = qq{ #!/usr/bin/env perl

 # Sub::Genius is not used, but this call list has been generated
 # using Sub::Genius::Util::plan2nodeps,
 #
 #  perl -MSub::Genius::Util -e 'print Sub::Genius::Util->plan2nodeps(preplan => q{$preplan})'
 use strict;
 use warnings;
 use feature 'state';

 ## intialize hash ref as container for global memory
# The following sequence of calls is consistent with the original preplan,
#
## ~> $preplan
#

 my \$GLOBAL = {};
 my \$scope  = { thing => 0, };
};

    # init (compiles to DFA)
    $sq->init_plan;

    # gets serialized execution plan
    my @subs = split / /, $sq->next;

    # generate shot callers, 50" blades on the empala's
    foreach my $sub (@subs) {
        $perl .= qq{\$scope = $sub(\$scope);\n};
    }

    # get uniq list of subs for sub stub generation
    my %uniq = map { $_ => 1 } @subs;

    $perl .= $self->_dump_subs( [ keys %uniq ] );

    $perl =~ s/^ //gm;

    return $perl;
}

sub precache {
    my ( $self, %opts ) = @_;

    die qq{'preplan' and 'prefile' are mutually exclusive\n} if ( $opts{preplan} and $opts{prefile} );

    # clean %opts, otherwise Sub::Genius will disable caching
    # the others are safely ignored
    delete $opts{cachedir} if not defined $opts{cachedir};

    if ( defined $opts{prefile} ) {
        local $/ = undef;
        open my $ph, q{<}, $opts{prefile} || die $!;
        $opts{preplan} = <$ph>;
        close $ph;
    }
    my $sq = $self->new(%opts)->init_plan;
    return $sq;
}

1;

=head1 NAME

Sub::Genius::Util - Helper module for dumping Perl code

=head1 SYNOPSIS

This is implemented for use with L<stubby>, please look at that script
to see how it's used. This module is lightly documented, to say the least.

=head1 DESCRIPTION

Useful for dumping a Perl code for starting a module or script that
implements the subroutines that are involved in the execution of a C<plan>.

Given a PRE, dumps a Perl script with the subroutines implied by the
symbols in the PREs as subroutines. It might be most effective when called
as a one liner,

This could get unweildy if you have a concurrent model in place, but
anyone reviewing this POD should be able to figure out the best way to
leverage C<plan2perl>.

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

C<plan2nodeps>

Given a PRE, dumps a Perl script that can be run without loading L<Sub::Genius>
by providing explicit calls, that also pass along a C<$scope> variable.

    $ perl -MSub::Genius::Util -e 'print Sub::Genius::Util->plan2nodeps(plan => q{A&B&C&D&E&F&G})' > my-script.pl
    
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

C<precache>

Accepts various parameters for invoking L<Sub::Genius>'s caching feature
and options. Returns a necessarily initialized Sub::Genius instance. Since
this uses Sub::Genius' native handling of caching, the PRE will not be
repeatedly cached unless forced. 

=head1 SEE ALSO

L<Sub::Genius>

=head1 COPYRIGHT AND LICENSE

Same terms as perl itself.

=head1 AUTHOR

OODLER 577 E<lt>oodler@cpan.orgE<gt>


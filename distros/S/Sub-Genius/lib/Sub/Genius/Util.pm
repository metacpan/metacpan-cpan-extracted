package Sub::Genius::Util;

use strict;
use warnings;

use parent q{Sub::Genius};
use Util::H2O::More qw/ddd/;

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

sub export_as {
    my ( $self, %opts ) = @_;

    die qq{'preplan' and 'prefile' are mutually exclusive\n} if ( $opts{preplan} and $opts{prefile} );

    if ( defined $opts{prefile} ) {
        local $/ = undef;
        open my $ph, q{<}, $opts{prefile} || die $!;
        $opts{preplan} = <$ph>;
        close $ph;
    }

    my $sq = $self->new(%opts);
    $sq->init_plan;
    print $sq->dfa->as_graphviz; # this is a minimal DFA

    return;
}

sub list {
    my ( $self, %opts ) = @_;

    die qq{'preplan' and 'prefile' are mutually exclusive\n} if ( $opts{preplan} and $opts{prefile} );

    if ( defined $opts{prefile} ) {
        local $/ = undef;
        open my $ph, q{<}, $opts{prefile} || die $!;
        $opts{preplan} = <$ph>;
        close $ph;
    }

    my $sq = $self->new(%opts);
    $sq->init_plan;

    while (my $preplan = $sq->next) {
      print qq{$preplan\n};
    }

    return;
}

sub subs2perl {
    my ( $self, %opts ) = @_;

    die qq{'preplan' and 'prefile' are mutually exclusive\n} if ( $opts{preplan} and $opts{prefile} );

    if ( defined $opts{prefile} ) {
        local $/ = undef;
        open my $ph, q{<}, $opts{prefile} || die $!;
        $opts{preplan} = <$ph>;
        close $ph;
    }

    # PRE is parsed, but not converted to validate it
    my $sq = $self->new(%opts);

    my @subs       = split /[^\w]/, $opts{preplan};
    my @pre_tokens = ();
    my @perlsubpod = ();

    # make sure subs are not repeated
    my %uniq = ();
    foreach my $sub ( @subs ) {
        ++$uniq{$sub};
    }
    delete $uniq{q{}} if $uniq{q{}};

    @subs          = ();
  SUBS:
    foreach my $sub ( keys %uniq ) {
        push @subs,       $sub;
        push @pre_tokens, $sub;
        push @perlsubpod, qq{ =item * C<$sub>\n};
    }

    my $perlsub    = $self->_dump_subs( \@subs );

    my $perlpre    = $opts{preplan};
    $perlpre =~ s/\n$//;
    $perlpre =~ s/^/  /gm; 
    my $perlsubpod = join( qq{\n}, @perlsubpod );
    my $invokemeth = $invocation->{ $opts{q{with-run}} }->();

    my $perl = qq{#!/usr/bin/env perl
 use strict;
 use warnings;
 use feature 'state';

 use Sub::Genius ();

 my \$preplan = q{
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

  DUMPSUBS:
    foreach my $sub (@$subs) {
      if ($sub =~ m/::/g) { 
        warn qq{'$sub' appears to be a call to a fully qualified method from an external package. Skipping subroutine stub...\n};
        next DUMPSUBS;
      }
        $perl .= qq/
 #TODO - implement the logic!
 sub $sub {
   my    \$scope   = shift;    # execution context passed by Sub::Genius::run_once
   my    \$private = {};       # private variable hash, reaped when execution is out of sub scope
   state \$mystate = {};       # gives subroutine state from call to call
 
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

    die qq{'preplan' and 'prefile' are mutually exclusive\n} if ( $opts{preplan} and $opts{prefile} );

    if ( defined $opts{prefile} ) {
        local $/ = undef;
        open my $ph, q{<}, $opts{prefile} || die $!;
        $opts{preplan} = <$ph>;
        close $ph;
    }
 
    my $sq = $self->new(%opts);

    my $preplan = $sq->original_preplan;
    $preplan =~ s/^/#   /gm;
    $preplan =~ s/\n$//g;

    my $perl = qq{ #!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';

# Sub::Genius is not used, but this call list has been generated
# using Sub::Genius::Util::plan2nodeps,
# 
## intialize hash ref as container for global memory
# The following sequence of calls is consistent with the original preplan,
# my \$preplan = q{
$preplan
# };

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

    delete $uniq{q{}} if $uniq{q{}};

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

=encoding UTF-8

=head1 NAME

Sub::Genius::Util - Utilities for generating and inspecting Perl code from Sub::Genius plans

=head1 SYNOPSIS

    use Sub::Genius::Util;

    # Generate a standalone Perl script from a plan
    print Sub::Genius::Util->plan2nodeps(
        plan => q{ A & B & C }
    );

This module is primarily intended for use by tooling such as
L<stubby>, but its methods may also be invoked directly when exploring,
debugging, or materializing Sub::Genius plans.

=head1 DESCRIPTION

C<Sub::Genius::Util> provides helper routines that operate I<on top of>
L<Sub::Genius> to make execution plans concrete and inspectable.

Where C<Sub::Genius> focuses on expressing and executing concurrency
semantics, this module focuses on:

=over 4

=item *
Generating Perl code from declarative plans

=item *
Materializing execution order explicitly

=item *
Bootstrapping scripts or modules from plans

=item *
Eliminating runtime dependency on Sub::Genius when desired

=back

The utilities in this module are most commonly used during development,
experimentation, or build-time code generation, rather than in
long-running production systems.

=head2 Generated Subroutine Shape

When generating Perl code that corresponds to plan symbols, each
subroutine is emitted with a conventional structure compatible with
C<Sub::Genius::run_once>:

    sub C {
      my $scope      = shift;    # execution context
      state $mystate = {};       # persistent state (coroutine-style)
      my    $myprivs = {};       # lexical scratch space

      # --- implementation goes here ---
      print qq{Sub C: placeholder\n};

      return $scope;
    }

This reflects the core Sub::Genius execution model, where a mutable
C<$scope> hash reference is threaded through the execution plan.

=head1 METHODS

=head2 subs2perl

    Sub::Genius::Util->subs2perl(...);

Generates Perl subroutine stubs corresponding to the symbols implied by
a plan.

This method exists to support tooling that initializes scripts or
modules intended to be executed under Sub::Genius. The generated code
is a starting point and is expected to be edited by hand.

=head2 plan2nodeps

    Sub::Genius::Util->plan2nodeps( plan => $pre );

Given a PRE, generates a standalone Perl script that explicitly encodes
the execution order implied by the plan.

The resulting script:

=over 4

=item *
Does not depend on L<Sub::Genius> at runtime

=item *
Contains explicit subroutine calls

=item *
Passes a C<$scope> variable between calls

=back

Example:

    perl -MSub::Genius::Util \
         -e 'print Sub::Genius::Util->plan2nodeps(
               plan => q{A&B&C&D}
             )' > my-script.pl

This produces code equivalent to what
C<Sub::Genius::run_once> would execute dynamically, but fully spelled
out:

    my $scope = {};
    $scope = C($scope);
    $scope = A($scope);
    $scope = D($scope);
    $scope = B($scope);
    $scope = E($scope);

The exact order depends on the chosen valid serialization.

=head2 precache

    my $sg = Sub::Genius::Util->precache(%opts);

Invokes Sub::Genius caching facilities and returns an initialized
C<Sub::Genius> instance.

This method centralizes cache-related setup and ensures that PREs are
compiled only once unless explicitly forced. It is primarily intended
for build-time or tooling workflows.

=head1 DESIGN NOTES

This module is intentionally narrow in scope.

It does not attempt to abstract away the mechanics of Sub::Genius or hide
how execution plans are linearized. Instead, it aims to make those
mechanics explicit and inspectable.

If you find yourself calling these utilities repeatedly at runtime, it
is worth reconsidering whether code generation is the appropriate tool
for that use case.

=head1 SEE ALSO

L<Sub::Genius>,
L<Sub::Genius::Example>,
L<stubby>

=head1 COPYRIGHT AND LICENSE

Same terms as Perl itself.

=head1 AUTHOR

OODLER 577 E<lt>oodler@cpan.orgE<gt>

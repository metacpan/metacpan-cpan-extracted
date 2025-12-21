package Sub::Genius;

use strict;
use warnings;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use Digest::MD5 ();
use Storable    ();
use Cwd         ();

our $VERSION = q{0.314006};

sub new {
    my $pkg  = shift;
    my %self = @_;
    my $self = \%self;
    bless $self, $pkg;
    die qq{'preplan' parameter required!\n} if not defined $self->{preplan};

    # set to undef to disable preprocessing
    if ( not exists $self->{preprocess} ) {
        $self->{preprocess} = 1;
    }

    # set to undef to disable caching
    if ( not exists $self->{cachedir} ) {
        $self->cachedir( sprintf( qq{%s/%s}, Cwd::cwd(), q{_Sub::Genius} ) );
    }

    # keep a historical record
    $self->original_preplan($self->preplan);

    # 'pre-process' plan - this step maximizes the chance of capturing
    # the same checksum for identical PREs that may just be formatted differently
    if ( $self->{preprocess} ) {
        $self->_trim;
        $self->_balkanize;
        $self->_normalize;
    }

    # generates checksum based on post-preprocessed form
    $self->checksum( Digest::MD5::md5_hex( $self->preplan ) );

    $self->pregex( FLAT::Regex::WithExtraOps->new( $self->preplan ) );
    return $self;
}

sub cachefile {
    my $self = shift;
    return ( $self->cachedir ) ? sprintf( qq{%s/%s}, $self->cachedir, $self->checksum ) : undef;
}

sub cachedir {
    my ( $self, $dir ) = @_;
    if ($dir) {
        $self->{cachedir} = $dir;
        if ( not -d $self->{cachedir} ) {
            mkdir $self->{cachedir}, 0700 || die $!;
        }
    }
    return $self->{cachedir};
}

sub checksum {
    my ( $self, $sum ) = @_;
    if ($sum) {
        $self->{checksum} = $sum;
    }
    return $self->{checksum};
}

sub do_cache {
    my $self = shift;
    return ( $self->cachedir and $self->checksum and $self->cachefile );
}

# strips comments and empty lines
sub _trim {
    my $self = shift;
    my $_pre = q{};
    my @pre  = ();
  STRIP:
    foreach my $line ( split /\n/, $self->{preplan} ) {
        next STRIP if ( $line =~ m/^\s*#|^\s*$/ );
        my @line = split /\s*#/, $line;
        push @pre, $line[0];
    }
    $self->preplan( join qq{\n}, @pre );
    return $self->preplan;
}

sub _balkanize {
    my $self = shift;
    if ( $self->{preplan} =~ m/[#\[\]]+/ ) {
        die qq{plan to be bracketized must not contain '#', '[', or ']'};
    }
    my $_pre = q{};
    my @pre  = ();
  STRIP:
    foreach my $line ( split /\n/, $self->{preplan} ) {

        # supports strings with namespace delim, '::'
        $line =~ s/([a-zA-Z:_\d]+)/\[$1\]/g;
        push @pre, $line;
    }
    $self->preplan( join qq{\n}, @pre );
    return $self->preplan;
}

# currently, removes all spaces and newlines
sub _normalize {
    my $self     = shift;
    my @pre      = split /\n/, $self->{preplan};
    my $minified = join qq{}, @pre;
    $minified =~ s/[\s]+//g;
    $self->preplan($minified);
    return $self->preplan;
}

# accessor for original plan
sub original_preplan {
    my ( $self, $pp ) = @_;
    if ($pp) {
        $self->{original_preplan} = $pp;
    }
    return $self->{original_preplan};
}

# accessor for original plan
sub preplan {
    my ( $self, $pp ) = @_;
    if ($pp) {
        $self->{preplan} = $pp;
    }
    return $self->{preplan};
}

# accessor for original
sub pregex {
    my ( $self, $pregex ) = @_;
    if ($pregex) {
        $self->{pregex} = $pregex;
    }
    return $self->{pregex};
}

# set/updated whenever ->next() and friends are called, simple way to
# query what plan was last created; RO, not destructive on current 'plan'
sub plan {
    my $self = shift;
    return $self->{plan};
}

# setter/getter for DFA
sub dfa {
    my ( $self, $dfa ) = @_;
    if ($dfa) {
        $self->{DFA} = $dfa;
    }
    return $self->{DFA};
}

# Converts plan -> PFA -> NFA -> DFA:
# NOTE: plan is not generated here, much call ->next()
#  can pass param to underlying ->dfa also, like 'reset => 1'
sub init_plan {
    my ( $self, %opts ) = @_;

    # requires plan (duh)
    die qq{Need to call 'new' with 'preplan => q{PRE...}' to initialize\n} if not $self->pregex;

    # convert PRE to DFA
    $self->convert_pregex_to_dfa(%opts);

    # warn if DFA is not acyclic (infinite strings accepted)
    if ( $self->dfa->is_infinite ) {
        if ( not $self->{'allow-infinite'} ) {
            warn qq{(fatal) Infinite language detected. To avoid, do not use Kleene Star (*).\n};
            die qq{  pass in 'allow-infinite => 1' to constructor to disable this warning.\n};
        }
    }

    # else - currently no meaningful way to control 'infinite' languages, this needs to
    # be investigated

    # returns $self, for chaining in __PACKAGE__->run_any
    return $self;
}

# to force a reset, pass in, C<reset => 1>.; this makes a lot of cool things
sub convert_pregex_to_dfa {
    my ( $self, %opts ) = @_;

    # look for cached DFA
    if ( not $self->{reset} and $self->do_cache ) {
        if ( -e $self->cachefile ) {
            $self->dfa( Storable::retrieve( $self->cachefile ) );
            return $self->dfa;
        }
    }

    if ( not $self->dfa or defined $opts{reset} ) {
        $self->dfa( $self->pregex->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks );

        # save to cache
        if ( $self->do_cache ) {
            Storable::store( $self->dfa, $self->cachefile );
        }
    }
    return $self->dfa;
}

# Acyclic String Iterator
#   force a reset, pass in, C<reset => 1>.
sub next {
    my ( $self, %opts ) = @_;

    die qq{(fatal) Use 'inext' instead of 'next' for infinite languages.\n} if $self->dfa->is_infinite;

    if ( not defined $self->{_acyclical_iterator} or $opts{reset} ) {
        $self->{_acyclical_iterator} = $self->dfa->init_acyclic_iterator(q{ });
    }

    $self->{plan} = $self->{_acyclical_iterator}->();

    return $self->{plan};
}

# accepts the same parameters as a constructor, used to re-initialize
# the current reference
sub plan_nein {
    my $pkg  = shift;
    my $self = __PACKAGE__->new(@_);

    # also returns $self for convenience
    return $self;
}

# wrapper that combines C<init_plan> and C<run_once> to present an idiom,
#    my $final_scope = Sub::Genius->new($plan)->run_any( scope => { ... });
sub run_any {
    my ( $self, %opts ) = @_;
    $self->init_plan;
    my $final_scope = $self->run_once(%opts);
    return $final_scope;
}

# Runs any single serialization ONCE
# defaults to main::, specify namespace of $sub
#
# * ns      => q{Some::NS}  # specify name space
# * scope   => { }          # specify initial state of pipeline accumulator
# * verbose => 0|1          # output runtime diagnostics
sub run_once {
    my ( $self, %opts ) = @_;

    # initialize scope
    $opts{scope} //= {};

    # appends '::' (no check if '::' is at the end to encourage a standard idiom)
    if ( not defined $opts{ns} ) {
        $opts{ns} = q{main::};
    }
    else {
        $opts{ns} .= q{::};
    }

    # only call interator if $self->{plan} has not yet been set
    $self->next if not $self->plan;

    # check plan is set, just to be sure
    if ( my $plan = $self->plan ) {
        if ( $opts{verbose} ) {
            print qq{plan: "$plan" <<<\n\nExecute:\n\n};
        }
        my @seq = split( / /, $plan );

        # main run loop - run once
        local $@;
        foreach my $sub (@seq) {
            eval sprintf( qq{%s%s(\$opts{scope});}, $opts{ns}, $sub );
            die $@ if $@;    # be nice and die for easier debuggering
        }
    }
    return $opts{scope};
}

#
# D R A G O N S
#            ~~~> *E X P E R I M E N T A L* (not even in POD yet)
#

# Deep (Infinite) String Iterator
#   force a reset, pass in, C<reset => 1>.
#
# To us:
#   my $sg = Sub::Genius=->new(preplan => q{a&b*c}, => 'allow-infinite' => 1);
#   $sg->init_plan;
#
#
sub inext {
    my ( $self, %opts ) = @_;
    local $| = 1;
    $opts{max} //= 5;
    if ( not defined $self->{_deepdft_iterator} or $opts{reset} ) {
        $self->{_deepdft_iterator} = $self->dfa->init_deepdft_iterator( $opts{max}, q{ } );
    }

    $self->{plan} = $self->{_deepdft_iterator}->();

    return $self->{plan};
}

1;

__END__

=encoding UTF-8

=head1 NAME

Sub::Genius - Declarative concurrency planning for sequential Perl execution

=head1 SYNOPSIS

    use Sub::Genius;

    my $plan = q{ ( A B ) & ( C D ) Z };
    my $sg   = Sub::Genius->new(preplan => $plan);

    $sg->init_plan;
    $sg->run_once;

    sub A { print "A" }
    sub B { print "B" }
    sub C { print "C" }
    sub D { print "D" }
    sub Z { print "\n" }

=head1 DESCRIPTION

C<Sub::Genius> allows you to express I<concurrent or partially ordered>
execution semantics using a declarative I<plan>, then safely execute that
plan in Perl’s uniprocess runtime.

Plans are written as I<Parallel Regular Expressions> (PREs), which are
compiled into a deterministic finite automaton (DFA). Valid execution
orders are then enumerated and executed I<sequentially consistent> with
the declared constraints.

This makes it possible to:

=over 4

=item *
Declare concurrency without threads

=item *
Guarantee ordering constraints without locks or atomics

=item *
Explore or execute all valid serializations of a concurrent plan

=item *
Reason about shared-memory behavior in plain Perl

=back

C<Sub::Genius> does not introduce real parallelism. Instead, it provides
a rigorous way to describe concurrency I<intent> and execute it safely
within Perl’s single-process execution model.

=head1 QUICK EXAMPLE

    my $plan = q{ A & B & C };
    Sub::Genius->new(preplan => $plan)->run_any;

All permutations of A, B, and C are valid execution orders. One is chosen
and executed sequentially.

=head1 WHERE TO GO NEXT

This module has a rich theoretical and practical background, including:

=over 4

=item *
Parallel Regular Expressions (PREs)

=item *
Shuffle operators and partial ordering

=item *
Sequential consistency and uniprocess memory models

=item *
Finite automata construction and caching

=back

For the full explanation, detailed examples, operator reference, runtime
methods, performance considerations, and tools, see:

L<Sub::Genius::Extended>

=head1 SEE ALSO

L<Sub::Genius::Extended>, L<FLAT>, L<Graph::PetriNet>

=head1 AUTHOR

OODLER 577 E<lt>oodler@cpan.orgE<gt>

=head1 LICENSE

Same terms as Perl itself.

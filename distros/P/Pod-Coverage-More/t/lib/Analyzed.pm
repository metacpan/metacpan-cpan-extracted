package Analyzed;

# Subs written in the idioms that Pod::Coverage::More::Analyzer must read without a signature.
# Each sub exercises one idiom; t/Pod-Coverage-More-Analyzer.t states what the analyzer must report for it.

use 5.036;
use warnings FATAL => q{all};

# Each sub here is an idiom that the analyzer must read, and these policies forbid some of them:
# implicit returns, $_[N], an unused import of a sub that analyze_package must leave out,
# a closure, one-argument bless, string eval, eval as a statement, and the croak and constants
# that the analyzer must recognize.
## no critic (Subroutines::RequireFinalReturn Subroutines::RequireArgUnpacking ProhibitUnusedImports Subroutines::ProhibitSingleUseLexicalSubs ClassHierarchies::ProhibitOneArgBless BuiltinFunctions::ProhibitStringyEval ErrorHandling::RequireCheckingReturnValueOfEval PreferredModules)

use Carp         qw{croak};
use Scalar::Util qw{blessed};

use constant LIMIT    => 5;
use constant GREETING => 'hello';

sub shifted {
    my $self = shift;
    my $name = shift;
    return $name;
}

sub listed {
    my ( $self, $first, @rest ) = @_;
    return scalar(@rest);
}

sub named {
    my $self = shift;
    my %opts = @_;
    return $opts{size} + $opts{count} if exists $opts{verbose};
    return $self->frob( $opts{name} );
}

sub hashref_arg {
    my ( $self, $args ) = @_;
    return $args->{alpha}[0];
}

sub elements {
    return $_[0] + $_[1];
}

sub shift_method {
    return shift->frob;
}

sub uses {
    my ( $num, $str, $code, $obj ) = @_;
    my $total = $num + 1;
    my $label = $str . 'x';
    $code->($total);
    $obj->render($label);
    return;
}

sub anon_inside {
    my $x = shift;
    my $f = sub { return shift };
    return $f->($x);
}

sub constructor {
    my ( $class, %args ) = @_;
    return bless {%args}, ref($class) || $class;
}

sub fixed_class {
    return bless( [], 'Some::Class' );
}

sub one_arg_bless {
    return bless {};
}

sub branches {
    my ($x) = @_;
    if ($x) {
        return 1;
    }
    else {
        return 'no';
    }
}

sub ternary {
    my ($x) = @_;
    return $x ? [] : undef;
}

sub empty_hashref {
    return {};
}

sub fall_through {
    my ($x) = @_;
    if ($x) {
        'yes';
    }
    else {
        { a => 1 };
    }
}

sub bare_return {
    return;
}

sub listy {
    return ( 1, 2, 3 );
}

sub context {
    return wantarray ? (1) : 0;
}

sub calls {
    return listed(@_);
}

sub dies {
    my ($x) = @_;
    die "bad" unless $x;
    croak("worse") if $x < 0;
    eval { die "caught" };
    return 1;
}

{
    no warnings 'once';
    *generated = sub { my ($q) = @_; return [$q] };
}

# Built the way Moo builds its accessors: from a string, with no source file.
eval 'sub evaled { my ($self, $value) = @_; return $value }; 1' or die $@;

# A termination that skips END blocks, and a warning with a stack trace that is not a termination.
use POSIX ();

sub exits_hard {
    POSIX::_exit(1);
}

sub clucks {
    Carp::cluck(q{only a warning});
    return;
}

# Optional parameters written by hand, as Method::Signatures also compiles them.
sub defaulted {
    my $x = $_[0];
    my $y = @_ > 1 ? $_[1] : 5;
    my $z = $_[2] // q{z};
    return [ $x, $y, $z ];
}

sub chosen_class {
    my ( $self, $kind ) = @_;
    return bless {}, $kind;
}

# Perl leaves the empty list of a ternary out of the op tree.
sub ternary_empty_else {
    my ($x) = @_;
    return $x ? lc $x : ();
}

sub ternary_empty_then {
    my ($x) = @_;
    return $x ? () : lc $x;
}

sub ternary_empty_fall_through {
    my ($x) = @_;
    $x ? () : 7;
}

sub context_empty_list {
    return wantarray ? () : 0;
}

# $_[N] with an empty list as its default is no default that a caller can see.
sub defaulted_empty {
    my $x = $_[0];
    my $y = @_ > 1 ? () : 5;
    return [ $x, $y ];
}

# Methods that die by their contract.
sub throws {
    Some::Exception->throw( message => 'no' );
}

sub logs_fatal {
    my ($self) = @_;
    $self->log_fatal('no');
}

sub logs_and_dies {
    my ($self) = @_;
    $self->{log}->logdie('no');
}

sub logs_only {
    my ($self) = @_;
    $self->log_debug('fine');
    return;
}

sub listed_undef_last {
    my ( $self, $elem, undef ) = @_;
    return $elem;
}

sub listed_undef_first {
    my ( undef, $value ) = @_;
    return $value;
}

my sub refuses ( $class, $what ) {
    die "$class does not say $what\n";
}

sub abstract_via_lexical {
    my ($class) = @_;
    return refuses( $class, 'abstract_via_lexical' );
}

sub refuses_too {
    my ( $class, $what ) = @_;
    die "$class does not say $what\n";
}

sub abstract_via_package {
    my ($class) = @_;
    return refuses_too( $class, 'abstract_via_package' );
}

sub sometimes_refuses {
    my ( $class, $flag ) = @_;
    return refuses( $class, 'sometimes' ) if $flag;
    return 1;
}

1;

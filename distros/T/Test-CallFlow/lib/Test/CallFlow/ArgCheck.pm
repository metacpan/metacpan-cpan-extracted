package Test::CallFlow::ArgCheck;
use strict;

=head1 NAME

Test::CallFlow::ArgCheck

=head1 SYNOPSIS

Abstract base class for mock call argument checkers.
Implementors should only need to implement check() below.

  my $checker = Test::CallFlow::ArgCheck::Regexp->new( test => qr/../, max => 9 );
  my @args = qw(abc ab a abcd);
  my $at = 0;
  $at = $checker->skip_matching( $at, \@args );
  "@args[$at,]" eq "a abcd" or die "checker failed";

=head1 PROPERTIES

  test	whatever child class check() method uses to validate an argument
  min	minimum number of matches, 0 means optional, default 1
  max	maximum number of matches, default same as min.

=head1 FUNCTIONS

=head2 new

  my $checker = Test::CallFlow::ArgCheck::SUBCLASS->new( $test, $min, $max );

or

  my $checker = Test::CallFlow::ArgCheck::SUBCLASS->new( 
	test => 'whatever SUBCLASS::check() tests an argument against',
	min => 0,
	max => 999, 
  );

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my %self;
    if ( ref $_[0] ) {
        $self{test} = shift;
        $self{min}  = shift if @_;
        $self{max}  = shift if @_;
    } else {
        %self = @_;
    }

    bless \%self, $class;
}

=head2 check

  $checker->check( $at, \@args ) ? 1 : undef;

Should be implemented in an inherited class to
return a boolean result of comparing a single argument against value of C<test> property.

=head2 skip_matching

  die "Mismatch at $at" unless defined
    $at = $checker->skip_matching( $at, \@args );

If arguments on beginning of given list match requirements (test, range) of this checker,
new index is returned.

Otherwise returns -1 - position of failed argument.

=cut

sub skip_matching {
    my ( $self, $at, $args ) = @_;
    my $min = defined $self->{min} ? $self->{min} : 1;
    my $max = defined $self->{max} ? $self->{max} : $min;
    my $matched = 0;
    my $debug   = exists $ENV{DEBUG} and $ENV{DEBUG} =~ /\bArgCheck\b/;
    my $len     = @$args;
    my $match;

    do {
        $match = $self->check( $at++, $args );
        warn "$self at $at/$len, matched $matched/$min-$max '$args->[$at]': ",
            ( $match || 'mismatch' )
            if $debug;
    } while ( $match and ++$matched < $max and $at < $len );

    warn "$self end at $at/$len, matched $matched/$min-$max" if $debug;
    return $matched < $min ? -$at : $at;
}

1;

package Quux;

use 5.036;
use warnings FATAL => q{all};

=head1 DESCRIPTION

Module for testing out Pod::Coverage::More

=head1 FUNCTIONS

=head2 some_function

Test function with no args

=cut

sub some_function {
    return "HOO HAA";
}

=head2 some_other_function(arg,arg2)

Test function with underscores

=cut

sub some_other_function {
    my ( $arg, $arg2 ) = @_;
    return;
}

=head2 some_function_with_args(nugs,gravy,milk)

Test arg'd function

=cut

sub some_function_with_args {
    my ( $nugs, $gravy, $milk ) = @_;
    print "$nugs, $gravy, $milk\n";
    return;
}

=head2 fun1(arg0,arg1),fun2(arg2,arg3)

Test multiple arg'd functions

=cut

sub fun1 {
    my ( $arg0, $arg1 ) = @_;
    return;
}

sub fun2 {
    my ( $arg2, $arg3 ) = @_;
    return;
}

=head2 fun3(arg1,arg2),fun4,fun5(arg)

Test mixed arg/no arg

=cut

sub fun3 {
    my ( $arg1, $arg2 ) = @_;
    return;
}
sub fun4 { }

sub fun5 {
    my $arg = shift;
    return;
}

=head2 Quux::fully_qualified_function(arg)

Test fully qualified names

=cut

sub fully_qualified_function {
    my $arg = shift;
    return;
}

=head2 B<formatted_function>,B<formatted_function_with_args (foo,bar)>,B<Quux::qualified_formatted_function(arg)>

Test POD formatting

=cut

sub formatted_function { }

sub formatted_function_with_args {
    my ( $foo, $bar ) = @_;
    return;
}

sub qualified_formatted_function {
    my $arg = shift;
    return;
}

=head2 tidied_function ( arg1 , arg2 )

Test whitespace oddities

=cut

sub tidied_function {
    my ( $arg1, $arg2 ) = @_;
    return;
}

=head2 $qx->some_method(arr)

Test lines that are dressed up as method calls

=cut

sub some_method {
    my $arr = shift;
    return;
}

=head2 semi_colon;,semi_colon_with_args(whee,zap)

Test lines with semicolons

=cut

sub semi_colon { }

sub semi_colon_with_args {
    my ( $whee, $zap ) = @_;
    return;
}

=head2 ws_sep ws_sep2(whee, zap, tickle) ws_sep3(poo) ws_sep4( goo, quux ) ws_sep5

Test separating functions by space.

=cut

sub ws_sep { }

sub ws_sep2 {
    my ( $whee, $zap, $tickle ) = @_;
    return;
}

sub ws_sep3 {
    my $poo = shift;
    return;
}

sub ws_sep4 {
    my ( $goo, $quux ) = @_;
    my $horgle;    ## no critic (Variables::ProhibitUnusedVarsStricter) a lexical declared without @_ is not a parameter
    return;
}
sub ws_sep5 { }

=head2 named_args(size,count)

Test arguments that are keys of a hash of named arguments

=cut

sub named_args {
    my ( $self, %opts ) = @_;
    return $opts{size} * $opts{count};
}

1;

__END__



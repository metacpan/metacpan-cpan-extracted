use Test;
use StateML::Machine;
use StateML::Class;
use strict;

=for package StateML::Object

=cut

my $m;
my $o;

## Use StateML::Class for the most part because bare objects can't
## be added to machines.

my @tests = (
sub {
    my $m = StateML::Machine->new( ID => "test machine" );
    $m->add( StateML::Class->new( ID => "base", ATTRS => { "{a}b" => "A:B" } ) );

    $m->add(
        $o = StateML::Class->new( ATTRS => { "{c}d" => "C:D" } )
    );
    my %attrs = $o->attributes;
    ok
        join( ",", map { ( $_ => $attrs{$_} ) } sort keys %attrs ),
        "{c}d,C:D";
},

sub {
    ok join( ",", $o->attributes( "a" ) ), "";
},

sub {
    ok join( ",", $o->attributes( "c" ) ), "d,C:D";
},

sub {
    ## Test inheritence
    $o->class_ids( "base" );
    my %attrs = $o->attributes;
    ok
        join( ",", map { ( $_ => $attrs{$_} ) } sort keys %attrs ),
        "{a}b,A:B,{c}d,C:D";
},


sub {
    ok join( ",", $o->attributes( "a" ) ), "b,A:B";
},

sub {
    ok join( ",", $o->attributes( "c" ) ), "d,C:D";
},
);

plan tests => 0+@tests;

$_->() for @tests;

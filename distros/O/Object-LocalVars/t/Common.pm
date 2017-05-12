package t::Common;
use strict;
use warnings;
use Exporter ();
our @ISA = 'Exporter';
our @EXPORT = qw( 
    test_constructor TC
    test_accessors TA
    test_methods TM
    test_new TN
);

use Test::More;
use Test::Exception;

sub load_fail_msg { return "because $_[0] isn't loaded" }
sub method_fail_msg { return "because $_[0] can't $_[1]" }

sub TC { return 1 + TN() }
sub test_constructor {
    my ($class, @args) = @_;
    my $pass = require_ok( $class );
    my $o;
    SKIP: {
        skip load_fail_msg($class), TC() - 1 unless $pass;
        $o = test_new($class,@args);
    }
    return $o;
}

sub TN { return 2 }
sub test_new {
    my ($class, @args) = @_;
    my $o;
    ok( $o = $class->new(@args), "... creating a $class object");
    ok( $o->isa($class), "... confirming object is a $class" );
    return $o;
}


sub TA { return TN() + 7 }
sub test_accessors {
    my ($o, $prop, $prefix) = @_;
    my $class = ref($o);
    $prefix ||= { get => q{}, set => 'set_' };
    my $acc = $prefix->{get} . $prop;
    my $mut = $prefix->{set} . $prop;
    my $pass = ok( $o->can($acc), "... found accessor function '$acc'" );
    $pass = ok( $o->can($mut), "... found mutator function '$mut'" ) && $pass;

    SKIP: {
        skip load_fail_msg($class), TA() - 2  unless $pass;
        my $p = test_new($class);
        my $value1 = "foo";
        my $value2 = "bar";
        if ( $acc ne $mut ) {
            is( $o->$mut($value1), $o, 
                "... $mut(\$value1) returns self for object 1" );
            is( $o->$acc, $value1,
                "... $acc() equals \$value1 for object 1" );
            is( $p->$mut($value2), $p, 
                "... $mut(\$value2) returns self for object 2" );
            is( $p->$acc, $value2,
                "... $acc() equals \$value2 for object 2" );
            is( $o->$acc, $value1,
                "... $acc() still equals \$value1 for object1" );
        }
        else {
            is( $o->$mut($value1), $value1, 
                "... $mut(\$value1) returns \$value1 for object 1" );
            is( $o->$acc, $value1,
                "... $acc() equals \$value1 for object 1" );
            is( $p->$mut($value2), $value2, 
                "... $mut(\$value2) returns \$value2 for object 2" );
            is( $p->$acc, $value2,
                "... $acc() equals \$value2 for object 2" );
            is( $o->$acc, $value1,
                "... $acc() still equals \$value1 for object1" );
        }
    }
    return $pass;
}

sub TM { return 2 }
sub test_methods {
    my ($o, $case) = @_;
    my ($method, $args, $result) = @$case;
    my $class = ref($o);
    my $pass = can_ok( $o, $method );
    SKIP: {
        skip method_fail_msg($class, $method), TM() - 1  unless $pass;
        is( $o->$method(@$args), $result, "$method gave correct result" );
    }
    return $pass;
}

1;

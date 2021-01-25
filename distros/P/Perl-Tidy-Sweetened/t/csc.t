use lib 't/lib';
use Test::More;
use TidierTests qw(run_test);

run_test( <<'RAW', <<'TIDIED', 'GH#12 - Closing Side Comments', 0, '-csc', '-csci=1', '-cscp="## tidy end:"' );
method _trip_attribute_columns {
    1;
}
RAW
method _trip_attribute_columns {
    1;
} ## tidy end: method _trip_attribute_columns
TIDIED

# Perl::Tidy changed the spacing in version 20200907
if( $Perl::Tidy::VERSION ge '20200907' ) {
run_test( <<'RAW', <<"TIDIED", 'GH#12 - Closing Side Comments', 0, '-csc', '-csci=1'  );
method _trip_attribute_columns {
    1;
}
RAW
method _trip_attribute_columns {
    1;
} ## end method _trip_attribute_columns
TIDIED
} else {
run_test( <<'RAW', <<"TIDIED", 'GH#12 - Closing Side Comments', 0, '-csc', '-csci=1'  );
method _trip_attribute_columns {
    1;
}
RAW
method _trip_attribute_columns {
    1;
} ## end method _trip_attribute_columns
TIDIED
}

run_test( <<'RAW', <<'TIDIED', 'GH#20 - Closing comments when 10+ subs', 0, '-csc', '-csci=1'  );
sub foo0a ($a) {
$a++;
}
sub foo1a ($a) {
$a++;
}
sub foo2a ($a) {
$a++;
}
sub foo3a ($a) {
$a++;
}
sub foo4a ($a) {
$a++;
}
sub foo5a ($a) {
$a++;
}
sub foo6a ($a) {
$a++;
}
sub foo7a ($a) {
$a++;
}
sub foo8a ($a) {
$a++;
}
sub foo9a ($a) {
$a++;
}
sub foo10a ($a) {
$a++;
}
RAW
sub foo0a ($a) {
    $a++;
} ## end sub foo0a

sub foo1a ($a) {
    $a++;
} ## end sub foo1a

sub foo2a ($a) {
    $a++;
} ## end sub foo2a

sub foo3a ($a) {
    $a++;
} ## end sub foo3a

sub foo4a ($a) {
    $a++;
} ## end sub foo4a

sub foo5a ($a) {
    $a++;
} ## end sub foo5a

sub foo6a ($a) {
    $a++;
} ## end sub foo6a

sub foo7a ($a) {
    $a++;
} ## end sub foo7a

sub foo8a ($a) {
    $a++;
} ## end sub foo8a

sub foo9a ($a) {
    $a++;
} ## end sub foo9a

sub foo10a ($a) {
    $a++;
} ## end sub foo10a
TIDIED

done_testing;


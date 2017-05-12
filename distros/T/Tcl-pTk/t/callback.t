use Test::More tests => 16;

use Tcl::pTk;
use Tcl::pTk::Callback;
use Data::Dumper;
 
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

sub lots
{
 my @retval = ("Lots Args = ".join(", ", @_) ); 
 push @retval, (0..10);
 return @retval;
}

sub one
{
 my $retval = ("one Args = ".join(", ", @_) ); 
 return $retval;;
}


my $mainWindow = MainWindow();

is( Data::Dumper::Dumper( [Tcl::pTk::Callback->new(\&lots)->Call('a'..'d')] ),
        "['Lots Args = a, b, c, d',0,1,2,3,4,5,6,7,8,9,10]",
        "Subref Form, with no args");
is(Data::Dumper::Dumper( [Tcl::pTk::Callback->new([\&lots,'A'..'F'])->Call('a'..'d')] ),
        "['Lots Args = A, B, C, D, E, F, a, b, c, d',0,1,2,3,4,5,6,7,8,9,10]", 
        "Subref Form, with args");
        
is(Data::Dumper::Dumper( [Tcl::pTk::Callback->new(\&one)->Call('a'..'d')] ),
        "['one Args = a, b, c, d']",
        "Subref Form, with no args, scalar ret val");

is(Data::Dumper::Dumper( [Tcl::pTk::Callback->new([\&one,'A'..'F'])->Call('a'..'d')] ),
        "['one Args = A, B, C, D, E, F, a, b, c, d']",
        "Subref Form, with args, scalar ret val");


is(Data::Dumper::Dumper( [Tcl::pTk::Callback->new([\&one,'A'..'F'])->BindCall('event','a'..'d')] ),
        "['one Args = event, A, B, C, D, E, F, a, b, c, d']",
        "BindCall Subref Form, with args, scalar ret val");


my $foo = 'foo'->new();

# Obj-Method Call tests
is(Data::Dumper::Dumper( [Tcl::pTk::Callback->new([$foo,'fooMethod'] )->Call('a'..'d')] ),
        "['fooMethod Args = a, b, c, d']",
        "Object->Method Form, no args");

is( Data::Dumper::Dumper( [Tcl::pTk::Callback->new([$foo,'fooMethod','A'..'F'])->Call('a'..'d')] ),
        "['fooMethod Args = A, B, C, D, E, F, a, b, c, d']",
        "Object->Method Form, with args");

is( Data::Dumper::Dumper( [Tcl::pTk::Callback->new(['fooMethod','A'..'F'])->BindCall($foo, 'a'..'d')] ),
        "['fooMethod Args = A, B, C, D, E, F, a, b, c, d']",
        "BindCall Method Form, with args");

is( Data::Dumper::Dumper( [Tcl::pTk::Callback->new('fooMethod')->BindCall($foo, 'a'..'d')] ),
        "['fooMethod Args = a, b, c, d']",
        "BindCall Method Form with no args");

# Obj-Method form for bindcall, event source 'bogus' should be ignored
is( Data::Dumper::Dumper( [Tcl::pTk::Callback->new([$foo, 'fooMethod','A'..'F'])->BindCall('bogus', 'a'..'d')] ),
        "['fooMethod Args = A, B, C, D, E, F, a, b, c, d']",
        "BindCall Obj-Method Form, with args");


# Method-Obj Call tests
is(Data::Dumper::Dumper( [Tcl::pTk::Callback->new(['fooMethod', $foo] )->Call('a'..'d')] ),
        "['fooMethod Args = a, b, c, d']",
        "Method, Obj Form, no args");

is( Data::Dumper::Dumper( [Tcl::pTk::Callback->new(['fooMethod',$foo,'A'..'F'])->Call('a'..'d')] ),
        "['fooMethod Args = A, B, C, D, E, F, a, b, c, d']",
        "Method, Obj Form, with args");


###### Test of Ev Substitutions #####
# Create a callback with Ev() substitutions
my $callback = Tcl::pTk::Callback->new([\&lots, 'arg1', Ev('x'), Ev('y'), 'arg4']);

# Check to see if the arg substitution method works
$callback->_updateEvArgs('XXX', 'YYY');
my $callbackRef = $callback->{callback};
my @callbackArgs = @$callbackRef[1..4];
is_deeply( [@callbackArgs], ['arg1', 'XXX', 'YYY', 'arg4'], "_updateEvArgs method");


###### Test of Ev Substitutions #####
# Create a callback with Ev() substitutions
$callback = Tcl::pTk::Callback->new([\&lots, 'arg1', Ev('x'), Ev('y'), 'arg4']);
my $cbRef = $callback->createTclBindRef($mainWindow);
is( ref($cbRef->[1]), 'Tcl::Ev', "TclBindRef arg component");

my @retVal = $cbRef->[0]->('.', 'XXX', 'YYY');

is( Data::Dumper::Dumper( [@retVal] ),
        "['Lots Args = ., arg1, XXX, YYY, arg4',0,1,2,3,4,5,6,7,8,9,10]",
        "createTclBindRef output");

# Fall-thru test of creating a callback that is already a callback
$callback = Tcl::pTk::Callback->new(\&lots);
$callback = Tcl::pTk::Callback->new($callback);
is(ref($callback), 'Tcl::pTk::Callback', "Callback fallthru"); 


################# Test Object for checking method calls ######################################
package foo;

sub new{
        my $class = shift;
        
        my $self = {};
        
        return bless($self, $class);
}

sub fooMethod{
        my $self = shift;
        return "fooMethod Args = ".join(", ", @_);
}
        



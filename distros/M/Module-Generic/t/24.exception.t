#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use Config;
    use Test::More qw( no_plan );
    use_ok( 'Module::Generic::Exception' ) || BAIL_OUT( "Unable to load Module::Generic::Exception" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
no warnings 'once';

subtest 'methods' => sub
{
    my $ex = Module::Generic::Exception->new;
    isa_ok( $ex, 'Module::Generic::Exception' );

    # To generate this list:
    # egrep -E '^sub ' ./lib/Module/Generic/Exception.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$ex, \"$m\" );"'
    can_ok( $ex, "init" );
    can_ok( $ex, "as_string" );
    can_ok( $ex, "caught" );
    can_ok( $ex, "cause" );
    can_ok( $ex, "code" );
    can_ok( $ex, "file" );
    can_ok( $ex, "lang" );
    can_ok( $ex, "line" );
    can_ok( $ex, "locale" );
    can_ok( $ex, "message" );
    can_ok( $ex, "package" );
    can_ok( $ex, "PROPAGATE" );
    can_ok( $ex, "rethrow" );
    can_ok( $ex, "retry_after" );
    can_ok( $ex, "subroutine" );
    can_ok( $ex, "throw" );
    can_ok( $ex, "trace" );
    can_ok( $ex, "type" );
    can_ok( $ex, "_obj_eq" );
    can_ok( $ex, "FREEZE" );
    can_ok( $ex, "STORABLE_freeze" );
    can_ok( $ex, "STORABLE_thaw" );
    can_ok( $ex, "THAW" );
    can_ok( $ex, "TO_JSON" );
};

my $str = MyObject::String->new( 'Oops' => 'en_GB' );
my $ex = Module::Generic::Exception->new({
    code => 500,
    message => $str,
    type => 'syntax',
    debug => 4,
    cause => {
        id => 1234,
    },
});

isa_ok( $str => 'MyObject::String' );
isa_ok( $ex => 'Module::Generic::Exception' );
SKIP:
{
    if( !defined( $str ) )
    {
        skip( "Error instantiating the exception object.", 1 );
    }
    is( $ex->code, 500, 'code' );
    is( $ex->message, 'Oops', 'message' );
    is( $ex->lang, 'en_GB', 'lang' );
    is( $ex->locale, 'en_GB', 'locale' );
    is( $ex->type, 'syntax', 'type' );
    is( $ex->cause->id, 1234, 'cause' );
};

subtest 'create_class' => sub
{
    my $rv = exception My::Exception;
    is( $rv => 'My::Exception', 'exception class created' );
    $rv = exception Other::Exception extends => 'My::Exception';
    is( $rv => 'Other::Exception', 'exception class created with inheritance' );
    local $@;
    eval
    {
        die( My::Exception->new( "Something bad has happened" ) );
    };
    isa_ok( $@ => 'My::Exception', 'exception error' );
    if( Module::Generic::Exception->_is_a( $@ => 'My::Exception' ) )
    {
        is( $@->message, 'Something bad has happened', 'exception message' );
    }
    else
    {
        fail( 'exception message' );
    }
    my $ex = Other::Exception->new( "Another bad thing has happened" );
    isa_ok( $ex => 'Other::Exception', 'exception object' );
    
};

subtest 'basic exception creation' => sub
{
    my $e = Module::Generic::Exception->new( 'Something bad happened' );
    isa_ok( $e, 'Module::Generic::Exception' );
    is( $e->message, 'Something bad happened', 'Message stored correctly' );
    like( "$e", qr/Something bad happened/, 'Stringification returns message' );
    # ok( !$e->success, 'success method always returns false' );
};

subtest 'exception without message' => sub
{
    my $e = Module::Generic::Exception->new;
    isa_ok( $e, 'Module::Generic::Exception' );
    is( $e->message, '', 'No message is used' );
    # like( "$e", qr/An unknown error occurred/i, 'Stringification returns default message' );
};

subtest 'threaded usage' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads are not available on this system', 1 );
        }
        require threads;
        threads->import;

        my $thr = threads->create(sub
        {
            my $e = Module::Generic::Exception->new( "Threaded error" );
            return( scalar( $e->message ) );
        });

        my $result = $thr->join;
        is( $result, 'Threaded error', 'Exception created and passed correctly in thread' );
    }
};

subtest 'exception as object and string' => sub
{
    my $e = Module::Generic::Exception->new( 'Mixed usage' );
    my $str = "$e";
    like( $str, qr/Mixed usage/, 'Stringified exception matches expected output' );
    is( $e->message, 'Mixed usage', 'Object still holds correct message' );
};

{
    package
        MyObject::String;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use overload (
            '""'    => 'as_string',
            'bool'  => sub{1},
            fallback => 1,
        );
    };

    use strict;
    use warnings;
    
    sub init
    {
        my $self = shift( @_ );
        my $value = shift( @_ );
        my $locale = shift( @_ );
        $self->{locale} = $locale;
        $self->{value}  = $value;
        $self->SUPER::init( @_ );
        return( $self );
    }
    
    sub as_string { return( shift->value->scalar ); }
    
    sub locale { return( shift->_set_get_scalar_as_object( 'locale', @_ ) ); }

    sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }
    
    sub TO_JSON { return( shift->as_string ); }
}

done_testing();

__END__


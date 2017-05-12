use strict;
use warnings;
use Scalar::Util qw/refaddr/;
use Test::More tests => 11;
use Test::Exception;


BEGIN{
    use_ok(q|Scope::Session|);

}

::lives_ok {
    Scope::Session::start {
        pass(q|call in|);
    };
};

Scope::Session::start {
    my $session = shift;
    ::isa_ok 
        $session, 
        'Scope::Session' ,
        q|instance is a Scope::Session|;

    ::is
        refaddr( $session ), 
        refaddr( Scope::Session->get_instance ),
        q|same instance $session and Scope::Session->get_instance|;

    $session->set_option( 'is_debug' => 1 );

    ::ok $session->get_option('is_debug') ,q|set is_debug|;
};


::dies_ok { 
    Scope::Session::start {
        Scope::Session::start{
            fail('dont call here');
        };
    };
};

{
    package Test::Error;
    use base qw/Error::Simple/;
};
{
    package Test::Error::Sub;
    use base qw/Test::Error/;
};

Scope::Session::start{
    my $session = shift;

    $session->add_error_handler('Test::Error',sub{
        my $error = shift;
        ::isa_ok $error , 'Test::Error';
    });
    die with Test::Error('');
};

Scope::Session::start{
    my $session = shift;

    $session->add_error_handler('Test::Error',sub{
        my $error = shift;
        ::isa_ok $error , 'Test::Error';
    });

    $session->add_error_handler('Test::Error',sub{
        my $error = shift;
        ::pass 'second';
    });

    $session->add_error_handler('Test::Error::Sub',sub{
        my $error = shift;
        ::isa_ok $error , 'Test::Error::Sub';
    });

    die with Test::Error::Sub('');
};

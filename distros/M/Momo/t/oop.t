use Test::More;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

BEGIN {
    unshift @INC, abs_path( File::Spec->catdir( $Bin, '..', 'lib' ) );
    use_ok('Momo');
}

# test oop new object
{

    package foo;

    use Momo;

    extends 'FileHandle';

    has name => 'james';
    has age  => 28;
    has lang => 'perl';

    sub test_foo {
        shift->say("I'm a foo boject");
    }

    sub check_age {
        if ( shift->age =~ /\d+/ ) {
            return 1;
        }
    }

    1;

}
{

    package Logger;

    use Momo::Role;

    sub log {
        my $self = shift;
        print for @_;
        print "\n";
    }
}
{

    package role;

    use Momo::Role;

    with 'Logger';

    has 'is_role' => 1;

    around get_email_domain => sub {
        my $origin = shift;
        my $self   = shift;
        my $email  = $self->email;
        if ( $email =~ m/live/ ) {
            $self->$origin('hotmail');
        }
    };
    1;
}
{

    package bar;

    use Momo;

    extends 'foo';
    with 'role';

    has city     => 'changsha';
    has email    => 'yiming.jin@live.com';
    has province => sub {
        if ( shift->city eq 'changsha' ) {
            return 'hunan';
        }
    };
    has xml => '';

    sub new {
        my $self = shift->SUPER::new(@_);
        $self->age(30);
    }

    sub get_email_domain {
        my ( $self, $type ) = @_;
        return $type;
    }
    before xml_info => sub {
        my $self = shift;
        my $xml  = $self->xml;
        $xml .= '<name>';
        $self->xml($xml);
    };
    before xml_info => sub {
        my $self = shift;
        my $xml  = $self->xml;
        $xml .= '<xml>';
        $self->xml($xml);
    };

    around xml_info => sub {
        my ( $origin, $self ) = @_;
        my $xml = $self->xml;
        $xml .= $self->name . '</name>';
        $self->xml($xml);
        $self->$origin();
    };
    after xml_info => sub {
        my $self = shift;
        my $xml  = $self->xml;
        $xml .= '<age>' . $self->age . '</age>';
        $self->xml($xml);
    };
    after xml_info => sub {
        my $self = shift;
        my $xml  = $self->xml;
        $xml .= '</xml>';
        $self->xml($xml);
    };

    sub xml_info {
    }
    1;
}

# test common object attr
my $obj = bar->new( name => 'jack' );
is( $obj->city,      'changsha', 'test obj city attr' );
is( $obj->name,      'jack',     'test obj name attr' );
is( $obj->lang,      'perl',     'test obj lang attr' );
is( $obj->age,       30,         'test obj age attr' );
is( $obj->check_age, 1,          'test check_age method' );
is( $obj->province,  'hunan',    'test province attr' );
is( $obj->get_email_domain, 'hotmail',
    'test email type with before method modifier' );
is( $obj->is_role,            1, 'test role option' );
is( defined $obj->can('log'), 1, 'test role log method' );

#$obj->log("log some thing");
$obj->xml_info;
is(
    $obj->xml,
    '<xml><name>jack</name><age>30</age></xml>',
    'test xml info create'
);
is( $obj->isa("FileHandle"),1,'test obj is subclass of FileHandle');

done_testing();

# niumang // vim: ts=4 sw=4 expandtab
# TODO - Edit.

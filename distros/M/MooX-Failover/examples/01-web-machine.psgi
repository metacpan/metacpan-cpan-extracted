use lib 'lib';

{
    package Local::Resource::Foo;

    use Moo;
    use MooX::Failover;
    use MooX::Types::MooseLike::Base qw/ Int /;

    extends 'Web::Machine::Resource';

    has 'arg' => (
        is       => 'ro',
        isa      => Int,
        required => 1,
    );

    failover_to 'Local::Resource::Error';

    sub content_types_provided {
        [
            {
                'text/plain' => 'foo_text',
            }
        ];
    }

    sub foo_text {
        my ($self) = @_;
        $self->response->body( "foo.arg = " . $self->arg . "\n" );
    }

}

{
    package Local::Resource::Error;

    use Moo;
    use MooX::Types::MooseLike::Base qw/ Int Str /;

    extends 'Web::Machine::Resource';


    has error => ( is => 'ro', );

    has class => (
        is  => 'ro',
        isa => Str
    );

    has status => (
        is      => 'rw',
        isa     => Int,
        default => 500,
    );

    sub content_types_provided {
        [
            {
                'text/plain' => 'error_text',
            }
        ];
    }

    sub error_text {
        my ($self) = @_;

        my $error = $self->error // '';
        if ( my ($arg) = ($error =~ /isa check for "(\w+)" failed/))
        {

          if ($self->class) {
            my ($class) = (lc($self->class) =~ /Local::Resource::(\w+)/i);

            $self->status(400);
            return "${class}.${arg} is invalid\n";

          }

        }

        return 'Internal error';
    }

    sub finish_request {
        my ($self) = @_;
        $self->response->status( $self->status );
    }

}

{

    package Local::App;

    use Web::Simple;
    use Web::Machine;

    use Local::Resource::Foo;

    use common::sense;

    sub dispatch_request {
        ( 'GET + /foo/*' => 'foo', );
    }

    sub foo {
        my ( $self, $arg ) = @_;

        Web::Machine->new(
            resource      => 'Local::Resource::Foo',
            resource_args => [
                arg         => $arg,
            ],
        );
    }

}

use Local::App;

use common::sense;

Local::App->run_if_script;

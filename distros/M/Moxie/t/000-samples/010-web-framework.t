#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

# traits ...

package Entity::Traits::Provider {
    use Moxie;

    use Method::Traits ':for_providers';

    sub JSONParameter { () }
}

package Service::Traits::Provider {
    use Moxie;

    use Method::Traits ':for_providers';

    sub Path ($meta, $method_name, $path) { () }

    sub GET ($meta, $method_name) { () }
    sub PUT ($meta, $method_name) { () }

    sub Consumes ($meta, $method_name, $media_type) { () }
    sub Produces ($meta, $method_name, $media_type) { () }
}

# this is the entity class

package Todo {
    use Moxie
        traits => [ 'Entity::Traits::Provider' ];

    extends 'Moxie::Object';

    has _description => ();
    has _is_done     => ();

    sub description : ro(_description) JSONParameter;
    sub is_done     : ro(_is_done)     JSONParameter;
}

# this is the web-service for it

package TodoService {
    use Moxie
        traits => [ 'Service::Traits::Provider', ':experimental' ];

    extends 'Moxie::Object';

    has 'todos' => ( default => sub { +{} } );

    my sub todos : private;

    sub get_todo ($self, $id) : Path('/:id') GET Produces('application/json') {
        todos->{ $id };
    }

    sub update_todo ($self, $id, $todo) : Path('/:id') PUT Consumes('application/json') {
        return unless todos->{ $id };
        todos->{ $id } = $todo;
    }
}

done_testing;


=pod
# this is what it ultimately generates ...
package TodoResource {
    use Moxie;

    extends 'Web::Machine::Resource';

    has 'JSON'    => sub { JSONinator->new  };
    has 'service' => sub { TodoService->new };

    sub allowed_methods        { [qw[ GET PUT ]] }
    sub content_types_provided { [{ 'application/json' => 'get_as_json' }]}
    sub content_types_accepted { [{ 'application/json' => 'update_with_json' }]}

    sub get_as_json ($self) {
        my $id  = bind_path('/:id' => $self->request->path_info);
        my $res = $self->{service}->get_todo( $id );
        return \404 unless $res;
        return $self->{JSON}->collapse( $res );
    }

    sub update_with_json ($self) {
        my $id  = bind_path('/:id' => $self->request->path_info);
        my $e   = $self->{JSON}->expand( $self->{service}->entity_class, $self->request->content )
        my $res = $self->{service}->update_todo( $id, $e );
        return \404 unless $res;
        return;
    }
}
=cut


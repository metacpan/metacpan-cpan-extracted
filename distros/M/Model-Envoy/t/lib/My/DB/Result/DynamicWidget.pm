package My::DynamicProperty;

use base 'DBIx::Class';

sub insert {

    my $self = shift;

    if ( ! defined $self->name ) {
        $self->name('name set');
    }

    if ( ! defined $self->id ) {
        $self->id( 42 );
    }

    return $self->next::method(@_);
    
}

1;

package My::DB::Result::DynamicWidget;

use Moose;

extends 'DBIx::Class::Core';

__PACKAGE__->load_components( '+My::DynamicProperty' );

__PACKAGE__->table('widgets');
__PACKAGE__->add_columns(

    'id'      => { data_type => 'integer', is_nullable => 0, },
    'name'    => { data_type => 'text',    is_nullable => 1, },

);
__PACKAGE__->set_primary_key('id');

1;

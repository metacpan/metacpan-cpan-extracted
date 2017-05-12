# This is the root class of all Fluidinfo value types. The hierarchy splits
# into native types and non native types.
#
# These objects carry transport knowledge as of today. They know their MIME
# type, and they know how they should be travel as payload of HTTP requests.
# This could be internally redesigned in the future, but by now looks like
# a good compromise.
package Net::Fluidinfo::Value;
use Moose;

has mime_type => (is => 'ro', isa => 'Str');
has value     => (is => 'ro', isa => 'Any');

sub is_native {
    0;
}

sub is_non_native {
    0;
}

sub new_from_types_and_content {
    my ($class, $mime_type, $fin_type, $content) = @_;

    # instead of ordinary use(), to play nice with inheritance
    require Net::Fluidinfo::Value::Native;
    if (Net::Fluidinfo::Value::Native->is_mime_type($mime_type)) {
        Net::Fluidinfo::Value::Native->new_from_fin_type_and_json($fin_type, $content);
    } else {
        # instead of ordinary use(), to play nice with inheritance
        require Net::Fluidinfo::Value::NonNative;
        Net::Fluidinfo::Value::NonNative->new(mime_type => $mime_type, value => $content);
    }
}

sub payload {
    # abstract
}

sub type {
    my $self = shift;
    if ($self->is_native) {
        $self->type_alias;
    } else {
        $self->mime_type;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

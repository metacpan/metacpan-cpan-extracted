package MyService::MyEntry;
use Any::Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Entry';
use XML::Atom::Util qw(textValue);

feedurl child => (
    entry_class => 'MyService::MyEntry',
    rel => 'http://example.com/schema#myentry',
);

feedurl src_child => (
    entry_class => 'MyService::MyEntry',
    as_content_src => 1,
    query_builder => sub {
        my ($self, $args) = @_;
        return {
            foobar => $args || '',
        }
    },
    arg_builder => sub {
        my ($self, $args) = @_;
        return {
            foobar => $args || '',
        }
    }
);

feedurl atom_child => (
    entry_class => 'MyService::MyEntry',
    from_atom => sub {
        my ($self, $atom) = @_;
        return textValue($self->elem, $self->ns('hoge')->{uri}, 'fuga');
        return $atom->id;
    }
);

feedurl null_child => (
    entry_class => 'MyService::MyEntry',
);

entry_has foobar => (
    is => 'rw',
    isa => 'Str',
    tagname => 'foobar',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;
no Net::Google::DataAPI;

1;

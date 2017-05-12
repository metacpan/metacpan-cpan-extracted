package MongoDB::Simple::Test;

use MongoDB::Simple;
our @ISA = ('MongoDB::Simple');
our $data = {};

database 'mtest';
collection 'items';

string 'name'        => {
    changed => sub {
        my ($self, $value) = @_;
        eval {
            my $obj = new MongoDB::Simple::Test::Duplicate(client => $self->{client});
            $obj->load($self->{doc}->{_id});
            $obj->name($value);
            $obj->save;
        };
    }
};
date 'created'       => undef;
boolean 'available'  => undef;
object 'attr'        => undef;
array 'tags'         => undef;
object 'metadata'    => { type => 'MongoDB::Simple::Test::Meta' };
array 'labels'       => { type => 'MongoDB::Simple::Test::Label' };
array 'multi'        => { types => [ 'MongoDB::Simple::Test::Meta', 'MongoDB::Simple::Test::Label' ] };
object 'hash'        => undef;
array 'callbacks'    => {
    'changed' => sub {
        my ($self, $value) = @_;
        $MongoDB::Simple::Test::data->{changed} = $value;
    },
    'pop' => sub {
        my ($self, $value) = @_;
        $MongoDB::Simple::Test::data->{pop} = $value;
    },
    'push' => sub {
        my ($self, $value) = @_;
        $MongoDB::Simple::Test::data->{push} = $value;
    },
    'shift' => sub {
        my ($self, $value) = @_;
        $MongoDB::Simple::Test::data->{shift} = $value;
    },
    'unshift' => sub {
        my ($self, $value) = @_;
        $MongoDB::Simple::Test::data->{unshift} = $value;
    }
};

################################################################################

package MongoDB::Simple::Test::Meta;

use MongoDB::Simple;
our @ISA = ('MongoDB::Simple');

matches sub {
    my ($doc) = @_;
    my %keys = map { $_ => 1 } keys %$doc;
    return 1 if scalar keys %keys == 1 && $keys{type};
    return 0;
};

string 'type'  => undef;
object 'label' => { type => 'MongoDB::Simple::Test::Label' };

################################################################################

package MongoDB::Simple::Test::Label;

use MongoDB::Simple;
our @ISA = ('MongoDB::Simple');

matches sub {
    my ($doc) = @_;
    my %keys = map { $_ => 1 } keys %$doc;
    return 1 if (scalar keys %keys == 1) && $keys{text};
    return 0;
};

string 'text'  => undef;

################################################################################

package MongoDB::Simple::Test::Duplicate;

use MongoDB::Simple;
our @ISA = ('MongoDB::Simple');

database 'mtest';
collection 'itemlist';

dbref 'item_id';
string 'name';

locator sub {
    my ($self, $id) = @_;

    return {
        'item_id' => $self->item_id || {
            '$ref' => 'items',
            '$id' => $id
        }
    };
};

################################################################################

1;

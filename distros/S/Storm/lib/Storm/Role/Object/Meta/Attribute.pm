package Storm::Role::Object::Meta::Attribute;
{
  $Storm::Role::Object::Meta::Attribute::VERSION = '0.240';
}

use Moose::Role;
use Storm::Meta::Column;

use Storm::Types qw( SchemaColumn );
use MooseX::Types::Moose qw( Undef );

has 'column' => (
    is => 'rw',
    isa => SchemaColumn|Undef,
    coerce => 1,
);

has 'transform' => (
    is => 'rw',
    isa => 'Maybe[HashRef[CodeRef]]',
);

has 'define' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);


# we need to play with the options before sending them
# on to the attribute constructor

before '_process_options' => sub {
    my ( $class, $name, $options ) = @_;
    my $meta = $class->meta;
    
    # if the transform option was supplied, make sure
    # the both the inflator and deflator we specified
    if ( $options->{transform} ) {
        
        # check for bad keys
        for my $key ( keys %{ $options->{transform} } ) {
            if ( $key ne 'inflate' && $key ne 'deflate' ) {
                confess "bad transformation '$key', must be either 'inflate' or 'deflate'";
            }
        }
        
        # check the both inflate and deflate options exist
        if ( ! exists $options->{transform}{inflate} || ! exists $options->{transform}{deflate} ) {
            confess "must supply both an inflate and deflate argument";
        }
    }
    
    # edit the column option as necessary
    
    # if no column option was specified, default it to the attribute name
    if ( ! exists $options->{column} ) {
        $options->{column} = { name => $name };
    }
    # if column option is hashref with no name, set it to the attribute name
    elsif ( defined $options->{column} && ref $options->{column} eq 'HASH') {
        $options->{column}{name} = $name if ! exists $options->{column}{name};
    }
    # if just a string was supplied, that is the column name
    elsif (defined $options->{column} && ! ref $options->{column} ) {
        $options->{column} = { name => $options->{column} }
    }
    
};

1;

package Orochi::Injection::Constructor;
use Moose;
use namespace::clean -except => qw(meta);

with 'Orochi::Injection';

has class => (
    is => 'rw',
    isa => 'Str', # if we make this a 'ClassName', we force the user to
                  # load it before hand
    required => 1
);

has args => (
    is => 'ro',
    isa => 'Orochi::Injection | HashRef | ArrayRef',
    predicate => 'has_args',
);

has deref_args => (
    is => 'ro',
    isa => 'Bool',
    required => 1,
    default => 1
);

has block => (
    is => 'ro',
    isa => 'CodeRef',
    predicate => 'has_block'
);

has constructor => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => 'new',
);

sub expand {
    my ($self, $c) = @_;

    my @args = $self->mangle_args($c);
    if (Orochi::DEBUG() >= 2) {
        require Data::Dumper;
        Orochi::_debug( "Constructor: expanding class '%s' with args %s", $self->class, Data::Dumper::Dumper(\@args) );
    } elsif (Orochi::DEBUG() == 1) {
        Orochi::_debug( "Constructor: expanding class '%s'", $self->class);
    }
    return $self->construct_object($c, \@args);
}

sub construct_object {
    my ($self, $c, $args) = @_;

    my $constructor = $self->constructor;
    my $class = $self->class;
    if (! Class::MOP::is_class_loaded($class) ) {
        Class::MOP::load_class($class);
    }

    return $self->has_block ?
        $self->block->( $class, @$args ) :
        $class->$constructor(@$args)
    ;
}

sub mangle_args {
    my ($self, $c) = @_;

    my @args;
    if ($self->has_args) {
        my $x = $self->args;

        if (blessed $x && Moose::Util::does_role($x, 'Orochi::Injection')) {
            my $injection = $x;
            $x = $injection->expand($c);
            if ($x && (my $post_expand = $injection->can('post_expand')) ) {
                $post_expand->($injection, $c, $x);
            }
        }
        
        if ($self->deref_args) {
            my $ref = ref $x;
            @args = 
                $ref eq 'HASH' ? %$x :
                $ref eq 'ARRAY' ? @$x :
                confess "Don't know how to dereference $ref"
            ;
        } else {
            push @args, $x;
        }
    }

    my $wrap = [@args];
    $self->expand_all_injections($c, $wrap);
    return @$wrap;
}

1;
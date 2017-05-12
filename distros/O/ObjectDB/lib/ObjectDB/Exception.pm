package ObjectDB::Exception;

use strict;
use warnings;

use overload '""' => \&to_string, fallback => 1;

require Carp;

sub new {
    my $class = shift;
    my ($message, %context) = @_;

    my $self = {};
    bless $self, $class;

    $self->{message} = $message;

    $self->{context} = $context{context};
    $self->{sql}     = $context{sql};

    return $self;
}

sub throw {
    my $class = shift;

    Carp::croak($class->new(@_));
}

sub as_string { &to_string }

sub to_string {
    my $self = shift;

    my $message = $self->{message};

    my @context;
    if (my $context = $self->{context}) {
        my $class = ref($context) ? ref($context) : $context;
        push @context, q{class='} . $class . q{'};

        if (ref($context) && $class->can('meta')) {
            push @context, q{table='} . $context->meta->table . q{'};
        }
    }

    if (my $sql = $self->{sql}) {
        push @context, q{sql='} . $sql->to_sql . q{'};
        push @context, q{bind='} . join(', ', $sql->to_bind) . q{'};
    }

    if (@context) {
        $message .= ': ' . join ', ', @context;
    }

    return $message;
}

1;

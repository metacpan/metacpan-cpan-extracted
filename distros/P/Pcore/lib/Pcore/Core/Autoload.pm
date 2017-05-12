package Pcore::Core::Autoload;

use Pcore -export, { DEFAULT => ['AUTOLOAD'] };

sub AUTOLOAD ( $self, @ ) {    ## no critic qw[ClassHierarchies::ProhibitAutoloading]
    die qq["_AUTOLOAD" method is required in "$self" by "-autoload" pragma] unless $self->can('_AUTOLOAD');

    my $method = our $AUTOLOAD =~ s/\A.*:://smr;

    my $class = ref $self || $self;

    # request CODEREF
    my $code = $self->_AUTOLOAD( $method, @_ );

    # install returned coderef as method
    no strict qw[refs];

    if ( ref $code ) {
        *{"$class\::$method"} = $code;
    }
    else {
        eval "\*{'$class\::$method'} = $code";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval ErrorHandling::RequireCheckingReturnValueOfEval]
    }

    goto &{"$class\::$method"};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Autoload

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

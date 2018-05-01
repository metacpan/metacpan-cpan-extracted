package # Hide from the indexer.
    MooseX::SingleArg::Meta::Object;
use Moose::Role;

use Carp qw( croak );

around BUILDARGS => sub{
    my $orig  = shift;
    my $class = shift;

    my $meta = $class->meta();
    croak("single_arg() has not been called for $class") if !$meta->has_single_arg();

    my $force = $meta->force_single_arg();
    croak("$class accepts only one argument") if $force and @_>1;

    if (@_==1 and ($force or ref($_[0]) ne 'HASH')) {
        return $class->$orig( $meta->single_arg() => $_[0] );
    }

    return $class->$orig( @_ );
};

1;

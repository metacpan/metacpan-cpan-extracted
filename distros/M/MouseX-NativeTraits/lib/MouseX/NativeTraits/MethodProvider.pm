package MouseX::NativeTraits::MethodProvider;
use Mouse;

has attr => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
    weak_ref => 1,
);

has reader => (
    is => 'ro',

    lazy_build => 1,
);

has writer => (
    is => 'ro',

    lazy_build => 1,
);

sub _build_reader {
    my($self) = @_;
    return $self->attr->get_read_method_ref;
}

sub _build_writer {
    my($self) = @_;
    return $self->attr->get_write_method_ref;
}

sub has_generator {
    my($self, $name) = @_;
    return $self->meta->has_method("generate_$name");
}

sub generate {
    my($self, $handle_name, $method_to_call) = @_;

    my @curried_args;
    ($method_to_call, @curried_args) = @{$method_to_call};

    my $code = $self->meta
        ->get_method_body("generate_$method_to_call")->($self);

    if(@curried_args){
        return sub {
            my $instance = shift;
            $code->($instance, @curried_args, @_);
        };
    }
    else{
        return $code;
    }
}

sub get_generators {
    my($self) = @_;

    return grep{ s/\A generate_ //xms } $self->meta->get_method_list;
}

sub argument_error {
    my($self, $name, $min, $max, $nargs) = @_;

    if(not defined $max) {
        $max = 9 ** 9 ** 9; # inifinity :p
    }

    # fix numbers for $self
    $min--;
    $max--;
    $nargs--;

    if($min <= $nargs and $nargs <= $max) {
        Carp::croak("Oops ($name): nags=$nargs, min=$min, max=$max");
    }

    my $message = 'Cannot call %s %s argument%s';

    if($min == 0 and $max == 0 && $nargs > 0) {
        $self->meta->throw_error(
            sprintf $message,
                $name, 'with any', 's' );
    }

    $self->meta->throw_error(
        sprintf 'Cannot call %s %s %d argument%s',
            $name, ($nargs < $min
                ? ('without at least', $min)
                : ('with more than',   $max) ),
            $nargs == 1 ? '' : 's' );
}

no Mouse;
__PACKAGE__->meta->make_immutable(strict_constructor => 1);

__END__


=head1 NAME

MouseX::NativeTraits::MethodProvider - The common base class for method providers

=head1 DESCRIPTION

This class is the common base class for method providers.

=head1 ATTRIBUTES

=over 4

=item attr

=item reader

Shortcut for C<< $provider->attr->get_read_method_ref >>.

=item writer

Shortcut for C<< $provider->attr->get_write_method_ref >>.

=back

=head1 METHODS

=over 4

=item has_generator

=item generate

=item get_generators

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>

=cut

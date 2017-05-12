package MooseX::LeakCheck::Base;
use Moose::Role;
use Moose::Util::TypeConstraints;

sub DEMOLISH {};

after DEMOLISH => sub {
    my $self = shift;
    my $meta = $self->meta;
    return unless $meta;

    for my $attr ( $meta->get_all_attributes ) {
        next unless my $check = $attr->{leak_check};
        my $name = $attr->name;

        Scalar::Util::weaken $self->{$name};
        next unless $self->{$name};

        if ( ref $check && Scalar::Util::reftype $check eq 'CODE' ) {
            $self->$check( $name, \($self->{$name}) );
        }
        else {
            warn "External ref to attribute '$name' detected on instance '$self'";
        }
    }
};

1;

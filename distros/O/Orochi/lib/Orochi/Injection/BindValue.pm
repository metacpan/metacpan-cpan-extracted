package Orochi::Injection::BindValue;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::clean -except => qw(meta);

with 'Orochi::Injection';

subtype 'Orochi::Injection::BindValue::BindTo'
    => as 'ArrayRef'
    => message { "must be an array of bind names" }
;
coerce 'Orochi::Injection::BindValue::BindTo'
    => from 'Str'
    => via {
        return [ $_ ];
    }
;

has bind_to => (
    is => 'ro',
    isa => 'Orochi::Injection::BindValue::BindTo',
    coerce => 1,
    required => 1
);

sub BUILDARGS {
    my $class = shift;

    return @_ == 1 ? { bind_to => $_[0] } : { @_ };
}

sub expand {
    my ($self, $c) = @_;

    my $value;
    foreach my $bind_to (@{ $self->bind_to }) {
        $value = $c->get($bind_to);
        last if defined $value;
    }

    if (Orochi::DEBUG()) {
        Orochi::_debug("BindValue '%s' expands to %s\n", join('|', @{$self->bind_to}), $value || '(null)');
    }
    return defined $value ? $value : ();
}

__PACKAGE__->meta->make_immutable();

1;

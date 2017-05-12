package MouseX::AttributeHelpers::Base;
use Mouse;

extends 'Mouse::Meta::Attribute';

has 'method_constructors' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

around 'install_accessors' => sub {
    my ($next, $attr, @args) = @_;

    $attr->$next(@args);

    my $metaclass    = $attr->associated_class;
    my $name         = $attr->name;
    my $constructors = $attr->method_constructors;

    # curries
    my %curries = %{ $attr->{curries} || {} };
    while (my ($key, $curry) = each %curries) {
        next unless my $constructor = $constructors->{$key};

        my $code = $constructor->($attr, $name);

        while (my ($aliased, $args) = each %$curry) {
            if ($metaclass->has_method($aliased)) {
                my $classname = $metaclass->name;
                $attr->throw_error("The method ($aliased) already exists in class ($classname)");
            }

            my $method = do {
                if (ref $args eq 'ARRAY') {
                    $attr->_make_curry($code, @$args);
                }
                elsif (ref $args eq 'CODE') {
                    $attr->_make_curry_with_sub($code, $args);
                }
                else {
                    $attr->throw_error("curries parameter must be ref type HASH or CODE");
                }
            };

            $metaclass->add_method($aliased => $method);
            $attr->associate_method($aliased);
        }
    }

    # provides
    my %provides = %{ $attr->{provides} || {} };
    while (my ($key, $aliased) = each %provides) {
        next unless my $constructor = $constructors->{$key};

        if ($metaclass->has_method($aliased)) {
            my $classname = $metaclass->name;
            $attr->throw_error("The method ($aliased) already exists in class ($classname)");
        }

        $metaclass->add_method($aliased => $constructor->($attr, $name));
        $attr->associate_method($aliased);
    }

    return;
};

around '_process_options' => sub {
    my ($next, $class, $name, $args) = @_;

    $args->{is}  = 'rw'                unless exists $args->{is};
    $args->{isa} = $class->helper_type unless exists $args->{isa};

    unless (exists $args->{default} or exists $args->{builder} or exists $args->{lazy_build}) {
        $args->{default} = $class->helper_default if defined $class->helper_default;
    }

    $class->$next($name, $args);
    return;
};

sub helper_type    {}
sub helper_default {}

sub _make_curry {
    my $self = shift;
    my $code = shift;
    my @args = @_;
    return sub {
        my $self = shift;
        $code->($self, @args, @_);
    };
}

sub _make_curry_with_sub {
    my $self = shift;
    my $body = shift;
    my $code = shift;
    return sub {
        my $self = shift;
        $code->($self, $body, @_);
    };
}

# Mouse does not support proper imetaclass constructor replacement,
# so we must set inline_constructor false
no Mouse;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__END__

=head1 NAME

MouseX::AttributeHelpers::Base - Base class for attribute helpers

=head1 METHODS

=head2 method_constructors

=head2 helper_type

=head2 helper_default

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse::Meta::Attribute>

=cut

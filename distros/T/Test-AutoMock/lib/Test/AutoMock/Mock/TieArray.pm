package Test::AutoMock::Mock::TieArray;
use strict;
use warnings;

sub TIEARRAY {
    my ($class, $manager) = @_;

    bless \$manager => $class;
}

sub FETCH {
    my ($self, $key) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;
    my $method_name = "[$key]";

    $manager->_call_method($method_name, [], sub {
        my $self = shift;
        $arrayref->[$key] = $manager->child($method_name)->mock
                                               unless exists $arrayref->[$key];
        $arrayref->[$key];
    });
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method("[$key]", [$value], sub {
        my ($self, $value) = @_;
        $arrayref->[$key] = $value;
    });
}

sub FETCHSIZE {
    my $self = shift;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(FETCHSIZE => [], sub {
        my $self = shift;
        $#$arrayref + 1;
    });
}

sub STORESIZE {
    my ($self, $count) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(STORESIZE => [$count], sub {
        my ($self, $count) = @_;
        $#$arrayref = $count - 1;
    });
}

sub CLEAR {
    my $self = shift;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(CLEAR => [], sub {
        my $self = shift;
        @$arrayref = ();
    });
}

sub PUSH {
    my ($self, @list) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(PUSH => \@list, sub {
        my ($self, @list) = @_;
        push @$arrayref, @list;
    });
}

sub POP {
    my $self = shift;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(POP => [], sub {
        my $self = shift;
        pop @$arrayref;
    });
}

sub SHIFT {
    my $self = shift;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(SHIFT => [], sub {
        my $self = shift;
        shift @$arrayref;
    });
}

sub UNSHIFT {
    my ($self, @list) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(UNSHIFT => \@list, sub {
        my ($self, @list) = @_;
        unshift @$arrayref, @list;
    });
}

sub SPLICE {
    my ($self, $offset, $length, @list) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(SPLICE => [$offset, $length, @list], sub {
        my ($self, $offset, $length, @list) = @_;
        splice @$arrayref, $offset, $length, @list;
    });
}

sub EXTEND {
    my ($self, $count) = @_;
    my $manager = $$self;

    $manager->_call_method(EXTEND => [$count], sub {
        my ($self, $count) = @_;
        # NOP
    });
}

sub DELETE {
    my ($self, $key) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(DELETE => [$key], sub {
        my ($self, $key) = @_;
        delete $arrayref->[$key];
    });
}

sub EXISTS {
    my ($self, $key) = @_;
    my $manager = $$self;
    my $arrayref = $manager->tie_array;

    $manager->_call_method(EXISTS => [$key], sub {
        my ($self, $key) = @_;
        exists $arrayref->[$key];
    });
}

# sub DESTROY {
#     my $self = shift;
#     $self->SUPER::DESTROY(@_);
# }

# sub UNTIE {
#     my $self = shift;
#     # NOP
# }

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Mock::TieArray - Track operations to array-ref

=head1 DESCRIPTION

This module is part of L<Test::AutoMock::Mock::Overloaded> and tracks
operations to array-refs. You won't instantiate this class.

For the sake of simplicity, we use the notation C<[index]> for C<FETCH> and
C<STORE>. For other tie methods, record with the original name.

See https://perldoc.perl.org/perltie.html#Tying-Arrays .

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut


BEGIN {
    # A hack to suppress redefined warning caused by circulation dependency
    $INC{'Test/AutoMock/Mock/Basic.pm'} //= do {
        require File::Spec;
        File::Spec->rel2abs(__FILE__);
    };
}

package Test::AutoMock::Mock::Basic;
use strict;
use warnings;
use Scalar::Util ();
use Test::AutoMock::Mock::Functions ();

sub isa {
    my $class_or_self = shift;
    my ($name) = @_;

    # don't look for isa if $self is a class name
    if (Scalar::Util::blessed $class_or_self) {
        my $manager =
            Test::AutoMock::Mock::Functions::get_manager $class_or_self;
        return 1 if $manager->{isa}{$name};
    }

    $class_or_self->SUPER::isa(@_);
}

sub DESTROY {}

sub AUTOLOAD {
    my ($self, @params) = @_;
    (my $meth = our $AUTOLOAD) =~ s/.*:://;

    my $manager = Test::AutoMock::Mock::Functions::get_manager $self;
    $manager->_call_method($meth => \@params, undef);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Mock::Basic

=head1 DESCRIPTION

The mock class. Only C<isa>, C<DESTROY>, C<AUTOLOAD> methods are implemented.
You operate this class with the function defined in
L<Test::AutoMock::Mock::Functions>.

Do not instantiate this class directly. Use L<Test::AutoMock::mock> instead.

=head1 SEE ALSO

=over 4

=item L<Test::MockObject>

=item L<Test::AutoMock::Mock::Functions>

=back

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut


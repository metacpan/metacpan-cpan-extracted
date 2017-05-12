package MouseX::Param;

use 5.8.1;
use Mouse::Role;

our $VERSION = '0.01';

has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

sub param {
    my $self = shift;

    return keys %{ $self->params } if @_ == 0;
    return $self->params->{+shift} if @_ == 1;

    my %params = @_;
    while (my ($key, $value) = each %params) {
        $self->params->{$key} = $value;
    }
}

no Mouse::Role; 1;

=head1 NAME

MouseX::Param - A Mouse role for manipulating params

=head1 SYNOPSIS

    package MyApp;
    use Mouse;
    with 'MouseX::Param';

    package main;

    my $app = MyApp->new(params => {
        foo => 10,
        bar => 20,
    });

    # getting params
    $app->param('foo'); # 10

    # getting list of params
    $app->param(); # foo, bar

    # setting params
    $app->param(foo => 30, bar => 40);

=head1 DESCRIPTION

MouseX::Param is a simple Mouse role which provides a L<CGI> like
C<param> method.

=head1 METHODS

=head2 param

=head1 PROPERTIES

=head2 params

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

Stevan Little, L<MooseX::Param/AUTHOR>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse>, L<MooseX::Param>

=cut

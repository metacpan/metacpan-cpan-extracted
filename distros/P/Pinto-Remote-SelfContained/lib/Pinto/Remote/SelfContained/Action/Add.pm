package
    Pinto::Remote::SelfContained::Action::Add; # hide from PAUSE

use v5.10;
use Moo;

use Carp qw(croak);
use Pinto::Remote::SelfContained::Types qw(SingleBodyPart);

use namespace::clean;

our $VERSION = '0.900';

extends qw(Pinto::Remote::SelfContained::Action);

has archives => (is => 'ro', isa => SingleBodyPart, required => 1);

around BUILDARGS => sub {
    my ($orig, $class, @rest) = @_;

    my $args = $class->$orig(@rest);

    $args->{args}{author} //= $ENV{PINTO_AUTHOR_ID}
        if defined $ENV{PINTO_AUTHOR_ID};

    $args->{archives} //= delete $args->{args}{archives};

    return $args;
};

around _make_body_parts => sub {
    my ($orig, $self) = @_;

    my $body = $self->$orig;
    my $archives = $self->archives;
    push @$body, @$archives;

    return $body;
};

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Action::Add - add a distribution to a the repository

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut

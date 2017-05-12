package Opsview::REST::Acknowledge;
{
  $Opsview::REST::Acknowledge::VERSION = '0.013';
}

use Moo;

has base => (
    is       => 'ro',
    default  => sub { '/acknowledge' },
    init_arg => undef,
);

with 'Opsview::REST::QueryBuilder';

sub BUILDARGS {
    my $class = shift;
    return {
        args => { @_ },
    };
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

Opsview::REST::Acknowledge - Convenience object to transform its attributes into an /acknowledge URL endpoint

=head1 SYNOPSIS

    use Opsview::REST::Acknowledge;

    my $acknowledge = Opsview::REST::Acknowledge->new(
        host   => [qw/ hostA hostB /], 
    );
    $acknowledge->as_string; # '/acknowledge?host=hostA&host=hostB'

=head1 DESCRIPTION

You shouldn't be calling this directly, but be using the "ack" method in L<Opsview::REST>.

=head1 AUTHOR

=over 4

=item *

Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

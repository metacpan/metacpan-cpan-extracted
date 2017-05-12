package Opsview::REST::Status;
{
  $Opsview::REST::Status::VERSION = '0.013';
}

use Moo;

has base => (
    is       => 'ro',
    default  => sub { '/status/' },
    init_arg => undef,
);

with 'Opsview::REST::QueryBuilder';

has '+path' => (
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

Opsview::REST::Status - Convenience object to transform its attributes into a /status URL endpoint

=head1 SYNOPSIS

    use Opsview::REST::Status;

    my $status = Opsview::REST::Status->new(
        'host',
        host   => [qw/ hostA hostB /], 
        filter => 'unhandled',
    );
    $status->as_string; # '/status/host?filter=unhandled&host=hostA&host=hostB'

=head1 DESCRIPTION

You shouldn't be calling this directly, but be using the "status" method in L<Opsview::REST>.

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

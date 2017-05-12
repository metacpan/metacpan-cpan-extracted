package Opsview::REST::Recheck;
{
  $Opsview::REST::Recheck::VERSION = '0.013';
}

use Moo;

has base => (
    is       => 'ro',
    default  => sub { '/recheck' },
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

Opsview::REST::Recheck - Convenience object to transform its attributes into a /recheck URL endpoint

=head1 SYNOPSIS

    use Opsview::REST::Recheck;

    my $status = Opsview::REST::Status->new(
        host   => [qw/ hostA hostB /],
    );
    $status->as_string; # '/status/?host=hostA&host=hostB'

=head1 DESCRIPTION

You shouldn't be calling this directly, but be using the "recheck" method in L<Opsview::REST>.

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

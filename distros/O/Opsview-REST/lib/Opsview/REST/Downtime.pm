package Opsview::REST::Downtime;
{
  $Opsview::REST::Downtime::VERSION = '0.013';
}

use Moo;

has base => (
    is       => 'ro',
    default  => sub { '/downtime' },
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

Opsview::REST::Status - Convenience object to transform its attributes into a /downtime URL endpoint

=head1 SYNOPSIS

    use Opsview::REST::Downtime;

    my $dwnt = Opsview::REST::Downtime->new();
    $dwnt->as_string; # '/downtime'

=head1 DESCRIPTION

You shouldn't be calling this directly, but be using the "downtime" method in L<Opsview::REST>.

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

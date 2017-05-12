package Opsview::REST::Event;
{
  $Opsview::REST::Event::VERSION = '0.013';
}

use Moo;

has base => (
    is       => 'ro',
    default  => sub { '/event' },
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

Opsview::REST::Event - Convenience object to transform its attributes into a /event valid query

=head1 SYNOPSIS

    use Opsview::REST::Event;

    my $event = Opsview::REST::Event->new(
        host      => [qw/ hostA hostB /], 
        startTime => '2012-01-12 19:42:22'
    );
    
    $event->as_string; # '/event?startTime=2012-01-12%2019:42:22&host=hostA&host=hostB'

=head1 DESCRIPTION

You shouldn't be calling this directly, but be using the "events" method in L<Opsview::REST>.

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

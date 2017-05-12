package ShardedKV::Error::ConnectFail;
$ShardedKV::Error::ConnectFail::VERSION = '0.20';
use Moose;
extends 'ShardedKV::Error';

#ABSTRACT: Thrown when connection exceptions occur.

1;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

=pod

=head1 NAME

ShardedKV::Error::ConnectFail - Thrown when connection exceptions occur.

=head1 VERSION

version 0.20

=head1 DESCRIPTION

ShardedKV::Error::ConnectFail is thrown when an exception occurs connecting to
a particular resource. It adds no other attributes beyond what is provided in
the base class: L<ShardedKV::Error>. Please see that module for more
information.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# vim: ts=2 sw=2 et

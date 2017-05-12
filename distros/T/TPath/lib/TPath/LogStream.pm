package TPath::LogStream;
$TPath::LogStream::VERSION = '1.007';
# ABSTRACT: role of log-like things


use Moose::Role;


requires 'put';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::LogStream - role of log-like things

=head1 VERSION

version 1.007

=head1 DESCRIPTION

Behavior required by object to which L<TPath::Forester> delegates logging.

=head1 METHODS

=head2 put

Prints a message to the log.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

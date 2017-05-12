package Purple::Server;

use warnings;
use strict;
our $VERSION = '0.9';

my $DEFAULT_SERVER = 'REST';

sub new {
    my $class = shift;
    my %p = @_;

    $p{type} ||= $DEFAULT_SERVER;

    my $real_class = 'Purple::Server::' . $p{type};
    unless ( $real_class->can('_New') ) {
        eval "require $real_class";
        die "Unable to load $real_class: $@" if $@;
    }
    delete $p{type};

    return $real_class->_New(%p);
}

=head1 NAME

Purple::Server - Factory class for generating servers for Purple Numbers

=head1 VERSION

Version 0.9

=head1 SYNOPSIS

See the default implementation L<Purple::Server::REST>.

=head1 METHODS

=head2 new(%options)

You can specify an alternative server by passing:

  type => 'server'

where 'server' is the name of the server type. If you don't pass this
parameter, it will default to REST.

=head1 AUTHOR

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Purple

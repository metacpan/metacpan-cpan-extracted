package Purple;

use warnings;
use strict;

our $VERSION = '1.4';

my $DEFAULT_TYPE = 'SQLite';

# XXX these are not what they look like
# make this an explicit factory
sub new {
    my $class = shift;
    my %p = @_;

    $p{type} ||= $DEFAULT_TYPE;

    my $real_class = 'Purple::' . $p{type};
    unless ( $real_class->can('_New') ) {
        eval "require $real_class";
        die "Unable to load $real_class: $@" if $@;
    }

    # store is a directory
    return $real_class->_New(store => $p{store});
}

=head1 NAME

Purple - Distributed granular addresses on the web

=head1 VERSION

Version 1.4

=head1 SYNOPSIS

Factory class for generating purple numbers.

    use Purple;

    my $p = Purple->new;  # by default, uses SQLite backend
    ...

=head1 METHODS

=head2 new(%options)

You can specify a different backend by passing:

  type => 'backend'

where 'backend' is the name of the backend. If you don't pass any
parameters, uses SQLite by default.

=head1 AUTHOR

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Purple

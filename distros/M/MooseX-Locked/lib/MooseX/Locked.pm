package MooseX::Locked;

use 5.008;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.01';

use Moose ();

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        class => [
            'MooseX::Locked::Class',
        ],
    },
    role_metaroles => {
        application_to_class => [
            'MooseX::Locked::ApplicationToClass',
        ],
    },
);

1; # End of MooseX::Locked
__END__

=head1 NAME

MooseX::Locked - Moose role to automatically lock object hashes

=head1 VERSION

version 1.01

=head1 SYNOPSIS

By default, Moose creates objects as unlocked hashes.  This lets attribute
typos go unchecked.  If you use MooseX::Locked in your Moose classes, any
typos when accessing object attributes will be detected and throw exceptions.

    use Moose;
    use MooseX::Locked;

    has foo => ( is => 'ro' );

    ...

    sub thing_that_sets_foo {
        my ($self) = @_;
        ...
        $self->{oof} = 1;    # RUNTIME EXCEPTION
    }

According to Moose's authors, you should never access attributes directly in
this way.  But when converting legacy code, eliminating direct hash accesses
may be inconvenient, if not impossible.  And I've found that the speed gain
is sometimes impossible to resist.  In such circumstances, or if you simply
want to protect against others falling into temptation, you may find this
module helpful.

Note that this module provides a metarole (i.e. a role on the metaclass),
not a role.  Your objects will not report C<-E<gt>does('MooseX::Locked')>.

=head1 CAVEATS

If your code modifies the Moose attribute list after any objects are
created, then you should avoid this class for now and report your use case
in a ticket.  It's possible that the code needs to be changed to serve you
better.  Or maybe it's just not for you.  :)

Locked hashes use more memory than their unlocked equivalents.  If you're
going to have a LOT of a given class around, you may not want to use this
role.  But test first -- human intuition is not an effective profiler.

=head1 AUTHOR

Chip Salzenberg, C<< <chip at pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-locked at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Locked>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Locked

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Locked>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Locked>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Locked>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Locked/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Chip Salzenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

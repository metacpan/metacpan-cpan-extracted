package Net::Tomcat::JVM;

use strict;
use warnings;

our @ATTR       = qw(free_memory total_memory max_memory);

foreach my $attr ( @ATTR ) {{
        no strict 'refs';
        *{ __PACKAGE__ . '::' . $attr } = sub { my $self = shift; return $self->{$attr} }
}}

sub new {
        my ( $class, %args ) = @_;

        my $self = bless {}, $class;
        $self->{$_} = $args{$_} for @ATTR;
        $self->{__timestamp} = time;

        return $self;
}

sub __timestamp { return $_[0]->{__timestamp} }

1;

__END__

=head1 NAME

Net::Tomcat::JVM - Utility class for representing Apache Tomcat JVM objects.

=cut

=head1 SYNOPSIS

Net::Tomcat::JVM - Utility class for representing Apache Tomcat JVM objects.

Note that you should not need to create a Net::Tomcat::JVM obejct directly,
rather one will be created for you implicitly on invocation of methods in other
classes - e.g. the I<jvm()> method in the Net::Tomcat class.

=head1 METHODS

=head2 free_memory

Returns the amount of free memory available.

=head2 total_memory

Returns the total amount of memory available.

=head2 max_memory

Returns the maximum amount of allocatable memory.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/ltp/Net-Tomcat>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-tomcat-jvm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Tomcat-JVM>.  I will 
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Net::Tomcat>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Tomcat::JVM

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat-JVM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat-JVM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat-JVM>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat-JVM/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

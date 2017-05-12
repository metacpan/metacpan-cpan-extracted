package Monitis::InternalMonitors;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub delete {
    my ($self, @params) = @_;

    my @mandatory = qw/testIds type/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('deleteInternalMonitors' => $params);
}

sub get_all {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/types tag tagRegExp/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('internalMonitors' => $params);
}

__END__

=head1 NAME

Monitis::InternalMonitors - Internal monitors manipulation

=head1 SYNOPSIS

    use Monitis::InternalMonitors;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::InternalMonitors> implements following attributes:

=head1 METHODS

L<Monitis::InternalMonitors> implements following methods:

=head2 get_all

    my $response = $api->internal_monitors->get_all;

Get monitors info.

Optional parameters:

    types tag tagRegExp

Response:

    Please, refer to documentation:

    L<http://monitis.com/api/api.html#getInternalMonitors>

=head2 delete

    my $response = $api->internal_monitors->delete(
        testIds => '12345,1236',
        type    => 4               # HTTP
    );

Delete monitor.

Mandatory parameters:

    testIds type

Normal response is:

    {"status" => "ok"}


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#getInternalMonitors>


=head1 AUTHOR

Yaroslav Korshak  C<< <ykorshak@gmail.com> >>
Alexandr Babenko  C<< <foxcool@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2011, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

package Solstice::Model::X509;

# $Id: $

=head1 NAME

Solstice::Model::X509

=head1 SYNOPSIS

    use Solstice::Model::X509;

    my $model = ServiceManager::Model::X509->new();


=head1 DESCRIPTION

Manages reading the values from an X509 cert used to authenticate the current service user.

=cut

use strict;
use warnings;
use 5.006_000;

use Crypt::X509 qw(); #crypt x509 exports some irritating things, and we only use it oo style, so I disable exports
use MIME::Base64;

use base qw(Solstice::Model);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4


=item new()

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return unless $self->_init();

    return $self;
}

=back

=head2 Private Methods

=over 4

=cut

=item _init()

Intialized the object based on the SSL data in ENV.

=cut

sub _init {
    my $self = shift;

    my $cn = $ENV{'SSL_CLIENT_S_DN_CN'};
    return unless defined $cn;
    $self->_setCN($cn);

    my $cert = $ENV{'SSL_CLIENT_CERT'};

    if (defined $cert) {
        $cert =~ s/^-----BEGIN CERTIFICATE-----//;
        $cert =~ s/-----END CERTIFICATE-----$//;
        $cert = decode_base64($cert);
        my $decoded_cert = Crypt::X509->new(cert => $cert);
        $self->_setSubjectAltName($decoded_cert->SubjectAltName);
    }
    return TRUE;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
    {
        name        => 'CN',
        key         => '_c_n',
        type        => 'String',
    },
    {
        name        => 'SubjectAltName',
        key         => '_subject_alt_name',
        type        => 'ArrayRef',
    },

    ];
}


1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

=head1 SEE ALSO

L<Solstice::Model>,
L<Solstice::Model>,
L<perl>.

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

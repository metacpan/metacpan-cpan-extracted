package Net::Amazon::S3::ACL::Grant::URI;

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

use base qw(Net::Amazon::S3::ACL::Grant);
__PACKAGE__->mk_accessors(qw( URI ));

# Module implementation here
sub parse_grantee {
   my ($self, $xpc, $node) = @_;

   my $URI = $xpc->findvalue('.//s3:Grantee/s3:URI', $node)
      or croak 'no URI grant in provided node';
   $self->URI($URI);

   (my $key = $URI) =~ s{.*/}{}mxs;
   $key =
         ($key eq 'AllUsers')           ? 'ALL'
       : ($key eq 'AuthenticatedUsers') ? 'AUTH'
       :                                   $URI;
   $self->key($key);

   return $self;
} ## end sub _parse_acl_grant

my (%canonical_key_for, %URI_for);

BEGIN {
   %canonical_key_for = (
      'AUTHENTICATED' => 'AUTH',
      'AUTH'          => 'AUTH',
      'ALL'           => 'ALL',
      'ANY'           => 'ALL',
      'ANONYMOUS'     => 'ALL',
      'ANON'          => 'ALL',
      '*'             => 'ALL',
   );
   %URI_for = (
      AUTH => 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers',
      ALL  => 'http://acs.amazonaws.com/groups/global/AllUsers',
   );
}

sub canonical_key_for {
   my ($self, $key) = @_;
   if (my ($type) = $key =~ m{\A http://.*/(All | Authenticated)Users \z}imxs) {
      $key = $type;
   }
   croak "no canonical name for '$key'"
      unless exists $canonical_key_for{uc $key};
   return $canonical_key_for{uc $key};
}

sub populate_from_target {
   my ($self, $target) = @_;

   $target = $self->canonical_key_for($target);
   $self->key($target);
   $self->URI($URI_for{$target});

   return $self;
}

sub _set_key {
    $_[0]->key($_[0]->canonical_key_for($_[0]->URI())); 
}

sub stringify_grantee {
   my ($self) = @_;
   my $URI = $self->URI();
   return <<"END_OF_GRANTEE";
<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
   <URI>$URI</URI>
</Grantee>
END_OF_GRANTEE
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Net::Amazon::S3::ACL::Grant::URI - URI grant representation

=head1 SYNOPSIS

   use Net::Amazon::S3::ACL::Grant::URI;

   my $grant = Net::Amazon::S3::ACL::Grant::ID->new();
   $grant->populate_from_target('ALL');
   $grant->permissions('READ');


=head1 DESCRIPTION

The URI grant representation is used when ACLs have to be given to
groups of users. At the moment, only two groups are defined by Amazon:
one matching all the possible users, and one matching all users
authenticated in the Amazon S3 service. Each group is identified
through a URI.

=head1 INTERFACE 

The following accessors are available:

=over

=item B<< URI >>

The URI representing the grantee. As of EoY 2008, only two URIs are
allowed:

      http://acs.amazonaws.com/groups/global/AuthenticatedUsers
      http://acs.amazonaws.com/groups/global/AllUsers


=back

See L<Net::Amazon::S3::ACL::Grant/GRANT CLASSES> for details on the
general interface offered by this module. In addition, this class also
provides the following method:

=over

=item B<< canonical_key_for >>

   my $canonical = $grant->canonical_key_for($key);

As explained in L<Net::Amazon::S3::ACL::Grant/canonical>, if you want to
set a grant for a group you can use different variants, like C<ALL>,
C<*>, or the URIs for the group. This method canonicalises the input key
and returns one of C<ALL> or C<AUTH>, depending on the input key.

=back

=begin pod_coverage

=over

=item B<< parse_grantee >>

=item B<< populate_from_target >>

=item B<< stringify_grantee >>

=back

=end pod_coverage


=head1 DIAGNOSTICS

=over

=item C<< no URI grant in provided node >>

The C<$node> parameter in method L<Net::Amazon::S3::ACL::Grant/parse_grantee>
does not contain an URI. This means that the XML representation of the
grant is *not* one handled by this subclass.

=item C<< no canonical name for '%s' >>

This error is given by L</canonical_key_for> when the provided
parameter does not match any of the possible aliases for either
C<ALL> or C<AUTH>. See L<Net::Amazon::S3::ACL::Grant> to find out
which are the allowed values.

Note that this error is also thrown by 
L<Net::Amazon::S3::ACL::Grant/populate_from_target>, which uses
L</canonical_key_for> under the hood.

=back

=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.x itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl 5.8.x stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


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

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=head1 SEE ALSO

L<Net::Amazon::S3>, L<Net::Amazon::S3::ACL>, L<Net::Amazon::S3::ACL::Grant>.

=cut

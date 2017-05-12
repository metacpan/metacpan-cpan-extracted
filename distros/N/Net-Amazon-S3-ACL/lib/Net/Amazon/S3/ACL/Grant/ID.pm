package Net::Amazon::S3::ACL::Grant::ID;

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

use base qw(Net::Amazon::S3::ACL::Grant);
__PACKAGE__->mk_accessors(qw( ID displayname ));

# Module implementation here
sub parse_grantee {
   my ($self, $xpc, $node) = @_;

   my $id = $xpc->findvalue('.//s3:Grantee/s3:ID', $node)
      or croak 'no ID grant in provided node';
   $self->ID($id);
   $self->key($id);

   my $name = $xpc->findvalue('.//s3:Grantee/s3:DisplayName', $node);
   $self->displayname($name);

   return $self;
} ## end sub _parse_acl_grant

sub populate_from_target {
   my ($self, $target) = @_;
   $self->ID($target);
   $self->displayname(undef);
   $self->key($target);
   return $self;
}

sub _set_key { $_[0]->key($_[0]->ID()); }

sub stringify_grantee {
   my ($self) = @_;

   # The DisplayName attribute is actually ignored by AWS, but for
   # sake of completeness we're including it here
   my $id = $self->ID();
   my $displayname = $self->displayname();
   $displayname = '' unless defined $displayname;
   return <<"END_OF_GRANTEE";
<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
   <ID>$id</ID>
   <DisplayName>$displayname</DisplayName>
</Grantee>
END_OF_GRANTEE
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Net::Amazon::S3::ACL::Grant::ID - ID grant representation

=head1 SYNOPSIS

   use Net::Amazon::S3::ACL::Grant::ID;

   my $grant = Net::Amazon::S3::ACL::Grant::ID->new(
      {
         ID => 'some-amazon-ID',
         displayname => 'mainly ignored',
         permissions => qw[ 'READ' ],
      }
   );

=head1 DESCRIPTION

The ID grant representation is used when the grant is given
to a specific customer of the Amazon S3 service.

=head1 INTERFACE 

The following accessors are available:

=over

=item B<< ID >>

the Amazon S3 identifier for the grantee.

=item B<< displayname >>

this is used mainly to read the displayname as sent by Amazon, it has
no impact when setting ACLs.

=back

See L<Net::Amazon::S3::ACL::Grant/GRANT CLASSES> for details on the
general interface offered by this module.

=begin pod_coverage

=over

=item B<< parse_grantee >>

=item B<< populate_from_target >>

=item B<< stringify_grantee >>

=back

=end pod_coverage


=head1 DIAGNOSTICS

=over

=item C<< no ID grant in provided node >>

The C<$node> parameter in method L<Net::Amazon::S3::ACL::Grant/parse_grantee>
does not contain an ID. This means that the XML representation of the
grant is *not* one handled by this subclass.

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

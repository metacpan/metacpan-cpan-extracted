package Net::Amazon::S3::ACL;

use warnings;
use strict;
use version; our $VERSION = qv('0.1.0');

use Carp;
use English qw( -no_match_vars );
use Net::Amazon::S3::ACL::XMLHelper qw( xpc );
use Net::Amazon::S3::ACL::Grant;
use Scalar::Util qw( blessed );

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw( owner_id owner_displayname grants ));

# Module implementation here
sub new {
   my $class = shift;

   my $params = shift || {};
   my $xml    = delete $params->{xml};
   my $self   = $class->SUPER::new($params);

   $self->parse($xml) if defined $xml;
   $self->grants({}) unless $self->grants();

   return $self;
} ## end sub new

sub parse {
   my ($self, $xml) = @_;
   my $xpc = xpc($xml);

   $self->owner_id($xpc->findvalue('//s3:Owner/s3:ID'));
   $self->owner_displayname($xpc->findvalue('//s3:Owner/s3:DisplayName'));

   my %grants = map {
      my $grant = Net::Amazon::S3::ACL::Grant->create(
         {
            xpc => $xpc,
            node => $_,
         }
      );
      ($grant->key() => $grant);
   } $xpc->findnodes('.//s3:AccessControlList/s3:Grant');
   $self->grants(\%grants);

   return $self;
} ## end sub parse

sub delete {
   my $self = shift;
   if (@_ == 1 && blessed($_[0])) {
      $self->_delete(undef, @_);
      return $self;
   }

   my @grants = ref $_[0] ? %{$_[0]} : @_;
   while (my ($target, $item) = splice @grants, 0, 2) {
      $self->_delete($target, $item);
   }
   return $self;
}

sub _delete {
   my $self = shift;
   my $item = Net::Amazon::S3::ACL::Grant->canonical(@_);
   #use Data::Dumper; warn Dumper $item;
   my $target = $item->key();

   my $grants = $self->grants() or return;
   my $perms = $item->{permissions} || [];
   if (scalar(@$perms)) {
      my $previous = $grants->{$target} or return;
      my %forbidden = map { $_ => 1 } @$perms;
      $previous->{permissions} =
        [grep { !$forbidden{$_} } @{$previous->{permissions} || []}];
      delete $grants->{$target} unless @{$previous->{permissions}};
   } ## end if (defined($item->{permissions...
   else {
      #use Data::Dumper; warn Dumper($grants, \$target);
      delete $grants->{$target};
   }
   return;
} ## end sub _delete

sub add {
   my $self = shift;
   if (@_ == 1 && blessed($_[0])) {
      $self->_add(undef, @_);
      return $self;
   }

   my @grants = ref $_[0] ? %{$_[0]} : @_;
   while (my ($target, $item) = splice @grants, 0, 2) {
      $self->_add($target, $item);
   }
   return $self;
} ## end sub add

sub _add {
   my $self = shift;
   my $item = Net::Amazon::S3::ACL::Grant->canonical(@_);
   #use Data::Dumper; warn Dumper $item;
   my $target = $item->key();

   my $grants = $self->grants();
   $self->grants($grants = {}) unless $grants;

   my $previous = $grants->{$target} ||= $item;
   my %flag;    # to filter out duplicates
   $previous->{permissions} = [
      grep { !$flag{$_}++ } @{$previous->{permissions} || []},
      @{$item->{permissions} || []}
   ];

   delete $grants->{$target} unless @{$previous->{permissions}};
   return;
} ## end sub _add

sub stringify {
   my $self = shift;

   my $owner_chunk  = $self->_stringify_owner();
   my $grants_chunk = $self->_stringify_grants();

   # Indent for pretty printing
   s/^/   /mxsg for $owner_chunk, $grants_chunk;

   return <<"END_OF_ACL";
<?xml version="1.0" encoding="UTF-8"?>
<AccessControlPolicy>
$owner_chunk$grants_chunk
</AccessControlPolicy>
END_OF_ACL
} ## end sub stringify

sub _stringify_owner {
   my ($self) = @_;

   defined(my $owner_id = $self->owner_id()) or return '';
   my $owner_displayname = $self->owner_displayname();
   $owner_displayname = '' unless defined $owner_displayname;

   return <<"END_OF_OWNER";
<Owner>
   <ID>$owner_id</ID>
   <DisplayName>$owner_displayname</DisplayName>
</Owner>
END_OF_OWNER
} ## end sub _stringify_owner

sub _stringify_grants {
   my ($self) = @_;

   my $list = join "\n",
     map { $_->stringify(); } 
     grep { $_->is_valid()} 
     values %{$self->grants()};

   $list =~ s/^/   /mxsg;    # indented
   return "<AccessControlList>\n$list\n</AccessControlList>";
} ## end sub _stringify_acl

sub dump {
   my $self = shift;

   eval {
      require YAML;
      return YAML::Dump({
         grants => $self->grants(),
         owner  => {
            id => $self->owner_id(),
            displayname => $self->owner_displayname(),
         },
      });
   } or return $self->stringify();
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Net::Amazon::S3::ACL - work with Amazon S3 Access Control Lists

=head1 VERSION

This document describes Net::Amazon::S3::ACL version 0.1.0. Most likely, this
version number here is outdate, and you should peek the source.

=head1 SYNOPSIS

   use Net::Amazon::S3::ACL;

   # analysis. Say you have a Net::Amazon::S3::Bucket...
   my $xml_acl = $bucket->get_acl();
   my $acl = Net::Amazon::S3::ACL->new({xml => $xml_acl});

   # Now you can use it
   print $acl->dump();

   my $owner_id = $acl->owner_id();
   my $owner_display_name = $acl->owner_displayname();

   while (my ($name, $grant) = each %{$acl->grants()}) {
      print "Policy for '$name':\n";

      (my $type = ref $grant) =~ s/.*:://;
      print "   Type: $grant->{type}\n";

      if ($type eq 'ID') {
         print "   AWS ID: ", $grant->id(), "\n";
         print "   AWS Display Name: ", $grant->displayname(), "\n";
      }
      elsif ($type eq 'Email') {
         print "   email address: ", $grant->email(), "\n";
      }
      elsif ($type eq 'URI') {
         print "   group definition URI: ", $grant->URI(), "\n";
      }

      print '   Permissions: ', join(', ', @{$grant->{permissions}}), "\n";
   }

   $acl->clear(); # wipe all grants in ACL object

   # Straightforward addition of permissions, DWIM
   $acl->add(
      'foo@example.com' => 'READ',   # seems email, added as such
      'http://whatever/' => 'WRITE', # seems URI, added as such
      'dafadfda908940394...' => '*', # added as AWS identifier
   );

   # Detailed addition of permissions, e.g. by ID
   my $grant = Net::Amazon::S3::Grant::ID->new(
      {
         ID => 'long-AWS-ID-here',
         displayname => 'display-name-here',
         permissions => [qw( WRITE READ READ_ACP )],
      }
   );
   $acl->add($grant);

   my $ID = 'some-AWS-ID';
   $acl->delete($ID); # remove whole ACL for given ID
   $acl->delete($ID => 'READ'); # remove this permission only
   $acl->delete($ID => [qw( READ WRITE )]); # remove these permissions only

   # install new ACL
   $bucket->set_acl({acl_xml => $acl->stringify()});
   $bucket->set_acl({acl_xml => $acl->stringify(), key => 'whatever'});

=head1 DESCRIPTION

This module represents an S3 Access Control List; it is a representation
of the XML ACL that is easier to handle. As such, there are methods
that ease passing from one representation to the
other, namely L</parse> (to parse an XML document into an object) and
L</stringify> (to get the XML representation of the ACL).

An ACL (or, better, a L<Net::Amazon::S3::ACL> object) contains the
following:

=over

=item B<owner>

the owner of the resource. It is represented by two different fields
in the ACL, each with its accessors, namely:

=over

=item owner_id

that long string that identifies an AWS customer;

=item owner_displayname

the I<DisplayName> in Amazon's terminology.

=back

=item B<grants>

the list of grants that are associated to the resource. It is
represented by a hash reference in which the keys identify the grantee,
and the values are L<Net::Amazon::S3::ACL::Grant> objects (in
particular, each item will be a suitable specialisation of a
grant object).

See L<Net::Amazon::S3::ACL::Grant> and related documentation for
more details.

As a general note, you don't need to bother with grants list internals
if you want to set it: just use the L</add>, L</delete> and L</clear>
convienience methods, that try to DWIM.

=back

=head1 INTERFACE 

=over

=item B<< new >>

create a new ACL object. You can pass initialisation values for the
members via a configuration hash (this can be useful if you want to
do a shallow copy of another ACL object), or an XML document to parse:

=over

=item owner_id

=item owner_displayname

these are what you already suspect.

=item grants

a hash reference pointing to the grants.

=item xml

if passed, the L</parse> method is called to initialise the object. This
overrides any parameter given in the configuration hash.

=back

Returns a reference to the new ACL object.

=item B<< parse >>

parse an XML document and fill the ACL in. The previous contents of the
ACL object are wiped, if any.

Expects a single string with the XML document to parse.

Returns a reference to the ACL document itself.

=item B<< stringify >>

renders the ACL object as an XML document that can be sent to S3.

Does not take parameters.

Returns the XML document.

=item B<< dump >>

renders the ACL object as something readable. If the L<YAML> module
is available, it is used to produce the dump; otherwise the output
of L</stringify> is given back.

=item B<< add >>

adds permissions for a given list of grantees.

Can accept different inputs. If given a single, blessed
parameter, it is assumed to be the grant to be added, so it is
inserted using the output of the C<key> method to get a key
for the grants hash.

Otherwise, it ccepts either a reference to a hash of grants to be added,
or a list which is interpreted as a sequence
of I<target>/I<permissions> pairs:

=over

=item target (or keys in the hashref)

the grantee to which this addition apply. The actual target
will be derived by means of 
L<Net::Amazon::S3::ACL::Grant/canonical>, so you can refer to
items that are represented differently in the acl. For example,
if yo specify a C<*> target, the actual target will be the URI
for the anonymous group. See 
L<Net::Amazon::S3::ACL::Grant/canonical> for more details about
how you can specify a target.

=item permissions (or values in the hashref)

this can be either a string with a single permission to be added,
or an array reference with a list of permissions to be added,
or an acl item (see L</DESCRIPTION> to know how acl items are
structured).

=back

Note that when given as a list, this is B<NOT> transformed into
a hash before the operations. This lets you specify the same
target multiple times, and the permissions for each occurrence will
be taken into account.

Also, note that this method's name is a bit misleading at the moment.
It seems that AWS only supports a single permission for each
grantee, so for example you can't set both READ and READ_ACP permissions
for a given grantee on a given resource. Hopefully, things will change
in the future. The bottom line is that the last thing that you "add"
is the one that is actually set remotely.

=item B<< delete >>

removes permissions for a given list of grantees.

Can accept different inputs. If given a single, blessed
parameter, it is assumed to be the grant to be deleted. Otherwise,
it accepts either a reference to a hash of grants to be deleted,
or a list which is interpreted as a sequence
of I<target>/I<permissions> pairs:

=over

=item target (or keys in the hashref)

the grantee to which this deletion apply. The actual target
will be derived by means of
L<Net::Amazon::S3::ACL::Grant/canonical>, so you can refer to
items that are represented differently in the acl. For example,
if yo specify a C<*> target, the actual target will be the URI
for the anonymous group. See
L<Net::Amazon::S3::ACL::Grant/canonical> for more details about
how you can specify a target.

=item permissions (or values in the hashref, optionally populated)

this can be either a string with a single permission to be removed,
or an array reference with a list of permissions to be removed,
or an acl item (see L</DESCRIPTION> to know how acl items are
structured).

If absent or undef or containing an undefined I<permissions> item,
the whole grant for the target is deleted.

=back

Note that when given as a list, this is B<NOT> transformed into
a hash before the operations. This lets you specify the same
target multiple times, and the permissions for each occurrence will
be taken into account.

=item B<< clear >>

remove all grants in the ACL.

=back

=head1 DIAGNOSTICS

This module does not die and produce diagnostics per-se, but only
as a result of some forbidden operation in L<Net::Amazon::S3::ACL::Grant>
or its descendants. See them for a list of possible diagnostics messages.

=head1 CONFIGURATION AND ENVIRONMENT

Net::Amazon::S3::ACL requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Class::Accessor::Fast> and, where needed, L<version>. For XML
parsing, L<XML::LibXML> and L<XML::LibXML::XPathContext> are needed too.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


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

L<Net::Amazon::S3>.

=cut

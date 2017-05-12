package Net::Amazon::S3::ACL::Grant;

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );
use Scalar::Util qw( blessed );

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw( key permissions ));

our @Classes;
BEGIN {
   @Classes = qw( Email URI ID );
}

# Module implementation here
sub new {
   my $package = shift;
   my $params = shift || {};

   my $self = $package->SUPER::new($params);
   if ($params->{xpc} && $params->{node}) {
      $self->parse($params->{xpc}, $params->{node});
   }
   elsif ($params->{target}) {
      $self->populate_from_target($params->{target});
   }

   $self->_set_key();

   my $permissions = $self->permissions();
   $self->permissions([]);
   $self->add_permissions($permissions) if $permissions;

   return $self;
} ## end sub new

my %permission_normalisation_for = (
   WRITE        => 'WRITE',
   W            => 'WRITE',
   '>'          => 'WRITE',
   READ         => 'READ',
   R            => 'READ',
   '<'          => 'READ',
   FULL_CONTROL => 'FULL_CONTROL',
   'FULL-CONTROL' => 'FULL_CONTROL',
   FULL         => 'FULL_CONTROL',
   F            => 'FULL_CONTROL',
   '*'          => 'FULL_CONTROL',
   'WRITE_ACP'  => 'WRITE_ACP',
   'WP'         => 'WRITE_ACP',
   'WRITE-ACP'  => 'WRITE_ACP',
   'READ_ACP'   => 'READ_ACP',
   'RP'         => 'READ_ACP',
   'READ-ACP'   => 'READ_ACP',
);

sub add_permissions {
   my $self = shift;

   my @input = grep {defined} ref($_[0]) ? @{$_[0]} : @_;
   my @permissions = @{$self->permissions()};
   for my $new_perm (@input) {
      $new_perm = uc $new_perm;
      croak "unknown permission $new_perm"
         unless exists $permission_normalisation_for{$new_perm};
      push @permissions, $permission_normalisation_for{$new_perm};
   }

   my %flag;
   @permissions = grep { ! $flag{$_}++ } @permissions;
   $self->permissions(\@permissions);

   return $self;
}

sub delete_permissions {
   my $self = shift;

   my @input = ref($_[0]) ? @{$_[0]} : @_;
   my %flag = map { 
      croak "unknown permission $_"
         unless exists $permission_normalisation_for{$_};
      $permission_normalisation_for{$_} => 1;
   } @input;

   my @permissions = grep { ! $flag{$_}++ } @{$self->permissions()};
   $self->permissions(\@permissions);

   return $self;
}

sub is_valid { return scalar(@{$_[0]->permissions()}) > 0; }

sub class_for {
   my ($package, $name) = @_;
   $package = ref($package) || $package;
   return join '::', $package, $name;
}

sub create {
   my $package = shift;
   my $params = shift || {};

   croak "not enough parameters to create a grant"
      unless ($params->{xpc} && $params->{node})
         || $params->{target};

   for my $type (@Classes) {
      my $class = $package->class_for($type);
      
      my $sub_new = $class->can('new');
      if (! $sub_new) {
         eval "require $class" or die "no package $class available";
         $sub_new = $class->can('new')
            or die "package $class does not support 'new'";
      }

      my $self;
      $self = eval { $class->$sub_new($params) }
         and return $self;
   }

   require Data::Dumper;
   croak 'no suitable subclass found to handle input data: ',
      Data::Dumper::Dumper($params);
} ## end sub new


sub canonical {
   my ($pack, $target, $item) = @_;

   return $item if blessed $item;

   $target = $target->key() if blessed $target;
   $item = $pack->create(
      {
         target => $target,
         permissions => $item,
      }
   );

   return $item;
}

sub parse {
   my ($self, $xpc, $node) = @_;
   $self->parse_grantee($xpc, $node);
   my @permissions =
      map { $_->to_literal() } $xpc->findnodes('.//s3:Permission', $node);
   $self->permissions(\@permissions);
   return $self;
}

sub stringify {
   my ($self) = @_;

   return '' unless $self->is_valid();

   (my $grantee = $self->stringify_grantee()) =~ s/^/   /mxsg;
   return join "\n", map {
      ;
      "<Grant>\n$grantee   <Permission>$_</Permission>\n</Grant>";
   } @{$self->permissions()};
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::Amazon::S3::ACL::Grant - represent a grant in a S3 ACL

=head1 SYNOPSIS

   # if you have some XPathContext and node...
   my $grant = Net::Amazon::S3::ACL::Grant->create({
      xpc  => $xpc, 
      node => $node,
   });

   # otherwise
   $grant = Net::Amazon::S3::ACL::Grant->create({
      target      => 'foo@example.com',
      permissions => [qw( READ WRITE )],
   });

   # or also
   $grant = Net::Amazon::S3::ACL::Grant->canonical(
      'foo@example.com' => [qw( READ WRITE )],
   );

   # given a $grant...
   my $key = $grant->key();
   my $permissions = $grant->permissions();
   print "permissions for '$key': [@$permissions]\n";

   $grant->add_permissions(qw( READ_ACP WRITE_ACP ));
   $grant->delete_permissions('WRITE');

   die 'invalid!' unless $grant->is_valid();

   $grant->parse($xpc, $node);
   print $grant->stringify();

=head1 DESCRIPTION

This class represents a single grant in the grants hash of
L<Net::Amazon::S3::ACL>. This is actually a base class that has been
specialised into three implementations, representing the three
different ways to specify a grantee in AWS as of writing this.

=head1 INTERFACE 

The following functions are all methods, i.e. they have to be called
with the OO syntax.

=over

=item B<< new >>

not to be called directly, only serves for derived classes.

=item B<< create >>

   my $grant = Net::Amazon::S3::ACL::Grant->create({
      xpc  => $xpc,  # XPathContext
      node => $node,
   });
   my $grant = Net::Amazon::S3::ACL::Grant->create({
      target      => $target,
      permissions => $permissions,  # optional
   });

factory class method to generate a new object of the rigth type. The
natively supported types are:

=over

=item *

Email

=item *

URI

=item *

ID

=back

and are available in the package array C<@Classes>, in the given order.
They are scanned in order to find a suitable class to handle each particular
case, C<ID> serving as a fall-back. Each of them maps to a subclass
C<Net::Amazon::S3::ACL::Grant::>I<Type>.

You should pass either suitable data for parsing (in the form of an
XPathContext object and a node within), or a target description for DWIM and
some permissions (optional):

=over

=item xpc, node

data for XML parsing

=item target, permissions (these are optional)

data for DWIM elaboration of the grant.

=back

Returns the newly created object or complains about not having a suitable
subclass to handle the specific case.

=item B<< class_for >>

   my $class_name = Net::Amazon::S3::ACL::Grant->class_for($type);

given a subtype, returns the name of the class supporting that subtype.
In the implementation it just returns 
C<Net::Amazon::S3::ACL::Grant::>I<Type>, but it can be overridden (it
used by the L</create> method).

=item B<< canonical >>

   my $grant = Net::Amazon::S3::ACL::Grant->canonical($target, $perm_string);
   my $grant = Net::Amazon::S3::ACL::Grant->canonical($target, $perm_aref);
   my $grant = Net::Amazon::S3::ACL::Grant->canonical($target, $other_grant);

This is a class method.

Tries to apply a Do What I Mean logic upon its input, used to figure out
what to do with these parameters when L</add>ing or L</delete>-ing
stuff. Two positional parameters are accepted:

=over

=item target

a string that describes the particular item we're referring to. It
represents the grantee to which a particular grant applies. You can
choose among the following ones:

=over

=item C<AUTHENTICATED>

=item C<AUTH>

refers to the group of "all authenticated AWS customers". This is
canonicalised to the URI of the group, i.e.
C<http://acs.amazonaws.com/groups/global/AuthenticatedUsers>.

=item C<ALL>

=item C<ANY>

=item C<ANONYMOUS>

=item C<ANON>

=item C<*>

refers to the anonymous user group, i.e. any user without authentication.
It's canonicalised to the URI of the group, i.e.
C<http://acs.amazonaws.com/groups/global/AllUsers>.

=item anything resembling a I<HTTP URI>

the target is left as-is and the I<item> type can be set to C<URI> if the
conditions apply.

=item anything with an C<@> inside

the target is left as-is and the I<item> type can be set to I<email> if
the conditions apply.

=item anything else

the target is left as-is and the I<item> type can be set to I<ID> if the
conditions apply.

=back

=item item

this can be different things, which yield to different behaviours:

=over

=item a string

in this case, the string is intepreted as a single permission. The
canonicalisation for this permission (case-insensitive) is based on
the following mappings:

=over

=item C<READ>

=item C<R>

=item C<< < >>

set the C<READ> permission

=item C<WRITE>

=item C<W>

=item C<< > >>

set the C<WRITE> permission

=item C<READ_ACP>

=item C<READ-ACP>

=item C<RP>

set the C<READ_ACP> permission

=item C<WRITE_ACP>

=item C<WRITE-ACP>

=item C<WP>

set the C<WRITE_ACP> permission

=item C<FULL_CONTROL>

=item C<FULL>

=item C<F>

=item C<< * >>

set the C<FULL_CONTROL> permission

=back

=item a blessed (hash) reference

in this case the reference is supposed to be a valid
L<Net::Amazon::S3::ACL::Grant> object, and it is simply returned back.

=item an array reference

this fall back to the string case, because every item in the array
is interpreted as a string above.

=back

=back

If the I<item> parameter is already a "valid" acl element, then the
I<target> parameter could be completely overridden and read from the
I<item> itself. For example, if the input I<item> is the following
hash reference:


   {
      type =>  'email',
      email => 'whatever@example.com',
   }

the I<target> will be set to the email address whatever the input value
is.

On the other hand, if the I<item> part is not a valid acl element,
the I<target> will be used to guess the actual item type and set the
I<item> accordingly. This is the very base of the DWIM behaviour.

=item B<< is_valid >>

   my $bool = $grant->is_valid();

a grant is assumed to be valid if it contains at least one permission.

=item B<< add_permissions >>

   $grant->add_permissions(qw( READ WRITE ));

add the given permissions to the grant. Accepts a list of permissions
or a reference to an array containing the permissions to be added. See
L</canonical> for a list of accepted variants for permissions.

Returns a reference to the object, for chaining methods if needed.

=item B<< delete_permissions >>

   $grant->delete_permissions(qw( READ_ACP ));

delete the given permissions to the grant. Accepts a list of permissions
or a reference to an array containing the permissions to be deleted. See
L</canonical> for a list of accepted variants for permissions.

Returns a reference to the object, for chaining methods if needed.

=item B<< parse >>

   $grant->parse($xpc, $node);

accepts an XPathContext and a node to draw info from. Basically, grabs
a grant from the node.

=item B<< stringify >>

   my $xml_chunk = $grant->stringify();

gives back an XML representation for the grant. The output is an XML
chunk, not a complete document.

=back

=head1 GRANT CLASSES

Net::Amazon::S3::ACL::Grant comes for types to handle different grant
options as of EoY 2008. In case Amazon S3 adds more options in the future
and this module still doesn't implement them, or you work in Amazon and
want to implement a new one, or you replicate Amazon's system, or... you
get the idea, it's quite simple to add new types to handle new
options.

Each class is required to derive from Net::Amazon::S3::ACL::Grant, and
implement the following methods according to the given semantics:

=over

=item B<< parse_grantee >>

   $grant->parse_grantee($xpc, $node);

accepts an XPathContext and a node to draw info from. Basically, grabs
a grant of the specifically supported type from the node.

MUST return C<$self> to allow for chaining.

=item B<< populate_from_target >>

   $grant->populate_from_target($target);

This method should implement the I<Do What I Mean> behaviour for the
specific option. The nature and content of the given target are thus
depending on the specific new option you're adding. For example, in
the email case it will be an email address.

If the passed C<$target> isn't a good one for your implementation you
should C<croak()> loudly (i.e. throw an exception). Otherwise, you MUST
return the C<$grant> itself for chaining.

=item B<< stringify_grantee >>

   my $xml = $grant->stringify_grantee();

Return the XML representation of the grantee (note: of the grantee *only*,
the rest is handled by Net::Amazon::S3::ACL::Grant). For example,
L<Net::Amazon::S3::ACL::Grant::ID> returns something like this when the
ACL is for I<all>:

   <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
         xsi:type="Group">
      <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
   </Grantee>

=back

See L<Net::Amazon::S3::ACL::Grant::ID> for an example implementation.

Last thing you have to do (if you want your class to be considered
when using the DWIM approach) is to notify Net::Amazon::S3::ACL::Grant
of the new subclass. It keeps the subclasses registered in its package
variable C<@Classes>, so you can just do this:

   unshift 'My::New::Subclass', @Net::Amazon::S3::ACL::Grant::Classes;

Be careful to C<unshift> instead of C<push>: the array is scanned as is
when looking for a suitable class when the DWIM behaviour is triggered.
The Net::Amazon::S3::ACL::Grant::ID is quite liberal as to what it accepts
for target, so putting something past it is virtually a no-op. You can
obviously adjust the order inside C<@Classes> to match your order of
preference for scanning classes when looking for something suitable for
the given target.

=head1 DIAGNOSTICS

=over

=item C<< unknown permission %s >>

available permissions are described in the documentation for the
L</canonical> method. Stick to them - any case will be fine - and
you'll have no problem.

=item C<< not enough parameters to create a grant >>

when you L</create> a grant, you have to provide either sufficient
XML-related parameters, or at least a target.

=item C<< no suitable subclass found to handle input data: %s >>

when you L</create> a grant, you pass in some information that should
be useful to understand what type of grant we're dealing with. This is
actually a factory method that tries the types in the package array
C<@Classes> to find out some grant specialisation that is able to cope
with the input data. If none of them is... you'll get this error.

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

L<Net::Amazon::S3>, L<Net::Amazon::S3::ACL>,
L<Net::Amazon::S3::ACL::Grant::ID>, L<Net::Amazon::S3::ACL::Grant::Email>,
L<Net::Amazon::S3::ACL::Grant::URI>

=cut

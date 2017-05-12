package Net::Amazon::S3::Policy;

use warnings;
use strict;
use version; our $VERSION = qv('0.1.6');

use Carp;
use English qw( -no_match_vars );
use JSON;
use Encode ();
use MIME::Base64 qw< decode_base64 >;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( exact starts_with range );
our %EXPORT_TAGS = (all => \@EXPORT_OK,);

# Module implementation here
sub new {
   my $class = shift;
   my %args  = ref($_[0]) ? %{$_[0]} : @_;
   my $self  = bless {}, $class;

   if ($args{json}) {
      $self->parse($args{json});
   }
   else {
      $self->expiration($args{expiration}) if defined $args{expiration};
      $self->conditions([]);
      $self->add($_) for @{$args{conditions} || []};
   }

   return $self;
} ## end sub new

# Accessors
sub expiration {
   my $self     = shift;
   my $previous = $self->{expiration};
   if (@_) {
      my $time = shift;
      if ($time && $time =~ /\A \d+ \z/mxs) {
         my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
           gmtime($time);
         $time = sprintf "%04d-%02d-%02dT%02d:%02d:%02d.000Z",
           $year + 1900,
           $mon + 1, $mday, $hour, $min, $sec;
      } ## end if ($time && $time =~ ...
      $time ? ($self->{expiration} = $time) : delete $self->{expiration};
   } ## end if (@_)
   return $previous;
} ## end sub expiration

sub conditions {
   my $self     = shift;
   my $previous = $self->{conditions};

   if (@_) {
      $self->{conditions} = (scalar(@_) == 1) ? shift : [@_];
   }

   return $previous;
} ## end sub conditions

{    # try to understand rules

   sub _prepend_dollar {
      return substr($_[0], 0, 1) eq '$' ? $_[0] : '$' . $_[0];
   }
   my @DWIMs = (
         qr{\A\s* (\S+?) \s* \*  \s*\z}mxs => sub {
            my $target = _prepend_dollar(shift);
            return starts_with($target, '');
         },
         qr{\A\s* (\S+) \s+ eq \s+ (.*?) \s*\z}mxs => sub{
            my $target = _prepend_dollar(shift);
            my $value = shift;
            return $value eq '*' ? starts_with($target, '') : exact($target, $value);
         },
         qr{\A\s* (\S+) \s+ (?: ^ | starts[_-]?with) \s+ (.*?) \s*\z}mxs => sub {
            my $target = _prepend_dollar(shift);
            my $prefix = shift;
            return starts_with($target, $prefix);
         },
         qr{\A\s* (\d+) \s*<=\s* (\S+) \s*<=\s* (\d+) \s*\z}mxs => sub {
            my ($min, $value, $max) = @_;
            s{_}{}g for $min, $max;

            # no "_prepend_dollar" for range conditions
            return range($value, $min, $max);
         },
   );

   sub _resolve_rule {
      my ($string) = @_;

      for my $i (0 .. (@DWIMs - 1) / 2) {
         my ($regex, $callback) = @DWIMs[$i * 2, $i * 2 + 1];
         if (my @captures = $string =~ /$regex/) {
            my $result = $callback->(@captures);
            return $result if defined $result;
         }
      }

      croak "could not understand '$_', bailing out";
   } ## end sub _resolve_rule
}

sub add {
   my ($self, $condition) = @_;
   push @{$self->conditions()},
     ref($condition) ? $condition : _resolve_rule($condition);
   return;
}

sub remove {
   my ($self, $condition) = @_;
   $condition = _resolve_rule($condition) unless ref $condition;
   my $conditions = $self->conditions();
   my @filtered   = grep {
      my $keep;
      if (@$condition != @$_) {    # different lengths => different
         $keep = 1;
      }
      else {
         for my $i (0 .. $#$condition) {
            last if $keep = $condition->[$i] ne $_->[$i];
         }
      }
      $keep;
   } @$conditions;
   $self->conditions(\@filtered);
   return;
} ## end sub remove

sub exact {
   shift if ref $_[0];
   my ($target, $value) = @_;
   return ['eq', $target, $value];
}

sub starts_with {
   shift if ref $_[0];
   my ($target, $value) = @_;
   return ['starts-with', $target, $value];
}

sub range {
   shift if ref $_[0];
   my ($target, $min, $max) = @_;
   return [$target, $min, $max];
}

sub json {
   my ($self, $args) = @_;
   my %params = %$self;
   delete $params{expiration} unless defined $params{expiration};
   return to_json(\%params, $args);
} ## end sub json

sub base64 {
   my $self = shift;
   return encode_base64(Encode::encode('utf-8', $self->json(@_)));
}

{
   no warnings;
   *stringify        = \&json;
   *json_base64      = \&base64;
   *stringify_base64 = \&base64;
}

sub parse {
   my ($self, $json) = @_;

   $json = decode_base64($json)
     unless substr($json, 0, 1) eq '{';

   my %decoded = %{from_json($json)};
   $self->{conditions} = [
      map {
         if   (ref($_) eq 'ARRAY') { $_; }
         else {
            my ($name, $value) = %$_;
            ['eq', '$' . $name, $value]; 
         }
        } @{$decoded{conditions}}
   ];
   $self->{expiration} = $decoded{expiration};

   return $self;
} ## end sub parse

sub signature {
   my ($self, $key) = @_;
   require Digest::HMAC_SHA1;
   return Digest::HMAC_SHA1::hmac_sha1($self->base64(), $key);
}

sub signature_base64 {
   my ($self, $key) = @_;
   return encode_base64($self->signature($key));
}

# Wrapper around base64 encoder, ensuring that there's no newline
# to make AWS S3 happy
sub encode_base64 {
   return MIME::Base64::encode_base64($_[0], '');
}

1;    # Magic true value required at end of module
__END__

=encoding iso-8859-1

=head1 NAME

Net::Amazon::S3::Policy - manage Amazon S3 policies for HTTP POST forms

=head1 VERSION

This document describes Net::Amazon::S3::Policy version 0.1.3. Most likely,
this version number here is outdate, and you should peek the source.


=head1 SYNOPSIS

   use Net::Amazon::S3::Policy;

   # Expire in one hour
   my $policy = Net::Amazon::S3::Policy->new(expiration => time() + 3600);

   # Do What I Mean handling of conditions
   # Note: single quotes, $key is not a Perl variable in this example!
   $policy->add('$key eq path/to/somewhere');
   # In DWIM mode, '$' are pre-pended automatically where necessary
   $policy->add('key eq path/to/somewhere');
   $policy->add('x-some-field starts-with some-prefix');
   $policy->add(' 0 <= content-length-range <= 1_000_000 ');
   $policy->add('whatever *'); # any value admitted for field 'whatever'

   # NON-DWIM interface for conditions
   use Net::Amazon::S3::Policy qw( :all ); # OR
   use Net::Amazon::S3::Policy qw( exact starts_with range );
   $policy->add(exact('$field', 'whatever spaced value   ');
   $policy->add(starts_with('$other-field', '   yadda    ');
   $policy->add(range('percentual', 0, 100));

   # The output as JSON
   print $policy->stringify(), "\n"; # OR
   print $policy->json(), "\n";

   # Where the stuff is really needed: HTML FORMs for HTTP POSTs
   my $policy_for_form    = $policy->base64();
   my $signature_for_form = $policy->signature_base64($key);

   # If you ever receive a policy...
   my $received = Net::Amazon::S3::Policy->new(json => $json_text);
   my $rec2 = Net::Amazon::S3::Policy->new();
   $rec2->parse($json_base64); # either JSON or its Base64 encoding


=head1 DESCRIPTION

Net::Amazon::S3::Policy gives you an object-oriented interface to
manage policies for Amazon S3 HTTP POST uploads.

Amazon S3 relies upon either a REST interface (see L<Net::Amazon::S3>)
or a SOAP one; as an added service, it is possible to give access to
the upload of resources using HTTP POSTs that do not involve using
any of these two interfaces, but a single HTML FORM. The rules you
have to follow are explained in the Amazon S3 Developer Guide.

More or less, it boils down to the following:

=over

=item *

if the target bucket is not writeable by the anonymous group, you'll need
to set an access policy;

=item *

almost every field in the HTML FORM that will be used to build up the HTTP POST
message by the browser needs to be included into a I<policy>, and the policy
has to be sent along within the HTTP POST

=item *

together with the I<policy>, also the bucket owner's AWS ID (the public one) has to
be sent, together with a digital signature of the policy that has to be created
using the bucket owner's AWS secret key.

=back

So, you'll have to add three fields to the HTTP POST in order for it to comply
with Amazon's requirement when the bucket is not publicly writeable:

=over

=item C<AWSAccessKeyId>

given "as-is", i.e. as you copied from your account in Amazon Web Services;

=item C<policy>

given as a JSON document that is Base64 encoded;

=item C<signature>

calculated as a SHA1-HMAC of the Base64-encoded policy, using your secret
key as the signature key, and then encoded with Base64.

=back

This module lets you manage the build-up of a policy document, providing you
with tools to get the Base64 encoding of the resulting JSON policy document,
and to calculate the Base64 encoding of the signature. See L</Example> for
a complete example of how to do this.

In addition to I<policy synthesis>, the module is also capable of parsing
some policy (base64-encoded or not, but in JSON format). This shouldn't
be a need in general... possibly for debug reasons.

=head2 Example

For example, suppose that you have the following HTML FORM to allow selected
uploads to the C<somebucket> bucket (see the Amazon S3 Developer Guide for
details about writing the HTML FORM):

   <form action="http://somebucket.s3.amazonaws.com/" method="post"
         enctype="multipart/form-data">
      <!-- inputs needed because bucket is not publicly writeable -->
      <input type="hidden" name="AWSAccessKeyId" value="your-ID-here">
      <input type="hidden" name="policy" value="base64-encoded-policy">
      <input type="hidden" name="signature" value="base64-encoded-signature">

      <!-- input needed by AWS-S3 logic: there MUST be a key -->
      <input type="hidden" name="key" value="/restricted/${filename}">

      <!-- inputs that you want to include in your form -->
      <input type="hidden" name="Content-Type" value="image/jpeg">
      <label for="colour">Colour</label>
      <input type="text" id="colour" name="x-amz-meta-colour" value="green">

      <!-- input needed to have something to upload. LAST IN FORM! -->
      <input type="file" id="file" name="file">
   </form>

You need to include the following elements in your policy:

=over

=item *

C<key>

=item *

C<Content-Type>

=item *

C<x-amz-meta-colour>

=back

Your policy can then be built like this:

   my $policy = Net::Amazon::S3::Policy->new(
      expiration => time() + 60 * 60, # one-hour policy
      conditions => [
         '$key         starts-with /restricted/', # restrict to here
         '$Content-Type starts-with image/', # accept any image format
         '$x-amz-meta-colour *', # accept any colour
         'bucket eq somebucket',
      ],
   );

   # Put this as the value for "policy", 
   # instead of "base64-encoded-policy"
   my $policy_for_form = $policy->base64();

   # Put this as the value for "signature", 
   # instead of "base64-encoded-signature"
   my $signature_for_form = $policy->signature_base64($key);

=head1 INTERFACE 

=begin PrivateMethods

=head2 encode_base64

=end PrivateMethods

=head2 Module Interface

=over

=item B<< new (%args)  >>

=item B<< new (\%args)  >>

constructor to create a new Net::Amazon::S3::Policy object.

Arguments can be passed either as a single hash reference, or
as a hash. Choose whatever you like most.

Recognised keys are:

=over

=item expiration

the expiration date for this policy.

=item conditions

a list of conditions to initialise the object. This should
point to an array with the conditions, that will be passed through
the L</add> method.

=item json

a piece of JSON text to parse the configuration from. The presence
of this parameter overrides the other two.

=back

=item B<< expiration ()  >>

=item B<< expiration ($time)  >>

get/set the expiration time for the condition. Set to a false value
to remove the expiration time from the policy.

You should either pass an ISO8601 datetime string, or an epoch value.
You'll always get an ISO8601 string back.

=item B<< conditions () >>

=item B<< conditions (@conditions)  >>

=item B<< conditions (\@conditions)  >>

get/set the conditions in the policy. You should never need to use this
method, because the L</add> and L</remove> are there for you to interact
with this member. If you want to use this, anyway, be sure to take
a look to the functions in L</Convenience Condition Functions>.

=item B<< add ($spec)  >>

add a specification to the list of conditions.

A specification can be either an ARRAY reference, or a textual one:

=over

=item *

if you pass an ARRAY reference, it should be something like the one
returned by any of the functions in L</Convenience Condition Functions>;

=item *

othewise, it can be a string with a single condition, like the following
examples:

   some-field eq some-value
   $some-other-field starts-with /path/to/somewhere/
   10 <= numeric-value <= 1000

Note that the string specification is less "strict" in checking its
parameters; in particular, you should stick to the ARRAY reference if
your parameters have a space inside. You can use the following formats:

=over

=item C<< <name> eq <value> >>

set a name to have a given value, exactly;

=item C<< <name> starts-with <prefix> >>

=item C<< <name> starts_with <prefix> >>

=item C<< <name> ^ <prefix> >>

set the prefix that has to be matched against the value
for the field with the given name. If the prefix is left
empty, every possible value will be admitted;

=item C<< <name> * >>

admit any value for the given field, just like setting an empty
value for a C<starts-with> rule;

=item C<< <min> <= <name> <= <max> >>

set an allowable range for the given field.

=back

Policies for exact or starts-with matching usually refer to the form's
field, thus requiring to refer them as "variables" with a prepended
dollar sign, just like Perl scalars (more or less). Thus, if you forget
to put it, it will be automatically added for you. Hence, the following
conditions are equivalent:

   field  eq blah
   $field eq blah

because both yield the following condition in JSON:

   ["eq","$field","blah"]

=back

=item B<< remove ($spec)  >>

remove a condition in the list of conditions. The parameter is
regarded exactly as in L</add>; once it is found, the list of
conditions will be filtered to exclude that particular
condition, exactly.

=item B<< json () >>

=item B<< stringify () >>

get a textual version of the object, in JSON format. This is the
base format used to interact with Amazon S3.

=item B<< base64 () >>

=item B<< json_base64 () >>

=item B<< stringify_base64 () >>

get a textual version of the object, as a Base64 encoding of the
JSON representation (see L</json>). This is what should to be put
as C<policy> field in the POST form.


=item B<< parse ($json_text)  >>

parse a JSON representation of a policy and fill in the object. This
is the opposite of L</json>.


=item B<< signature ($key)  >>

get the signature for the Base 64 encoding of the JSON representation of
the policy. The signature is the SHA1-HMAC digital signature, with the
given key.


=item B<< signature_base64 ($key)  >>

get the Base64 encoding of the signature, as given by L</signature>. This
is the value that should be put in the C<signature> field in the POST
form.

=back

=head2 Convenience Condition Functions

The following functions can be optionally imported from the
module, and can be used indifferently as class/instance
methods or as functions.

=over

=item B<< exact ($target, $value)  >>

produce an I<exact value> condition. This condition is an array
reference with the following elements:

=over

=item *

the C<eq> string;

=item *

the I<name> of the field;

=item *

the I<value> that the field should match exactly.

=back

=item B<< starts_with ($target, $value)  >>

produce a I<starts-with> condition. This condition is an array
reference with the following elements:

=over

=item *

the C<starts-with> string;

=item *

the I<name> of the field;

=item *

the I<prefix> that has to be matched by the field's value

=back

=item B<< range ($target, $min, $max) >>

produce a I<value range> condition. This condition is an array
reference with the following elements:

=over

=item *

the I<name> of the field;

=item *

the I<minimum> value allowed for the field's value;

=item *

the I<maximum> value allowed for the field's value;

=back

=back

=head1 DIAGNOSTICS


=over

=item C<< could not understand '%s', bailing out >>

The L</add> and L</remove> function try their best to understand
a condition when given in string form... but you should really
stick to the format given in the documentation!

=back


=head1 CONFIGURATION AND ENVIRONMENT

Net::Amazon::S3::Policy requires no configuration files or environment variables.


=head1 DEPENDENCIES

The C<version> pragma (which has been included in Perl 5.10) and the
L</JSON> module.


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

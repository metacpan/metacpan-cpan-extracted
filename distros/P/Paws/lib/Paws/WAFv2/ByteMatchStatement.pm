package Paws::WAFv2::ByteMatchStatement;
  use Moose;
  has FieldToMatch => (is => 'ro', isa => 'Paws::WAFv2::FieldToMatch', required => 1);
  has PositionalConstraint => (is => 'ro', isa => 'Str', required => 1);
  has SearchString => (is => 'ro', isa => 'Str', required => 1);
  has TextTransformations => (is => 'ro', isa => 'ArrayRef[Paws::WAFv2::TextTransformation]', required => 1);
1;

### main pod documentation begin ###

=head1 NAME

Paws::WAFv2::ByteMatchStatement

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::WAFv2::ByteMatchStatement object:

  $service_obj->Method(Att1 => { FieldToMatch => $value, ..., TextTransformations => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::WAFv2::ByteMatchStatement object:

  $result = $service_obj->Method(...);
  $result->Att1->FieldToMatch

=head1 DESCRIPTION

This is the latest version of B<AWS WAF>, named AWS WAFV2, released in
November, 2019. For information, including how to migrate your AWS WAF
resources from the prior release, see the AWS WAF Developer Guide
(https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html).

A rule statement that defines a string match search for AWS WAF to
apply to web requests. The byte match statement provides the bytes to
search for, the location in requests that you want AWS WAF to search,
and other settings. The bytes to search for are typically a string that
corresponds with ASCII characters. In the AWS WAF console and the
developer guide, this is refered to as a string match statement.

=head1 ATTRIBUTES


=head2 B<REQUIRED> FieldToMatch => L<Paws::WAFv2::FieldToMatch>

  The part of a web request that you want AWS WAF to inspect. For more
information, see FieldToMatch.


=head2 B<REQUIRED> PositionalConstraint => Str

  The area within the portion of a web request that you want AWS WAF to
search for C<SearchString>. Valid values include the following:

B<CONTAINS>

The specified part of the web request must include the value of
C<SearchString>, but the location doesn't matter.

B<CONTAINS_WORD>

The specified part of the web request must include the value of
C<SearchString>, and C<SearchString> must contain only alphanumeric
characters or underscore (A-Z, a-z, 0-9, or _). In addition,
C<SearchString> must be a word, which means that both of the following
are true:

=over

=item *

C<SearchString> is at the beginning of the specified part of the web
request or is preceded by a character other than an alphanumeric
character or underscore (_). Examples include the value of a header and
C<;BadBot>.

=item *

C<SearchString> is at the end of the specified part of the web request
or is followed by a character other than an alphanumeric character or
underscore (_), for example, C<BadBot;> and C<-BadBot;>.

=back

B<EXACTLY>

The value of the specified part of the web request must exactly match
the value of C<SearchString>.

B<STARTS_WITH>

The value of C<SearchString> must appear at the beginning of the
specified part of the web request.

B<ENDS_WITH>

The value of C<SearchString> must appear at the end of the specified
part of the web request.


=head2 B<REQUIRED> SearchString => Str

  A string value that you want AWS WAF to search for. AWS WAF searches
only in the part of web requests that you designate for inspection in
FieldToMatch. The maximum length of the value is 50 bytes.

Valid values depend on the areas that you specify for inspection in
C<FieldToMatch>:

=over

=item *

C<Method>: The HTTP method that you want AWS WAF to search for. This
indicates the type of operation specified in the request.

=item *

C<UriPath>: The value that you want AWS WAF to search for in the URI
path, for example, C</images/daily-ad.jpg>.

=back

If C<SearchString> includes alphabetic characters A-Z and a-z, note
that the value is case sensitive.

B<If you're using the AWS WAF API>

Specify a base64-encoded version of the value. The maximum length of
the value before you base64-encode it is 50 bytes.

For example, suppose the value of C<Type> is C<HEADER> and the value of
C<Data> is C<User-Agent>. If you want to search the C<User-Agent>
header for the value C<BadBot>, you base64-encode C<BadBot> using MIME
base64-encoding and include the resulting value, C<QmFkQm90>, in the
value of C<SearchString>.

B<If you're using the AWS CLI or one of the AWS SDKs>

The value that you want AWS WAF to search for. The SDK automatically
base64 encodes the value.


=head2 B<REQUIRED> TextTransformations => ArrayRef[L<Paws::WAFv2::TextTransformation>]

  Text transformations eliminate some of the unusual formatting that
attackers use in web requests in an effort to bypass detection. If you
specify one or more transformations in a rule statement, AWS WAF
performs all transformations on the content identified by
C<FieldToMatch>, starting from the lowest priority setting, before
inspecting the content for a match.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::WAFv2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut


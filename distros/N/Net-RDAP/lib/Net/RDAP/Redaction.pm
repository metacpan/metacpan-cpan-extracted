package Net::RDAP::Redaction;
use strict;

=pod

=head1 NAME

L<Net::RDAP::Redaction> - a module representing a redacted field in an RDAP
response.

=head1 DESCRIPTION

Any RDAP object which inherits from L<Net::RDAP::Object> has a C<redactions()>
methid which will return an array of L<Net::RDAP::Redaction> representing the
fields identified by the server as being redacted (if any).

=cut

sub new {
    my ($package, $args) = @_;
    my %self = %{$args};
    return bless(\%self, $package);
}

=pod

=head1 METHODS

=head2 Redacted Field Name

    $name = $field->name;

Returns the logical name for the redacted field, which may be registered or
unregistered (see L<Section 4.2 of RFC 9537|https://www.rfc-editor.org/rfc/rfc9537.html#name-redacted-member>).

=head2 Redaction Method

    $method = $field->method;

Returns one of C<removal>, C<emptyValue>, C<partialValue> or C<replacementValue>.

=head2 JSON Path Expression Language

    $lang = $field->pathLang;

Returns the JSON path expression language used, which is C<jsonpath> by default.

=head2 JSON Paths

    $prePath = $field->prePath;

Returns the path expression referencing the redacted field in the pre-redacted
response (if any).

    $postPath = $field->postPath;

Returns the path expression referencing a redacted field in the redacted
(post-redacted) response (if any).

    $replacementPath = $field->replacementPath;

Returns the path expression of the replacement field of the redacted field when
the redaction method is C<replacementValue>.

=head2 Reason

    $reason = $field->reason;
    $lang = $field->reasonLang;

C<$field-E<gt>reason> returns the human-readable reason(s) why the field has
been redacted. C<$field-E<gt>reasonLang> returns the language of the reason,
which is <en> by default.

=cut

sub name {
    my $self = shift;
    return $self->{'name'}->{'type'} || $self->{'name'}->{'description'};
}

sub method          { shift->{'method'} || 'removal'        }
sub pathLang        { shift->{'pathLang'} || 'jsonpath'     }
sub prePath         { shift->{'prePath'}                    }
sub postPath        { shift->{'postPath'}                   }
sub replacementPath { shift->{'replacementPath'}            }
sub reasonLang      { shift->{'reason'}->{'lang'} || 'en'   }
sub reason          { shift->{'reason'}->{'description'}    }

=pod

=head1 COPYRIGHT

Copyright 2024 Gavin Brown. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;

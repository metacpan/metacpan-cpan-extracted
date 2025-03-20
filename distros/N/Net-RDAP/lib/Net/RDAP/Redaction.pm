package Net::RDAP::Redaction;
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Redaction> - a module representing a redacted field in an RDAP
response.

=head1 DESCRIPTION

Any RDAP object which inherits from L<Net::RDAP::Object> has a C<redactions()>
method which will return an array of L<Net::RDAP::Redaction> objects
representing the fields identified by the server as being redacted (if any).

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
which is C<en> by default.

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

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;

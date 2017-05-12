
## no critic (ProhibitMultiplePackages, RequireFilenameMatchesPackage, RequireUseWArnings, RequireUseStrict, RequireExplicitPackage)

=head1 NAME

OAuthomatic::Error - structured exceptions thrown by OAuthomatic

=head1 DESCRIPTION

Errors defined here allow for inspection of various error details.

=head1 SYNOPSIS

    try {
        OAuthomatic::Error::Sth->throw({
            ident   => 'short description',
            # ... other params
        });
    } catch {
        my $error = $_;
        if ($error->isa('OAuthomatic::Error')) {
            print $error->message, "\n\n", $error->stack_trace->as_string;
            # Or use class-dependant fields
        }
    };

=cut

{
    package OAuthomatic::Error;
    use Moose;
    use Moose::Util::TypeConstraints;
    sub Payload { return 'Role::HasPayload::Meta::Attribute::Payload' }
    use namespace::sweep;

    # Some, but not all, parts of Throwable::X
    with 'Throwable';                # ->throw
    with 'Role::HasPayload::Merged'; # ->payload (marked attribs + explicit payload)
    with 'StackTrace::Auto';         # ->stack_trace->as_string
    # Subtypes use Role::HasMessage::Errf

    has ident => (is  => 'ro', required => 1,
                  isa => subtype('Str', where { length && /\A\S/ && /\S\z/ }),
                  traits => [Payload]);

    use overload fallback => 1,
      '""' => sub { $_[0]->message };
};

=head2 OAuthomatic::Error::HTTPFailure

Object representing various communication and OAuth-protocol related failures.

    try {
        OAuthomatic::Error::HTTPFailure->throw({
            ident    => 'OAuth HTTP request failed',
            request  => $request,   # HTTP::Request
            response => $response, # HTTP::Response
        });
    } catch {
        my $error = $_;
        if ($error->isa('OAuthomatic::Error::HTTPFailure')) {
            print "$error\n";   # message
            print $error->stack_trace->as_string;  # if necessary
            if($error->is_new_client_key_required) {
                # request new client (application) key
            } elsif($error->is_new_token_required) {
                # redo authorization sequence
            }
            # See also other fields - code, uri, struct_detail
        }
    };

=head3 METHODS

=over 4

=item C<is_new_client_key_required()>

Do details of this error mean, that OAuth client key in use is no longer valid and should be replaced?

=item C<is_new_token_required()>

Do details of this error mean, that OAuth token in use is no longer valid and application
should get new one?

=back

=head3 ATTRIBUTES

=over 4

=item C<request>

L<HTTP::Request> object containing request which caused failure.

=item C<response>

L<HTTP::Response> object containing obtained reply (error reply).

=item C<code>

Shortcut. HTTP error code (400, 401, 500, ...).

=item C<status>

Shortcut. HTTP status line

=item C<oauth_problem>

If description of actual OAuth problem was detected, appropriate text code, for
example C<parameter_absent>, C<token_revoked>, C<consumer_key_rejected>, ...

See L<http://wiki.oauth.net/w/page/12238543/ProblemReporting> for possible values.

=item C<detail>

Error detail. Formatted from information available in response content (if format
was not recognized, this very content by itself).

=item C<struct_detail>

Deserialized error detail in case output contains form-encoded data. Handles:

=over 4

=item form-serialized data

Frequently used in OAuth initial protocol sequences, for example you may see here:

    {
        oauth_problem => 'parameter_absent',
        oauth_parameters_absent => 'oauth_consumer_key',
    }

=item JSON error output

For example

    {
        error => { id => '9e9c7bddeff3',
                   message => 'Object already deleted' },
    }

=back

=item C<method>

Shortcut. HTTP method (GET, POST, PUT, DELETE)

=item C<uri>

Shortcut. URI object representing the call.

=back

=cut

{
    package OAuthomatic::Error::HTTPFailure;
    use Moose;
    use Try::Tiny;
    use OAuthomatic::Internal::Util qw/parse_http_msg_form parse_http_msg_json/;
    use Data::Dump qw(dump);
    use namespace::sweep;

    extends 'OAuthomatic::Error';
    with 'Role::HasMessage::Errf' => {
        default => "OAuthomatic HTTP failure: %{ident}s.\n"
          . "    Code: %{code}s. Status: %{status}s\n"
          . "    Call: %{method}s %{uri}s\n"
          . "    %{detail}s",
    };

    sub Payload { return 'Role::HasPayload::Meta::Attribute::Payload' }

    has request => (is => 'ro', isa => 'HTTP::Request', required => 1);
    has response => (is => 'ro', isa => 'HTTP::Response', required => 1);

    has code => (is => 'ro', lazy_build => 1, traits => [Payload]);
    has status => (is => 'ro', lazy_build => 1, traits => [Payload]);
    has method => (is => 'ro', lazy_build => 1, traits => [Payload]);
    has uri => (is => 'ro', lazy_build => 1, traits => [Payload]);
    has detail => (is => 'ro', lazy_build => 1, traits => [Payload]);
    # In some cases we get form-encoded error attributes, if they
    # are present, we keep them there
    has struct_detail => (is => 'ro', lazy_build => 1);
    # Detailed info about problem, if any, http://wiki.oauth.net/w/page/12238543/ProblemReporting
    has oauth_problem => (is => 'ro', lazy_build => 1);

    sub is_new_client_key_required {
        my $self = shift;
        my $problem = $self->oauth_problem || '';
        if($problem =~ /^(consumer_key_unknown|consumer_key_rejected)$/x) {
            return 1;
        }
        return 0;
    }

    sub is_new_token_required {
        my $self = shift;
        my $problem = $self->oauth_problem || '';
        if($problem =~ /^(token_expired|token_revoked|token_rejected|permission_unknown|permission_denied)$/x) {
            return 1;
        }
        return 0;
    }

    ## FIXME: implement by delegation?

    ## no critic (RequireArgUnpacking)
    sub _build_code {
        return $_[0]->response->code;
    }
    sub _build_status {
        return $_[0]->response->message;
    }
    sub _build_method {
        return $_[0]->request->method;
    }
    sub _build_uri {
        return $_[0]->request->uri;
    }
    ## use critic

    sub _build_struct_detail {
        my $self = shift;
        my $reply;

        my $response = $self->response;
        return unless $response;

        my $content_type = $response->content_type;
        # my $charset = $response->content_type_charset;

        # HTML form errors. Some real examples:
        # (in headers)
        #     Content-Type: application/x-www-form-urlencoded;charset=UTF-8
        # (in body)
        #     oauth_parameters_absent=oauth_consumer_key%26oauth_signature_method%26oauth_signature%26oauth_timestamp&oauth_problem=parameter_absent
        # (or)
        #     oauth_parameters_absent=oauth_consumer_key&oauth_problem=parameter_absent
        if($content_type eq 'application/x-www-form-urlencoded') {
            try {
                $reply = parse_http_msg_form($response, 1);
            };
        }
        elsif($content_type =~ m{^application/(?:x-)?json}x) {
            try {
                $reply = parse_http_msg_json($response);
            };
        }

        # FIXME: maybe compact JSON level up if it contains just 'error'

        # FIXME: XML errors (LinkedIn for example)

        return $reply;
    }

    sub _build_oauth_problem {
        my $self = shift;
        my $struct_detail = $self->struct_detail;
        if($struct_detail) {
            if(exists $struct_detail->{oauth_problem}) {
                return $struct_detail->{oauth_problem};
            }
        }
        return '';  # To make comparisons easier
    }

    sub _build_detail {
        my $self = shift;

        my $struct_detail = $self->struct_detail;
        my $detail_text;
        if($struct_detail) {
            local $Data::Dump::INDENT = "    ";
            $detail_text = dump($struct_detail);
            chomp($detail_text);
        } else {
            $detail_text = $self->response->decoded_content;
            chomp($detail_text);
        }
        $detail_text =~ s{\r?\n}{\n       }xg;
        return "Details:\n        " . $detail_text . "\n";
    }
};

=head2 OAuthomatic::Error::Generic

Object representing non-HTTP related exception (mostly various cases of bad parameters
and programming errors).

    try {
        OAuthomatic::Error::Generic->throw({
            ident   => 'Required parameter missing',
            extra   => "Neither body, nor body_params provided."
        });
    } catch {
        my $error = $_;
        if ($error->isa('OAuthomatic::Error::Generic')) {
            print "$error\n";   # message
            print $error->stack_trace->as_string;  # if necessary
        }
    };

=head3 ATTRIBUTES

=over 4

=item C<ident>

Short error description

=item C<extra>

Additional, more elaborate, information.

=back

=cut

{
    package OAuthomatic::Error::Generic;
    use Moose;
    extends 'OAuthomatic::Error';
    with 'Role::HasMessage::Errf' => {
        default => "OAuthomatic internal error: %{ident}s.\n"
          . "%{extra}s\n",
    };

    sub Payload { return 'Role::HasPayload::Meta::Attribute::Payload' }

    has extra => (is => 'ro', isa => 'Str', traits => [Payload]);
};

1;

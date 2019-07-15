use utf8;

package SemanticWeb::Schema::EntryPoint;

# ABSTRACT: An entry point

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'EntryPoint';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has action_application => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actionApplication',
);



has action_platform => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actionPlatform',
);



has application => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'application',
);



has content_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contentType',
);



has encoding_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'encodingType',
);



has http_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'httpMethod',
);



has url_template => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'urlTemplate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EntryPoint - An entry point

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An entry point, within some Web-based protocol.

=head1 ATTRIBUTES

=head2 C<action_application>

C<actionApplication>

An application that can complete the request.

A action_application should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SoftwareApplication']>

=back

=head2 C<action_platform>

C<actionPlatform>

The high level platform(s) where the Action can be performed for the given
URL. To specify a specific application or operating system instance, use
actionApplication.

A action_platform should be one of the following types:

=over

=item C<Str>

=back

=head2 C<application>

An application that can complete the request.

A application should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SoftwareApplication']>

=back

=head2 C<content_type>

C<contentType>

The supported content type(s) for an EntryPoint response.

A content_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<encoding_type>

C<encodingType>

The supported encoding type(s) for an EntryPoint request.

A encoding_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<http_method>

C<httpMethod>

An HTTP method that specifies the appropriate HTTP method for a request to
an HTTP EntryPoint. Values are capitalized strings as used in HTTP.

A http_method should be one of the following types:

=over

=item C<Str>

=back

=head2 C<url_template>

C<urlTemplate>

An url template (RFC6570) that will be used to construct the target of the
execution of the action.

A url_template should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

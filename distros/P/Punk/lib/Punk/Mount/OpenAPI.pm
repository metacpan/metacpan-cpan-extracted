package Punk::Mount::OpenAPI;

use 5.010;
use strict;
use warnings;
use Open::API;
use Punk ();            

our $VERSION = '0.17';

1;

__END__

=head1 NAME

Punk::Mount::OpenAPI - the api mount: spec-first operations

=head1 SYNOPSIS

    my $v1  = under '/v1' => 'API::Auth#bearer';
    my $api = $v1->api('openapi.json' => {
        controller_ns => 'MyApp::Controller::API',   # the default
        under         => { '/books/manage' => 'API::Auth#admin' },
        security      => { session => 'API::Auth#session' },
    });

=head1 DESCRIPTION

An C<api> mount compiles an OpenAPI 3.1 document through L<Open::API>
and dispatches each operation to the controller method named after its
operationId. Everything resolves at C<to_app>:

=over 4

=item * every class under C<controller_ns> (default
C<MyApp::Controller::API>) is loaded and operationIds mapped to the
one class implementing each - two implementers croak, none croaks
(unless C<< stub => 1 >>, which answers 501 per request instead); the
C<handlers> option overrides per operationId with a coderef or target
string;

=item * the spec's security requirements compile to a generated guard
per operation from the C<< security => { scheme => checker } >> map -
alternatives are OR, schemes within one are AND, results land in
C<< $c->stash->{auth} >>, failure answers 401 before any validation. A
required scheme with no checker croaks at boot;

=item * the C<under> option assigns extra guards by spec-path prefix
(longest prefix wins), appended after the mount scope's own guards.

=back

Per request the pipeline is: route (C<< $api->match >>, one C call),
guard chain (a 401/redirect costs no body read), C<max_body_size>
check (413), C<< $api->validate_request >> (one C call; failures
answer 400 with the same C<< {errors=>[...]} >> shape as
L<Open::API::Plack>), then the controller with C<< $c->openapi >>
holding the typed parameters and C<< $c->param >> reading them first.

=head1 METHODS

The mount is an internal object - the C<api> keyword returns it and the
framework drives it. C<new(spec =E<gt> ..., opts =E<gt> ..., prefix =E<gt>
..., guards =E<gt> ...)> constructs one; C<compile($app, $resolve)>
resolves it at boot; C<dispatch($c, $before, $op_id, $caps)> runs one
matched operation per request. C<prefix>, C<api> (the compiled
L<Open::API>), C<ops>, C<max_body_size> and C<on_error> are read-only
accessors onto what C<compile> froze.

=head1 OPTIONS

C<controller_ns>, C<handlers>, C<under>, C<security>,
C<max_body_size> (default 1048576), C<on_error> (mount-level
override), C<stub>.

=head1 SEE ALSO

L<Punk>, L<Open::API>, L<Open::API::Plack>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

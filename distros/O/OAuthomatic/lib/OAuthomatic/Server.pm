package OAuthomatic::Server;
# ABSTRACT: Definition of OAuth server crucial characteristics

use Moose;
use Carp;
use namespace::sweep;


# FIXME: some formatting for _help (markdown?)

has oauth_temporary_url => (
    is => 'ro', isa => 'Str', required => 1);
has oauth_authorize_page => (
    is => 'ro', isa => 'Str', required => 1);
has oauth_token_url => (
    is => 'ro', isa => 'Str', required => 1);

has site_name =>  (
    is => 'ro', isa => 'Str', lazy => 1, required => 1, default => sub {
        my $self = shift;
        if($self->oauth_authorize_page =~ m{^https?://(.*?)/}x) {
            # print "[OAuthomatic] Calculated site_name: $1\n" if $self->debug;
            return $1;
        } else {
            OAuthomatic::Error::Generic->throw(
                ident => "Can not detect site_name",
                extra => "Tried guessing from "
                    . $self->oauth_authorize_page
                    . "\nPlease provide explicit site_name => ...");
        }
    });

has site_client_creation_page =>  (
    is => 'ro', isa => 'Str');

has site_client_creation_desc =>  (
    is => 'ro', isa => 'Str', lazy => 1, required => 1, default => sub {
        return $_[0]->site_name . " application access settings";
    });

has site_client_creation_help =>  (
    is => 'ro', isa => 'Str');

# FIXME: api calls prefix (prepended whenever relative path is given anywhere)


has 'protocol_version' => (
    is => 'ro', isa => 'Str', required => 1, default => '1.0a',
    trigger => sub {
        my ($self, $val, $old_val) = @_;
        OAuthomatic::Error::Generic->throw(
            ident => "Invalid parameter",
            extra => "Invalid protocol_version: $val (expected 1.0 or 1.0a)")
            unless $val =~ /^1\.0a?$/x;
    });


has 'signature_method' => (
   is => 'ro', isa => 'Str', required => 1, default => 'HMAC-SHA1');

# FIXME: pluggable class?

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Server - Definition of OAuth server crucial characteristics

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Definition of specific OAuth server - all necessary URLs and some
additional information.

=head1 PARAMETERS

=head2 oauth_temporary_url

Full address of API endpoint used to create OAuth temporary token
(initial step of OAuth exchange). Should be documented inside given
webservice API docs.

Example: C<https://bitbucket.org/api/1.0/oauth/request_token>

=head2 oauth_authorize_page

Full address (without params) of web page to which user should be sent
to authorize application access. Should be documented inside given
webservice API docs.

Example: C<https://bitbucket.org/api/1.0/oauth/authenticate>

=head2 oauth_token_url

Full address of API endpoint used to create OAuth token (final
step of OAuth exchange, executed after successful authorization).
Should be documented inside given webservice API docs.

Example: C<https://bitbucket.org/api/1.0/oauth/access_token>

=head2 site_name

Symbolic name of the server we authorize access to. Usually domain name,
sometimes slightly prettified.

Default: hostname extracted from oauth_authorize_page

Example: C<BitBucket.com>.

=head2 site_client_creation_page

Address of the web page on which client key and secret can be created
(note, terminology varies, those may also be called I<application
keys> or I<consumer keys> etc). Usually this is labeled "OAuth",
"Developer", "Application access", "Access tokens" or similarly, and
can be found among security settings or developer settings.

This parameter is optional as sometimes the page may have dynamic
address (for example contain user name or id in URL) or not directly
addressable (heavily javascripted apps).

Example: C<https://github.com/settings/applications>

=head2 site_client_creation_desc

Short textual description of that page, used as link text (if
site_client_creation_page is known) or instead of link (if not).

Default: C<[SiteName] application access settings>.

=head2 site_client_creation_help

Any extra help worth presenting to the user while he looks for app
keys (for example info how field names map).

=head1 ATTRIBUTES

=head2 protocol_version

OAuth Protocol version supported by the site. Currently either '1.0'
or '1.0a' (the latter is default).

=head2 signature_method

OAuth signature method which shold be used. Default: HMAC-SHA1

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

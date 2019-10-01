# Copyrights 2013-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Net-OAuth2.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Net::OAuth2::Profile::WebServer;
use vars '$VERSION';
$VERSION = '0.66';

use base 'Net::OAuth2::Profile';

use warnings;
use strict;

use Net::OAuth2::AccessToken;
use MIME::Base64  'encode_base64';
use Scalar::Util  'blessed';

use HTTP::Request     ();
use HTTP::Response    ();
use HTTP::Status      qw(HTTP_TEMPORARY_REDIRECT);


sub init($)
{   my ($self, $args) = @_;
    $args->{grant_type}   ||= 'authorization_code';
    $self->SUPER::init($args);
    $self->{NOPW_redirect}  = $args->{redirect_uri};
    $self->{NOPW_referer}   = $args->{referer};
    $self->{NOPW_auto_save} = $args->{auto_save}
      || sub { my $token = shift; $token->changed(1) };
    $self;
}

#-------------------

sub redirect_uri() {shift->{NOPW_redirect}}
sub referer(;$)
{   my $s = shift; @_ ? $s->{NOPW_referer} = shift : $s->{NOPW_referer} }
sub auto_save()    {shift->{NOPW_auto_save}}

#--------------------

sub authorize(@)
{   my ($self, @req_params) = @_;

    # temporary, for backward compatibility warning
    my $uri_base = $self->SUPER::authorize_url;
#   my $uri_base = $self->authorize_url;

    my $uri      = blessed $uri_base && $uri_base->isa('URI')
      ? $uri_base->clone : URI->new($uri_base);

    my $params   = $self->authorize_params(@req_params);
    $uri->query_form($uri->query_form, %$params);
    $uri;
}

# Net::OAuth2 returned the url+params here, but this should return the
# accessor to the parameter with this name.  The internals of that code
# was so confused that it filled-in the params multiple times.
sub authorize_url()
{   require Carp;
    Carp::confess("do not use authorize_url() but authorize()! (since v0.50)");
}


sub authorize_response(;$)
{   my ($self, $request) = @_;
    my $resp = HTTP::Response->new
      ( HTTP_TEMPORARY_REDIRECT => 'Get authorization grant'
      , [ Location => $self->authorize ]
      );
    $resp->request($request) if $request;
    $resp;
}


sub get_access_token($@)
{   my ($self, $code, @req_params) = @_;

    my $params   = $self->access_token_params(code => $code, @req_params);

    my $request  = $self->build_request
      ( $self->access_token_method
      , $self->access_token_url
      , $params
      );

    my $basic    = encode_base64 "$params->{client_id}:$params->{client_secret}"
      , '';   # no new-lines!

    $request->headers->header(Authorization => "Basic $basic");
    my $response = $self->request($request);

    Net::OAuth2::AccessToken->new
      ( profile      => $self
      , auto_refresh => !!$self->auto_save
      , $self->params_from_response($response, 'access token')
      );
}


sub update_access_token($@)
{   my ($self, $access, @req_params) = @_;
    my $refresh =  $access->refresh_token
        or die 'unable to refresh token without refresh_token';

    my $req   = $self->build_request
      ( $self->refresh_token_method
      , $self->refresh_token_url
      , $self->refresh_token_params(refresh_token => $refresh, @req_params)
      );

    my $resp  = $self->request($req);
    my %data  = $self->params_from_response($resp, 'update token');

    my $token = $data{access_token}
        or die "no access token found in refresh data";

    my $type  = $data{token_type};

    my $exp   = $data{expires_in}
        or die  "no expires_in found in refresh data";

    $access->update_token($token, $type, $exp+time(), $data{refresh_token});
}

sub authorize_params(%)
{   my $self   = shift;
    my $params = $self->SUPER::authorize_params(@_);
    $params->{response_type} ||= 'code';

    # should not be required: usually the related between client_id and
    # redirect_uri is fixed to avoid security issues.
    my $r = $self->redirect_uri;
    $params->{redirect_uri}  ||= $r if $r;

    $params;
}

sub access_token_params(%)
{   my $self   = shift;
    my $params = $self->SUPER::access_token_params(@_);
    $params->{redirect_uri} ||= $self->redirect_uri;
    $params;
}

sub refresh_token_params(%)
{   my $self   = shift;
    my $params = $self->SUPER::refresh_token_params(@_);
    $params->{grant_type}   ||= 'refresh_token';
    $params;
}

#--------------------

sub build_request($$$)
{   my $self    = shift;
    my $request = $self->SUPER::build_request(@_);

    if(my $r = $self->referer)
    {   $request->header(Referer => $r);
    }

    $request;
}

#--------------------

1;

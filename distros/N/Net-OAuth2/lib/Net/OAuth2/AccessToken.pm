# Copyrights 2013-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Net-OAuth2.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Net::OAuth2::AccessToken;
use vars '$VERSION';
$VERSION = '0.66';

use warnings;
use strict;

our $VERSION;  # to be able to test in devel environment

use JSON::MaybeXS qw/encode_json/;
use URI::Escape   qw/uri_escape/;
use Encode        qw/find_encoding/;

# Attributes to be saved to preserve the session.
my @session = qw/access_token token_type refresh_token expires_at
   scope state auto_refresh/;

# This class name is kept for backwards compatibility: a better name
# would have been: Net::OAuth2::Session, with a ::Token::Bearer split-off.

# In the future, most of this functionality will probably need to be
# split-off in a base class ::Token, to be shared with a new extension
# which supports HTTP-MAC tokens as proposed by ietf dragt
#   http://datatracker.ietf.org/doc/draft-ietf-oauth-v2-http-mac/


sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;

    $self->{NOA_expires_at} = $args->{expires_at}
       || ($args->{expires_in} ? time()+$args->{expires_in} : undef);

    # client is the pre-v0.50 name
    my $profile = $self->{NOA_profile} = $args->{profile} || $args->{client}
        or die "::AccessToken needs profile object";

    $self->{NOA_access_token}  = $args->{access_token};
    $self->{NOA_refresh_token} = $args->{refresh_token};
    $self->{NOA_refresh_always}= $args->{refresh_always};
    $self->{NOA_scope}         = $args->{scope};
    $self->{NOA_state}         = $args->{state};
    $self->{NOA_hd}            = $args->{hd};
    $self->{NOA_token_type}    = $args->{token_type};
    $self->{NOA_auto_refresh}  = $args->{auto_refresh};
    $self->{NOA_changed}       = $args->{changed};

    $self->{NOA_error}         = $args->{error};
    $self->{NOA_error_uri}     = $args->{error_uri};
    $self->{NOA_error_descr}   = $args->{error_description} || $args->{error};

    $self->{NOA_attr}          = $args;
    $self;
}


sub session_thaw($%)
{   my ($class, $session) = (shift, shift);
    # we can use $session->{net_oauth2_version} to upgrade the info
    $class->new(%$session, @_);
}

#--------------

sub token_type() {shift->{NOA_token_type}}
sub scope()      {shift->{NOA_scope}}
sub state()      {shift->{NOA_state}}
sub hd()         {shift->{NOA_hd}}
sub profile()    {shift->{NOA_profile}}


sub attribute($) { $_[0]->{NOA_attr}{$_[1]} }


sub changed(;$)
{   my $s = shift; @_ ? $s->{NOA_changed} = shift : $s->{NOA_changed} }


sub access_token()
{   my $self = shift;

    if($self->expired)
    {   delete $self->{NOA_access_token};
        $self->{NOA_changed} = 1;
        $self->refresh if $self->auto_refresh;
    }
    elsif($self->refresh_always)
    {   $self->refresh;
    }

    $self->{NOA_access_token};
}

#---------------

sub error()      {shift->{NOA_error}}
sub error_uri()  {shift->{NOA_error_uri}}
sub error_description() {shift->{NOA_error_descr}}

#---------------

sub refresh_token()  {shift->{NOA_refresh_token}}
sub refresh_always() {shift->{NOA_refresh_always}}
sub auto_refresh()   {shift->{NOA_auto_refresh}}


sub expires_at() { shift->{NOA_expires_at} }


sub expires_in() { shift->expires_at - time() }


sub expired(;$)
{   my ($self, $after) = @_;
    my $when = $self->expires_at or return;
    $after = 15 unless defined $after;
    $when < time() + $after;
}


sub update_token($$$;$)
{   my ($self, $token, $type, $exp, $refresh) = @_;
    $self->{NOA_access_token}  = $token;
    $self->{NOA_token_type}    = $type if $type;
    $self->{NOA_expires_at}    = $exp;

    $self->{NOA_refresh_token} = $refresh
        if defined $refresh;

    $token;
}

#--------------

sub to_json()
{   my $self = shift;
    encode_json $self->session_freeze;
}
*to_string = \&to_json;  # until v0.50


sub session_freeze(%)
{   my ($self, %args) = @_;
    my %data    = (net_oauth2_version => $VERSION);
    defined $self->{"NOA_$_"} && ($data{$_} = $self->{"NOA_$_"}) for @session;
    $self->changed(0);
    \%data;
}


sub refresh()
{   my $self = shift;
    $self->profile->update_access_token($self);
}

#--------------

sub request{ my $s = shift; $s->profile->request_auth($s, @_) }
sub get    { my $s = shift; $s->profile->request_auth($s, 'GET',    @_) }
sub post   { my $s = shift; $s->profile->request_auth($s, 'POST',   @_) }
sub delete { my $s = shift; $s->profile->request_auth($s, 'DELETE', @_) }
sub put    { my $s = shift; $s->profile->request_auth($s, 'PUT',    @_) }

1;

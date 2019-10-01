# Copyrights 2013-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Net-OAuth2.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Net::OAuth2::Profile::Password;
use vars '$VERSION';
$VERSION = '0.66';

use base 'Net::OAuth2::Profile';

use warnings;
use strict;

use URI;
use Net::OAuth2::AccessToken;
use HTTP::Request;


sub init($)
{   my ($self, $args) = @_;
    $args->{grant_type} ||= 'password';
    $self->SUPER::init($args);
    $self;
}

#-------------------

#--------------------


sub get_access_token(@)
{   my $self = shift;

    my $request  = $self->build_request
      ( $self->access_token_method
      , $self->access_token_url
      , $self->access_token_params(@_)
      );

    my $response = $self->request($request);

    Net::OAuth2::AccessToken->new(client => $self
      , $self->params_from_response($response, 'access token'));
}

1;

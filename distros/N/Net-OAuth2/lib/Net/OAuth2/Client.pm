# Copyrights 2013-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Net-OAuth2.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Net::OAuth2::Client;
use vars '$VERSION';
$VERSION = '0.66';

use warnings;
use strict;

use LWP::UserAgent ();
use URI            ();

use Net::OAuth2::Profile::WebServer;
use Net::OAuth2::Profile::Password;


sub new($$@)
{   my ($class, $id, $secret, %opts) = @_;

    $opts{client_id}     = $id;
    $opts{client_secret} = $secret;

    # auto-shared user-agent
    $opts{user_agent}  ||= LWP::UserAgent->new;

    bless \%opts, $class;
}

#----------------

sub id()         {shift->{NOC_id}}
sub secret()     {shift->{NOC_secret}}
sub user_agent() {shift->{NOC_agent}}

#----------------

sub web_server(@)
{   my $self = shift;
    Net::OAuth2::Profile::WebServer->new(%$self, @_);
}



sub password(@)
{   my $self = shift;
    Net::OAuth2::Profile::Password->new(%$self, @_);
}

1;

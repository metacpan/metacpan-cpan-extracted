package Solstice::ErrorHandler;

=head1 NAME

Solstice::ErrorHandler - A superclass for application error handlers with lots of helpful methods.

=head1 SYNOPSIS

    my $handler = Solstice::ErrorHandler->new($error);
    $handler->handleError();

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::Configure;
use Solstice::Email;
use Solstice::CGI;
use Solstice::Server;


use constant SUCCESS => 1;
use constant FAIL    => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new($error)

=cut

sub new {
    my $obj = shift;
    my ($error) = @_;
    
    my $self = bless {}, $obj;

    $self->setError($error);
    
    return $self;
}

=item setError($error)

=cut

sub setError {
    my $self = shift;
    $self->{'_error'} = shift;
}

=item getError()

=cut

sub getError {
    my $self = shift;
    return $self->{'_error'};
}

=item handleError()

=cut

sub handleError {
    die 'Not implemented';
}

=item sendAlert($name)

=cut

sub sendAlert {
    my $self = shift;
    my $name = shift || 'Solstice';

    my $config = Solstice::Configure->new();

    my $body = 'URL: '. Solstice::Server->new()->getURI() ."\n";
    my $sess_user = eval{ return Solstice::UserService->new()->getUser()->getLoginName();};
    if(!$@ && $sess_user){
        $body .="Session User: $sess_user\n";
    }

    $@ = undef;
    my $orig_user = eval{ return Solstice::UserService->new()->getOriginalUser()->getLoginName();};
    if(!$@ && $orig_user){
        $body .="Original User: $orig_user\n";
    }
    $body .= $self->getError() . "\n\n";
    $body .= $self->_getParams();
    eval { $body .= (Solstice::Session->new()->hasSession()) ? $self->_getSessionVars() : ''; };
    $body .= "Error pulling session vars: $@" if $@;
    $body .= $self->_getEnVars();

    my $mail = Solstice::Email->new();
    $mail->to($config->getAdminEmail());
    $mail->from($config->getServerString().' <'. $config->getAdminEmail() .'>');
    $mail->subject("$name 500 Error");
    $mail->plainTextBody($body);
    $mail->send();

    return SUCCESS;
}

=item redirect($url)

=cut

sub redirect {
    my $self = shift;

    my $server = Solstice::Server->new();
    my $url = $server->getURI();

    $url .= "/" unless $url =~ /\/$/;
    
    $url .="?solstice_err=1";
    
    unless($server->getContentType()) {
        $server->setContentType("text/html");
    }
    $server->printHeaders();
        print "<html><head><meta http-equiv=\"refresh\" content=\"0;url=$url\"/></head><body><script type=\"text/javascript\">window.location=\"$url\";</script></body></html>\n";
    return SUCCESS;
}
    
=item _getEnVars()

=cut

sub _getEnVars {
    my $self = shift;
    
    my $content = '';
    if (%ENV) {
        $content .= "**** Environment Vars ****\n\n";
        for my $e (sort keys %ENV) { $content .= "$e = $ENV{$e}\n" }
    } else {
        $content .= "**** NO Environment Vars present ****\n\n";
    }
    return $content;
}

=item _getParams()

=cut

sub _getParams {
    my $self = shift; 

    my $content = '';
    if (param()) {
        $content .= "\n\n**** Form Input ****\n\n";
        for my $p (param()) { $content .= "$p => [" . param($p) . "]\n" }
    } else {
        $content .= "\n\n**** NO Form Input present ****\n\n";
    }
    return $content;
}

sub _getSessionVars {
    my $self = shift;
    my $session = Solstice::Session->new();
    
    my $content = "\n\n**** Session Information ****\n\n";
    $content .= "Session ID: ".$session->getSessionID()."\n";
    $content .= "Subsession Chain ID: ".$session->getSubsessionID()."\n";
    my $button = $self->getButtonService()->getSelectedButton();
    if($button){
        $content .= "Selected Button: ".$button->getName()."\n";
        $content .= "Button Action: ".$button->getAction()."\n";
    }
}

1;

__END__

=back

=head2 Modules Used

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2061 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

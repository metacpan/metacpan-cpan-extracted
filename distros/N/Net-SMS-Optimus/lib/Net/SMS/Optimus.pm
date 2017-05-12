package Net::SMS::Optimus;

use warnings;
use strict;
use Carp;

use LWP::UserAgent;
use HTTP::Cookies;
use HTML::Form;
use URI;

=head1 NAME

Net::SMS::Optimus - Send SMS through www.optimus.pt

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';
our (@ISA)    = qw/Exporter/;
our (@EXPORT) = qw/send_sms/;

=head1 SYNOPSIS

This module exports just one function that
is responsible for sending your sms through
www.optimus.pt portal.

    use Net::SMS::Optimus;

    send_sms($username, $password, $number, $msg);

=head1 EXPORT

send_sms

=head1 FUNCTIONS

=head2 send_sms

This function does all the magic. It receives the
following arguments:

=over 4

=item username

The username to the portal

=item password

...

=item number

A string containing the destination number

=item message

A string (no longer than 152 chars) containing the
message to be sent.

=back

The operation uses various phases, doing several
connections to the website, trying to mimic a real
human SMS send. If anything goes wrong, it croaks
and returns.

=cut

sub send_sms {
    my ($username, $password, $number, $message) = @_;

    # Do some checks
    croak "Username required" unless $username;
    croak "Password required" unless $password;
    croak "Number required" unless $number;
    croak "You must specify a message, asshole" unless $message;
    croak "Your message should be no more than 152 chars" unless (length $message) <= 152;

    # Initialize the browser
    my $browser = LWP::UserAgent->new(
        requests_redirectable => ['GET', 'HEAD', 'POST']
    );
    $browser->cookie_jar( {} );
    $browser->env_proxy;
    
    # Fase 1: Login
    my $res = $browser->get('http://optimus.pt/particulares/omeuoptimus/');
    $res->is_success or die "Error reading from www.optimus.pt (Phase 1)\n";
    
    my @forms = HTML::Form->parse($res);
    @forms = grep $_->attr("id") eq "aspnetForm", @forms;
    die "No login form found (Phase 1)\n" unless @forms;
    my $form = shift @forms;
    
    $form->value('ctl00$MainContentPlaceHolder$UserAuth1$TxtUsername', $username);
    $form->value('ctl00$MainContentPlaceHolder$UserAuth1$TxtPassword', $password);
    
    $res = $browser->request($form->click);
    $res->is_success or die "Error submiting login form (Phase 1)\n";
    
    $res->content =~ /Logout/ or die "Check username and/or password (Phase 1)\n";
    
    # Fase 2: Obter a form de SMS    
    $res->content =~ /id\=\"totalFreeSms\"\>(\d+)\</;
    print "Free SMS: $1\n";
    
    @forms = HTML::Form->parse($res);
    @forms = grep $_->attr("id") eq "aspnetForm", @forms;
    die "No sms form found (Phase 2)\n" unless @forms;
    $form = shift @forms;
    
    # Fase 3: Preencher a form e enviar
    my $url = URI->new('http://optimus.pt/OMeuOptimus/OptimusOnlineAjaxCalls/SendSms.aspx');
    $url->query_form(
      To => $number,
      Text => $message,
      Type => 'normal'
    );
    $res = $browser->get($url);   
    $res->is_success or die "Error submiting SMS form (Phase 3)\n";
    
    $res->content =~ /Resultados\>\<Correctos/ or die "Error sending SMS (Phase 3)\n";
    print "SMS Sent :)\n";
}

=head1 AUTHOR

Ruben Fonseca, C<< <root at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-sms-optimus at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-Optimus>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::Optimus

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-Optimus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-Optimus>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-Optimus>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-Optimus>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ruben Fonseca, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::SMS::Optimus

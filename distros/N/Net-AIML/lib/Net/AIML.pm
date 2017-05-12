package Net::AIML;
use strict;
use warnings;

our $VERSION = '0.0.5';


use HTTP::Request::Common qw(POST);
use LWP::Simple;
use LWP::UserAgent;
use XML::Smart;

use constant BOTURL => 'http://www.pandorabots.com/pandora/talk-xml';

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub tell {
    my ( $self, $input, $custid ) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy();
    my $req = POST BOTURL,
      [ botid => $self->{botid}, custid => $custid, input => $input ];
    my $res = $ua->request($req);
    if ( ! $res->is_success ) { return "sorry, I'm having connection problems"; }
    my $xs    = XML::Smart->new( $res->content );    # or whatever    
    my $error = qq[$xs->{result}{status}];
    if ($error) { warn $error; return; }
    return wantarray
      ? ( qq[$xs->{result}{that}], qq[$xs->{result}{custid}] )
      : qq[$xs->{result}{that}];
}

1;
__END__

1; # Magic true value required at end of module
__END__

=head1 NAME

Net::AIML - Perl interface to the Pandorabots.com AIML server

=head1 VERSION

Version 0.0.2

=head1 SYNOPSIS

    #!/usr/bin/perl
    package Alice;
    use Net::AIML;
    use IO::Prompt;

    my $bot = Net::AIML->new( botid => be50f516be367d9d ); # Alice
    while (prompt "You: ") {
    	print "Alice: ".$bot->tell($_)."\n";
    }  

=head1 DESCRIPTION

Pandorabots.com provides an XMLRPC interface to their AIML server. This module wraps that interface 
into an easy Perl OO interface. 

=head1 INTERFACE

Net::AIML exports exactly two methods.

=over 

=item C< new >

The only important parameter currently being c< botid > which identifies the 
bot you wish to use on Pandorabots.com. You can get this botid from Pandorabots.

=item C< tell >

Given a line of text, tell returns the line returned by pandorabots. 

=back 

=head1 CONFIGURATION AND ENVIRONMENT
  
Net::AIML uses LWP internally. Any environment variables that LWP supports should be supported 
by Net::AIML. I hope.

=head1 DEPENDENCIES

=over

=item L<HTTP::Request::Common>

=item L<LWP::Simple>

=item L<LWP::UserAgent>

=item L<XML::Smart>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-aiml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Chris Prather  C<< <cpan@prather.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Chris Prather C<< <cpan@prather.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


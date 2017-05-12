=head1 NAME

Petal::Mail - Format text e-mail using Petal


=head1 SYNOPSIS

  use Petal::Mail;
  use Petal::Mail;
  use Petal::Mail;
  use Petal::Mail;
  my $petal_mail = new Petal::Mail ('email.xml');
  my $text_mail  = $petal_mail->process (%args);


=head1 SUMMARY

L<Petal::Mail> processes a Petal XML template, and then turns the resulting XML
into a text email which can be sent through sendmail or other. The XML has to
follow a certain syntax which is defined in this documentation.

Since L<Petal::Mail>'s is a subclass of Petal, its API is the same. Which
means you need to read about L<Petal> before you can use L<Petal::Mail>.

=cut
package Petal::Mail;
use strict;
use warnings;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::Decode;
use Encode;
use base qw /Petal/;


=head1 GLOBAL / LOCAL VARIABLES

=head2 local $Petal::Mail::Line_Wrap = 68;

Amounts of characters allowed before text-flowed wrapping.

=head2 local $Petal::Mail::Indent = 4;

Amounts of whitespace when indenting <dd> tags

=head2 local $Petal::Mail::Sendmail = '/usr/sbin/sendmail -t';

If you set this variable to your sendmail executable, and make sure the
$ENV{SERVER_ADMIN} is set to a proper email address for processing bounces,
then you can use the send() method instead of the process() method and
Petal::Mail will send the email once it's been created.

=cut
our $Line_Wrap = 68;
our $DD_Indent = 4; 
our $Sendmail  = '/usr/sbin/sendmail -t';


# can't touch those
our $Decode    = new MKDoc::XML::Decode qw/xml xhtml numeric/;

=head1 FUNCTIONS

=head2 process

This function processes a template. It takes a hash or hashref which is used
to fill out any elements in the template. It returns the processed template as
a string. See L<Petal> for further details.

=cut
our $VERSION   = 0.31;

=head1 FUNCTIONS

=head2 process

This function processes a template. It takes a hash or hashref which is used
to fill out any elements in the template. It returns the processed template as
a string. See L<Petal> for further details.
=head2 send

This function processes a template and sends an email message according to the
headers in the template.  It takes the same parameters as process in addition
to the email address of the authorized sender. The authorized sender may also
be set with the environment parameter 'SERVER_ADMIN'. Returns null on success
or dies on failure.

	$petal_mail->send(AUTH_SENDER => 'lewis@carroll.net', %args);

=cut

=cut

=head1 FUNCTIONS

=head2 process

This function processes a template. It takes a hash or hashref which is used
to fill out any elements in the template. It returns the processed template as
a string. See L<Petal> for further details.
=head2 send

This function processes and sends an email message according to a template.
It takes the same parameters as process. Returns null(?) on success or dies on
failure.

=cut

=head1 FUNCTIONS

=head2 process

This function processes a template. It takes a hash or hashref which is used
to fill out any elements in the template. It returns the processed template as
a string. See L<Petal> for further details.
=head2 send

This function processes and sends an email message according to a template.
It takes the same parameters as process. Returns null(?) on success or dies on
failure.

=cut

sub process
{
    my $self = shift;
    my $xml  = $self->SUPER::process (@_);
    return $self->_xml_to_text ($xml);
}


=head2 send

This function processes and sends an email message according to a template.
It takes the same parameters as process. Returns null(?) on success or dies on
failure.

=cut
sub send
{
    my $self = shift;
    my %args = @_;
    my $authorized_sender = $args{'AUTH_SENDER'} || $ENV{SERVER_ADMIN} || '';
    delete $args{'AUTH_SENDER'};
    $authorized_sender || die 'No authorized sender defined and $ENV{SERVER_ADMIN} not set';
    
    my $mail = $self->process (%args)                    || die '$self->process (\@_) returned undef';
    open (SENDMAIL, "| $Sendmail -f $authorized_sender") || die "error opening sendmail [$Sendmail]: $!";
    binmode (SENDMAIL, ":utf8");
    print SENDMAIL $mail                                 || die "error writing to sendmail [$Sendmail]: $!";
    close SENDMAIL;
}


sub _xml_to_text
{
    my $self   = shift;
    my $xml    = shift;
    
    my @nodes  = MKDoc::XML::TreeBuilder->process_data ($xml);
    my @result = map {
	((ref $_) and ($_->{_tag} eq 'Message')) ?
	$self->__Message ($_) : ()
    } @nodes;
    
    return join "\n", @result;
}


sub __Message
{
    my $self    = shift;
    my $node    = shift;

    my $headers = $self->__Headers ($node);
    my $body    = $self->__Body    ($node);
    return join "\n\n", ($headers, $body);
}


sub __Headers
{
    my $self = shift;
    my $node = shift;
    my @res  = map {
	(ref $_ and $_->{_tag} !~ /^body$/i) ? do {
    	    my $text = $self->__Content_To_Text ($_);
	    $text = $Decode->process ($text);
	    $text =~ s/\n/ /gsm;
	    $text = encode ('MIME-Header', $text);
	    
	    my $tag  = $_->{_tag};
	    ($tag =~ /^from$/i) ?
	        ("$tag: $text", $self->__Headers_message_id ($text)) :
		("$tag: $text");
	} : ()
    } @{$node->{_content}};
    
    my $res  = join "\n", @res;
    return $res;
}


sub __Headers_message_id
{
    my $self = shift;
    my $id   = shift;
    my $time = time();
    my $rand = join '', map { chr (ord ('A') + int rand (26)) } 1..5;
    $id      =~ s/^.*<//;
    $id      =~ s/>.*$//;
    $id      =~ s/^\s+//;
    $id      =~ s/\s+$//;
    $id      =~ s/^.*\@//;
    $id      = "$time.$rand\@$id";
    return qq |Message-ID: <$id>|;
}


sub __Content_To_Text
{
    my $self = shift;
    my $node = shift;
    my @res  = map {
	(ref $_) ? ( $self->__Content_To_Text ($_) ) : ( $Decode->process ($_) )
    } @{$node->{_content}};
    return join '', @res;
}


sub __Body
{
    my $self = shift;
    my $node = shift;
    my @res  = map {
	(ref $_ and $_->{_tag} =~ /^body$/i) ?
	$self->__Body_Process ($_) : ()
    } @{$node->{_content}};

    my $res = join "\n", @res;
    $res =~ s/^\n+//gs;
    return $res;
}


sub __Body_Process
{
    my $self = shift;
    my $node = shift;
    
    my @res  = map {
	my $node = $_;
	$self->__Body_P   ($node) ||
	$self->__Body_DT  ($node) ||
	$self->__Body_DD  ($node) ||
	$self->__Body_PRE ($node) ||
	do { ref ($_) ? ( $self->__Body_Process ($node) ) : () }
    } @{$node->{_content}};
    
    my $res  = join '', @res;
    return $res;
}


sub __Body_PRE
{
    my $self = shift;
    my $node = shift;
    
    ref $node || return;
    return unless ($node->{_tag} =~ /^pre$/i);
    
    my $text = $self->__Content_To_Text ($node);
    return "\n\n$text";
}


sub __Body_P
{
    my $self = shift;
    my $node = shift;

    ref $node || return;
    return unless ($node->{_tag} =~ /^p$/i);
    
    my $text = $self->__Content_To_Text ($node);
    $text =~ s/\n/ /gsm;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    
    my @tokens = split /\s+/, $text;
    return "\n\n" . $self->_soft_wrap (@tokens);
}


sub __Body_DT
{
    my $self = shift;
    my $node = shift;
    
    ref $node || return;
    return unless ($node->{_tag} =~ /^dt$/i);
    
    # treat a DT as a paragraph
    $node->{_tag} = 'p';
    return $self->__Body_P ($node);
}


sub __Body_DD
{
    my $self = shift;
    my $node = shift;
    
    ref $node || return;
    return unless ($node->{_tag} =~ /^dd$/i);
    
    my $text = $self->__Content_To_Text ($node);
    $text =~ s/\n/ /gsm;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    
    my @tokens = split /\s+/, $text;
    
    local ($Line_Wrap) = $Line_Wrap - length ($DD_Indent);
    my $res = $self->_soft_wrap (@tokens);

    my $indent = $self->_text_indent();
    $res =~ s/\n/\n$indent/g;
    return "\n$indent$res";
}


sub _text_indent
{
    return " " x $DD_Indent;
}


sub _soft_wrap
{
    my $self   = shift;
    my @tokens = @_;
    
    my @res       = ();
    my @next_line = ();    
    while (@tokens)
    {
	my $next_token = shift (@tokens);
	my $potential_line = join " ", (@next_line, $next_token);
	
	if (length ($potential_line) > $Line_Wrap)
	{
	    if (@next_line == 0)
	    {
		push @res, $next_token;
	    }
	    else
	    {
		unshift (@tokens, $next_token);
		push @res, join " ", @next_line;
		@next_line = ();
	    }
	}
	else
	{
	    push @next_line, $next_token;
	}
    }
    
    push @res, join " ", @next_line unless (@next_line == 0);
    return join " \n", @res;
}


1;


__END__


=head1 XML Syntax

For L<Petal::Mail> to work properly, your resulting XML template must implement
the following syntax:

  <Message>
    <Header1>Value1</Header1>
    <Header2>Value2</Header2>
    <Header3>Value3</Header3>
    <body>
      <p>First Paragraph</p>
      <pre>Preformatted Text</pre>
      <dl>
        <dt>Definition Term</dt>
=back

Text contained in <p> tags will ignore white space characters (e.g., extra
spaces, tabs, carriage returns, etc.). See the XHTML specs at W3C for complete
details-- http://www.w3.org/MarkUp/.
        <dd>Definition List</dd>
      </dl>
    </Body>
  </Message>


As you can see, L<Petal::Mail>'s template syntax is quite simple:


=over 4

=item * It has one top element <Message> tag

=item * Each header is defined in a <Header> tag which MUST be a direct child of <Message>

=item * The body of the message is defined in the <Body> tag

=back

Text contained in <p> tags will ignore white space characters (e.g., extra
spaces, tabs, carriage returns, etc.). See the XHTML specs at W3C for complete
details-- http://www.w3.org/MarkUp/.
=back


As you can see, the content of the <Body> seems to be XHTML. However only a
subset of XHTML is supported and some extra limitations:

=over 4
=back

Text contained in <p> tags will ignore white space characters (e.g., extra
spaces, tabs, carriage returns, etc.). See the XHTML specs at W3C for complete
details-- http://www.w3.org/MarkUp/.

=item * Paragraphs "<p>"

=item * Preformatted text "<pre>"

=item * Definition lists "<dl>, <dt>, <dd>"

=item * Anything which is outside <p>, <pre>, <dt>, <dd> tags will be ignored / stripped
out

=back

Text contained in <p> tags will ignore white space characters (e.g., extra
spaces, tabs, carriage returns, etc.). See the XHTML specs at W3C for complete
details-- http://www.w3.org/MarkUp/.

=head1 Silly Example

Here's an example of an acceptable XML SPAM^H^H^H^H Email syntax. For
simplicity here I haven't used any TAL attributes, but you could have as much
TAL stuff as you'd want in there.

(I hope Damian doesn't mind my bad sense of humor)

  <Message>
    <Content-Type>text/plain; charset=utf-8; format=flowed</Content-Type>
    <Content-Disposition>inline</Content-Disposition>
    <Content-Transfer-Encoding>8bit</Content-Transfer-Encoding>
    <Content-Language>en</Content-Language>
    <MIME-Version>1.0</MIME-Version>
    <From>Mark Conway &lt;mark@bruce.csse.monash.edu.au&gt;</From>
    <To>Yourself &lt;your@self.net&gt;</To>
    <Subject>Please help me with important transaction</Subject>
    <User-Agent>MKDoc::Mail 0.1</User-Agent>
    <Precedence>bulk</Precedence>
    <Organization>Rather Messy</Organization>

    <body xmlns="http://www.w3.org/1999/xhtml">
      <p>Dear yourself,</p>

      <p>My name is Mark Conway. I am one of Damian Conway's illegitimate sons,
      the very famous Perl hacker who bringed tons of great crazy Perl modules.
      </p>

      <p>Unfortunately Damian, as you are aware, has been trampled by a Camel
      on his holiday to egypt. However, I had the surprise of being sent a letter of
      last will from Damian, who did not forgetting his secret sons.</p>

      <p>Damian left me the incredible amounts of FIFTY MILLION LINES OF OBFUSCATED
      PERL CODE (OPC 50,000,000.00) so that I can be seen as a great hacker and get
      some acknowledgement too.</p>

      <p>However I currently cannot publish this code because of USA and
      European patent laws. Since you live in Nigeria, I would request your
      cooperation for a mutually exceptionally profitable business.</p>

      <p>The operation would proceed as follows:</p>

      <dl>
        <dt>CPAN Account</dt>
        <dd>You give me your CPAN account username and password</dd>

        <dt>Login</dt>
        <dd>I log in CPAN as you</dd>

        <dt>Upload</dt>

	<dd>I delete all your code from... euh... I upload the FIFTY MILLION
        LINES OF OBFUSCATED PERL CODE (OPC 50,000,000.00) in your CPAN account</dd>

        <dt>Which gives you...</dt>
        <dd>Fame!</dd>
      </dl>

      <p>Of course, as a compensation, I will subscribe myself as a module
      co-author, effectively grabbing about half the fame you'll get for these
      modules. Which will still leave you a whopping TWENTY FIVE MILLION LINES OF
      OBFUSCATED PERL CODE (OPC 25,000,000.00)</p>

     <pre>-- 
  Yours Faithfully,
  Mark Conway, Illegitimate Son</pre>
    </body>
  </Message>


This gives the following output:

  Content-Type: text/plain; charset=utf-8; format=flowed
  Content-Disposition: inline
  Content-Transfer-Encoding: 8bit
  Content-Language: en
  MIME-Version: 1.0
  From: Mark Conway <mark@bruce.csse.monash.edu.au>
  Message-ID: <1067607400.IJCVT@bruce.csse.monash.edu.au>
  To: Yourself <your@self.net>
  Subject: Please help me with important transaction
  User-Agent: MKDoc::Mail 0.1
  Precedence: bulk
  Organization: Rather Messy
  
  Dear yourself,
  
  My name is Mark Conway. I am one of Damian Conway's illegitimate 
  sons, the very famous Perl hacker who bringed tons of great crazy 
  Perl modules.
  
  Unfortunately Damian, as you are aware, has been trampled by a Camel 
  on a holiday to egypt. However, I had the surprise of being sent a 
  letter from Damian. Not forgetting his secret son.
  
  Damian left me the incredible amounts of FIFTY MILLION LINES OF 
  OBFUSCATED PERL CODE (OPC 50,000,000.00) so that I can be seen as a 
  great hacker and get some acknowledgement too.
  
  However I currently cannot publish this code because of USA and 
  European patent law. Since you live in Nigeria, I would request your 
  cooperation for a mutually profitable business.
  
  The operation would proceed as follows:
  
  CPAN Account
      You give me your CPAN account username and password
  
  Login
      I log in CPAN as you
  
  Upload
      I remove all the code from... euh... I upload the FIFTY MILLION 
      LINES OF OBFUSCATED PERL CODE (OPC 50,000,000.00) in your CPAN 
      account
  
  Which gives...
      Fame!
  
  Of course, as a compensation, I will subscribe myself as a module 
  co-author, effectively grabbing about half the fame you'll get for 
  these modules. Which will still leave you a whopping TWENTY FIVE 
  MILLION LINES OF OBFUSCATED PERL CODE (OPC 25,000,000.00)
  
  -- 
  Yours Faithfully,
  Mark Damian, Illegitimate Son

Note that the Message-ID is automatically generated from the <From> contents.
If you're not careful, SpamAssasin will pickup on inconsistant Message-ID,
which would make your SPAM^H^H^H^H informative newsletters useless.

Also note that the message headers are automatically MIME encoded using the
Encode module's 'MIME-Header' encoding facility. 


=head1 BUGS

Probably plenty.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  Petal: http://search.cpan.org/dist/Petal/
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut

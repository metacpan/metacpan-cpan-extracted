#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Email;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Email - Email plugin for the Nile framework.

=head1 SYNOPSIS

    $email = $app->plugin->email;
    # or create new object
    #$email = $app->plugin->email->new;

    $email->email({
        from    => 'ahmed@mewsoft.com',
        to      => 'ramy@domain.com',
        subject => 'Happy birthday Ramy',
        body    => 'Hello Ramy, Happy new year Ramy',
        type    => 'html', # 'html' or 'text' message type
        attach  => '/path/to/attachment', # optional attachment file
    });
        
=head1 DESCRIPTION

Nile::Plugin::Email - Email plugin for the Nile framework.

This plugin build on the top of L<Email::Sender::Simple> module which supports any transporter like L<Sendmail|Email::Sender::Transport::Sendmail>, L<SMTP|Email::Sender::Transport::SMTP> etc.

Plugin configuration can be set in the config file under the plugin section. 

Example plugin configuration for C<SMTP> transporter:

    <plugin>

        <email>
            <transport>SMTP</transport>
            <host>localhost</host>
            <ssl>0</ssl>
            <port>25</port>
            <timeout>120</timeout>
            <sasl_username></sasl_username>
            <sasl_password>0</sasl_password>
            <allow_partial_success>0</allow_partial_success>
            <helo>Hello from loclahost</helo>
            <localaddr>localhost</localaddr>
            <localport>1234</localport>
        </email>

    </plugin>

Example plugin configuration for C<Sendmail> transporter:

    <plugin>

        <email>
            <transport>Sendmail</transport>
            <sendmail>/usr/sbin/sendmail</sendmail>
        </email>

    </plugin>

If no configuration found, the module will search for Sendmail program and use it, if not found it will
try to connect to local SMTP server.

You also can set the transporter programmatically using the method L</transport> below.

=cut

use Nile::Plugin; # also extends Nile::Plugin

use Try::Tiny;
use Module::Load;
#use Net::SMTP::SSL;
use MIME::Entity;
use Email::Simple;
use Email::Sender::Simple qw(sendmail); # try_to_sendmail
use Email::Date::Format qw(email_date);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main { # our sub new {}

    my ($self, $arg) = @_;
    
    $self->type('html');
    $self->mailer("Nile");

    my $setting = $self->setting();
    
    my $transport = delete $setting->{transport};


    if ($transport) {
        $self->transport($transport, $setting);
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 email()

Send email with optional attachments quickly:
    
    $email->email({
        from    => 'ahmed@mewsoft.com',
        #from    => '"Ahmed Elsheshtawy" <ahmed@mewsoft.com>',
        to      => 'ramy@domain.com',
        subject => 'Happy birthday Ramy',
        body    => 'Hello Ramy, Happy new year Ramy',
        type    => 'html', # 'html' or 'text' message type, default 'html'
        attach  => '/path/to/attachment',   # optional attachment file
    });

Send email with many options:

    $email->email({

        from        => 'ahmed@mewsoft.com',
        to      => 'ramy@ramys.net',

        cc      => ['x@y.com', 'a@b.com', 'b@d.com'],
        bcc     => ['c@x.com', 'e@z.com', 'r@j.com'],

        subject => 'Happy birthday Ramy',
        
        # optional headers
        sender      => 'support@mewsoft.com', # set to the 'from' if not set
        #'Return-Path'  =>  '', # set to the 'from' if not set
        #'Reply-To'     =>  '', # set to the 'from' if not set
        #'X-Mailer'     =>  'Nile',
        #'X-Priority'   =>  3, # highest => 1, high => 2, normal => 3, low => 4, lowest => 5
        #Date       =>  email_date(), # automatically set to current date and time
        #Comments   =>  '',
        #Encrypted  =>  '',
        #References     =>  '',
        #'Message-ID'   =>  '',
        #'MIME-Version' =>  '',
        #Organization   =>  'Mewsoft',
        
        #multipart  => 'related',

        type        => 'html', # 'html' or 'text' message type, default 'html'

        # optional raw headers overried above and used as is
        header      => {
            "X-Mailer"          => '',
            "X-Accept-Language" => 'en',
        },
        
        # attachments
        attach      => [
            '/path/to/attachment1', 
            '/path/to/attachment2',
            '/path/to/attachment3',
            {
                Path => "/path/to/attachment4",
                # Mime::Entity options.
                Id => "...",
            }
        ],
    });

Set the email components one by one for more control:
    
    $email->from('ahmed@mewsoft.com');
    $email->to('x@domain.com');
    $email->cc(['a@b.com', 'b@c.com']);
    $email->bcc(['d@e.com', 'e@f.com']);
    $email->sender('company@mewsoft.com');
    $email->type('text');
    $email->mailer('Nile');
    $email->subject('Happy birthday');
    $email->body('Hello Ramy, Happy new year');
    
    # send the email
    $email->send();

=cut

sub email {

    my ($self, $args) = @_;
    
    # X-Priority: highest => 1, high => 2, normal => 3, low => 4, lowest => 5

    #    Bcc           Encrypted     Received      Sender
    #    Cc            From          References    Subject
    #    Comments      Keywords      Reply-To      To
    #    Content-*     Message-ID    Resent-*      X-*
    #    Date          MIME-Version  Return-Path
    #                  Organization

    foreach my $header (qw(from to cc bcc sender multipart Return-Path Reply-To X-Mailer X-Priority Subject
                                            Date Comments Encrypted References Message-ID MIME-Version Organization Content-Type
                                        )) {
        if (exists $args->{$header}) {
            $self->header->{$header} = $args->{$header}; #decode_utf8($args->{$header});
        }
    }

    $args->{header}->{'Return-Path'} ||= $args->{header}->{From};
    $args->{header}->{'Reply-To'} ||= $args->{header}->{From};

    if ($args->{type}) {
        $self->header->{'Content-Type'} = lc($args->{type}) eq "html" ? 
                'text/html; charset=' . $self->charset : 'text/plain; charset=' . $self->charset;
    }
    
    if (exists $args->{mailer}) {
        $self->header->{'X-Mailer'} = $args->{mailer};
    }

    # optional headers
    if (exists $args->{header}) {
        while (my ($k, $v) = each %{ $args->{header} }) {
            $self->header->{$k} = $v; #decode_utf8($v});
        }
    }
    
    #Content-Transfer-Encoding: 8bit
    #Content-type: text/html; charset=UTF-8

    if ($self->header->{type} =~ /text\/plain/i && !$self->format) {
        $self->format('flowed');
    }
    
    if ($args->{attach}) {
        $self->attach(ref($args->{attach}) eq 'ARRAY' ? @{$args->{attach}} : $args->{attach});
    }

    $self->subject($args->{subject}) if ($args->{subject});

    $self->body($args->{body} || $args->{message}) if ($args->{body} || $args->{message});
    
    $self->send;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 from()
    
    $email->from('ahmed@mewsoft.com');
    $from = $email->from;

Sets or returns the C<from> email address.

=cut

has 'from' => (
        is => 'rw',
    );

=head2 to()

    $email->to('ahmed@mewsoft.com');
    $to = $email->to;

Sets or returns the C<to> email address.

=cut

sub to {
    my ($self, @to) = @_;
    if (@to) {
        foreach my $to (@to) {
            push @{$self->to_list}, $to;
        }
    }
    else {
        @{$self->to_list};
    }
}

has 'to_list' => (
        is => 'rw',
        isa => 'ArrayRef',
        default => sub { [] }
    );

=head2 sender()
    
    # if not set, the from address will be used
    $email->sender('support@mewsoft.com');
    $sender = $email->sender;

Sets or returns the C<sender> email address.

=cut

has 'sender' => (
        is => 'rw',
    );

=head2 cc()
    
    $email->cc('x@mewsoft.com', 'y@mewsoft.com');
    @cc = $email->cc;

Sets or returns the C<cc> email addresses.

=cut

sub cc {
    my ($self, @cc) = @_;
    if (@cc) {
        foreach my $cc (@cc) {
            push @{$self->cc_list}, $cc;
        }
    }
    else {
        @{$self->cc_list};
    }
}

has 'cc_list' => (
        is => 'rw',
        isa => 'ArrayRef',
        default => sub { [] }
    );

=head2 bcc()

    $email->bcc('x@mewsoft.com', 'y@mewsoft.com');
    @bcc= $email->bcc;

Sets or returns the C<bcc> email addresses.

=cut

sub bcc {
    my ($self, @bcc) = @_;
    if (@bcc) {
        foreach my $bcc (@bcc) {
            push @{$self->bcc_list}, $bcc;
        }
    }
    else {
        @{$self->bcc_list}
    }
}

has 'bcc_list' => (
        is => 'rw',
        isa => 'ArrayRef',
        default => sub { [] }
    );

=head2 subject()
    
    $email->subject($subject);
    $subject = $email->subject;

Sets or returns the C<subject>.

=cut

has 'subject' => (
        is => 'rw',
    );

=head2 body()
    
    $email->body($body);
    $body = $email->body;

Sets or returns the C<body>.

=cut

has 'body' => (
        is => 'rw',
    );

=head2 encoding()
    
    # default is 'quoted-printable'
    $email->encoding($encoding);
    $encoding = $email->encoding;

Sets or returns the C<encoding>. Standard encodings are '7bit', '8bit', 'base64', 'binary', 'quoted-printable'.
Non-standard encodings are 'binhex', 'binhex40', 'mac-binhex40', 'mac-binhex', 'x-uu', 'x-uuencode'.

Encoding auto detected if not set.

=cut

has 'encoding' => (
        is => 'rw',
        #default => 'quoted-printable', # auto detected
    );

=head2 format()
    
    # $format = 'flowed';
    $email->format($format);
    $format = $email->format;

Sets or returns the C<format>.

=cut

has 'format' => (
        is => 'rw',
    );

=head2 charset()
    
    # default $charset = "UTF-8";
    $email->charset($charset);
    $charset = $email->charset;

Sets or returns the C<charset>.

=cut

has 'charset' => (
        is => 'rw',
        default => "UTF-8",
    );

=head2 multipart()
    
    # default is "mixed" for "multipart/mixed"
    $email->multipart("mixed");
    $multipart = $email->multipart;

Sets or returns the C<multipart>.

=cut

has 'multipart' => (
        is => 'rw',
    );

=head2 header()
    
    $email->header->{$name} = $value;
    $value = $email->header->{$name};

Sets or returns the C<header> entries.

=cut

has 'header' => (
        is => 'rw',
        isa => 'HashRef',
        default => sub { +{} }
    );

has 'attachments' => (
        is => 'rw',
        isa     => 'ArrayRef',
        default => sub { [] },
   );

has 'transporter' => (
        is => 'rw',
   );

=head2 type()
    
    # html email message
    $email->type("html");
    
    # text/plain email message
    $email->type("text");

Sets or returns the message content type.

=cut

sub type {
    my ($self, $type) = @_;
    if ($type) {
        $self->header->{'Content-Type'} = lc($type) eq "html" ? 'text/html; ' : 'text/plain; ';
        $self->header->{'Content-Type'} .= "charset=" . $self->charset;
    }
    else {
        return $self->header->{'Content-Type'};
    }
}

=head2 mailer()
    
    $email->mailer("Nile");
    
Sets or returns the header C<X-Mailer>.

=cut

sub mailer {
    my ($self, $mailer) = @_;
    if ($mailer) {
        $self->header->{'X-Mailer'} = $mailer;
    }
    else {
        return $self->header->{'X-Mailer'};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 attach()
    
    $email->attach('/path/to/attachment1');
    $email->attach('/path/to/attachment2');

    $email->attach(
        '/path/to/attachment1',
        '/path/to/attachment2',
        '/path/to/attachment3',
        {
            Path => "/path/to/attachment4",
            # Mime::Entity options
            Id => "...",
        }
    );

Attach files to the email message.

=cut

sub attach {

    my ($self, @attach) = @_;
    
    my ($attach, %attach);

    foreach $attach (@attach) {
        if (ref($attach) eq 'HASH') {
            $attach->{Encoding} ||= 'base64';
            $attach->{Type} ||= $self->app->mime->for_file($attach->{Path});
        } 
        else {
            $attach = {
                Path     => $attach,
                Encoding => 'base64',
                Type     => $self->app->mime->for_file($attach),
            };
        }
        push @{$self->attachments}, $attach;
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 transport()
    
    $email->transport($transport, %options);
    
    # set transport to Sendmail program, path auto detected
    $email->transport('Sendmail');

    # set transport to Sendmail program, specify path to it
    $email->transport('Sendmail', { sendmail => '/usr/sbin/sendmail' });
    
    # set transport to SMTP with options
    $email->transport("SMTP", {
        host => 'mail.mewsoft.com', # the name of the host to connect to; defaults to localhost
        ssl => 0, # if true, connect via SSL; defaults to false
        port => 25, # port to connect to; defaults to 25 for non-SSL, 465 for SSL
        timeout => 180, # maximum time in secs to wait for server; default is 120
        sasl_username => '', # the username to use for auth; optional
        sasl_password => '', # the password to use for auth; required if username is provided
        allow_partial_success => 0, # if true, will send data even if some recipients were rejected; defaults to false
        helo => 'mail.mewsoft.com', # what to say when saying HELO; no default
        #localaddr => 'localhost', # local address from which to connect
        #localport =>'1234', # local port from which to connect
    });
    
    # custom transport
    #$transport = MyTransport->new();
    $email->transport($transport, %options);

Set the email transporter class. Can be C<Email::Sender::Transport> subclass
name like C<Sendmail>, C<SMTP>, etc or C<Email::Sender::Transport> type object.

To find available transporters, search cpan for L<Email::Sender::Transport|http://search.cpan.org/search?query=+Email%3A%3ASender%3A%3ATransport%3A&mode=all>

=cut

sub transport {
    
    my ($self, $transport, @arg) = @_;

    if ( $self->app->instance_isa($transport, 'Email::Sender::Transport') ) {
        $self->transporter($transport);
    }
    else {
        my $class = "Email::Sender::Transport::$transport";
        load $class;
        $self->transporter($class->new(@arg));
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 send()
    
    $email->send();

Send the email with current settings. This method is called automatically by the method C<email> to send the email.

=cut

sub send {
    my ($self) = @_;
    
    # get plugin setting from config files.  same as $self->setting("email");
    # setting method is inherited from Nile::Plugin the base class
    my $setting = $self->setting();
    
    #$self->app->dump($setting);
    
    $self->header->{Date} ||= email_date();
    
    my $email = MIME::Entity->build(
        Charset  => $self->charset,
        Encoding => $self->encoding || '',
        From => $self->from,
        Sender => ($self->sender || $self->from),
        To => $self->to_list,
        Cc => $self->cc_list,
        Bcc => $self->bcc_list,
        Subject => $self->subject,
        %{$self->header},
        Data => $self->body,
    );

    #$email->attach(Path => $gif_path, Type => "image/gif", Encoding => "base64");
    if (@{$self->attachments}) {
        if ($self->multipart) {
            #make_multipart [SUBTYPE], OPTSHASH...
            $email->make_multipart($self->multipart);
        }
        foreach my $attach (@{$self->attachments}) {
            $email->attach(%{$attach});
        }
    }

    # text/plain
    #       content_type => 'text/plain', charset => 'utf-8', encoding => 'quoted-printable', format => 'flowed',
    # text/html
    #       content_type => 'text/html',  charset => 'utf-8', encoding => 'quoted-printable',
    
    # return sendmail $email, $options; # dies on error
    try {
        sendmail($email, {
                ($self->transporter ? (transport => $self->transporter) : ()),
            });
        return;
    }
    catch {
        my $error = $_ || 'unknown error';
        #try {
        #   if ($error->isa('Email::Sender::Failure')) {
        #       $error = Email::Sender::Failure->message;
        #   }
        #};
        #say "Email status: ". $error;
        return $error;
    }
    
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

=head1 NAME

Synapse::MailSender - email notification system


=head1 About Synapse's Open Telephony Toolkit

L<Synapse::MailSender> is a part of Synapse's Wholesale Open Telephony Toolkit.

As we are refactoring our codebase, we at Synapse have decided to release a
substantial portion of our code under the GPL. We hope that as a developer, you
will find it as useful as we have found open source and CPAN to be of use to
us.


=head1 What is L<Synapse::MailSender> all about

Wether it's to send rate notifications, QOS alarms, rate import confirmation,
or credit limit warnings, doing wholesale telecom requires sending mail. Lots
of mail, in fact.

The goal of this module is to provide a simple and easy to work with email
sending library as well as a templating library. It is based on L<MIME::Lite>
to construct the mail and send it, and on L<Petal::Tiny> and
L<XML::Parser::REX> to provide an XML email templating framework.

This modules allows you to constructs emails which have:

=over 4

=item - an optional 'SetSender' attribute (set to 'From' by default)

=item - a 'From' field

=item - a 'To' field

=item - one or more optional 'Cc' (carbon copy) fields

=item - one or more optional 'Bcc' (blind carbon copy) fields

=item - a subject field

=item - One or more paragraphs, which will make up for the email contents, which
is ALWAYS pure text. This module is designed for boring and dull email
notifications.

=item - One or more optional file attachments, since it is useful for doing
things like attaching PDF invoices, Excel spreadsheets with statistics, or cdr
files in .CSV format for instance.

=back

=head1 A simple example:

Say you have template.xml:

    <xml>
      <From petal:content="yaml/From">From</From>
      <To petal:content="yaml/To">To</To>
      <Subject petal:content="yaml/Subject">Subject</Subject>
      <Say>Hello, World</Say>
    </xml>

And somedata.yaml

    ---
    From: foo@bar.net
    To: baz@buz.com
    Subject: foo bar baz buz

You can use the provided script synapse-mailsender and type in the following
command to have your email sent out:

    synapse-mailsender ./template.xml ./somedata.yaml


=head1 API 

=cut
package Synapse::MailSender;
use MIME::Lite;
use MIME::Type::FileName;
use XML::Parser::REX;
use Petal::Tiny;
use YAML::XS;
use Synapse::Logger;
use warnings;
use strict;

our $VERSION = '1.4';


=head2 $class->new();

Creates a new L<Synapse::Mail::Sender> object.

=cut
sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;
    $self->{Sendmail} ||= '/usr/sbin/sendmail';
    return $self;
}


=head2 $self->Sendmail ('/usr/local/bin/mysendmail');

Sets the sendmail command to use with MIME::Lite. By default, is set to
/usr/sbin/sendmail.

=cut
sub Sendmail {
    my $self = shift;
    $self->{Sendmail} = shift;
}


=head2 $self->From ('from@example.com');

Sets the 'From' field.

=cut
sub From {
    my $self = shift;
    $self->{From} = [ @_ ];
}


=head2 $self->To ('to@example.com');

Sets the 'To' field.

=cut
sub To {
    my $self = shift;
    $self->{To} = [ @_ ];
}


=head2 $self->Cc ('cc@example.com');

Adds a carbon copy recipient. Can be invoked multiple times to add more than
one carbon copy recipients.

=cut
sub Cc {
    my $self = shift;
    $self->{Cc} ||= [];
    push @{$self->{Cc}}, @_;
}


=head2 $self->Bcc ('cc@example.com');

Adds a 'blind carbon copy' recipient. Can be invoked multiple times to add more
than one blind carbon copy recipients.

=cut
sub Bcc {
    my $self = shift;
    $self->{Bcc} ||= [];
    push @{$self->{Bcc}}, @_;
}


=head2 $self->Subject ('Your account is over limit');

Sets the 'Subject' field.

=cut
sub Subject {
    my $self = shift;
    $self->{Subject} = shift;
}


=head2 $self->SetSender ('Your account is over limit');

Sets the 'SetSender' field. If not set, the 'From' field will be used, which is
what you want most of the time anyways.

=cut
sub SetSender {
    my $self = shift;
    $self->{SetSender} = shift;
}


=head2 $self->Body ('Dear Customer');

Adds a paragraph to the text body. i.e. you can call this method once per
paragraph.

=cut
sub Body {
    my $self = shift;
    $self->{Body} ||= [];
    push @{$self->{Body}}, @_;
}


=head2 $self->Say ('Dear Customer');

Alias for Body(), looks nicer in templates.

=cut
sub Say {
    my $self = shift;
    $self->{Body} ||= [];
    push @{$self->{Body}}, @_;
}


=head2 $self->Para ('Dear Customer');

Another alias for Body(), can't make up my mind right now...

=cut
sub Para {
    my $self = shift;
    $self->{Body} ||= [];
    push @{$self->{Body}}, @_;
}


=head2 $self->Attach ('/path/to/file.xls');

Attaches a file to the message.

=cut
sub Attach {
    my $self = shift;
    $self->{Attach} ||= [];
    push @{$self->{Attach}}, @_;
}


sub None {}



=head2 $self->loadxml ($path_to_xml_template, option1 => $option1, option2 => $option2, etc)

Uses L<Petal::Tiny> to process $path_to_xml_template. Passes the following
arguments to the template:

=over 4

=item self : current L<Synapse::MailSender> object

=item anything else you pass to it, i.e. in this case 'option1' and 'option2'.

=back

Say your code looks like this:

    my $sMailSender = Synapse::MailSender->new();
    $sMailSender->loadxml ( '/opt/templates/accountsuspended.xml',
                            user => $user,
                            accountDetailsFile => $user->accountFile() );
    $sMailSender->send();


Your template itself may look roughly like this:

    <Message>
      <From petal:condition="true:user/from" petal:content="user/from">example@example.com</From>
      <To petal:condition="true:user/to" petal:content="user/to">example@example.com</To>
      <Cc petal:condition="true:user/cc" petal:repeat="cc user/cc" petal:content="cc">example@example.com</Cc>
      <Bcc petal:condition="true:user/bcc" petal:repeat="bcc user/bcc" petal:content="bcc">example@example.com</Bcc>
      <Subject>Your account is over limit</Subject>
      <Say>Dear Customer,</Say>
      
      <Say>Unfortunately, your account with a balance of <span petal:replace="user/balance">0.00</span>
      has reached its allowed limit.</Say>
      <Say>Your services are being suspended for now. We kindly request that you post a payment with us
      so that your account reaches its allowed credit limit.</Say>
      <Say>Get in touch.
Cheers
Ourselves (example@example.com)</Say>
      <Attach petal:condition="true:accountDetailsFile" petal:content="true:accountDetailsFile">some-file.xls</Attach>
    </Message>


=head2 $self->loadxml ($path_to_xml_template, $yamlfile)

Same as above, but passes a YAML file as options for template processing. The
Dumped YAML is passed as 'yaml' in the template.  option1 => $option1, option2
=> $option2, etc)


=head2 $self->loadxml ($xmldata, option1 => $option1, option2 => $option2, etc)

Same as above, but instead of passing an XML Template name, the XML template
data is passed directly.


=head2 $self->loadxml ($xmldata, $yamlfile)

Spame as above, but instead of passing an XML Template name, the XML template
data is passed directly.

Plus, passes a YAML file as options for template processing. The Dumped YAML is
passed as 'yaml' in the template.  option1 => $option1, option2 => $option2,
etc)


=cut
sub loadxml {
    my $self = shift;
    my $xml  = shift;
    my $tmpl = Petal::Tiny->new ($xml);
    my $res  = (@_ == 1) ? $tmpl->process (self => $self, yaml => _loadyaml (shift())) : $tmpl->process (self => $self, @_);
    $self->_loadxml($res);
}


sub _loadyaml {
    my $yamlfile = shift @_;
    open YAML, "<$yamlfile" or do {
        logger ("cannot read open YAML file $yamlfile");
        die "Cannot read open $yamlfile";
    };
    my $data = join '', <YAML>;
    close YAML;
    my $res = eval {
        my ($yaml) = Load $data;
        $yaml;
    };
    $@ and logger($@);
    return $res;
}


sub _loadxml {
    my $self    = shift;
    my $xmldata = shift;
    eval {
        my @tokens  = XML::Parser::REX::ShallowParse ($xmldata);
        my $method  = 'None';
        for (@tokens) {
            /^\<SetSender\>/i and do { $method = 'SetSender';    next };
            /^\<From\>/i      and do { $method = 'From';    next };
            /^\<To\>/i        and do { $method = 'To';      next };
            /^\<Cc\>/i        and do { $method = 'Cc';      next };
            /^\<Bcc\>/i       and do { $method = 'Bcc';     next };
            /^\<Subject\>/i   and do { $method = 'Subject'; next };
            /^\<Body\>/i      and do { $method = 'Body';    next };
            /^\<Say\>/i       and do { $method = 'Say';     next };
            /^\<Para\>/i      and do { $method = 'Para';    next };
            /^\<Attach\>/i    and do { $method = 'Attach';  next };
            /^\</             and do { $method = 'None';    next };
            $self->$method($_);
        }
    };
    $@ and logger($@);
}


=head2 $self->message();

Once you have configured your L<Synapse::MailSender> object with the methods
above, you can construct a L<MIME::Lite> object by invoking $self->message();

=cut
sub message {
    my $self = shift;
    
    my $from    = ref $self->{From} ? join ', ', @{$self->{From}} : $self->{From};
    my $to      = ref $self->{To}   ? join ', ', @{$self->{To}}   : $self->{To};
    my $cc      = ref $self->{Cc}   ? join ', ', @{$self->{Cc}}   : $self->{Cc};
    my $bcc     = ref $self->{Bcc}  ? join ', ', @{$self->{Bcc}}  : $self->{Bcc};
    my $subject = $self->{Subject};
    my $body    = join "\n\n", @{$self->{Body}};
     
    ### Create a new multipart message:
    my %args = (
        From    => $from,
        To      => $to,
        Subject => $subject,
        Type    => 'multipart/mixed'
    );
    $args{Cc} = $cc if ($cc);
    $args{Bcc} = $bcc if ($bcc);
    
    ### Add parts (each "attach" has same arguments as "new"):
    my $msg = MIME::Lite->new (%args);
    $msg->attach ( Type => 'TEXT', Data => $body );
    $self->{Attach} ||= [];
    foreach my $file ( @{$self->{Attach}} ) {
        my $type = MIME::Type::FileName::guess ($file);
        $msg->attach ( Type        => $type,
                       Path        => $file,
                       Disposition => 'attachment' );
    }
    
    ### return final object
    return $msg;   
}


=head2 $self->send();

Once you have configured your L<Synapse::MailSender> object with the methods
above, you can send the corresponding email message using this method.

=cut
sub send {
    my $self = shift;
    my $msg  = $self->message();
    my $str  = $msg->as_string; # somehow this seems to fix a bug where by sometimes the message is empty...
    $msg->send_by_sendmail (
        Sendmail  => $self->{Sendmail},
        SetSender => $self->{SetSender} || $self->{From}->[0],
    );
}


1;


__END__

=head1 EXPORTS

none.


=head1 BUGS

Please report them to me. Patches always welcome...


=head1 AUTHOR

Jean-Michel Hiver, jhiver (at) synapse (dash) telecom (dot) com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

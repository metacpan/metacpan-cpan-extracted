package RWDE::PostMaster;

use strict;
use warnings;

use base qw( RWDE::Singleton );

use Template;

use Net::SMTP;

use RWDE::Configuration;
use RWDE::RObject;

my $unique_instance;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 527 $ =~ /(\d+)/;

=pod

=head1 RWDE::Postmaster

This class implements methods that detail the sending of email. Both verp and standard emailing are implemented here, as 
well as methods for automatically reporting exceptions and hooks for assigning tickets to RT.

=cut

=head2 get_instance()

Return an instance of RWDE::Postmaster

=cut

sub get_instance {
  my ($self, $params) = @_;

  if (ref $unique_instance ne $self) {
    $unique_instance = $self->new;
  }

  return $unique_instance;
}

=head2 initialize()

Initialize an instance of RWDE::Postmaster. This includes pulling some data from the config file in order to find an
SMTP server and preparing to handle a mail template.

=cut

sub initialize {
  my ($self, $params) = @_;

  $self->{server} = RWDE::Configuration->get_SMTP();

  # create template object for future use
  $self->{template} = Template->new(
    {
      TAG_STYLE    => 'asp',
      PROCESS      => 'message.tt',
      INCLUDE_PATH => RWDE::Configuration->get_root . '/templates/emailmessages',
      VARIABLES    => {
        commify => \&RWDE::Utility::commify,
        global  => RWDE::Configuration->get_instance,
      },
    }
  ) or throw RWDE::DevelException({ info => 'Template::new failure.' });

  return ();
}

=head2 send_message ($smtp_sender, $smtp_recipient, $template)

Prepare or send a 1-to-1 message to the $smtp_recipient address, from $smtp_sender address, using $template as a template input
and the $params to populate the template. To alter the header from/to etc, edit the template.

=cut

sub send_message {
  my ($self, $params) = @_;

  my @required = qw( smtp_sender smtp_recipient template );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  # Process the message thru the Template
  my $output;

  my $postmaster = RWDE::PostMaster->get_instance();

  my $template = $postmaster->{template};

  unless ($template->process($$params{template}, $params, \$output)) {
    throw RWDE::DevelException({ info => $template->error() });
  }

  my $mh = new Net::SMTP($postmaster->{server})
    or throw RWDE::DevelException({ info => 'PostMaster::CONNECT failure ' . $postmaster->{server} });

  $mh->mail($$params{smtp_sender})
    or throw RWDE::DevelException({ info => 'PostMaster::SMTP FROM failure: ' . $postmaster->{server} . '::' . $mh->message() });

  $mh->recipient($$params{smtp_recipient})
    or throw RWDE::DevelException({ info => 'PostMaster::SMTP TO failure: ' . $postmaster->{server} . '::' . $mh->message() . ' for: ' . $$params{smtp_recipient} });

  $mh->data()
    or throw RWDE::DevelException({ info => 'PostMaster::DATA failure: ' . $postmaster->{server} . '::' . $mh->message() });
  $mh->datasend("Errors-To:$$params{smtp_sender}\n")
    or throw RWDE::DevelException({ info => 'PostMaster::DATASEND failure: ' . $postmaster->{server} . '::' . $mh->message() });
  $mh->datasend($output)
    or throw RWDE::DevelException({ info => 'PostMaster::DATASEND failure: ' . $postmaster->{server} . '::' . $mh->message() });

  $mh->dataend()
    or throw RWDE::DevelException({ info => 'PostMaster::DATA END failure, message NOT sent: ' . $postmaster->{server} . '::' . $mh->message() });

  $mh->quit();

  return ();
}

=head2 send_verp_message($smtp_sender, $recipients, $template)

Prepare or send a 1-to-many message to all the addresses contained within $recipients, from $smtp_sender address, using $template as a template input
and the $params to populate the template. To alter the header from/to etc, edit the template.

=cut

sub send_verp_message {
  my ($self, $params) = @_;

  my @failed;

  my @required = qw( smtp_sender recipients template);
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $postmaster = RWDE::PostMaster->get_instance();

  my @recipients = @{ $$params{recipients} };
  if (!(@recipients > 0)) {
    return;
  }

  # Process the message through the Template
  my $output;
  my $template = $postmaster->{template};

  unless ($template->process($$params{template}, $params, \$output)) {
    throw RWDE::DevelException({ info => $template->error() });
  }

  my $mh = new Net::SMTP($postmaster->{server})
    or throw RWDE::DevelException({ info => 'PostMaster::CONNECT failure' });

  #Limit to 1000 recipients per connection
  # if we get more, just bucketize them

  $mh->mail($$params{smtp_sender}, XVERP => 1)
    or throw RWDE::DevelException({ info => 'PostMaster::SMTP XVERP failure: ' . $mh->message() });

  my @good_recipients = $mh->recipient(@recipients, { SkipBad => 1 }) or ();

  $mh->data()
    or throw RWDE::DevelException({ info => 'PostMaster::DATA failure: ' . $mh->message() });

  $mh->datasend($output)
    or throw RWDE::DevelException({ info => 'PostMaster::DATASEND failure: ' . $mh->message() });

  $mh->dataend()
    or throw RWDE::DevelException({ info => 'DATA END failure, message NOT sent: ' . $postmaster->{server} . '::' . $mh->message() });

  $mh->quit();

  return \@good_recipients;
}

=head2 send_support_message($topic, $question)

Prepare or send a message to the support queue requested within $topic, from a Sender (specified in config file) using support.tt as a template input.
The $params are used to to populate the template. To alter the header from/to etc, edit the template.

This is a somewhat niche method utilized with pre-established support systems such as RT.

=cut

sub send_support_message {
  my ($self, $params) = @_;

  my $topic = $$params{topic}
    or throw RWDE::DataBadException({ info => 'No topic selected. Please select a topic so we can route your message properly' });

  my $question = $$params{question}
    or throw RWDE::DataBadException({ info => 'Sorry, we didn\'t receive your message.  Please try sending it again.' });

  $self->send_message(
    {
      smtp_sender    => RWDE::Configuration->Sender,
      smtp_recipient => RWDE::Configuration->$topic,
      template       => 'support.tt',

      #-- template params
      params => $params,
    }
  );

  return ();
}

=head2 send_report_message($topic, $question, $template)

Prepare or send a message to the ErrorReport address specified in the config file, from Sender - also specified in the config file.
Uses report.tt as a template input. The $params are used to to populate the template. To alter the header from/to etc, edit the template.

This method is extremely useful in addressing uncaught exceptions, if the system is configured correctly those messages will get sent 
via this method.

=cut

sub send_report_message {
  my ($self, $params) = @_;

  $$params{smtp_sender}    = RWDE::Configuration->Sender;
  $$params{smtp_recipient} = RWDE::Configuration->ErrorReport;
  $$params{template}       = 'report.tt';

  $self->send_message($params);

  return ();
}

1;

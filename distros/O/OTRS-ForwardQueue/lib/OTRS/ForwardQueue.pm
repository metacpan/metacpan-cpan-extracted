package OTRS::ForwardQueue;

use 5.014;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Email::Sender::Simple;
use Email::Sender::Transport::SMTP;
use Email::Simple;
use Email::Simple::Creator;

use Template;

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::Ticket;
use Kernel::System::Ticket::Article;

our $VERSION = '0.13';

has 'query' => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef',
  required => 1,
  handles => {
    get_query => 'get',
    set_query => 'set',
  },
);

has 'options' => (
  traits => ['Hash'],
  is => 'ro',
  isa => 'HashRef',
  required => 1,
  handles => {
    get_option => 'get',
    exists_option => 'exists',
    defined_option => 'defined',
  },
);

sub process_queue
{
  my $self = shift;

  # Create all objects necessary for searching tickets
  # Taken from documentation for Kernel::System::Ticket
  my $ConfigObject = Kernel::Config->new();

  if ($self->exists_option('TempDir') && $self->defined_option('TempDir'))
  {
    $ConfigObject->Set( Key => 'TempDir', Value => $self->get_option('TempDir') );
  }

  my $EncodeObject = Kernel::System::Encode->new(
    ConfigObject => $ConfigObject,
  );

  my $LogObject = Kernel::System::Log->new(
    ConfigObject => $ConfigObject,
    EncodeObject => $EncodeObject,
  );

  my $TimeObject = Kernel::System::Time->new(
    ConfigObject => $ConfigObject,
    LogObject    => $LogObject,
  );

  my $MainObject = Kernel::System::Main->new(
    ConfigObject => $ConfigObject,
    EncodeObject => $EncodeObject,
    LogObject    => $LogObject,
  );

  my $DBObject = Kernel::System::DB->new(
    ConfigObject => $ConfigObject,
    EncodeObject => $EncodeObject,
    LogObject    => $LogObject,
    MainObject   => $MainObject,
  );

  my $TicketObject = Kernel::System::Ticket->new(
    ConfigObject       => $ConfigObject,
    LogObject          => $LogObject,
    DBObject           => $DBObject,
    MainObject         => $MainObject,
    TimeObject         => $TimeObject,
    EncodeObject       => $EncodeObject,
  );  
  
  # Always return results as an array, as we use Ticket ID to obtain any additional
  # information (results as a hash includes Ticket Number as well)
  $self->set_query('Result' => 'ARRAY');
  
  my @results = $TicketObject->TicketSearch(%{$self->query});
  
  foreach my $ticket_id (@results)
  {
    if ($self->exists_option('Debug') && $self->defined_option('Debug') && $self->get_option('Debug'))
    {
      print "Processing ticket ID: $ticket_id\n";
    }
    
    my %ticket = $TicketObject->TicketGet(
      TicketID => $ticket_id,
    );
    
    unless ($self->exists_option('DisableLocking') && $self->defined_option('DisableLocking') && $self->get_option('DisableLocking'))
    {
      # Lock ticket before proceeding, to prevent other users from accessing it
      my $lock_success = $TicketObject->TicketLockSet(
        Lock => 'lock',
        TicketID => $ticket_id,
        UserID => $self->get_query('UserID'),
        SendNoNotification => 1,
      );
    }
    
    unless ($self->exists_option('DisableEmail') && $self->defined_option('DisableEmail') && $self->get_option('DisableEmail'))
    {
      # First article in ticket will be the original user request - we need this for the
      # body of the forwarded email and the full From: field
      my %first_article = $TicketObject->ArticleFirstArticle(
        TicketID => $ticket_id,
      );
    
      my $from_address = $first_article{'From'};
      my $recipient = $self->get_option('ForwardTo');
      
      my $forward_email = Email::Simple->create(
        header => [
          To => $recipient,
          From => $from_address,
          Subject => $ticket{'Title'},
        ],
        body => $first_article{'Body'},
      );
      
      # Set additional mail options, including envelope from
      my %mail_options = (
        from => $first_article{'CustomerID'},
      );
      
      if ($self->exists_option('SMTP') && $self->defined_option('SMTP') && $self->get_option('SMTP'))
      {
        my $transport = Email::Sender::Transport::SMTP->new({
          host => $self->get_option('SMTPServer'),
        });
        
        $mail_options{'transport'} = $transport;
      }
      
      Email::Sender::Simple->send($forward_email, \%mail_options);
      
      if ($self->exists_option('NotifyCustomer') && $self->defined_option('NotifyCustomer') && $self->get_option('NotifyCustomer'))
      {
        # Produce the body of the response to the customer
        my $nc_tt = Template->new({
          INCLUDE_PATH => $self->get_option('TemplatesPath')
        }) || die "$Template::ERROR\n";
        
        my $nc_output = '';
        my $nc_vars = {
          ticket => \%ticket,
        };
				
				my $notify_template = 'notify_customer.tt';
				
				if ($self->exists_option('NotifyCustomerTemplate') && $self->defined_option('NotifyCustomerTemplate') && $self->get_option('NotifyCustomerTemplate'))
				{
					$notify_template = $self->get_option('NotifyCustomerTemplate');
				}
        
        $nc_tt->process($notify_template, $nc_vars, \$nc_output) || die $nc_tt->error() . "\n";
				
				my $from_address = $first_article{'ToRealname'};
				
				if ($self->exists_option('FromAddress') && $self->defined_option('FromAddress') && $self->get_option('FromAddress'))
				{
					$from_address = $self->get_option('FromAddress');
				}
        
        # Add a new article, which should be emailed automatically to the customer.
        # Remember that To/From are reversed here, since we are sending an email to
        # the customer who raised the ticket.
        my $article_id = $TicketObject->ArticleSend(
          TicketID => $ticket_id,
          ArticleType => 'email-external',
          SenderType => 'system',
          From => $from_address,
          To => $first_article{'From'},
          Subject => 'Ticket forwarded: ' . $ticket{'Title'},
          Body => $nc_output,
          Charset => 'ISO-8859-15',
          MimeType => 'text/plain',
          HistoryType => 'EmailCustomer',
          HistoryComment => 'Notified customer of ticket forwarding',
          UserID => $self->get_query('UserID'),
          AutoResponseType => 'auto reply',
          OrigHeader => {
            From => $from_address,
            To => $first_article{'From'},
            Subject => 'Ticket forwarded: ' . $ticket{'Title'},
          },
        );
      }
    }
        
    unless ($self->exists_option('DisableHistory') && $self->defined_option('DisableHistory') && $self->get_option('DisableHistory'))
    {
      # Log the change in the history
      my $history_success = $TicketObject->HistoryAdd(
        Name => $self->get_option('HistoryComment'),
        HistoryType => 'Misc',
        TicketID => $ticket_id,
        CreateUserID => $self->get_query('UserID'),
      );
    }
    
    unless ($self->exists_option('DisableClosing') && $self->defined_option('DisableClosing') && $self->get_option('DisableClosing'))
    {
      # Mark the ticket as successfully closed
      my $close_success = $TicketObject->TicketStateSet(
        State => 'closed successful',
        TicketID => $ticket_id,
        UserID => $self->get_query('UserID'),
        SendNoNotifications => 1,
      );
    }
  }
}

__PACKAGE__->meta->make_immutable;

1; # Magic true value required at end of module

=pod

=encoding UTF-8

=head1 NAME

OTRS::ForwardQueue - Forwards the contents of an OTRS queue to a given email address.

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use OTRS::ForwardQueue;

    %query = (
      Queues => ['MyQueue'],
      States => ['new', 'open'],
      Locks => ['unlock'],
      UserID => 1,
    );

    %options = (
      ForwardTo => 'nobody@example.org',
      TempDir => '/tmp',
      HistoryComment => 'Forward to other request system',
      SMTP => 1,
      SMTPServer => 'smtp.example.org',
      NotifyCustomer => 1,
      NotifyCustomerTemplate => 'notify_customer.tt',
      TemplatesPath => '/usr/local/templates',
      Debug => 1,
    );

    my $fq = OTRS::ForwardQueue->new('query' => \%query, 'options' => \%options);

    $fq->process_queue();

=head1 DESCRIPTION

This module queries the Open Technology Real Services (OTRS) ticket management
system for tickets matching the query provided and then forwards these
tickets to an email address, closing them in OTRS.

The following functions are provided:

=over

=item new(\%query, \%options)

Produced automatically by Moose, this is the constructor for the class.

=over

=item \%query

Reference to a hash which contains the query parameters. This takes the same
key/value pairs as the C<TicketSearch> function of C<Kernel::System::TicketSearch>,
except that the C<Result> value is always set to 'ARRAY'.

=item \%options

Required list of options which affect how the queue is processed.

=over

=item C<HistoryComment> (required): The comment left in the history of the ticket when it is forwarded to anther system.

=item C<TempDir> (optional): Override the temporary directory used by the OTRS cache. Probably needs to be set if you are not running the module as the web server user (e.g. apache). If you get errors about file permissions, try setting this to C<'/tmp'>.

=item C<ForwardTo> (required): The email address to forward tickets to.

=item C<DisableLocking> (optional): Set to 1 to disable locking of forwarded tickets. Default behaviour is to lock tickets.

=item C<DisableHistory> (optional): Set to 1 to disable leaving a comment in the history (effectively makes C<HistoryComment> redundant). Default behaviour is to add a comment.

=item C<DisableClosing> (optional): Set to 1 to disable closing the ticket after forwarding. Default behaviour is to mark ticket as 'closed successful'.

=item C<DisableEmail> (optional): Set to 1 to disable sending any emails, which effectively prevents forwarding of tickets. Default behaviour is to send email. Included as an option to allow module users to test their code before sending out emails.

=item C<SMTP> (optional): Set to 1 to use an SMTP server to send email, instead of the local MTA.

=item C<SMTPServer> (optional): Host name or IP address of the SMTP server to use. Only effective if C<SMTP> is set to 1.

=item C<NotifyCustomer> (optional): Set to 1 to create a new article on the ticket and notify the customer that it has been forwarded.

=item C<NotifyCustomerTemplate> (optional): Relative filename to template for customer notification. Required if C<NotifyCustomer> is set to 1.

=item C<TemplatesPath> (optional): Absolute path to template directory. Required if C<NotifyCustomerTemplate> is set.

=item C<Debug> (optional): Set to 1 to print extra debugging information, such as the IDs of forwarded tickets.

=back

=back

=item process_queue()

Processes the queue based on the options passed in the constructor.

=back

=head1 DEPENDENCIES

Perl version 5.14 or higher is required. You may be able to use the module with older versions of Perl, but this is neither tested nor supported.

This module requires the following modules:

=over 4

=item * L<Moose>

=item * L<namespace::autoclean>

=item * L<Email::Simple>

=item * L<Email::Sender>

=item * L<Template> - For dynamically producing the body of emails.

=back

Although some of the above modules are used for optional features, all the dependencies
must be installed as this module will attempt to import all of them.

You must also have the OTRS source installed and available via C<@INC>. This module has
been tested with OTRS 3.2.10 and 3.3.9.

=head1 RUNNING AS A CRON JOB

Running a script which uses this module as a cron job may require some additional tweaks.
The easiest way is to create a small wrapper script to set the various library paths
correctly, such as the one below:

    #!/bin/bash
    
    # Set this to the absolute path to your OTRS install, so those
    # modules can be loaded
    FQ_OTRS_LIB="-I/path/to/otrs"
    
    # Comment out this line if you are not using local::lib
    FQ_LOCAL_LIB="-I$HOME/perl5/lib/perl5"
    
    # Change this to the path of your script
    /usr/bin/perl "$FQ_OTRS_LIB" "$FQ_LOCAL_LIB" /path/to/script.pl

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs through the Github issue system:

L<https://github.com/pwaring/OTRS-ForwardQueue/issues>

=head1 AUTHOR

Paul Waring <paul.waring@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by University of Manchester.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

__END__

# ABSTRACT: Forwards the contents of an OTRS queue to a given email address.


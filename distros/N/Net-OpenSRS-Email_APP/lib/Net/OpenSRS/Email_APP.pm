package Net::OpenSRS::Email_APP;

use strict;
use warnings;
use vars qw($VERSION @ISA $APP_PROTOCOL_VERSION $Debug $Emit_Debug $Last_Error);
use Carp;
use IO::Socket::SSL;
use IO::Select;
use Errno;
use Time::HiRes qw(gettimeofday tv_interval);

=head1 NAME

Net::OpenSRS::Email_APP -- Communicate using the OpenSRS Email Service Account Provisioning Protocol

=head1 VERSION

Version 0.61

=cut 

our $VERSION = '0.61';
$APP_PROTOCOL_VERSION='3.4';
$Debug=0;
$Emit_Debug = sub { print STDERR join("\n", @_) . "\n"; };

# All possible OpenSRS Email Service APP environments
my %environments = (
    test => 'admin.test.hostedemail.com:4449',
    production => 'admin.hostedemail.com:4449',
);

# Default timeout
my $Timeout = 10;
my $Buf_len = 32768;

=head1 SYNOPSIS

    use strict;
    use Net::OpenSRS::Email_APP;

    my $app = new Net::OpenSRS::Email_APP(Environment=>'test',
                                          User=>'admin',
                                          Domain=>'example.com',
                                          Password=>'secret')
          || die "I encountered a problem: " . \ 
             Net::OpenSRS::Email_APP::errstr();

    $app->login();

    my $rows = $app->get_company_domains();
    foreach my $r (@$rows) {
       print "$r->{DOMAIN}\n";
    }

    $app->quit();

=head1 DESCRIPTION

    "Net::OpenSRS::Email_APP" provides an object interface for
    communicating OpenSRS Email Service Account Provisioning Protocol
    (APP).  For this module to be useful to you, you will need an
    OpenSRS reseller account, and MAC credentials.  This module uses
    IO::Socket::SSL, thus depends upon its presence to function.

=cut

=head1 CONSTRUCTOR

=head2 new ( [ARGS] ) 

    Creates a "Net::OpenSRS::Email_APP" object.  "new"
    requires the User, Domain and Password arguments in
    key-value pairs.
    
    The following key-value pairs are accepted:
    
      Environment   Either 'test' or 'production' - defaults to 'test'
      User          User for login() to use
      Domain        Domain for login() to use
      Password      Password for login() to use

=cut
sub new {
    my ($class, %arg) = @_;

    my $self = {};
    bless $self, $class;
    $self->_initialise(%arg);
    return $self;
}

sub _initialise {
    my ($self, %arg) = @_;

    my $env = delete $arg{Environment};
    if (defined $env && !exists $environments{$env}) {
        croak "Net::OpenSRS::Email_APP: Unsupported environment: $env";
    }

    # If unspecified, default to test
    if (defined $env) {
        $arg{PeerAddr} = $environments{$env};
    }
    else {
        $arg{PeerAddr} = $environments{test};
        $env = 'test';
    }

    $self->{environment} = $env;
    $self->{username}    = delete $arg{User};
    $self->{domain}      = delete $arg{Domain};
    $self->{password}    = delete $arg{Password};
    if (!defined $self->{username} || $self->{username} eq '') {
        croak 'Net::OpenSRS::Email_APP: User must be specified';
    }
    if (!defined $self->{domain} || $self->{domain} eq '') {
        croak 'Net::OpenSRS::Email_APP: Domain must be specified';
    }
    if (!defined $self->{password} || $self->{password} eq '') {
        croak 'Net::OpenSRS::Email_APP: Password must be specified';
    }

    # Hard-wire this, udp will never work
    $arg{Proto} = 'tcp';
 
    if (!exists $arg{Timeout}) {
        $arg{Timeout} = $Timeout;
    }

    if ($Debug) {
        $Emit_Debug->("Net::OpenSRS::Email_APP using:\nEnvironment: $self->{environment}\nHost/Port: $arg{PeerAddr}\nUser: $self->{username}\nDomain: $self->{domain}\nPassword: $self->{password}\nTimeout: $arg{Timeout}\n\n");
    }

    my $socket = new IO::Socket::SSL(%arg);
    $self->{socket} = $socket;
    return $self;
}

=head1 GENERAL METHODS

=head2 login ()

    Attempt to login to OpenSRS APP

=cut
sub login {
    my ($self) = @_;

    my $resp = $self->_read();
    $self->_send("VER VER=\"$APP_PROTOCOL_VERSION\"");
    my ($r_code, $r) = $self->_read();
    if ($r_code != 0) {
        confess "Unable to VER: $r";
    }

    my %args;
    $args{User}     = $self->{username};
    $args{Domain}   = $self->{domain};
    $args{Password} = $self->{password};
    my ($rows,$error) = $self->_call_opensrs(Required=>[qw/User Domain Password/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
        return 0;
    }

    return 1;
}

=head2 quit ()

    Close your APP connection

=cut
sub quit {
    my ($self) = @_;

    $self->_send('QUIT');
    my ($r_code, $r) = $self->_read();
    if ($r_code != 0) {
        carp "quit: Unsuccessful return from OpenSRS: ($r_code) $r";
    }
    my $socket = $self->{socket};
    $socket->close(SSL_fast_shutdown=>1);
}

=head2 debug ( $level, $debug_cb )

    Set the debug level, debug output will optionally be returned
    using supplied callback

    If $debug_cb is not supplied, output will be emitted via STDERR

=cut
sub debug {
    my ($self, $level, $debug_cb) = @_;

    if (defined $level && $level =~ /^\d+$/) {
        $Debug = $level;
    }

    if (defined $debug_cb && ref($debug_cb) eq 'CODE') {
        $Emit_Debug = $debug_cb;
    }
}

=head2 last_status ( )

    Returns an array containing the status code and status text from
    the last OpenSRS call

    Note: The status text may be undefined, you should test for this.

=cut
sub last_status {
    my ($self) = @_;

    my $status_code = $self->{status_code};
    my $status_text = $self->{status_text};

    return ($status_code, $status_text);
}

=head1 GET METHODS

=head2 get_admin ( [ARGS] )

    The privilege level of this mailbox

      Required: Domain Mailbox

=cut
sub get_admin {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_alternate_mailbox_names ( [ARGS] )

    Given a comma-seperated list of email addresses, provide a
    comma-seperated list of available alternatives

      Required: Mailbox_List

=cut
sub get_alternate_mailbox_names {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Mailbox_List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_company_domains ()

    A list of all domains

=cut
sub get_company_domains {
    my ($self) = @_;

    my ($rows, $error) = $self->_call_opensrs();
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain ( [ARGS] )

    Information about this domain

      Required: Domain

=cut
sub get_domain {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain_allow_list ( [ARGS] )

    The allowed senders list for this domain

      Required: Domain

=cut
sub get_domain_allow_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain_block_list ( [ARGS] )

    The blocked senders list for this domain

      Required: Domain

=cut
sub get_domain_block_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain_brand ( [ARGS] )

    The name of the brand associated to this domain

     Required: Domain

=cut
sub get_domain_brand {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain_mailboxes ( [ARGS] )

    The list of mailboxes for this domain
    
      Required: Domain

=cut    
sub get_domain_mailboxes {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain_mailbox_limits ( [ARGS] )

    Counts of each mailbox type permitted to be configured for
    this domain

      Required: Domain

=cut
sub get_domain_mailbox_limits {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_domain_workgroups ( [ARGS] )

    The list of workgroups for this domain

      Required: Domain

=cut

sub get_domain_workgroups {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_group_alias_mailbox ( [ARGS] )

    List the attributes and members of this mailing-list

      Required: Domain Group_Alias_Mailbox

=cut
sub get_group_alias_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Group_Alias_Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox ( [ARGS] )

    Information about this mailbox (ONLY regular and filter-only
    mailboxes)

      Required: Domain Mailbox

=cut
sub get_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_allow_list ( [ARGS] )

    The allowed senders list for this mailbox

      Required: Domain Mailbox

=cut
sub get_mailbox_allow_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_any ( [ARGS] )

    Information about this mailbox (INCLUDING forward-only and
    mailing-lists)

      Required: Domain Mailbox

=cut
sub get_mailbox_any {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_autorespond ( [ARGS] )

    The autoresponse state, text and attributes for this mailbox

      Required: Domain Mailbox

=cut
sub get_mailbox_autorespond {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_availability ( [ARGS] )

    Supplying a comma-seperated list of users, indicate whether
    they already exist or not

      Required: Domain Mailbox_List

=cut
sub get_mailbox_availability {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox_List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_block_list ( [ARGS] )

    The blocked senders list for this mailbox

      Required: Domain Mailbox

=cut
sub get_mailbox_block_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_forward ( [ARGS] )

    Configured forwarding details for this regular mailbox

      Required: Domain Mailbox

=cut
sub get_mailbox_forward {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_forward_only ( [ARGS] )

    Details for this forward-only mailbox

      Required: Domain Mailbox

=cut
sub get_mailbox_forward_only {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_mailbox_suspension ( [ARGS] )

    List the suspension status of each service for this mailbox

      Required: Domain Mailbox

=cut
sub get_mailbox_suspension {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 get_num_domain_mailboxes ( [ARGS] )

    Counts of each mailbox type and whether a domain
    catch-all is configured

      Required: Domain

=cut
sub get_num_domain_mailboxes {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 CREATE METHODS

=head2 create_alias_mailbox ( [ARGS] )

    Add an alias pointing to another mailbox on this domain
    
      Required: Domain Alias_Mailbox Mailbox

=cut
sub create_alias_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Alias_Mailbox Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_domain ( [ARGS] )

    Add a new domain
    
      Required: Domain
      Optional: Timezone Language FilterMX Spam_Tag Spam_Folder Spam_Level

=cut
sub create_domain {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Optional=>[qw/Timezone Language FilterMX Spam_Tag Spam_Folder Spam_Level/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_domain_alias ( [ARGS] )

    Creates a domain aliased to this one
    
      Required: Domain Alias
=cut
sub create_domain_alias {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Alias/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_domain_welcome_email ( [ARGS] )

    The welcome message to send to each new user for this domain
    
      Required: Domain Welcome_Text Welcome_Subject From_Name From_Address Charset Mime_Type

=cut
sub create_domain_welcome_email {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Welcome_Text Welcome_Subject From_Name From_Address Charset Mime_Type/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_group_alias_mailbox ( [ARGS] )

    Creates a mailing-list to the specified list of addresses
    
      Required: Domain Group_Alias_Mailbox Workgroup Alias_To_Email_CDL
      Optional: Spam_Level

=cut
sub create_group_alias_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Group_Alias_Mailbox Workgroup Alias_To_Email_CDL/], Optional=>[qw/Spam_Level/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_mailbox ( [ARGS] )

    Create a regular or filter-only mailbox
    
      Required: Domain Mailbox Workgroup Password
      Optional: FilterOnly First_Name Last_Name Phone Fax Title Timezone Lang Spam_Tag Spam_Folder Spam_Level

=cut
sub create_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox Workgroup Password/], Optional=>[qw/FilterOnly First_Name Last_Name Phone Fax Title Timezone Lang Spam_Tag Spam_Folder Spam_Level/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_mailbox_forward_only ( [ARGS] )

    Creates an alias which forwards to any single address
    
      Required: Domain Mailbox Workgroup Forward_Email
      Optional: Spam_Level

=cut
sub create_mailbox_forward_only {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox Workgroup Forward_Email/], Optional=>[qw/Spam_Level/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 create_workgroup ( [ARGS] )

    Create a workgroup within this domain
    
      Required: Domain Workgroup

=cut
sub create_workgroup {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Workgroup/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 DELETE METHODS

=head2 delete_domain ( [ARGS] )

    Delete this domain

      Required: Domain
      Optional: Cascade

=cut
sub delete_domain {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Optional=>[qw/Cascade/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_group_alias_mailbox ( [ARGS] )

    Deletes this mailing-list

      Required: Domain Group_Alias_Mailbox
    
=cut
sub delete_group_alias_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Group_Alias_Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_domain_alias ( [ARGS] )

    Delete this domain alias

      Required: Alias

=cut
sub delete_domain_alias {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Alias/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_domain_welcome_email ( [ARGS] )

    Delete the welcome email for this domain
    
      Required: Domain

=cut
sub delete_domain_welcome_email {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_mailbox ( [ARGS] )

    Deletes this regular or filter-only mailbox

      Required: Domain Mailbox
    
=cut
sub delete_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_mailbox_any ( $domain, $mailbox )

    Deletes this mailbox (irrespective of type)
    
      Required: Domain Mailbox

=cut
sub delete_mailbox_any {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_mailbox_forward_only ( [ARGS] )

    Deletes this forward-only mailbox

      Required: Domain Mailbox
    
=cut
sub delete_mailbox_forward_only {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 delete_workgroup ( [ARGS] )

    Delete a workgroup within this domain
    
      Required: Domain Workgroup
      Optional: Cascade

=cut
sub delete_workgroup {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/Cascade/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 CHANGE METHODS

=head2 change_domain ( [ARGS] )

    Change this domain's details

      Required: Domain (and at least one of the optionals)
      Optional: Timezone Language FilterMX Spam_Tag Spam_Folder Spam_Level

=cut
sub change_domain {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Optional=>[qw/Timezone Language FilterMX Spam_Tag Spam_Folder Spam_Level/], Required_Optional=>1, Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 change_group_alias_mailbox ( [ARGS] )

    Alter this mailing-list
    
      Required: Domain Group_Alias_Mailbox (and one optional)
      Optional: Alias_To_Email_CDL Spam_Level

=cut
sub change_group_alias_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Group_Alias_Mailbox/], Optional=>[qw/Alias_To_Email_CDL Spam_Level/], Required_Optional=>1, Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 change_mailbox ( [ARGS] )

    Alters this regular or filter-only mailbox
    
      Required: Domain Mailbox
      Optional: Workgroup Password FilterOnly First_Name Last_Name Phone Fax Title Timezone Language Spam_Tag Spam_Folder Spam_Level

    Note: When specifying FilterOnly, it may only be 'F' - you may change a filter-only mailbox to regular, but not the reverse.

=cut
sub change_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/Workgroup Password FilterOnly First_Name Last_Name Phone Fax Title Timezone Language Spam_Tag Spam_Folder Spam_Level/], Required_Optional=>1, Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 change_mailbox_forward_only ( [ARGS] )

    Alters this forward-only mailbox
    
      Required: Domain Mailbox Forward_Email
      Optional: New_Mailbox_Name Spam_Level

=cut
sub change_mailbox_forward_only {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox Forward_Email/], Optional=>[qw/New_Mailbox_Name Spam_Level/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 SET METHODS

=head2 set_domain_admin ( [ARGS] )

    Specify the domain administrator for this domain

      Required: Domain Mailbox
      Optional: State

=cut
sub set_domain_admin {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/State/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_domain_allow_list ( [ARGS] )

    Set the permitted sender list for this domain

      Required: Domain List

=cut
sub set_domain_allow_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_domain_block_list ( [ARGS] )

    Set the blocked sender list for this domain

      Required: Domain List

=cut
sub set_domain_block_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_domain_brand ( [ARGS] )

    Assign a brand for this domain

      Required: Domain Brand_Code

=cut
sub set_domain_brand {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Brand_Code/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_domain_catch_all_mailbox ( [ARGS] )

    Set the mailbox to receive mail for any non-existent recipients

      Required: Domain (and one of the optionals)
      Optional: Mailbox State

    Note: OpenSRS will return Internal system error if you attempt to
    set State='T' on a domain which currently does not have a
    catch-all mailbox.  OpenSRS have deprecated catch-all addresses.

=cut
sub set_domain_catch_all_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Optional=>[qw/Mailbox State/], Required_Optional=>1, Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_domain_disabled_status ( [ARGS] )

    Enable or disable this domain

      Required: Domain Disabled

=cut
sub set_domain_disabled_status {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Disabled/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_domain_mailbox_limits ( [ARGS] )

    Set the limit of each mailbox type which may be created on this domain

      Required: Domain
      Optional: Mailbox Filter_Only Alias Forward_Only Mailing_List

=cut
sub set_domain_mailbox_limits {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain/], Optional=>[qw/Mailbox Filter_Only Alias Forward_Only Mailing_List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}


=head2 set_mail_admin ( [ARGS] )

    Grant or revoke administrative privileges for this mailbox

      Required: Domain Mailbox
      Optional: State

=cut
sub set_mail_admin {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/State/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_mailbox_allow_list ( [ARGS] )

    Set the permitted sender list for this mailbox

      Required: Domain Mailbox List

=cut
sub set_mailbox_allow_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_mailbox_block_list ( [ARGS] )

    Set the blocked sender list for this mailbox

      Required: Domain Mailbox List

=cut
sub set_mailbox_block_list {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox List/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_mailbox_autorespond ( [ARGS] )

    Configure autoresponse for this mailbox

      Required: Domain Mailbox (and at least one optional)
      Optional: State Text

=cut
sub set_mailbox_autorespond {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/State Text/], Required_Optional=>1, Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_mailbox_forward ( [ARGS] )

    Configure forwarding for this mailbox

      Required: Domain Mailbox (and at least one optional)
      Optional: Forward Keep_Copy State

=cut
sub set_mailbox_forward {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/Forward Keep_Copy State/], Required_Optional=>1, Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_mailbox_suspension ( [ARGS] )

    Enable or disable services for this mailbox

      Required: Domain Mailbox
      Optional: SMTPIn SMTPRelay IMAP POP Webmail

=cut
sub set_mailbox_suspension {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/SMTPIn SMTPRelay IMAP POP Webmail/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 set_workgroup_admin ( [ARGS] )

    Add or remove a workgroup administrator

      Required: Domain Mailbox
      Optional: State

=cut
sub set_workgroup_admin {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Optional=>[qw/State/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 RENAME METHODS

=head2 rename_mailbox ( [ARGS] )

    Rename this regular mailbox and update all references to it

      Required: Domain Old_Mailbox New_Mailbox

=cut
sub rename_mailbox {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Old_Mailbox New_Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 VERIFY METHODS

=head2 verify_password ( [ARGS] )

    Verify this mailbox's password

      Required: Domain Mailbox Password

=cut
sub verify_password {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox Password/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 SHOW METHODS

=head2 show_available_offerings ( [ARGS] )

    Available offers for this mailbox

      Required: Domain Mailbox

=cut
sub show_available_offerings {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head2 show_enabled_offerings ( [ARGS] )

    The active offers for this mailbox

      Required: Domain Mailbox

=cut
sub show_enabled_offerings {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 DISABLE METHODS

=head2 disable_offering ( [ARGS] )

    Disables an active mailbox offer

      Required: Mailbox_Offering_ID

=cut
sub disable_offering {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Mailbox_Offering_ID/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

=head1 ENABLE METHODS

=head2 enable_offering ( [ARGS] )

    Activate the specified offer for this mailbox

      Required: Domain Mailbox Offering_ID
      Optional: Auto_Renew

=cut
sub enable_offering {
    my ($self, %args) = @_;

    my ($rows, $error) = $self->_call_opensrs(Required=>[qw/Domain Mailbox Offering_ID/], Optional=>[qw/Auto_Renew/], Args=>\%args);
    if (defined $error) {
        carp $error;
        $Last_Error = $error;
    }
    
    return $rows;
}

#
# Only internal routines from here on..
#
sub _reconnect {
    my ($self) = @_;

    if ($Debug) {
        $Emit_Debug->("_reconnect: Closing original connection\n");
    }
    
    my $environment = $self->{environment};
    my $username    = $self->{username};
    my $domain      = $self->{domain};
    my $password    = $self->{password};

    my $socket = $self->{socket};
    $socket->close(SSL_fast_shutdown=>1);
    
    $self->_initialise( Environment => $environment,
                        User        => $username,
                        Domain      => $domain,
                        Password    => $password ) || die "I encountered a problem: $Net::OpenSRS::Email_APP::Last_Error";

    if (!$self->login()) {
        die "unable to login to OpenSRS APP: $Net::OpenSRS::Email_APP::Last_Error";
    }
    
    return $self;
}

sub _call_opensrs {
    my ($self, %params) = @_;

    my ($sub, $cmd) = _generate_opensrs_cmd();
    my $args = _normalise_keys($params{Args});
    my @keys;
    my $error;

    if (exists $params{Required}) {
        foreach my $required (@{$params{Required}}) {
            my $r = uc($required);
            if (!exists $args->{$r} || !defined $args->{$r}) {
                $error = "$sub: Please supply $required";
                return (undef, $error);
            }

            push @keys, $r;
        }
    }
    
    if (exists $params{Optional}) {
        foreach my $optional (@{$params{Optional}}) {
            push @keys, uc($optional);
        }
    }
    
    if (exists $params{Required_Optional} && $params{Required_Optional} > 0) {
        my $expected_count = int(@{$params{Required}});
        $expected_count += $params{Required_Optional};
        my $actual_count = int(keys(%$args));
        if ($actual_count < $expected_count) {
            $error = "$sub: Please supply at least $params{Required_Optional} optional arguments";
            return (undef, $error);
        }
    }

    my $statement = "$cmd";
    foreach my $key (@keys) {
        if (exists $args->{$key}) {
            $statement .= " $key=\"$args->{$key}\"";
        }
    }
    
    $self->_send("$statement");
    my ($r_code, $r) = $self->_read();

    # Attempt a single retransmit if our read errorred
    if ($r_code != 0) {
        if ($Debug) {
            $Emit_Debug->("Got $r_code - $r, attempting reconnect and retransmit\n");
        }

        $self->_reconnect();
        $self->_send("$statement");
        ($r_code, $r) = $self->_read();
    }

    # Log the fact it *still* didn't work
    if ($r_code != 0) {
        $error = "$sub unsuccessful return from OpenSRS: ($r_code) $r";
        if ($Debug) {
            $Emit_Debug->("$sub unsuccessful return from OpenSRS: ($r_code) $r\n");
        }
        return (undef, $error);
    }

    return $r;
}

sub _normalise_keys(\%) {
    my ($args) = @_;
    my $new = {};
    foreach my $key (sort keys %$args) {
        $new->{uc($key)} = $args->{$key};
    }
    return $new;
}

sub _generate_opensrs_cmd {
    my ($sub) = (caller(2))[3] =~ /^.+::([^:]+)$/;
    return ($sub, uc($sub));
}

sub _send {
    my ($self, $msg) = @_;

    my $socket = $self->{socket};
    my $sel = new IO::Select $socket;
    unless ($sel->can_write($Timeout)) {
        if ($Debug) {
            $Emit_Debug->("_send: select can_write returns false\n");
        }
        $@ = '_send: timeout';
        $! = (exists &Errno::ETIMEDOUT ? &Errno::ETIMEDOUT : 1);
        return $!;
    }

    if ($Debug) {
        $Emit_Debug->("sending: $msg\n");
    }

    $SIG{PIPE} = 'IGNORE';
    my $bytes = syswrite($socket, sprintf("%s\r\n.\r\n", $msg));
    if (defined $bytes) {
        return 0;
    }

    # We likely got a SIGPIPE above, reconnect and try one more time
    $self->_reconnect();
    $socket = $self->{socket};
    $bytes = syswrite($socket, sprintf("%s\r\n.\r\n", $msg));
    if (defined $bytes) {
        return 0;
    }
    else {
        $@ = '_send: broken pipe';
        $! = (exists &Errno::EPIPE ? &Errno::EPIPE : 1);
        return $!;
    }
}

sub _read {
    my ($self) = @_;

    #
    # First lets read out the buffer a reasonable number of times
    # until we receive a complete response (signified by \r\n.\r\n)
    #
    my $buf;
    my $t0 = [gettimeofday()];
    my $elapsed = tv_interval($t0);
    my $complete_response = 0;
    while (!$complete_response && ($elapsed < $Timeout)) {
        if ($Debug > 1) {
            $Emit_Debug->("==enter buf read ==\ncomplete_response: $complete_response\nelapsed: $elapsed\nTimeout: $Timeout\n\n");
        }
        my $b = _read_buf($self);
        if (!defined $b) {
            return $!, $@;
        }
        
        $buf .= $b;

        if ($Debug) {
            $Emit_Debug->("read: [$b]\nbuf: [$buf]\n\n");
        }

        if ($buf =~ /\r\n\.\r\n/ms) {
            $complete_response = 1;
            last;
        }

        $elapsed = tv_interval($t0);
        if ($Debug > 1) {
            $Emit_Debug->("== buf read ==\ncomplete_response: $complete_response\nelapsed: $elapsed\n\n");
        }
    }

    if (!$complete_response) {
        return 1, "unable to receive complete response within $Timeout seconds\n";
    }

    
    my @response = split(/\r\n/, $buf);
    pop @response;

    #
    # Second, parse out the status-line, return if we encountered an error
    #
    my $status_line = shift @response;
    my ($status, $status_code, $status_text) = split(/\s+/, $status_line, 3);
    $self->{status_code} = $status_code;
    $self->{status_text} = $status_text;

    if ($status eq 'ER') {
        if (@response > 0) {
            if (!defined $status_text) {
                $status_text = '';
            }
            $status_text = join("\n", $status_text, @response);
        }

        $self->{status_text} = $status_text;

        my $error = "OpenSRS Email APP error: $status_code";
        if (defined $status_text) {
            $error .= ", $status_text";
        }

        if ($status_code > 0) {
            return $status_code, $error;
        }
        else {
            return 1, $error;
        }
    }

    #
    # Third, if there is any response lines, parse them into an array of hashes
    # OpenSRS's response differs depending upon whether this is a single or multi-row response
    #
    # Single-row response:
    # MAILBOX="sifl" WORKGROUP="staff"
    if (@response == 1) {
        my $row = _parse_single_row(shift @response);
        
        if (int(keys %$row) > 0) {
            return $status_code, $row;
        }
    }
    # Multi-row response:
    # MAILBOX DOMAIN WORKGROUP
    # ,
    # "sifl" "example.net" "staff"
    # ,
    # "ollie" "example.net" "staff"
    elsif(@response > 1) {
        my $rows = _parse_multiple_rows(\@response);
        return $status_code, $rows;
    }
}

#
# Okay this is insane, but due to the fact that key-val
# delimiter is space which is also present in values, this is
# the only way to parse values 100% safely.
# 
sub _parse_single_row {
    my ($line) = @_;
    my $row = {};
    
    my $within_key = 1;
    my $within_value = 0;
    my $seen_quote = 0;
    my $key;
    my $value;
    
    if ($Debug > 1) {
        $Emit_Debug->("Response: $line\n");
    }
    
    foreach my $char (split(//, $line)) {
        if ($Debug > 2) {
            $Emit_Debug->("char: $char ");
        }
        
        if ($within_key && $char ne '=') {
            if ($Debug > 2) {
                $Emit_Debug->("within_key and char ne =\n");
            }
            
            if ($char !~ /\s/) {
                $key .= $char;
            }
        }
        elsif ($within_key && $char eq '=') {
            if ($Debug > 2) {
                $Emit_Debug->("within_key and char eq =\n");
            }
            $within_key = 0;
        }
        elsif (!$within_key && !$within_value && $char eq '"') {
            if ($Debug > 2) {
                $Emit_Debug->("within_value and char eq \"\n");
            }
            $within_value = 1;
            $seen_quote = 0;
            $value = $char;
        }
        elsif ($within_value && !$seen_quote && $char eq '"') {
            if ($Debug > 2) {
                $Emit_Debug->("within_value and !seen_quote and char eq \"\n");
            }
            $seen_quote = 1;
            $value .= $char;
        }
        elsif ($within_value && $seen_quote && $char eq '"') {
            if ($Debug > 2) {
                $Emit_Debug->("within_value and seen_quote and char eq \"\n");
            }
            $seen_quote = 0;
            $value .= $char;
        }
        elsif ($within_value && $seen_quote && $char =~ /\s/) {
            if ($Debug > 2) {
                $Emit_Debug->("within_value and seen_quote and char matches space\n");
            }
            $seen_quote = 0;
            $within_value = 0;
            $within_key = 1;
            
            $value =~ s/^\"//;
            $value =~ s/\"$//;
            $value =~ s/\"\"/\"/g;
            
            $row->{$key} = $value;
            
            $key = undef;
            $value = undef;
        }
        elsif ($within_value && !$seen_quote) {
            if ($Debug > 2) {
                $Emit_Debug->("within_value and !seen_quote\n");
            }
            $value .= $char;
        }
    }

    if (defined $value && $value ne '' && $within_value && $seen_quote) {
        $value =~ s/^\"//;
        $value =~ s/\"$//;
        $value =~ s/\"\"/\"/g;
        
        $row->{$key} = $value;
    }
    
    return $row;
}

sub _parse_multiple_rows {
    my ($response) = @_;

    if ($Debug > 1) {
        $Emit_Debug->("Response: " . join("\n", @$response) . "\n");
    }

    my $rows = [];
    my $line_no = 0;
    my @keys;
    foreach my $line (@$response) {
        my $row = {};
        $line_no++;
        if ($line_no == 1) {
            foreach my $key (split(/\s+/, $line)) {
                if ($Debug > 2) {
                    $Emit_Debug->("found key $key\n");
                }
                push @keys, $key;
            }
        }
        elsif ($line eq ',') {
            next;
        }
        else {
            my $within_value = 0;
            my $seen_quote = 0;
            my $column = 0;
            my $value;
            foreach my $char (split(//, $line)) {
                if ($Debug > 2) {
                    $Emit_Debug->("char: $char ");
                }
                
                if (!$within_value && $char eq '"') {
                    if ($Debug > 2) {
                        $Emit_Debug->("within_value and char eq \"\n");
                    }
                    $within_value = 1;
                    $seen_quote = 0;
                    $value = $char;
                }
                elsif ($within_value && !$seen_quote && $char eq '"') {
                    if ($Debug > 2) {
                        $Emit_Debug->("within_value and !seen_quote and char eq \"\n");
                    }
                    $seen_quote = 1;
                    $value .= $char;
                }
                elsif ($within_value && $seen_quote && $char eq '"') {
                    if ($Debug > 2) {
                        $Emit_Debug->("within_value and seen_quote and char eq \"\n");
                    }
                    $seen_quote = 0;
                    $value .= $char;
                }
                elsif ($within_value && $seen_quote && $char =~ /\s/) {
                    if ($Debug > 2) {
                        $Emit_Debug->("within_value and seen_quote and char matches space\n");
                    }
                    $seen_quote = 0;
                    $within_value = 0;
                    
                    $value =~ s/^\"//;
                    $value =~ s/\"$//;
                    $value =~ s/\"\"/\"/g;

                    if ($Debug > 2) {
                        $Emit_Debug->("adding $keys[$column]: $value\n");
                    }
                    
                    if (exists $keys[$column]) {
                        $row->{$keys[$column]} = $value;
                    }
                    
                    $value = undef;
                    $column++;
                }
                elsif ($within_value && !$seen_quote) {
                    if ($Debug > 2) {
                        $Emit_Debug->("within_value and !seen_quote\n");
                    }
                    $value .= $char;
                }
            }

            if (defined $value && $value ne '' && $within_value && $seen_quote) {
                $value =~ s/^\"//;
                $value =~ s/\"$//;
                $value =~ s/\"\"/\"/g;
                
                if (exists $keys[$column]) {
                    $row->{$keys[$column]} = $value;
                }
            }
            
            push @$rows, $row;
        }
    }

    return $rows;
}

sub _read_buf {
    my ($self) = @_;
    my $buf;
    my $socket = $self->{socket};
    my $sel = new IO::Select $socket;
    if (!$sel->can_read($Timeout)) { 
        if ($Debug) {
            $Emit_Debug->("_read_buf: select can_read returns false\n");
        }
       
        $@ = 'read: timeout';
        $! = (exists &Errno::ETIMEDOUT ? &Errno::ETIMEDOUT : 1);
        return;
    }
    
    my $bytes = sysread($socket, $buf, $Buf_len);

    if ($bytes == 0) {
        $@ = 'read: connection closed';
        $! = (exists &Errno::EINTR ? &Errno::EINTR : 1);
        return;
    }

    return $buf;
}

1;

=head1 NOTES

The functions get_mailbox_status and set_mailbox_status are not
implemented, OpenSRS have tagged these functions as being deprecated.
Use get_mailbox_suspension and set_mailbox_suspension functions
instead.

=head1 AUTHOR

Mark Goldfinch, C<< mark.goldfinch at modicagroup.com >>

=head1 BUGS

The internal functions _parse_single_row and _parse_multiple_rows
currently make use some handwritten logic to correctly parse the rows
as returned by APP.  The OpenSRS supplied documentation includes an
ABNF definition for the entire protocol.  The handwritten logic could
likely be replaced by Parser::RecDescent (or similar) logic.  A hurdle
to this is the left-resolving the supplied ABNF uses,
Parser::RecDescent's design inhibits the use of left-resolving
parsing.  Patches are welcome to address this.  My testing suggests
the current handwritten logic is robust and functional however.

Other than presence of required arguments, no validation of supplied
arguments is currently performed.

Otherwise please report any bugs or feature requests to
C<bug-net-opensrs-email_app at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OpenSRS-Email_APP>.

=head1 SEE ALSO

This implementation is based upon documentation from
L<http://opensrs.com/docs/OpenSRS_APP_Dev_Guide.pdf> dated December
14, 2010.  Please read the pdf for greater detail about the protocol,
required and returned values of each function.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OpenSRS::Email_APP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OpenSRS-Email_APP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OpenSRS-Email_APP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OpenSRS-Email_APP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OpenSRS-Email_APP/>

=item * Github repository

L<https://github.com/goldie80/Net-OpenSRS-Email_APP>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to Modica Group L<http://www.modicagroup.com/> for funding
the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mark Goldfinch.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

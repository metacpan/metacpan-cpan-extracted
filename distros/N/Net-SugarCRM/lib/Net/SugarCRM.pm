package Net::SugarCRM;

use Moose;
use Log::Log4perl qw(:easy);
use LWP::UserAgent;
use DateTime;
use Time::HiRes;
use JSON;
use Data::Dumper;
use Readonly;
use Try::Tiny;
use HTTP::Request::Common;
use DBI;
use Carp qw(croak);
use Data::Dumper;
use Net::SugarCRM::Entry;
use Tie::IxHash;

BEGIN {
    if(!(Log::Log4perl->initialized())) {
      Log::Log4perl->easy_init($ERROR);
    }
}

Readonly our $LEADS => 'Leads';
Readonly our $NOTES => 'Notes';
Readonly our $ACCOUNTS => 'Accounts';
Readonly our $CONTACTS => 'Contacts';
Readonly our $OPPORTUNITIES => 'Opportunities';
Readonly our $CAMPAIGNS => 'Campaigns';
Readonly our $PROSPECTLISTS => 'ProspectLists';
Readonly our $EMAILMARKETINGS => 'EmailMarketing'; # email templates association
Readonly our $USERS => 'Users';
Readonly our $CURRENCIES => 'Currencies';

=head1 NAME

Net::SugarCRM - A simple module to access SugarCRM via Rest services

=head1 VERSION

Version $Revision$

=cut

our $VERSION = sprintf "3.320000", q$Revision$ =~ /(\d+)/xg;

=head1 DESCRIPTION

This is a simple module to provision entries in SugarCRM via REST methods.

This is for example to be able to provision contacts, leads, accounts via web services
and be able to integrate Sugar with other applications.

See the Sugar Developer Guide for more info:

http://developers.sugarcrm.com/docs/OS/6.2/-docs-Developer_Guides-Sugar_Developer_Guide_6.2.0-Sugar_Developer_Guide_6.2.1_ht
ml.html#9000412

Most of the attributes values that you can use, you need to get them from the description
of the mysql tables leads, accounts, contacts, ...

See also L<Net::SugarCRM::Tutorial>


=head2 Examples

    # Sometimes the encryption parameter seems necessary
    # my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> md5_hex($Test::pass));
    # or you have to encode the password as md5_hex
    # my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
    # 
    
    my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
    my $lead_entry = {
       email1 => 'batman@justiceleague.org',
       salutation => 'Mr',
       first_name => 'Bruce',
       last_name => 'Wayne',
       title => 'Detective',
       account_name => 'Justice League of America',
       department => 'Gotham city dep',
       phone_work => '+1123123123',
       website => 'http://justiceleagueofamerica.org',
   };
   my $leadid = $s->create_lead($lead_entry);
   ...
   my $account_entry = {
       email1 => 'dc@dc.neverland',
       name => 'DC Comics',
       description => 'DC Comics is special...',
       website => 'http://dccomics.neverland',
       annual_revenue => '12345',
       phone_office => '1123123124',
   };
   my $accountid = $s->create_account($account_entry);
   my $account_entries_from_mail = $s->get_accounts_from_mail('dc@dc.neverland');
   # this method croaks if you've got more the email more than once
   my $accountid = $s->get_unique_account_id_from_mail($mail);
   my $phone_office = $s->get_account_attribute($accountid, 'phone_office');
   ...
   my $mail = 'superman@justiceleague.org';
   my $contact_entry = {
       email1 => $mail,
       salutation => 'Mr',
       first_name => 'Clark',
       last_name => 'Kent123',
       title => 'SuperHero',
       department => 'Metropolis dep',
       phone_work => '+1123123124',
   };
   my $contactid = $s->create_contact($contact_entry);
   my $opportunity_entry = {
       name => 'My incredible opportunity',
       description => 'This is the former DC Comics is special...',
       amount => '12345',
       sales_stage => 'Prospecting',
       date_closed => '2011-12-31',
       account_id => $accountid,
   };
   my $opportunityid = $s->create_opportunity($opportunity_entry);
   my $query = 'opportunities.name = "My incredible opportunity"';
   my $opid2 = $s->get_unique_opportunity_id($query);
   ...
   # Now try to send a campaign email bypassing previous sent emails
   # For this you need to have access to the SugarCRM database to
   # manipulate the campaign_log
   $s->dsn('DBI:mysql:database=sugarcrm;host=localhost');
   $s->dbuser($Test::testdbuser);
   $s->dbpassword($Test::testdbpass);
   # You need to have created the campaign, target list (prospect_list), and email_marketing
   # entry and mail template
   my $attrs = {
        campaign_name => 'My Demo Campaign',
        emailmarketing_name => 'Demo users send greetings', 
        prospectlist_name => 'Demo users', 
        related_type => 'Leads',
        related_id => $leadid,
        email => 'batman@justiceleague.org',
   };



=head1 ATTRIBUTES

=cut

=head2 url

The default url to access, if not defined http://localhost/sugarcrm/service/v4/rest.php

=cut

has 'url' => ( is => 'rw', default => sub { 'http://localhost/sugarcrm/service/v4/rest.php' });

=head2 restuser

the username for login in the rest method

=cut

has 'restuser' => (is => 'rw', default => sub { '' });

=head2 restpasswd

the password for login in the rest method

Sometimes the encryption parameter seems to be necessary to use plain password (See https://rt.cpan.org/Ticket/Display.html?id=93696), or you can manually encode the password as md5_hex, that is.

 $self->restpasswd(md5_hex('mypass'))

=cut

has 'restpasswd' => (is => 'rw', default => sub { '' });

=head2 globalua

The default useragent

=cut

has 'globalua' => ( is => 'rw', builder => '_buildUa');

sub _buildUa {
    my $self = shift;
    my $globalua = LWP::UserAgent->new(
        agent => "Net-SugarCRM/$VERSION",
        keep_alive => 1,
    );
    $globalua->default_header('Accept' => 'application/json');
    return $globalua;
}

=head2 application

The application name to be used for the rest method in sugar

=cut

has 'application' => ( is => 'rw', default => sub { 'net_sugarcrm' } );

=head2 email_attr

The SugarCRM attribute name for email

=cut

has 'email_attr' => (is => 'rw', default => sub { 'email1' });

=head2 required_attr

Hash reference to the required attrs for a lead, contact, account

=cut

has 'required_attr' => 
    ( is => 'rw', default => 
      sub { 
              my $ret_val = { 
              $LEADS => ['last_name', 'email1'],
              $NOTES => ['name', 'description', 'parent_id', 'parent_type'],
              $ACCOUNTS => ['name'],
              $CONTACTS => ['last_name', 'email1'],
              $OPPORTUNITIES => ['name', 'amount', 'sales_stage', 'account_id', 'date_closed'],
          };
          return $ret_val;
      });

has '_module_id_for_mail_search' =>
    ( is => 'rw', default => 
      sub { 
          my $ret_val = {
              $LEADS => 'leads.id',
              $ACCOUNTS => 'accounts.id',
              $CONTACTS => 'contacts.id',
          };
          return $ret_val;
      });
has '_module_id_for_prospect_list' =>
    ( is => 'rw', default => 
      sub { 
          my $ret_val = {
              $LEADS => 'leads.id',
              $CONTACTS => 'contacts.id',
              $ACCOUNTS => 'accounts.id',
          };
          return $ret_val;
      });

has '_module_id_for_search' =>
    ( is => 'rw', default => 
      sub { 
          my $ret_val = {
              $LEADS => 'leads.id',
              $NOTES => 'notes.id',
              $ACCOUNTS => 'accounts.id',
              $CONTACTS => 'contacts.id',
              $OPPORTUNITIES => 'opportunities.id',
              $CAMPAIGNS => 'campaigns.id',
              $PROSPECTLISTS => 'prospect_lists.id',
              $EMAILMARKETINGS => 'email_marketing.id',
          }; 
          return $ret_val;
      });


=head2 dsn

Datasource Name: the configuration string for the database. For example:

DBI:mysql:database=qvd;host=localhost

=cut 

has 'dsn' => (is => 'rw', default => sub { 'DBI:mysql:database=theqvdsugarcrm;host=localhost' });

=head2 dbuser

the user to connect to the database

=cut
has 'dbuser' => (is => 'rw', default => sub { '' } );

=head2 dbpassword

the password of user to connect to the database

=cut
has 'dbpassword' => (is => 'rw', default => sub { '' } );

=head2 dbh

the database handler

=cut
has 'dbh' => (is => 'rw', lazy => 1, builder => '_buildDbh');

sub _buildDbh {
    my $self = shift;
    my $dbh = DBI->connect($self->dsn, $self->dbuser, $self->dbpassword, {RaiseError=>1});
    return $dbh;
}

has '_delete_sth' => (is => 'rw', lazy => 1, default => sub { my $self = shift;  return $self->dbh->prepare('DELETE FROM campaign_log WHERE id = ?'); } );

=head2 sessionid

Returns the sessionid after the login. If it is not defined, it tries to do a login.

=cut
has '_sessionid' => (is => 'rw');

sub sessionid {
    my ($self) = @_;
    $self->login
        if (!defined($self->_sessionid));
    return $self->_sessionid;
}

# Logger with a known, fixed category
has 'log' => (
    is => 'rw',
    lazy => 1,
    default => sub { Log::Log4perl->get_logger },
);

=head2 max_results

The maximum number of results a get_entry_list returns. By default it is 1000

=cut

has 'max_results' => ( is => 'rw', default => sub { 1000 } );

=head1 METHODS


=cut


# Input the method, and the rest_data
# Output response entry

sub _rest_request {
    my ($self, $method, $rest_data) = @_;

    my $res = $self->_rest_request_no_json($method, $rest_data);
    my ($response, $msg) = try {
        return(JSON->new->decode($res->content), 0);
    } catch {
        return({}, "SugarCRM internal error: ".$res->content);
    };

    if ($msg or (exists($$response{number}) && exists($$response{name}) &&
        exists($$response{description}))) {
        $msg = "Error getting id <".$res->status_line."> fetching ".Dumper($res->content)
            unless $msg;
        $self->log->logconfess($msg);
    }

    $self->log->debug("Success rest method <$method>\n");
    return $response;
}


sub _rest_request_no_json {
    my ($self, $method, $rest_data) = @_;
    my $req = POST($self->url, Accept=>'application/json', Content => [
        method          => $method,
        input_type      => 'json',
        response_type   => 'json',
        rest_data       => $rest_data
    ]);


    my $res = $self->globalua->request($req);
    if ($res->is_error) {
        $self->log->logconfess("Error <".$res->status_line."> fetching ".Dumper($res->request));
    }
    return $res;
}

=head2 Login/logout

=head3 login

login

it uses the object attributes url, restuser and restpasswd for the login.
It returns the sessionid. And it also stores the sessionid in the object.
Normally you don't need to call this method it is implicitly called

On some SugarCRM PRO it seems that it is needed to set $self->encryption('PLAIN')

The code would be something like

 my $sugar = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 $sugar->encryption('PLAIN');
 $sugar->login

On error the method croaks

=cut

sub login {
    my ($self) = @_;


    my $application = $self->application;
    my $user_auth = {
            user_name => $self->restuser,
            password => $self->restpasswd
    };
    $self->log->debug( "Received rest parameters: restuser: ". $self->restuser." ; restpasswd: ".$self->restpasswd);

    $user_auth->{encryption} = $self->encryption if ($self->encryption);

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'user_auth'} = $user_auth;
    $rest_data{'application'} = $application;

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('login', $rest_data_json);

    my $sessionid=$response->{id};
    $self->log->debug( "Successfully logged in for user ".$self->restuser."x with session id $sessionid");
    $self->_sessionid($sessionid);
    return $sessionid;
}


=head3 encryption

encryption if set it will add the "encryption" parameter to the login service
REST message.

The valid values currently are "PLAIN", although this is not enforced. 
If it is undef, the parameter is not passed in the login method.

=cut

has encryption => ( is => 'rw', default => sub { undef } );

=head3 logout

Input: session id

On error the method croaks. Normally you don't need to invoke this method it is implicitly called.

=cut

sub logout {
    my ($self) = @_;

    if (!defined($self->_sessionid)) {
        $self->log->error("logging out for user ".$self->restuser." which was not logged in, not doing anything");
        return;
    }
    my $rest_data = encode_json({
            session => $self->_sessionid,
        });
    my $res = try {
        $self->_rest_request_no_json('logout', $rest_data);
    } catch {
        $self->log->error("Error in SugarCRM: method returned invalid JSON: $rest_data. $_");
    };

    try {
	if ($res->content ne 'null') {
	    $self->log->error("Error logging out user ".$self->restuser." <".$res->status_line."> fetching ".Dumper($res->content)) ;
	} else {
	    # On DEMOLISH sometimes it does not exist
	    $self->log->debug( "Successfully logged out user ".$self->restuser." with session id ".$self->_sessionid);
	    $self->_sessionid(undef);
	}
    } catch  {
        $self->log->error("Error logging out user logout result is not defined:".Dumper($res)) ;
    };

    return;
}

=head2 Modules

=head3 get_available_modules

Input: 

 * session id

Output:

 * ref to an array of modules. On error the method croaks

=cut

sub get_available_modules {
    my ($self) = @_;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;

    my $rest_data_json = encode_json(\%rest_data);
 
    my $response = $self->_rest_request('get_available_modules', $rest_data_json);
    return $response;
}

=head3 get_module_fields

Input: 

 * Module names

Output:
 * ref to an array of modules. On error the method croaks

=cut

sub get_module_fields {
    my ($self, $module_name) = @_;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module_name;

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('get_module_fields', $rest_data_json);
    return $response;
}


=head2 Generic module methods

=head3 create_module_entry

Input: 

 * Module name: Contacts, Accounts, Notes, Leads
 * A hash reference of attributes for the entry. Valid values depend on the module name, ...

Output:

 * The created id for the module entry. On error the method croaks

=cut
sub create_module_entry {
    my ($self, $module, $attributes) = @_;

    foreach my $required_attr (@{$self->required_attr->{$module}}) {
        $self->log->logconfess("No $required_attr attribute. Not creating entry in $module for: ".Dumper($attributes))
            if (!exists($$attributes{$required_attr}) ||
                !defined($$attributes{$required_attr}) ||
                $$attributes{$required_attr} eq '');
    }

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'name_value_list'} = encode_json($attributes);
    $rest_data{'track_view'} = 'false';

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('set_entry', $rest_data_json);

    $self->log->info( "Successfully created module entry $module <".encode_json($attributes)."> entry with sessionid ".$self->sessionid."\n");
    $self->log->debug("Entry created in module $module was:".Dumper($response));
    return $response->{id};
}

=head3 get_module_entries

Returns the entries for a given module, searching for an attribute

Input:
 * query string. This must be one of the valid attributes in the module or module_cstm table, for example for Leads these would be the leads or leads_cstm table. Examples (Note email1 does not work as a valid attribute although it works for create_lead):
       "salutation = 'Mr'"
       "first_name = 'Bruce'"
       "last_name = 'Wayne'"
       "title => 'Detective'"
       "account_name = 'Justice League of America'"
       "department = 'Gotham city dep'"
       "phone_work = '+1123123123'"
       "website = 'http://justiceleagueofamerica.org'"

Output:

 * A reference to a an array of module entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entries_from_mail = $s->get_module_entries('Leads', 'website = "http://justiceleagueofamerica.org"');
 for my $l (@$lead_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_module_entries {
    my ($self, $module, $query) = @_;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'query'} = $query;
    $rest_data{'order_by'} = "";
    $rest_data{'offset'} = "";
    $rest_data{'select_fields'} = "";
    $rest_data{'link_name_to_fields_array'} = "";
    $rest_data{'max_results'} = $self->max_results;

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('get_entry_list', $rest_data_json);

    $self->log->debug("Module entry for module $module with query <$query> found was:".Dumper($response));
    if ($response->{total_count} == 0) {
        $self->log->debug( "No entries found for module $module and query $query and sessionid ".$self->sessionid."\n");
        return [];
    }
    $self->log->trace( "Successfully found entry for module $module for query $query and sessionid ".$self->sessionid."\n");

    return [map { Net::SugarCRM::Entry->new($_) } @{$response->{entry_list}}];
}

=head3 get_module_ids

Returns an array of module ids, searching for query see L<get_module_entries> for more info.

Input:
 * query
 * module

Output:

 * A reference to an array of module ids, and confess on error 

=cut

sub get_module_ids {
    my ($self, $module, $query) = @_;
    my $entries = $self->get_module_entries($module, $query);
    my @entriesids = map { $_->{id} } @$entries;
    return \@entriesids;
}

=head3 get_unique_module_id

Returns the module id, searching for query $query
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
module entry for the given query

Input:
 * query (see L<get_module_entries> for more info)

Output:

 * entry id found, 0 if none is found, and confess on error or if more than
   one leadid is found.
 

=cut

sub get_unique_module_id {
    my ($self, $module, $query) = @_;
    my $entries = $self->get_module_ids($module, $query);
    return () if ($#$entries == -1);
    $self->log->logconfess("More than one module entry is found for module $module searching for query $query")
        if ($#$entries > 0);
    return $entries->[0];
}


=head3 get_module_entry

Returns the module entry, given a module name and a module id

Input:
 * module name
 * id

Output:

 * A module entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_module_entry {
    my ($self, $module, $id) = @_;
    if (!exists($self->_module_id_for_search->{$module})) {
        $self->log->logconfess("The module $module cannot be used to search by ID");
    }
    $self->log->logconfess("ID is required") unless defined $id;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'query'} = $self->_module_id_for_search->{$module} . ' = "' . $id . '"'; 

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('get_entry_list', $rest_data_json);

    $self->log->debug("Module entry for module $module and id $id found was:".Dumper($response));
    if ($response->{total_count} == 0) {
        $self->log->debug( "No entries found found for id $id in module $module and sessionid ".$self->sessionid."\n");
        return ();
    }
    $self->log->trace("Successfully found entry with for id $id in module $module and sessionid ".$self->sessionid."\n");

    return Net::SugarCRM::Entry->new($response->{entry_list}->[0]);
}

=head3 get_module_attribute

Returns the value of the attribute for a given module and module id,
If the attribute or module id is not found undef is returned.
On error the method confess

Input:
 * module name
 * module id
 * attribute name

Output:

 * attribute value or undef (if the leadid is not found, the attribute does not exists)
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         print $s->get_module_attribute('Leads', $lead_entry, 'last_name');
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_module_attribute {
    my ($self, $module, $id, $attribute) = @_;
    my $entry = $self->get_module_entry($module, $id);
    if (defined $entry && exists($entry->{name_value_list}{$attribute})) {
        return $entry->{name_value_list}{$attribute}{value};
    }
    return ();
}

=head3 get_module_entries_from_mail

Returns the module ids, searching for mail

Input:
 * module name
 * email address

Output:

 * A reference to a an array of module entries,
   [] if none found, and 
   confess on error, or the module does not searching by mail address

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entries_from_mail = $s->get_module_entries_from_mail('Leads', 'batman@justiceleague.org');
 for my $l (@$lead_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_module_entries_from_mail {
    my ($self, $module, $mail) = @_;
    my $umail = uc $mail;
    if (!exists($self->_module_id_for_mail_search->{$module})) {
        $self->log->logconfess("The module $module cannot be used to search by mail address");
    }
    my $query = $self->_module_id_for_mail_search->{$module}.' in ( SELECT eabr.bean_id FROM email_addr_bean_rel eabr JOIN email_addresses ea ON (ea.id = eabr.email_address_id) WHERE eabr.deleted=0 AND ea.email_address_caps = "'.$umail.'")';
    return $self->get_module_entries($module, $query);
}

=head3 get_module_ids_from_mail

Returns an array of module id, searching for mail

Input:
 * email address

Output:

 * A reference to an array of module id, and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entries_from_mail = $s->get_module_ids_from_mail('Leads', 'batman@justiceleague.org');
 for my $l (@$lead_entries_from_mail) {
    print Dumper($l);
 }
 

=cut

sub get_module_ids_from_mail {
    my ($self, $module, $mail) = @_;
    my $entries = $self->get_module_entries_from_mail($module, $mail);
    my @entriesids = map { $_->{id} } @$entries;
    return \@entriesids;
}

=head3 get_unique_module_id_from_mail

Returns the module id, searching for mail
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
module entry with the same email address

Input:
 * email address

Output:

 * module id found, 0 if none is found, and confess on error or if more than
   one leadid is found.
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_module_id_from_mail('Leads', 'batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         print "$lead_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_unique_module_id_from_mail {
    my ($self, $module, $mail) = @_;
    my $entries = $self->get_module_ids_from_mail($module, $mail);
    return ()
        if ($#$entries == -1);
    $self->log->logconfess("More than one module entry is found searching for mail $mail and module $module")
        if ($#$entries > 0);
    return $entries->[0];
}

=head3 delete_module_entry_by_id

Deletes the module entry indicated by id

Input:
 * module name
 * entry id

Output:

 * 1 if the module id was modified, 0 if the id was not found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         $s->delete_module_entry_by_id('Leads', $lead_entry);
         print "$lead_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub delete_module_entry_by_id {
    my ($self, $module, $id) = @_;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'name_value_list'} = '{ "id" : "' . $id . '", "deleted" : "1" }';
    $rest_data{'track_view'} = 'false';

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('set_entry', $rest_data_json);

    $self->log->debug("Module entry in module $module deleted was:".Dumper($response));
    if ($response->{id} ne $id) {
        $self->log->info( "No entries updated found for module id $id module $module and sessionid ".$self->sessionid."\n");
        return ();
    }
    $self->log->info( "Successfully deleted entry in module $module and id $id and sessionid ".$self->sessionid."\n");

    return 1;
    
}

=head3 get_module_link_ids

Returns related ids for a given module, searching for an id

Input:

 * module name
 * link_field_name
 * module id
 * query (which might be empty)
 * related_fields (which might be empty and if not it should be a reference to an array of fields). By default this is ["id"]

Output:

 * A reference to an array of related ids

Example: Get all the opportunity ids of account id $accountid

my $ids = $s->get_module_link_ids("Accounts", "opportunities", $accountid);
print Dumper($ids);


=cut

sub get_module_link_ids {
    my ($self, $module, $link, $id, $query, $relatedfields) = @_;
    
    $query = '' if (!$query);
    $relatedfields = [ 'id' ] if (ref $relatedfields ne 'ARRAY');
    my $relatedfieldsjson;
    {
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Useqq = 1;
	local $Data::Dumper::Terse = 1;
	$relatedfieldsjson = Dumper($relatedfields);
    }

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'module_id'} = $id;
    $rest_data{'link_field_name'} = $link;
    $rest_data{'related_module_query'} = $query;
    $rest_data{'related_fields'} = $relatedfieldsjson;

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('get_relationships', $rest_data_json);

    $self->log->debug("Module entry for module $module with id <$id> found was:".Dumper($response));

    my @entriesids = map { $_->{id} } @{$response->{entry_list}};
    return \@entriesids;
}

=head3 update_module_entry

Updates the module entry attributes

Input:
 * module name
 * module id
 * A hash reference of attribute pairs. Example { website => 'http://newsite.org'}

Output:

 * 1 if the id was modified, 0 if the id was not found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         $s->update_module_entry('Leads', $lead_entry, { website => 'http://newsite.org' });
         print "$lead_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub update_module_entry {
    my ($self, $module, $id, $attributes) = @_;
    $$attributes{id} = $id;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'name_value_list'} = encode_json($attributes);

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('set_entry', $rest_data_json);

    $self->log->debug("Module entry updated for module $module was:".Dumper($response));
    if ($response->{id} ne $id) {
        $self->log->info( "No entries updated found for in module $module and id $id and sessionid ".$self->sessionid."\n");
        return ();
    }
    $self->log->info( "Successfully updated entry in module $module with id $id and sessionid ".$self->sessionid.". Attributes: ".join(",", (%$attributes))."\n");

    return 1;
    
}

=head2 Lead

Leads methods

=head3 create_lead

Input: 

 * A hash reference of attributes for the Lead. Valid values are first_name, last_name, email1, account_name, title, department, phone_work, website, ...

Output:

 * The created id for the lead

On error the method confess

Example:

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entry = {
       email1 => 'batman@justiceleague.org',
       salutation => 'Mr',
       first_name => 'Bruce',
       last_name => 'Wayne',
       title => 'Detective',
       account_name => 'Justice League of America',
       department => 'Gotham city dep',
       phone_work => '+1123123123',
       website => 'http://justiceleagueofamerica.org',
 };
 
 my $leadid = $s->create_lead($lead_entry);


=cut

sub create_lead {
    my ($self, $attributes) = @_;

    return $self->create_module_entry($LEADS, $attributes);
}




=head3 get_leads

Returns the lead entry, searching for an attribute

Input:
 * query string. This must be one of the valid attributes in the leads or leads_cstm table. Examples (Note email1 does not work as a valid attribute although it works for create_lead):
       "salutation = 'Mr'"
       "first_name = 'Bruce'"
       "last_name = 'Wayne'"
       "title => 'Detective'"
       "account_name = 'Justice League of America'"
       "department = 'Gotham city dep'"
       "phone_work = '+1123123123'"
       "website = 'http://justiceleagueofamerica.org'"

Output:

 * A reference to a an array of lead entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entries_from_mail = $s->get_leads('website = "http://justiceleagueofamerica.org"');
 for my $l (@$lead_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_leads {
    my ($self, $query) = @_;
    return $self->get_module_entries($LEADS, $query);
}


=head3 get_lead_ids

Returns an array of lead id, searching for query see L<get_leads> for more info.

Input:
 * query

Output:

 * A reference to an array of lead id, and confess on error 

=cut

sub get_lead_ids {
    my ($self, $query) = @_;
    return $self->get_module_ids($LEADS, $query);
}

=head3 get_unique_lead_id

Returns the lead id, searching for query $query
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
lead with the same email address

Input:
 * query (see L<get_leads> for more info)

Output:

 * leadid found, 0 if none is found, and confess on error or if more than
   one leadid is found.
 

=cut

sub get_unique_lead_id {
    my ($self, $query) = @_;
    return $self->get_unique_module_id($LEADS, $query);
}

=head3 get_lead

Returns the lead entry, given an leadid

Input:
 * leadid

Output:

 * A lead entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_lead {
    my ($self, $leadid) = @_;
    return $self->get_module_entry($LEADS, $leadid);
}


=head3 get_lead_attribute

Returns the value of the attribute for a given lead id,
If the attribute or lead id is not found undef is returned.

Input:
 * leadid
 * attribute name

Output:

 * attribute value or undef (if the leadid is not found, the attribute does not exists)
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         print $s->get_lead_attribute($lead_entry, 'last_name');
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_lead_attribute {
    my ($self, $leadid, $attribute) = @_;
    return $self->get_module_attribute($LEADS, $leadid, $attribute);
}

=head3 get_leads_from_mail

Returns the lead id, searching for mail

Input:
 * email address

Output:

 * A reference to a an array of lead entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entries_from_mail = $s->get_leads_from_mail('batman@justiceleague.org');
 for my $l (@$lead_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_leads_from_mail {
    my ($self, $mail) = @_;

    return $self->get_module_entries_from_mail($LEADS, $mail);
#    my $umail = uc $mail;
#    my $query = 'leads.id in ( SELECT eabr.bean_id FROM email_addr_bean_rel eabr JOIN email_addresses ea ON (ea.id = eabr.email_address_id) WHERE eabr.deleted=0 AND ea.email_address_caps = "'.$umail.'")';
#    return $self->get_leads($query);
}

=head3 get_lead_ids_from_mail

Returns an array of lead id, searching for mail

Input:
 * email address

Output:

 * A reference to an array of lead id, and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $lead_entries_from_mail = $s->get_lead_ids_from_mail('batman@justiceleague.org');
 for my $l (@$lead_entries_from_mail) {
    print Dumper($l);
 }
 

=cut

sub get_lead_ids_from_mail {
    my ($self, $mail) = @_;
    my $entries = $self->get_leads_from_mail($mail);
    my @entriesids = map { $_->{id} } @$entries;
    return \@entriesids;
}

=head3 get_unique_lead_id_from_mail

Returns the lead id, searching for mail
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
lead with the same email address

Input:
 * email address

Output:

 * leadid found, undef if none is found, and confess on error or if more than
   one leadid is found.
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         print "$lead_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_unique_lead_id_from_mail {
    my ($self, $mail) = @_;
    return $self->get_unique_module_id_from_mail($LEADS, $mail);
}

=head3 delete_lead_by_id

Deletes the leadid indicated by $id

Input:
 * leadid

Output:

 * 1 if the leadid was modified, 0 if no leadid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         $s->delete_lead_by_id($lead_entry);
         print "$lead_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub delete_lead_by_id {
    my ($self, $leadid) = @_;
    return $self->delete_module_entry_by_id($LEADS, $leadid);
}

=head3 update_lead

Updates the lead attributes

Input:
 * leadid
 * A hash reference of attribute pairs. Example { website => 'http://newsite.org'}

Output:

 * 1 if the leadid was modified, 0 if no leadid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $lead_entry = $s->get_unique_lead_id_from_mail('batman@justiceleague.org');
      if (!defined($lead_entry)) {
         print "Not found\n";
      } else {
         $s->update_lead($lead_entry, { website => 'http://newsite.org' });
         print "$lead_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub update_lead {
    my ($self, $leadid, $attributes) = @_;
    return $self->update_module_entry($LEADS, $leadid, $attributes);
}


=head2 Contacts

Contacts methods

=head3 create_contact

Input: 

 * A hash reference of attributes for the Contact. Valid values are first_name, last_name, email1, ...

To reference it to an account include the attribute "account_id" pointing it to an account.

Output:

 * The created id for the contact

On error the method confess

=cut

sub create_contact {
    my ($self, $attributes) = @_;
    return $self->create_module_entry($CONTACTS, $attributes);
}

=head3 get_contacts

Returns the contact entry, searching for an attribute

Input:
 * query string. This must be one of the valid attributes in the contacts or contacts_cstm table. Examples (Note email1 does not work as a valid attribute although it works for create_contact):
       "salutation = 'Mr'"
       "first_name = 'Bruce'"
       "last_name = 'Wayne'"
       "title => 'Detective'"
       "account_name = 'Justice League of America'"
       "department = 'Gotham city dep'"
       "phone_work = '+1123123123'"
       "website = 'http://justiceleagueofamerica.org'"

Output:

 * A reference to a an array of contact entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $contact_entries_from_mail = $s->get_contacts('website = "http://justiceleagueofamerica.org"');
 for my $l (@$contact_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_contacts {
    my ($self, $query) = @_;
    return $self->get_module_entries($CONTACTS, $query);
}


=head3 get_contact_ids

Returns an array of contact id, searching for query see L<get_contacts> for more info.

Input:
 * query

Output:

 * A reference to an array of contact id, and confess on error 

=cut

sub get_contact_ids {
    my ($self, $query) = @_;
    return $self->get_module_ids($CONTACTS, $query);
}

=head3 get_unique_contact_id

Returns the contact id, searching for query $query
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
contact with the same email address

Input:
 * query (see L<get_contacts> for more info)

Output:

 * contactid found, 0 if none is found, and confess on error or if more than
   one contactid is found.
 

=cut

sub get_unique_contact_id {
    my ($self, $query) = @_;
    return $self->get_unique_module_id($CONTACTS, $query);
}

=head3 get_contact

Returns the contact entry, given an contactid

Input:
 * contactid

Output:

 * A contact entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_contact {
    my ($self, $contactid) = @_;
    return $self->get_module_entry($CONTACTS, $contactid);
}


=head3 get_contact_attribute

Returns the value of the attribute for a given contact id,
If the attribute or contact id is not found undef is returned.

Input:
 * contactid
 * attribute name

Output:

 * attribute value or undef (if the contactid is not found, the attribute does not exists)
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $contact_entry = $s->get_unique_contact_id_from_mail('batman@justiceleague.org');
      if (!defined($contact_entry)) {
         print "Not found\n";
      } else {
         print $s->get_contact_attribute($contact_entry, 'last_name');
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_contact_attribute {
    my ($self, $contactid, $attribute) = @_;
    return $self->get_module_attribute($CONTACTS, $contactid, $attribute);
}

=head3 get_contacts_from_mail

Returns the contact id, searching for mail

Input:
 * email address

Output:

 * A reference to a an array of contact entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $contact_entries_from_mail = $s->get_contacts_from_mail('batman@justiceleague.org');
 for my $l (@$contact_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_contacts_from_mail {
    my ($self, $mail) = @_;

    return $self->get_module_entries_from_mail($CONTACTS, $mail);
#    my $umail = uc $mail;
#    my $query = 'contacts.id in ( SELECT eabr.bean_id FROM email_addr_bean_rel eabr JOIN email_addresses ea ON (ea.id = eabr.email_address_id) WHERE eabr.deleted=0 AND ea.email_address_caps = "'.$umail.'")';
#    return $self->get_contacts($query);
}

=head3 get_contact_ids_from_mail

Returns an array of contact id, searching for mail

Input:
 * email address

Output:

 * A reference to an array of contact id, and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $contact_entries_from_mail = $s->get_contact_ids_from_mail('batman@justiceleague.org');
 for my $l (@$contact_entries_from_mail) {
    print Dumper($l);
 }
 

=cut

sub get_contact_ids_from_mail {
    my ($self, $mail) = @_;
    my $entries = $self->get_contacts_from_mail($mail);
    my @entriesids = map { $_->{id} } @$entries;
    return \@entriesids;
}

=head3 get_unique_contact_id_from_mail

Returns the contact id, searching for mail
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
contact with the same email address

Input:
 * email address

Output:

 * contactid found, 0 if none is found, and confess on error or if more than
   one contactid is found.
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $contact_entry = $s->get_unique_contact_id_from_mail('batman@justiceleague.org');
      if (!defined($contact_entry)) {
         print "Not found\n";
      } else {
         print "$contact_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_unique_contact_id_from_mail {
    my ($self, $mail) = @_;
    return $self->get_unique_module_id_from_mail($CONTACTS, $mail);
}

=head3 get_contact_account_ids

Find all accounts associated with the specified contact

Input:

  * contactid

Output:

  * A reference to an array of account ids

=cut

sub get_contact_account_ids {
    my ($self, $id) = @_;
    return $self->get_module_link_ids($CONTACTS, 'accounts', $id);
}


=head3 delete_contact_by_id

Deletes the contactid indicated by $id

Input:
 * contactid

Output:

 * 1 if the contactid was modified, 0 if no contactid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $contact_entry = $s->get_unique_contact_id_from_mail('batman@justiceleague.org');
      if (!defined($contact_entry)) {
         print "Not found\n";
      } else {
         $s->delete_contact_by_id($contact_entry);
         print "$contact_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub delete_contact_by_id {
    my ($self, $contactid) = @_;
    return $self->delete_module_entry_by_id($CONTACTS, $contactid);
}

=head3 update_contact

Updates the contact attributes

Input:
 * contactid
 * A hash reference of attribute pairs. Example { website => 'http://newsite.org'}

Output:

 * 1 if the contactid was modified, 0 if no contactid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $contact_entry = $s->get_unique_contact_id_from_mail('batman@justiceleague.org');
      if (!defined($contact_entry)) {
         print "Not found\n";
      } else {
         $s->update_contact($contact_entry, { website => 'http://newsite.org' });
         print "$contact_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub update_contact {
    my ($self, $contactid, $attributes) = @_;
    return $self->update_module_entry($CONTACTS, $contactid, $attributes);
}


=head2 Accounts

Accounts methods

=head3 create_account

Input: 

 * A hash reference of attributes for the Account. Valid values are first_name, last_name, email1, ...

To reference it to an account include the attribute "account_id" pointing it to an account.

Output:

 * The created id for the account

On error the method confess

=cut

sub create_account {
    my ($self, $attributes) = @_;
    return $self->create_module_entry($ACCOUNTS, $attributes);
}

=head3 get_accounts

Returns the account entry, searching for an attribute

Input:
 * query string. This must be one of the valid attributes in the accounts or accounts_cstm table. Examples (Note email1 does not work as a valid attribute although it works for create_account):
       "salutation = 'Mr'"
       "first_name = 'Bruce'"
       "last_name = 'Wayne'"
       "title => 'Detective'"
       "account_name = 'Justice League of America'"
       "department = 'Gotham city dep'"
       "phone_work = '+1123123123'"
       "website = 'http://justiceleagueofamerica.org'"

Output:

 * A reference to a an array of account entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $account_entries_from_mail = $s->get_accounts('website = "http://justiceleagueofamerica.org"');
 for my $l (@$account_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_accounts {
    my ($self, $query) = @_;
    return $self->get_module_entries($ACCOUNTS, $query);
}


=head3 get_account_ids

Returns an array of account id, searching for query see L<get_accounts> for more info.

Input:
 * query

Output:

 * A reference to an array of account id, and confess on error 

=cut

sub get_account_ids {
    my ($self, $query) = @_;
    return $self->get_module_ids($ACCOUNTS, $query);
}

=head3 get_unique_account_id

Returns the account id, searching for query $query
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
account with the same email address

Input:
 * query (see L<get_accounts> for more info)

Output:

 * accountid found, 0 if none is found, and confess on error or if more than
   one accountid is found.
 

=cut

sub get_unique_account_id {
    my ($self, $query) = @_;
    return $self->get_unique_module_id($ACCOUNTS, $query);
}

=head3 get_account

Returns the account entry, given an accountid

Input:
 * accountid

Output:

 * A account entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_account {
    my ($self, $accountid) = @_;
    return $self->get_module_entry($ACCOUNTS, $accountid);
}


=head3 get_account_attribute

Returns the value of the attribute for a given account id,
If the attribute or account id is not found undef is returned.

Input:
 * accountid
 * attribute name

Output:

 * attribute value or undef (if the accountid is not found, the attribute does not exists)
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $account_entry = $s->get_unique_account_id_from_mail('batman@justiceleague.org');
      if (!defined($account_entry)) {
         print "Not found\n";
      } else {
         print $s->get_account_attribute($account_entry, 'last_name');
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_account_attribute {
    my ($self, $accountid, $attribute) = @_;
    return $self->get_module_attribute($ACCOUNTS, $accountid, $attribute);
}

=head3 get_accounts_from_mail

Returns the account id, searching for mail

Input:
 * email address

Output:

 * A reference to a an array of account entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $account_entries_from_mail = $s->get_accounts_from_mail('batman@justiceleague.org');
 for my $l (@$account_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_accounts_from_mail {
    my ($self, $mail) = @_;

    return $self->get_module_entries_from_mail($ACCOUNTS, $mail);
#    my $umail = uc $mail;
#    my $query = 'accounts.id in ( SELECT eabr.bean_id FROM email_addr_bean_rel eabr JOIN email_addresses ea ON (ea.id = eabr.email_address_id) WHERE eabr.deleted=0 AND ea.email_address_caps = "'.$umail.'")';
#    return $self->get_accounts($query);
}

=head3 get_account_ids_from_mail

Returns an array of account id, searching for mail

Input:
 * email address

Output:

 * A reference to an array of account id, and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $account_entries_from_mail = $s->get_account_ids_from_mail('batman@justiceleague.org');
 for my $l (@$account_entries_from_mail) {
    print Dumper($l);
 }
 

=cut

sub get_account_ids_from_mail {
    my ($self, $mail) = @_;
    my $entries = $self->get_accounts_from_mail($mail);
    my @entriesids = map { $_->{id} } @$entries;
    return \@entriesids;
}

=head3 get_unique_account_id_from_mail

Returns the account id, searching for mail
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
account with the same email address

Input:
 * email address

Output:

 * accountid found, 0 if none is found, and confess on error or if more than
   one accountid is found.
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $account_entry = $s->get_unique_account_id_from_mail('batman@justiceleague.org');
      if (!defined($account_entry)) {
         print "Not found\n";
      } else {
         print "$account_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_unique_account_id_from_mail {
    my ($self, $mail) = @_;
    return $self->get_unique_module_id_from_mail($ACCOUNTS, $mail);
}

=head3 get_account_contact_ids

Find all contacts associated with the specified account

Input:

  * accountid

Output:

  * A reference to an array of contact ids

=cut

sub get_account_contact_ids {
    my ($self, $id) = @_;
    return $self->get_module_link_ids($ACCOUNTS, 'contacts', $id);
}

=head3 delete_account_by_id

Deletes the accountid indicated by $id

Input:
 * accountid

Output:

 * 1 if the accountid was modified, 0 if no accountid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $account_entry = $s->get_unique_account_id_from_mail('batman@justiceleague.org');
      if (!defined($account_entry)) {
         print "Not found\n";
      } else {
         $s->delete_account_by_id($account_entry);
         print "$account_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub delete_account_by_id {
    my ($self, $accountid) = @_;
    return $self->delete_module_entry_by_id($ACCOUNTS, $accountid);
}

=head3 update_account

Updates the account attributes

Input:
 * accountid
 * A hash reference of attribute pairs. Example { website => 'http://newsite.org'}

Output:

 * 1 if the accountid was modified, 0 if no accountid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $account_entry = $s->get_unique_account_id_from_mail('batman@justiceleague.org');
      if (!defined($account_entry)) {
         print "Not found\n";
      } else {
         $s->update_account($account_entry, { website => 'http://newsite.org' });
         print "$account_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub update_account {
    my ($self, $accountid, $attributes) = @_;
    return $self->update_module_entry($ACCOUNTS, $accountid, $attributes);
}


=head2 Currency

Currency methods

=head3 create_currency

Input: 

 * A hash reference of attributes for the Currency. Valid values are name, symbol, iso4217, conversion_rate

Output:

 * The created id for the currency


=cut

sub create_currency {
    my ($self, $attributes) = @_;
    return $self->create_module_entry($CURRENCIES, $attributes);
}


=head3 get_currencies

Returns the currency entry, searching for an attribute

Input:
 * query string. This must be one of the valid attributes in the currencies or currencies_cstm table. 
Output:

 * A reference to a an array of currency entries,
   [] if none found, and 
   confess on error
 

=cut

sub get_currencies {
    my ($self, $query) = @_;
    return $self->get_module_entries($CURRENCIES, $query);
}


=head3 get_currency_ids

Returns an array of currency id, searching for query see L<get_currencies> for more info.

Input:
 * query

Output:

 * A reference to an array of currency id, and confess on error 

=cut

sub get_currency_ids {
    my ($self, $query) = @_;
    return $self->get_module_ids($CURRENCIES, $query);
}

=head3 get_unique_currency_id

Returns the currency id, searching for query $query
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
currency with the same email address

Input:
 * query (see L<get_currencies> for more info)

Output:

 * currencyid found, 0 if none is found, and confess on error or if more than
   one currencyid is found.
 

=cut

sub get_unique_currency_id {
    my ($self, $query) = @_;
    return $self->get_unique_module_id($CURRENCIES, $query);
}

=head3 get_currency

Returns the currency entry, given an currencyid

Input:
 * currencyid

Output:

 * A currency entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_currency {
    my ($self, $currencyid) = @_;
    return $self->get_module_entry($CURRENCIES, $currencyid);
}


=head3 get_currency_attribute

Returns the value of the attribute for a given currency id,
If the attribute or currency id is not found undef is returned.

Input:
 * currencyid
 * attribute name

Output:

 * attribute value or undef (if the currencyid is not found, the attribute does not exists)
 

=cut

sub get_currency_attribute {
    my ($self, $currencyid, $attribute) = @_;
    return $self->get_module_attribute($CURRENCIES, $currencyid, $attribute);
}

=head3 delete_currency_by_id

Deletes the currencyid indicated by $id

Input:
 * currencyid

Output:

 * 1 if the currencyid was modified, 0 if no currencyid was found and confess on error

=cut

sub delete_currency_by_id {
    my ($self, $currencyid) = @_;
    return $self->delete_module_entry_by_id($CURRENCIES, $currencyid);
}

=head3 update_currency

Updates the currency attributes

Input:
 * currencyid
 * A hash reference of attribute pairs. Example { website => 'http://newsite.org'}

Output:

 * 1 if the currencyid was modified, 0 if no currencyid was found and confess on error

=cut

sub update_currency {
    my ($self, $currencyid, $attributes) = @_;
    return $self->update_module_entry($CURRENCIES, $currencyid, $attributes);
}





=head2 Opportunity

Opportunity methods

=head3 create_opportunity

Input: 

 * A hash reference of attributes for the Opportunity. Valid values are first_name, last_name, email1, ...

To reference it to an opportunity include the attribute "opportunity_id" pointing it to an opportunity.

Output:

 * The created id for the opportunity

On error the method confess

my $opportunity_entry = {
       name => 'My incredible opportunity',
       description => 'This is the former DC Comics is special...',
       amount => '12345',
       sales_stage => 'Prospecting',
       date_closed => '2011-12-31',
       account_id => $accountid,
};
my $opportunityid2 = $s->create_opportunity($opportunity_entry);

=cut

sub create_opportunity {
    my ($self, $attributes) = @_;
    return $self->create_module_entry($OPPORTUNITIES, $attributes);
}

=head3 get_opportunities

Returns the opportunity entry, searching for an attribute

Input:
 * query string. This must be one of the valid attributes in the opportunities or opportunities_cstm table. Examples (Note email1 does not work as a valid attribute although it works for create_opportunity):
       "salutation = 'Mr'"
       "first_name = 'Bruce'"
       "last_name = 'Wayne'"
       "title => 'Detective'"
       "opportunity_name = 'Justice League of America'"
       "department = 'Gotham city dep'"
       "phone_work = '+1123123123'"
       "website = 'http://justiceleagueofamerica.org'"

Output:

 * A reference to a an array of opportunity entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $opportunity_entries_from_mail = $s->get_opportunities('website = "http://justiceleagueofamerica.org"');
 for my $l (@$opportunity_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_opportunities {
    my ($self, $query) = @_;
    return $self->get_module_entries($OPPORTUNITIES, $query);
}


=head3 get_opportunity_ids

Returns an array of opportunity id, searching for query see L<get_opportunities> for more info.

Input:
 * query

Output:

 * A reference to an array of opportunity id, and confess on error 

=cut

sub get_opportunity_ids {
    my ($self, $query) = @_;
    return $self->get_module_ids($OPPORTUNITIES, $query);
}

=head3 get_unique_opportunity_id

Returns the opportunity id, searching for query $query
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
opportunity with the same email address

Input:
 * query (see L<get_opportunities> for more info)

Output:

 * opportunityid found, 0 if none is found, and confess on error or if more than
   one opportunityid is found.
 

=cut

sub get_unique_opportunity_id {
    my ($self, $query) = @_;
    return $self->get_unique_module_id($OPPORTUNITIES, $query);
}

=head3 get_opportunity

Returns the opportunity entry, given an opportunityid

Input:
 * opportunityid

Output:

 * A opportunity entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_opportunity {
    my ($self, $opportunityid) = @_;
    return $self->get_module_entry($OPPORTUNITIES, $opportunityid);
}


=head3 get_opportunity_attribute

Returns the value of the attribute for a given opportunity id,
If the attribute or opportunity id is not found undef is returned.

Input:
 * opportunityid
 * attribute name

Output:

 * attribute value or undef (if the opportunityid is not found, the attribute does not exists)
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $opportunity_entry = $s->get_unique_opportunity_id_from_mail('batman@justiceleague.org');
      if (!defined($opportunity_entry)) {
         print "Not found\n";
      } else {
         print $s->get_opportunity_attribute($opportunity_entry, 'last_name');
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_opportunity_attribute {
    my ($self, $opportunityid, $attribute) = @_;
    return $self->get_module_attribute($OPPORTUNITIES, $opportunityid, $attribute);
}

=head3 get_opportunities_from_mail

Returns the opportunity id, searching for mail

Input:
 * email address

Output:

 * A reference to a an array of opportunity entries,
   [] if none found, and 
   confess on error
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $opportunity_entries_from_mail = $s->get_opportunities_from_mail('batman@justiceleague.org');
 for my $l (@$opportunity_entries_from_mail) {
    print Dumper($l);
 }

=cut

sub get_opportunities_from_mail {
    my ($self, $mail) = @_;

    return $self->get_module_entries_from_mail($OPPORTUNITIES, $mail);
#    my $umail = uc $mail;
#    my $query = 'opportunities.id in ( SELECT eabr.bean_id FROM email_addr_bean_rel eabr JOIN email_addresses ea ON (ea.id = eabr.email_address_id) WHERE eabr.deleted=0 AND ea.email_address_caps = "'.$umail.'")';
#    return $self->get_opportunities($query);
}

=head3 get_opportunity_ids_from_mail

Returns an array of opportunity id, searching for mail

Input:
 * email address

Output:

 * A reference to an array of opportunity id, and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 my $opportunity_entries_from_mail = $s->get_opportunity_ids_from_mail('batman@justiceleague.org');
 for my $l (@$opportunity_entries_from_mail) {
    print Dumper($l);
 }
 

=cut

sub get_opportunity_ids_from_mail {
    my ($self, $mail) = @_;
    my $entries = $self->get_opportunities_from_mail($mail);
    my @entriesids = map { $_->{id} } @$entries;
    return \@entriesids;
}

=head3 get_unique_opportunity_id_from_mail

Returns the opportunity id, searching for mail
If none is found undef is returned, and if more than one is found
an error is issued.

This method should only be used if you can garantee that you have only one
opportunity with the same email address

Input:
 * email address

Output:

 * opportunityid found, 0 if none is found, and confess on error or if more than
   one opportunityid is found.
 
 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $opportunity_entry = $s->get_unique_opportunity_id_from_mail('batman@justiceleague.org');
      if (!defined($opportunity_entry)) {
         print "Not found\n";
      } else {
         print "$opportunity_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub get_unique_opportunity_id_from_mail {
    my ($self, $mail) = @_;
    return $self->get_unique_module_id_from_mail($OPPORTUNITIES, $mail);
}

=head3 delete_opportunity_by_id

Deletes the opportunityid indicated by $id

Input:
 * opportunityid

Output:

 * 1 if the opportunityid was modified, 0 if no opportunityid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $opportunity_entry = $s->get_unique_opportunity_id_from_mail('batman@justiceleague.org');
      if (!defined($opportunity_entry)) {
         print "Not found\n";
      } else {
         $s->delete_opportunity_by_id($opportunity_entry);
         print "$opportunity_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub delete_opportunity_by_id {
    my ($self, $opportunityid) = @_;
    return $self->delete_module_entry_by_id($OPPORTUNITIES, $opportunityid);
}

=head3 update_opportunity

Updates the opportunity attributes

Input:
 * opportunityid
 * A hash reference of attribute pairs. Example { website => 'http://newsite.org'}

Output:

 * 1 if the opportunityid was modified, 0 if no opportunityid was found and confess on error

 my $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
 try {
      my $opportunity_entry = $s->get_unique_opportunity_id_from_mail('batman@justiceleague.org');
      if (!defined($opportunity_entry)) {
         print "Not found\n";
      } else {
         $s->update_opportunity($opportunity_entry, { website => 'http://newsite.org' });
         print "$opportunity_entry\n";
      }
 } catch {
    print "Error or more than one entry was found: $@";
 }

=cut

sub update_opportunity {
    my ($self, $opportunityid, $attributes) = @_;
    return $self->update_module_entry($OPPORTUNITIES, $opportunityid, $attributes);
}



=head2 Mail

mail methods

=head3 get_mail_entry

Returns the EmailAddress entry, searching for mail address

Input:
 * email address

Output:

 * the EmailAddress entry, undef if none found, and confess on error

=cut

sub get_mail_entry {
    my ($self, $mail) = @_;
    my $umail = uc $mail;

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = "EmailAddresses";
    $rest_data{'query'} = 'email_address_caps = "'.$umail.'"';

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('get_entry_list', $rest_data_json);

    $self->log->debug("Email found was:".Dumper($response));
    if ($response->{total_count} > 1) {
        $self->log->logconfess("Found more than one entry with for mail $mail and sessionid $self->sessionid:".Dumper($response));
    }
    if ($response->{total_count} == 0) {
        $self->log->debug( "No entries found found for mail $mail and sessionid ".$self->sessionid."\n");
        return;
    }
    $self->log->trace( "Successfully found entry with for mail $mail and sessionid ".$self->sessionid."\n");
    return $response->{entry_list}->[0];
}

=head3 get_mail_entry_id

Returns the emailaddress id, searching for mail
Adds the lead identified by id to the specified to the outgoing email

Input:
 * email address

Output:

 * the contact id, undef if none found, and confess on error

=cut
sub get_mail_entry_id {
    my ($self, $mail) = @_;
    my $entry = $self->get_mail_entry($mail);
    return (ref($entry) eq 'HASH') ? $entry->{id} : undef;
}

=head2 Note

Notes methods

=head3 create_note

contact_id, description, name =subject

parent_type -> Accounts, Opportunities
parent_id -> account_id or opportunity_id

=cut
sub create_note {
    my ($self, $attributes) = @_;

    return $self->create_module_entry($NOTES, $attributes);
}

=head3 get_note

Returns the note entry, given an noteid

Input:
 * noteid

Output:

 * A Note entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_note {
    my ($self, $noteid) = @_;
    return $self->get_module_entry($NOTES, $noteid);
}


=head3 get_note_attribute

Returns the value of the attribute for a given note id,
If the attribute or note id is not found undef is returned.

Input:
 * noteid
 * attribute name

Output:

 * attribute value or undef (if the noteid is not found, the attribute does not exists)
 

=cut

sub get_note_attribute {
    my ($self, $noteid, $attribute) = @_;
    return $self->get_module_attribute($NOTES, $noteid, $attribute);
}


=head3 delete_note_by_id

Deletes the note indicated by $id

Input:
 * noteid

Output:

 * 1 if the opportunityid was modified, 0 if no opportunityid was found and confess on error

=cut

sub delete_note_by_id {
    my ($self, $noteid) = @_;
    return $self->delete_module_entry_by_id($OPPORTUNITIES, $noteid);
}


=head2 Campaigns

=head3 get_campaignid_by_name

Returns a campaign id searching for the campaign name, 

Input:

 * Campaign name

Output:

 * if duplicate names exists
an error is thrown (confess), if not found undef is returned and if found the campaign id
is returned
=cut
sub get_campaignid_by_name {
    my ($self, $name) = @_;
    my $query = 'campaigns.name = "'.$name.'"';
    return $self->get_unique_module_id($CAMPAIGNS, $query);
}

=head3 get_campaign

Returns the campaign entry, given a campaign id

Input:
 * campaignid

Output:

 * A campaign entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_campaign {
    my ($self, $campaignid) = @_;
    return $self->get_module_entry($CAMPAIGNS, $campaignid);
}

=head3 get_campaign_attribute

Returns the value of the attribute for a given campaing id,
If the attribute or campaing id is not found undef is returned.

Input:
 * campaignid
 * attribute name

Output:

 * attribute value or undef (if the leadid is not found, the attribute does not exists)
 

=cut

sub get_campaign_attribute {
    my ($self, $campaignid, $attribute) = @_;
    return $self->get_module_attribute($CAMPAIGNS, $campaignid, $attribute);
}


=head2 Prospectlists

=head3 get_prospectlistid_by_name

Returns a prospectlist id searching for the prospectlist name, 

Input:

 * Prospectlist name

Output:

 * if duplicate names exists
an error is thrown (confess), if not found undef is returned and if found the prospectlist id
is returned
=cut
sub get_prospectlistid_by_name {
    my ($self, $name) = @_;
    my $query = 'prospect_lists.name = "'.$name.'"';
    return $self->get_unique_module_id($PROSPECTLISTS, $query);
}

=head3 get_prospectlist

Returns the prospectlist entry, given a prospectlist id

Input:
 * prospectlistid

Output:

 * A prospectlist entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_prospectlist {
    my ($self, $prospectlistid) = @_;
    return $self->get_module_entry($PROSPECTLISTS, $prospectlistid);
}

=head3 get_prospectlist_attribute

Returns the value of the attribute for a given campaing id,
If the attribute or campaing id is not found undef is returned.

Input:
 * prospectlistid
 * attribute name

Output:

 * attribute value or undef (if the leadid is not found, the attribute does not exists)
 

=cut

sub get_prospectlist_attribute {
    my ($self, $prospectlistid, $attribute) = @_;
    return $self->get_module_attribute($PROSPECTLISTS, $prospectlistid, $attribute);
}

=head2 EmailMarketing

=head3 get_emailmarketingid_by_name

Returns a emailmarketing id searching for the emailmarketing name, 

Input:

 * Emailmarketing name

Output:

 * if duplicate names exists
an error is thrown (confess), if not found undef is returned and if found the emailmarketing id
is returned
=cut
sub get_emailmarketingid_by_name {
    my ($self, $name) = @_;
    my $query = 'email_marketing.name = "'.$name.'"';
    return $self->get_unique_module_id($EMAILMARKETINGS, $query);
}

=head3 get_emailmarketing

Returns the emailmarketing entry, given a emailmarketing id

Input:
 * emailmarketingid

Output:

 * A emailmarketing entry,
   undef if none found, and 
   confess on error
 
=cut

sub get_emailmarketing {
    my ($self, $emailmarketingid) = @_;
    return $self->get_module_entry($EMAILMARKETINGS, $emailmarketingid);
}

=head3 get_emailmarketing_attribute

Returns the value of the attribute for a given campaing id,
If the attribute or campaing id is not found undef is returned.

Input:
 * emailmarketingid
 * attribute name

Output:

 * attribute value or undef (if the leadid is not found, the attribute does not exists)
 

=cut

sub get_emailmarketing_attribute {
    my ($self, $emailmarketingid, $attribute) = @_;
    return $self->get_module_attribute($EMAILMARKETINGS, $emailmarketingid, $attribute);
}

=head2 Prospect Lists

=head3 add_module_id_to_prospect_list

Adds the lead identified by id to the specified target list

Input:
 * Module (currently only Contacts and Leads are supported)
 * Lead id or contact id
 * Target list id

Output:

 * Returns 1 on success and undef if the entry was not created
   confess on error
 

=cut

sub add_module_id_to_prospect_list {
    my ($self, $module, $id, $prospect_list) = @_;
    $self->log->logconfess("Module $module cannot be added to a target list")
        if (!exists($self->_module_id_for_prospect_list->{$module}));

    if (!defined($self->get_module_entry($module, $id))) {
        $self->log->logconfess("Not found module $module and id $id. Check that the id is valid");
    }
    if (!defined($self->get_module_entry($PROSPECTLISTS, $prospect_list))) {
        $self->log->logconfess("Not found module $module and id $id. Check that the id is valid");
    }

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'module_id'} = $id;
    $rest_data{'link_field_name'} = "prospect_lists";
    $rest_data{'related_ids'} = $prospect_list;

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('set_relationship', $rest_data_json);

    $self->log->info( "Successfully created link from module \"$module\" and "
        ."id \"$id\" to target list \"$prospect_list\" entry with sessionid "
        ."\"".$self->sessionid."\"");
    $self->log->debug("Module id $id in module $module linked was:".Dumper($response));
    return ($response->{created} == 1) ? 1 : undef;

}

=head3 delete_module_id_from_prospect_list

Gets the leads and contacts ids from the specified target list

Input:
 * Target list id

Output:

 * A reference to a hash with the entries ,confess on error
 

=cut

sub delete_module_id_from_prospect_list {
    my ($self, $module, $id, $prospect_list) = @_;
    $self->log->logconfess("Module $module cannot be added to a target list")
        if (!exists($self->_module_id_for_prospect_list->{$module}));

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = $module;
    $rest_data{'module_id'} = $id;
    $rest_data{'link_field_name'} = "prospect_lists";
    $rest_data{'related_ids'} = $prospect_list;
    # Need to set both deleted and delete, if not it doesn't work in 6.2.1 at least...
    $rest_data{'deleted'} = "1";
    $rest_data{'delete'} = "1";

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('set_relationship', $rest_data_json);

    $self->log->info( "Successfully deleted link from module $module and $id to target list  <".$prospect_list.."> entry with sessionid ".$self->sessionid."\n");
    $self->log->debug("Module id $id in module $module linked was:".Dumper($response));
    return ($response->{deleted} == 1) ? 1 : undef;

}


=head3 add_lead_id_to_prospect_list

Adds the lead identified by id to the specified target list

Input:
 * Lead id
 * Target list id

Output:

 * 1 if the lead was added undef if not
   confess on error
 

=cut

sub add_lead_id_to_prospect_list {
    my ($self, $id, $prospect_list) = @_;
    return $self->add_module_id_to_prospect_list($LEADS, $id, $prospect_list);
}

=head3 add_contact_id_to_prospect_list

Adds the contact identified by id to the specified target list

Input:
 * Contact id
 * Target list id

Output:

 * 1 if the lead was added undef if not
   confess on error
 

=cut

sub add_contact_id_to_prospect_list {
    my ($self, $id, $prospect_list) = @_;
    return $self->add_module_id_to_prospect_list($CONTACTS, $id, $prospect_list);
}

=head3 delete_lead_id_from_prospect_list

Note: This method does not seem to work

Deletes the lead identified by id from the specified target list

Input:
 * Lead id
 * Target list id

Output:

 * 1 if the lead was added undef if not
   confess on error
 

=cut

sub delete_lead_id_from_prospect_list {
    my ($self, $id, $prospect_list) = @_;
    return $self->delete_module_id_from_prospect_list($LEADS, $id, $prospect_list);
}

=head3 delete_contact_id_from_prospect_list

Note: This method does not seem to work

Deletes the contact identified by id from the specified target list

Input:
 * Contact id
 * Target list id

Output:

 * 1 if the lead was added undef if not
   confess on error
 

=cut

sub delete_contact_id_from_prospect_list {
    my ($self, $id, $prospect_list) = @_;
    return $self->delete_module_id_from_prospect_list($CONTACTS, $id, $prospect_list);
}


=head2 Campaign emails

These methods are to send emails out.

=head3 send_prospectlist_marketing_email_force

Note: Be careful you might resend emails that were already sent, this function overrides that.

This method gets as input:
 * Hash array:
   * campaign_name:  campaign name,
   * emailmarketing_name: marketing name (this is the name of the name that holds the email template)
   * prospectlist_name: Prospect list, where the contact or lead is going to be added
   * related_name: Can be one of two values Leads or Contacts
   * related_id: The leadid or contactid
   * email: The email of the contact

Output:

 * undef if the email was not put in the outbound queue, confess in case of error.

this method is a facility method to add contact to a prospect_list, delete all the relevant entries in the campaign log, and put the email in the outbound queue (emailman)
  
=cut

# Verifies params and returns mail
sub _send_prospectlist_marketing_email_force_verify_params {
    my ($self, $attrs) = @_;
    $self->log->logconfess("campaign_name not specified:".Dumper($attrs))
        if (!defined($$attrs{campaign_name}));
    $self->log->logconfess("emailmarketing_name not specified:".Dumper($attrs))
        if (!defined($$attrs{emailmarketing_name}));
    $self->log->logconfess("prospectlist_name not specified:".Dumper($attrs))
        if (!defined($$attrs{prospectlist_name}));
    $self->log->logconfess("related_type not specified:".Dumper($attrs))
        if (!defined($$attrs{related_type}));
    $self->log->logconfess("email not specified:".Dumper($attrs))
        if (!defined($$attrs{email}));
    $self->log->logconfess("related_type is not $CONTACTS, $LEADS, or $ACCOUNTS:".Dumper($attrs))
        if ($$attrs{related_type} ne $CONTACTS && $$attrs{related_type} ne $LEADS &&
	    $$attrs{related_type} ne $ACCOUNTS);
    $self->log->logconfess("related_id not specified:".Dumper($attrs))
        if (!defined($$attrs{related_id}));
    # Just verify that the related_id and related_type exists
    my $mail = $self->get_module_attribute($$attrs{related_type}, $$attrs{related_id}, 'email1');
    $self->log->logconfess("No email1 attribute for module and id ".$$attrs{related_type}." ".$$attrs{related_id}."")
        if (!$mail);
    # TODO verify $mail = $$attrs{email}
    return $mail;
}

sub send_prospectlist_marketing_email_force {
    my ($self, $attrs) = @_;

    # Verify parameters
    my $mail = $self->_send_prospectlist_marketing_email_force_verify_params($attrs);

    # Get parameters
    my $campaignid = $self->get_campaignid_by_name($$attrs{campaign_name})
        or $self->log->logcroak("Campaign \"$$attrs{campaign_name}\" not found");
    my $marketingid = $self->get_emailmarketingid_by_name($$attrs{emailmarketing_name})
        or $self->log->logcroak("Email marketing \"$$attrs{emailmarketing_name}\" not found");
    my $prospectlistid = $self->get_prospectlistid_by_name($$attrs{prospectlist_name})
        or $self->log->logcroak("Prospect list \"$$attrs{prospectlist_name}\" not found");
    my $userid = $self->get_unique_module_id($USERS, 'users.sugar_login = "'.$self->restuser.'"');
    # Delete existing emails sent either leads or contacts which have the
    # email address
    my $existing_leadid = $self->get_unique_lead_id_from_mail($mail);
    if (!$existing_leadid) {
        $self->log->debug("Previous email for leadid not found, forcing leadid to a non existen value -1 to allow searching also for non existent lead and existent email");
        $existing_leadid = '-1';
    }
    my $attrs_campaign_leads = {
        campaign_id => $campaignid,
        target_id => $existing_leadid,
        target_type => $LEADS,
        list_id => $prospectlistid,
        marketing_id => $marketingid,
        email => $mail,
    };
    $self->log->debug("Getting campaignlog id with params".Dumper($attrs_campaign_leads));
    my $ids = $self->get_ids_from_campaignlog($attrs_campaign_leads);
    $self->delete_ids_from_campaignlog($ids);

    my $existing_contactid = $self->get_unique_contact_id_from_mail($mail);
    if (!$existing_contactid) {
        $self->log->debug("Previous email for contactid not found, forcing contactid to a non existen value -1 to allow searching also for non existent contact and existent email");
        $existing_contactid = '-1';
    }
    my $attrs_campaign_contacts = {
        campaign_id => $campaignid,
        target_id => $existing_contactid,
        target_type => $CONTACTS,
        list_id => $prospectlistid,
        marketing_id => $marketingid,
        email => $mail,
    };
    $self->log->debug("Getting campaignlog id with params".Dumper($attrs_campaign_contacts));
    $ids = $self->get_ids_from_campaignlog($attrs_campaign_contacts);
    $self->delete_ids_from_campaignlog($ids);

    # Add the contact or lead to a distribution list
    $self->add_module_id_to_prospect_list($$attrs{related_type}, $$attrs{related_id}, $prospectlistid);
    $self->log->debug("Adding to list $prospectlistid module and id ".$$attrs{related_type}." ".$$attrs{related_id});

    # queue the mail outgoing
    my $emailman_attrs = {
        campaign_id => $campaignid,
        marketing_id => $marketingid,
        list_id => $prospectlistid,
        related_id => $$attrs{related_id},
        related_type => $$attrs{related_type},
        user_id => $userid,
        modified_user_id => $userid,
    };
    $self->add_to_emailman($emailman_attrs);

    return 1;
}

=head3 add_to_emailman

Adds the module entry identified by some attributes to the specified to the outgoing email.

This method puts in the outbound queue the mail specified by marketing_id, related_id and list_id (to resend a previous sent email you need to specifically delete the entries in the campaign log, see L<delete_ids_from_campaignlog>


Input:
 * A hash with the following elements at least
   * campaign_id e6c3a792-9d03-c063-3601-4e2ad8991061
   * marketing_id e6c3a792-9d03-c063-3601-4e2ad8991061
   * list_id 55308e7d-1d97-9a8f-dc30-4e2ad69623af
   * related_id, new id created,
   * related_type, Leads or Contacts

Output:

 * the hash created,confess on error
 
Side effect the way we generate the ids, there should be at least a millisecond between
each insert...

    my $emailman_attrs = {
        campaign_id => $campaignid,
        marketing_id => $emailmarketingid,
        list_id => $prospectlistid,
        related_id => $leadid, 
        related_type => 'Leads',
        user_id => 'f2347eb8-b5ed-b324-a316-4e26c9558337',
        modified_user_id => 'f2347eb8-b5ed-b324-a316-4e26c9558337',
    };
    ok($s->add_to_emailman($emailman_attrs), "Added mails to emailman");

=cut

sub add_to_emailman {
    my ($self, $attributes) = @_;

    my $now = DateTime->now->strftime("%Y-%m-%d %T");;
    my $id = int(Time::HiRes::time * 10**2) % (2**31);
    $$attributes{id} = $id;
    $$attributes{new_with_id} = 1;
    $$attributes{send_date_time} = $now;
    $$attributes{in_queue_date} = $now;

#    my $attributes = {
#        id=>$id,
# If you don't specify this then new_with_id will just not work...
#        new_with_id=>1,
#        campaign_id => $campaign_id,
#        marketing_id => $marketing_id,
#        list_id => $list_id,
#        related_id => $lead_id,
#        user_id => $user_id,
#        related_type => 'Leads',
#        modified_user_id => $user_id,
#        send_date_time => "$now",
#        in_queue_date => "$now",
#    };

    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = "EmailMan";
    $rest_data{'name_value_list'} = encode_json($attributes);
    $rest_data{'track_view'} = 'false';

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('set_entry', $rest_data_json);

    $self->log->info( "Successfully created emailman entry entry with sessionid ".$self->sessionid."\n");
    $self->log->debug("Module entry created was:".Dumper($response));
    return $response;

}


=head3 get_ids_from_campaignlog

Returns the id, searching for campaign_id, target_id, target_type, list_id, marketing_id

Input:
 * hash with 
   * campaign_id
   * target_id
   * target_type
   * list_id
   * marketing_id
   * email

Output:

 * an array ref with the campaign logs id,  if none found an empty hash array, and confess on error
 
=cut

sub get_ids_from_campaignlog {
    my ($self, $attributes) = @_;
    my @required_keys = ('campaign_id', 'target_id', 'target_type', 'list_id', 'marketing_id', 'email');
    foreach (@required_keys) {
        $self->log->logconfess("key $_ not found in attributes: ".Dumper($attributes))
            unless defined $$attributes{$_};
    }
    my $query = "( campaign_log.campaign_id = '".$$attributes{'campaign_id'}.
        "' AND campaign_log.target_id = '".$$attributes{'target_id'}.
        "' AND campaign_log.target_type = '".$$attributes{'target_type'}.
        "' AND campaign_log.list_id = '".$$attributes{'list_id'}.
        "' AND campaign_log.marketing_id = '".$$attributes{'marketing_id'}.
        "' ) OR campaign_log.more_information = '".$$attributes{'email'}."'";


    tie my %rest_data, 'Tie::IxHash';
    $rest_data{'session'} = $self->sessionid;
    $rest_data{'module_name'} = "CampaignLog";
    $rest_data{'query'} = $query;

    my $rest_data_json = encode_json(\%rest_data);

    my $response = $self->_rest_request('get_entry_list', $rest_data_json);

    $self->log->debug("Campaign log ids for found was:".Dumper($query, $attributes,$response));

    my @ids = map { $_->{id} } @{$response->{entry_list}};

    return \@ids;;
}

=head3 delete_ids_from_campaignlog

Returns the id, searching for campaign_id, target_id, target_type, list_id, marketing_id
Adds the lead identified by id to the specified to the outgoing email

For this method to work you need to get the database configuration set up see sttributes dsn, dbuser and dbpassword

Input:
 * reference to an array with campaign log ids to be deleted

Output:

 * None, confess on error

    my $attrs = {
        campaign_id => $campaignid,
        target_id => $contactid,
        target_type => 'Contacts',
        list_id => $prospectlistid,
        marketing_id => $emailmarketingid,
    };
    my $ids = $s->get_ids_from_campaignlog($attrs);
    $s->delete_ids_from_campaignlog($ids);

 
=cut

sub delete_ids_from_campaignlog {
    my ($self, $ids) = @_;

    $self->log->debug("delete_ids_from_campaignlog".Dumper($ids));

    foreach my $id (@$ids) {
        $self->_delete_sth->execute($id);
        $self->log->info("Deleted from campaignlog id  $id");
    }

    return;
}

# =head2 convertlead

# Input:

#  * leadid
#  * Opportunity attrs. As defined in L<create_opportunity>. If this is empty no opportunity is created

# Output:
#  * a hash with 
#    * contactid (created, or existent if the email exists as contact)
#    * accountid (created or existent if the name exists as account)
#    * opportunityid (created with the attributes specified)

# =cut

# sub _create_account_from_leadentry {
#     my ($self, $leadentry) = @_;
#     my $accountid = 1;
#     return $accountid;
# }

# sub _create_account_from_leadentry {
#     my ($self, $leadentry) = @_;
#     my $leadid = 1;
#     return $leadid;
# }

# sub convertlead {
#     my ($self, $leadid, $opportunity_args) = @_;

#     my $leadentry = $self->get_lead($leadid);
#     confess "No leadid found with leadid $leadid"
#         if (!defined($leadentry));
#     confess "Found leadentry with id $leadid, but no email attribute email1 defined... ".Dumper($leadentry)
#         if (!exists($leadentry->{name_value_list}->{email1}->{value}));
#     my $leademail = $leadentry->{name_value_list}->{email1}->{value};
    
#     my ($accountid, $newaccountid);
#     $accountid = $self->get_unique_account_id('accounts.name = "'.$leadentry->{account_name}.'"');
#     if (!defined($accountid)) {
#         $accountid = $self->_create_account_from_leadentry();
#         $newaccountid = $accountid;
#     }
#     # On error it sends an exception
#     # Check if accountid was empty
#     # check contact by mail
#     my ($contactid, $newcontactid);
#     try {
#         $contactid = $self->get_unique_contact_id_from_mail($leademail); # 
#         if (!defined($contactid)) {
#             $contactid = $self->_create_contact_from_leadentry($leadentry);
#             $newcontactid = $contactid;
#         }
#     } catch {
#         $self->delete_account_by_id($accountid) if (defined(e$newaccountid));
#         confess "Error creating contact, removing account $accountid from lead entry: $@. Entry: ".Dumper($leadentry);
#     };

    
# # leads

# #| id                         | char(36)     | NO   | PRI | NULL    |       | 
# #| date_entered               | datetime     | YES  |     | NULL    |       | 
# #| date_modified              | datetime     | YES  |     | NULL    |       | 
# #| modified_user_id           | char(36)     | YES  |     | NULL    |       | 
# #| created_by                 | char(36)     | YES  |     | NULL    |       | 
# #| description                | text         | YES  |     | NULL    |       | 
# #| deleted                    | tinyint(1)   | YES  | MUL | 0       |       | 
# #| assigned_user_id           | char(36)     | YES  | MUL | NULL    |       | 
# #| salutation                 | varchar(255) | YES  |     | NULL    |       | 
# #| first_name                 | varchar(100) | YES  |     | NULL    |       | 
# #| last_name                  | varchar(100) | YES  | MUL | NULL    |       | 
# #| title                      | varchar(100) | YES  |     | NULL    |       | 
# #| department                 | varchar(100) | YES  |     | NULL    |       | 
# #| do_not_call                | tinyint(1)   | YES  |     | 0       |       | 
# #| phone_home                 | varchar(100) | YES  |     | NULL    |       | 
# #| phone_mobile               | varchar(100) | YES  |     | NULL    |       | 
# #| phone_work                 | varchar(100) | YES  |     | NULL    |       | 
# #| phone_other                | varchar(100) | YES  |     | NULL    |       | 
# #| phone_fax                  | varchar(100) | YES  |     | NULL    |       | 
# #| primary_address_street     | varchar(150) | YES  |     | NULL    |       | 
# #| primary_address_city       | varchar(100) | YES  |     | NULL    |       | 
# #| primary_address_state      | varchar(100) | YES  |     | NULL    |       | 
# #| primary_address_postalcode | varchar(20)  | YES  |     | NULL    |       | 
# #| primary_address_country    | varchar(255) | YES  |     | NULL    |       | 
# #| alt_address_street         | varchar(150) | YES  |     | NULL    |       | 
# #| alt_address_city           | varchar(100) | YES  |     | NULL    |       | 
# #| alt_address_state          | varchar(100) | YES  |     | NULL    |       | 
# #| alt_address_postalcode     | varchar(20)  | YES  |     | NULL    |       | 
# #| alt_address_country        | varchar(255) | YES  |     | NULL    |       | 
# #| assistant                  | varchar(75)  | YES  |     | NULL    |       | 
# #| assistant_phone            | varchar(100) | YES  |     | NULL    |       | 
# #| converted                  | tinyint(1)   | YES  |     | 0       |       | 
# #| refered_by                 | varchar(100) | YES  |     | NULL    |       | 
# #| lead_source                | varchar(100) | YES  |     | NULL    |       | 
# #| lead_source_description    | text         | YES  |     | NULL    |       | 
# #| status                     | varchar(100) | YES  |     | NULL    |       | 
# #| status_description         | text         | YES  |     | NULL    |       | 
# #| reports_to_id              | char(36)     | YES  | MUL | NULL    |       | 
# #| account_name               | varchar(255) | YES  | MUL | NULL    |       | 
# #| account_description        | text         | YES  |     | NULL    |       | 
# #| contact_id                 | char(36)     | YES  | MUL | NULL    |       | 
# #| account_id                 | char(36)     | YES  | MUL | NULL    |       | 
# #| opportunity_id             | char(36)     | YES  | MUL | NULL    |       | 
# #| opportunity_name           | varchar(255) | YES  |     | NULL    |       | 
# #| opportunity_amount         | varchar(50)  | YES  |     | NULL    |       | 
# #| campaign_id                | char(36)     | YES  |     | NULL    |       | 
# #| birthdate                  | date         | YES  |     | NULL    |       | 
# #| portal_name                | varchar(255) | YES  |     | NULL    |       | 
# #| portal_app                 | varchar(255) | YES  |     | NULL    |       | 
# #| website                    | varchar(255) | YES  |     | NULL    |       | 
# #
# #mysql> describe accounts;
# #+-----------------------------+--------------+------+-----+---------+-------+
# #| Field                       | Type         | Null | Key | Default | Extra |
# #+-----------------------------+--------------+------+-----+---------+-------+
# #| id                          | char(36)     | NO   | PRI | NULL    |       | 
# #| name                        | varchar(150) | YES  | MUL | NULL    |       | 
# #| date_entered                | datetime     | YES  |     | NULL    |       | 
# #| date_modified               | datetime     | YES  |     | NULL    |       | 
# #| modified_user_id            | char(36)     | YES  |     | NULL    |       | 
# #| created_by                  | char(36)     | YES  |     | NULL    |       | 
# #| description                 | text         | YES  |     | NULL    |       | 
# #| deleted                     | tinyint(1)   | YES  | MUL | 0       |       | 
# #| assigned_user_id            | char(36)     | YES  |     | NULL    |       | 
# #| account_type                | varchar(50)  | YES  |     | NULL    |       | 
# #| industry                    | varchar(50)  | YES  |     | NULL    |       | 
# #| annual_revenue              | varchar(100) | YES  |     | NULL    |       | 
# #| phone_fax                   | varchar(100) | YES  |     | NULL    |       | 
# #| billing_address_street      | varchar(150) | YES  |     | NULL    |       | 
# #| billing_address_city        | varchar(100) | YES  |     | NULL    |       | 
# #| billing_address_state       | varchar(100) | YES  |     | NULL    |       | 
# #| billing_address_postalcode  | varchar(20)  | YES  |     | NULL    |       | 
# #| billing_address_country     | varchar(255) | YES  |     | NULL    |       | 
# #| rating                      | varchar(100) | YES  |     | NULL    |       | 
# #| phone_office                | varchar(100) | YES  |     | NULL    |       | 
# #| phone_alternate             | varchar(100) | YES  |     | NULL    |       | 
# #| website                     | varchar(255) | YES  |     | NULL    |       | 
# #| ownership                   | varchar(100) | YES  |     | NULL    |       | 
# #| employees                   | varchar(10)  | YES  |     | NULL    |       | 
# #| ticker_symbol               | varchar(10)  | YES  |     | NULL    |       | 
# #| shipping_address_street     | varchar(150) | YES  |     | NULL    |       | 
# #| shipping_address_city       | varchar(100) | YES  |     | NULL    |       | 
# #| shipping_address_state      | varchar(100) | YES  |     | NULL    |       | 
# #| shipping_address_postalcode | varchar(20)  | YES  |     | NULL    |       | 
# #| shipping_address_country    | varchar(255) | YES  |     | NULL    |       | 
# #| parent_id                   | char(36)     | YES  | MUL | NULL    |       | 
# #| sic_code                    | varchar(10)  | YES  |     | NULL    |       | 
# #| campaign_id                 | char(36)     | YES  |     | NULL    |       | 
# #+-----------------------------+--------------+------+-----+---------+-------+
# #33 rows in set (0.01 sec)
# #
# #mysql> describe opportunities;
# #+------------------+--------------+------+-----+---------+-------+
# #| Field            | Type         | Null | Key | Default | Extra |
# #+------------------+--------------+------+-----+---------+-------+
# #| id               | char(36)     | NO   | PRI | NULL    |       | 
# #| name             | varchar(50)  | YES  | MUL | NULL    |       | 
# #| date_entered     | datetime     | YES  |     | NULL    |       | 
# #| date_modified    | datetime     | YES  |     | NULL    |       | 
# #| modified_user_id | char(36)     | YES  |     | NULL    |       | 
# #| created_by       | char(36)     | YES  |     | NULL    |       | 
# #| description      | text         | YES  |     | NULL    |       | 
# #| deleted          | tinyint(1)   | YES  |     | 0       |       | 
# #| assigned_user_id | char(36)     | YES  | MUL | NULL    |       | 
# #| opportunity_type | varchar(255) | YES  |     | NULL    |       | 
# #| campaign_id      | char(36)     | YES  |     | NULL    |       | 
# #| lead_source      | varchar(50)  | YES  |     | NULL    |       | 
# #| amount           | double       | YES  |     | NULL    |       | 
# #| amount_usdollar  | double       | YES  |     | NULL    |       | 
# #| currency_id      | char(36)     | YES  |     | NULL    |       | 
# #| date_closed      | date         | YES  |     | NULL    |       | 
# #| next_step        | varchar(100) | YES  |     | NULL    |       | 
# #| sales_stage      | varchar(255) | YES  |     | NULL    |       | 
# #| probability      | double       | YES  |     | NULL    |       | 
# #+------------------+--------------+------+-----+---------+-------+
# #19 rows in set (0.00 sec)
# #
# #mysql> describe contacts;
# #+----------------------------+--------------+------+-----+---------+-------+
# #| Field                      | Type         | Null | Key | Default | Extra |
# #+----------------------------+--------------+------+-----+---------+-------+
# #| id                         | char(36)     | NO   | PRI | NULL    |       | 
# #| date_entered               | datetime     | YES  |     | NULL    |       | 
# #| date_modified              | datetime     | YES  |     | NULL    |       | 
# #| modified_user_id           | char(36)     | YES  |     | NULL    |       | 
# #| created_by                 | char(36)     | YES  |     | NULL    |       | 
# #| description                | text         | YES  |     | NULL    |       | 
# #| deleted                    | tinyint(1)   | YES  | MUL | 0       |       | 
# #| assigned_user_id           | char(36)     | YES  | MUL | NULL    |       | 
# #| salutation                 | varchar(255) | YES  |     | NULL    |       | 
# #| first_name                 | varchar(100) | YES  |     | NULL    |       | 
# #| last_name                  | varchar(100) | YES  | MUL | NULL    |       | 
# #| title                      | varchar(100) | YES  |     | NULL    |       | 
# #| department                 | varchar(255) | YES  |     | NULL    |       | 
# #| do_not_call                | tinyint(1)   | YES  |     | 0       |       | 
# #| phone_home                 | varchar(100) | YES  |     | NULL    |       | 
# #| phone_mobile               | varchar(100) | YES  |     | NULL    |       | 
# #| phone_work                 | varchar(100) | YES  |     | NULL    |       | 
# #| phone_other                | varchar(100) | YES  |     | NULL    |       | 
# #| phone_fax                  | varchar(100) | YES  |     | NULL    |       | 
# #| primary_address_street     | varchar(150) | YES  |     | NULL    |       | 
# #| primary_address_city       | varchar(100) | YES  |     | NULL    |       | 
# #| primary_address_state      | varchar(100) | YES  |     | NULL    |       | 
# #| primary_address_postalcode | varchar(20)  | YES  |     | NULL    |       | 
# #| primary_address_country    | varchar(255) | YES  |     | NULL    |       | 
# #| alt_address_street         | varchar(150) | YES  |     | NULL    |       | 
# #| alt_address_city           | varchar(100) | YES  |     | NULL    |       | 
# #| alt_address_state          | varchar(100) | YES  |     | NULL    |       | 
# #| alt_address_postalcode     | varchar(20)  | YES  |     | NULL    |       | 
# #| alt_address_country        | varchar(255) | YES  |     | NULL    |       | 
# #| assistant                  | varchar(75)  | YES  |     | NULL    |       | 
# #| assistant_phone            | varchar(100) | YES  |     | NULL    |       | 
# #| lead_source                | varchar(255) | YES  |     | NULL    |       | 
# #| reports_to_id              | char(36)     | YES  | MUL | NULL    |       | 
# #| birthdate                  | date         | YES  |     | NULL    |       | 
# #| campaign_id                | char(36)     | YES  |     | NULL    |       | 
# #+----------------------------+--------------+------+-----+---------+-------+
# #35 rows in set (0.00 sec)
# #
# #mysql> describe opportunities;
# #+------------------+--------------+------+-----+---------+-------+
# #| Field            | Type         | Null | Key | Default | Extra |
# #+------------------+--------------+------+-----+---------+-------+
# #| id               | char(36)     | NO   | PRI | NULL    |       | 
# #| name             | varchar(50)  | YES  | MUL | NULL    |       | 
# #| date_entered     | datetime     | YES  |     | NULL    |       | 
# #| date_modified    | datetime     | YES  |     | NULL    |       | 
# #| modified_user_id | char(36)     | YES  |     | NULL    |       | 
# #| created_by       | char(36)     | YES  |     | NULL    |       | 
# #| description      | text         | YES  |     | NULL    |       | 
# #| deleted          | tinyint(1)   | YES  |     | 0       |       | 
# #| assigned_user_id | char(36)     | YES  | MUL | NULL    |       | 
# #| opportunity_type | varchar(255) | YES  |     | NULL    |       | 
# #| campaign_id      | char(36)     | YES  |     | NULL    |       | 
# #| lead_source      | varchar(50)  | YES  |     | NULL    |       | 
# #| amount           | double       | YES  |     | NULL    |       | 
# #| amount_usdollar  | double       | YES  |     | NULL    |       | 
# #| currency_id      | char(36)     | YES  |     | NULL    |       | 
# #| date_closed      | date         | YES  |     | NULL    |       | 
# #| next_step        | varchar(100) | YES  |     | NULL    |       | 
# #| sales_stage      | varchar(255) | YES  |     | NULL    |       | 
# #| probability      | double       | YES  |     | NULL    |       | 
# #+------------------+--------------+------+-----+---------+-------+
# #19 rows in set (0.00 sec)
# #
# #mysql> 

# #mysql> select * from leads where last_name = "sainz"
# #    -> ;
# #+--------------------------------------+---------------------+---------------------+--------------------------------------+--------------------------------------+-------------+---------+------------------+------------+------------+-----------+----------+---------------+-------------+------------+--------------+--------------+-------------+-----------+------------------------+----------------------+-----------------------+----------------------------+-------------------------+--------------------+------------------+-------------------+------------------------+---------------------+-----------+-----------------+-----------+------------+-------------+-------------------------+--------+--------------------+---------------+--------------+---------------------+------------+------------+----------------+------------------+--------------------+-------------+-----------+-------------+------------+---------+
# #| id                                   | date_entered        | date_modified       | modified_user_id                     | created_by                           | description | deleted | assigned_user_id | salutation | first_name | last_name | title    | department    | do_not_call | phone_home | phone_mobile | phone_work   | phone_other | phone_fax | primary_address_street | primary_address_city | primary_address_state | primary_address_postalcode | primary_address_country | alt_address_street | alt_address_city | alt_address_state | alt_address_postalcode | alt_address_country | assistant | assistant_phone | converted | refered_by | lead_source | lead_source_description | status | status_description | reports_to_id | account_name | account_description | contact_id | account_id | opportunity_id | opportunity_name | opportunity_amount | campaign_id | birthdate | portal_name | portal_app | website |
# #+--------------------------------------+---------------------+---------------------+--------------------------------------+--------------------------------------+-------------+---------+------------------+------------+------------+-----------+----------+---------------+-------------+------------+--------------+--------------+-------------+-----------+------------------------+----------------------+-----------------------+----------------------------+-------------------------+--------------------+------------------+-------------------+------------------------+---------------------+-----------+-----------------+-----------+------------+-------------+-------------------------+--------+--------------------+---------------+--------------+---------------------+------------+------------+----------------+------------------+--------------------+-------------+-----------+-------------+------------+---------+
# #| 55002180-ee48-b7b9-4ec8-4e5c5a3b9ed7 | 2011-08-30 03:34:52 | 2011-08-30 03:34:52 | f2347eb8-b5ed-b324-a316-4e26c9558337 | f2347eb8-b5ed-b324-a316-4e26c9558337 | NULL        |       0 | NULL             | Mr         | Jorge      | Sainz     | Puto amo | Uno muy bueno |           0 | NULL       | NULL         |  34600000000 | NULL        | NULL      | NULL                   | NULL                 | NULL                  | NULL                       | NULL                    | NULL               | NULL             | NULL              | NULL                   | NULL                | NULL      | NULL            |         0 | NULL       | Online Demo | NULL                    | New    | NULL               | NULL          | Qindel       | NULL                | NULL       | NULL       | NULL           | NULL             | NULL               | NULL        | NULL      | NULL        | NULL       | NULL    | 
# # After lead conversion
# #| 55002180-ee48-b7b9-4ec8-4e5c5a3b9ed7 | 2011-08-30 03:34:52 | 2011-10-28 10:31:42 | 1                | f2347eb8-b5ed-b324-a316-4e26c9558337 | NULL        |       0 | NULL             | Mr         | Jorge      | Sainz     | Puto amo | Uno muy bueno |           0 | NULL       | NULL         |  34600000000 | NULL        | NULL      | NULL                   | NULL                 | NULL                  | NULL                       | NULL                    | NULL               | NULL             | NULL              | NULL                   | NULL                | NULL      | NULL            |         1 | NULL       | Online Demo | NULL                    | Converted | NULL               | NULL          | Qindel       | NULL                | b960509e-085f-76d2-6186-4eaa84c22c59 | c6a57a6d-6aab-8829-0058-4eaa849b236c | d15428f7-ddd8-9cd7-08e2-4eaa84b175c4 | NULL             | NULL               | NULL        | NULL      | NULL        | NULL       | NULL    | 

# #1 row in set (0.01 sec)
# #
# #mysql> 


# }

=head2 DESTROY

if the object is dereferenced and the sessionid is defined a logout is issued

=cut
sub DESTROY {
    my ($self) = @_;
    $self->logout;
    return;
}

=head2 update

Save the values of a Net::SugarCRM::Entry

=cut

sub update {
    # Update Net::SugarCRM::Entry in CRM
    my ($self, $entry) = @_;
    return $self->update_module_entry(
        $entry->{module_name},
        $entry->{id},
        $entry->{name_value_list});
}

=head1 TODO

=over 4

=item * convert lead

=back

=head1 AUTHOR

Nito Martinez, C<< <Nito at Qindel.ES> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sugarcrm-client-rest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SugarCRM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SugarCRM

    perldoc Net::SugarCRM::Tutorial

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SugarCRM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SugarCRM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SugarCRM>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SugarCRM/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item * Thanks to Phil Hallows Globe Microsystems L<www.globemicro.com> for contributing with get_module_link_ids and get_contact_account_ids  the methods

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nito Martinez.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
1; # End of Net::SugarCRM

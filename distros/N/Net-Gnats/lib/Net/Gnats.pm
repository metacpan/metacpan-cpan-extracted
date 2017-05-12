package Net::Gnats;
BEGIN {
  $Net::Gnats::VERSION = '0.22';
}
use 5.010_000;
use utf8;
use strictures;
use English '-no_match_vars';
use Net::Gnats::Session;
require Exporter;
use Net::Gnats::PR qw(deserialize serialize);
use Net::Gnats::Response;
use Net::Gnats::Command;
use Net::Gnats::Constants qw(CODE_OK CODE_GREETING CODE_INFORMATION CODE_TEXT_READY
                             CODE_INVALID_FTYPE_PROPERTY CODE_ERROR
                             CODE_GNATS_LOCKED CODE_CMD_ERROR CODE_ERROR
                             CODE_GNATS_NOT_LOCKED CODE_NONEXISTENT_PR CODE_LOCKED_PR
                             CODE_PR_NOT_LOCKED CODE_OK CODE_NO_ACCESS
                             CODE_SEND_PR CODE_SEND_TEXT CODE_FILE_ERROR
                             RESTART_CHECK_THRESHOLD
                             CODE_INFORMATION_FILLER
                             CODE_NO_PRS_MATCHED
                             CODE_INVALID_EXPR CODE_INVALID_QUERY_FORMAT
                             CODE_PR_READY CODE_INVALID_DATABASE
                             LF CR CRLF DOT CONT MAX_NEW_PRS);
use vars qw($VERSION);
my $current_session;
my $VERBOSE          = 0;
my $VERBOSE_LEVEL    = 0;
our @ISA              = qw(Exporter);
our @EXPORT           = qw($VERBOSE $VERBOSE_LEVEL);
our @EXPORT_OK        = qw(verbose verbose_level current_session);
$OUTPUT_AUTOFLUSH = 1;

=head1 NAME

Net::Gnats - Perl interface to GNU Gnats daemon

=head1 VERSION

0.22

=head1 DESCRIPTION

Net::Gnats provides a perl interface to the
L<gnatsd|http://www.gnu.org/software/gnats/> command set.  Although most of
the gnatsd command are present and can be explicitly called through
Net::Gnats, common gnats tasks can be accompished through some methods
which simplify the process (especially querying the database, editing bugs,
etc).

=head1 SYNOPSIS

  use Net::Gnats;

  # Instantiates object with Gnats hostname 'localhost' and port '1529'.
  my $g = Net::Gnats->new;

  # Creates the session between Net::Gnats and the gnatsd process.
  say 'Connected.' if $g->gnatsd_connect;

  # Retrieves the list of databases hosted by the server.  Typically,
  # it's the only command that can be performed without logging in.
  my $db_names = $g->get_dbnames;

  $g->login("default","somedeveloper","password");

  # Change field values in Gnats immediately by using the replaceField
  # method.

  my $pr = $g->get_pr_by_number(2);
  $pr->replaceField('Synopsis', 'The New Synopsis String');
  $pr->replaceField('Responsible', 'joe', q|Because It's Joe's|);

  # Change field values and submit the PR for update.  This is the
  # preferred method if many fields require updating.

  my $pr = $g->get_pr_by_number(3);
  $pr->setField('Synopsis', 'The New Synopsis String');
  $pr->setField('Responsible', 'joe', q|Because It's Joe's|);
  $g->update_pr($pr);

  my $new_pr = $g->new_pr();
  $new_pr->setField("Submitter-Id","developer");
  $g->submitPR($new_pr);

  # Close the session.  The session will close abruptly if the program
  # simply exits.

  $g->disconnect;

=head1 COMMON TASKS

=head2 VIEWING DATABASES

Fetching database names is the only action that can be done on a Gnats
object before logging in via the login() method.

  my $g = Net::Gnats->new;
  $g->gnatsd_connect;
  my @dbNames = $g->getDBNames;

Note that getDBNames() is different than listDatabases(), which
requires logging in first and gets a little more info than just names.

=head2 LOGGING IN TO A DATABASE

The Gnats object has to be logged into a database to perform almost
all actions.

  my $g = Net::Gnats->new;
  $g->gnatsd_connect;
  $g->login("default","myusername","mypassword");

=head2 SUBMITTING A NEW PR

The Net::Gnats::PR object acts as a container object to store
information about a PR (new or otherwise).  A new PR is submitted to
gnatsperl by constructing a PR object.

  my $pr = $g->new_pr;
  $pr->setField("Submitter-Id","developer");
  $pr->setField("Originator","Doctor Wifflechumps");
  $pr->setField("Organization","GNU");
  $pr->setField("Synopsis","Some bug from perlgnats");
  $pr->setField("Confidential","no");
  $pr->setField("Severity","serious");
  $pr->setField("Priority","low");
  $pr->setField("Category","gnatsperl");
  $pr->setField("Class","sw-bug");
  $pr->setField("Description","Something terrible happened");
  $pr->setField("How-To-Repeat","Like this.  Like this.");
  $pr->setField("Fix","Who knows");
  $g->submit_pr($pr);

Obviously, fields are dependent on a specific gnats installation,
since Gnats administrators can rename fields and add constraints.
There are some methods in Net::Gnats to discover field names and
constraints, all described below.

Instead of setting each field of the PR individually, the
setFromString() method is available.  The string that is passed to it
must be formatted in the way Gnats handles the PRs.  This is useful
when handling a Gnats email submission ($pr->setFromString($email))
or when reading a PR file directly from the database.  See
Net::Gnats::PR for more details.


=head2 QUERYING THE PR DATABASE

  my $prNums = $g->query('Number>"12"', "Category=\"$thisCat\"");
  print "Found " . join(":", @$prNums ) . " matching PRs \n";

Pass a list of query expressions to query().  A list of PR numbers of
matching PRs is returned.  You can then pull out each PR as described
next.


=head2 FETCHING A PR

  my $prnum = 23;
  my $PR = $g->get_pr_by_number($prnum);
  print $PR->getField('synopsis');
  print $PR->asString();

The method get_pr_by_number() will return a Net::Gnats::PR object
corresponding to the PR num that was passed to it.  The getField() and
asString() methods are documented in Net::Gnats::PR, but I will note
here that asString() returns a string in the proper Gnats format, and
can therefore be submitted directly to Gnats via email or saved to the
db directory for instance.  Also:

 $pr->setFromString($oldPR->asString() );

 works fine and will result in a duplicate of the original PR object.


=head2 MODIFYING A PR

There are 2 methods of modifying fields in a Net::Gnats::PR object.

The first is to use the replaceField() or appendField() methods which
uses the gnatsd REPL and APPN commands.  This means that the changes
to the database happen immediatly.

  my $prnum = 23;
  my $PR = $g->get_pr_by_number($prnum);
  if (! $PR->replaceField('Synopsis','New Synopsis')) {
    warn "Error replacing field (" . $g->get_error_message . ")\n";
  }

If the field requires a change reason, it must be supplied as the 3rd argument.

  $PR->replaceField('Responsible','joe',"It's joe's problem");

The second is to use the setField() and updatePR() methods which uses
the gnatsd EDIT command.  This should be used when multiple fields of
the same PR are being changed, since the datbase changes occur at the
same time.

  my $prnum = 23;
  my $PR = $g->get_pr_by_number($prnum);
  $PR->setField('Synopsis','New Synopsis');
  $PR->setField('Responsible','joe',"It's joe's problem");
  if (! $g->updatePR($PR) ) {
    warn "Error updating $prNum: " . $g->get_error_message . "\n";
  }

=head1 CONSTRUCTOR

=head2 new

Constructor, optionally taking one or two arguments of hostname and
port of the target gnats server.  If not supplied, the hostname
defaults to localhost and the port to 1529.

=cut

sub new {
  my ( $class, $host, $port ) = @_;
  my $self = bless {}, $class;

  $host = $host || 'localhost';
  $port = $port || '1529';
  $self->{session} = Net::Gnats::Session->new(hostname => $host,
                                              port => $port);

  # stash this globally so we can use it in fallback scenarios
  $current_session = $self->{session};
  return $self;
}

=head1 ACCESSORS

=head2 current_session

Exported function.

Retrieves the currently used session (last initialized).

=cut

sub current_session {
  my ($self, $session) = @_;
  $current_session = $session if defined $session;
  return $current_session;
}

=head2 skip_version_check

If you are using a custom gnats daemon, your version number might
"not be supported".  If you are sure you know what you are doing
and am willing to take the consequences:

 my $g = Net::Gnats->new();
 $g->skip_version_check(1);

=cut

sub skip_version_check {
  my ($self, $value) = @_;
  $self->session->skip_version(1);
}

=head2 session

Retrieve the session currently in effect.  Used for Net::Gnats
instantiated objects only.

 my $session = $g->session;

=cut

sub session { shift->{session}; }

=head2 verbose

Sets verbose on. By default, verbose is off. The default setting is
optimized for headless execution.

To turn verbose on, change to 1.

=cut

sub verbose {
  my ($class, $value) = @_;
  $VERBOSE = $value if defined $value;
  return $VERBOSE;
}

=head2 verbose_level

Sets the verbose level. The levels are:

 0: No level (based on verbose being on)
 1: Brief error, displays Gnats error codes.
 2: Detailed error, displays Gnats error codes and any messages.
 3: Trace, full code path walking.

=cut

sub verbose_level {
  my ($class, $value) = @_;
  $VERBOSE_LEVEL = $value if defined $value;
  return $VERBOSE * $VERBOSE_LEVEL;
}

=head1 METHODS

=cut


=head2 gnatsd_connect

Connects to the gnats server.  No arguments.  Returns true if
successfully connected, false otherwise.

=cut

sub gnatsd_connect {
  my ( $self ) = shift;
  my $conn = $self->session->gconnect;
  return 0 if not defined $conn;
  return $conn->is_connected;
}

=head2 disconnect

Issues the QUIT command to the Gnats server, thereby closing the
connection.

Although the Gnats documentation says there is not a failure case for
this command, it responds true/false accordingly.

 $g->disconnect;

=cut

sub disconnect {
  return shift->session->issue(Net::Gnats::Command->quit)->is_ok;
}

=head2 get_dbnames

Issues the DBLS command, and returns a list of database names in the
gnats server.  Unlike listDatabases, one does not need to use the logn
method before using this method.

 my $list = $g->get_dbnames;

=cut

sub getDBNames { shift->get_dbnames; }

sub get_dbnames {
  shift->session->issue(Net::Gnats::Command->dbls)
    ->response
    ->as_list;
}

=head2 list_databases

Issues the LIST DATABASES command, and returns a list of hashrefs with
keys 'name', 'desc', and 'path'.

=cut

sub list_databases {
  my ( $self ) = @_;
  $self->session->issue(Net::Gnats::Command->list(subcommand => 'databases')
                       )->formatted;
}

=head2 list_categories

Issues the LIST CATEGORIES command, and returns a list of hashrefs
with keys 'name', 'desc', 'contact', and '?'.

=cut

sub list_categories {
  my $self = shift;
  $self->session->issue(Net::Gnats::Command->list(subcommand => 'categories')
                       )->formatted;
}

=head2 list_submitters

Issues the LIST SUBMITTERS command, and returns a list of hashrefs
with keys 'name', 'desc', 'contract', '?', and 'responsible'.

 my $s = $gnats->list_submitters;

=cut

sub list_submitters {
  my $self = shift;
  $self->session->issue(Net::Gnats::Command->list(subcommand => 'submitters')
                       )->formatted;
}

=head2 list_responsible

Issues the LIST RESPONSIBLE command, and returns a list of hashrefs
with keys 'name', 'realname', and 'email'.

=cut

sub list_responsible {
  my $self = shift;
  $self->session->issue(Net::Gnats::Command->list(subcommand => 'responsible')
                       )->formatted;
}

=head2 list_states

Issues the LIST STATES command, and returns a list of hashrefs with
keys 'name', 'type', and 'desc'.

=cut

sub list_states {
  my $self = shift;
  $self->session->issue(Net::Gnats::Command->list(subcommand => 'states')
                       )->formatted;
}

=head2 list_fieldnames

Issues the LIST FIELDNAMES command, and returns a list of hashrefs
with key 'name'.

Protocol: returns an anonymous array of field names.

=cut

sub list_fieldnames {
  my $self = shift;
  $self->session->issue(Net::Gnats::Command->list(subcommand => 'fieldnames')
                       )->response->as_list;
}

=head2 list_inputfields_initial

Issues the LIST INITIALINPUTFIELDS command, and returns a list of
hashrefs with key 'name'.

=cut

sub list_inputfields_initial {
  my $self = shift;
  $self
    ->session
    ->issue(Net::Gnats::Command->list(subcommand => 'initialinputfields')
           )->response->as_list;
}

sub list_inputfields_initial_required {
  my $self = shift;
  $self
    ->session
    ->issue(Net::Gnats::Command->list(subcommand => 'initialrequiredfields')
           )->response->as_list;
}

=head2 get_field_type

Expects a single fieldname or an anonymous array of field types.

Returns 0 if the type information could not be retrieved.

Returns a list of types based on the number of fields passed.

=cut

sub get_field_type {
  my ( $self, $field ) = @_;

  return 0 if not defined $field;

  my $c = $self->session->issue(Net::Gnats::Command->ftyp(fields => $field));

  return 0 if not $c->is_ok;
  return $c->response->as_list;
}

=head2 get_field_type_info

Expects a fieldname and property as arguments, and issues the FTYPINFO
command.  Returns text response or undef if error.

=cut

sub get_field_type_info {
  my ( $self, $field, $property ) = @_;
  return 0 if not defined $field;
  $property = $property || 'separators';
  $self->session->issue(Net::Gnats::Command->ftypinfo(field => $field,
                                                     property => $property)
                       )->response->as_string;
}

=head2 get_field_desc

Expects a fieldname as sole argument, and issues the FDSC command.
Returns text response or undef if error.

=cut

sub get_field_desc {
  my ( $self, $field ) = @_;
  return 0 if not defined $field;
  $self->session->issue(Net::Gnats::Command->fdsc(fields => $field)
                       )->response->as_list;
}

=head2 get_field_flags

Expects a fieldname as sole argument, and issues the FIELDFLAGS
command.  Returns text response or undef if error.

=cut

sub get_field_flags {
  my ( $self, $field, $flag ) = @_;
  return 0 if not defined $field;
  $self->session->issue(Net::Gnats::Command->fieldflags(fields => $field)
                       )->response->as_list;
}

=head2 get_field_validators

Expects a fieldname as sole argument, and issues the FVLD command.
Returns text response or undef if error.

=cut

sub get_field_validators {
  my ( $self, $field ) = @_;
  return 0 if not defined $field;
  my $c = $self->session->issue(Net::Gnats::Command->fvld(field => $field));
  return 0 if not $c->is_ok;
  $c->response->as_list;
}

=head2 validate_field

Expects a Net::Gnats::FieldInstance object,
and issues the VFLD command.  Returns true if propose value is
acceptable, false otherwise.

 $g->validate_field(Net::Gnats::FieldInstance->new(name => 'Originator', value => 'rich'));

=cut

sub validate_field {
  my ( $self, $field ) = @_;

  return $self
    ->session
    ->issue(Net::Gnats::Command->vfld(field => $field))
    ->is_ok;
}

=head2 get_field_default

Expects a fieldname as sole argument, and issues the INPUTDEFAULT
command.  Returns text response or undef if error.

=cut

sub get_field_default {
  my ( $self, $field ) = @_;
  $self->session->issue(Net::Gnats::Command->inputdefault(fields => $field)
                       )->response->as_list;
}

=head2 reset_server

Issues the RSET command, returns true if successful, false otherwise.

=cut

sub reset_server {
  shift->session->issue(Net::Gnats::Command->rset)->is_ok;
}

=head2 lock_main_database

Issues the LKDB command, returns true if successful, false otherwise.

=cut

sub lock_main_database {
  shift->session->issue(Net::Gnats::Command->lkdb)->is_ok;
}


=head2 unlock_main_database

Issues the UNDB command, returns true if successful, false otherwise.

=cut

sub unlock_main_database {
  shift->session->issue(Net::Gnats::Command->undb)->is_ok;
}

=head2 lock_pr

Expects a PR number and user name as arguments, and issues the LOCK
command.  Returns true if PR is successfully locked, false otherwise.

NEW:
Note that the response content has the PR.  If you would like the PR
from this response:

 my $s = $gnats->session;
 $s->issue(Net::Gnats::Command->lock_pr( ... ))->response->as_list;

=cut

sub lock_pr {
  my ( $self, $pr_number, $user ) = @_;
  return 0 if not defined $pr_number or not defined $user;
  $self->session->issue(Net::Gnats::Command->lock_pr(pr_number => $pr_number,
                                                     user => $user))->is_ok;
}

=head2 unlock_pr

Expects a PR number a sole argument, and issues the UNLK command.
Returns true if PR is successfully unlocked, false otherwise.

=cut

sub unlock_pr {
  my ( $self, $pr_number ) = @_;
  return 0 if not defined $pr_number;
  $self->session->issue(Net::Gnats::Command->unlk(pr_number => $pr_number)
                       )->is_ok;
}

=head2 delete_pr($pr)

Expects a PR number a sole argument, and issues the DELETE command.
Returns true if PR is successfully deleted, false otherwise.

=cut

sub delete_pr {
  my ( $self, $pr_number ) = @_;
  return 0 if not defined $pr_number;
  $self->session->issue(Net::Gnats::Command->delete_pr(pr_number => $pr_number)
                       )->is_ok;
}

sub check_newpr {
  my ( $self, $pr ) = @_;
  $self->check_pr($pr, 'initial');
  return;
}


=head2 check_pr

Expects the text representation of a PR (see COMMON TASKS above) as
input and issues the CHEK initial command.  Returns true if the given
PR is a valid entry, false otherwise.

=cut

sub check_pr {
  my ( $self, $pr, $arg ) = @_;

  $self->session
    ->issue(Net::Gnats::Command->chek( pr => $pr, type => $arg))
    ->is_ok;
}


=head2 set_workingemail

Expects an email address as sole argument, and issues the EDITADDR
command.  Returns true if email successfully set, false otherwise.

=cut

sub set_workingemail {
  my ( $self, $email ) = @_;
  $self->session
    ->issue(Net::Gnats::Command->editaddr(address => $email))
    ->is_ok;
}

#
# TODO: "text" fields are limited to 256 characters.  Current gnatsd does
# not correctly truncate, if you enter $input is 257 characters, it will
# replace with an empty field.  We should truncate text $input's correctly.

=head2 truncate_field_content

Expects a PR number, a fieldname, a replacement value, and optionally
a changeReason value as arguments, and issues the REPL command.
Returns true if field successfully replaced, false otherwise.

If the field has requireChangeReason attribute, then the changeReason
must be passed in, otherwise the routine will return false.

replaceField changes happen immediatly in the database.  To change
multiple fields in the same PR it is more efficiant to use updatePR.

=cut

sub truncate_field_content {
  my ( $self, $pr, $field, $input, $reason ) = @_;
  logerror('? Error: pr not passed to replaceField')
    if not defined $pr;

  logerror('? Error: field passed to replaceField')
    if not defined $field;

  logerror('? Error: no input passed to replaceField')
    if not defined $input;

  # See if this field requires a change reason.
  # TODO: We could just enter the $input, and see if gnatsd says
  #       a reason is required, but I could not figure out how to
  #       abort at that point if no reason was given...
  my $need_reason = $self->getFieldFlags($field, 'requireChangeReason');

  if ($need_reason and ( not defined $reason or $reason eq q{} )) {
    logerror('No change Reason Specified');
    return;
  }

  my $r = $self->_do_gnats_cmd("REPL $pr $field");

  if ( $r->code == CODE_SEND_TEXT ) {
    $r = $self->_do_gnats_cmd($input . LF . DOT);

    if ($need_reason) {
      #warn "reason=\"$reason\"";
      # TODO: This can choke here if we encounter a PR with a bad field like:
      # _getGnatsdResponse: READ >>411 There is a bad value `unknown' for the field `Category'.
      $r = $self->_do_gnats_cmd($reason . LF . DOT)
    }

    $self->restart($r->code)
      and return $self->replaceField($pr, $field, $input, $reason)
      if $r->code == CODE_FILE_ERROR;

    if ($self->_is_code_ok($r->code)) {
      return 1;
    }
    $self->_mark_error($r);

  }

  $self->_mark_error($r );
  return;
}

my $restart_time;

sub restart {
  my ( $self, $code ) = @_;

  my $ctime = time;
  if ( defined $restart_time ) {
    if ( ($ctime - $restart_time) < RESTART_CHECK_THRESHOLD ) {
      logerror('! ERROR: Restart attempted twice in a row, 640 error must be real!');
      return 0;
    }
  }

  logerror ( LF
      .  LF . '! ERROR: Recieved GNATSD code ' . $code . ', will now disconnect and'
      .  LF . 'reconnecting to gnatsd, then re-issue the command.  This may cause any'
      .  LF . 'following commands to behave differently if you depended on'
      .  LF . 'things like QFMT'
      .  LF . time . LF );

  $restart_time = $ctime;
  $self->session->gconnect;
  return $self->session->is_connected;
}

=head2 append_field_content

Expects a PR number, a fieldname, and a append value as arguments, and
issues the APPN command.  Returns true if field successfully appended
to, false otherwise.

=cut

sub append_field_content {
  my ( $self, $pr, $field, $input ) = @_;

  logerror('? Error: pr not passed to appendField')
    if not defined $pr;
  logerror('? Error: field passed to appendField')
      if not defined $field;
  logerror('? Error: no input passed to appendField')
    if not defined $input;

  my $r = $self->_do_gnats_cmd("APPN $pr $field");

  if ($self->_is_code_ok($r->code)) {
    $r= $self->_do_gnats_cmd( $input . LF . DOT );
    if ($self->_is_code_ok($r->code)) {
      return 1;
    } else {
      $self->_mark_error( $r );
    }
  } else {
    $self->_mark_error($r);
  }
  if ($r->code == CODE_FILE_ERROR and $self->restart($r->code)) {
    # TODO: This can potentially be an infinte loop...
    return $self->appendToField($pr, $field, $input);
  }
  return 0;
}

=head2 submit_pr

Expect a Gnats::PR object as sole argument, and issues the SUMB
command.  Returns true if PR successfully submitted, false otherwise.

DEPRECATION NOTICE: This method will be deprecated soon.  Please be
aware that you can submit a PR from a PR object.

 $pr = $pr->submit;

And $pr will contain the new PR number.  See PR.pm for details.

=cut

sub submitPR { shift->submit_pr( shift ); }

sub submit_pr {
  my ( $self, $pr ) = @_;
  $self->session->issue(Net::Gnats::Command->subm(pr => $pr))->is_ok;
}

=head2 update_pr

Expect a Gnats::PR object as sole argument, and issues the EDIT
command.  Returns true if PR successfully submitted, false otherwise.

Use this instead of replace_field if more than one field has changed.

=cut

sub updatePR { shift->update_pr(shift); }

sub update_pr {
  my ( $self, $pr ) = @_;
  return 0 if not defined $pr;

  return 0 if not
    $self->session
    ->issue(Net::Gnats::Command->editaddr(address => $self->session->username))
    ->is_ok;

  return 0 if not
    $self->session
    ->issue(Net::Gnats::Command->lock_pr(pr_number => $pr->get_field('Number')->value,
                                         user => $self->session->username ))
    ->is_ok;

  my $c = $self->session
    ->issue(Net::Gnats::Command->edit(pr => $pr));

  return 0 if not
    $self->session
    ->issue(Net::Gnats::Command->unlk(pr_number => $pr->get_field('Number')->value))
    ->is_ok;

  $c->is_ok;
}

=head2 new_pr

returns undef if the session is not initialized.

=cut

sub new_pr {
  my ( $self ) = @_;

  my $pr = Net::Gnats::PR->new;

  # session not properly initialized, send back empty PR
  return undef if not defined $self->session->schema;

  foreach my $field ( @{ $self->session->schema->fields } ) {
    $pr->add_field(Net::Gnats::FieldInstance
                   ->new(schema => $self->session->schema->field($field)));
  }
  return $pr;
}

=head2 get_pr_by_number()

Expects a number as sole argument.  Returns a Gnats::PR object.

=cut

sub get_pr_by_number {
  my ( $self, $pr_number ) = @_;
  return undef
    if not defined $pr_number;
  return undef
    if not $self->session->issue(Net::Gnats::Command->rset)->is_ok;
  return undef
    if not $self->session->issue(Net::Gnats::Command->qfmt(format => 'full'))->is_ok;

  my $raw = $self
    ->session
    ->issue(Net::Gnats::Command->quer(pr_numbers => [ $pr_number ]))
    ->response->as_list;

  return Net::Gnats::PR->deserialize( data => $raw,
                                      schema => $self->session->schema);

}



sub expr {
  my $self = shift;
  my @exprs = @_;
  return 1 if scalar( @exprs ) == 0;
  return $self
    ->session
    ->issue(Net::Gnats::Command->expr(expressions => \@exprs))
    ->is_ok;
}

# Because we don't know what's in the dbconfig file, we will only
# support FULL, STANDARD, and SUMMARY since those must be defined.
# Otherwise, we assume it is a custom format.
sub qfmt {
  my ($self, $format) = @_;
  $format = $format || 'standard';
  return $self->session->issue(Net::Gnats::Command->qfmt(format => $format))
    ->is_ok;
}

=head2 query()

Expects one or more query expressions as argument(s).  Returns an
anonymous array of PR numbers.

If there is an error, then it will return an empty set.

=cut

sub query {
  my $self = shift;
  my @exprs = @_;

  return [] if not $self->reset_server;
  return [] if not $self->qfmt('full');
  return [] if not $self->expr(@exprs);

  my $c = $self->session->issue(Net::Gnats::Command->quer);
  return [] if not $c->is_ok;
  my $r = $c->response->as_list;
  my @numbers = grep { $_ =~ s/>Number:\s+(.*)/$1/} @{$r};
  return \@numbers;
}

=head2 login

Expects a database name, user name, and password as arguments and
issues the CHDB command.  Returns true if successfully logged in,
false otherwise.

 my $g = Net::Gnats->new;
 $g->login('mydb', 'joe', 'joepass');

=cut

sub login {
  my ( $self, $db, $username, $password ) = @_;
  if ( not defined $password or $password eq q{} ) { $password = q{*}; }

  $self->session->username($username);
  $self->session->password($password);
  return 0 if not $self->session->authenticate;

  $self->session->database($db) if $self->session->database ne $db;
  return 1 if $self->session->database eq $db;
  return 0;
}

=head2 get_access_mode

Returns the current access mode of the gnats database.  Either "edit",
"view", or undef;

=cut

sub get_access_mode { shift->session->access; }

1;

=head1 DIAGNOSTICS

Most methods will return undef if a major error is encountered.

The most recent error codes and messages which Net::Gnats encounters
while communcating with gnatsd are stored, and can be accessed with
the get_error_code() and get_error_message() methods.

=head1 INCOMPATIBILITIES

This library is not compatible with the Gnats protocol prior to GNATS
4.

=head1 BUGS AND LIMITATIONS

Bug reports are very welcome.  Please submit to the project page
(noted below).

=head1 CONFIGURATION AND ENVIRONMENT

No externalized configuration or environment at this time.

=head1 DEPENDENCIES

No runtime dependencies other than the Perl core at this time.

=head1 AUTHOR

Current Maintainer:
Richard Elberger riche@cpan.org

Original Author:
Mike Hoolehan, <lt>mike@sycamore.us<gt>

Contributions By:
Jim Searle, <lt>jims2@cox.net<gt>
Project hosted at sourceforge, at http://gnatsperl.sourceforge.net

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, Richard Elberger.  All Rights Reserved.

Copyright (c) 1997-2003, Mike Hoolehan. All Rights Reserved.

This module is free software. It may be used, redistributed,
and/or modified under the same terms as Perl itself.

=cut

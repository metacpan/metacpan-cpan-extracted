package Net::Gnats::Command;
use utf8;
use strictures;
use Scalar::Util 'reftype';

BEGIN {
  $Net::Gnats::Command::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Response;
use Net::Gnats::Command::ADMV;
use Net::Gnats::Command::APPN;
use Net::Gnats::Command::CHDB;
use Net::Gnats::Command::CHEK;
use Net::Gnats::Command::DBLS;
use Net::Gnats::Command::DBDESC;
use Net::Gnats::Command::DELETE;
use Net::Gnats::Command::EDIT;
use Net::Gnats::Command::EDITADDR;
use Net::Gnats::Command::EXPR;
use Net::Gnats::Command::FDSC;
use Net::Gnats::Command::FIELDFLAGS;
use Net::Gnats::Command::FTYP;
use Net::Gnats::Command::FTYPINFO;
use Net::Gnats::Command::FVLD;
use Net::Gnats::Command::INPUTDEFAULT;
use Net::Gnats::Command::LIST;
use Net::Gnats::Command::LKDB;
use Net::Gnats::Command::LOCK;
use Net::Gnats::Command::QFMT;
use Net::Gnats::Command::QUER;
use Net::Gnats::Command::REPL;
use Net::Gnats::Command::RSET;
use Net::Gnats::Command::SUBM;
use Net::Gnats::Command::UNDB;
use Net::Gnats::Command::UNLK;
use Net::Gnats::Command::USER;
use Net::Gnats::Command::VFLD;
use Net::Gnats::Command::QUIT;

=head1 NAME

Net::Gnats::Command - Command factory and base class.

=head1 VERSION

0.18

=head1 DESCRIPTION

Encapsulates all Gnats Daemon commands and their command processing
codes.

This module implements the factory pattern for retrieving specific
commands.

=cut

our @EXPORT_OK =
  qw(admv appn chdb chek dbdesc dbls delete_pr edit editaddr expr fdsc
     fieldflags ftyp ftypinfo fvld inputdefault list lkdb lock_pr qfmt
     quer quit repl rset subm undb unlk user vfld);

=head1 CONSTRUCTOR

=head2 new

Instantiates a new L<Net::Gnats::Command> object.

 $c = Net::Gnats::Command->new;

This class is not instantiated directly; it is a superclass for all Gnats
command objects.

=cut

sub new {
  my ($class, %options) = @_;

  my $self = bless {}, $class;
  return $self;
}

=head1 ACCESSORS

=head2 field

Sets and retrieves a L<Net::Gnats::FieldInstance> to the command.

=cut

sub field {
  my ( $self, $value ) = @_;
  return $self->{field} if not defined $value;
  return $self->{field} if not defined reftype($value);
  return $self->{field} if not reftype($value) eq 'HASH';
  return $self->{field} if not $value->isa('Net::Gnats::FieldInstance');

  $self->{field} = $value;
  return $self->{field};
}

=head2 field_change_reason

Sets and retrieves a L<Net::Gnats::FieldInstance> for Change Reasons to the
command.

This may be removed in the future given a FieldInstance now manages its own
Change Reason.

=cut

sub field_change_reason {
  my ( $self, $value ) = @_;
  return $self->{field_change_reason} if not defined $value;
  return $self->{field_change_reason} if not defined reftype($value);
  return $self->{field_change_reason} if not reftype($value) eq 'HASH';
  return $self->{field_change_reason}
    if not $value->isa('Net::Gnats::FieldInstance');

  $self->{field_change_reason} = $value;
  return $self->{field_change_reason};
}

=head2 pr

For commands that must send a serialized PR, or serialized field, after issuing a command.

=cut

sub pr {
  my ( $self, $value ) = @_;
  return $self->{pr} if not defined $value;
  return $self->{pr} if not defined reftype($value);
  return $self->{pr} if not reftype($value) eq 'HASH';
  return $self->{pr} if not $value->isa('Net::Gnats::PR');

  $self->{pr} = $value;
  return $self->{pr};
}

=head2 error_codes

Retrieves the valid error codes for the command.  Not used yet.

 my $codes = $c->error_codes;

=cut

sub error_codes   { shift->{error_codes} }


=head2 success_codes

Retrieves the valid success codes for the command.  Not used yet.

 my $codes = $c->success_codes;

=cut

sub success_codes { shift->{success_codes} }

=head2 response

Manages the response outcome from the server encapsulated in a
L<Net::Gnats::Response> object.

When the command has not been issued yet, the value will be undef.

 $response = $c->response;
 $code = $c->response->code;

=cut

sub response {
  my ($self, $value) = @_;
  $self->{response} = $value if defined $value;
  return $self->{response};
}

=head2 requests_multi

A flag for knowing if multiple responses are expected.  Normally used and
managed internally.  May become a private method later.

=cut

sub requests_multi {
  my $self = shift;
  return $self->{requests_multi};
}


=head1 METHODS

=head2 as_string

Returns the currently configured command as a string.

=cut

sub as_string {
  my ( $self ) = @_;
}

=head2 from

This method is used for commands where 1..n fields can be defined for a given
command, and the issuer needs to match up field names to values.

 $c = Net::Gnats::Command->fdsc( [ 'FieldA', 'FieldB' ];
 Net::Gnats->current_session->issue( $c );
 $value = $c->from( 'FieldA' ) unless not $c->is_ok;

=cut

sub from {
  my ( $self, $value ) = @_;
  # identify idx of value
  my @fields = @{ $self->{fields} };
  my ( $index )= grep { $fields[$_] =~ /$value/ } 0..$#fields;
  return @{ $self->response->as_list }[$index];
}

=head1 EXPORTED METHODS

The following exported methods are helpers for executing all Gnats
protocol commands.

=head2 admv

 my $c = Net::Gnats::Command->admv;

=cut

sub admv         { shift; return Net::Gnats::Command::ADMV->new( @_ ); }

=head2 appn

Manages the command for appending field content to an existing PR field. The
field key is a L<Net::Gnats::FieldInstance> object.

 $c = Net::Gnats::Command->appn( pr_number => 5, field => $field );

See L<Net::Gnats::Command::APPN> for details.

=cut

sub appn         { shift; return Net::Gnats::Command::APPN->new( @_ ); }

=head2 chdb

Manages the command for changing databases within the same
L<Net::Gnats::Session> instance.

 $c = Net::Gnats::Command->chdb( database => 'external' );

See L<Net::Gnats::Command::CHDB> for details.

=cut

sub chdb         { shift; return Net::Gnats::Command::CHDB->new( @_ ); }

=head2 chek

Manages the command for checking the validity of a PR before sending.

 # New problem reports:
 $c = Net::Gnats::Command->chek( type => 'initial', pr => $pr );

 # Existing problem reports:
 $c = Net::Gnats::Command->chek( pr => $pr );

See L<Net::Gnats::Command::CHEK> for details.

=cut

sub chek         { shift; return Net::Gnats::Command::CHEK->new( @_ ); }

=head2 dbls

Manages the command to list server databases.  This command is the only command
that typically does not require credentials.

 $c = Net::Gnats::Command->dbls;

See L<Net::Gnats::Command::DBLS> for details.

=cut

sub dbls         { shift; return Net::Gnats::Command::DBLS->new( @_ ); }

=head2 dbdesc

Manages the command for returning the description of the databases existing on
the server.

 $c = Net::Gnats::Command->dbdesc;

See L<Net::Gnats::Command::DBDESC> for details.

=cut

sub dbdesc       { shift; return Net::Gnats::Command::DBDESC->new( @_ ); }

=head2 delete_pr

Manages the command for deleting a PR from the database.  Only those with
'admin' credentials can successfully issue this command.

 $c = Net::Gnats::Command->delete_pr( pr => $pr );

See L<Net::Gnats::Command::DELETE> for details.

=cut

sub delete_pr    { shift; return Net::Gnats::Command::DELETE->new( @_ ); }

=head2 edit

Manages the command for submitting an update to an existing PR to the database.

 $c = Net::Gnats::Command->edit( pr => $pr );

See L<Net::Gnats::Command::EDIT> for details.

=cut

sub edit         { shift; return Net::Gnats::Command::EDIT->new( @_ ); }

=head2 editaddr

Manages the command for setting the active email address for the session.  This
is most relevant when submitting or editing PRs.

 $address = 'joe@somewhere.com';
 $c = Net::Gnats::Command->editaddr( address => $address );

See L<Net::Gnats::Command::EDITADDR> for details.

=cut

sub editaddr     { shift; return Net::Gnats::Command::EDITADDR->new( @_ ); }

=head2 expr

Manages the command for setting the query expression for a PR.  Query
expressions AND together.

This method may change in the future.

 $c = Net::Gnats::Command->expr( expressions => ['foo="bar"', 'bar="baz"'] );

See L<Net::Gnats::Command::EXPR> for details.

=cut

sub expr         { shift; return Net::Gnats::Command::EXPR->new( @_ ); }

=head2 fdsc

Manages the command for retrieving the description for one or more fields.

 $c = Net::Gnats::Command->fdsc( fields => 'MyField' );
 $c = Net::Gnats::Command->fdsc( fields => [ 'Field1', 'Field2' ] );

See L<Net::Gnats::Command::FDSC> for details.

=cut

sub fdsc         { shift; return Net::Gnats::Command::FDSC->new( @_ ); }

=head2 fieldflags

Manages the command for retrieving field flags for one or more fields.

 $c = Net::Gnats::Command->fieldflags( fields => 'MyField' );
 $c = Net::Gnats::Command->fieldflags( fields => [ 'Field1', 'Field2' ] );

See L<Net::Gnats::Command::FIELDFLAGS> for details.

=cut

sub fieldflags   { shift; return Net::Gnats::Command::FIELDFLAGS->new( @_ ); }

=head2 ftyp

Manages the command for retrieving the data type for one or more fields.

 $c = Net::Gnats::Command->ftyp( fields => 'MyField' );
 $c = Net::Gnats::Command->ftyp( fields => [ 'Field1', 'Field2' ] );

See L<Net::Gnats::Command::FTYP> for details.

=cut

sub ftyp         { shift; return Net::Gnats::Command::FTYP->new( @_ ); }

=head2 ftypinfo

Manages the command for retrieving the type information for a field. Relevant
to MultiEnum fields only.

 $c = Net::Gnats::Command->ftypinfo( field => 'MyField' );
 $c = Net::Gnats::Command->ftypinfo( field => 'MyField',
                                     property => 'separators );

See L<Net::Gnats::Command::FTYPINFO> for details.

=cut

sub ftypinfo     { shift; return Net::Gnats::Command::FTYPINFO->new( @_ ); }

=head2 fvld

Manages the command for retrieving the set field validators defined in the
Gnats schema.

 $c = Net::Gnats::Command->fvld( field => 'MyField' );

See L<Net::Gnats::Command::FVLD> for details.

=cut

sub fvld         { shift; return Net::Gnats::Command::FVLD->new( @_ ); }

=head2 inputdefault

Manages the command for retrieving field default values.

 $c = Net::Gnats::Command->inputdefault( fields => 'MyField' );
 $c = Net::Gnats::Command->inputdefault( fields => [ 'Field1', 'Field2' ] );

See L<Net::Gnats::Command::INPUTDEFAULT> for details.

=cut

sub inputdefault { shift; return Net::Gnats::Command::INPUTDEFAULT->new( @_ ); }

=head2 list

Manages the command for different lists that can be retrieved from Gnats.

 $c = Net::Gnats::Command->list( subcommand => 'Categories' );
 $c = Net::Gnats::Command->list( subcommand => 'Submitters' );
 $c = Net::Gnats::Command->list( subcommand => 'Responsible' );
 $c = Net::Gnats::Command->list( subcommand => 'States' );
 $c = Net::Gnats::Command->list( subcommand => 'FieldNames' );
 $c = Net::Gnats::Command->list( subcommand => 'InitialInputFields' );
 $c = Net::Gnats::Command->list( subcommand => 'InitialRequiredFields' );
 $c = Net::Gnats::Command->list( subcommand => 'Databases' );

See L<Net::Gnats::Command::LIST> for details.

=cut

sub list         { shift; return Net::Gnats::Command::LIST->new( @_ ); }

=head2 lkdb

Manages the command for locking the gnats main database.

 $c = Net::Gnats::Command->lkdb;

See L<Net::Gnats::Command::LKDB> for details.

=cut

sub lkdb         { shift; return Net::Gnats::Command::LKDB->new( @_ ); }

=head2 lock_pr

Manages the command for locking a specific PR. Usually this occurs prior to
updating a PR through the edit command.

 $c = Net::Gnats::Command->lock_pr( pr => $pr, user => $user );
 $c = Net::Gnats::Command->lock_pr( pr => $pr, user => $user, pid => $pid );

See L<Net::Gnats::Command::LOCK> for details.

=cut

sub lock_pr      { shift; return Net::Gnats::Command::LOCK->new( @_ ); }

=head2 qfmt

Manages the command for setting the PR output format.  Net::Gnats parses 'full'
format only.  If you choose another format, you can retrieve the response via
$c->response->as_string.

 $c = Net::Gnats::Command->qfmt( format => 'full' );

See L<Net::Gnats::Command::QFMT> for details.

=cut

sub qfmt         { shift; return Net::Gnats::Command::QFMT->new( @_ ); }

=head2 quer

Manages the command for querying Gnats.  It assumes the expressions have
already been set.  If specific numbers are set, the command will query only
those PR numbers.

 $c = Net::Gnats::Command->quer;
 $c = Net::Gnats::Command->quer( pr_numbers => ['10'] );
 $c = Net::Gnats::Command->quer( pr_numbers => ['10', '12'] );

See L<Net::Gnats::Command::QUER> for details.

=cut

sub quer         { shift; return Net::Gnats::Command::QUER->new( @_ ); }

=head2 quit

Manages the command for disconnecting the current Gnats session.

 $c = Net::Gnats::Command->quit;

See L<Net::Gnats::Command::QUIT> for details.

=cut

sub quit         { shift; return Net::Gnats::Command::QUIT->new( @_ ); }

=head2 repl

Manages the command for replacing field contents.

 $c = Net::Gnats::Command->appn( pr_number => 5, field => $field );

See L<Net::Gnats::Command::REPL> for details.

=cut

sub repl         { shift; return Net::Gnats::Command::REPL->new( @_ ); }

=head2 rset

Manages the command for resetting the index and any query expressions on the
server.

 $c = Net::Gnats::Command->rset;

See L<Net::Gnats::Command::RSET> for details.

=cut

sub rset         { shift; return Net::Gnats::Command::RSET->new( @_ ); }

=head2 subm

Manages the command for submitting a new PR to Gnats.  If the named PR already
has a 'Number', a new PR with the same field contents will be created.

 $c = Net::Gnats::Command->subm( pr => $pr );

See L<Net::Gnats::Command::SUBM> for details.

=cut

sub subm         { shift; return Net::Gnats::Command::SUBM->new( @_ ); }

=head2 undb

Manages the command for unlocking the Gnats main database.

 $c = Net::Gnats::Command->undb;

See L<Net::Gnats::Command::UNDB> for details.

=cut

sub undb         { shift; return Net::Gnats::Command::UNDB->new( @_ ); }

=head2 unlk

Manages the command for unlocking a specific PR.

 $c = Net::Gnats::Command->unlk( pr_number => $pr->get_field('Number')->value );

See L<Net::Gnats::Command::UNLK> for details.

=cut

sub unlk         { shift; return Net::Gnats::Command::UNLK->new( @_ ); }

=head2 user

Manages the command for setting the security context for the session.

 $c = Net::Gnats::Command->user( username => $username, password => $password );

See L<Net::Gnats::Command::USER> for details.

=cut

sub user         { shift; return Net::Gnats::Command::USER->new( @_ ); }

=head2 vfld

Manages the command for validating a specific field. The field is a
L<Net::Gnats::FieldInstance> object.

 $c = Net::Gnats::Command->vfld( field => $field );
 $c = Net::Gnats::Command->vfld( field => $pr->get_field('Synopsis');

See L<Net::Gnats::Command::VFLD> for details.

=cut

sub vfld         { shift; return Net::Gnats::Command::VFLD->new( @_ ); }


1;

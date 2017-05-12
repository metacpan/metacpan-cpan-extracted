package POE::Component::LaDBI::Engine;

use v5.6.0;
use strict;
use warnings;

use Data::Dumper;

use DBI;

use POE::Component::LaDBI::Commands; # imports @COMMANDS
use POE::Component::LaDBI::Request;
use POE::Component::LaDBI::Response;

our $VERSION = '1.0';

# a little tricky to enforce consitancy with sibling modules
no strict 'refs';
our %COMMANDS = ( map { ( $_ => \&{lc($_)} ) } @COMMANDS );
use strict 'refs';

#our %COMMANDS =
#  (
#   CONNECT     	  => \&connect       ,
#   DISCONNECT  	  => \&disconnect    ,
#   PREPARE     	  => \&prepare       ,
#   FINISH      	  => \&finish        ,
#   EXECUTE     	  => \&execute       ,
#   ROWS        	  => \&rows          ,
#   FETCHROW    	  => \&fetchrow      ,
#   FETCHROW_HASH  => \&fetchrow_hash ,
#   FETCHALL    	  => \&fetchall      ,
#   FETCHALL_HASH  => \&fetchall_hash ,
#   PING        	  => \&ping          ,
#   DO          	  => \&do            ,
#   BEGIN_WORK     => \&begin_work    ,
#   COMMIT      	  => \&commit        ,
#   ROLLBACK    	  => \&rollback      ,
#   SELECTALL      => \&selectall     ,
#   SELECTALL_HASH => \&selectall_hash,
#   SELECTCOL      => \&selectcol     ,
#   SELECTROW      => \&selectrow     ,
#   QUOTE          => \&quote         ,
#  );


# Preloaded methods go here.
sub new {
  my $o = shift;
  my $class = ref($o) || $o;
  my $self = bless {}, $class;


  ### FIXME: need to merge the handle cache
  $self->{dbh} = {};
  $self->{dbh_id} = 'a';

  $self->{sth} = {};
  $self->{sth_id} = 'a';

  return $self;
} #end: new()


sub gen_dbh_id {
  my $self = shift;
  return 'dbh:'.$self->{dbh_id}++;
} #end: gen_dbh_id()


sub gen_sth_id {
  my $self = shift;
  return 'sth:'.$self->{sth_id}++;
} #end: gen_sth_id()


sub request :method {
  my $self = shift;
  my ($req) = @_;

  return $COMMANDS{ $req->cmd }->( $self, $req );
} #end: request()


sub connect :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  my $dbh;
  eval { $dbh = DBI->connect( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'   ,
       HandleId => undef      ,
       Id       => $req->id   ,
       DataType => 'EXCEPTION',
       Data     => $@
      );
    return $resp;
  }

  unless (defined $dbh) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED',
       HandleId => undef   ,
       Id       => $req->id,
       DataType => 'ERROR' ,
       Data     => {err => $DBI::err, errstr => $DBI::errstr}
      );
    return $resp;
  }

  my $dbh_id = $self->gen_dbh_id;
  $self->{dbh}->{$dbh_id} = $dbh;

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'    ,
     HandleId => $dbh_id ,
     Id       => $req->id
    );

  return $resp;
} #end: connect()


sub disconnect :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = delete $self->{dbh}->{ $req->handle_id };
  my $rc;
  eval { $rc = $dbh->disconnect; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rc) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $DBI::err, errstr => $DBI::errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id
    );

  return $resp;
} #end: disconnect()


sub prepare :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $sth;

  eval { $sth = $dbh->prepare( @{ $req->data } ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $sth) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR',
       Data     => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  my $sth_id = $self->gen_sth_id;
  $self->{sth}->{ $sth_id } = $sth;

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'   ,
     HandleId => $sth_id,
     Id       => $req->id
    );

  return $resp;
} #end: prepare()


sub finish :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $sth = delete $self->{sth}->{ $req->handle_id };
  my $rc;
  eval { $rc = $sth->finish; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rc) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id
    );

  return $resp;
} #end: finish()


sub execute :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  #data is optional for execute
  my $data = ref($req->data) eq 'ARRAY' ? $req->data : [];

  my $sth = $self->{sth}->{ $req->handle_id };
  my $rv;
  eval { $rv = $sth->execute( @$data ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rv) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RV'           ,
     Data => $rv
    );

  return $resp;
} #end: execute()


sub rows :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $sth = $self->{sth}->{ $req->handle_id };
  my $rv;
  eval { $rv = $sth->rows; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rv) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RV'           ,
     Data     => $rv
    );

  return $resp;
} #end: rows()


sub fetchrow :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $sth = $self->{sth}->{ $req->handle_id };
  my $row;
  eval { $row = $sth->fetchrow_arrayref; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $row) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data     => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'ROW'          ,
     Data     => $row
    );

  return $resp;
} #end: fetchrow()


sub fetchrow_hash :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  #data is optional for fetchrow_hashref
  my $data = ref($req->data) eq 'ARRAY' ? $req->data : [];

  my $sth = $self->{sth}->{ $req->handle_id };
  my $row_hash;
  eval { $row_hash = $sth->fetchrow_hashref(@$data); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $row_hash) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data     => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'NAMED_ROW'    ,
     Data     => $row_hash
    );

  return $resp;
} #end: fetchrow_hash()


sub fetchall :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $sth = $self->{sth}->{ $req->handle_id };
  my $table;
  eval { $table = $sth->fetchall_arrayref; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $table) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data     => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'TABLE'          ,
     Data     => $table
    );

  return $resp;
} #end: fetchall()


sub fetchall_hash :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{sth}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $sth = $self->{sth}->{ $req->handle_id };
  my $table;
  eval { $table = $sth->fetchall_hashref( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $table) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data     => {err => $sth->err, errstr => $sth->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'NAMED_TABLE'  ,
     Data     => $table
    );

  return $resp;
} #end: fetchall_hash()



sub ping :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $rv;
  eval { $rv = $dbh->ping; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rv) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RV'           ,
     Data     => $rv
    );

  return $resp;
} #end: ping()


sub do :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $rv;
  eval { $rv = $dbh->do( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rv) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RV'           ,
     Data     => $rv
    );

  return $resp;
} #end: do()


sub begin_work :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $rc;
  eval { $rc = $dbh->begin_work; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rc) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RC'           ,
     Data     => $rc
    );

  return $resp;
} #end: begin_work()


sub commit :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $rv;
  eval { $rv = $dbh->commit; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rv) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RV'           ,
     Data     => $rv
    );

  return $resp;
} #end: commit()


sub rollback :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $rv;
  eval { $rv = $dbh->rollback; };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $rv) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'RV'           ,
     Data     => $rv
    );

  return $resp;
} #end: rollback()


sub selectall :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $table;
  eval { $table = $dbh->selectall_arrayref( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $table) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'TABLE'        ,
     Data     => $table
    );

  return $resp;
} #end: selectall()



sub selectall_hash :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
	HandleId => $req->handle_id,
	Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $table;
  eval { $table = $dbh->selectall_hashref( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
	HandleId => $req->handle_id,
	Id       => $req->id       ,
	DataType => 'EXCEPTION'    ,
	Data     => $@
      );
    return $resp;
  }

  unless (defined $table) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
	HandleId => $req->handle_id,
	Id       => $req->id       ,
	DataType => 'ERROR'        ,
	Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'NAMED_TABLE'  ,
     Data     => $table
    );

  return $resp;
} #end: selectall_hash()



sub selectcol :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  ### FIXME: selectcol can be called on a dbh or sth
  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $column;
  eval { $column = $dbh->selectcol_arrayref( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $column) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'COLUMN'       ,
     Data     => $column
    );

  return $resp;
} #end: selectcol()


sub selectrow :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $row;
  eval { $row = $dbh->selectrow_arrayref( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $row) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'ROW'          ,
     Data     => $row
    );

  return $resp;
} #end: selectrow()



sub quote :method {
  my $self = shift;
  my ($req) = @_;
  my ($resp);

  unless (exists $self->{dbh}->{ $req->handle_id }) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'INVALID_HANDLE_ID',
       HandleId => $req->handle_id,
       Id       => $req->id
      );
    return $resp;
  }

  my $dbh = $self->{dbh}->{ $req->handle_id };
  my $sql;
  eval { $sql = $dbh->quote( @{$req->data} ); };
  if ($@) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'EXCEPTION'    ,
       Data     => $@
      );
    return $resp;
  }

  unless (defined $sql) {
    $resp = POE::Component::LaDBI::Response->new
      (Code     => 'FAILED'       ,
       HandleId => $req->handle_id,
       Id       => $req->id       ,
       DataType => 'ERROR'        ,
       Data => {err => $dbh->err, errstr => $dbh->errstr}
      );
    return $resp;
  }

  $resp = POE::Component::LaDBI::Response->new
    (Code     => 'OK'           ,
     HandleId => $req->handle_id,
     Id       => $req->id       ,
     DataType => 'SQL'          ,
     Data     => $sql
    );

  return $resp;
} #end: quote()


1;
__END__

=head1 NAME

POE::Component::LaDBI:Engine - Core DBI request servicing class.

=head1 SYNOPSIS

  use POE::Component::LaDBI::Engine;
  use POE::Component::LaDBI::Request;
  use POE::Component::LaDBI::Response;

  $eng = POE::Component::LaDBI::Engine->new();

  $resp = $eng->request( $req );

=head1 DESCRIPTION

This module is meant a an abstraction layer to the DBI API.

=over 4

=item C<POE::Component::LaDBI::Engine->new()>

Instantiates a C<POE::Component::LaDBI::Engine> object.

This function takes no arguments.

It must be called as a method C<POE::Component::LaDBI::Engine-E<gt>new()>.

The instatiated object maintains a cache of all DBI database and statement
handle objects which are currently active.

Each C<POE::Component::LaDBI::Engine> object is responsible for allocating
database and statement handle ids. These IDs are cookies that represent
DBI database and statement handle objects it has in the it's cache.
 '

=item C<$eng-E<gt>request()>

This function take only one arguemnt. It is a
C<POE::Component::LaDBI::Request> object. For most requests, the
C<POE::Component::LaDBI::Request> requires a valid handle id.

This funtion dispatches the command represented by the arguemnt.

The return value is always a C<POE::Component::LaDBI::Response> object.
For most responses, the returned C<POE::Component::LaDBI::Response> object
contains a valid handle id.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Sean Egan, E<lt>seanegan:bigfoot_comE<gt>

=head1 SEE ALSO

L<perl>, L<DBI>, L<POE::Component::LaDBI::Request>,
L<POE::Component::LaDBI::Response>.

=cut

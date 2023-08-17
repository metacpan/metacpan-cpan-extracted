package PApp::Config;

=head1 NAME

PApp::Config - load configuration settings and configure process

=head1 Functions

=over 4

=cut

use PApp::SQL;

use Compress::LZF qw(:compress :freeze);
BEGIN { Compress::LZF::set_serializer "PApp::Storable", "PApp::Storable::net_mstore", "PApp::Storable::mretrieve" }

$VERSION = 2.3;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw($DBH DBH $Database);

our %papp; # loaded applications
our %pimp; # loaded imports
our $DBH;

=item @paths = search_path [path...]

Return the standard search path and optionally add additional paths. (The
returned path entries might or might not include the arguments).

=back

=head1 Defined Keys in the C<%PApp::Config> Hash

The following configuration items are available in the C<%PApp::Config>
hash. Keys marked with a star (*) are access-restricted and can only be
accessed from processes having read-access to the config file in libdir.

=over 4

=item SECURE

A boolean indicating wether secure configuration values (marked with an
"*") are available (or not).

=item LIBDIR

The standard papp library directory.

=item I18NDIR

The directory where translation files are being stored (usually
"LIBDIR/i18n").

=item STATEDB

The DSN specification for papp's statedb (also used by poedit and
acedit). Usually something like 'DBI:mysql:papp'.

=item STATEDB_USER, STATEDB_PASS*

The username and password to access the state database.

=item CIPHERKEY*

The cipherkey to use to encrypt cookies.

=back

=cut

my $load = sub {
   local $@;
   do $_[0]
      or do {
         $@ ||= "$!";
         die "$_[0]: $@";
      }
};

%PApp::Config = (
   ETCDIR => "/etc/papp",
);

$PApp::Config{ETCDIR} = $ENV{PAPP_ETCDIR}
   if exists $ENV{PAPP_ETCDIR};

%PApp::Config = (%PApp::Config, %{ $load->("$PApp::Config{ETCDIR}/config") });

eval {
   %PApp::Config = (%PApp::Config, %{ $load->("$PApp::Config{ETCDIR}/secure") });
   $PApp::Config{SECURE} = 1;
};

our @incpath = $PApp::Config{LIBDIR};

sub search_path {
   push @incpath, @_;
   @incpath;
}

$PApp::statedb      = $PApp::Config{STATEDB};
$PApp::statedb_user = $PApp::Config{STATEDB_USER};
$PApp::statedb_pass = $PApp::Config{STATEDB_PASS};

# "inlined" into DBH
$Database = new PApp::SQL::Database "papp_1", $PApp::statedb, $PApp::statedb_user, $PApp::statedb_pass;

our %prepare_papp_dbh;

sub _prepare_DBH {
   my $dbh = shift;

   $PApp::st_fetchstate  = $dbh->prepare ("select count, state, userid, previd, sessid from event_count left join state on (id = ?)");
   $PApp::st_newstateids = $dbh->prepare ("update state_seq set seq = last_insert_id(seq) + ?");
   $PApp::st_insertstate = $dbh->prepare ("replace into state (id, state, userid, previd, sessid, alternative) values (?,?,?,?,?,?)");
   $PApp::st_eventcount  = $dbh->prepare ("select count from event_count");
   $PApp::st_reload_p    = $dbh->prepare ("select count(*) from state where previd = ? and alternative = ?");
   $PApp::st_newuserid   = $dbh->prepare ("update user_seq set seq = last_insert_id(seq) + 1");
   $PApp::st_replacepref = $dbh->prepare ("replace into prefs (uid, path, name, value) values (?,?,?,?)");
   $PApp::st_deletepref  = $dbh->prepare ("delete from prefs where uid = ? and path = ? and name = ?");

   $_->($dbh) for values %prepare_papp_dbh;
}

sub new_dbh {
   PApp::SQL::connect_cached ("papp_1", $PApp::statedb, $PApp::statedb_user, $PApp::statedb_pass, {
      AutoCommit => 1,
      RaiseError => 1,
      PrintError => 0,
   }, \&_prepare_DBH) or die "error connecting to papp database: $DBI::errstr";
}

sub DBH() {
   $DBH = new_dbh
}

DBH
   unless $PApp::Config::NO_AUTOCONNECT;

1;

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

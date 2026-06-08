######################################################################
#
# 03_form_db.pl - an HTML form backed by DB::Handy (the model layer)
#
# Run: perl -Ilib eg/03_form_db.pl
# Then open http://127.0.0.1:8080/ to list and add memos.
#
# Wiring: a DB::Handy connection handle is injected into PSGI::Handy
# via db => $dbh, then reached inside handlers with $c->db. Only GET and
# POST are used because HTTP::Handy serves those two methods.
#
# Demonstrates:
#   PSGI::Handy new(db=>...)/get/post/to_app, Context db/param/redirect,
#   DB::Handy connect/do/prepare/execute/fetchrow_hashref/disconnect
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;

use PSGI::Handy;
use HTTP::Handy;   # delivery layer (any PSGI server works)
use DB::Handy;

# --- model: a throwaway database under the system temp directory -----
my $DBDIR = File::Spec->catfile(File::Spec->tmpdir(), "psgi_eg03_$$");
mkdir($DBDIR, 0700) or die "Cannot mkdir $DBDIR: $!";

my $dbh = DB::Handy->connect($DBDIR, 'memo', { RaiseError => 0, PrintError => 0 });
die "DB connect failed
" unless $dbh;

$dbh->do(<<'SQL');
CREATE TABLE memo (
    id    INT,
    body  VARCHAR(200)
)
SQL

# --- application -----------------------------------------------------
my $app = PSGI::Handy->new(db => $dbh);

$app->get('/', sub {
    my $c = shift;
    my $sth = $c->db->prepare("SELECT id, body FROM memo ORDER BY id");
    $sth->execute();
    my $rows = '';
    my $row;
    while ($row = $sth->fetchrow_hashref()) {
        my $body = $row->{body};
        $body =~ s/[<>&]//g;
        $rows .= "<li>#$row->{id}: $body</li>\n";
    }
    $sth->finish;
    $rows = "<li><em>(no memos yet)</em></li>\n" if $rows eq '';
    return $c->html(
        "<!DOCTYPE html>\n<title>Memos</title>\n<h1>Memos</h1>\n"
      . "<ul>\n$rows</ul>\n"
      . "<form method=\"post\" action=\"/add\">\n"
      . "  <input name=\"body\" size=\"40\">\n"
      . "  <button type=\"submit\">Add</button>\n"
      . "</form>\n");
});

$app->post('/add', sub {
    my $c = shift;
    my $body = $c->param('body');
    $body = '' unless defined $body;
    $body =~ s/\A\s+//;
    $body =~ s/\s+\z//;
    if ($body ne '') {
        my $next = _next_id($c->db);
        my $ins  = $c->db->prepare("INSERT INTO memo (id, body) VALUES (?, ?)");
        $ins->execute($next, $body);
        $ins->finish;
    }
    return $c->redirect('/');
});

# Compute the next id (this demo has no AUTOINCREMENT column).
sub _next_id {
    my ($h) = @_;
    my $sth = $h->prepare("SELECT id FROM memo ORDER BY id");
    $sth->execute();
    my $max = 0;
    my $row;
    while ($row = $sth->fetchrow_hashref()) {
        $max = $row->{id} if $row->{id} > $max;
    }
    $sth->finish;
    return $max + 1;
}

# --- cleanup on exit -------------------------------------------------
END {
    $dbh->disconnect if $dbh;
    _rmtree($DBDIR) if defined $DBDIR && -d $DBDIR;
}

sub _rmtree {
    my ($dir) = @_;
    local *DH;
    opendir(DH, $dir) or return;
    my @e = grep { $_ ne '.' && $_ ne '..' } readdir(DH);
    closedir(DH);
    my $e;
    for $e (@e) {
        my $fp = File::Spec->catfile($dir, $e);
        if (-d $fp) { _rmtree($fp); }
        else        { unlink $fp; }
    }
    rmdir $dir;
}

my $psgi = $app->to_app;
HTTP::Handy->run(app => $psgi, host => '127.0.0.1', port => 8080);

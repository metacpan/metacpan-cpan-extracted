######################################################################
#
# 04_template_db.pl - the full three-layer stack in one file
#
# Server = HTTP::Handy, view = HP::Handy, model = DB::Handy, glued by
# PSGI::Handy. HP::Handy has render_string/render_file (not render), so
# it is injected through a CODE renderer that maps a template name to an
# in-memory source and calls render_string. $c->render then works as in
# any PSGI::Handy app.
#
# Run: perl -Ilib eg/04_template_db.pl
# Then open http://127.0.0.1:8080/ for a product report.
#
# Demonstrates:
#   PSGI::Handy new(renderer=>CODE, db=>...)/get/to_app, Context render/db,
#   HP::Handy render_string (for loop, filters), DB::Handy SELECT
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
use HP::Handy;
use DB::Handy;

# --- view: HP::Handy with an in-memory template registry -------------
my $TMPL = HP::Handy->new(auto_escape => 1);

my %VIEW = (
    'products.html' => <<'TMPL',
<!DOCTYPE html>
<title>{{ title }}</title>
<h1>{{ title }}</h1>
<table border="1" cellpadding="4">
  <tr><th>#</th><th>Name</th><th>Category</th><th>Price</th></tr>
{% for p in products %}
  <tr>
    <td>{{ loop.index }}</td>
    <td>{{ p.name }}</td>
    <td>{{ p.category }}</td>
    <td>{{ p.price }}</td>
  </tr>
{% endfor %}
</table>
<p>{{ products | length }} product(s).</p>
TMPL
);

# CODE renderer: ($template_name, \%vars) -> rendered string
my $RENDERER = sub {
    my ($name, $vars) = @_;
    my $src = $VIEW{$name};
    die "no such template: $name" unless defined $src;
    return $TMPL->render_string($src, $vars);
};

# --- model: a throwaway database, seeded once ------------------------
my $DBDIR = File::Spec->catfile(File::Spec->tmpdir(), "psgi_eg04_$$");
mkdir($DBDIR, 0700) or die "Cannot mkdir $DBDIR: $!";

my $dbh = DB::Handy->connect($DBDIR, 'shop', { RaiseError => 0, PrintError => 0 });
die "DB connect failed
" unless $dbh;

$dbh->do(<<'SQL');
CREATE TABLE product (
    id       INT,
    name     VARCHAR(40),
    category VARCHAR(20),
    price    INT
)
SQL

my $ins = $dbh->prepare(
    "INSERT INTO product (id, name, category, price) VALUES (?, ?, ?, ?)");
my @seed = (
    [ 1, 'Perl Cookbook',       'Book',   3500 ],
    [ 2, 'Learning Perl',       'Book',   2800 ],
    [ 3, 'USB Hub 4-port',      'Gadget',  980 ],
    [ 4, 'Mechanical Keyboard', 'Gadget', 8900 ],
);
my $r;
for $r (@seed) { $ins->execute(@$r); }
$ins->finish;

# --- application -----------------------------------------------------
my $app = PSGI::Handy->new(renderer => $RENDERER, db => $dbh);

$app->get('/', sub {
    my $c = shift;
    my $sth = $c->db->prepare(
        "SELECT name, category, price FROM product ORDER BY category, price");
    $sth->execute();
    my @products;
    my $row;
    while ($row = $sth->fetchrow_hashref()) {
        push @products, {
            name     => $row->{name},
            category => $row->{category},
            price    => $row->{price},
        };
    }
    $sth->finish;
    return $c->render('products.html', {
        title    => 'Product Report',
        products => \@products,
    });
});

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

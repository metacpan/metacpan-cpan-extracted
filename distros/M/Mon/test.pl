exit;
use Mon::Protocol;
use Data::Dumper;

$block= <<'EOF';
begin_block=UNKNOWN
begin=host1
var1=val1
var2=val2
end=host1
begin=host2
var1=fuck\0ayou\0avery\0amuch\0a\02\03\zz
var2=val2
end=host2
end_block=UNKNOWN
EOF

my $p = new Mon::Protocol;
$p->parse_data ($block);

print Dumper ($p), "\n";

exit;
use Mon::Protocol;

my $p = new Mon::Protocol;

$p->add_to_section ("host1", {
    "var1"	=> "val1",
    "var2"	=> "val2",
});

$p->add_to_section ("host2", {
    "var1"	=> "val1\nfuck\nyou\n",
    "var2"	=> "val2",
});

$a = $p->dump_data;

print "$a\n";
exit;

use Mon::Client;

my $c = new Mon::Client (
    host => "localhost",
);

die if (!defined $c);

$c->{"PROT"} = 9746;

$c->connect ("skip_protid" => 1);

if ($c->error ne "") {
    die "error: " . $c->error . "\n";
}

if ($c->connected)
{
	print "CONNECTED\n";
}
else
{
	print "NOT CONNECTED\n";
	print $c->error . "\n";
}

#my @s = $c->list_watch;

$c->disconnect;

exit;
use Mon::Client;

my $c = new Mon::Client (
    host => "localhost",
);

die if (!defined $c);

$c->connect;

if ($c->connected)
{
	print "CONNECTED\n";
}
else
{
	print "NOT CONNECTED\n";
	print $c->error . "\n";
}

my %op = $c->list_opstatus (["bd1", "ping"]);

foreach my $g (keys %op)
{
    foreach my $s (keys %{$op{$g}})
    {
	print "[$g] [$s]\n";
    	foreach my $v (keys %{$op{$g}->{$s}})
	{
	    print "     $v=[$op{$g}->{$s}->{$v}]\n";
	}
    }
}
$c->disconnect;

exit;
use Mon::Client;

my $c = new Mon::Client (
    host => "uplift",
);

die if (!defined $c);

if ($c->connected)
{
	print "CONNECTED\n";
}
else
{
	print "NOT CONNECTED\n";
}

if (!defined $c->connect)
{
    die "connect error: " . $c->error . "\n";
}

if ($c->connected)
{
	print "CONNECTED\n";
}
else
{
	print "NOT CONNECTED\n";
}

print $c->version, "\n";

my $v = $c->get ("router", "ping", "_timer");
if (!defined ($v))
{
    print STDERR "err getting\n";
}
else
{
    print "timer=$v\n";
}

my $v = $c->set ("router", "ping", "_fake_timer", "up it\n50");
if (!defined ($v))
{
    print STDERR "err setting\n";
}
else
{
    print "timer=$v\n";
}

my $v = $c->get ("router", "ping", "_fake_timer");
if (!defined ($v))
{
    print STDERR "err getting\n";
}
else
{
    print "timer=$v\n";
}


$c->disconnect;

exit;

my %op = $c->list_opstatus;

foreach my $g (keys %op)
{
    foreach my $s (keys %{$op{$g}})
    {
	print "[$g] [$s]\n";
    	foreach my $v (keys %{$op{$g}->{$s}})
	{
	    print "     $v=[$op{$g}->{$s}->{$v}]\n";
	}
    }
}

exit;


exit;
use Mon::Client;
use Data::Dumper;

my $n = new Mon::Client ( host => "localhost" );

die if (!defined $n);
$n->connect;

%a = $n->list_deps;

$n->disconnect;

print Dumper \%a, "\n";

exit;
use Mon::Client;
my $n = new Mon::Client ( host => "localhost" );
die if (!defined $n);
$n->connect;
@l = $n->list_alerthist;
$n->disconnect;

for my $line (sort {$a->{"time"} <=> $b->{"time"}} (@l)) {
    print "$line->{group} $line->{service} $line->{time}\n";
}

exit;
use Mon::Client;

$c = new Mon::Client (
    host => "localhost",
    port => 2583
);

die if (!defined $c);

$c->connect;

die "connect: " . $c->error . "\n" if ($c->error ne "");

%o = $c->list_opstatus;

die "list_opstatus: " . $c->error . "\n" if ($c->error ne "");

$c->quit;

foreach $g (keys %o) {
    foreach $s (keys %{$o{$g}}) {
    	foreach $v (keys %{$o{$g}->{$s}}) {
		print "[$g] [$s] [$v] = [$o{$g}->{$s}->{$v}]\n";
	}
    }
}

__END__
#
# $Id: test.pl 1.1 Mon, 21 Aug 2000 08:30:45 -0700 trockij $
#

use Mon::Client;

$a = new Mon::Client (
	host => "uplift",
);

if (!defined $a->connect) {
    die "could not connect: " . $a->error . "\n";
} else {
    print "connected\n";
}

if ((%o = $a->list_opstatus) == 0) {
    die "could not get optstatus: " . $a->error . "\n";
} else {
    print "got opstatus\n";
}

#$a->username ("mon");
#$a->password ("supermon");
#if (!defined ($a->login)) {
#    die "could not log in: " . $a->error . "\n";
#} else {
#    print "logged in\n";
#}

#if (!defined $a->stop) {
#    die "could not stop: " . $a->error . "\n";
#}

#if (!defined $a->start) {
#    die "could not start: " . $a->error . "\n";
#} else {
#    print "started scheduler\n";
#}

#if (!defined (%o = $a->list_failures)) {
#    die "could not get failures: " . $a->error . "\n";
#}

%d = $a->list_disabled();
if ($a->error) {
    die "could not get disabled: " . $a->error . "\n";
}

#if (!defined (@group = $a->list_group ("software"))) {
#    die "could not list group: " . $a->error . "\n";
#}


#if (!defined ($a->enable_host ("pgupta-dsl"))) {
#    die "could not enable host: " . $a->error . "\n";
#}

#if (!defined (($server, @pids) = $a->list_pids)) {
#    die "could not get failures: " . $a->error . "\n";
#}

if (!defined $a->disconnect) {
    die "could not disconnect: " . $a->error . "\n";
} else {
    print "disconnected\n";
}


&show_disabled;
&show_opstatus;

exit 0;




sub show_disabled {
    print "HOSTS\n";
    foreach $g (keys %{$d{hosts}}) {
	foreach $h (keys %{$d{hosts}{$g}}) {
	    print "group $g [$h]\n";
	}
    }

    print "SERVICES\n";
    foreach $g (keys %{$d{services}}) {
	foreach $s (keys %{$d{services}{$g}}) {
	    print "[$g] [$s]\n";
	}
    }

    print "WATCHES\n";
    foreach $g (keys %{$d{watches}}) {
	print "[$g]\n";
    }
}

sub show_opstatus {
    my ($g, $s, $k);

    print "OPSTATUS\n";
    foreach $g (keys %o) {
    	foreach $s (keys %{$o{$g}}) {
	    foreach $k (keys %{$o{$g}{$s}}) {
	    	print "[$g] [$s] [$k] [$o{$g}{$s}{$k}]\n";
	    }
	}
    }
}

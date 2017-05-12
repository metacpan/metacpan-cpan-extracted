use strict;
package ObjStore::AppInstance;
use Carp;
use ObjStore;
require ObjStore::HV::Database;
use vars qw($VERSION);
$VERSION = '1.01';

sub new {
    my ($class, $app, $skey) = @_;
    croak "$class->new($app, session_key): session key missing"
	if !$skey;

    if ($app !~ m'/') {
	my $dbdir = $ENV{"\U${app}_DBDIR"};
	if (!$dbdir) {
	    $dbdir = $ObjStore::Config::TMP_DBDIR;
	}
	$app = "$dbdir/$app";
    }
    my $wdb = ObjStore::HV::Database->new($app, 'update', 0666);

    bless { 'wdb' => $wdb, 'skey' => $skey }, $class;
}

sub get_pathname {
    shift->{wdb}->get_pathname();
}

sub now {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime;
    $mon++; $year+=1900;
    sprintf("%4d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min);
}

sub top {
    # fold back into ObjStore::HV?  'partition'?
    my ($o) = @_;
    if ($o->{'ref'}) {
	my $r = $o->{'ref'};
	# deleted? XXX
	return $r->focus();
    }
    my $h = $o->{wdb}->hash;
    my $skey = $o->{'skey'};
    if (! $h->{$skey}) {
	my $s = $o->{wdb}->create_segment($skey);
	my $i = ObjStore::HV->new($s, 30);
	$i->{SELF} = $i;
	$i->{ctime} = &now;
	$h->{ $skey } = $i->new_ref($h, 'hard');
    }
    $o->{'ref'} = $h->{ $skey }->focus()->new_ref('transient','hard');
    my $top = $o->{'ref'}->focus();
    $top;
}

sub global {
    my ($o) = @_;
    if ($o->{'gref'}) {
	my $r = $o->{'gref'};
	return $r->focus();
    }
    my $gl = $o->{wdb}->root('global');
    if (!$gl) {
	my $s = $o->{wdb}->create_segment('GLOBAL');
	$gl = $o->{wdb}->root('global', ObjStore::HV->new($s, 30));
    }
    $o->{'gref'} = $gl->new_ref('transient','hard');
    $gl;
}

sub modified {
    my ($o) = @_;
    my $t = $o->top;
    $t->{mtime} = &now;
}

sub prune {
    my ($o, $oldest) = @_;
    # delete stuff older than $oldest XXX
}

1;

=head1 NAME

  ObjStore::AppInstance - helper class for interactive tools

=head1 SYNOPSIS

  use ObjStore::AppInstance;

  my $app = ObjStore::AppInstance->new('posh', scalar(getpwuid($>)));

  my $hash = $app->top();   # fetch the top level hash for this key

  $app->modified();         # set the modification time

  $app->prune($oldest);     # delete instances older than $oldest

=head1 DESCRIPTION

I'm not sure if this will be depreciated...

=cut

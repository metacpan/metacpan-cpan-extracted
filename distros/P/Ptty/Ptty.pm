package Ptty;
require DynaLoader;
@Ptty::ISA = qw(DynaLoader);

use Carp;

use Tk::Pretty;

bootstrap Ptty;

sub gensym 
{
 my ($what) = @_;
 local *{"Ptty::$what"};
 \delete $Ptty::{$what};
}

sub new
{
 my ($class) = @_;
 my $tty;
 my $fd = OpenPTY($tty);
 my $master = gensym($tty.'_master');
 my $slave  = gensym($tty);
 open($master,"+>&$fd") || croak "Cannot open $master as $fd:$!";
 my $what = select($master);
 $| = 1;
 select($what);
 return bless {master => $master, slave => $slave, tty => $tty},$class;
}

sub master
{
 my ($obj) = @_;
 return $obj->{'master'};
}

sub slave
{
 my ($obj) = @_;
 my $slave = $obj->{'slave'};
 my $tty   = $obj->{'tty'};
 open($slave,"+>$tty") || croak "Cannot open $slave as $tty:$!";
 InitSlave($slave,$tty);
 my $code = system("stty sane >&".fileno($slave)." <&1");
 print STDERR "stty code=$code\n" if ($code); 
 my $what = select($slave);
 $| = 1;
 select($what);
 return $slave;
}



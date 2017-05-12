#!/usr/local/bin/perl
# Sample script for PogoLink
# 2000 Sey Nakajima <sey@jkc.co.jp>
use Person;
use Pogo;
use strict vars;
use vars qw(@Cmds0 @Cmds1 @Cmds2 $AUTOLOAD);

@Cmds0 = qw(add_man add_woman list help);
@Cmds1 = qw(show);
@Cmds2 = qw(
    add_child del_child add_father del_father add_mother del_mother
    add_friend del_friend add_hus del_hus add_wife del_wife
);

main(@ARGV);

sub main {
	my($arg) = @_;

	my $pogo = new Pogo 'sample.cfg';
	my $root = $pogo->root_tie;
	if( $arg eq 'new' ) {
		$root->{PERSONS} = new Pogo::Btree;
	} else {
		$root->{PERSONS} = new Pogo::Btree unless exists $root->{PERSONS};
	}
	my $persons = $root->{PERSONS};

	print "type 'help' for help, 'exit' for exit\n";
	while(1) {
		print ">";
		my $line = <STDIN>;
		my($func, @args) = split(/\s+/,$line);
		last if $func eq 'exit';
		if( grep($func eq $_, @Cmds0) ) {
			unshift @args, $root, $persons;
		} else {
			@args = map $persons->{$_}, @args;
			print("no such name\n"),next if grep !$_, @args;
		}
		eval { &$func(@args); };
		print $@ if $@;
	}
}

sub help {
	print <<END;
command as follows:
  exit           : exit this script
  list           : show all persons name list
  show NAME      : show attributes of NAME person
  add_man NAME   : add a man who has NAME
  add_woman NAME : add a woman who has NAME
  
  add_child NAME1 NAME2 : NAME2 person becomes NAME1 person's child
  
  below commands are same as add_child
    add_child del_child add_father del_father add_mother del_mother
    add_friend del_friend add_hus del_hus add_wife del_wife
END
}

sub list {
	my($root, $persons) = @_;
	my @name = keys %{$persons};
	print "@name\n" if @name;
}
sub add_man {
	my($root, $persons, $name) = @_;
	return if exists $persons->{$name};
	$persons->{$name} = new Man $root, $name;
}
sub add_woman {
	my($root, $persons, $name) = @_;
	return if exists $persons->{$name};
	$persons->{$name} = new Woman $root, $name;
}
sub AUTOLOAD {
	my($person1, $person2) = @_;
	my $func = $AUTOLOAD;
	$func =~ s/.*:://;
	if( grep($func eq $_, @Cmds1) && $person1 ) {
		$person1->$func();
	} elsif( grep($func eq $_, @Cmds2) && $person1 && $person2 ) {
		$person1->$func($person2);
	} else {
		print "no such command\n";
	}
}


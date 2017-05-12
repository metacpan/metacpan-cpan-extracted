#!/usr/bin/perl -w

package Solaris::Modinfo;

use strict;

require Exporter;
require DynaLoader;

use vars qw(@ISA $VERSION);

@ISA = qw(Exporter DynaLoader);

$VERSION = 0.1;

sub new {
	my($proto, @modinfo) = shift;
	my $class = ref($proto) || $proto;
	my $self  = { };

	@modinfo  = qx(modinfo);
	$self->{_private}{numModule} = 0;

	for (@modinfo) {
		chomp;
		s#^\s+##;

		next if ($_ =~ /^Id/g);
		my(@line) = split(/\s+/, $_);

		my $id = $self->{_private}{numModule};

		foreach my $info ("Id", "Loadaddr", "Size", "Info", "Rev") {
			$self->{_modinfo}{$id}{$info} = shift(@line);
		}

		$self->{_modinfo}{$id}{ModuleName} = join(" ", @line);
		$self->{_private}{numModule}++;
	}
	bless $self, $class;
	
	return $self;
}

sub listModule {
	my($self)= @_;

	return $self->{_modinfo};
}

sub countModule {
	my($self)= @_;

	return $self->{_private}{numModule};
}

sub showModule {
	my($self) = @_;
	my(@mod_t);

	for (sort { $a <=> $b } keys %{ $self->{_modinfo} }) {
        	push(@mod_t, $self->{_modinfo}{$_}{Id}, $self->{_modinfo}{$_}{Loadaddr}, 
                	$self->{_modinfo}{$_}{Size}, $self->{_modinfo}{$_}{Info}, 
                	$self->{_modinfo}{$_}{Rev}, $self->{_modinfo}{$_}{ModuleName});
		write;
		undef @mod_t;
	}

	format STDOUT =
@<<<<<@<<<<<<<<<<<@<<<<<<<@<<<<@<<<<@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$mod_t[0], $mod_t[1], $mod_t[2], $mod_t[3], $mod_t[4], $mod_t[5]
.

}

1;

=head1 NAME 

Solaris::Modinfo - Perl module providing object oriented interface to modinfo (display information about Solaris loaded kernel modules)

=head1 SYNOPSIS

	use Solaris::Modinfo;

	my $module  = Solaris::Modinfo->new();
	my $modinfo = $module->listModule();

	print "Number of modules : ", $module->countModule(), "\n";

	map {
        	print $modinfo->{$_}{Id}, "  ",
                	$modinfo->{$_}{Loadaddr}, "  ",
                	$modinfo->{$_}{Size}, "  ",
                	$modinfo->{$_}{Info}, "  ",
                	$modinfo->{$_}{Rev}, "  ",
                	$modinfo->{$_}{ModuleName}, "\n";
	}(keys %{ $modinfo });

=head1 DESCRIPTION

This module provides an object oriented interface to the module informations. The implementation attempts to display informations about Solaris loaded kernel modules.

=head2 METHODS

=item listModule

Provide a reference to a hash of the modinfo parameters.

=item countModule 

Display the number of kernel module loaded.

=item showModule

Display the information of kernel module loaded.

=head1 AUTHOR

Stephane Chmielewski 	<snck@free.fr>

=head1 COPYRIGHT

Copyright (C) 2006 Stephane Chmielewski. All rights reserved. 
This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself. 

=cut


package PRANG::Util;
$PRANG::Util::VERSION = '0.21';
use strict;
use warnings;

use Sub::Exporter -setup =>
	{ exports => [qw(types_of)] };

use Set::Object qw(set);

# 12:20 <@mugwump> is there a 'Class::MOP::Class::subclasses' for roles?
# 12:20 <@mugwump> I want a list of classes that implement a role
# 12:37 <@autarch> mugwump: I'd kind of like to see that in core
sub types_of {
	my @types = @_;

	# resolve type names to meta-objects;
	for (@types) {
		if ( !ref $_ ) {
			$_ = $_->meta;
		}
	}
	my $known = set(@types);
	my @roles = grep { $_->isa("Moose::Meta::Role") } @types;

	if (@roles) {
		$known->remove(@roles);
		for my $mc (Class::MOP::get_all_metaclass_instances) {
			next if !$mc->isa("Moose::Meta::Class");
			next if $known->includes($mc);
			if ( grep { $mc->does_role($_->name) } @roles ) {
				$known->insert($mc);
			}
		}
	}
	for my $class ( $known->members ) {
		my @subclasses = map { $_->meta } $class->subclasses;
		$known->insert(@subclasses);
	}
	$known->members;
}

1;

# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>

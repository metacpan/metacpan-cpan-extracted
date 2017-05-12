# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Netlist::Net;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Net);
$VERSION = '1.344';
use strict;

######################################################################
# Accessors

sub netlist {
    return $_[0]->module->netlist;
}

sub cast_type {
    my $self = shift;
    my $typeref = $self->netlist->find_class($self->data_type);
    return $typeref && $typeref->cast_type;
}

sub sc_type {
    my $self = shift;
    my $typeref = $self->netlist->find_class($self->data_type);
    return $typeref && $typeref->sc_type;
}

sub sc_type_from_verilog {
    my $self = shift;
    return ((!$self->width || $self->width == 1)
	    ? 'bool'
	    : "sp_ui<".$self->msb.",".$self->lsb.">");
}

sub is_sc_bv {
    my $self = shift;
    my $typeref = $self->netlist->find_class($self->data_type);
    return $typeref && $typeref->is_sc_bv;
}

sub inherited {
    $_[0]->attributes("_sp_inherited", $_[1]) if exists $_[1];
    return $_[0]->attributes("_sp_inherited")||0;
}

sub _decl_order {
    $_[0]->attributes("_sp_decl_order", $_[1]) if exists $_[1];
    return $_[0]->attributes("_sp_decl_order")||0;
}

######################################################################
# Methods

sub _link {
    my $self = shift;
    # If there is no msb defined, try to pull it based on the type of the signal
    if (!defined $self->msb && defined $self->data_type) {
	my $typeref = $self->netlist->find_class($self->data_type);
	if (defined $typeref) {
	    $self->msb($typeref->msb);
	    $self->lsb($typeref->lsb);
	    $self->stored_lsb($typeref->stored_lsb);
	}
    }
    $self->SUPER::_link();
    return $self;
}

sub lint {
    my $self = shift;
    $self->SUPER::lint();
    # We peek into simple sequential logic to see what symbols are referenced
    if ($self->module->attributes("autotieoff")) {
	$self->_used_out_inc(1);
    }
    if (!$self->module->lesswarn
	&& (($self->_used_in() && !$self->_used_out())
	    || ($self->module->attributes('check_inputs_used')
		&& $self->_used_out() && !$self->_used_in()))
	&& !$self->_used_inout()
	&& !$self->array
	&& !defined $self->module->_code_symbols->{$self->name}
	&& $self->netlist->{lint_checking}
	) {
	if ($self->_used_in()) {
	    $self->warn("Signal has no drivers: ",$self->name(), "\n");
	} else {
	    $self->warn("Signal has no sinks: ",$self->name(), "\n");
	}
	$self->dump_drivers(8);
	my @noautoinst;
	foreach my $cellref ($self->module->cells_sorted) {
	    push @noautoinst, $cellref->name if !$cellref->_autoinst();
	}
	if ($#noautoinst>-1) {
	    print "        Note: No AUTOINST's for: ",join(", ",@noautoinst),"\n";
	}
	$self->module->dump() if $Verilog::Netlist::Debug;
    }
}

sub _scdecls {
    my $self = shift;
    my $type = $self->_decls;
    $type ||= "wire";
    return $type;
}

sub verilog_text {
    my $self = shift;
    my @out;
    foreach my $decl ($self->_scdecls) {
	push @out, $decl;
	my $vec = ((defined $self->msb && !($self->msb==0 && $self->lsb==0))
		   ? " [".$self->msb.":".$self->lsb."]"
		   : "");
	push @out, sprintf("%-8s", $vec);
	push @out, " ".$self->name;
	push @out, " ".$self->array if $self->array;
	push @out, ";";
    }
    return (wantarray ? @out : join('',@out));
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Net - Net for a SystemC Module

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Net, derived for a SystemC netlist
pin.

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.org/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/systemperl>.

Copyright 2001-2014 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Net>
L<SystemC::Netlist>
L<Verilog::Netlist>

=cut

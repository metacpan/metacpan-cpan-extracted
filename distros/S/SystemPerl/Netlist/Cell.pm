# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Netlist::Cell;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Cell);
$VERSION = '1.344';
use strict;

######################################################################

sub new_pin {
    my $self = shift;
    # @_ params
    # Create a new pin under this cell
    my $pinref = new SystemC::Netlist::Pin (cell=>$self, @_);
    $self->portname($self->name) if !$self->name;	# Back Version 1.000 compatibility
    $self->_pins ($pinref->name(), $pinref);
    return $pinref;
}

######################################################################
#### Automatics (Preprocessing)

sub _d { defined $_[0] ? $_[0] : "" }

sub _autos_connect_port {
    my $self = shift;
    my $portref = shift;

    my $netname = $portref->name;
    my $typename = $portref->iotype;
    # Search for a template for this
    my $cellname = $self->name;
    my $comment;
    foreach my $templref (@{$self->module->_pintemplates}) {
	my $cellre = $templref->cellre;
	if ($cellname =~ /$cellre/) {
	    my $pinre = $templref->pinre;
	    if ($netname =~ /$pinre/) {
		my $typere = $templref->typere;
		if ($typename =~ /$typere/) {
		    my $cellpin_regexp = ("^".$templref->cellregexp
					  ."####".$templref->pinregexp
					  ."####".$templref->typeregexp
					  .'$');
		    my $cellpin = $cellname."####".$netname."####".$typename;
		    my $replace = $templref->netregexp;
		    # You can't use s/$compile/$compile/ directly.  We could make a eval{}, but
		    # we'll do it the way some C code might eventually have to...
		    if ($cellpin =~ m/$cellpin_regexp/) {
			my $a=_d($1); my $b=_d($2); my $c=_d($3); my $d=_d($4); my $e=_d($5);
			my $f=_d($6); my $g=_d($7); my $h=_d($8); my $i=_d($9);
			($replace !~ /\$1[0-9]/) or $self->error("AUTO_TEMPLATE only supports up to \$9, Replace='$replace'\n");
			$replace =~ s/\$\{1\}/$a/g; $replace =~ s/\$\{2\}/$b/g;  $replace =~ s/\$\{3\}/$c/g; $replace =~ s/\$\{4\}/$d/g;
			$replace =~ s/\$\{5\}/$e/g; $replace =~ s/\$\{6\}/$f/g;  $replace =~ s/\$\{7\}/$g/g; $replace =~ s/\$\{8\}/$h/g;
			$replace =~ s/\$\{9\}/$i/g;
			$replace =~ s/\$1/$a/g; $replace =~ s/\$2/$b/g;  $replace =~ s/\$3/$c/g; $replace =~ s/\$4/$d/g;
			$replace =~ s/\$5/$e/g; $replace =~ s/\$6/$f/g;  $replace =~ s/\$7/$g/g; $replace =~ s/\$8/$h/g;
			$replace =~ s/\$9/$i/g;
			$netname = $replace;
			$comment = "Templated on ".$templref->filename.":".$templref->lineno;
			print " SP_TEMPLATE replaced (cell=$cellname,net=$netname,type=$typename) with $netname\n" if $SystemC::Netlist::Debug;
		    } else {
			$self->error("Bad regexp in expanding AUTO_TEMPLATE, Cellpin='$cellpin_regexp', Cellpin='$cellpin', Replace='$replace'\n");
		    }
		}
	    }
	}
    }

    print "  AUTOINST connect ",$self->module->name,"."
	,$self->name," (",$self->submod->name,") port ",$portref->name
	," to ",$netname,"\n" if $SystemC::Netlist::Debug;
    $self->new_pin (name=>$portref->name, portname=>$portref->name,
		    filename=>'AUTOINST('.$self->module->name.')', lineno=>$self->lineno,
		    netname=>$netname, sp_autocreated=>($comment||1),)
	->_link();
}

sub _autos {
    my $self = shift;
    if ($self->_autoinst) {
	if ($self->submod()) {
	    my %conn_ports = ();
	    foreach my $pinref ($self->pins) {
		$conn_ports{$pinref->name} = 1;
	    }
	    foreach my $portref ($self->submod->ports) {
		if (!$conn_ports{$portref->name}) {
		    $self->_autos_connect_port($portref);
		}
	    }
	}
    }
    foreach my $pinref ($self->pins) {
	$pinref->_autos();
    }
}

sub _write_autoinst {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic instantiation pins\n");
    foreach my $pinref ($self->pins_sorted) {
	if ($pinref->sp_autocreated) {
	    $fileref->printf ("%sSP_PIN(%s, %-20s %-20s // %s%s\n"
			      ,$prefix,$self->name,$pinref->name.",",$pinref->netname.");"
			      ,$pinref->port->direction
			      ,(($pinref->sp_autocreated ne '1')?" ".$pinref->sp_autocreated:"")
			      );
	}
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic instantiation pins\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Cell - Cell for a SystemC Module

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Cell, derived for a SystemC netlist
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

L<Verilog::Netlist::Cell>
L<SystemC::Netlist>
L<Verilog::Netlist>

=cut

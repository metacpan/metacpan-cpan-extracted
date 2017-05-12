# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Netlist::Class;
use Class::Struct;
use Carp;

use SystemC::Netlist;
use SystemC::Netlist::Net;
use SystemC::Template;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Class::Struct
	  Verilog::Netlist::Subclass);
$VERSION = '1.344';
use strict;

structs('new',
	'SystemC::Netlist::Class::Struct'
	=>[name     	=> '$', #'	# Name of the module
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   msb	 	=> '$', #'	# MSB bit #
	   lsb		=> '$', #'	# LSB bit #
	   stored_lsb	=> '$', #'	# Bit number of signal stored in bit 0  (generally lsb)
	   cast_type	=> '$', #'	# What to cast to for tracing
	   convert_type	=> '$', #'	# What to output if transforming sp_ui's
	   is_enum	=> '$', #'	# Maps to enum type
	   netlist	=> '$', #'	# Netlist is a member of
	   userdata	=> '%',		# User information
	   #
	   # For special procedures
	   _nets	=> '%',		# List of nets if this is tracable
	   ]);

######################################################################
# List of basic C++ types and their sizes

our %GenerateInfo
    = (bool=>		[ msb=>0,  lsb=>0, cast_type=>undef, ],
       sc_clock=>	[ msb=>0,  lsb=>0, cast_type=>'bool', ],
       int8_t=>		[ msb=>7,  lsb=>0, cast_type=>undef, ],
       int16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       int32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       int64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
#      int =>		[ msb=>31, lsb=>0, cast_type=>undef, ],
       uint8_t=>	[ msb=>7,  lsb=>0, cast_type=>undef, ],
       uint16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       uint32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       uint64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
#      uint =>		[ msb=>0,  lsb=>0, cast_type=>undef, ],
       nint8_t=> 	[ msb=>7,  lsb=>0, cast_type=>undef, ],
       nint16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       nint32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       nint64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
       vluint8_t=>	[ msb=>7,  lsb=>0, cast_type=>undef, ],
       vluint16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       vluint32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       vluint64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
       vlsint8_t=>	[ msb=>7,  lsb=>0, cast_type=>undef, ],
       vlsint16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       vlsint32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       vlsint64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
       );

######################################################################
######################################################################
#### Netlist construction

sub generate_class {
    my $netlist = shift;
    my $name = shift;
    # We didn't find a class already declared of the specified type.
    # See if it matches a C++ standard type, and if so, add it.
    if ($GenerateInfo{$name}) {
	return $netlist->new_class(name=>$name,
				   @{$GenerateInfo{$name}});
    }
    elsif ($name =~ /^sc_bv<(\d+)>$/) {
	return $netlist->new_class(name=>$name,
				   msb=>($1-1), lsb=>0, cast_type=>undef);
    }
    elsif ($name =~ /^sp_ui<(-?\d+),(-?\d+)>$/) {
	my $msb = $1;  my $lsb = $2;
	# sp_ui<10,1> means we store bits 10:0,
	# and trace 10:0 (as VCD format doesn't allow otherwise)
	my $stored_lsb = ($lsb<0 ? $lsb : 0);
	my $size = $msb-$stored_lsb+1;
	my $out = ((($size==1) && "bool")
		   || (($size<=32) && "uint32_t")
		   || (($size<=64) && "uint64_t")
		   || "sc_bv<".$size.">");
	return $netlist->new_class(name=>$name, convert_type=>$out,
				   msb=>$msb, lsb=>$lsb,
				   stored_lsb=>$stored_lsb,
				   cast_type=>undef);
    }
    elsif ($netlist->{_enum_classes}{$name}) {
	return $netlist->new_class(name=>$name, is_enum=>1,
				   msb=>31, lsb=>0, cast_type=>'uint32_t');
    }
    return undef;
}

######################################################################
######################################################################
#### Accessors

sub logger { return $_[0]->netlist->logger; }

sub sc_type { return $_[0]->convert_type || $_[0]->name; }

sub is_sc_bv {
    my $self = shift;
    return ($self->sc_type =~ /^sc_bv/);
}

######################################################################
######################################################################
#### Nets

# Constructors
sub new_net {
    my $self = shift;
    # @_ params
    # Create a new net under this module
    my $netref = new SystemC::Netlist::Net (direction=>'net', array=>'', @_, module=>$self, );
    $self->_nets ($netref->name(), $netref);
    return $netref;
}

######################################################################
#### Nets
# These are compatible with Module's methods so the reader doesn't need to know
# if it is adding to a module or a class

sub find_net {
    my $self = shift;
    my $search = shift;
    return $self->_nets->{$search};
}

sub _decl_order {}
sub _decl_max { return 1;}

sub nets {
    return (values %{$_[0]->_nets});
}
sub nets_sorted {
    return (sort {$a->name() cmp $b->name()} (values %{$_[0]->_nets}));
}

######################################################################
#### Linking

sub _link {
    my $self = shift;
    foreach my $netref ($self->nets) {
	$netref->_link();
    }
}

######################################################################
#### Debug

sub dump {
    my $self = shift;
    my $indent = shift||0;
    my $norecurse = shift;
    print " "x$indent,"Class:",$self->name(),"  File:",$self->filename(),"\n";
    if (!$norecurse) {
	foreach my $netref ($self->nets_sorted) {
	    $netref->dump($indent+2);
	}
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Class - Class (type) information

=head1 DESCRIPTION

SystemC::Netlist::Class contains type information.  It is called from
SystemC::Netlist.

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

L<SystemC::Netlist>

=cut

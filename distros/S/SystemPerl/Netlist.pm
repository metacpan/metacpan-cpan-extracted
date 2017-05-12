# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Netlist;
use Carp;
use IO::File;

use Verilog::Netlist;
use SystemC::Netlist::Class;
use SystemC::Netlist::Module;
use SystemC::Netlist::File;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist);
use strict;
use vars qw($Debug $Verbose $VERSION);

$VERSION = '1.344';

######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = $class->SUPER::new
	(sp_allow_output_tracing => undef,	# undef = set it automatically
	 sp_trace_duplicates => 0,
	 sp_netlist => 1,  # General flag for future feature tests
	 sc_version => undef,
	 ncsc => undef,
	 lint_checking => 1,
	 remove_defines_without_tick => 1,
	 _enum_classes => {},
	 _enums => {},
	 _classes => {},
	 @_);
    bless $self, $class;
    $self->_set_features();
    return $self;
}

######################################################################
#### Error Handling

# Netlist file & line numbers don't apply
sub filename { return 'SystemC::Netlist'; }
sub lineno { return ''; }

sub new_logger {
    # Undocumented, as only for backward compatibility before Verilog-Perl 3.041
    if ($::Verilog::Netlist::Logger::{new}) {  # Function exists
	return Verilog::Netlist::Logger->new(@_);
    } else {
	return undef;
    }
}

######################################################################
#### Utilities

sub tracing {
    my $self = shift;
    return !$self->{ncsc};
}

sub sc_version {
    my $self = shift;
    # Return version of SystemC in use
    if (!$self->{sc_version} && $ENV{SYSTEMC}) {
	my $fh;
	my $inc = $ENV{SYSTEMC_INCLUDE} || $ENV{SYSTEMC}."/include";
	foreach my $fn ("$inc/sysc/kernel/sc_ver.h",
			"$inc/systemc/kernel/sc_ver.h",
			"$inc/sc_ver.h") {
	    $fh = IO::File->new("<$fn");
	    last if $fh;
	}
	if ($fh) {
	    while (defined (my $line = $fh->getline)) {
		if ($line =~ /^\s*#\s*define\s+SYSTEMC_VERSION\s+(\S+)/) {
		    $self->{sc_version} = $1;
		    print "SC_VERSION = $1\n" if $Debug;
		    last;
		}
	    }
	}
    }
    return $self->{sc_version};
}

sub sc_numeric_version {
    my $self = shift;
    # Return version of SystemC in use
    if (!exists $self->{sc_numeric_version}) {
	my $scv = $self->sc_version;
	if (!$scv) { # Indeterminate
	    $self->{sc_numeric_version} = undef;
	} elsif ($scv > 20110000) {  # 2.3.0
	    $self->{sc_numeric_version} = 2.300;
	} elsif ($scv > 20070000) {  # 2.2.0
	    $self->{sc_numeric_version} = 2.200;
	} elsif ($scv > 20050700) {  # 2.1.v1
	    $self->{sc_numeric_version} = 2.110;
	} elsif ($scv > 20041000) {  # 2.1.oct_12_2004.beta
	    $self->{sc_numeric_version} = 2.100;
	} elsif ($scv > 20011000) {
	    $self->{sc_numeric_version} = 2.010;
	} elsif ($scv > 20010100) {
	    $self->{sc_numeric_version} = 1.211;
	} else {
	    warn "%Warning: SystemC Version isn't recognized: $scv,";
	    $self->{sc_numeric_version} = undef;
	}
	print "SC_NUMERIC_VERSION = $self->{sc_numeric_version}\n" if $Debug;
    }
    return $self->{sc_numeric_version};
}

sub _set_features {
    my $self = shift;
    # Determine what features are in this SystemC version
    my $ver = $self->sc_version;
    my $patched = ($ENV{SYSTEMC} && -r "$ENV{SYSTEMC}/systemperl_patched");
    if (!defined $self->{sp_allow_output_tracing}) {
	if (($self->sc_numeric_version||0) >= 2.000) {
	    $self->{sp_allow_output_tracing} = 1;
	} elsif ($patched) {
	    $self->{sp_allow_output_tracing} = 'hack';
	} else {
	    $self->{sp_allow_output_tracing} = 0;
	}
    }
}

# add this pagename to the list; error if it's already there
sub add_coverpoint_page_name {
    my $self = shift;
    my $pagename = shift;
    my $coverpoint = shift;

    if (defined $self->{pagenames}->{$pagename}) {
	$coverpoint->error("duplicate SP_COVERGROUP page name \"$pagename\"\n");
    }
    $self->{pagenames}->{$pagename} = 1;
}

######################################################################
#### Functions

sub autos {
    my $self = shift;

    # Autos will load new modules, which we must auto in turn, so repeat until everybody's happy
    my %did_autos;
    while (1) {
	my $did_one;
	foreach my $modref ($self->modules) {
	    next if $did_autos{$modref->name};
	    next if $modref->is_libcell();
	    $modref->autos1();
	    $did_autos{$modref->name} = 1;
	    $did_one = 1;
	}
	if ($did_one) {
	    $self->link();  # Pick up pins autos1 created
	} else {
	    last;
	}
    }

    foreach my $modref ($self->modules) {
	next if $modref->is_libcell();
	$modref->autos2();
    }

    $self->link();
}

sub link {
    my $self = shift;
    $self->SUPER::link(@_);
    foreach my $modref ($self->classes) {
	$modref->_link();
    }
}

######################################################################
#### Class access

sub new_class {
    my $self = shift;
    my $modref = new SystemC::Netlist::Class
	(netlist=>$self,
	 @_);
    $self->{_classes}{$modref->name} = $modref;
    return $modref;
}

sub classes {
    return (values %{$_[0]->{_classes}});
}
sub classes_sorted {
    return (sort {$a->name() cmp $b->name()} (values %{$_[0]->{_classes}}));
}

sub find_class {
    my $self = shift;
    my $search = shift;
    # Return file maching name
    my $class = $self->{_classes}{$search};
    return $class if $class;
    return SystemC::Netlist::Class::generate_class($self, $search);
}

######################################################################
#### Module access

sub new_module {
    my $self = shift;
    # @_ params
    # Can't have 'new SystemC::Netlist::Module' do this,
    # as not allowed to override Class::Struct's new()
    my $modref = new SystemC::Netlist::Module
	(netlist=>$self,
	 is_top=>1,
	 @_);
    $self->{_modules}{$modref->name} = $modref;
    return $modref;
}

######################################################################
#### Files access

sub new_file {
    my $self = shift;
    # @_ params
    # Can't have 'new SystemC::Netlist::File' do this,
    # as not allowed to override Class::Struct's new()
    my $fileref = new SystemC::Netlist::File
	(netlist=>$self,
	 @_);
    defined $fileref->name or carp "%Error: No name=> specified, stopped";
    $self->{_files}{$fileref->name} = $fileref;
    $fileref->basename (Verilog::Netlist::Module::modulename_from_filename($fileref->name));
    return $fileref;
}

sub read_file {
    my $self = shift;
    my %params = (netlist=>$self,
		 @_);

    if ($params{filename}) {
	my $filepath = $self->resolve_filename($params{filename});
	if (($filepath||'') =~ /\.v$/) {
	    return $self->read_verilog_file(is_libcell=>1,
					    %params);
	}
    }
    return $self->read_sp_file(%params);
}

sub read_sp_file {
    my $self = shift;
    my $fileref = SystemC::Netlist::File::read
	(netlist=>$self,
	 @_);
}

######################################################################
#### Library files

sub write_cell_library {
    my $self = shift;
    my %params = (filename=>undef,
		  include_libcells=>0,
		  @_);
    $self->dependency_out($params{filename});
    my $fh = IO::File->new(">$params{filename}") or die "%Error: $! writing $params{filename}\n";
    foreach my $modref ($self->modules_sorted) {
	next if !$params{include_libcells} && $modref->is_libcell();
	# Skip libcells that are never used
	next if $params{include_libcells} && $modref->is_libcell() && $modref->userdata('level')==0;
	print $fh "MODULE ",$modref->name,"\n";
	foreach my $cellref ($modref->cells_sorted) {
	    print $fh "  CELL ",$cellref->name," ",$self->remove_defines($cellref->submodname),"\n";
	}
    }
    $fh->close;
}

sub read_cell_library {
    my $self = shift;
    my %params = (filename=>undef,
		  @_);
    $self->dependency_in($params{filename});
    my $fh = IO::File->new("<$params{filename}") or die "%Error: $! $params{filename}\n";
    my $modref;
    while (defined (my $line = $fh->getline)) {
	$line =~ s/#.*$//;
	$line =~ s/^[ \t]+//;
	$line =~ s/[ \t\n\t]+$//;
	if ($line =~ /^PROGRAM\s+(\S+)/) {
	}
	elsif ($line =~ /^MODULE\s+(\S+)/) {
	    $modref = $self->find_module($1);
	    if (!$modref) {
		$modref = $self->new_module(name=>$1, is_libcell=>1,
					    filename=>$params{filename}, lineno=>$.);
	    }
	}
	elsif ($line =~ /^CELL\s+(\S+)\s+(\S+)$/) {
	    my $cellname = $1; my $submodname = $2;
	    my $cellref = $modref->find_cell($cellname);
	    if (!$cellref) {
		$cellref = $modref->new_cell(name=>$cellname, submodname=>$submodname,
					     filename=>$params{filename}, lineno=>$.);
	    }
	}
	else {
	    die "%Error: $params{filename}:$.: Unknown line: $line\n";
	}
    }
    $fh->close;
}

######################################################################
#### Debug

sub dump {
    my $self = shift;
    $self->SUPER::dump();
    foreach my $modref ($self->classes_sorted) {
	$modref->dump();
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist - SystemC Netlist

=head1 SYNOPSIS

  use SystemC::Netlist;

  # See Verilog::Netlist for base functions

    $nl->autos();
    $nl->exit_if_error();


=head1 DESCRIPTION

SystemC::Netlist contains interconnect information about a whole design
database.  The classes of SystemC::Netlist parallel those of
Verilog::Netlist, which should be seen for all documentation.

The database is composed of files, which contain the text read from each
file.

A file may contain modules, which are individual blocks that can be
instantiated (designs, in Synopsys terminology.)

Modules have ports, which are the interconnection between nets in that
module and the outside world.  Modules also have nets, (aka signals), which
interconnect the logic inside that module.

Modules can also instantiate other modules.  The instantiation of a module
is a Cell.  Cells have pins that interconnect the referenced module's pin
to a net in the module doing the instantiation.

Each of these types, files, modules, ports, nets, cells and pins have a
class.  For example SystemC::Netlist::Cell has the list of
SystemC::Netlist::Pin (s) that interconnect that cell.

=head1 FUNCTIONS

See Verilog::Netlist for all common functions.

=over 4

=item $netlist->autos

Updates /*AUTO*/ comments in the internal database.  Normally called before
lint.

=item $netlist->sc_version

Return the version number of SystemC.

=back

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

L<SystemC::Manual>

L<SystemC::Netlist::Cell>,
L<SystemC::Netlist::Class>,
L<SystemC::Netlist::CoverGroup>,
L<SystemC::Netlist::File>,
L<SystemC::Netlist::Module>,
L<SystemC::Netlist::Net>,
L<SystemC::Netlist::Pin>,
L<SystemC::Netlist::Port>,
L<Verilog::Netlist::Subclass>

=cut

# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Netlist::File;
use Class::Struct;
use Carp;

use SystemC::Netlist;
use SystemC::Template;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::File::Struct
	Verilog::Netlist::Subclass);
$VERSION = '1.344';
use strict;

structs('new',
	'SystemC::Netlist::File::Struct'
	=>[name		=> '$', #'	# Filename this came from
	   basename	=> '$', #'	# Basename of the file
	   netlist	=> '$', #'	# Netlist is a member of
	   userdata	=> '%',		# User information
	   module_exp	=> '$', #'	# What to expand __module__ into
	   #
	   text		=> '$',	#'	# ARRAYREF: Lines of text
	   is_libcell	=> '$',	#'	# True if is a library cell
	   has_slow	=> '$',	#'	# True if has #sp slow
	   # For special procedures
	   _write_var	=> '%',		# For write() function info passing
	   _enums	=> '$', #'	# For autoenums, hash{class}{en}{def} = value
	   _autoenums	=> '%', 	# For autoenums, hash{class} = en
	   _modules	=> '%',		# For autosubcell_include
	   _intf_done	=> '$', #'	# For autointf, already inserted it
	   _impl_done	=> '$', #'	# For autoimpl, already inserted it
	   _uses	=> '%',		# For #sp use
	   ]);

######################################################################
######################################################################
#### Read class

package SystemC::Netlist::File::Parser;
use SystemC::Parser;
use Carp;
use strict;
use vars qw (@ISA);
use vars qw (@Text);	# Local for speed while inside parser.
@ISA = qw (SystemC::Parser);

# longest allowed user-defined string
#use constant MAX_USER_STRING_LEN => 256;
use constant MAX_USER_STRING_LEN => 5000;

sub new {
    my $class = shift;
    my %params = (@_);	# filename=>

    # A new file; make new information
    $params{fileref} or die "%Error: No fileref parameter?";
    $params{netlist} = $params{fileref}->netlist;
    my $parser = $class->SUPER::new (%params,
				     modref=>undef,	# Module being parsed now
				     cellref=>undef,	# Cell being parsed now
				     _ifdef_stack => [], # For parsing, List of outstanding ifdefs
				     _ifdef_off => 0,	# For parsing, non-zero if not-processing
				     );
    $parser->{filename} = $parser->{netlist}->resolve_filename($params{filename});
    if (!$parser->{filename}) {
	$params{error_self} and $params{error_self}->error("Cannot open $params{filename}\n");
	die "%Error: Cannot open $params{filename}\n";
    }
    $parser->read (filename=>$parser->{filename});
    return $parser;
}

sub logger { return $_[0]->netlist->logger; }

sub netlist { return $_[0]->{netlist}; }

sub push_text {
    push @Text, $_[1] if $_[0]->{need_text};
}

sub text {
    my $self = shift;
    my $line = shift;
    return if $self->{_ifdef_off};

    # comment lines while inside a covergroup
    if (defined $self->{parsing_covergroup} &&
       ($self->{parsing_covergroup} == 1)) {
	print "\"$line\"\n" if (defined $line && $SystemC::Netlist::Debug);
	$line =~ s#\n#\n//#g if defined $line;
    }

    push_text($self, [ 0, $self->filename, $self->lineno,
		       $line ]);
    if ($self->{netref}) {
	# Snarf comment following signal declaration
	# Note comments must begin on the same line as the signal
	if ($line =~ /^[ \t]*\/\/[ \t]*([^\n]+)/
	    || $line =~ /^[ \t]*\/\*[ \t]*(.*)/) {
	    my $cmt = $1;
	    $cmt =~ s/\*\/.*$//;  # Strip */ ... comment endings
	    $cmt =~ s/\s+/ /g;
	    $self->{netref}->comment($cmt);
	}
	$self->{netref} = undef;
    }
}

sub module {
    my $self = shift;
    my $module = shift;
    return if $self->{_ifdef_off};

    my $fileref = $self->{fileref};
    my $netlist = $self->{netlist};
    $module = $self->{fileref}->module_exp if $module eq "__MODULE__";
    print "Module $module\n" if $SystemC::Netlist::Debug;
    $self->endmodule();	  # May be previous module in file
    $self->{modref} = $netlist->new_module
	(name=>$module,
	 is_libcell=>$fileref->is_libcell(),
	 filename=>$self->filename, lineno=>$self->lineno);
    $fileref->_modules($module, $self->{modref});
}

sub module_continued {
    my $self = shift;
    my $module = shift;
    return if $self->{_ifdef_off};

    my $fileref = $self->{fileref};
    my $netlist = $self->{netlist};
    $module = $self->{fileref}->module_exp if $module eq "__MODULE__";
    print "Module_Continued $module\n" if $SystemC::Netlist::Debug;
    $self->endmodule();	  # May be previous module in file
    $self->{modref} = $netlist->find_module($module);
    if (!$self->{modref}) {
	$self->error ("SP_MODULE_CONTINUED of module that doesn't exist: $module\n");
	$self->module($module);
    }
}

sub endmodule {
    my $self = shift;
    if ($#{$self->{_ifdef_stack}}>-1) {
	$self->error("'#sp ifdef' never terminated with '#sp endif");
    }
    $self->_add_code_symbols($self->symbols());
    $self->{modref} = undef;
}

sub _add_code_symbols {
    my $self = shift;
    my $hashref = shift;
    return if !$self->{modref};
    my $modref = $self->{modref};
    if (!$modref->_code_symbols) {
	$modref->_code_symbols($hashref);
    } else { # Add to existing hash
	my $csref = $modref->_code_symbols;
	while (my ($key, $val) = each %{$hashref}) { $csref->{$key} = $val; }
    }
}

sub auto {
    my $self = shift;
    my $line = shift;

    return if (!$self->{strip_autos});
    return if $self->{_ifdef_off};

    my $modref = $self->{modref};
    my $cellref = $self->{cellref};
    if ($line =~ /^(\s*)\/\*AUTOCTOR\*\//	# Depreciated
	|| $line =~ /^(\s*)\/\*AUTOINIT\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOINIT outside of module definition", $line);
	}
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Module::_write_autoinit,
			   $modref, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSIGNAL\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOSIGNAL outside of module definition", $line);
	}
	$modref->_autosignal($modref->_decl_max + 10);
	$modref->_decl_max(100000000+$modref->_decl_max);  # Leave space for autos
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Module::_write_autosignal,
			   $modref, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELL(S|_DECL)\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOSUBCELL_DECL outside of module definition", $line);
	}
	$modref->_autosubcells(1);
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Module::_write_autosubcell_decl,
			   $modref, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELL_CLASS\*\//) {
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autosubcell_class,
			   $self->{fileref}, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELL_INCLUDE\*\//) {
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autosubcell_include,
			   $self->{fileref}, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOINST\*\//) {
	if (!$cellref) {
	    return $self->error ("AUTOINST outside of cell definition", $line);
	}
	elsif ($cellref->_autoinst()) {
	    return $self->error ("AUTOINST already declared earlier for same cell", $line);
	}
	$cellref->_autoinst(1);
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Cell::_write_autoinst,
			   $cellref, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOENUM_CLASS\(([a-zA-Z0-9_]+)(\.|::)([a-zA-Z0-9_]+)\)\*\//) {
	my $prefix = $1; my $class = $2;  my $enumtype = $4;
	$self->{fileref}->_autoenums($class, $enumtype);
	$self->{netlist}->{_enum_classes}{$class} = 1;
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autoenum_class,
			   $self->{fileref}, $class, $enumtype, $prefix,]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOENUM_GLOBAL\(([a-zA-Z0-9_]+)(\.|::)([a-zA-Z0-9_]+)\)\*\//) {
	my $prefix = $1; my $class = $2;  my $enumtype = $4;
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autoenum_global,
			   $self->{fileref}, $class, $enumtype, $prefix,]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOMETHODS\*\//) {
	my $prefix = $1;
	if (!$modref) {
	    return $self->error ("AUTOMETHODS outside of module definition", $line);
	}
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Module::_write_autodecls,
			   $modref, $self->{fileref}, $prefix]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOTRACE\(([a-zA-Z0-9_]+)((,manual)?(,recurse)?(,activity)?(,exists)?(,standalone)?(,c)?)\)\*\//) {
	my $prefix = $1; my $modname = $2; my $manual = $3;
	$modname = $self->{fileref}->module_exp if $modname eq "__MODULE__";
	my $mod = $self->{netlist}->find_module ($modname);
	$mod or $self->error ("Declaration for module not found: $modname\n");
	$mod->_autotrace('on',1);
	$mod->_autotrace('manual',1) if $manual =~ /\bmanual\b/;
	$mod->_autotrace('recurse',1) if $manual =~ /\brecurse\b/;
	$mod->_autotrace('activity',1) if $manual =~ /\bactivity\b/;
	$mod->_autotrace('exists',1) if $manual =~ /\bexists\b/;
	$mod->_autotrace('standalone',1) if $manual =~ /\bstandalone\b/;
	$mod->_autotrace('c',1) if $manual =~ /\bc\b/;
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::AutoTrace::_write_autotrace,
			   $mod, $self->{fileref}, $prefix,]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOATTR\(([a-zA-Z0-9_,]+)\)\*\//) {
	my $attrs = $2 . ",";
	$modref or $self->error ("Attribute outside of module declaration\n");
	foreach my $attr (split (",", $attrs)) {
	    if ($attr eq "verilated") {
	    } elsif ($attr eq "no_undriven_warning") {
		$modref->lesswarn(1);
	    } elsif ($attr eq "check_outputs_used"
		     || $attr eq "check_inputs_used") {
		$modref->attributes($attr,1);
	    } else {
		$self->error ("Unknown attribute $attr\n");
	    }
	}
    }
    elsif ($line =~ /^(\s*)\/\*AUTOIMPLEMENTATION\*\//) {
	my $prefix = $1;
	$self->{fileref}->_impl_done(1);
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autoimpl,
			   $self->{fileref}, $prefix]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOINTERFACE\*\//) {
	my $prefix = $1;
	$self->{fileref}->_intf_done(1);
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autointf,
			   $self->{fileref}, $prefix]);
    }
    elsif ($line =~ /^(\s*)SP_AUTO_CTOR\s*;/) {
	my $prefix = $1;
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::File::_write_autoctor,
			   $self->{fileref}, $prefix, $modref]);
    }
    elsif ($line =~ /^(\s*)SP_AUTO_METHOD\(([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_().]*)\)\s*;/) {
	my $prefix = $1; my $name=$2; my $sense=$3;
	if (!$modref) {
	    return $self->error ("SP_AUTO_METHOD outside of module definition", $line);
	}
	$modref->new_method(name=>$name,
			    filename=>$self->filename, lineno=>$self->lineno,
			    module=>$modref,
			    sensitive=>$sense);
	foreach my $symb (split /[^a-zA-Z0-9_]+/, $sense) {
	    $self->_add_code_symbols({$symb=>1});  # Track that we consume the clock, etc
	}
    }
    elsif ($line =~ /^(\s*)\/\*AUTOINOUT_MODULE\(([a-zA-Z0-9_]+)(?: *, *"([^"]*)" *, *"([^"]*)"|) *\)\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOINOUT_MODULE outside of module definition", $line);
	}
	!$modref->_autoinoutmod() or return $self->error("Only one AUTOINOUT_MODULE allowed per module");
	$modref->_autoinoutmod([$2,$3,$4]);
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Module::_write_autoinout,
			   $modref, $self->{fileref}, $1]);
    }
    elsif ($line =~ /^(\s*)\/\*AUTOTIEOFF\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOTIEOFF outside of module definition", $line);
	}
	$modref->attributes("autotieoff",1);
	push_text($self, [ 1, $self->filename, $self->lineno,
			   \&SystemC::Netlist::Module::_write_autotieoff,
			   $modref, $self->{fileref}, $1]);
    }
    elsif ($line    =~ /^(\s*)SP_AUTO_COVER	  # $1 prefix
			 (?:  inc \s* \( \s* \d+, # SP_AUTO_COVERinc(id,
			  |   \d* \s* \( )	  # SP_AUTO_COVER1(
			 (?:     \s* \"([^\"]+)\" |) # What
	                 (?: \s*,\s* \"([^\"]+)\" |) # File
			 (?: \s*,\s*   (\d+)      |) # Line
	                 (?: \s*,\s* \"([^\"]+)\" |) # Comment
			 ()			  # Enable
			 \s* \) \s* ;/x
	   || $line    =~ /^(\s*)SP_AUTO_COVER_CMT # $1 prefix
			 (?:  \d* \s* \( )	  # #(
	                 ()()()			  # What, File, Line
	                 (?: \s* \"([^\"]+)\"  )  # Comment
			 ()			  # Enable
			 \s* \) \s* ;/x
	   || $line    =~ /^(\s*)SP_AUTO_COVER_CMT_IF # $1 prefix
			 (?:  \d* \s* \( )	  # #(
	                 ()()()			  # What, File, Line
	                 (?: \s* \"([^\"]+)\"  )  # Comment
			 \s* , \s* ([^;]+)	  # Enable (should check for matching parens...)
			 \s* \) \s* ;/x
	   ) {

	my ($prefix,$what,$file,$line,$cmt,$enable) = ($1,$2,$3,$4,$5,$6);
	$what = 'line' if !defined $what;
	$enable = 1 if (!defined $enable || $enable eq "");
	if (!$file) {
	    $file = $self->filename; $line = $self->lineno;
	}
	$cmt ||= '';
	$modref or return $self->error ("SP_AUTO_COVER outside of module definition", $line);
	my $coverref = $modref->new_cover (filename=>$file, lineno=>$line,
					   what=>$what, comment=>$cmt,
					   enable=>$enable,);
	# We simply replace the existing SP_AUTO instead of adding the comments.
	if ($self->{need_text}) {
	    my $last = pop @Text;
	    ($last->[3] =~ /SP_AUTO/) or die "Internal %Error,"; # should have poped SP_AUTO we're replacing
	    push_text($self, [ 0, $self->filename, $self->lineno, $coverref->call_text($prefix) ]);
	}
    }
    else {
	return $self->error ("Unknown AUTO command", $line);
    }
}

sub ctor {
    my $self = shift;
    my $modref = $self->{modref};
    return if $self->{_ifdef_off};
    $modref or return $self->error ("SC_CTOR outside of module definition\n");
    $modref->_ctor(1);
}

sub cell_decl {
    my $self = shift;
    my $submodname=shift;
    my $instname=shift;
    return if $self->{_ifdef_off};

    print "Cell_decl $instname\n" if $SystemC::Netlist::Debug;
    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_CELL_DECL outside of module definition", $instname);
    }
    my $instnamebase = $instname;
    if ($instnamebase =~ s/\[(.*)\]//) {	# Strip any arrays
	$modref->_cellarray($instnamebase,$1);
    }
    $modref->_celldecls($instnamebase,$submodname);
}

sub cell {
    my $self = shift;
    my $instname=shift;
    my $submodname=shift;
    return if $self->{_ifdef_off};

    print "Cell $instname\n" if $SystemC::Netlist::Debug;
    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_CELL outside of module definition", $instname);
    }
    $self->{cellref} = $modref->new_cell
	(name=>$instname,
	 filename=>$self->filename, lineno=>$self->lineno,
	 submodname=>$submodname);
}

sub pin {
    my $self = shift;
    my $cellname = shift;
    my $pin = shift;
    my $pinvec = shift;
    my $net = shift;
    my $netvec = shift;

    return if !$self->{need_signals};
    return if $self->{_ifdef_off};

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_PIN outside of module definition", $pin);
    }
    # Lookup cell based on the name
    my $cellref = $modref->find_cell($cellname);
    if (!$cellref) {
	return $self->error ("Cell name not found for SP_PIN:", $cellname);
    }

    my $pinref;
    my $pinname = $pin;
    if ($pinref = $cellref->find_pin($pin)) {
	if (!defined $pinvec) {
	    return $self->error ("SP_PIN previously declared, at line ".$pinref->lineno
				 .": ".$pinref->name, $pinref->name);
	} else {
	    # Multiple pins are ok if a vector, so make name unique
	    $pinname .= ";".$self->lineno;
	}
    }
    $cellref->new_pin (name=>$pinname,
		       filename=>$self->filename, lineno=>$self->lineno,
		       portname=>$pin,
		       netname=>$net, );
}

sub _pin_template_clean_regexp {
    my $self = shift;
    my $regexp = shift;
    # Take regexp and clean it

    $regexp =~ s/^\"//;
    $regexp =~ s/\"$//;
    if ($regexp =~ /^\^/ || $regexp =~ /\$$/) {
	$self->error ("SP_TEMPLATE does not need ^/\$ anchoring",$regexp);
    }
    return $regexp;
}

sub _pin_template_check_regexp {
    my $self = shift;
    my $regexp = shift;
    # Take regexp and test for correctness
    # Return new regexp string, and compiled regexp
    $regexp = $self->_pin_template_clean_regexp($regexp);

    my $compiled;
    eval {
	$compiled = qr/^$regexp$/;
    };
    if (my $err = $@) {
	$err =~ s/ at .*$//;
	$self->error ("SP_TEMPLATE compile error: ",$err);
    }

    return ($regexp,$compiled);
}

sub pin_template {
    my $self = shift;
    my $cellregexp = shift;
    my $pinregexp = shift;
    my $netregexp = shift;
    my $typeregexp = shift || ".*";
    return if $self->{_ifdef_off};

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_TEMPLATE outside of module definition");
    }

    my ($cellre, $pinre, $netre, $typere);

    ($cellregexp,$cellre) = $self->_pin_template_check_regexp($cellregexp);
    ($pinregexp,$pinre) = $self->_pin_template_check_regexp($pinregexp);
    ($typeregexp,$typere) = $self->_pin_template_check_regexp($typeregexp);
    # Special rules for replacement
    $netregexp = $self->_pin_template_clean_regexp($netregexp);

    $modref->new_pin_template (filename=>$self->filename, lineno=>$self->lineno,
			       cellregexp => $cellregexp, cellre => $cellre,
			       pinregexp => $pinregexp, pinre => $pinre,
			       typeregexp => $typeregexp, typere => $typere,
			       netregexp => $netregexp,
			       );
}

sub _find_or_new_class {
    my $self = shift;
    if (!$self->{class}) {
	$self->error("Not inside a class declaration");
	$self->{class} = '_undeclared';
    }
    my $class = $self->{netlist}->find_class($self->{class});
    if (!$class) {
	$class = $self->{netlist}->new_class
	    (name=>$self->{class},
	     filename=>$self->filename, lineno=>$self->lineno);
    }
    return $class;
}

sub signal {
    my $self = shift;
    my $inout = shift;
    my $type = shift;
    my $netname = shift;
    my $array = shift;
    my $msb = shift;
    my $lsb = shift;

    return if !$self->{need_signals};
    return if $self->{_ifdef_off};

    if ($type eq "sc_clock" && (($self->{netlist}->sc_version||0) > 20020000
				|| $self->{netlist}{ncsc})) {
	# 2.0.1 changed the basic type of sc_in_clk to a bool
	$type = "bool";
    }

    if ($array) {
	$array =~ s/^\[//;
	$array =~ s/\]$//;
    }

    my $modref = $self->{modref};
    if (!$modref && $inout eq "sp_traced") {
	$modref = $self->_find_or_new_class();
    }

    if (!$modref) {
	return $self->error ("Signal declaration outside of module definition", $netname);
    }

    if ($inout eq "sc_signal"
	|| $inout eq "sc_clock"
	|| $inout eq "sp_traced"
	|| $inout eq "sp_traced_vl"
	) {
	my $net = $modref->find_net ($netname);
	$net or $net = $modref->new_net
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     sp_traced=>($inout eq "sp_traced"),
	     simple_type=>($inout eq "sp_traced" || $inout eq "sp_traced_vl"),
	     data_type=>$type, array=>$array,
	     comment=>undef, msb=>$msb, lsb=>$lsb,
	     );
	$net->_decl_order($modref->_decl_max(1+$modref->_decl_max));
	$self->{netref} = $net;
    }
    elsif ($inout =~ /vl_(inout|in|out)/) {
	my $dir = $1;
	my $net = $modref->find_net ($netname);
	$net or $net = $modref->new_net
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     simple_type=>1, data_type=>$type, array=>$array,
	     comment=>undef, msb=>$msb, lsb=>$lsb,
	     );
	$self->{netref} = $net;
	my $port = $modref->new_port
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     direction=>$dir, data_type=>$type,
	     array=>$array, comment=>undef,);
    }
    elsif ($inout =~ /sc_(inout|in|out)$/) {
	my $dir = $1;
	my $net = $modref->new_port
	    (name=>$netname,
	     filename=>$self->filename, lineno=>$self->lineno,
	     direction=>$dir, type=>$type,
	     array=>$array, comment=>undef,);
	$net->_decl_order($modref->_decl_max(1+$modref->_decl_max));
	$self->{netref} = $net;
    }
    else {
	return $self->error ("Strange signal type: $inout", $inout);
    }

    # Replace our special types
    if ($type =~ /^sp_ui\b/) {
	$self->_var_decl_guts($type);
    }
}

sub covergroup_begin {
    my $self = shift;
    my $name = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: covergroup_begin parsed with name: $name\n" if $SystemC::Netlist::Debug;

    my $modref = $self->{modref};

    if (!$modref) {
	return $self->error ("SP_COVERGROUP \"$name\" outside of module definition\n");
    }

    if (length($name) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$name\" string too long (max $max chars)\n");
    }

    # make a new covergroup
    my $covergroupref = $modref->current_covergroup();
    # name it
    $covergroupref->name($name);
    $covergroupref->page("\"$name\""); # default page = name with quotes
    $covergroupref->lineno($self->lineno);

    my $modname = $modref->name;
    if (defined $modref->_covergroups($name)) {
	$self->error("SP_COVERGROUP name \"$name\" appears more than once in module $modname\n");
    }
    # add it to this module's list
    $modref->_covergroups($name,$covergroupref);

    $self->{parsing_covergroup} = 1;

    my $last = pop @Text;
    # comment the initial SP_COVERGROUP line
    $last->[3] =~ s/(SP_COVERGROUP)/\/\/SP_COVERGROUP/ if defined $last->[3];
    push_text($self, [ 0, $self->filename, $self->lineno, "\n//SP_COVERGROUP Begin of SystemPerl coverage group\n"]);
    push_text($self, $last);

}

sub covergroup_end {
    my $self = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: covergroup_end parsed\n" if $SystemC::Netlist::Debug;

    $self->{parsing_covergroup} = 0;

    my $modref = $self->{modref};
    $modref->close_new_covergroup ();

    push_text($self, [ 0, $self->filename, $self->lineno, "\n//SP_COVERGROUP End of SystemPerl coverage group\n"]);
}

sub covergroup_option {
    my $self = shift;
    my $var = shift;
    my $val = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: covergroup_option parsed with var = value: $var = $val\n" if $SystemC::Netlist::Debug;

    if (length($var) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$var\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    my $currentCovergroup = $modref->current_covergroup();
    $currentCovergroup->set_option($var, $val);
}

sub covergroup_description {
    my $self = shift;
    my $desc = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: covergroup_description parsed with name: $desc\n" if $SystemC::Netlist::Debug;

    if (length($desc) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$desc\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_COVERGROUP outside of module definition\n");
    }
    my $currentCovergroup = $modref->current_covergroup();
    $currentCovergroup->add_desc($desc);
}

sub covergroup_page {
    my $self = shift;
    my $page = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: covergroup_page parsed with name: $page\n" if $SystemC::Netlist::Debug;

    if (length($page) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$page\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_COVERGROUP outside of module definition\n");
    }
    my $currentCovergroup = $modref->current_covergroup();
    $currentCovergroup->add_page($page);
}

sub coversample {
    my $self = shift;
    my $name = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: coversample parsed with name: $name\n" if $SystemC::Netlist::Debug;

    if (length($name) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$name\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_COVER_SAMPLE($name) outside of module definition\n");
    }

    my %cgh = %{$modref->_covergroups};
    my $covergroupref = $cgh{$name}; # look up by name
    $covergroupref || $self->error("SP_COVER_SAMPLE($name) but no SP_COVERGROUP found with that name!\n");

    push_text($self, [ 0, $self->filename, $self->lineno, "\n//SP_COVER_SAMPLE Begin of SystemPerl coverage sample\n"]);
    push_text($self, [ 0, $self->filename, $self->lineno,
		       SystemC::Netlist::CoverGroup::covergroup_sample_text($covergroupref,"\n" )]);
    push_text($self, [ 0, $self->filename, $self->lineno, "//SP_COVER_SAMPLE End of SystemPerl coverage sample\n"]);
}

sub cross_begin {
    my $self = shift;
    my $connection = shift;
    my $name = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: parsed cross name: $name, connecting to $connection\n" if $SystemC::Netlist::Debug;

    if (length($name) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$name\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    my $point = $modref->current_coverpoint();

    $point->lineno($self->lineno);
    $point->isCross(1);
    $point->name($name);
    $point->connection($connection);
}

sub cross {
    my $self = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    my $modref = $self->{modref};
    my $point = $modref->current_coverpoint();

    # pass the rest of the args on down, with fileref added at the front
    unshift @_, $self->{fileref};
    $point->cross_build(@_);
}

sub coverpoint_begin {
    my $self = shift;
    my $connection = shift;
    my $name = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: coverpoint parsed point name: $name, connecting to $connection\n" if $SystemC::Netlist::Debug;

    if (length($name) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$name\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    my $point = $modref->current_coverpoint();

    $point->lineno($self->lineno);
    $point->name($name);
    $point->connection($connection);
    $point->isCross(0);
}

sub coverpoint_window {
    my $self = shift;
    my $name = shift;
    my $ev1 = shift;
    my $ev2 = shift;
    my $depth = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    print "Netlist::File: coverpoint parsed window name: $name\n" if $SystemC::Netlist::Debug;

    if (length($name) > MAX_USER_STRING_LEN) {
	my $max = MAX_USER_STRING_LEN;
	return $self->error ("SP_COVERGROUP \"$name\" string too long (max $max chars)\n");
    }

    my $modref = $self->{modref};
    my $point = $modref->current_coverpoint();

    $point->isWindow(1);
    $point->name($name);
    $point->event1($ev1);
    $point->event2($ev2);
    $point->windowDepth($depth);
}

sub coverpoint {
    my $self = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    my $modref = $self->{modref};
    my $point = $modref->current_coverpoint();

    # pass the rest of the args on down, with fileref added at the front
    unshift @_, $self->{fileref};
    $point->coverpoint_build(@_);
}

sub coverpoint_end {
    my $self = shift;

    return if $self->{_ifdef_off};
    return if !$self->{need_covergroup};

    my $modref = $self->{modref};
    # close this one out
    $modref->close_new_coverpoint();
}

sub preproc_sp {
    my $self = shift;
    my $line = shift;
    if ($line=~ /^\s*\#\s*sp\s+(.*)$/) {
	my $cmd = $1; $cmd =~ s/\s+$//;
	$cmd =~ s!\s+//.*$!!;
	while ($cmd =~ s!\s*/\*.*?\*/!!) {}
	if ($cmd =~ m!(/\*|\*/)!) { $self->error("/* without terminating */ on same line not supported here"); }
	# Ifdef/else/etc
	if ($cmd =~ /^ifdef\s+(\S+)$/) {
	    my $def = $self->{netlist}->defvalue_nowarn($1);
	    my $enable = defined $def;
	    push @{$self->{_ifdef_stack}}, $enable;
	    $self->{_ifdef_off}++ if !$enable;
	}
	elsif ($cmd =~ /^ifndef\s+(\S+)$/) {
	    my $def = $self->{netlist}->defvalue_nowarn($1);
	    my $enable = ! defined $def;
	    push @{$self->{_ifdef_stack}}, $enable;
	    $self->{_ifdef_off}++ if !$enable;
	}
	elsif ($cmd =~ /^else$/) {
	    if ($#{$self->{_ifdef_stack}}<0) {
		$self->error("'#sp else' outside of any '#sp ifdef");
	    } else {
		my $lastEnable = pop @{$self->{_ifdef_stack}};
		$self->{_ifdef_off}-- if !$lastEnable;
		#
		my $enable = !$lastEnable;
		push @{$self->{_ifdef_stack}}, $enable;
		$self->{_ifdef_off}++ if !$enable;
	    }
	}
	elsif ($cmd =~ /^endif$/) {
	    if ($#{$self->{_ifdef_stack}}<0) {
		$self->error("'#sp endif' outside of any '#sp ifdef");
	    } else {
		my $enable = pop @{$self->{_ifdef_stack}};
		$self->{_ifdef_off}-- if !$enable;
	    }
	}
	# Those that only apply when processing
	elsif ($cmd =~ /^implementation$/) {
	    return if $self->{_ifdef_off};
	    push_text($self, [ 0, $self->filename, $self->lineno,
			       \&SystemC::Netlist::File::_start_implementation,
			       $self->{fileref}, $line]);
	}
	elsif ($cmd =~ /^interface$/) {
	    return if $self->{_ifdef_off};
	    push_text($self, [ 0, $self->filename, $self->lineno,
			       \&SystemC::Netlist::File::_start_interface,
			       $self->{fileref}, $line]);
	}
	elsif ($cmd =~ /^slow$/) {
	    return if $self->{_ifdef_off};
	    $self->{fileref}->has_slow(1);
	    push_text($self, [ 0, $self->filename, $self->lineno,
			       \&SystemC::Netlist::File::_start_slow,
			       $self->{fileref}, $line]);
	}
	elsif ($cmd =~ /^use/) {
	    return if $self->{_ifdef_off};
	    my $origtext = "";
	    my $incname;
	    my $dotted;
	    if ($cmd =~ m/^use\s+(\S+)$/ && $cmd !~ /\"/) {
		$origtext = $1;
		$incname = $origtext;
		$incname = $self->{netlist}->remove_defines($incname);
		$dotted = 1 if $incname =~ /^\./;
	    } elsif ($cmd =~ m/^use\s+\"([^\" \n]+)\"$/) {
		$origtext = $1;
		$incname = $origtext;
	    } else {
		return $self->error("Badly formed sp use line", $line);
	    }
	    if (!$dotted) {
		$incname =~ s/\.(h|sp)$//;
		($incname !~ s/(\.[a-z]+)$//)
		    or $self->error("No $1 extensions on sp use filenames", $line);
	    }
	    push_text($self, [ 0, $self->filename, $self->lineno,
			       \&SystemC::Netlist::File::_write_use,
			       $self->{fileref}, $line, $incname, $origtext,
			       $self->filename, $self->lineno, ]);
	    $self->{fileref}->_uses($incname,{name=>$incname, found=>0})
		if !$dotted;
	}
	elsif ($cmd =~ /^include/) {
	    ($cmd =~ m/^include\s+\"([^\" \n]+)\"$/)
		or return $self->error("Badly formed sp include line", $line);
	    return if $self->{_ifdef_off};
	    my $filename = $1;
	    print "#include $filename\n" if $SystemC::Netlist::Debug;
	    $filename = $self->{netlist}->resolve_filename($filename)
		or $self->error("Cannot find include $filename\n");
	    $self->read_include (filename=>$filename);
	}
	else {
	    return $self->error ("Invalid sp_preproc directive",$line);
	}
    }
}

sub class {
    my $self = shift;
    my $class = shift;
    my $inhs = shift;
    # Track class x { enum y ...}
    $class = $self->{fileref}->module_exp if $class eq "__MODULE__";
    $self->{class} = $class;
    #print "CLASS $class  INH $inhs   $self->{netlist}\n" if $Debug;
    if ($inhs) {
	foreach my $inh (split /[:,]/,$inhs) {
	    #print "INHSPLIT $class $inh\n" if $Debug;
	    $self->{netlist}{_class_inherits}{$class}{$inh} = $self;
	}
	# See if it's really a module via inheritance
	_class_recurse_inherits($self, $self->{netlist}{_class_inherits}{$class});
    }
}

sub _class_recurse_inherits {
    my $self = shift;
    my $inhsref = shift;
    # Recurse inheritance tree looking for sc_modules
    foreach my $inh (keys %$inhsref) {
	#print "Class rec $self->{class}  $inh\n";
	if ($inh eq 'sc_module') {
	    if (!$self->{modref} || $self->{modref}->name ne $self->{class}) {
		module($self,$self->{class});
	    }
	} else {
	    _class_recurse_inherits($self,$self->{netlist}{_class_inherits}{$inh});  # Inh->inh
	    # Clone cells/pinouts from lower modules
	}
    }
}

sub enum_value {
    my $self = shift;
    my $enum = shift;
    my $def = shift;
    my $value = shift;

    if ($value =~ /^0x[0-9a-fA-F]+$/) { # convert hex number
	#print "recognized hex $str as ". (hex $str)."\n";
	$value = hex $value;
    }

    # We haven't defined a class for enums... Presume others won't use them(?)
    return if $self->{_ifdef_off};
    my $fileref = $self->{fileref};

    my $class = $self->{class} || "TOP";
    my $href = $fileref->_enums() || {};
    if (!defined $href->{$class}{$enum}) {
	$self->{_last_enum_value} = -1;  # So first enum gets '0'
    }
    # If user didn't specify a value, C++ simply increments from the last value
    if (($value||"") eq "") {
	$value = $self->{_last_enum_value}+1;
    }
    $self->{_last_enum_value} = $value;

    $href->{$class}{$enum}{$def} = $value;
    $fileref->_enums($href);

    # write this to the netlist too
    my $netlist = $fileref->netlist();
    $netlist->{_enums}{$class} = $href->{$class};
}

sub var_decl {
    my $self = shift;
    my $type = shift;
    # Callback from parser
    return if $self->{_ifdef_off};
    $self->_var_decl_guts($type);
}

sub _var_decl_guts {
    my $self = shift;
    my $type = shift;
    # Callback or expansion of type used in another call
    # Replace our special types
    if ($type =~ /^sp_ui\b/) {
	my $typeref = $self->netlist->find_class($type);
	if ($typeref && $typeref->convert_type
	    && $self->{need_text}) {
	    my $last = pop @Text;
	    my $out = $typeref->sc_type;
	    ($last->[3] =~ s!(sp_ui\s*<[^>]+>)!$out/*$1*/!g)
		or $self->error("%Error, can't find type $type on text line\n");
	    push_text($self, $last);
	}
    } else {
	$self->error("%Error, unexpected declaration callback on '$type'");
    }
}

sub error {
    my $self = shift;
    my $text = shift;
    my $token = shift;

    my $fileref = $self->{fileref};
    # Call Verilog::Netlist::Subclass's error reporting, it will track # errors
    my $fileline = $self->filename.":".$self->lineno;
    $fileref->error ($self, "$text\n"
		     ."%Error: ".(" "x length($fileline))
		     .": At token '".($token||"")."'\n");
}

package SystemC::Netlist::File;

######################################################################
#### Accessors

sub filename { return $_[0]->name(); }
sub lineno { return 0; }
sub logger { return $_[0]->netlist->logger; }

######################################################################
######################################################################
#### Functions

sub read {
    my %params = (#filename => undef,
		  append_filenames=>[],	# Extra files to read and add on to current parse
		  @_);
    # If error_self==0, then it's non fatal if we can't open the file.

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::read_file (filename=>) parameter required, stopped";
    my $netlist = $params{netlist} or croak ("Call SystemC::Netlist::read_file instead,");
    $params{strip_autos} = $netlist->{strip_autos} if !exists $params{strip_autos};

    my $filepath = $netlist->resolve_filename($filename);
    if (!$filepath) {
	return if (!$params{error_self});  # Non-fatal
	$params{error_self} and $params{error_self}->error("Cannot open $params{filename}\n");
	die "%Error: Cannot open $params{filename}\n";
    }
    print __PACKAGE__."::read_file $filepath\n" if $SystemC::Netlist::Debug;

    my $fileref = $netlist->new_file (name=>$filepath,
				      module_exp=>(Verilog::Netlist::Module::modulename_from_filename($filepath)),
				      is_libcell=>$params{is_libcell}||0,
				      );

    # For speed, we use @Text instead of the accessor function
    local @SystemC::Netlist::File::Parser::Text = ();

    $params{need_text} = $netlist->{need_text} if !defined $params{need_text};
    $params{need_signals} = $netlist->{need_signals} if !defined $params{need_signals};
    $params{need_covergroup} = $netlist->{need_covergroup} if !defined $params{need_covergroup};
    $params{strip_autos} = $netlist->{strip_autos} if !defined $params{strip_autos};

    my $parser = SystemC::Netlist::File::Parser->new
	( fileref=>$fileref,
	  filename=>$filepath,	# for ->read
	  strip_autos=>$params{strip_autos}||0,		# for ->read
	  need_text=>$params{need_text},		# for ->read
	  need_signals=>$params{need_signals},		# for ->read
	  need_covergroup=>$params{need_covergroup},	# for ->read
	  );
    foreach my $addfile (@{$params{append_filenames}}) {
	$parser->read(filename=>$addfile);
    }
    $fileref->text(\@SystemC::Netlist::File::Parser::Text);
    $parser->endmodule();
    return $fileref;
}

######################################################################
######################################################################
# Linking/Dumping

sub _link {
    my $self = shift;
    foreach my $incref (values %{$self->_uses()}) {
	if (!$incref->{fileref}) {
	    print "FILE LINK $incref->{name}\n" if $SystemC::Netlist::Debug;
	    my $filename = $self->netlist->resolve_filename($incref->{name});
	    if (!$filename) {
		if (!$self->netlist->{link_read_nonfatal}) {
		    $self->error("Cannot find module $incref->{name}\n");
		}
		next;
	    }
	    $incref->{fileref} = $self->netlist->find_file($filename);
	    if (!$incref->{fileref} && $self->netlist->{link_read}) {
		print "  use_Link_Read ",$filename,"\n" if $Verilog::Netlist::Debug;
		my $filepath = $self->netlist->resolve_filename($filename)
		    or $self->error("Cannot find module $filename\n");
		(my $filename_h = $filename) =~ s/\.sp$/.h/;
		if (!$filepath && $self->netlist->resolve_filename($filename_h)) {
		    # There's a .h.  Just consider it as a regular #include
		} else {
		    $incref->{fileref} = $self->netlist->read_file(filename=>$filepath);
		    $incref->{fileref} or die;
		    $self->netlist->{_relink} = 1;
		}
	    }
	}
    }
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"File:",$self->name(),"  Lines:",$#{@{$self->text}},"\n";
}

sub uses_sorted {
    my $self = shift;
    # Return all uses
    return (sort {$a->{name} cmp $b->{name}} (values %{$self->_uses()}));
}

######################################################################
######################################################################
# WRITING

# _write locals
use vars qw($_Write_Type $outputting);

sub print {
    shift if ref $_[0];
    SystemC::Template::print (@_);
}
sub printf {
    shift if ref $_[0];
    SystemC::Template::printf (@_);
}

sub write {
    my $self = shift;  ref $self or croak "%Error: Call as \$ref->".__PACKAGE__."::write, stopped";
    my %params = (@_);

    $SystemC::Netlist::Verbose = 1 if $SystemC::Netlist::Debug;

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::write (filename=>) parameter required, stopped";
    local $_Write_Type = $params{type} || "";
    my $autos  = $params{expand_autos};
    my $program = $params{program} || __PACKAGE__;	# Allow user to override it
    foreach my $var (keys %params) {
	# Copy variables so subprocesses can see them
	$self->_write_var($var, $params{$var});
    }


    my $tpl = new SystemC::Template (ppline=>($_Write_Type),
				     keep_timestamp=>$params{keep_timestamp},
				     # Eval is to support pre-Verilog-Perl 3.041 w/o logger
				     logger=>(eval { $self->logger } || undef),
				     );
    foreach my $lref (@{$tpl->src_text()}) {
	#print "GOT LINE $lref->[1], $lref->[2], $lref->[3]";
	$tpl->print_ln ($lref->[1], $lref->[2], $lref->[3]);
    }

    local $outputting = 1;

    if ($_Write_Type) {
	my $hc = (($_Write_Type eq 'interface') && "_H"
		  || ($_Write_Type eq 'slow') && "SLOW_CPP"
		  || "_CPP");
	$tpl->printf("#ifndef _%s${hc}_\n#define _%s${hc}_ 1\n", uc $self->basename, uc $self->basename);
	$tpl->print("// This file generated automatically by $program\n");
	$tpl->printf("#include \"%s.h\"\n", $self->basename) if ($_Write_Type ne 'interface');
    }

    my $module_exp = $self->module_exp;
    foreach my $line (@{$self->text}) {
	# [autos, filename, lineno, text]
	# [autos, filename, lineno, function, args, ...]
	my $needautos = $line->[0];
	my $src_filename   = $line->[1];
	my $src_lineno = $line->[2];
	if ($autos || !$needautos) {
	    my $func = $line->[3];
	    if (ref $func) {
		# it contains a function and arguments to that func
		#print "$func ($line->[1], $fh, $line->[2], );\n";
		&{$func} ($line->[4],$line->[5],$line->[6],$line->[7],$line->[8],
			  $line->[9],$line->[10],$line->[11],$line->[12],);
	    } else {
		my $text = $line->[3];
		if (defined $text && $outputting) {
		    # This will also substitute in strings.  This was deemed a feature.
		    $text =~ s/\b__MODULE__\b/$module_exp/g;
		    $tpl->print_ln ($src_filename, $src_lineno, $text);
		}
	    }
	}
    }

    # Automatic AUTOIMPLEMENTATION/AUTOINTERFACE at end of each file
    $outputting = 1;
    if (0&&$autos && $_Write_Type eq 'interface' && !$self->_intf_done) {
	$self->_write_autointf("");
    }
    if ($autos && $_Write_Type eq 'implementation' && !$self->_impl_done) {
	$self->_write_autoimpl("");
    }

    if ($_Write_Type) {
	$tpl->print ("// This file generated automatically by $program\n");
	$tpl->printf ("#endif /*guard*/\n");
    }

    # Write the file
    $self->netlist->dependency_out ($filename);
    $tpl->write( filename=>$filename,
		 # Bug in NCSC 05.40-p004
		 absolute_filenames => $self->netlist->{ncsc},
		 );
}

sub _start_implementation {
    my $self = shift;
    my $line = shift;
    if ($_Write_Type) {
	$self->print ("//$line");
	$outputting = ($_Write_Type eq 'implementation');
    } else {
	$self->print ($line);
    }
}
sub _start_interface {
    my $self = shift;
    my $line = shift;
    if ($_Write_Type) {
	$self->print ("//$line");
	$outputting = ($_Write_Type eq 'interface');
    } else {
        $self->print ($line);
    }
}
sub _start_slow {
    my $self = shift;
    my $line = shift;
    if ($_Write_Type) {
	$self->print ("//$line");
	$outputting = ($_Write_Type eq 'slow');
    } else {
	$self->print ($line);
    }
}

sub _write_in_slow {
    my $self = shift;
    return ($_Write_Type eq 'slow'
	    || (!$self->has_slow && $_Write_Type eq 'implementation'));
}
sub _write_in_fast {
    my $self = shift;
    return ($_Write_Type eq 'implementation');
}

our $_Write_Use_Last_Filename = "";
our $_Write_Use_Last_Lineno = 0;
our %_Write_Use_Did_Includes;  #{include_filename}

sub _write_use {
    my $self = shift;
    my $line = shift;
    my $incname = shift;
    my $origtext = shift;
    my $src_filename = shift;
    my $src_lineno = shift;
    return if !$SystemC::Netlist::File::outputting;

    # Flush the duplicate #include cache any time include lines aren't adjacent
    # This way it works if there are #ifdef's around the uses
    if ($_Write_Use_Last_Filename ne $src_filename
	|| ($_Write_Use_Last_Lineno != $src_lineno
	    && ($_Write_Use_Last_Lineno+1) != $src_lineno)
	) {
	%_Write_Use_Did_Includes = ();
    }
    $_Write_Use_Last_Filename = $src_filename;
    $_Write_Use_Last_Lineno = $src_lineno;

    # Output it
    if ($_Write_Type) {
	if ($incname =~ /^\./) {
	    my $line = $incname;
	    my $curmodref = (values %{$self->_modules})[0];
	    my $path = "";
	    my $top = 1;
	    while ($line =~ s/^\.([^.]+)//) {
		my $subname = $1;
		$path .= ".".$subname;
		my $subcell = $curmodref && $curmodref->find_cell($subname);
		$top = 0 if $subcell;
		if ($top) {
		    # Look for a top level module with same name
		    $curmodref = $self->netlist->find_module($subname);
		} else {
		    $curmodref = $subcell->submod if $subcell;  # else error printed below
		}
		if (!$curmodref || (!$top && !$subcell)) {
		    # We put out a #error for C++ to complain about instead
		    # of us erroring, so user #ifdefs can wrap around the error
		    $self->printf("#error sp_preproc didnt find subcell of name '$subname' in sp use: $incname\n");
		    return;
		}
		$self->printf ("#include \"%-22s  // For sp use %s\n",
			       $curmodref->name.'.h"', $path)
		    if (!$_Write_Use_Did_Includes{$curmodref->name});
		$_Write_Use_Did_Includes{$curmodref->name} = 1;
		$top = 0;
	    }
	    $line eq "" or $self->error("Strange sp use line, leftover text '$line': $incname\n");
	} else {
	    $self->printf ("#include \"%-22s  // For sp use %s\n", $incname.'.h"', $origtext)
		if (!$_Write_Use_Did_Includes{$incname});
	    $_Write_Use_Did_Includes{$incname} = 1;
	}
    } else {
        $self->print ($line);
    }
}

sub _write_autointf {
    my $self = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $self->print ("${prefix}// Beginning of SystemPerl automatic interface\n");
    $self->print ("${prefix}// End of SystemPerl automatic interface\n");
}

sub _write_autoctor {
    my $self = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    $self->print ("${prefix}// Beginning of SystemPerl automatic constructors\n");
    SystemC::Netlist::AutoCover::_write_autocover_ctor($self,$prefix,$modref);
    SystemC::Netlist::CoverGroup::_write_covergroup_ctor($self,$prefix,$modref);

    my $last_meth = "";
    foreach my $meth ($modref->methods_sorted) {
	if ($last_meth ne $meth) {
	    $last_meth = $meth;
	    $self->print($prefix."SC_METHOD(".$meth->name.");  // SP_AUTO_METHOD at ".$meth->fileline."\n");
	}
	if ($meth->sensitive) {
	    $self->print($prefix."sensitive << ".$meth->sensitive.";  // SP_AUTO_METHOD at ".$meth->fileline."\n");
	}
    }

    $self->print ("${prefix}// End of SystemPerl automatic constructors\n");
}

sub _write_autoimpl {
    my $self = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $self->print ("${prefix}// Beginning of SystemPerl automatic implementation\n");
    foreach my $class (sort (keys %{$self->_autoenums()})) {
	my $enumtype = $self->_autoenums($class);
	$self->_write_autoenum_impl($prefix,$class,$enumtype);
    }
    foreach my $modref (values %{$self->_modules}) {
	SystemC::Netlist::AutoCover::_write_autocover_impl($self,$prefix,$modref);
	SystemC::Netlist::CoverGroup::_write_covergroup_impl($self,$prefix,$modref);
    }
    $self->print ("${prefix}// End of SystemPerl automatic implementation\n");
}

sub _write_autoenum_class {
    my $self = shift;
    my $class = shift;
    my $enumtype = shift;
    my $prefix = shift;

    return if !$SystemC::Netlist::File::outputting;
    $self->print
	("${prefix}// Beginning of SystemPerl automatic enumeration\n"
	 ."${prefix}enum ${enumtype} e_${enumtype};\n"
	 ."${prefix}// Avoid the default constructor; it may become private.\n"
	 ."${prefix}inline ${class} () : e_${enumtype}(static_cast<${enumtype}>(0x0 /* 0xdeadbeef */)) {};\n"
	 .("${prefix}inline ${class} (${enumtype} _e)"
	   ." : e_${enumtype}(_e) {};\n")
	 .("${prefix}explicit inline ${class} (int _e)"
	   ." : e_${enumtype}(static_cast<${enumtype}>(_e)) {};\n")
	 ."${prefix}operator const char* () const { return ascii(); };\n"
	 ."${prefix}operator ${enumtype} () const { return e_${enumtype}; };\n"
	 ."${prefix}const char* ascii () const;\n"
	 ."${prefix}${enumtype} next () const;\n"
	 );

    my ($min,$max) = $self->_enum_min_max_value($class,$enumtype);
    if (defined $min && defined $max) {
	$self->print
	    ("${prefix}class iterator {\n"
	     ."${prefix}    ${enumtype} m_e; public:\n"
	     ."${prefix}    inline iterator(${enumtype} item) : m_e(item) {};\n"
	     ."${prefix}    iterator operator++();\n"
	     ."${prefix}    inline operator ${class}() const { return ${class}(m_e); }\n"
	     ."${prefix}    inline ${class} operator*() const { return ${class}(m_e); }\n"
	     ."${prefix}};\n"
	     ."${prefix}static iterator begin() { return iterator($class($min)); }\n"
	     ."${prefix}static iterator end()   { return iterator($class($max+1)); }\n"
	     );
    } else {
	$self->print("${prefix}// No ${class}::iterator, as some enum values are assigned from non-numerics\n");
    }

    #Can do this, but then also need setting functions...
    #foreach my $valsym (sort (keys %{$href->{$enumtype}})) {
    #	 $self->print ("${prefix}bool is${valsym}() const {return e_${enumtype}==${valsym};};\n");
    #}
    $self->print ("${prefix}// End of SystemPerl automatic enumeration\n");
}

sub _write_autoenum_global {
    my $self = shift;
    my $class = shift;
    my $enumtype = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $self->print
	("${prefix}// Beginning of SystemPerl automatic enumeration\n"
	 ."${prefix}inline bool operator== (const ${class}& lhs, const ${class}& rhs)"
	 ." { return (lhs.e_${enumtype} == rhs.e_${enumtype}); }\n"
	 ."${prefix}inline bool operator== (const ${class}& lhs, const ${class}::${enumtype} rhs)"
	 ." { return (lhs.e_${enumtype} == rhs); }\n"
	 ."${prefix}inline bool operator== (const ${class}::${enumtype} lhs, const ${class}& rhs)"
	 ." { return (lhs == rhs.e_${enumtype}); }\n"
	 ."${prefix}inline bool operator!= (const ${class}& lhs, const ${class}& rhs)"
	 ." { return (lhs.e_${enumtype} != rhs.e_${enumtype}); }\n"
	 ."${prefix}inline bool operator!= (const ${class}& lhs, const ${class}::${enumtype} rhs)"
	 ." { return (lhs.e_${enumtype} != rhs); }\n"
	 ."${prefix}inline bool operator!= (const ${class}::${enumtype} lhs, const ${class}& rhs)"
	 ." { return (lhs != rhs.e_${enumtype}); }\n"
	 ."${prefix}inline std::ostream& operator<< (std::ostream& lhs, const ${class}& rhs)"
	 ." { return lhs << rhs.ascii(); }\n"
	 ."${prefix}// End of SystemPerl automatic enumeration\n"
	 );
}

sub _write_autoenum_impl {
    my $self = shift;
    my $prefix = shift;
    my $class = shift;
    my $enumtype = shift;

    $self->print
	("${prefix}// AUTOIMPLEMENTATION: AUTOENUM($class,$enumtype)\n"
	 ."${prefix}const char* ${class}::ascii () const {\n"
	 ."${prefix}   switch (e_${enumtype}) {\n"
	 );

    my $href = $self->_enums() || {{}};
    my $vals = $href->{$class};
    $vals = $href->{TOP} if !defined $vals;
    foreach my $valsym (sort (keys %{$vals->{$enumtype}})) {
	my $name = $valsym;
	$self->print ("${prefix}   case ${valsym}: return \"${name}\";\n");
    }

    $self->print
	("${prefix}   default: return \"%E:BadVal:${class}\";\n"
	 ."${prefix}   };\n"
	 ."${prefix}}\n"
	 );

    # Now the iterator
    my ($min,$max) = $self->_enum_min_max_value($class,$enumtype);
    if (defined $min && defined $max) {
	$self->print
	    ("${prefix}${class}::iterator ${class}::iterator::operator++() {\n"
	     ."${prefix}   switch (m_e) {\n"
	     );
	my @valsyms = (sort {$vals->{$enumtype}{$a} <=> $vals->{$enumtype}{$b}}
		       (keys %{$vals->{$enumtype}}));
	my %next_values;
	my $last;
	foreach my $valname (@valsyms) {
	    my $valval = $vals->{$enumtype}{$valname};
	    if (!defined $last || $valval ne $vals->{$enumtype}{$last}) {
		if ($last) {
		    if ($valval == $vals->{$enumtype}{$last}+1) {
			$next_values{inc}{$last} = "${class}(m_e + 1)";
		    } else {
			$next_values{expr}{$last} = $valname;
		    }
		}
		$last = $valname;
	    }
	}
	# Note final value isn't in next_values; the default will catch it.
	foreach my $inc ("inc", "expr") {
	    my @fields = (sort keys %{$next_values{$inc}});
	    for (my $i=0; $i<=$#fields; ++$i) {
		my $field = $fields[$i];
		my $next_field = $fields[$i+1];
		$self->printf ("${prefix}   case %s:",$field);
		if ($next_field && $next_values{$inc}{$field} eq $next_values{$inc}{$next_field}) {
		    $self->printf (" /*FALLTHRU*/\n");
		} else {
		    $self->printf (" m_e=%s; return *this;\n"
				   ,$next_values{$inc}{$field});
		}
	    }
	}
	$self->print
	    ("${prefix}   default: m_e=$class($max+1); return *this;\n"
	     ."${prefix}   }\n"
	     ."${prefix}}\n"
	     );
    }
}

sub _enum_min_max_value {
    my $self = shift;
    my $class = shift;
    my $enumtype = shift;
    # Return (minvalue, maxvalue) for enumeration if it only is
    # assigned to numbers, else return undef.
    # Also, convert any hex values to decimal.

    my $href = $self->_enums() || {{}};
    my $vals = $href->{$class};
    $vals = $href->{TOP} if !defined $vals;
    my $min;
    my $max;
    foreach my $valsym (sort (keys %{$vals->{$enumtype}})) {
	my $val = $vals->{$enumtype}{$valsym};
	if ($val =~ /^\d+$/) {
	} elsif ($val =~ /^0x([a-f0-9]+)$/i) {
	    $val = hex $1;
	} else {
	    return undef;
	}
	$vals->{$enumtype}{$valsym} = $val;
	$min = $val if !defined $min || $val<$min;
	$max = $val if !defined $max || $val>$max;
    }
    return ($min,$max);
}

sub _cells_in_file {
    my $fileref = shift;
    my %cells;
    foreach my $modref (values %{$fileref->_modules}) {
	foreach my $cellref ($modref->cells_sorted) {
	    $cells{$cellref->submodname} = $cellref;
	}
    }
    return (sort {$a->submodname cmp $b->submodname} (values %cells));
}

sub _write_autosubcell_class {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic subcell classes\n");
    foreach my $cellref ($fileref->_cells_in_file) {
	$fileref->printf ("%sclass %-21s  // For %s.%s\n"
				 ,$prefix,$cellref->submodname.";"
				 ,$cellref->module->name, $cellref->name);
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic subcell classes\n");
}

sub _write_autosubcell_include {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic implementation includes\n");
    foreach my $modref (values %{$fileref->_modules}) {
	SystemC::Netlist::AutoCover::_write_autocover_incl($self,$prefix,$modref);
    }
    foreach my $cellref ($fileref->_cells_in_file) {
	$fileref->printf ("#include \"%-22s  // For %s.%s\n"
			  ,$self->netlist->remove_defines($cellref->submodname).".h\""
			  ,$cellref->module->name, $cellref->name);
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic implementation includes\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::File - File containing SystemC code

=head1 SYNOPSIS

  use SystemC::Netlist;

  my $nl = new SystemC::Netlist;
  my $fileref = $nl->read_file (filename=>'filename');
  $fileref->write (filename=>'new_filename',
		   expand_autos=>1,);

=head1 DESCRIPTION

SystemC::Netlist::File allows SystemC files to be read and written.

=head1 ACCESSORS

=over 4

=item $self->basename

The filename of the file with any path and . suffix stripped off.

=item $self->name

The filename of the file.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->dump

Prints debugging information for this file.

=item $self->read

Generally called as $netlist->read_file.  Pass a hash of parameters.  Reads
the filename=> parameter, parsing all instantiations, ports, and signals,
and creating SystemC::Netlist::Module structures.  The optional
preserve_autos=> parameter prevents default ripping of /*AUTOS*/ out for
later recomputation.

=item $self->write

Pass a hash of parameters.  Writes the filename=> parameter with the
contents of the previously read file.  If the expand_autos=> parameter is
set, /*AUTO*/ comments will be expanded in the output.  If the type=>
parameter is set to 'implementation', 'interface' or 'slow', only that type
of code will be written.

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

L<SystemC::Netlist>

=cut

#!/usr/bin/perl -w
################################################################################
#
# Copyright (C) 1998-2000, Ashley Winters <jql@accessone.com>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use Carp;

$| = 1;
umask 0;

use strict;

my %Types;
my %Cast;

my %Info;
my %Input;
my %Methods;
my %Prototypes;

my %IncCache;

my %Inclusive;    # All virtual methods in class and superclasses
my %Exclusive;    # Virtual methods first defined in this class

my $Ext = '.pig';
my $Module = '';
my $Class = '';
my $Path = '';
my $File = '';
my $Line = 0;
my(%Operator) = (
    "=" => "newcopy",
    "()" => "run",
    "==" => "beq",
    "!=" => "bne",
    "*" => "bmul",
    "/" => "bdiv",
    "+" => "badd",
    "-" => "bsub",
    "neg" => "uneg",
    "*=" => "amul",
    "/=" => "adiv",
    "+=" => "aadd",
    "-=" => "asub",
    "<<" => "serialize",
    ">>" => "deserialize"
);

my $Source = 'src';
my $Sourcedir;
my $Libdir = 'lib';

my $VirtualHeader;

my($Sourcefile, $Headerfile);

my(@ClassList, %ConstantList);

my @Vtbl;
my @VtblIn;

my %LinkList;

my(@Modules, @I, @Include, @l, @L, @S, @r, @c);
my($verbose, $silent, $pedantic);
my $Indent;

my $Method;

my @sourcefiles;        # list of files to save;

#&main();    # Start of the program, bottom of the application

sub whisper { print @_ unless $silent }
sub say { whisper @_ unless $verbose }
sub verbose { whisper $_[0] if $verbose }
sub veryverbose { whisper $_[0] if $verbose && $verbose > 1 }

sub source { print SOURCE @_ }
sub header { print HEADER @_ }
sub vheader { print VHEADER @_ }
sub iheader { print IHEADER @_ }

package PerlQt::Method;

sub constructor {
    my $self = shift;
    return ($self->{'Name'} eq 'new');
}

sub destructor {
    my $self = shift;
    return ($self->{'Name'} eq 'DESTROY');
}

sub virtual {
    my $self = shift;
    return (defined($self->{'Virtual'}) &&
	    $self->{'Virtual'} ne 'static' &&
	    $self->{'Virtual'} ne 'variable');
}

sub variable {
    my $self = shift;
    return (defined($self->{'Virtual'}) && $self->{'Virtual'} eq 'variable');
}

sub abstract {
    my $self = shift;
    return (defined($self->{'Virtual'}) && $self->{'Virtual'} eq 'abstract');
}

sub static {
    my $self = shift;
    return ($self->constructor || defined $self->{'Virtual'} && $self->{'Virtual'} eq 'static');
}

sub private {
    my $self = shift;
    return ($self->{'Protection'} eq 'private');
}

sub protected {
    my $self = shift;
    return ($self->{'Protection'} eq 'protected');
}

sub public {
    my $self = shift;
    return ($self->{'Protection'} eq 'public');
}

sub const {
    my $self = shift;
    return $self->{'Const'} || "";
}

sub purpose {
    my $self = shift;
    return $self->{'Purpose'};
}

sub perlonly {
    my $self = shift;
    return ($self->purpose eq '&');
}

sub cpponly {
    my $self = shift;
    return ($self->purpose eq '^');
}

sub everylang {
    my $self = shift;
    return ($self->purpose eq '*');
}

package PerlQt::ClassInfo;

sub alias {
    my $self = shift;
    return $self->{'Alias'}[0] if exists $self->{'Alias'};
    return ();
}

sub define {
    my $self = shift;
    return @{$self->{'Define'}} if exists $self->{'Define'};
    return ();
}

sub undefine {
    my $self = shift;
    return @{$self->{'Undef'}} if exists $self->{'Undef'};
    return ();
}

sub include {
    my $self = shift;
    return @{$self->{'Include'}} if exists $self->{'Include'};
    return ();
}

sub inherit {
    my $self = shift;
    return @{$self->{'Inherit'}} if exists $self->{'Inherit'};
    return ();
}

sub virtual {
    my $self = shift;
    return @{$self->{'Virtual'}} if exists $self->{'Virtual'};
    return ();
}

sub export {
    my $self = shift;

    return @{$self->{'Export'}} if exists $self->{'Export'};
    return ();
}

sub class {
    my $self = shift;

    return (!exists $self->{'Class'} || $self->{'Class'});
}

sub copy {
    my $self = shift;

    return (exists $self->{'Copy'} && $self->{'Copy'});
}

package main;

################################################################################
#
# &cpp_type($psuedotype)
#
# Takes a &slurped psuedo-type and converts it into its C++-equivalent
# value.
#
# Returns a string which indicates the type of C++ argument $psuedotype
# represents.
#
sub cpp_type {
    my $arg = shift;

    $arg =~ s/\{.*\}//;
    $arg =~ s/=.*//;
    $arg =~ s/^\s*//;
    $arg =~ s/\s*$//;
    return $arg;
}

################################################################################
#
# &polyname($proto)
#
# Enhance the method-name of a prototype to indicate argument number and
# types.
#
# Returns a string which can be used to compare two prototypes and check for
# an exact C++ inheritance-override match.
#
sub polyname {
    my $proto = shift;
    my $name;
#    cpp_type($proto->{'Returns'});
    $name = $proto->{'Method'};
    $name .= "(";
    my $x = 0;
    for my $argname (@{$proto->{'Arguments'}}) {
        next unless $x++ || $proto->static;
        my $arg = cpp_type($argname);
        $name .= "," if ($x - (1 - $proto->static)) > 1;
        $name .= $arg;
    }
    $name .= ")";
    $name =~ s/\bconst\b//g;
    $name =~ s/\s+//g;
    $name .= 'static' if $proto->static;
    return $name;
}

################################################################################
#
# &getline(\*fileglob)
#
# Read a single prototype from $fileglobref for &slurp. The new prototype is
# saved in $_. Erroneous prototypes are passed through without warning.
#
# The line is saved in $_. The line-number (for debugging) is saved in $line.
# Returns true while not EOF.
#
# This is where any C++ => pig translation would need to take place.
# &slurp is a sacred function, and should not be touched by mere mortals.
# &getline is far more useful to the huddled masses yearning to add features.
#
sub getline {
    my $handle = shift;

    $Line = 0 if $Line eq "EOF";
    $_ = readline(*$handle);
    $Line++;

    s~//.*~~ if $_;    # remove comments

    unless(defined $_ && !eof(*$handle)) {
	$Line = "EOF";
	return 0 unless defined $_;
    }

    return 1;
}

################################################################################
#
# &slurp(\*fileglob)
#
# Read from $fileglobref, parse it, save it in usable data-structures.
#
#
sub slurp {
    my $source = shift;

    my(@include, @define, @undef, @alias);
    my($class, $protection);
    my $info;

PARSE:
    while(getline($source)) {
	warn "Missing newline in $File ($Line): $_\n" unless chomp || !$pedantic;


########################### This section needs some cleanup
	if(/^\#(include|define|undef)\s*(.*)$/) {
	    my $type = $1;
	    my $arg = $2;
	    if($type eq 'include') {          #include <file.h>
		if($arg =~ /^\<(.*)\>$/) {
		    push @include, $1;
		} else {
		    warn "Bad \#include directive [$_] in $File ($Line)\n";
		}
	    } elsif($type eq 'define') {      #define THIS or #define THIS that
		if($arg =~ /^(\w+)(\s+.+|)$/) {
		    push @define, ($2 ? "$1=$2" : $1);
		} else {
		    warn "Bad \#define directive [$_] in $File ($Line)\n";
		}
	    } elsif($type eq 'undef') {       #undef THIS
		if($arg =~ /^(\w+)\s*$/) {
		    push @undef, $arg;
		} else {
		    warn "Bad \#undef directive [$_] in $File ($Line)\n";
		}
	    }
	    next PARSE;
	}

#	s/\#.*//;
	s/^\#/^/;
	s/^\/\//\&/;
	s/;.*/;/;

	if(/^\s*enum\s+\w*\s*\{/) {   # begin enumeration
	    my $enum = $_;
	    until($enum =~ /\}\;/) {
		last PARSE unless getline($source);
		warn "Missing newline in $File ($Line): $_\n" unless chomp || !$pedantic;
		$enum .= $_;
	    }
	    $enum =~ /^\s*enum\s+\w*\s*\{(.*?)\}\;/;
	    my(@enum) = map { /(\w+)/; $1 } split /,\s*/, $1;
	    if($class) {
		for my $e (@enum) {
		    $Info{$class}{'Constant'}{$e}{'Type'} = 'enum';
		}
#		print "Complete enum: $class\::@enum\n";
	    } else {
		for my $e (@enum) {
		    $Info{$Class}{'Global'}{$e}{'Type'} = 'enum';
		}
#		print "Global enum: $Class\::@enum\n";
	    }
	    next PARSE;
	}
	if(/^\s*(?:extern\s+)?const\s+(\w+\s*?(?:\*|\&)*)\s*(\w+)\s*\;$/) {
	    if($class) {
		$Info{$class}{'Constant'}{$2}{'Type'} = $1;
#		print "Const $1 $class\::$2\n";
	    } else {
		$Info{$Class}{'Global'}{$2}{'Type'} = $1;
#		print "Global $1 $Class\::$2\n";
	    }
	    next PARSE;
	}
	if(/^
	     (suicidal\s+|)        # don't delete on destroy?
	     (virtual\s+|)         # virtual class
	     (class|struct|namespace)\s+ # must have the word 'class' or 'struct'
	     (\w+)\s*              # (virtual)? class QClass
	     (:.*|)                # (virtual)? class QClass : QSuper
	     \{\s*                 # (virtual)? class QClass : QSuper {
	    $/x) {
	    my($suicidal, $v, $t, $c, $s) = ($1, $2, $3, $4, $5);
	    $class = $c;

	    $Info{$class} = $Input{$class}{"\$"}{$class} = {};
	    $info = bless $Info{$class}, 'PerlQt::ClassInfo';

	    push @{$info->{'Virtual'}}, $class if $v;
	    $info->{'Copy'} = 1 if $t eq 'struct';
	    $info->{'Class'} = 0 if $t eq 'namespace';
	    $info->{'Suicidal'} = 1 if $suicidal;

	    $protection = 'public';

	    if($s) {
		my(@list) = split(',', $s);
		for my $super (@list) {
		    if($super =~ /^:?\s*(virtual\s+|)(\w+)\s*$/) {
			push @{$info->{'Inherit'}}, $2;
			push @{$info->{'Virtual'}}, $2 if $1;
		    }
		}
	    }
	    next;
	}
	if(/^\}(.*);\s*$/) {
	    for my $alias (split(',', $1)) {
		$alias =~ s/^\s*(.*?)\s*$/$1/;
		push @alias, $alias;
	    }
	    # Since this is the end of the class, we populate $Info{$class}
	    $Info{$class}{'Alias'} = \@alias if @alias;
	    $Info{$class}{'Include'} = \@include if @include;
	    $Info{$class}{'Define'} = \@define if @define;
	    $Info{$class}{'Undef'} = \@undef if @undef;
	    $class = undef;
	    next;
	}
	if($class) {
	    if(/^\s*(public|protected|private):\s*$/) {
		$protection = $1;
		next;
	    }
	    s/^(\*|\&|\^|)\s*
	       ((?:(?:virtual|abstract|static|variable)\s+)?)
	       (const\s+|)
	       ((?:\w+\s*[\*\&]+\s*|[\w:\<\>\*]+\s*\*?[^\w\(\:\{]|[\w:]+\s+)?)
	       (\{.*?\}\s*|)
	       (~?\w+\s*\(.*|operator.*)
	     /$1$protection $2$3$4$5$class\::$6/x;
#	    print "$_\n";
	}
########################### End of nasty section
	if(/^		  # Method parsing regex
	     (\+|-|)	  # $1 => method-diffs. Defaults to "+" if unspecified
	     (\*|\^|\&|)  # $2 => purpose. Defaults to "*"
	     (.*?)	  # $3 => protection? attribute? return-type?
	     \s*	  # C++ type voodoo =~ m!type\s*(\**\s*)*&?\s*!
	     (\w+)::	  # $4 => class-name
	     (operator\s*\S+  # allow "operator ()" without choking the regex
	      |~?\w+)	  # $5 => method-name, allow "~destructor"
	     \s*	  # allow "type class::method ()"
	     \((.*?)\)	  # $6 => end this argument-list with a space or a ;
	     (?:\s+([:\w].*))? # $7 => post-arg modifiers and colon-substitutes
	     ;		  # EVERY method must be terminated with a semi-colon!
	     (?:\s*\#.*)? # toss any comments at the end of the line
	    $/x) {
	    my($sign, $purpose, $ret, $class, $method, $args, $mod) =
	      ($1,    $2,       $3,   $4,     $5,      $6,    $7);
	    my($perlname, $prot, $virt, $const, $sigslot, $code);
	    my @args;

	    # unified diff format, + means add, - means remove
	    $sign = "+" unless $sign;		# default to + (add)

	    # "*" means visible in Perl and C++
	    # "&" means visible in Perl
	    # "^" means visible in C++
	    $purpose = "*" unless $purpose;

	    # Class::~Class()	    => Class::DESTROY
	    # Class::Class()	    => Class::new
	    # Class::operator ?? () => Class::$operator{??}
	    # Class::method(...)    => Class::method

	    $perlname = ($method =~ /^~/) 		? "DESTROY"	:
			($method eq $class) 		? "new"		:
			($method =~ /operator\s*(.*)$/) ? $Operator{$1} :
			$method;

	    # ^public|protected|private virtual|abstract|static|variable ...+

	    if($ret =~ s/^(public|protected|private)\s*//) { $prot = $1 }
	    if($ret =~ s/^(virtual|abstract|static|variable|)\s*//) {
		$virt = $1 if $1;
	    }
	    if($ret =~ s/^\.{3,}$//) { $ret = length($ret) - 3 }
	    $prot = "public" unless defined $prot;    # default to public

	    # Class::Class() => Class *Class::Class()
	    # Class::~Class() => void Class::~Class()

	    unless($ret) {
		if($perlname eq "new") { $ret = "$class *" }
		elsif($perlname eq "DESTROY") { $ret = "void" }
		else { warn "No return-type [$_] in $File ($Line)\n" }
	    }

	    # Class::method() : $this->method();
	    # Class::method() signal;
	    # Class::method() const;

	    if($mod) {
		my $origmod = $mod;
		if($mod =~ s/\s*:\s*(.*)//) { $code = $1 }
		if($mod =~ s/\s*\b(slot|signal)\b\s*//) { $sigslot = $1 }
		if($mod =~ s/\s*\bconst\b\s*//) { $const = 1 }
		if($mod) {
		    warn "Invalid method-modifier [$origmod] ($mod) " .
			 "in $File ($Line)\n";
		}
	    }

	    # Class::method(...) => Class::method(AV *);
	    # Class::method(.....) => Class::method(SV *, SV *);
	    # Class::method(type1 = Thing(6,7,8,9), that2 = this);

#	    while($args =~ s/^,?\s*([^,\{]+)(\{.*\})?\s*//) {
	    for my $arg (split(/,\s+/, $args)) {
		push @args, $arg;
#		if($arg eq "...") {
#		    push @args, "...";
#"AV *";
#		} elsif($arg =~ /^\.{4,}$/) {
#		    push @args, ("SV *") x (length($arg) - 3);
#		} else {
#		}
	    }

	    # Class::method(int) => Class::method(Class *, int)
	    # Class::method() const => Class::method(const Class *)

	    if($perlname ne "new" && (!defined $virt || $virt ne "static")) {
		my $arg;
		$arg .= "const " if defined $const;
		$arg .= "$class *";
		unshift @args, $arg;
	    }

	    my $info = bless {
		Name => $perlname,      # Perl method-name
		File => \$File,		# Filename (for warnings)
		Line => $Line,		# Line-number (for warnings)
		Prototype => $_,	# Actual prototype (for warnings)

		Diff => $sign,          # Add or remove?
		Purpose => $purpose,    # C++ or Perl or Both?
		Protection => $prot,	# private/protected/public
		Virtual => $virt,	# abstract/virtual/static
		Returns => $ret,	# Return-type
		Class => $class,	# Classname for *this and inheritance
		Method => $method,	# Method-name for this->Method()
		Arguments => \@args,	# Argument-list ref
		SigSlot => $sigslot,	# signal/slot
		Const => $const,	# const?
		Code => $code		# Everything between the : and the ;
	    }, 'PerlQt::Method';

	    push @{$Input{$Class}{'Proto'}}, $info;
	    push @{$Methods{$Class}{$perlname}}, $info;
	    $Prototypes{$Class}{&polyname($info)} = $info;
	}   # end if(proto)
	elsif(/\S/) {
	    warn "Invalid line $Line in $File: $_\n"
		unless /^\s*;$/;
	}
    }
}

use Cwd;

sub arguments {
    my(@args) = @_;

    push @I, cwd . "/include";
    push @L, cwd . "/lib";

    for(my $i = 0; $i < @args; $i++) {
        if($args[$i] =~ /^-(.)(.*)/) {
            my($opt, $arg) = ($1, $2);
            if($opt eq 'v') {
                $verbose = 1;
		$verbose += length($arg) if $arg =~ /^v+$/;
            } elsif($opt eq 's') {
                $silent = 1;
           } elsif($opt eq 'p') {
                $pedantic = 1;
	    } elsif($opt eq 'o') {
		$Source = $arg ? $arg : $args[++$i];
	    } elsif($opt eq 'I') {
		push @I, $arg ? $arg : $args[++$i];
	    } elsif($opt eq 'L') {
		push @L, $arg ? $arg : $args[++$i];
	    } elsif($opt eq 'S') {
		push @S, $arg ? $arg : $args[++$i];
	    } elsif($opt eq 'i' && $arg eq 'nclude') {
		push @Include, $args[++$i];
	    } elsif($opt eq 'l') {
		push @l, $arg ? $arg : $args[++$i];
	    } elsif($opt eq 'r') {
		my $a = $arg ? $arg : $args[++$i];
		$a = "pig_$a";
		push @l, $a;
	    } elsif($opt eq 'c') {
		push @c, $arg ? $arg : $args[++$i];
            } else {
                push @Modules, $args[$i];
            }
        } else {
            push @Modules, $args[$i];
        }
    }
}

sub find ($) {
    my $module = shift;
    my(@path) = ('.', @S);

    for my $path (@path) {
	return "$path/$module" if -d "$path/$module";
    }

    local($") = "', '";
    warn "Cannot find $module in ('@path') for $Class\n";
    return undef;
}

sub ismod ($) {
    my $module = shift;
    my(@path) = ('.', @S);
    for my $path (@path) {
        return 1 if -e "$path/$module$Ext";
        return 1 if -e "$path/$Module/$module$Ext";
    }
    return 0;
}

sub findmod ($) {
    my $module = shift;
    my(@path) = ('.', @S);
#    print "$Module => $Class\n";
    for my $path (@path) {
#	print "$path/$Module/$module\n";
	return "$path/$module" if -e "$path/$module";
	return "$path/$Module/$module" if -e "$path/$Module/$module";
    }

    local($") = "', '";
    warn "Cannot find $module in ('@path') for $Class\n";
    return undef;
}

sub mklibdir {
    mkdir $Libdir, 0755 unless -d $Libdir;
}

sub mksrcdir ($) {
    my $module = shift;
    my $srcdir = "$Source/$module";
    mkdir $Source, 0755 unless -d $Source;
    mkdir $srcdir, 0755 unless -d $srcdir;
    return $srcdir;
}

#sub manifest ($) { print MANIFEST $_[0] . "\n" }
#sub makefile ($) { print MAKEFILE "\t$_[0]\$(OBJ_EXT)\n" }

sub makefile ($) { push @sourcefiles, "$Sourcedir/$_[0]\$(OBJ_EXT)" }

sub export ($) { print MODULEEXPORT $_[0] }

#sub startmanifest {
#    unless(open MANIFEST, ">$Sourcedir/MANIFEST") {
#	warn "Cannot open $Sourcedir/MANIFEST for writing: $!";
#	return;
#    }
#    
#    manifest "MANIFEST";
#}
#
#sub endmanifest {
#    close MANIFEST;
#}
#
#sub startmakefile {
#    unless(open MAKEFILE, ">$Sourcedir/Makefile.PL") {
#	warn "Cannot open $Sourcedir/Makefile.PL for writing: $!";
#	return;
#    }
#
#    manifest "Makefile.PL";
#
#    print MAKEFILE "use ExtUtils::MakeMaker;\n";
#    print MAKEFILE "require 'perlqt.conf';\n\n";
#
#    print MAKEFILE "WriteMakefile(\n";
#    print MAKEFILE "    'NAME' => '$Module',\n";
#    print MAKEFILE "    'VERSION_FROM' => 'perlqt.conf',\n";
#    print MAKEFILE "    'CONFIGURE' => sub { return \\%PigConfig },\n";
#    print MAKEFILE "    'OBJECT' => q{\n";
#
#
#    for my $dir (@c) {
#	my $path = ($dir =~ m!^/!) ? $dir : "../../$dir";
#	next unless opendir(PIGDIR, $dir);
#	my $file;
#	while(defined($file = readdir(PIGDIR))) {
#	    if($file =~ /^(.*)\.c$/) {
#		symlink("$path/$file", "$Sourcedir/$file");
#		manifest $file;
#		makefile $1;
#	    }
#	}
#	closedir(PIGDIR);
#    }
#
#    return 1;
#}
#
#sub endmakefile {
#    print MAKEFILE "    }\n);\n";
#    close MAKEFILE;
#}

sub startmodulecode {
    unless(open MODULEEXPORT, ">$Sourcedir/pig_entry_$Module.c") {
	warn "Cannot open $Sourcedir/pig_entry_$Module.c for writing: $!";
	return;
    }

#    manifest "$Module.entry.c";
    makefile "$Sourcedir/pig_entry_$Module";

    export qq'#include "pig.h"\n';
}

sub endmodulecode {
    export "\n";
    export "struct pig_classinfo PIG_module\[] = {\n";
    for my $class (@ClassList) {
	my $suicidenote = $Info{$class}{'Suicidal'} ? "PIG_CLASS_SUICIDAL" : "0";
	my $const = "0";
	my $alias = $Info{$class}->alias || $class;
	$const = "PIG_${class}_const" if keys %{$Info{$class}{'Constant'}};

	if($Info{$class}->class) {
	    export qq'    {\t"$class",\n\t"$alias",\n\tPIG_${class}_methods,\n\t$const,\n\tPIG_${class}_isa,\n\t';
	    export qq'PIG_${class}_tocast,\n\tPIG_${class}_fromcast,\n\t$suicidenote\n    },\n';
	} else {
	    export qq'    {\t"$class",\n\t"$alias",\n\tPIG_${class}_methods,\n\t$const,\n\t0,\n\t';
	    export qq'0,\n\t0,\n\t0\n    },\n';
	}
    }
    export "    { 0, 0, 0, 0, 0, 0 }\n";
    export "};\n\n";

    export "struct pig_constant PIG_constant_$Module\[] = {\n";
    for my $cinfo (keys %ConstantList) {
	export "    { (void *)$cinfo, $ConstantList{$cinfo} },\n";
    }
    export "    { 0, 0 }\n";
    export "};\n\n";
#    export "struct pig_exportinfolist PIG_export\[] = {\n";
#    for my $extern (sort { $ConstantList{$a}{'Name'} cmp $ConstantList{$b}{'Name'} } keys %ConstantList) {
#	my $cast = $ConstantList{$extern}{'Cast'};
#	export qq'    { "%$ConstantList{$extern}{"Name"}", $extern, ';
#	if($cast) {
#	    $cast =~ s/^\s*const\s+//;
#	    if($cast =~ /^\s*(\w+)/) {
#		export qq'"$1"';
#	    } else {
#		warn "$ConstantList{$extern}{'Cast'} is an unacceptable type";
#	    }
#	} else {
#	    export "0";
#	}
#	export " },\n";
#    }
#    export "    { 0, 0 }\n";
#    export "};\n\n";

    export "PIG_EXPORT_TABLE(PIG_$Module)\n";
#    export "struct pig_symboltable PIG_export_$Module\[] = {\n";
    for my $export (@Vtbl) {
	export "    PIG_EXPORT_SUBTABLE(PIG_${export}_vtbl)\n";
#	export "    { 0, (void *)PIG_${export}_export_vtbl },\n";
    }
    export "PIG_EXPORT_ENDTABLE\n\n";
#    export "    { 0, 0 }\n};\n\n";

    close MODULEEXPORT;
}

sub info () { return $Info{$Class} }

sub readtypemap {
    my $typemap = shift;
    unless(open TYPEMAP, $typemap) {
        die "Could not open typemap $typemap: $!\n";
    }

    while(<TYPEMAP>) {
        s/\#.*//;
        if(/(.*\S)\s*=>\s*(.*\S)\s*/) {
	    my $type = $1;
            $Types{$type} = $2;
	    $Types{$type} =~ s/\s//g;
#            print "$typemap $_ [$.] => type $type => $Types{$type}\n";
        } elsif(/^(\w+)\s*=\s*(.*)/) {
	    $Cast{$1} = $2;
#	    print "cast $1 => $2\n";
	}
    }

    close TYPEMAP;
}


sub list ($) {
    my $path = shift;

    unless(opendir MODULEDIR, $path) {
	warn "Could not open $path for $Module: $!\n";
	return ();
    }

    my(@c, @h, @pig);
    for my $file (sort readdir MODULEDIR) {
	push @c, $1 if $file =~ /(.+)\.c$/;
	push @h, $1 if $file =~ /(.+)\.h$/;
	push @pig, $1 if $file =~ /(.+)$Ext$/;
#	if($file =~ /^pig\..*$/) {
#	    readtypemap("$path/$file");
#	}
    }

    closedir MODULEDIR;

#    for my $c (@c) { manifest $c . '.c'; } # makefile $c }
#    for my $h (@h) { manifest $h . '.h' }

    return @pig;
}

sub loadmodule {
    my $class = shift;
    return if exists $Info{$class};
    $File = findmod("$class$Ext");
#    warn "Trying to find $class$Ext\n";
    unless(open PIG, $File) {
	require Carp;
        Carp::confess("Cannot open $File for $class for reading: $!");
	return;
    }

    my $ssalc = $Class;
    $Class = $class;

    slurp(\*PIG);

    if(!exists($Methods{$class}{'DESTROY'}) && $Info{$class}->class) {
	my $destroy = bless {
	    Name => "DESTROY",
	    File => \$File,
	    Line => 0,
	    Prototype => "$class\::~$class();",
	    Diff => '+',
	    Purpose => '*',
	    Protection => 'public',
	    Virtual => undef,
	    Returns => 'void',
	    Class => $class,
	    Method => "~$class()",
	    Arguments => [ "$class *" ],
	    SigSlot => undef,
	    Const => undef,
	    Code => undef
	}, 'PerlQt::Method';

	push @{$Input{$class}{'Proto'}}, $destroy;
	push @{$Methods{$class}{'DESTROY'}}, $destroy;
	$Prototypes{$class}{&polyname($destroy)} = $destroy;
    }

    $Class = $ssalc;

    close PIG;
}

sub readmodule {
    my $class = shift;
    veryverbose "Reading $class...";
#    $Module = $class;

    loadmodule($class);
    $LinkList{$class}++;

    if($Info{$class}{'Inherit'}) {
	for my $super ($Info{$class}->inherit) {
	    next if $Info{$super};
	    veryverbose "\n";
	    readmodule($super, $class);
	}
    }

    veryverbose "\n" unless shift;
}

sub startsource ($) {
    my $class = shift;
    my $info = $Info{$class};

    open SOURCE, ">$Sourcedir/pig_$class.c";
#    manifest "pig_" . $class . ".c";
    makefile "pig_" . $class;

    open HEADER, ">$Sourcedir/pig_$class.h";
#    manifest "pig_" . $class . ".h";

    my $ifndef = uc("pig_${class}_h");
    header "#ifndef $ifndef\n";
    header "#define $ifndef\n\n";

    for my $include (@Include) {
	for my $undef ($Info{$class}->undefine) {
	    header "#undef $undef\n";
	} 
	for my $define ($Info{$class}->define) {
	    if($define =~ /^(\w+)=(.*)$/) {
		header "#undef $1\n";
		header "#define $1 $2\n";
	    } else {
		header "#undef $define\n";
		header "#define $define\n";
	    }
	}
	header qq'#include "$include"\n';
    }

    for my $include ($info->include) {
	for my $undef ($Info{$class}->undefine) {
	    header "#undef $undef\n";
	} 
	for my $define ($Info{$class}->define) {
	    if($define =~ /^(\w+)=(.*)$/) {
		header "#undef $1\n";
		header "#define $1 $2\n";
	    } else {
		header "#undef $define\n";
		header "#define $define\n";
	    }
	}
	header qq'#include <$include>\n';
    }

    if($info->virtual) {
	open VHEADER, ">$Sourcedir/pig_${class}_v.h";
#	manifest "pig_" . $class . "_v.h";
	header qq'#include "pig_${class}_v.h"\n';

	$ifndef = uc("pig_${class}_v_h");
	vheader "#ifndef $ifndef\n";
	vheader "#define $ifndef\n\n";

	if($info->virtual > 1) {
	    for my $super ($info->virtual) {
		vheader qq'#include "pig_${super}_v.h"\n' if $super ne $class;
	    }
	    vheader "\n";
	} else {
	    vheader qq'#include "$VirtualHeader"\n\n' if $info->virtual == 1;
	}
    }

    header "\n";
    source "#define " . uc("pig_${class}_c") . "\n";
    source qq'#include "pig_$class.h"\n';

    my %inclist;
    for my $proto (@{$Input{$class}{'Proto'}}) {
	next unless $proto->everylang;
	my $ret = $proto->{'Returns'};
	next if $ret eq 'void';
	unless(exists $IncCache{$ret}) {
	    my $type = fetch_ret($ret, 1);
	    if($type =~ /^new (\w+)$/) {
		$IncCache{$ret} = $1;
	    } else {
		$IncCache{$ret} = 0;
	    }
	}
	if($IncCache{$ret} && $IncCache{$ret} ne $class) {
	    for my $header ($Info{$IncCache{$ret}}->include) {
		$inclist{$header}++;
	    }
	}
    }

    for my $include (sort keys %inclist) {
	source qq'#include "$include"\n';
    }
    source "\n";
}

sub endsource ($) {
    my $class = shift;
    my $info = $Info{$class};
    my $ifndef = uc("pig_${class}_h");
    header "#endif  // $ifndef\n";
    if($info->virtual) {
	$ifndef = uc("pig_${class}_v_h");
	vheader "#endif  // $ifndef\n";
	close VHEADER;
    }
    close HEADER;
    close SOURCE;
}

sub startiheader {
    open(IHEADER, ">$Sourcedir/pig_import_${Module}.h") || die;
    iheader qq'#include "pig.h"\n';
    iheader qq'#include "pigtype.h"\n\n';
}

sub endiheader {
    iheader "\nPIG_IMPORT_TABLE(PIG_${Module})\n";
#    iheader "struct pig_symboltable PIG_import_${Module}\[] = {\n";

    for my $import (@Vtbl, @VtblIn) {
	iheader "    PIG_IMPORT_SUBTABLE(PIG_${import}_vtbl)\n";
#	iheader "    { 0, (void *)PIG_${import}_import_vtbl },\n";
    }
    iheader "PIG_IMPORT_ENDTABLE\n\n";
#    iheader "    { 0, 0 }\n};\n";

    close(IHEADER);
}

sub writeheader {
    my $start = "struct pig_alias_$Class : $Class {\n";
    return if exists $Info{$Class}{'Class'};
    for my $proto (@{$Methods{$Class}{'new'}}) {
	next if $proto->perlonly;
	my $decl = cpp_constructor_decl($proto);
	next unless $decl;    # BUG
	header $start;
	$start = "";
	header "    pig_alias_$decl {}\n";
    }
    for my $proto (sort { $a->{'Method'} cmp $b->{'Method'} }
		   values %{$Prototypes{$Class}}) {
	next unless $proto->protected;    # || $proto->virtual 
	next if $proto->constructor || $proto->destructor ||
	        $proto->private || $proto->variable || $proto->{'Code'};

	header $start;
	$start = "";
	my $decl = cpp_decl_proto($proto, 'pig');
        $decl =~ s/(\w+\()/pig_alias_$1/;
	header "    ";
	header "static " if $proto->static;
	header "$decl { ";
	header "return " if $proto->{'Returns'} ne 'void';
	header "$Class\::$proto->{'Method'}\(" .
	    cpp_argname_list($proto, 'pig') . "\);";
	header " }\n";
    }
    header "};\n\n" unless $start;
}

sub by_protection {         # SLOW!!!
    my $x = '';
    $x = "A" if $a->public;
    $x = "B" if $a->protected;
    $x = "C" if $a->private;
    $x .= $a->{'Method'};

    my $y = '';
    $y = "A" if $b->public;
    $y = "B" if $b->protected;
    $y = "C" if $b->private;
    $y .= $b->{'Method'};

    $x cmp $y;
}

sub write_virtual_methods_def {
    vheader "#define pig_virtual_${Class}_methods";
    for my $super (info->virtual) {
	vheader " \\\n    pig_virtual_${super}_methods" if $super ne $Class;
    }
    my $prot = '';
    for my $proto (sort by_protection values %Exclusive) {
	next unless $proto->virtual;
	next if $proto->destructor;
	if($prot ne $proto->{'Protection'}) {
	    $prot = $proto->{'Protection'};
	    vheader " \\\n";
	    vheader "$prot:";
	}
	my $decl = cpp_decl_proto($proto);        # BUG: Can be removed
	vheader " \\\n    virtual $decl;" if $decl;
    }
    vheader "\n\n";
}

sub write_virtual_class {
    my $header = shift;
    my @vlist;

    vheader "extern pigfptr _pig_virtual_$Class\[];\n\n";

    vheader "struct pig_virtual_$Class : ";
    if(info->virtual > 1) {
	my $i = 0;
	for my $super (info->virtual) {
	    next if $super eq $Class;
	    vheader ", " if $i++;
	    vheader "pig_virtual_$super";
	}
    } else {
	vheader "virtual pig_virtual";
    }
    vheader " {\n";

    my $idx = 0;
    for my $poly (sort keys %Exclusive) {
        my $proto = $Exclusive{$poly};
        next unless $proto->virtual;
        next if $proto->destructor;
        push @vlist, $proto;
	my $decl = cpp_decl_proto($proto, "pig");
	my $ptr = cpp_call_fptr($proto, "pig", "_pig_virtual_${Class}\[$idx]", "const pig_virtual");
	$decl =~ s/(\w+\()/pig_virtual_$1/;
	vheader "    $decl {\n";
	vheader "\t";
	vheader "return " if $proto->{'Returns'} ne 'void';
	vheader $ptr;
	vheader ";\n    }\n";
        $idx++;
    }

    vheader "};\n\n";

    source "PIG_EXPORT_TABLE(PIG_${Class}_vtbl)\n" unless $header;
#    source "struct pig_symboltable PIG_${Class}_export_vtbl[] = {\n";
    export "PIG_DECLARE_EXPORT_TABLE(PIG_${Class}_vtbl)\n" unless $header;
#    export "extern struct pig_symboltable PIG_${Class}_export_vtbl[];\n";
    $idx++ unless $idx;
    push @Vtbl, $Class unless $header;
    push @VtblIn, $Class if $header;
    iheader "pigfptr _pig_virtual_$Class\[$idx];\n";
    $idx = 0;
    iheader "PIG_IMPORT_TABLE(PIG_${Class}_vtbl)\n";
#    iheader "struct pig_symboltable PIG_${Class}_import_vtbl[] = {\n";
    for my $proto (@vlist) {
	my $decl;
	$decl .= cpp_type($proto->{'Returns'}) . " (*)(const pig_virtual *";
	my $x = 0;
	for my $arg (@{$proto->{'Arguments'}}) {
	    next unless $x++ || $proto->static;
	    $decl .= ", ";
	    $decl .= cpp_type($arg);
	}
	$decl .= ")";
	my $poly = polyname($proto);
	source qq~    PIG_EXPORT_VIRTUAL("$Class\::$poly", ($decl)pig_virtual_${Class}__$proto->{'Name'})\n~ unless $header;
#	source qq~    { "virtual $Class\::$poly", (void *)($decl)pig_virtual_${Class}__$proto->{'Name'} },\n~;
        iheader qq~    PIG_IMPORT_VIRTUAL("$Class\::$poly", &_pig_virtual_${Class}\[$idx])\n~;
#        iheader qq~    { "virtual $Class\::$poly", (void *)&_pig_virtual_${Class}\[$idx] },\n~;
        $idx++;
    }
    source "PIG_EXPORT_ENDTABLE\n" unless $header;
#    source "    { 0, 0 }\n};\n";
    iheader "PIG_IMPORT_ENDTABLE\n\n";
#    iheader "    { 0, 0 }\n};\n\n";

#    for my $proto (@vlist) {
#    }
}

sub cpp_deftype {
    my $arg = shift;

    return ($arg =~ /^.*=\s*(.*)/) ? $1 : undef;
}

sub cpp_defaultarg {
    my $arg = shift;
    my $def = cpp_deftype($arg);
#    print "$def\n";
    return defined($def) ? " = $def" : "";
}

sub cpp_decl_proto {
    my $proto = shift;
    my $pre = shift;
    my $nodefault = shift;
    my $decl;
    unless($proto->constructor || $proto->destructor) {
	$decl .= cpp_type($proto->{'Returns'}) . " ";
    }
    $decl .= "$proto->{'Method'}(";

    my $x = 0;
    for my $arg (@{$proto->{'Arguments'}}) {
	next unless $x++ || $proto->static;
	$decl .= ", " if ($x - (1 - $proto->static)) > 1;
	if($arg eq '...') {
	    $decl .= $arg;
	    next;
	}
	my $type = cpp_type($arg);
	return '' unless $type;    # BUG!

	$decl .= $type;
	$decl .= " $pre" . ($x-1) if $pre;
#	print "$arg\n";
	$decl .= cpp_defaultarg($arg) unless $nodefault;
    }

    $decl .= ")";

    if($proto->const) {
	$decl .= " const";
    }

    return $decl;
}

sub cpp_call_fptr {
    my($proto, $pre, $ptr, $class) = @_;
    my $call;
    $call = "(*(" . cpp_type($proto->{'Returns'}) . " (";
#    $call .= "$class\::" if $class;
    $call .= "*)(";
    my $x = 0;
    $call .= "$class *" if $class;
    for my $arg (@{$proto->{'Arguments'}}) {
        next unless $x++ || $proto->static;
        $call .= ", " if $class || ($x - (1 - $proto->static)) > 1;
        my $type = cpp_type($arg);
        $call .= $type;
    }
    $call .= "))$ptr)(";
    $call .= "this" if $class;
    $x = 0;
    for my $arg (@{$proto->{'Arguments'}}) {
        next unless $x++ || $proto->static;
        $call .= ", " if $class || ($x - (1 - $proto->static)) > 1;
        $call .= "$pre" . ($x-1);
    }
    $call .= ")";

    return $call;
}



sub cpp_argname_list {
    my $proto = shift;
    my $pre = shift;
    my $arglist = '';
    my $x = 0;
    for my $arg (@{$proto->{'Arguments'}}) {
	next unless $x++ || $proto->static;
	next if $arg eq '...';
	$arglist .= ", " if ($x - (1 - $proto->static)) > 1;
	$arglist .= $pre . ($x-1);
    }
    return $arglist
}

sub cpp_constructor_decl {
    my $proto = shift;
    my @ret;
    my $s = '';

    $s .= cpp_decl_proto($proto, 'pig');
    return $s unless $s;       # BUG!
    $s .= " : $Class(";
    $s .= cpp_argname_list($proto, 'pig');
    $s .= ")";

    return $s;
}

sub write_enhanced_class {
    vheader "class pig_enhanced_$Class : public $Class, private pig_virtual_$Class {\n";
    vheader "    pig_virtual_${Class}_methods\n";
    vheader "public:\n";
    for my $proto (@{$Methods{$Class}{'new'}}) {
	next if $proto->perlonly;
	vheader "    pig_enhanced_" . cpp_constructor_decl($proto) .
	    ", pig_virtual((void *)this) {}\n";
    }
    vheader "    virtual ~pig_enhanced_$Class();\n";
    vheader "};\n\n";
}

sub writevheader {
    write_virtual_methods_def;
    write_virtual_class;
    write_enhanced_class;
}

sub fetch_varg {
    my $argument = shift;
    my $argname = shift;
    my $arg = cpp_type($argument);
    my $def = cpp_deftype($argument);
    my $cast = cpp_cast($argument);

    my $type = pig_type($argument);
    $type =~ s/^\s*//;
    $type =~ s/\s*$//;
    $type =~ s/\s*([\*\&])/$1/g;

    my $s = '';

    my $cmp = $arg;
    $cmp =~ s/\s*([\*\&])/$1/g;

    if(exists $Types{$type}) {
	my $c = '';
        if(exists $Cast{$Types{$type}} &&
           $Cast{$Types{$type}} =~ /\(.*\)/) {
            $c = $Cast{$Types{$type}};
        }
	my $pre = "";
	my $xtype = $Types{$type};
	if($xtype =~ s/(\W).*//) {
	    $pre = '&' if $1 eq '&';
	}
	$s .= "pig_type_${xtype}_push(${pre}${c}$argname)";
    } elsif($cmp ne $type) {
	if($type =~ /^(\w+)\s*\*$/) {
	    $s = "pig_type_${1}_push($argname)";
	} else {
	    $type =~ s/\W.*//;
	    $s = "pig_type_${type}_push($argname)";
	}
    } elsif($cast =~ /^(?:const\s+)?(\w+)/) {
	my $class = $1;
	loadmodule($class);

	if($cast =~ /^const\s+(\w+)\s*\*$/) {
	    $s = qq'pig_type_const_object_push($argname, "$1")';
	} elsif($cast =~ /^const\s+(\w+)\s*\&$/) {
	    $s = qq'pig_type_const_object_ref_push(&$argname, "$1")';
	} elsif($cast =~ /^(\w+)\s*\*$/) {
	    $s = qq'pig_type_object_push($argname, "$1")';
	} elsif($cast =~ /^(\w+)\s*\&$/) {
	    $s = qq'pig_type_object_ref_push(&$argname, "$1")';
	} elsif($cast =~ /^(\w+)$/) {
	    $s = qq'pig_type_object_push(&$argname, "$1")';
	} else {
	    print "NO $argument\n";
	}
    } else {
	print "--$argument\n";
	
	$s = "($arg)pig_argument_skip()";
    }
    return $s;
}

sub fetch_vret {
    my $argument = shift;
    my $arg = cpp_type($argument);
    my $cast = cpp_cast($argument);
    my $type = pig_type($argument);
    $type =~ s/^\s*//;
    $type =~ s/\s*$//;
    $type =~ s/\s*([\*\&])/$1/g;

    my $s = '';

    my $cmp = $arg;
    $cmp =~ s/\s*([\*\&])/$1/g;

    if(exists $Types{$type}) {
	my $t = '';
        if(exists $Cast{$Types{$type}}) {
            $t = "($arg)";
        }
	my $pre = "";
	my $xtype = $Types{$type};
	if($xtype =~ s/(\W).*//) {
	    $pre = '&' if $1 eq '&';
	    my $xarg = $arg;
	    $xarg =~ s/\&.*//;
	    $t = "*($xarg *)";
	}
	$s = "${t}pig_type_${xtype}_pop()";
#    } elsif($cmp ne $type) {
#	$s = "pig_type_${type}_pop()";
    } else {
        if($argument =~ /^(?:const\s+)?(\w+)/) {
	    my $class = $1;
	    loadmodule($class);

	    if($argument =~ /^const\s+(\w+)\s*\*$/) {
		$s = qq'(const $1 *)pig_type_const_object_pop("$1")';
	    } elsif($argument =~ /^const\s+(\w+)\s*\&?$/) {
		$s = qq'*(const $1 *)pig_type_const_object_ref_pop("$1")';
	    } elsif($argument =~ /^(\w+)\s*\*$/) {
		$s = qq'($1 *)pig_type_object_pop("$1")';
	    } elsif($argument =~ /^(\w+)\s*\&?$/) {
		$s = qq'*($1 *)pig_type_object_ref_pop("$1")';
	    } elsif($argument =~ /^(\w+)$/) {
		$s = qq'*($1 *)pig_type_object_ref_pop("$1")';
	    } else {
		print "NO $argument\n";
	    }
	} else {
	    die "We must all die from $argument\n";
	}
#	print "%$argument\n";
    }

    return $s;
}


sub write_virtual_methods {
    for my $poly (sort keys %Exclusive) {
        my $proto = $Exclusive{$poly};
        next unless $proto->virtual;
        next if $proto->destructor;

	local($proto->{'Const'}) = "";    # Beware!!!

	my $decl = cpp_decl_proto($proto, 'pig', 1);

#        $decl =~ s/(\w+\()/pig_virtual_$Class\::pig_virtual_$1/;
	$decl =~ s/(\w+)\(([^\)])/pig_virtual_${Class}__$1(const pig_virtual *pig0, $2/;
	$decl =~ s/(\w+)\(\)/pig_virtual_${Class}__$1(const pig_virtual *pig0)/;

	unless($proto->everylang) {
	    source "$decl;\n\n";
	    next;
	}

        source "static $decl {\n";
	source "    PIG_VIRTUAL(PIG_$proto->{'Class'}_$proto->{'Name'});\n";
	my $x = 0;
	for my $arg (@{$proto->{'Arguments'}}) {
	    next unless $x++;
	    source "    " . fetch_varg($arg, "pig" . ($x-1)) . ";\n";
#	    source "    pig_push(&pig" . ($x-1) . ");\n";
	}
	if($proto->{'Returns'} ne 'void') {
	    source "    pig_call_retmethod(pig0, \"$proto->{'Name'}\");\n";
	    source "    return(" . fetch_vret($proto->{'Returns'}) . ");\n";
	} else {
	    source "    pig_call_method(pig0, \"$proto->{'Name'}\");\n";
	}
	source "}\n\n";
    }
    for my $poly (sort keys %Inclusive) {
	my $proto = $Inclusive{$poly};
	next unless $proto->virtual;
        next if $proto->destructor;
        my $decl = cpp_decl_proto($proto, 'pig', 1);
	$decl =~ s/(\w+\()/pig_enhanced_$Class\::$1/;
	source "$decl {\n";
	source "    ";
	source "return " if $proto->{'Returns'} ne 'void';
	source "pig_virtual_$proto->{'Method'}(" .
	    cpp_argname_list($proto, 'pig') . ");\n";
	source "}\n\n";
    }
}

sub newfirst {
    my($x, $y) = ($a, $b);
    for my $z ($x, $y) {
        $z = "A" if $z eq "new";         # highest alpha string
        $z = "AA" if $z eq "DESTROY";    # next highest alpha string
    }

    return $x cmp $y;
}

sub i {
    my $in = '';
    $in .= ("\t" x ($Indent/2));
    $in .= "    " if $Indent % 2;
    return $in;
}

sub pig_type {
    my $argument = shift;

    if($argument =~ /\{\@?(.*?)\}/) {
	return $1;
    } else {
	return cpp_type($argument);
    }
}

sub cpp_cast {
    my $arg = pig_type(@_);
    my $targ = cpp_type(@_);
    $arg =~ s/^\s*//;
    $arg =~ s/\s*$//;
    $arg =~ s/\s*([\*\&])/$1/g;
    return (exists $Cast{$arg}) ? $Cast{$arg} : $targ;
    return $targ;
}

sub fetch_ret {
    my $argument = shift;
    my $arg = cpp_type($argument);
    my $cast = cpp_cast($argument);
    my $type = pig_type($argument);
    $type =~ s/^\s*//;
    $type =~ s/\s*$//;
    $type =~ s/\s*([\*\&])/$1/g;

    my $s = '';

    my $cmp = $arg;
    $cmp =~ s/\s*([\*\&])/$1/g;

    my $ex = "";
    if($argument =~ /\{\s*(\w+)\s*\((.*)\)\}/) {
	my $list = $2;
	my @args;
	for my $x (split /,\s*/, $list) {
	    $x =~ s/\$[(\d)]/pig$1/g;
	    $x =~ s/\$this/pig0/g;
	    push @args, $x;
	}
	
	$ex = ", " . join(", ", @args) if @args;
    }

    if(exists $Types{$type}) {
	my $c = '';
	if(exists $Cast{$Types{$type}} &&
	   $Cast{$Types{$type}} =~ /\(.*\)/) {
	    $c = $Cast{$Types{$type}};
	}
#	$c = "($Cast{$Types{$type}})" if exists $Cast{$Types{$type}};
#	$c =~ s/\(+/(/g;
#	$c =~ s/\)+/)/g;
	my $pre = "";
	my $xtype = $Types{$type};
	if($xtype =~ s/(\W).*//) {
	    $pre = '&' if $1 eq '&';
	}
	$s = "pig_type_${xtype}_return(${pre}${c}pigr$ex)";
#	$s =~ s/\$type/$arg/g;
    } elsif($cmp ne $type) {
#	print "?$type\n";
	my $pre = "";
	if($type =~ s/(\W).*//) {
	    $pre = '&' if $1 eq '&';
	}
	$s = "pig_type_${type}_return(${pre}pigr$ex)";
    } else {
        if($argument =~ /^(?:const\s+)?(\w+)/) {
	    my $class = $1;
#	    print "Loading $class\n";
	    loadmodule($class);
	    if($Info{$class}->copy) {
		return "new $class" if shift; # include headers for new $class()

		if($argument =~ /^(?:const\s+)?(\w+)\s*\*$/) {
		    $s = qq{pig_type_new_object_return(pigr ? new $1(*pigr) : (void *)pigr, "$1")};
		} elsif($argument =~ /^(?:const\s+)?(\w+)\s*\&?$/) {
		    $s = qq{pig_type_new_object_return(new $1(pigr), "$1")};
		} else {
		    print "NO $argument\n";
		}
	    } else {
		if($argument =~ /^const\s+(\w+)\s*\*$/) {
		    $s = qq{pig_type_const_object_return(pigr, "$1")};
		} elsif($argument =~ /^const\s+(\w+)\s*\&$/) {
		    $s = qq{pig_type_const_object_return(&pigr, "$1")};
		} elsif($argument =~ /^(\w+)\s*\*$/) {
		    $s = qq{pig_type_object_return(pigr, "$1")};
		} elsif($argument =~ /^(\w+)\s*\&?$/) {
		    $s = qq{pig_type_object_return(&pigr, "$1")};
		} else {
		    print "NO $argument\n";
		}
	    }
	} else {
	    die "We must all die from $argument\n";
	}
#	print "%$argument\n";
    }

    return $s;
}

sub fetch_arg {
    my $argument = shift;
    my $idx = shift;
    my $prefix = shift || 'pig_type_';
    my $arg = cpp_type($argument);
    my $def = cpp_deftype($argument);
    my $cast = cpp_cast($argument);
    my $defarg = defined($def) ? "($cast)($def)" : "";

    my $type = pig_type($argument);
    $type =~ s/^\s*//;
    $type =~ s/\s*$//;
    $type =~ s/\s*([\*\&])/$1/g;

    my $s = '';

    my $cmp = $arg;
    $cmp =~ s/\s*([\*\&])/$1/g;

#    warn "$type\n";
    if(exists $Types{$type}) {
	my $c = '';
	my $t = '';
	if(exists $Cast{$Types{$type}}) {
if($Cast{$Types{$type}} =~ /\(.*\)/) {
	    $c = "$Cast{$Types{$type}}";
	    $t = "($arg)";
}
elsif($defarg) {
    $defarg = $def;
}
	}
	my $pre = "";
	my $xtype = $Types{$type};
	if($xtype =~ s/(\W).*//) {
	    $pre = '&' if $1 eq '&';
	    my $xarg = $arg;
	    $xarg =~ s/\s*\&//g;
	    $t = "*($xarg *)"
	}
	if($defarg) {
	    $s .= "$t$prefix${xtype}_defargument(${pre}${c}$defarg)";
	} else {
	    $s .= "$t$prefix${xtype}_argument()";
	}
    } elsif($cmp ne $type) {
	if($type =~ /^(\w+)\s*\*$/) {
	    $s = "*($arg *)$prefix${1}_argument($defarg)";
	} else {
	    my $xarg = "";
	    my $commaxarg = "";
	    if($type =~ /\((.+)\)/) {
		$xarg = $1;
		$commaxarg = ", $xarg";
	    }

	    $type =~ s/\W.*//;
	    if($arg =~ /\&\s*$/) {
		if($defarg) {
		    $s = "$prefix${type}_defargument($defarg$commaxarg)";
		} else {
		    $s = "$prefix${type}_argument($xarg)";
		}
	    } else {
		if($defarg) {
		    $s = "($arg)$prefix${type}_defargument($defarg$commaxarg)";
		} else {
		    $s = "($arg)$prefix${type}_argument($xarg)";
		}
#		$s = "($arg)$prefix${type}_argument($defarg)";
	    }
	}
    } elsif($cast =~ /^(?:const\s+)?(\w+)/) {
	my $class = $1;
	loadmodule($class);
	
	if($cast =~ /^const\s+(\w+)\s*\*$/) {
	    if(defined($def)) {
		$s .= qq'(const $1 *)${prefix}const_object_defargument($def, "$1")';
	    } else {
		$s .= qq'(const $1 *)${prefix}const_object_argument("$1")';
	    }
	} elsif($cast =~ /^const\s+(\w+)\s*\&$/) {
	    if(defined($def)) {
		$s .= qq'*(const $1 *)${prefix}const_object_ref_defargument(&pig_$idx, "$1")';
	    } else {
		$s .= qq'*(const $1 *)${prefix}const_object_ref_argument("$1")';
	    }
	} elsif($cast =~ /^(\w+)\s*\*$/) {
	    if(defined($def)) {
		$s .= qq'($1 *)${prefix}object_defargument($def, "$1")';
	    } else {
		$s .= qq'($1 *)${prefix}object_argument("$1")';
	    }
	} elsif($cast =~ /^(\w+)\s*\&?$/) {
	    if(defined($def)) {
		$s .= qq'*($1 *)${prefix}object_ref_defargument(&pig_$idx, "$1")';
	    } else {
		$s .= qq'*($1 *)${prefix}object_ref_argument("$1")';
	    }
	} else {
	    print "NO $argument\n";
	}
    } else {
	print "-$argument\n";
	
	$s = "($arg)pig_argument_skip()";
    }
    return $s;
}

sub write_proto_method {
    my $proto = shift;

    my $x = 0;
    return if $proto->{'Name'} eq 'newcopy';         # broken for now

    if($proto->destructor) {
	source i."$Class * pig0 = ($Class *)pig_type_object_destructor_argument(\"$Class\");\n";
    } else {
	for my $argument (@{$proto->{'Arguments'}}) {
	    my $arg = cpp_type($argument);
	    if(cpp_deftype($argument) && $arg =~ /\&/) {
		source i."$arg pig_$x = ".cpp_deftype($argument).";\n";
	    }
	    source i.$arg;
	    source " pig$x";
	    source " = ";
            if($x == 0 && !$proto->static && !$proto->constructor) {
                source fetch_arg($argument, $x, 'pig_type_this_');
            } else {
                source fetch_arg($argument, $x);
            }
	    source ";\n";
	    $x++;
	}
    }
    source i."PIG_END_ARGUMENTS;\n\n";
#    source "\n" if @{$proto->{'Arguments'}};
    source i;
    if($proto->{'Returns'} ne 'void') {
	my $arg = cpp_type($proto->{'Returns'});
	source $arg;
	source " pigr = ";
    }
    if($proto->{'Code'}) {
	my $code = $proto->{'Code'};
	$code =~ s/^\s*//;
	$code =~ s/\s*//;
	$code =~ s/\$class/pigclass/g;
	$code =~ s/\$this/pig0/g;
	$code =~ s/\$(\d+)/pig$1/g;
	source "$code;\n\n";
    } elsif($proto->variable) {
	my $code = $proto->{'Name'};
	my $set = 0;
	if($code =~ /^set/) {
	    $set = 1;
	    $code =~ s/^set([A-Z])/\l$1/;
	    $code =~ s/^set([a-z])/\u$1/;
	}
	if($set) {
	    source "pig0->$code = pig1;\n\n";
	} else {
	    source "pig0->$code;\n\n";
	}
    } elsif($proto->destructor) {
	if(info->virtual) {
	    source "if(pig_object_can_delete()) delete ((pig_enhanced_$Class *)pig0);\n\n";
	} else {
	    source "if(pig_object_can_delete()) delete pig0;\n\n";
	}
	source i."pig_return_nothing();\n";
	return;
    } elsif($proto->constructor) {
	if(info->virtual) {
	    source "new pig_enhanced_";
	} else {
	    source "new ";
	}
    } elsif($proto->static) {
	if($proto->protected) {
	    source "pig_alias_$Class\::pig_alias_";
	} else {
	    source "$Class\::";
	}
    } else {
	if($proto->protected) {
	    source "((pig_alias_$Class *)pig0)->pig_alias_";
	} elsif($proto->virtual) {
	    source "pig0->$Class\::";
	} else {
	    source "pig0->";
	}
    }

    unless($proto->{'Code'} || $proto->variable) {
	source "$proto->{'Method'}(";
	source cpp_argname_list($proto, 'pig');
	source ");\n\n";
    }

    if($proto->{'Name'} eq 'new') {
	source i.qq'pig_type_new_castobject_return(pigr, "$Class", pigclass);\n';
    } elsif($proto->{'Returns'} ne 'void') {
	source i.fetch_ret($proto->{'Returns'}).";\n";
    } else {
	source i."pig_return_nothing();\n";
    }
}

sub group_of_type {
    my $item = shift;
    my $arg = cpp_type($item);
    my $type = pig_type($item);
    my $cmp = $arg;
    $cmp =~ s/\s*([\*\&])/$1/g;
    $cmp =~ s/\s*\*.*//;
#    $type = $Types{$type} if exists $Types{$type} && $Types{$type} ne $cmp;
    $type =~ s/^\s*//;
    $type =~ s/\s*$//;
    $type =~ s/\s*([\*\&])/$1/g;
    $type =~ s/\s*\*.*//;
    if($type =~ /^(?:int|long|uint|short|enum)$/) {
	return 'int';
    } elsif($type =~ /^bool$/) {
	return 'bool';
    } elsif($type =~ /^(?:float|double)$/) {
	return 'float';
    } elsif($arg =~ /^(?:const\s+)?char\s*\*\s*$/) {
	return 'string';
    } elsif($cmp ne $type) {
        return group_of_type($arg);
    } elsif($arg =~ /^(?:const\s+)?([\w:]+)/ and ismod $1) {
	return 'class';
    } else {
	$arg =~ s/\s+/ /g;
	$arg =~ s/\s*([\*\&])/$1/g;
#	print "okay, $arg => $Types{$arg}\n";
	if(exists $Types{$arg} && $Types{$arg} ne $arg) {
#	    print "Getting $Types{$arg} from $arg\n";
	    return group_of_type($Types{$arg});
	}
#	print "Okay, casting $arg to $Cast{$arg}\n";
	if(exists $Cast{$arg} && $Cast{$arg} ne $arg) {
	    return group_of_type($Cast{$arg});
	}
#	print "UNKNOWN '$type' '$arg' '$cmp'\n";
#	if(exists $Types{$arg}
	return 'unknown';
    }
}

sub branched_filter {
    my $info = shift;
    my $list = shift;
    my $ninfo = {};

    $ninfo->{'undef'} = [ map { $$list{$_} ? ($_) : () } @{$info->{'undef'}} ];
    $ninfo->{'string'} = [ map { $$list{$_} ? ($_) : () } @{$info->{'string'}} ];
    $ninfo->{'mystery'} = [ map { $$list{$_} ? ($_) : () } @{$info->{'mystery'}} ];

    for my $key (keys %{$info->{'number'}}) {
	$ninfo->{'number'}{$key} = [ map { $$list{$_} ? ($_) : () }
				     @{$info->{'number'}{$key}} ];
    }

    for my $key (keys %{$info->{'class'}}) {
	$ninfo->{'class'}{$key} = [ map { $$list{$_} ? ($_) : () }
				    @{$info->{'class'}{$key}} ];
    }

    return $ninfo;
}

sub branch_condition {
    my $pm = shift;
    my $idx = shift;
    my $list = shift;
    my %list;

    if($Method eq 'new') {
	return 0 unless $idx < @$pm;
    } else {
	return 0 unless $idx < $#$pm;
    }

    for my $item (@$list) { $list{$item}++ }
    source "{\n";
    $Indent++;
    branching_conditional($pm, $idx + 1, \%list);   # mutual recursion
    $Indent--;
    source i."}\n";

    return 1;
}

sub byinheritance {
    my(@asuper, @bsuper);
    supernames($a, \@asuper);
    supernames($b, \@bsuper);
    if(grep($a, @bsuper)) {
	return 1;
    } elsif(grep($b, @asuper)) {
	return 0;
    } else {
	return $a cmp $b;
    }
}

sub branching_conditional {
    my $pm = shift;
    my $idx = shift;
    my $list = shift;
    my $info = branched_filter(($Method eq 'new') ? $pm->[$idx-1] : $pm->[$idx], $list);
    my $else = 0;

    source i."unsigned int pigi$idx = pig_argument_info($idx);\n";
    if(scalar @{$info->{'string'}} &&
       scalar @{$info->{'string'}} != scalar @{$info->{'undef'}}) {
	source i;
	source "else " if $else++;
	source "if(pig_is_string($idx)) ";
	if(scalar @{$info->{'string'}} == 1) {
	    source "pigs = $info->{'string'}[0];\n";
	} elsif(!branch_condition($pm, $idx, $info->{'string'})) {
	    source "pigs = 0;    // AMBIGUOUS\n";
	}
    }
    if(scalar keys %{$info->{'number'}}) {
	my $c = scalar keys %{$info->{'number'}};
	if($c == 1) {
	    my($key) = keys(%{$info->{'number'}});
	    source i;
	    source "else " if $else++;
	    source "if(pig_is_number($idx)) ";
	    if(scalar @{$info->{'number'}{$key}} == 1) {
		source "pigs = $info->{'number'}{$key}[0];\n";
	    } elsif(!branch_condition($pm, $idx, $info->{'number'}{$key})) {
		source "pigs = 0;      // AMBIGUOUS\n";
	    }
	} elsif($c == 2) {
	    my($k1, $k2) = keys(%{$info->{'number'}});
	    if($k1 eq 'int') {
		source i;
		source "else " if $else++;
                source "if(pig_is_int($idx)) ";
                if(scalar @{$info->{'number'}{'int'}} == 1) {
                    source "pigs = $info->{'number'}{'int'}[0];\n";
                } elsif(!branch_condition($pm, $idx, $info->{'number'}{'int'})) {
                    source "pigs = 0;      // AMBIGUOUS\n";
                }
	    }
	    if($k2 eq 'int') {
		source i;
		source "else " if $else++;
                source "if(pig_is_int($idx)) ";
                if(scalar @{$info->{'number'}{'int'}} == 1) {
                    source "pigs = $info->{'number'}{'int'}[0];\n";
                } elsif(!branch_condition($pm, $idx, $info->{'number'}{'int'})) {
                    source "pigs = 0;      // AMBIGUOUS\n";
                }
	    }

	    if($k1 eq 'float') {
		source i;
		source "else " if $else++;
                source "if(pig_is_float($idx)) ";
                if(scalar @{$info->{'number'}{'float'}} == 1) {
                    source "pigs = $info->{'number'}{'float'}[0];\n";
                } elsif(!branch_condition($pm, $idx, $info->{'number'}{'float'})) {
                    source "pigs = 0;      // AMBIGUOUS\n";
                }
	    }
	    if($k2 eq 'float') {
		source i;
		source "else " if $else++;
                source "if(pig_is_float($idx)) ";
                if(scalar @{$info->{'number'}{'float'}} == 1) {
                    source "pigs = $info->{'number'}{'float'}[0];\n";
                } elsif(!branch_condition($pm, $idx, $info->{'number'}{'float'})) {
                    source "pigs = 0;      // AMBIGUOUS\n";
                }
	    }

	    if($k1 eq 'bool') {
		source i;
		source "else " if $else++;
                source "if(pig_is_bool($idx)) ";
		if(scalar @{$info->{'number'}{'bool'}} == 1) {
		    source "pigs = $info->{'number'}{'bool'}[0];\n";
		} elsif(!branch_condition($pm, $idx, $info->{'number'}{'bool'})) {
		    source "pigs = 0;      // AMBIGUOUS\n";
		}
	    }
	    if($k2 eq 'bool') {
		source i;
		source "else " if $else++;
                source "if(pig_is_bool($idx)) ";
		if(scalar @{$info->{'number'}{'bool'}} == 1) {
		    source "pigs = $info->{'number'}{'bool'}[0];\n";
		} elsif(!branch_condition($pm, $idx, $info->{'number'}{'bool'})) {
		    source "pigs = 0;      // AMBIGUOUS\n";
		}
	    }
	}
    }
    if(scalar @{$info->{'undef'}}) {
	if(scalar @{$info->{'string'}} == scalar @{$info->{'undef'}}) {
	    source i;
	    source "else " if $else++;
	    source "if(pig_is_string($idx) || pig_is_undef($idx)) ";
	    if(scalar @{$info->{'string'}} == 1) {
		source "pigs = $info->{'string'}[0];\n";
	    } elsif(!branch_condition($pm, $idx, $info->{'string'})) {
		source "pigs = 0;      // AMBIGUOUS\n";
	    }
	} elsif(scalar(keys %{$info->{'class'}}) == 1 &&
		scalar(@{$info->{'class'}{(keys %{$info->{'class'}})[0]}}) ==
		(scalar(@{$info->{'undef'}}) - scalar(@{$info->{'string'}}))) {
	    my $key = (keys %{$info->{'class'}})[0];
	    source i;
	    source "else " if $else++;
	    source "if(pig_is_object($idx) || pig_is_undef($idx)) ";
	    if(scalar @{$info->{'class'}{$key}} == 1) {
		source "pigs = $info->{'class'}{$key}[0];\n";
	    } elsif(!branch_condition($pm, $idx, $info->{'class'}{$key})) {
		source "pigs = 0;    // AMBIGUOUS\n";
	    }
	} else {
	    source i;
	    source "else " if $else++;
	    source "if(pig_is_undef($idx)) ";
	    if(scalar @{$info->{'undef'}} == 1) {
		source "pigs = $info->{'undef'}[0];\n";
	    } elsif(!branch_condition($pm, $idx, $info->{'undef'})) {
		source "pigs = 0;    // AMBIGUOUS\n";
	    }
	}
    }
    if(scalar keys %{$info->{'class'}}) {
	if(scalar keys %{$info->{'class'}} == 1 &&
#	  (scalar(@{$info->{'string'}}) != scalar(@{$info->{'undef'}})) &&
	   scalar(@{$info->{'class'}{(keys %{$info->{'class'}})[0]}}) !=
	  (scalar(@{$info->{'undef'}}) - scalar(@{$info->{'string'}}))) {
	    my($key) = keys(%{$info->{'class'}});
	    source i;
	    source "else " if $else++;
	    source "if(pig_is_object($idx)) ";
	    if(scalar @{$info->{'class'}{$key}} == 1) {
		source "pigs = $info->{'class'}{$key}[0];\n";
	    } elsif(!branch_condition($pm, $idx, $info->{'class'}{$key})) {
		source "pigs = 0;     // AMBIGUOUS\n";
	    }
	} elsif(scalar(keys %{$info->{'class'}}) > 1) {
	    my(@classes) = sort byinheritance keys %{$info->{'class'}};
	    for my $key (@classes) {
		source i;
		source "else " if $else++;
		source "if(pig_is_class($idx, \"$key\")) ";
		if(scalar @{$info->{'class'}{$key}} == 1) {
		    source "pigs = $info->{'class'}{$key}[0];\n";
		} elsif(!branch_condition($pm, $idx, $info->{'class'}{$key})) {
		    source "pigs = 0;     // AMBIGUOUS\n";
		}
	    }
	}
    }
    if(scalar @{$info->{'mystery'}}) {
	source i;
	source "else " if $else++;
	source "if(pig_is_mystery($idx)) ";
	if(scalar @{$info->{'mystery'}} == 1) {
	    source "pigs = $info->{'mystery'}[0];\n";
	} elsif(!branch_condition($pm, $idx, $info->{'mystery'})) {
	    source "pigs = 0;    // AMBIGUOUS\n";
	}
    }
    if(!$else && $idx < $#$pm) {
#	branching_conditional($pm, $idx + 1, $list);
    }
}

sub write_whichproto {
    my $protos = shift;
    my $method = $protos->[0]{'Name'};
    my @argcnt;
    my $adj = 0;

#    my $v = $protos->[0]{'Class'} eq 'QScrollBar';

    $adj = 1 if $method eq 'new';

    for(my $item = 0; $item < @$protos; $item++) {
	my $proto = $protos->[$item];
	my @arguments;
	my $x = 0;
	for my $arg (@{$proto->{'Arguments'}}) {
	    push @arguments, $arg unless $arg =~ /\{\s*\@/;
#	    if($v) { print "x[$item] ($arg)\n" }
	}
	for my $arg (@arguments) {
#	    if($v) { print "deftype $arg\n" if  defined cpp_deftype($arg);
#		 }
	    last if defined cpp_deftype($arg);
	    $x++;
	}
	for my $i ($x .. scalar(@arguments)) {
	    push @{$argcnt[$i]}, $item;
	}
    }

    source i."if(";

    my($i, $bottom);
    for($i = 0; $i < @argcnt; $i++) {
	if(!defined($bottom) && $argcnt[$i]) {
	    if($i == 0) {
		$bottom = 0;
		next;
	    }
	    $bottom = $i;
	    source "pigc <= ".($i-1+$adj);
	}
	elsif(defined($bottom) && !$argcnt[$i]) {
	    source " || " if $bottom++;
	    source "pigc == " . ($i+$adj);
	}
    }

    source " || " if $bottom++;
    source "pigc >= " . ($i+$adj);

    source ") pigs = 0;\n";

    for($i = 0; $i < @argcnt; $i++) {
	next unless ref $argcnt[$i];
	if(scalar @{$argcnt[$i]} == 1) {
	    my $case = $argcnt[$i][0] + 1;
	    source i."else if(pigc == ".($i+$adj).") pigs = $case;\n";
	} else {
	    my @protomatrix;

	    source i."else if(pigc == ".($i+$adj).") {\n";
	    $Indent++;
	    source i."// ".scalar(@{$argcnt[$i]})." possibilities\n";

	    for my $idx (0..($i-1)) {
		$protomatrix[$idx] = {
		    'undef' => [],
		    'string' => [],
		    'number' => {},
		    'class' => {},
		    'mystery' => []
		};
	    }

	    my %x;

	    for my $idx (@{$argcnt[$i]}) {
		source "\n";
		source i."// idx: ".($idx+1)."\n";
		my $x = 0;
		for my $arg (@{$protos->[$idx]{'Arguments'}}[0..($i-1)]) {
		    next if $arg =~ /\{\s*\@/;
		    my $info = $protomatrix[$x++];
		    my $type = group_of_type($arg);
#print "got $type of $arg\n" if $v;
		    source i."// $type\n";

		    $x{$idx+1}++;

		    if($type eq 'int') {
			push @{$info->{'number'}{'int'}}, $idx+1;
		    } elsif($type eq 'float') {
			push @{$info->{'number'}{'float'}}, $idx+1;
		    } elsif($type eq 'bool') {
			push @{$info->{'number'}{'bool'}}, $idx+1;
		    } elsif($type eq 'string') {
			push @{$info->{'undef'}}, $idx+1;
			push @{$info->{'string'}}, $idx+1;
		    } elsif($type eq 'class') {
			push @{$info->{'undef'}}, $idx+1 unless $arg =~ /\&\s*$/;
			my $class = $arg;
			$class =~ s/^\s*(?:const\s+)?(\w+).*$/$1/;
			push @{$info->{'class'}{$class}}, $idx+1;
		    } elsif($type eq 'unknown') {
			push @{$info->{'mystery'}}, $idx+1;
		    }
#		    } else {
#			$x{$idx+1}--;
#		    }
		}
	    }

	    for my $idx (0..$#protomatrix) {
		local($") = ', ';
		my $pm = $protomatrix[$idx];

		source i."// \$info[$idx] = {\n";
		source i."//     'undef' => [@{$pm->{'undef'}}],\n";
		source i."//     'string' => [@{$pm->{'string'}}],\n";
		my $x = 0;
		source i."//     'number' => {";
		for my $number (sort keys %{$pm->{'number'}}) {
		    source ", " if $x++ > 0;
		    source "'$number' => [@{$pm->{'number'}{$number}}]";
		}
		source "},\n";

		$x = 0;
		source i."//     'class' => {";
		for my $class (sort keys %{$pm->{'class'}}) {
		    source ", " if $x++ > 0;
		    source "'$class' => [@{$pm->{'class'}{$class}}]";
		}
		source "},\n";
		source i."//     'mystery' => [@{$pm->{'mystery'}}]\n";

		source i."// };\n";

	    }

	    $Method = $protos->[0]{'Name'};
	    branching_conditional(\@protomatrix, ($Method eq 'new') ? 1 : 0, \%x);

	    $Indent--;
	    source i."}\n";
	}
    }
}

sub write_perl_methods {
    my @methods;

    source "static PIG_PROTO(PIG_${Class}_continue) {\n";
    source "    PIG_BEGIN(PIG_${Class}_continue);\n";
    source "    pig_object_continue();\n";
    source "    PIG_END;\n";
    source "}\n\n";
    push @methods, 'continue';
    source "static PIG_PROTO(PIG_${Class}_break) {\n";
    source "    PIG_BEGIN(PIG_${Class}_break);\n";
    source "    pig_object_break();\n";
    source "    PIG_END;\n";
    source "}\n\n";
    push @methods, 'break';

    for my $meth (sort newfirst keys %{$Methods{$Class}}) {
	my @protos;
	for my $proto (@{$Methods{$Class}{$meth}}) {
	    push @protos, $proto
		unless #$proto->variable ||
		       $proto->private  ||
#		       $proto->{'Code'} || 
#		       !$proto->everylang;
		       $proto->cpponly;
	}
	my $protocnt = scalar(@protos);
	next if $protocnt == 0;
	push @methods, $meth;

	if($Methods{$Class}{$meth}[0]->destructor &&
	   $Methods{$Class}{$meth}[0]->public) {
	    source "static PIG_PROTO(PIG_${Class}_delete) {\n";
	    source "    PIG_BEGIN(PIG_${Class}_delete);\n";
	    source "    $Class * pig0 = ($Class *)pig_type_object_destructor_argument(\"$Class\");\n";
	    source "    PIG_END_ARGUMENTS;\n\n";
	    source "    delete pig0;\n\n";
	    source "    pig_return_nothing();\n";
	    source "    PIG_END;\n";
	    source "}\n\n";
	    push @methods, 'delete';
	}
	my $polymorph = ($protocnt > 1);
	my $poly = 1;

	source "static PIG_PROTO(PIG_${Class}_$meth) {\n";
	source "    PIG_BEGIN(PIG_${Class}_$meth);\n";
	if($meth eq 'new') {
	    source "    const char *pigclass = pig_type_cstring_argument();\n";
	}

	if($polymorph) {
	    source "\n";
	    source "    int pigs = 0;\n";
	    source "    int pigc = pig_argumentcount();\n\n";
	    $Indent = 1;
	    write_whichproto(\@protos);
	    source "    switch(pigs) {\n";
	}
	$Indent = $polymorph ? 3 : 1;
	for my $proto (@protos) {
	    if($polymorph) {
		source "    case $poly:\n\t{\n";
		$poly++;
	    }
	    write_proto_method($proto);
	    if($polymorph) {
		source "\t}\n";
		source "\tbreak;\n";
	    }
	}
	if($polymorph) {
	    source "    default:\n";
	    source qq{\tpig_ambiguous("$Class", "$protos[0]{'Name'}");\n\tbreak;\n};
	    source "    }\n";
	}
	source "    PIG_END;\n";
	source "}\n\n";
    }
    export "extern pig_method PIG_${Class}_methods[];\n";
    source "pig_method PIG_${Class}_methods[] = {\n";
    for my $meth (sort newfirst @methods) {
	source "    { \"$meth\", PIG_PROTONAME(PIG_${Class}_$meth) },\n";
    }
    source "    { 0, 0 }\n";
    source "};\n\n";
}

sub write_isa {
    export "extern const char *PIG_${Class}_isa[];\n";
    source "const char *PIG_${Class}_isa[] = { ";
    for my $super (info->inherit) { source qq{"$super", } if $Info{$super}->class }
    source "0 };\n\n";
}

sub supernames {
    my $class = shift;
    my $array = shift;
    return if exists $Info{$class}{'Class'} && !$Info{$class}{'Class'};
    push @$array, $class;
    return unless exists $Info{$class}{'Inherit'};
    for my $super ($Info{$class}->inherit) {
        supernames($super, $array);
    }
}

sub write_typecast {
    my $direction = shift;
    export "extern void *PIG_${Class}_${direction}cast(const char *, void *);\n";
    source "void *PIG_${Class}_${direction}cast(const char *pig0, void *pig1) {\n";
    my @super;
    supernames($Class, \@super);
    push @super, "virtual" if info->virtual;
    source "    const char *pig_super[] = { ";
    for my $super (@super) {
	source qq{"$super", };
    }
    source "0 };\n\n";

    source "    if(!pig0) return pig1;\n";
    source "    switch(pig_find_in_array(pig0, pig_super)) {\n";
    my $x = 0;
    for my $super (@super) {
	source "\tcase $x: return (void *)";
	if($direction eq 'from') {
	    if($super eq 'virtual') {
		source "($Class *)(pig_enhanced_$Class *)(((pig_virtual *)pig1)->pig_this);\n";
	    } else {
		source "($Class *)($super *)pig1;\n";
	    }
	} else {
	    if($super eq 'virtual') {
		source "(pig_virtual *)(pig_virtual_$Class *)(pig_enhanced_$Class *)($Class *)";
	    } else {
		source "($super *)($Class *)";
	    }
	    source "pig1;\n";
	}
	$x++;
    }
    source "\tdefault: return 0;\n";
    source "    }\n";

    source "}\n\n";
}

sub write_constants {
#    for my $constant ($Info{$Class}->export) {
#	if($constant =~ /(\%|\@|\$|\&)(\w+)(.*)/) {
#	    my($type, $name, $rest) = ($1, $2, $3);
#	    my $cast = 'ulong';
#	    if($type eq '%') {
#		$cast = $1 if $rest =~ s/^{(.*?)}//;
#		export "extern pig_struct_constantdata PIG_${Class}_constant_$name\[];\n";
#		source "pig_struct_constantdata PIG_${Class}_constant_$name\[] = {\n";
#
#		$ConstantList{"PIG_${Class}_constant_$name"} = {
#		    Name => $name,
#		    Type => 'HASH',
#		    Cast => ($cast eq 'ulong') ? undef : $cast
#		};
#
#		for my $key (sort keys %{$Input{$Class}{$type}{$name}}) {
#		    source "    { \"$key\", (long)($cast)$Input{$Class}{$type}{$name}{$key} },\n";
#		}
#		source "    { 0, 0 }\n";
#		source "};\n\n";
#	    }
#	}
#    }

    my $type;
    my $c = $Info{$Class}{'Constant'};

    if(keys %$c) {
	my @int;
	my @object;
	my %list;

	for my $constant (keys %$c) {
            $type = $c->{$constant}{'Type'};
	    if($type eq 'enum') {
		push @int, $constant;
	    } elsif($type eq 'int') {
		push @int, $constant;
	    } elsif($type eq 'uint') {
		push @int, $constant;
	    } else {
                push @object, $constant;
#		print "No $constant $type\n";
	    }
	}

	if(@int) {
	    source "static struct pig_constant_int PIG_${Class}_const_int[] = {\n";
	    for my $constant (sort @int) {
		source qq~    { "$constant", (long)$Class\::$constant },\n~;
	    }
	    source "    { 0, 0 }\n";
	    source "};\n\n";

	    $list{"PIG_${Class}_const_int"} = "PIG_CONSTANT_INT";
	}
	if(@object) {
	    source "struct pig_constant_object PIG_${Class}_const_object[] = {\n";
	    for my $constant (sort @object) {
		my $t = $c->{$constant}{'Type'};
		my $n;
		my $v;

		if($t =~ /(.*\w)\s*\*\s*$/) {
		    $v = "$Class\::$constant";
		    $n = $1;
		} else {
		    if($t =~ /([\w:]+)/) {
			$n = $1;
		    } else {
			$n = $t;
		    }
		    $t = "$t*";
		    $v = "&$Class\::$constant";
		}
		unless($t =~ /^const\s+/) {
		    $t = "const $t";
		}
		source qq~    { "$constant", (void *)($t)$v, "$n" },\n~;
	    }
	    source "    { 0, 0, 0 }\n";
	    source "};\n\n";
	    $list{"PIG_${Class}_const_object"} = "PIG_CONSTANT_OBJECT";
	}

	source "struct pig_constant PIG_${Class}_const[] = {\n";
	for my $clist (keys %list) {
	    source "    { (void *)$clist, $list{$clist} },\n";
	}
	source "    { 0, 0 }\n";
	source "};\n\n";
	export "extern pig_constant PIG_${Class}_const[];\n";
    }

    $c = $Info{$Class}{'Global'};

    if(keys %$c) {
	my @int;
	my @object;

	for my $constant (keys %$c) {
            $type = exists $Types{$c->{$constant}{'Type'}} ?
		$Types{$c->{$constant}{'Type'}} : $c->{$constant}{'Type'};
	    if($type eq 'enum') {
		push @int, $constant;
	    } elsif($type eq 'int') {
		push @int, $constant;
	    } elsif($type eq 'uint') {
		push @int, $constant;
	    } else {
		push @object, $constant;
#		print "No $type $constant\n";
	    }
	}

	if(@int) {
	    source "struct pig_constant_int PIG_${Class}_global_int[] = {\n";
	    for my $constant (sort @int) {
		source qq~    { "$constant", (long)$constant },\n~;
	    }
	    source "    { 0, 0 }\n";
	    source "};\n\n";
	    export "extern pig_constant_int PIG_${Class}_global_int[];\n";
	    $ConstantList{"PIG_${Class}_global_int"} = "PIG_CONSTANT_INT";
	}
	if(@object) {
	    source "struct pig_constant_object PIG_${Class}_global_object[] = {\n";
	    for my $constant (sort @object) {
		my $t = $c->{$constant}{'Type'};
		my $n;
		my $v;

		if($t =~ /(.*\w)\s*\*\s*$/) {
		    $v = $constant;
		    $n = $1;
		} else {
		    if($t =~ /([\w:]+)/) {
			$n = $1;
		    } else {
			$n = $t;
		    }
		    $t = "$t*";
		    $v = "&$constant";
		}
		unless($t =~ /^const\s+/) {
		    $t = "const $t";
		}
		source qq~    { "$constant", (void *)($t)$v, "$n" },\n~;
	    }
	    source "    { 0, 0, 0 }\n";
	    source "};\n\n";
	    export "extern pig_constant_object PIG_${Class}_global_object[];\n";
	    $ConstantList{"PIG_${Class}_global_object"} = "PIG_CONSTANT_OBJECT";
	}
    }
}

sub write_virtual_destructor {
    source "pig_enhanced_$Class\::~pig_enhanced_$Class() {\n";
    source "    pig_object_destroy(this, (pig_virtual *)this);\n";
    source "}\n\n";
}

sub writesource {
    if(info->class) {
	write_isa;
	write_typecast('to');
	write_typecast('from');
    }
    write_constants;
    write_perl_methods;
    write_virtual_destructor if info->virtual;
    write_virtual_methods if info->virtual;
}

sub findvirtual {
    my $class = shift;
    for my $poly (keys %{$Prototypes{$class}}) {
	$Inclusive{$poly} = $Prototypes{$class}{$poly}
	    unless exists $Inclusive{$poly};
    }
    for my $super ($Info{$class}->virtual) {
	next if $super eq $class;
        findvirtual($super);
    }
}

sub getvirtual {
    %Inclusive = ();
    %Exclusive = ();
    for my $super (info->virtual) {
	next if $super eq $Class;
	findvirtual($super);
    }
    %Exclusive = %{$Prototypes{$Class}};
    for my $poly (keys %Exclusive) {
	if(exists $Inclusive{$poly}) {
	    delete $Exclusive{$poly};
	} else {
	    $Inclusive{$poly} = $Exclusive{$poly};
	}
    }
}

sub writemodule {
    my $class = shift;
    verbose "Writing $class...";

    getvirtual if info->virtual;

    startsource $class;
    writesource;
    writeheader;
    writevheader if info->virtual;
    endsource $class;

    delete $LinkList{$class};

    push @ClassList, $class;

    say ".";
    verbose "\n";
}

#sub main {
#    arguments(@ARGV);
#
#MODULE:
#    for my $module (@Modules) {
#	my $path = find $module;
#	next MODULE unless $path;
#	$Module = $module;
#	$Path = $path;
#
#	say "Loading $module...";
#	verbose "Loading $module...";
#
##	mklibdir;
#
#	my $srcdir = mksrcdir $module;
#	next MODULE unless $srcdir;
#	$Sourcedir = $srcdir;
#
##	next MODULE unless startmanifest;
##	next MODULE unless startmakefile;
#	next MODULE unless startmodulecode;
#	startiheader;
#
#	my(@classes) = list $path;
#
#	verbose "\n";
#
#	for my $class (@classes) {
#	    $Class = $class;
#	    readmodule $class;
#	    writemodule $class;
#	}
#	say "\n";
#
#	endiheader;
#	endmodulecode;
## endmanifest; endmakefile;
#    }
#}

sub GenerateSource {
    my(%args) = @_;
    for my $typemap (@{$args{'TYPEMAPS'}}) {
	readtypemap($typemap);
    }
    @Include = @{$args{'INCLUDE'}};
    $Sourcedir = $args{'SOURCEDIR'};
    $VirtualHeader = $args{'VIRTUALHEADER'};
    @S = (@S, @{$args{'LINK'}}) if ref $args{'LINK'};

    for my $module (@{$args{'DIR'}}) {
	$Module = $module;
	push @S, $module;
	$Module =~ s/\W+.*//;
	$Path = $module;

	say "Loading $module...";
	verbose "Loading $module...";

#	mklibdir;

#	my $srcdir = mksrcdir $module;
	mkdir($Sourcedir, 0755) unless -d $Sourcedir;

#	next MODULE unless $srcdir;
#	$Sourcedir = "src";

#	next MODULE unless startmanifest;
#	next MODULE unless startmakefile;
	next MODULE unless startmodulecode;
	startiheader;

	my(@classes) = list $Path;

	verbose "\n";

	for my $class (@classes) {
	    $Class = $class;
	    readmodule $class;
	}

	for my $class (@classes) {
	    $Class = $class;
	    writemodule $class;
	}
	say "\n";

	for my $class (keys %LinkList) {
	    $Class = $class;
	    if(info->virtual) {
		my $info = $Info{$class};
		my $ifndef;

        open VHEADER, ">$Sourcedir/pig_${class}_v.h";
        $ifndef = uc("pig_${class}_v_h");
        vheader "#ifndef $ifndef\n";
        vheader "#define $ifndef\n\n";
        if($info->virtual > 1) {
            for my $super ($info->virtual) {
                vheader qq'#include "pig_${super}_v.h"\n' if $super ne $class;
            }
            vheader "\n";
        } else {
            vheader qq'#include "$VirtualHeader"\n\n' if $info->virtual == 1;
        }

		getvirtual;
#		writevheader;
		write_virtual_methods_def;
		write_virtual_class 1;
	vheader "#endif $ifndef\n";
	close VHEADER;
	    }
	}
	endiheader;
	endmodulecode;
    }

    if(exists $args{'Source'} && ref $args{'Source'}) {
	${$args{'Source'}} = \@sourcefiles;
    }
}

1;

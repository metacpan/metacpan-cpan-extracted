package RDF::Notation3;

require 5.005_62;
use strict;
#use warnings;
use vars qw($VERSION);
use File::Spec::Functions ();
use Carp;
use RDF::Notation3::ReaderFile;
use RDF::Notation3::ReaderString;

$VERSION = '0.91';

############################################################

sub new {
    my ($class) = @_;

    my $self = {
	ansuri  => '#',
	quantif => 1,
	nIDpref	=> '_:a', # this fits to RDF:Core prefix for nodeID
    };

    bless $self, $class;
    return $self;
}


sub parse_file {
    my ($self, $path) = @_;

    $self->_define;
    
    my $fh;
    if (ref $path eq 'IO::File') {
	$fh = $path;

    } else {
	open(FILE, "$path") or $self->_do_error(2, $path);
	$fh = *FILE;
    }

    my $t = new RDF::Notation3::ReaderFile($fh);
    $self->{reader} = $t;

    $self->_document;

    close (FILE);
}


sub parse_string {
    my ($self, $str) = @_;

    $self->_define;

    my $t = new RDF::Notation3::ReaderString($str);
    $self->{reader} = $t;

    $self->_document;
}


sub anonymous_ns_uri {
    my ($self, $uri) = @_;
    if (@_ > 1) {
	$self->{ansuri} = $uri;
    } else {
	return $self->{ansuri};
    }
}

sub quantification {
    my ($self, $val) = @_;
    if (@_ > 1) {
	$self->_do_error(4, $val) 
	  unless $val == 1 || $val == 0;
	$self->{quantif} = $val;
    } else {
	return $self->{quantif};
    }
}


sub _define {
    my ($self) = @_;

    $self->{ns} = {};
    $self->{context} = '<>';
    $self->{gid} = 1;
    $self->{cid} = 1;
    $self->{hardns} = {
	rdf  => ['rdf','http://www.w3.org/1999/02/22-rdf-syntax-ns#'],
	daml => ['daml','http://www.daml.org/2001/03/daml+oil#'],
	log  => ['log','http://www.w3.org/2000/10/swap/log.n3#'],
	};
    $self->{keywords} = [];
}


sub _document {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">doc starts: $next\n";
    if ($next ne ' EOF ') {
	$self->_statement_list;
    }
    #print ">end\n";
}


sub _statement_list {
    my ($self) = @_;
    my $next = $self->_eat_EOLs;
    #print ">statement list: $next\n";

    while ($next ne ' EOF ') {
	if ($next =~ /^(?:|#.*)$/) {
	    $self->_space;

	} elsif ($next =~ /^}/) {
	    #print ">end of nested statement list: $next\n";
	    last;

	} else {
	    $self->_statement;	    
	}
	$next = $self->_eat_EOLs;
    }
    #print ">end of statement list: $next\n";
}


sub _space {
    my ($self) = @_;
    #print ">space: ";

    my $tk = $self->{reader}->get;
    # comment or empty string
    while ($tk ne ' EOL ') {
	#print ">$tk ";
	$tk = $self->{reader}->get;
    }
    #print ">\n";
}


sub _statement {
    my ($self, $subject) = @_;
    my $next = $self->{reader}->try;
    #print ">statement starts: $next\n";

    if ($next =~ /^\@prefix|\@keywords|bind$/) {
	$self->_directive;
	
    } else {
	$subject = $self->_node unless $subject;
	#print ">subject: $subject\n";

	my $properties = [];
	$self->_property_list($properties);

	#print ">CONTEXT: $self->{context}\n";
	#print ">SUBJECT: $subject\n";
	#print ">PROPERTY: void\n" unless @$properties;
	#foreach (@$properties) { # comment/uncomment by hand
	    #print ">PROPERTY: ", join('-', @$_), "\n";
	#}

	$self->_process_statement($subject, $properties) if @$properties;
    }
    # next step
    $next = $self->_eat_EOLs;
    if ($next eq '.') {
	$self->{reader}->get;
    } elsif ($next =~ /^\.(.*)$/) {
	$self->{reader}->get;
	unshift @{$self->{reader}->{tokens}}, $1;
    } elsif ($next =~ /^(?:\]|\)|\})/) {
    } else {
	$self->_do_error(115,$next);
    }
}
 

sub _node {
    my ($self) = @_;
    my $next = $self->_eat_EOLs;
    #print ">node: $next\n";

    if ($next =~ /^[\[\{\(]/) {
	#print ">node is anonnode\n";
	return $self->_anonymous_node;

    } elsif ($next eq 'this') {
	#print ">this\n";
	$self->{reader}->get;
	return "$self->{context}";
	
    } elsif ($next =~ /^(<[^>]*>|^(?:[_a-zA-Z]\w*)?:[_a-zA-Z][_\w]*)(.*)$/) {
	#print ">node is uri_ref2: $next\n";

	if ($2) {
	    $self->{reader}->get;
	    unshift @{$self->{reader}->{tokens}}, $2;
	    unshift @{$self->{reader}->{tokens}}, $1;
	    #print ">cleaned uri_ref2: $1\n";
	}
	return $self->_uri_ref2;

    } elsif ($self->{keywords}[0] && ($next =~ /^(^[_a-zA-Z][_\w]*)(.*)$/)) {
	#print ">node is uri_ref_kw: $next\n";

	$self->{reader}->get;
	unshift @{$self->{reader}->{tokens}}, $2 if $2;
	unshift @{$self->{reader}->{tokens}}, ':' . $1;
	#print ">cleaned uri_ref2: $1\n";
	return $self->_uri_ref2;

    } else {
	#print ">unknown node: $next\n";
	$self->_do_error(116,$next);
    }
}


sub _directive {
    my ($self) = @_;
    my $tk = $self->{reader}->get;
    #print ">directive: $tk\n";

    if ($tk eq '@prefix') {
	my $tk = $self->{reader}->get;
	if ($tk =~ /^([_a-zA-Z]\w*)?:$/) {
	    my $pref = $1;
	    #print ">nprefix: $pref\n" if $pref;

	    my $ns_uri = $self->_uri_ref2;
	    $ns_uri =~ s/^<(.*)>$/$1/;

	    if ($pref) {
		$self->{ns}->{$self->{context}}->{$pref} = $ns_uri;
	    } else {
		$self->{ns}->{$self->{context}}->{''} = $ns_uri;
	    }
	} else {
	    $self->_do_error(102,$tk);	    
	}

    } elsif ($tk eq '@keywords') {
	my $kw = $self->{reader}->get;
	while ($kw =~ /,$/) {
	    $kw =~ s/,$//;
	    push @{$self->{keywords}}, $kw;
	    $kw = $self->{reader}->get;
	}

	if ($kw =~ /^(.+)\.$/) {
	    push @{$self->{keywords}}, $1;
	    unshift @{$self->{reader}{tokens}}, '.';
	} else {
	    $self->_do_error(117,$tk);
	}
	#print ">keywords: ", join('|', @{$self->{keywords}}), "\n";

    } else {
	$self->_do_error(101,$tk);
    }
}


sub _uri_ref2 {
    my ($self) = @_;

    # possible end of statement, a simple . check is done
    my $next = $self->{reader}->try;
    if ($next =~ /^(.+)\.$/) {
	$self->{reader}->{tokens}->[0] = '.';
	unshift @{$self->{reader}->{tokens}}, $1;
    }

    my $tk = $self->{reader}->get;
    #print ">uri_ref2: $tk\n";

    if ($tk =~ /^<[^>]*>$/) {
	#print ">URI\n";
	return $tk;

    } elsif ($tk =~ /^([_a-zA-Z]\w*)?:[a-zA-Z]\w*$/) {
	#print ">qname ($1:)\n" if $1;

	my $pref = '';
	$pref = $1 if $1;
	if ($pref eq '_') { # workaround to parse N-Triples
	    $self->{ns}->{$self->{context}}->{_} = $self->{ansuri}
		unless $self->{ns}->{$self->{context}}->{_};
	}

	# Identifier demunging
	$tk = _unesc_qname($tk) if $tk =~ /_/;
	return $tk;

    } else {
	$self->_do_error(103,$tk);
    }
}


sub _property_list {
    my ($self, $properties) = @_;
    my $next = $self->_eat_EOLs;
    #print ">property list: $next\n";

    $next = $self->_check_inline_comment($next);

    if ($next =~ /^:-/) {
	#print ">anonnode\n";
	# TBD
	$self->_do_error(199, $next);

    } elsif ($next =~ /^\./) {
	#print ">void prop_list\n";
	# TBD

    } else {
	#print ">prop_list with verb\n";
	my $property = $self->_verb;
	#print ">property is back: $property\n";

	my $objects = [];
	$self->_object_list($objects);
	unshift @$objects, $property;
	unshift @$objects, 'i' if ($next eq 'is' or $next eq '<-');
	#print ">inverse mode\n" if ($next eq 'is' or $next eq '<-');
	push @$properties, $objects;
    }
    # next step
    $next = $self->_eat_EOLs;
    if ($next eq ';') {
	$self->{reader}->get;
	$self->_property_list($properties);
    }
}


sub _verb {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">verb: $next\n";

    if ($next eq 'has') {
	$self->{reader}->get;
	return $self->_node;

    } elsif ($next eq '>-') {
	$self->{reader}->get;
	my $node = $self->_node;
	my $tk = $self->{reader}->get;
	$self->_do_error(104,$tk) unless $tk eq '->';	    
	return $node;

    } elsif ($next eq 'is') {
	$self->{reader}->get;
	my $node = $self->_node;
	my $tk = $self->{reader}->get;
	$self->_do_error(109,$tk) unless $tk eq 'of';
	return $node;

    } elsif ($next eq '<-') {
 	$self->{reader}->get;
 	my $node = $self->_node;
 	my $tk = $self->{reader}->get;
 	$self->_do_error(110,$tk) unless $tk eq '-<';	    
 	return $node;

    } elsif ($next eq 'a') {
	$self->{reader}->get;
	return $self->_built_in_verb('rdf','type');
#	return '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>'

    } elsif ($next =~ /^=(.*)/) {
	$self->{reader}->get;
	unshift @{$self->{reader}->{tokens}}, $1 if $1;
	return $self->_built_in_verb('daml','equivalentTo');
#	return '<http://www.daml.org/2001/03/daml+oil#equivalentTo>';

    } else {
	#print ">property: $next\n";
	return $self->_node;
    }
}


sub _object_list {
    my ($self, $objects) = @_;
    my $next = $self->_eat_EOLs;
    #print ">object list: $next\n";

    $next = $self->_check_inline_comment($next);

    # possible end of entity, check for sticked next char is done
    while ($next =~ /^([^"]+)([,;\.\}\]\)])$/) {
	$self->{reader}->{tokens}->[0] = $2;
	unshift @{$self->{reader}->{tokens}}, $1;
	$next = $1;
    }

    my $obj = $self->_object;
    #print ">object is back: $obj\n";
    push @$objects, $obj;

    # next step
    $next = $self->_eat_EOLs;
    if ($next eq ',') {
	$self->{reader}->get;
	$self->_object_list($objects);
    }
}


sub _object {
    my ($self) = @_;
    my $next = $self->_eat_EOLs;
    #print ">object: $next:\n";

    if ($next =~ /^("(?:\\"|[^\"])*")([\.;,\]\}\)])*$/) {
	#print ">complete string1: $next\n";
	my $tk = $self->{reader}->get;
	unshift @{$self->{reader}->{tokens}}, $2 if $2;
	return $self->_unesc_string($1);

    } else {
	#print ">object is node: $next\n";
	$self->_node;
    }
}


sub _anonymous_node {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    $next =~ /^([\[\{\(])(.*)$/;
    #print ">anonnode1: $1\n";
    #print ">anonnode2: $2\n";

    $self->{reader}->get;
    unshift @{$self->{reader}->{tokens}}, $2 if $2;

    if ($1 eq '[') {
	#print ">anonnode: []\n";
	my $genid = "<$self->{ansuri}g_$self->{gid}>";
	$self->{gid}++;

	$next = $self->_eat_EOLs;
	if ($next =~ /^\](.)*$/) {
	    $self->_exist_quantif($genid);
	} else {
	    $self->_exist_quantif($genid);
	    $self->_statement($genid);	    
	}

	# next step
	$next = $self->_eat_EOLs;
	my $tk = $self->{reader}->get;
	if ($tk =~ /^\](.+)$/) {
	    unshift @{$self->{reader}->{tokens}}, $1;
	} elsif ($tk ne ']') {
	    $self->_do_error(107, $tk);
	}
	return $genid;

    } elsif ($1 eq '{') {
	#print ">anonnode: {}\n";
	my $genid = "<$self->{ansuri}c_$self->{cid}>";
	$self->{cid}++;

	# ns mapping is passed to inner context
	$self->{ns}->{$genid} = {};
	foreach (keys %{$self->{ns}->{$self->{context}}}) {
	    $self->{ns}->{$genid}->{$_} = 
	      $self->{ns}->{$self->{context}}->{$_};
	    #print ">prefix '$_' passed to inner context\n";
	}

	my $parent_context = $self->{context};
	$self->{context} = $genid;
	$self->_exist_quantif($genid); # quantifying the new context
	$self->_statement_list;        # parsing nested statements
	$self->{context} = $parent_context;

	# next step
	$self->_eat_EOLs;
 	my $tk = $self->{reader}->get;
	#print ">next token: $tk\n";
	if ($tk =~ /^\}([,;\.\]\}\)])?$/) {
	    unshift @{$self->{reader}->{tokens}}, $1 if $1;
	} else {
	    $self->_do_error(108, $tk);
	}
	return $genid;

    } else {
	#print ">anonnode: ()\n";
	my $next = $self->_eat_EOLs;

#	if ($next =~ /^\)([,;\.\]\}\)])*$/) {
	if ($next =~ /^\)(.*)$/) {
	    #print ">void ()\n";
	    $self->{reader}->get;
	    unshift @{$self->{reader}->{tokens}}, $1 if $1;
	    return $self->_built_in_verb('daml','nil');
	    
	} else {

	    #print ">anonnode () starts: $next\n";
	    my @nodes = ();
 	    until ($next =~ /^.*\)[,;\.\]\}\)]*$/) {
		push @nodes, $self->_object;
 		$next = $self->_eat_EOLs;
 	    }
	    if ($next =~ /^([^)]*)\)([,;\.\]\}\)]*)$/) {
		$self->{reader}->get;
		unshift @{$self->{reader}->{tokens}}, $2 if $2;
		unshift @{$self->{reader}->{tokens}}, ')';
		if ($1) {
		    unshift @{$self->{reader}->{tokens}}, $1;
		    push @nodes, $self->_object;
		}
		$self->{reader}->get;
	    }
	    my $pref = $self->_built_in_verb('daml','');

	    my $i = 0;
	    my @expnl = (); # expanded node list
	    foreach (@nodes) {
		$i++;
		push @expnl, '[';
		push @expnl, $pref . 'first';
		push @expnl, $_;
		push @expnl, ';';
		push @expnl, $pref . 'rest';
		push @expnl, $pref . 'nil' 
		  if $i == scalar @nodes;
	    }
	    for (my $j = 0; $j < $i; $j++) {push @expnl, ']'}
	    unshift @{$self->{reader}->{tokens}}, @expnl;
	    my $exp = join(' ', @expnl);
	    #print ">expanded: $exp\n";
	    my $genid = $self->_anonymous_node;
	    return $genid;
	}
    }
}

########################################
# utils

sub _exist_quantif {
    my ($self, $anode) = @_;

    if ($self->{quantif}) {
	my $qname = $self->_built_in_verb('log','forSome');
	#print ">existential quantification: $anode\n";
	#print ">CONTEXT: $self->{context}\n";
	#print ">SUBJECT: $self->{context}\n";
	#print ">PROPERTY: $qname";
	#print ">-$anode\n";
	$self->_process_statement($self->{context}, 
		[[$qname, $anode]]);
    }
}


sub _eat_EOLs {
    my ($self) = @_;

    my $next = $self->{reader}->try;
    while ($next eq ' EOL ') {
	$self->{reader}->get;
	$next = $self->{reader}->try;
    }
    return $next;
}


# comment inside a list
sub _check_inline_comment {
    my ($self, $next) = @_;

    if ($next =~ /^#/) { 
	$self->_space;
	$next = $self->_eat_EOLs;
    }
    return $next;
}


sub _built_in_verb {
    my ($self, $key, $verb) = @_;

    # resolves possible NS conflicts
    my $i = 1;
    while ($self->{ns}->{$self->{context}}->{$self->{hardns}->{$key}->[0]} and
	   $self->{ns}->{$self->{context}}->{$self->{hardns}->{$key}->[0]} ne 
	   $self->{hardns}->{$key}->[1]) {

	$self->{hardns}->{$key}->[0] = "$key$i";
	$i++;
    }
    # adds prefix-NS binding
    $self->{ns}->{$self->{context}}->{$self->{hardns}->{$key}->[0]} = 
      $self->{hardns}->{$key}->[1];

    return "$self->{hardns}->{$key}->[0]:$verb";
}


sub _unesc_qname {
    my $qname = shift;

    #print ">escaped qname: $qname\n";
    my $i = 0;
    my @unesc = ();
    while ($qname =~ /(__+)/) {
	my $res = substr(sprintf("%b", length($1) + 1), 1);
	$res =~ s/1/-/g;
	$res =~ s/0/_/g;
	$qname =~ s/__+/<$i>/;
	push @unesc, $res;
	$i++;
    }
    for ($i=0; $i<@unesc; $i++) { $qname =~ s/<$i>/$unesc[$i]/; }
    #print ">unescaped qname: $qname\n";
    return $qname;
}


sub _unesc_string {
    my ($self, $str) = @_;

    $str =~ s/\\\n//go;
    $str =~ s/\\\\/\\/go;
    $str =~ s/\\'/'/go;
    $str =~ s/\\"/"/go;
    $str =~ s/\\n/\n/go;
    $str =~ s/\\r/\r/go;
    $str =~ s/\\t/\t/go;
    $str =~ s/\\u([\da-fA-F]{4})/pack('U',hex($1))/ge;
    $str =~ s/\\U00([\da-fA-F]{6})/pack('U',hex($1))/ge;
    $str =~ s/\\([\da-fA-F]{3})/pack('C',oct($1))/ge; #deprecated
    $str =~ s/\\x([\da-fA-F]{2})/pack('C',hex($1))/ge; #deprecated
    
    return $str;
}

########################################

sub _do_error {
    my ($self, $n, $tk) = @_;

    my %msg = (
	1   => 'file not specified',
	2   => 'file not found',
	3   => 'string not specified',
	4   => 'invalid parameter of quantification method (0|1)',

	101 => 'bind directive is obsolete, use @prefix instead',
	102 => 'invalid namespace prefix',
	103 => 'invalid URI reference (uri_ref2)',
	104 => 'end of verb (->) expected',
	105 => 'invalid characters in string1',
	106 => 'namespace prefix not bound',
	107 => 'invalid end of anonnode, ] expected',
	108 => 'invalid end of anonnode, } expected',
	109 => 'end of verb (of) expected',
	110 => 'end of verb (-<) expected',
	111 => 'string1 ("...") is not terminated',
	112 => 'invalid characters in string2',
	113 => 'string2 ("""...""")is not terminated',
	114 => 'string1 ("...") can\'t include newlines',
	115 => 'end of statement expected',
	116 => 'invalid node',
	117 => 'last keyword expected',
	199 => ':- token not supported yet',

	201 => '[Triples] attempt to add invalid node',
	202 => '[Triples] literal not allowed as subject or predicate',

	#301 => '[SAX] systemID source not implemented',       
	302 => '[SAX] characterStream source not implemented',       

	401 => '[XML] unable to convert URI predicate to QName',
	402 => '[XML] subject not recognized - internal error',

	501 => '[RDFCore] literal not allowed as subject',
	502 => '[RDFCore] valid storage not specified',
	503 => '[RDFStore] literal not allowed as subject',
	);

    my $msg = "[Error $n]";
    $msg .= " line $self->{reader}->{ln}, token" if $n > 100;
    $msg .= " \"$tk\"\n";
    $msg .= "$msg{$n}!\n";
    croak $msg;
}


1;









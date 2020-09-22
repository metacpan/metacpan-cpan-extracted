# $Id: Config.pm,v 1.40 2009-04-08 12:58:11 mike Exp $

package Net::Z3950::DBIServer::Config;
use IO::File;
use Carp;
use strict;


=head1 NAME

Net::Z3950::DBIServer::Config - Configuration file parser for DBIServer

=head1 SYNOPSIS

	use Net::Z3950::DBIServer::Config;
	$config = new Net::Z3950::DBIServer::Config($configFile);

=head1 DESCRIPTION

This module parses configuration files for the
C<Net::Z3950::DBIServer> module.  I can't begin to imagine why anyone
who's not doing DBIServer development would be remotely interested in
the technical details of how that's done, and those people will be
reading the source rather than the documentation, so I don't propose
to write much.

The parser's a simple one-token-lookahead recursive descent parser,
similar to the one that's explained in some detail in pretty much the
first chapter of Aho, Sethi & Ullman's ``New Dragon Book'',
I<Compilers: Principles, Techniques and Tools>.  If you want to write
parsers of any substance, you I<have> to have this book.  It is the
absolute bible of compilers.

It was a pleasure writing the parser in Perl - it took about a tenth
as long as similar ones that I've written in C in the past (i.e. a
couple of hours) and that includes the lexer which, to my delight,
turned out to be thirty (count 'em!) lines of code.

I'm not going to insult your intelligence by documenting the public
methods, since the only one is the constructor, whose synopsis above
tells you all you need to know except that the C<$configFile>
parameter is a fileI<name>, not a fileI<handle>.  The object that it
returns is pretty much self-documenting.  Print it with
C<Data::Dumper> if you don't believe me.

=cut


sub STRING       { 500 }
sub NUMBER       { 501 }
sub SYMBOL       { 502 }
sub DATABASE     { 503 }
sub SEARCH       { 504 }
sub ACCESS       { 505 }
sub ATTR         { 506 }
sub ATTRSET      { 507 }
sub DATA         { 508 }
sub COLUMN       { 509 }
sub FORMAT       { 510 }
sub GRS1         { 511 }
sub XML          { 512 }
sub RECORD       { 513 }
sub DATASOURCE   { 514 }
sub CACHESIZE    { 515 }
sub TABLE        { 516 }
sub FIELD        { 517 }
sub AUXILIARY    { 518 }
sub WITH         { 519 }
sub USERNAME     { 520 }
sub PASSWORD     { 521 }
sub ATTRS        { 522 }
sub RESTRICTION  { 523 }
sub TRANSFORM    { 524 }
sub MARC         { 525 }
sub DEFAULTATTRS { 526 }
sub FULLTEXT     { 527 }
sub SUTRS        { 528 }
sub SCHEMA       { 529 }
sub JOIN         { 530 }
sub UPPERCASE    { 531 }
sub OPTION       { 532 }


sub new {
    my $class = shift();
    my($filename) = @_;

    if (!defined $filename) {
	print STDERR "$class: configuration file not specified\n";
	return undef;	
    }

    my @s = stat($filename) or die "can't stat '$filename': $!";
    my $mtime = $s[9];
    my $fh = new IO::File("<$filename");
    if (!defined $fh) {
	print STDERR "$class: can't open '$filename': $!\n";
	return undef;	
    }

    ### Should probably be a class with accessor methods
    my $state = { class => $class,
		  filename => $filename,
		  fh => $fh,
		  buffer => '',
		  line => 0,
		  token => undef,
		  lexeme => undef };
    lex($state);
    my $config = _parse_config($state);
    $config->{"*timeStamp"} = $mtime;
    return $config;
}


# PRIVATE to the new() method
sub _parse_config {
    my($state) = @_;

    my $config = [];
    my($dataSource, $userName, $passWord, %options);

    while (defined $state->{token}) {
	if ($state->{token} == DATASOURCE) {
	    fatal($state, "multiple dataSources specified")
		if defined $dataSource;
	    match($state, DATASOURCE);
	    match($state, ord("="));
	    $dataSource = parse_string($state);
	} elsif ($state->{token} == USERNAME) {
	    fatal($state, "multiple userNames specified")
		if defined $userName;
	    match($state, USERNAME);
	    match($state, ord("="));
	    $userName = parse_string($state)
	} elsif ($state->{token} == PASSWORD) {
	    fatal($state, "multiple passWords specified")
		if defined $passWord;
	    match($state, PASSWORD);
	    match($state, ord("="));
	    $passWord = parse_string($state);
	} elsif ($state->{token} == OPTION) {
	    match($state, OPTION);
	    my $name = parse_string($state);
	    match($state, ord("="));
	    my $value;
	    if ($state->{token} == NUMBER) {
		$value = $state->{lexeme};
		match($state, NUMBER);
	    } else {
		$value = parse_string($state);
	    }
	    $options{$name} = $value;
	} else {
	    push @$config, parse_perDB($state);
	}
    }

    my $hashref = { map { $_->{dbname}, $_ } @$config };

    # Treat dataSource, userName and passWord as special database names
    $hashref->{"*dataSource"} = $dataSource
	or fatal($state, "no dataSource specified");
    $hashref->{"*userName"} = $userName
	if defined $userName;
    $hashref->{"*passWord"} = $passWord
	if defined $passWord;
    $hashref->{"*options"} = \%options
	if %options;

    return bless $hashref, $state->{class};
}


sub parse_perDB {
    my($state) = @_;

    match($state, DATABASE);
    my $dbname = parse_string($state);
    match($state, ord("{"));

    my($tableName, @auxiliary, $restriction, $join, $searchSpec, $dataSpec);
    while ($state->{token} != ord("}")) {
	if ($state->{token} == TABLE) {
	    fatal($state, "multiple table specifications")
		if defined $tableName;
	    match($state, TABLE);
	    match($state, ord("="));
	    $tableName = parse_string($state);
	} elsif ($state->{token} == AUXILIARY) {
	    match($state, AUXILIARY);
	    my $linkName = parse_string($state);
	    match($state, WITH);
	    my $cond = parse_string($state);
	    push @auxiliary, bless({ tableName => $linkName, cond => $cond },
				   $state->{class} . '::AuxSpec');
	} elsif ($state->{token} == RESTRICTION) {
	    fatal($state, "multiple restriction specifications")
		if defined $restriction;
	    match($state, RESTRICTION);
	    match($state, ord("="));
	    $restriction = parse_string($state);
	} elsif ($state->{token} == JOIN) {
	    fatal($state, "multiple join specifications")
		if defined $join;
	    match($state, JOIN);
	    match($state, ord("="));
	    $join = parse_string($state);
	    fatal($state, "unrecognised join specification '$join'")
		if !grep { $join eq $_ } qw(implicit outer);
	} elsif ($state->{token} == SEARCH) {
	    fatal($state, "multiple search sections") if defined $searchSpec;
	    $searchSpec = parse_searchSpec($state);
	} elsif ($state->{token} == DATA) {
	    fatal($state, "multiple data sections") if defined $dataSpec;
	    $dataSpec = parse_dataSpec($state);
	} else {
	    # We know this will fail: match(0) always will.
	    match($state, 0, "SEARCH or DATA section");
	}
    }
    match($state, ord("}"));

    return bless {
	dbname => $dbname,
	tablename => $tableName,
	auxiliary => \@auxiliary,
	restriction => $restriction,
	join => $join,
	searchSpec => $searchSpec,
	dataSpec => $dataSpec,
    }, $state->{class} . '::PerDB';
}


sub parse_searchSpec {
    my($state) = @_;

    match($state, SEARCH);
    my $attrsets = [];
    if ($state->{token} == ord("{")) {
	# Multiple attribute-set specifications
	match($state, ord("{"));
	while ($state->{token} != ord("}")) {
	    push @$attrsets, parse_attrsetSpecOrDefaultAttrs($state);
	}
	match($state, ord("}"));
    } else {
	# Single attribute-set specification
	push @$attrsets, parse_attrsetSpecOrDefaultAttrs($state);
    }

    # Now turn the list of lists into a hash keyed on attrset/type
    my $hashref;
    foreach my $attrset (@$attrsets) {
	if ($attrset->isa($state->{class} . '::DefaultAttrs')) {
	    $hashref->{"*defaultattrs"} = $attrset;
	    next;
	}
	my $oid = $attrset->{attrset};
	foreach my $ap (@{ $attrset->{specs} }) {
	    $ap->{attrset} = $oid;
	    $hashref->{"$oid:" . $ap->{accesspoint}} = $ap;
	}
    }

    return bless $hashref, $state->{class} . '::SearchSpec';
}


sub parse_attrsetSpecOrDefaultAttrs {
    my($state) = @_;

    if ($state->{token} == DEFAULTATTRS) {
	return parse_defaultAttrs($state);
    } else {
	return parse_attrsetSpec($state);
    }
}


sub parse_defaultAttrs {
    my($state) = @_;

    match($state, DEFAULTATTRS);    
    my %attrs;

    while (1) {
	my $type = $state->{lexeme};
	match($state, NUMBER);
	match($state, ord("="));
	my $value = $state->{lexeme};
	match($state, NUMBER);
	$attrs{$type} = $value;
	last if $state->{token} != ord(",");
	match($state, ord(","));
    }

    return bless \%attrs, $state->{class} . '::DefaultAttrs';
}


sub parse_attrsetSpec {
    my($state) = @_;

    match($state, ATTRSET);
    my $attrset;
    if ($state->{token} == SYMBOL || $state->{token} == STRING) {
	# Recognise symbolic OIDs (e.g. "bib1") as well as literals.
	my $sym;
	if ($state->{token} == STRING) {
	    $sym = parse_string($state);
	} else {
	    $sym = $state->{lexeme};
	    match($state, $state->{token});
	}
	$attrset = lookup_attrset($state, $sym);
    } else {
	$attrset = [ $state->{lexeme} ];
	match($state, NUMBER, "attribute set");
	while ($state->{token} == ord(".")) {
	    match($state, ord("."));
	    push @$attrset, $state->{lexeme};
	    match($state, NUMBER);
	}
    }

    my $specs = [];
    match($state, ord("{"));
    while ($state->{token} != ord("}")) {
	push @$specs, parse_accessSpec($state);
    }
    match($state, ord("}"));

    ### I think the word "bless" in the next line shouldn't be there
    return bless { attrset => join('.', @$attrset), specs => $specs };
}


# The prefix query compiler does this with:
#	oid_value topSet = query_oid_getvalbyname (li);
#	zq->attributeSetId = yaz_oidval_to_z3950oid(o, CLASS_ATTSET, topSet);
# But those functions aren't wired out through Net::Z3950 or
# Net::Z3950::SimpleServer, so for now we need to hardwire the values.
#	### fix that bug in Net::Z3950*
#
my %_attributeSets = (
		      bib1 => 1,
		      exp1 => 2,
		      ext1 => 3,
		      ccl1 => 4,
		      gils => 5,
		      stas => 6,
		      collections => 7,
		      cimi => 8,
		      geo => 9,
		      zbig => 10,
		      util => 11,
		      xd => 12,
		      xd1 => 12,	# This is what YAZ uses
		      zthes => 13,
		      fin1 => 14,
		      dan1 => 15,
		      holdings => 16,
		      usmarc => 17,
		      bib2 => 18,
		      zeerex => 19,
		      );

sub lookup_attrset {
    my($state, $sym) = @_;

    my $orig = $sym;
    $sym =~ s/-//;
    $sym = lc($sym);
    my $val = $_attributeSets{$sym};
    fatal($state, "unrecognised attribute set '$orig'")
	if !defined $val;

    return [ 1, 2, 840, 10003, 3, $val ];
}


sub parse_accessSpec {
    my($state) = @_;

    match($state, ACCESS);
    my $accesspoint = $state->{lexeme};
    match($state, NUMBER);
    match($state, ord("="));

    my($fulltext, $uppercase);
    while (1) {
	if ($state->{token} == FULLTEXT) {
	    $fulltext = 1;
	    match($state, FULLTEXT);
	} elsif ($state->{token} == UPPERCASE) {
	    $uppercase = 1;
	    match($state, UPPERCASE);
	} else {
	    last;
	}
    }

    my $columnname = parse_string($state);
    my $spec = bless {
	accesspoint => $accesspoint,
	columnname => $columnname,
    }, $state->{class} . '::AccessSpec';
    $spec->{fulltext} = 1 if $fulltext;
    $spec->{uppercase} = 1 if $uppercase;
    return $spec;
}


sub parse_dataSpec {
    my($state) = @_;

    match($state, DATA);
    my $hashref = {};
    if ($state->{token} == ord("{")) {
	# Multiple record-syntax specifications
	match($state, ord("{"));
	while ($state->{token} != ord("}")) {
	    parse_formatSpec($state, $hashref);
	}
	match($state, ord("}"));
    } else {
	# Single record-syntax specification
	parse_formatSpec($state, $hashref);
    }

    return bless $hashref, $state->{class} . '::DataSpec';
}


# Note that this messes with %$hashref and does not return anything
sub parse_formatSpec {
    my($state, $hashref) = @_;

    # Special case: treat as a magic format-name
    if ($state->{token} == CACHESIZE) {
	match($state, CACHESIZE);
	match($state, ord("="));
	$hashref->{"*cacheSize"} = $state->{lexeme};
	match($state, NUMBER);
	return;
    }

    match($state, FORMAT);
    if ($state->{token} == GRS1) {
	match($state, GRS1);
	$hashref->{GRS1} = parse_GRS1Spec($state);
    } elsif ($state->{token} == XML) {
	match($state, XML);
	$hashref->{XML} = parse_XMLSpec($state);
    } elsif ($state->{token} == MARC) {
	match($state, MARC);
	$hashref->{MARC} = parse_XMLSpec($state);
    } elsif ($state->{token} == SUTRS) {
	match($state, SUTRS);
	$hashref->{SUTRS} = parse_XMLSpec($state);
    } else {
	match($state, GRS1, "format type: GRS1, XML, MARC or SUTRS");
    }
}


sub parse_GRS1Spec {
    my($state) = @_;

    match($state, ord("{"));
    my $specs = [];
    while ($state->{token} != ord("}")) {
	push @$specs, parse_GRS1ElementSpec($state);
    }
    match($state, ord("}"));
    return bless {
	specs => $specs,
	map => { map { $_->tagname(), $_ } @$specs },
    }, $state->{class} . '::GRS1Spec';
}


sub parse_GRS1ElementSpec {
    my($state) = @_;

    my($columnname, $tagpath);
    if ($state->{token} == COLUMN) {
	# 'column "x" = "y"' (obsolescent) is equivalent to 'field "y" = "x"'
	match($state, COLUMN);
	$columnname = parse_string($state);
	match($state, ord("="));
	$tagpath = parse_tagPath($state);
    } else {
	match($state, FIELD);
	$tagpath = parse_tagPath($state);
	match($state, ord("="));
	$columnname = parse_string($state);
    }

    return bless {
	columnname => $columnname,
	tagpath => $tagpath,
	tagname => "$tagpath",	# opaque string used as index in map
    }, $state->{class} . '::GRS1ElementSpec';
}


sub parse_tagPath {
    my($state) = @_;

    my $tags = [];
    while ($state->{token} == ord("(")) {
	match($state, ord("("));
	my $type = $state->{lexeme};
	match($state, NUMBER);
	match($state, ord(","));
	my $value;
	if ($state->{token} == NUMBER) {
	    $value = $state->{lexeme};
	    match($state, $state->{token});
	} elsif ($state->{token} == STRING) {
	    $value = parse_string($state);
	} else {
	    match($state, 0, "STRING or NUMBER tag-value");
	}
	match($state, ord(")"));
	push @$tags, [ $type, $value ];
    }
    return bless $tags, $state->{class} . '::TagPath';
}


sub parse_XMLSpec {
    my($state) = @_;

    match($state, ord("{"));
    my $specs = [];
    while ($state->{token} != ord("}")) {
	push @$specs, parse_XMLElementSpec($state);
    }
    match($state, ord("}"));
    return bless {
	specs => $specs,
	map => { map { $_->tagname(), $_ } @$specs },
    }, $state->{class} . '::XMLSpec';
}


sub parse_XMLElementSpec {
    my($state) = @_;

    my($columnname, $tagname);
    if ($state->{token} == COLUMN) {
	# 'column "x" = "y"' (obsolescent) is equivalent to 'field "y" = "x"'
	match($state, COLUMN);
	$columnname = parse_string($state);
	match($state, ord("="));
	$tagname = parse_string($state);
    } else {
	# Treat record-name, attrs and transform as special fields
	if ($state->{token} == RECORD) {
	    match($state, RECORD);
	    $tagname = "*record";
	} elsif ($state->{token} == ATTRS) {
	    match($state, ATTRS);
	    $tagname = "*attrs";
	} elsif ($state->{token} == TRANSFORM) {
	    match($state, TRANSFORM);
	    $tagname = "*transform";
	} elsif ($state->{token} == SCHEMA) {
	    match($state, SCHEMA);
	    $tagname = "*schema";
	} else {
	    match($state, FIELD);
	    $tagname = parse_string($state);
	}
	match($state, ord("="));
	$columnname = parse_string($state);
    }

    return bless {
	tagname => $tagname,
	columnname => $columnname,
    }, $state->{class} . '::XMLElementSpec';
}


sub parse_string {
    my($state) = @_;

    my $string = $state->{lexeme};
    match($state, STRING);
    # Allow concatenation of multiple strings with "+"
    while ($state->{token} == ord("+")) {
	match($state, ord("+"));
	$string .= $state->{lexeme};
	match($state, STRING);
    }
    return $string;
}


# PRIVATE to lex()
my %keywords = (database => DATABASE,
		search => SEARCH,
		access => ACCESS,
		attr => ATTR,
		attrset => ATTRSET,
		data => DATA,
		column => COLUMN,
		format => FORMAT,
		grs1 => GRS1,
		xml => XML,
		record => RECORD,
		datasource => DATASOURCE,
		cachesize => CACHESIZE,
		table => TABLE,
		field => FIELD,
		auxiliary => AUXILIARY,
		with => WITH,
		username => USERNAME,
		password => PASSWORD,
		attrs => ATTRS,
		restriction => RESTRICTION,
		transform => TRANSFORM,
		marc => MARC,
		defaultattrs => DEFAULTATTRS,
		fulltext => FULLTEXT,
		sutrs => SUTRS,
		schema => SCHEMA,
		join => JOIN,
		uppercase => UPPERCASE,
		option => OPTION,
		);

my %invert = reverse %keywords;
$invert{STRING()} = "STRING";
$invert{NUMBER()} = "NUMBER";
$invert{SYMBOL()} = "SYMBOL";


sub match {
    my($state, $token, $msg) = @_;

    if ($state->{token} != $token) {
	# Really throwing an exception
	if (defined $msg) {
	    $token = $msg;
	} else {
	    $token = "'" . ($invert{$token} || chr($token)) . "'" .
		" (" . $token . ")";
	}

	fatal($state, "expected $token, got '" . $state->{lexeme} . "'" .
	      " (" . $state->{token} . ")");
    }

    lex($state);
}


sub fatal {
    my $state = shift();

    die($state->{filename} . ":" . $state->{line} . ": " .
	join('', @_) . "\n");
}


sub lex {
    my($state) = @_;
    my $token = _lex($state);
    $state->{token} = $token;
    #warn "lexed $token (" . $state->{lexeme} . ")";
}


sub _lex {
    my($state) = @_;

    $state->{buffer} =~ s/^\s+//;
    while (!$state->{buffer}) {
	if (!defined ($state->{buffer} = $state->{fh}->getline())) {
	    return undef;
	}
	$state->{line}++;
	#warn "read line " . $state->{line} . ": " . $state->{buffer};
	$state->{buffer} =~ s/(?<!\\)#.*$//;
	$state->{buffer} =~ s/\\#/#/g;
	$state->{buffer} =~ s/\s+$//;
	$state->{buffer} =~ s/^\s+//;
    }

    my $q = '"';		# this avoids confusing emacs's Perl mode
    if ($state->{buffer} =~ s/^"([^$q]*)"//) {
	$state->{lexeme} = $1;
	# We need these special cases so we can specify a literal
	# newline in data-source names such as "DBD::CSV::csv_eol=\n"
	$state->{lexeme} =~ s/\\t/\t/g;
	$state->{lexeme} =~ s/\\n/\n/g;
	return STRING
    } elsif ($state->{buffer} =~ s/^([0-9]+)//) {
        $state->{lexeme} = $1;
	return NUMBER;
    } elsif ($state->{buffer} =~ s/^([_a-z][a-z_0-9]*)//i) {
	$state->{lexeme} = $1;
	return $keywords{lc($1)} || SYMBOL;
    }

    # Must be a single character
    $state->{buffer} =~ s/^(.)//;
    $state->{lexeme} = $1;
    return ord($1);
}

### should consider documenting access methods


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Sunday 3rd February 2002.

=head1 SEE ALSO

C<Net::Z3950::DBIServer>
is the module that uses this, and the only one that would ever want
to, I'm sure.

You might like to look at the
C<Parse::RecDescent>
module, but I didn't :-)

=cut



# And now, a few undocumented (because they're obvious) utility methods
package Net::Z3950::DBIServer::Config;

sub forDb {
    my $this = shift();
    my($dbname) = @_;

    # To make this do case-insensitive matching, we jump through some
    # rather silly hoops.
    foreach my $key (keys %$this) {
	if (lc($key) eq lc($dbname)) {
	    return $this->{$key};
	}
    }
    return undef;
}

sub dataSource { my $this = shift(); return $this->{"*dataSource"}; }
sub userName { my $this = shift(); return $this->{"*userName"}; }
sub passWord { my $this = shift(); return $this->{"*passWord"}; }
sub options { my $this = shift(); return $this->{"*options"}; }


package Net::Z3950::DBIServer::Config::PerDB;

sub dbname      { my $this = shift(); return $this->{dbname} }
sub tablename   { my $this = shift(); return $this->{tablename} }
sub auxiliary   { my $this = shift(); return $this->{auxiliary} }
sub restriction { my $this = shift(); return $this->{restriction} }
sub join        { my $this = shift(); return $this->{join} }
sub searchSpec  { my $this = shift(); return $this->{searchSpec} }
sub dataSpec    { my $this = shift(); return $this->{dataSpec} }

=head2 Net::Z3950::DBIServer::Config::PerDB::columns()

Return a list of strings, each of which is the name of one column that
should be included in SELECT statements for the database on whose
configuration object it is invoked.  It gathers these from the
information about all configured record syntaxes, and discards
``constant columns'' whose names begin with ``*''.

=cut

sub columns {
    my $this = shift();

    if (!defined $this->{columns}) {
	my $tablename = $this->tablename();
	#warn "calculating columns for '$tablename'";
	my $aux = $this->auxiliary();
	my $has_aux = (@$aux > 0) ? 1 : 0;
	my @columns;
	my %register;

	my $dataSpec = $this->dataSpec();
	my @formatNames = $dataSpec->formatNames();
	foreach my $formatName (@formatNames) {
	    foreach my $field ($dataSpec->{$formatName}->fields()) {
		my $colSpec = $field->columnName();
		foreach my $col (columnsInSpec($colSpec)) {
		    $col = "$tablename.$col" if $has_aux && $col !~ /\./;
		    if (!exists $register{$col}) {
			#warn "adding $formatName/$colSpec -> $col\n";
			push @columns, $col;
			$register{$col} = 1;
		    }
		}
	    }
	}
	$this->{columns} = [ @columns ];
	#warn "calculated " . join(', ', @{ $this->{columns} });
    }

    return @{ $this->{columns} };
}


sub columnsInSpec {
    my($spec) = @_;

    return () if $spec =~ /^\*/;
    if ($spec !~ /%/) {
	$spec =~ s/^\?//;
	return $spec;
    }

    my @cols;
    while ($spec =~ s/.*?%\{(.*?)\}//) {
	my $fieldname = $1;
	$fieldname =~ s/^\?//;
	push @cols, $fieldname;
    }

    return @cols;
}


package Net::Z3950::DBIServer::Config::AuxSpec;
sub tableName  { my $this = shift(); return $this->{tableName} }
sub cond       { my $this = shift(); return $this->{cond} }


package Net::Z3950::DBIServer::Config::SearchSpec;

sub accessPoint {
    my $this = shift();
    my($attrset, $attrval) = @_;

    return $this->{"$attrset:$attrval"};
}


package Net::Z3950::DBIServer::Config::DataSpec;

sub cacheSize {
    my $this = shift();

    my $cacheSize = $this->{"*cacheSize"};
    $cacheSize = 10 if !defined $cacheSize;
    return $cacheSize
}

sub formatNames {
    my $this = shift();

    my %formats = %$this;
    delete $formats{"*cacheSize"};
    return sort keys %formats;
}


package Net::Z3950::DBIServer::Config::FormatSpec;

sub fields {
    my $this = shift();

    my @fields = ();
    my $specs = $this->{specs};
    foreach my $field (@{ $this->{specs} }) {
	push @fields, $field
	    if $field->tagname() !~ /^\*/;
    }

    return @fields;
}

sub fieldNames {
    my $this = shift();
    Carp::confess("fieldNames($this) is deprecated\n");

    my @fields = ();
    my $specs = $this->{specs};
    foreach my $i (0..@$specs-1) {
	my $field = $specs->[$i]->tagname();
	push @fields, $field if $field !~ /^\*/;
    }

    return @fields;
}

sub fieldSpec {
    my $this = shift();
    my($field) = @_;
    Carp::confess("fieldSpec($this, '$field') is deprecated\n")
	if $field !~ /^\*/;

    return $this->{map}->{$field};
}


package Net::Z3950::DBIServer::Config::GRS1Spec;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::DBIServer::Config::FormatSpec);


package Net::Z3950::DBIServer::Config::XMLSpec;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::DBIServer::Config::FormatSpec);

sub recordName {
    my $this = shift();
    my $entry = $this->fieldSpec("*record");
    return !defined $entry ? undef : $entry->{columnname};
}

sub recordAttrs {
    my $this = shift();
    my $entry = $this->fieldSpec("*attrs");
    return !defined $entry ? undef : $entry->{columnname};
}

sub recordTransform {
    my $this = shift();
    my $entry = $this->fieldSpec("*transform");
    return !defined $entry ? undef : $entry->{columnname};
}

sub recordSchema {
    my $this = shift();
    my $entry = $this->fieldSpec("*schema");
    return !defined $entry ? undef : $entry->{columnname};
}


package Net::Z3950::DBIServer::Config::ElementSpec;

sub tagname {
    my $this = shift();
    return $this->{tagname};
}

sub columnName {
    my $this = shift();
    my($field) = @_;

    return $this->{columnname};
}


package Net::Z3950::DBIServer::Config::GRS1ElementSpec;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::DBIServer::Config::ElementSpec);

sub tagpath {
    my $this = shift();
    my($field) = @_;

    return $this->{tagpath};
}

package Net::Z3950::DBIServer::Config::XMLElementSpec;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::DBIServer::Config::ElementSpec);

1;

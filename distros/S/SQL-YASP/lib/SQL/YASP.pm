package SQL::YASP;
use Carp 'croak';
use strict;
use Tie::IxHash;
use Exporter;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# documentation at end of file

# globals
use vars qw[@ISA @EXPORT_OK %EXPORT_TAGS %StdDelimiters $defparser $VERSION $nullchar $wineof $err $errstr];
$VERSION = '0.12';

# export
@ISA = 'Exporter';
@EXPORT_OK = 
	qw[
	arr_split get_ixhash comma_split field_set_list
	ARG_STRING ARG_NONE ARG_RAW ARG_NUMERIC ARG_SENDNULLS
	OP_BETWEEN OP_LOGICAL OP_ADD OP_MULT OP_EXP OP_MISC
	];
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);


# constants
use constant SECTION_RETURN           => 0;
use constant SECTION_FIELD_SET_LIST   => 1;
use constant SECTION_COMMA_SPLIT      => 2;
use constant SECTION_EXPRESSION       => 3;
use constant SECTION_OBJECT_LIST      => 4;
use constant SECTION_ARG_LIST         => 5;
use constant SECTION_SINGLE_WORD      => 6;
use constant SECTION_TABLE_LIST       => 7;
use constant SECTION_ORDER_BY         => 8;
use constant IPOS => 3; # position of the $i argument in sql_split

# comparison types
use constant CMP_AGNOSTIC => 0;
use constant CMP_STRING   => 1;
use constant CMP_NUMBER   => 2;

# argument types
use constant ARG_STRING      => 0;
use constant ARG_NONE        => 1;
use constant ARG_RAW         => 2;
use constant ARG_NUMERIC     => 3;
use constant ARG_SENDNULLS   => 4;

# operator precedence levels
use constant OP_BETWEEN => 0;
use constant OP_LOGICAL => 1;
use constant OP_ADD     => 2;
use constant OP_MULT    => 3;
use constant OP_EXP     => 4;
use constant OP_MISC    => 5;

# braces around field names
use constant FIELD_BRACES_PROHIBIT => 0;
use constant FIELD_BRACES_ALLOW    => 1;
use constant FIELD_BRACES_REQUIRE  => 2;

# misc constants
use constant OPTSPKG => 'SQL::YASP::Opts';


# special characters
$nullchar = chr(0);
$wineof = chr(26);


#------------------------------------------------------------------------------
# new
# OVERRIDE ME
#
sub new {
	my ($class) = @_;
	my $self = bless({}, $class);
	
	# always call after_new just before returning parser object
	$self->after_new;
	
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# build_tree
# OVERRIDE ME
#
sub build_tree {
	my ($self, $stmt, $tokens, %opts) = @_;
	my ($cmd);
	
	# always set $stmt->{'command'}
	$cmd = $stmt->{'command'} = shift @$tokens;
	
	# create
	if ($cmd eq 'create')
		{$self->tree_create($stmt, @$tokens) or return undef}
	
	# select
	elsif ($cmd eq 'select')
		{$self->tree_select($stmt, @$tokens) or return undef}
	
	# insert
	elsif ($cmd eq 'insert')
		{$self->tree_insert($stmt, @$tokens) or return undef}
	
	# update
	elsif ($cmd eq 'update')
		{$self->tree_update($stmt, @$tokens) or return undef}
	
	# delete
	elsif ($cmd eq 'delete')
		{$self->tree_delete($stmt, @$tokens) or return undef}
	
	# if allow unknown command
	elsif ($opts{'allow_unknown_command'})
		{ return undef }
	
	# else don't recognize command
	else
		{croak "[1] Do not recognize command: [$stmt->{'command'}]"}
}
#
# build_tree
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_create
#
# OVERRIDE ME
#
sub tree_create {
	my ($self, $stmt, @els) = @_;
	
	# hold on to create type
	$stmt->{'create_type'} = shift(@els);
	
	# create table
	if ($stmt->{'create_type'} eq 'table')
		{return $self->tree_create_table($stmt, @els)}
	
	# else don't know this type of object
	croak "do not know how to create this type of object: $self->{'create_type'}";
}
#
# tree_create
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_create_table
# OVERRIDE ME
#
sub tree_create_table {
	my ($self, $stmt, @els) = @_;
	my ($fields);
	
	$stmt->{'table_name'} = shift @els;
	$stmt->{'fields'} = $fields = get_ixhash();
	
	FIELDLOOP:
	foreach my $field_def (comma_split(\@els)) {
		my @fieldargs = @$field_def;
		my ($field_name, $field);
		
		# if this is a command, not a field definition
		if (
			exists($self->{'non_fields'}->{'create'}) && 
			exists($self->{'non_fields'}->{'create'}->{$fieldargs[0]})
			) {
			$stmt->{'arguments'} ||= [];
			push @{$stmt->{'arguments'}}, @fieldargs;
			next FIELDLOOP;
		}
		
		# get data type
		$field = {};
		$field_name = shift @fieldargs;
		$field->{'data_type'} = {name=>shift @fieldargs};
		$field->{'modifiers'} = [];
		
		# add arguments to data type
		add_args($field->{'data_type'}, \@fieldargs);
		
		# loop through remaining arguments
		while (@fieldargs) {
			my $arg = shift @fieldargs;
			my $setting = {};
			
			# if the word is "not", then use the following word
			# as the arg name
			if ($arg eq 'not') {
				$setting->{'not'} = 1;
				$arg = shift @fieldargs;
			}
			
			add_args($setting, \@fieldargs);
			$setting->{'name'} = $arg;
			push @{$field->{'modifiers'}}, $setting;
		}
		
		# store in fields hash
		$fields->{$field_name} = $field;
	}
	
	return 1;
}
# 
# tree_create_table
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_select
#
# OVERRIDE ME
#
sub tree_select {
	my ($self, $stmt, @els) = @_;
	my ($unset);
	
	$unset = $self->get_sections(
		$stmt, \@els,
		'from'      =>  SECTION_TABLE_LIST,
		'order by'  =>  SECTION_ORDER_BY,
		'where'     =>  SECTION_EXPRESSION,
		'having'    =>  SECTION_EXPRESSION,
		'group by'  =>  SECTION_COMMA_SPLIT,
		'into'      =>  SECTION_TABLE_LIST,
	);
	
	defined($unset) or return undef;
	
	$stmt->{'fields'} = $self->tree_select_fields($stmt, $unset->{':open'});
}
# 
# tree_select
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_delete
# 
# OVERRIDE ME
# 
sub tree_delete {
	my ($self, $stmt, @els) = @_;
	my ($unset);
	
	$unset = $self->get_sections($stmt, \@els,
		'from'      =>  SECTION_TABLE_LIST,
		'where'     =>  SECTION_EXPRESSION,
	);
}
# 
# tree_delete
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_insert
# 
# OVERRIDE ME
# 
sub tree_insert {
	my ($self, $stmt, @els) = @_;
	my ($unset);
	
	$unset = $self->get_sections($stmt, \@els,
		'into'    =>  SECTION_RETURN,
		'values'  =>  SECTION_RETURN,
		'set'     =>  SECTION_FIELD_SET_LIST,
		);
	
	# into
	if ($unset->{'into'}) {
		$stmt->{'table_name'} = shift @{$unset->{'into'}};
		get_set_fields($stmt, $unset->{'into'}, $unset)
			or return undef;
	}
}
# 
# tree_insert
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_update
# 
# OVERRIDE ME
# 
sub tree_update {
	my ($self, $stmt, @els) = @_;
	my ($unset, $opener);
	
	$unset = $self->get_sections($stmt, \@els,
		'values'  =>  SECTION_RETURN,
		'where'   =>  SECTION_EXPRESSION,
		'set'     =>  SECTION_FIELD_SET_LIST,
		);
	
	$opener = $unset->{':open'};
	$stmt->{'table_name'} = shift @{$opener};
	
	# set "set" clause
	get_set_fields($stmt, $opener, $unset)
		or return undef;
}
# 
# tree_update
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# get_set_fields
# 
sub get_set_fields {
	my ($stmt, $fieldlist, $unset) = @_;
	
	# if a SET clause wasn't sent, and a VALUES clause was,
	# set "set" using values
	if ( (! $stmt->{'set'}) && $unset->{'values'} ) {
		my (%set, @fields, @exprs, $i);
		
		@fields = comma_split([deref_args($fieldlist)]);
		@exprs  = comma_split( [deref_args($unset->{'values'})] );
		$i = 0;
		
		if (@fields != @exprs) {
			SQL::YASP::Expr::set_err('invalid syntax: field list and expression list must have same number of elements');
			return undef;
		}
		
		while ($i <= $#fields) {
			$set{$fields[$i]->[0]} = SQL::YASP::Expr->new($stmt, $exprs[$i]);
			$i++;
		}
		
		$stmt->{'set'} = \%set;
	}
	
	return $stmt->{'set'};
}
# 
# get_set_fields
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_select_fields
# 
sub tree_select_fields {
	my ($self, $stmt, $clause) = @_;
	my $cc = ref($self) . '::Expr';  # clause class
	my $rv = get_ixhash();
	
	# get field list
	foreach my $fielddef (arr_split([','], $clause)) {
		my @def = @$fielddef;
		
		# single field
		if (@def == 1){
			# TODO: need to address possibility of format tablename.*
			# For now we assume that the select is from just one table.
			# 
			# If that single field is '*', and if we got a table definition hash.
			# 
			if ( ($def[0] eq '*') && $stmt->{'table_definitions'} ) {
				# Get the name of the first table.  See note above
				# for why we do this little cop-out.
				my $tablename = $stmt->{'from'}->{(keys(%{$stmt->{'from'}}))[0]};
				my $col_defs = $stmt->{'table_definitions'}->{$tablename}->{'col_defs'};
				
				foreach my $fieldname (keys %{$col_defs})
					{$rv->{$fieldname} = $cc->new($stmt, $fieldname)}
			}
			
			# else it's just the name of a table
			else
				{$rv->{$def[0]} = $cc->new($stmt, @def)}
		}
		
		# else if in format "expression as fieldname"
		elsif ( (@def >= 3) && ($def[-2] eq 'as') ) {
			my $name = pop @def;
			pop @def;
			$rv->{$name} = $cc->new($stmt, @def);
		}
		
		# else use entire string as field name
		else
			{$rv->{restring(@def)} = $cc->new($stmt, @def)}
	}
	
	return $rv;
}
# 
# tree_select_fields
#------------------------------------------------------------------------------


###############################################################################
#  IT IS NOT RECOMMENDED THAT YOU OVERRIDE ANY OF THE METHODS FROM HERE DOWN  #
###############################################################################


#------------------------------------------------------------------------------
# after_new
# 
sub after_new {
	my ($self) = @_;
	my (%quotes, %allops);
	
	# set which characters are quotes
	$self->{'quotes'} ||= ['"', "'"];
	$quotes{$_} = 1 for @{$self->{'quotes'}};
	$self->{'quotes'} = \%quotes;
	
	# tokenizer properties
	exists($self->{'lukas'})             or  $self->{'lukas'} = 1;
	exists($self->{'type_fix'})          or  $self->{'type_fix'} = 1;
	exists($self->{'perl_regex'})        or  $self->{'perl_regex'} = 1;
	exists($self->{'star_comments'})     or  $self->{'star_comments'} = 1;
	exists($self->{'dash_comments'})     or  $self->{'dash_comments'} = 1;
	exists($self->{'pound_comments'})    or  $self->{'pound_comments'} = 1;
	exists($self->{'!_is_not'})          or  $self->{'!_is_not'} = 1;
	exists($self->{'backslash_escape'})  or  $self->{'backslash_escape'} = 1;
	exists($self->{'dquote_escape'})     or  $self->{'dquote_escape'} = 1;
	exists($self->{'field_braces'})      or  $self->{'field_braces'} =  FIELD_BRACES_PROHIBIT;
	
	# double word tokens
	$self->{'double_word_tokens'} ||= {
		primary => {key=>1},
		current => {date=>1},
		order   => {by=>1},
		group   => {by=>1},
	};
	
	# operators
	$self->{'ops'} ||= \@SQL::YASP::Expr::dbin;
	
	# functions
	$self->{'functions'} ||= \%SQL::YASP::Expr::dfuncs;
	
	# hash of all operators
	foreach my $level (@{$self->{'ops'}})
		{@allops{keys %{$level}} = ()}
	$self->{'allops'} = \%allops;
	
	# operator regex
	$self->{'opregex'} = join('|', sort {length($b) <=> length($a)} map {$_=quotemeta($_)} keys %allops);
	
	# This hash of words indicates words that are not field names,
	# they are some other type of modifier.  This property is mainly
	# used by 'create table'.
	$self->{'non_fields'} ||= {
		create => {
			constraint => 1,
			unique     => 1,
			},
		};
	
	
	#---------------------------------------------------------------
	# extend Statement and Expr packages if they don't already exist
	# 
	unless ( (my $class = ref($self)) eq 'SQL::YASP') {
		my @isa;
		
		eval "\@isa = \@${class}::Statement::ISA";
		@isa or eval "\@isa = \@${class}::Statement::ISA = 'SQL::YASP::Statement'";
		@isa or croak 'did not set @isa';
		
		@isa = ();
		eval "\@isa = \@${class}::Expr::ISA";
		@isa or eval "\@isa = \@${class}::Expr::ISA = 'SQL::YASP::Expr'";
		@isa or croak 'did not set @isa';
	}
	# 
	# extend Statement and Expr packages if they don't already exist
	#---------------------------------------------------------------
	

}
#
# after_new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# parse
#
sub parse {
	my ($self, $sql, %opts) = @_;	
	my ($rv, @tokens, $carry);
	
	# create parser if one wasn't passed
	unless (ref $self) {
		$self::defparser ||= $self->new;
		$self = $self::defparser;
	}
	
	# instantiate statement object to be returned
	$rv = SQL::YASP::Statement->new();
	
	# hold on to original SQL if requested to do so
	$self->{'keep_org_sql'} and $rv->{'org_sql'} = $sql;
	
	# remove trailing semicolon
	$sql =~ s|\s*\;\s*$||s;
	
	# tokenize statement
	$carry = {placeholders=>[]};
	@tokens = $self->sql_split($sql, $carry);
	
	# get the command for this statement
	$rv->{'placeholders'} = $carry->{'placeholders'};
	$rv->{'placeholder_count'} = @{$carry->{'placeholders'}};
	$rv->{'parser'} = $self;
	$rv->{'table_definitions'} = $opts{'table_definitions'};
	
	# build statement tree
	$self->build_tree($rv, \@tokens, %opts) or return undef;
	
	# return statement object
	return $rv;
}
#
# parse
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# get_sections
#
sub get_sections {
	my ($self, $stmt, $els, %opts) = @_;
	my @clauses = arr_split([keys %opts], $els, keep_del_front=>1);
	my $rv = {};
	
	# if the first element is not a recognized command
	unless (exists $opts{$els->[0]}) {
		my $open = shift @clauses;
		$rv->{':open'} = $open;
	}
	
	# loop through sections assigning to statement
	CLAUSELOOP:
	foreach my $clause (@clauses) {
		my $sname = shift @$clause;
		
		# field set list
		if ($opts{$sname} == SECTION_FIELD_SET_LIST)
			{$stmt->{$sname} = field_set_list($stmt, $clause)}
		
		# single word
		elsif ($opts{$sname} == SECTION_SINGLE_WORD)
			{$stmt->{$sname} = $clause->[0]}
		
		# from clause
		# for now, just returns a single hash element
		elsif ($opts{$sname} == SECTION_TABLE_LIST) {
			my $tdefs = get_ixhash();
			
			foreach my $table_def (comma_split($clause)) {
				my ($key, $name);
				
				# check for expression-as-table, which is
				# out of scope
				foreach my $def (@$table_def)
					{ ref($def) and return undef }
				
				# get name
				$name = lc(shift(@{$table_def}));
				
				# if alias
				if (@{$table_def})
					{$key = $table_def->[0]}
				else
					{$key = $name}
				
				$tdefs->{$key} = $name;
			}
			
			# default $stmt->{'table_name'} to empty string
			$stmt->{'table_name'} = '';
			
			# if 'from' clause contains exactly one table,
			# put that single table into the {'table_name'} element
			if (keys(%$tdefs) == 1) {
				my ($key) = keys(%$tdefs);
				my ($val) = values(%$tdefs);
				
				if ($key eq $val) {
					$stmt->{'table_name'} = $val;
				}
			}
			
			$stmt->{$sname} = $tdefs;
		}
		
		# comma delimited list
		elsif ($opts{$sname} == SECTION_COMMA_SPLIT)
			{$stmt->{$sname} = comma_split($clause)}
		
		# comma delimited list, build into expression objects
		elsif ($opts{$sname} == SECTION_ORDER_BY){
			my $exprs = comma_split($clause);
			
			foreach my $expr (@$exprs) {
				my ($desc);
				
				if ($expr->[-1] eq 'desc') {
					$desc = 1;
					pop @$expr;
				}
				
				$expr = SQL::YASP::Expr->new($stmt, $expr);
				$expr->{'desc'} = $desc;
			}
			
			$stmt->{$sname} = $exprs;
		}
		
		# expression
		elsif ($opts{$sname} == SECTION_EXPRESSION)
			{$stmt->{$sname} = SQL::YASP::Expr->new($stmt, $clause)}
		
		# object list
		elsif ($opts{$sname} == SECTION_OBJECT_LIST)
			{$stmt->{$sname} = object_list($clause)}
		
		# argument list
		elsif ($opts{$sname} == SECTION_ARG_LIST)
			{$stmt->{$sname} = comma_split([deref_args($clause)])}
		
		# else return
		else
			{$rv->{$sname} = $clause}
	}
	
	return $rv;
}
#
# get_sections
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# field_set_list
# 
sub field_set_list {
	my ($stmt, $allsets) = @_;
	my $rv = {};
	
	foreach my $set (comma_split($allsets)) {
		my ($name, $expr) = arr_split(['='], $set, max=>2);
		# $rv->{$name->[0]} = $expr;
		$rv->{$name->[0]} = SQL::YASP::Expr->new($stmt, $expr);
	}
	
	return $rv;
}
# 
# field_set_list
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# add_args
# 
sub add_args {
	my ($field, $arr, %opts) = @_;
	my ($args);
	
	# early exit
	@{$arr} or return 0;
	ref($arr->[0]) or return 0;
	
	# default property name for arguments
	defined($opts{'arg_name'}) or $opts{'arg_name'} = 'arguments';
	
	# add arguments property
	$args = shift @{$arr};
	$field->{$opts{'arg_name'}} = $args;
	return 1;
}
# 
# add_args
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# sql_split
# 
sub sql_split {
	my ($self, $sql, $carry, $i) = @_;
	my (@rv, @major, $inquote, $inlinecomment, $instar, $allspaces, @chars, @field, $dtokens, $lastwasnum, $inregex);
	my %quotes = %{$self->{'quotes'}};
	my $opregex = $self->{'opregex'};
	
	# values that are carried through recursions
	$carry ||= {};
	$carry->{'placeholders'} ||= [];
	
	# split entire string into single characters
	@chars = ref($sql) ? @$sql : split('', $sql);
	defined($i) or $i=0;
	
	# loop through characters	
	CHARLOOP:
	while ($i <= $#chars) {
		my $char = $chars[$i++];
		
		# if in quote
		if (defined $inquote) {
			# escape next character
			if ( ($char eq '\\') && ($self->{'backslash_escape'}) ) {
				push @field, $char, splice(@chars, $i, 1);
				next CHARLOOP;
			}
			
			elsif ($char eq $inquote) {
				# if the next character is also a quote,
				# then remove it and don't go out of inquote mode
				if ( (! $inregex) && defined($chars[$i]) && ($chars[$i] eq $inquote) && $self->{'dquote_escape'} )
					{push @field, splice(@chars, $i, 1)}
				
				# else end the quote
				else {
					my ($field);
					undef $inquote;
					
					# if in regex
					if ($inregex) {
						my @params;
						$field = {rx => join('', @field)};
						
						# get trailing characters
						while ( ($i <= $#chars) && ($chars[$i] =~ m|[a-z]|i) )
							{push @params, splice@chars, $i, 1}
						
						$field->{'params'} = join('', @params);
						undef $inregex;
					}
					
					# else regular quote
					else
						{$field = joinfield(@field, $char)}
					
					push @major, $field;
					@field = ();
					next CHARLOOP;
				}
			}
		}
		
		# in line comment
		elsif ($inlinecomment) {
			$char =~ m|[\n\r]| or next CHARLOOP;
			undef $inlinecomment;
		}
		
		# in star comment
		elsif ($instar) {
			if ( ($char eq '*') && ($chars[$i] eq '/')) {
				splice(@chars, $i, 1);
				undef $instar;
			}
			
			next CHARLOOP;
		}
		
		# if char is a -, and the next character is also a -
		elsif ( ($char eq '-') && $self->{'dash_comments'} && ($chars[$i] eq '-')) {
			splice(@chars, $i, 1);
			$inlinecomment = 1;
			next CHARLOOP;
		}
		
		# if char is a #
		elsif ( ($char eq '#') && $self->{'pound_comments'}) {
			$inlinecomment = 1;
			next CHARLOOP;
		}
		
		# opening /* comment
		elsif ( ($char eq '/') && $self->{'star_comments'} && ($chars[$i] eq '*')) {
			splice(@chars, $i, 1);
			$instar = 1;
			next CHARLOOP;
		}
		
		# square brace
		elsif ( $self->{'field_braces'} && ($char eq '[') ) {
			push @major, joinfield(@field);
			@field = ();
			$inquote = ']';
		}
		
		# quote
		elsif ($quotes{$char}) {
			push @major, joinfield(@field);
			@field = ();
			$inquote = $char;
		}
		
		# regex
		elsif ( ($char eq '=') && $self->{'perl_regex'} && $chars[$i] && ($chars[$i] eq '~')) {
			# purge everything up to here
			push @field, $char, splice(@chars, $i, 1);
			push @major, joinfield(@field);
			@field = ();
			
			# remove leading spaces and alphas
			while ( ($i <= $#chars) && ($chars[$i] =~ m|[\sa-z]|i) )
				{splice @chars, $i, 1}
			
			# get closing character
			$inquote = splice @chars, $i, 1;
			$inquote =~ tr/\[\{\(/\]\}\)/;
			$inregex = 1;
			next CHARLOOP;
		}
		
		# opening paren
		elsif ($char eq '(') {
			push @major, joinfield(@field), [sql_split($self, \@chars, $carry, $i)];
			@field = ();
			next CHARLOOP;
		}
		
		# else if this is a closing paren
		elsif ($char eq ')')
			{last CHARLOOP}
		
		# add the character to the field		
		push @field, $char;
	}
	
	# get last field
	push @major, joinfield(@field);
	
	
	# pass position back to caller
	$_[IPOS] = $i;

	
	#-------------------------------------------------
	# split by delimiters
	# 
	foreach my $el (@major) {
		# quoted strings and references don't get split
		if (
			ref($el) ||
			($self->{'field_braces'} ? ($el =~ m|^['"\[]|) : ($el =~ m|^['"]|) )
			)
			{push @rv, $el}
		
		
		elsif(length $el)
			{push @rv, grep {m|\S|s} split(m/(\s|[\!\?\,]|[\d\.]+|[a-z0-9_]+|$opregex|\S+)\s*/soi, $el);}
	}
	# 
	# split by delimiters
	#-------------------------------------------------
	
	
	#-------------------------------------------------
	# change placeholders to references
	# lowercase elements that aren't quoted or references
	# unquote elements
	# 
	foreach my $el (@rv) {
		unless ( ref($el) || ($el =~ m|^['"]|) ) {
			if ($el eq '?') {
				$el = {
					placeholder=>1,
					index=>scalar @{$carry->{'placeholders'}}
					};
				
				push @{$carry->{'placeholders'}}, $el;
			}
			
			# alias ! to not
			elsif ( ($el eq '!') and $self->{'!_is_not'} )
				{$el = 'not'}
			else
				{$el =~ tr/A-Z/a-z/}
		}
	}
	# 
	# change placeholders to references
	# lowercase elements that aren't quoted or references
	#-------------------------------------------------
	
	
	#-------------------------------------------------
	# compact double word tokens
	# 
	$i = 0;
	$dtokens = $self->{'double_word_tokens'};
	
	while ($i < $#rv) {
		my $el = $rv[$i];
		
		# if this is a double_word token
		unless (ref $el) {
			if ($dtokens->{$el}) {
				if ( (! ref($rv[$i+1])) && exists $dtokens->{$el}->{$rv[$i+1]} )
					{$rv[$i] = $rv[$i] . ' ' . splice(@rv, $i+1, 1)}
			}
		}
		
		$i++;
	}
	# 
	# compact double word tokens
	#-------------------------------------------------
	
	
	# unquote if necessary
	#if ($opts{'unquote'}) {
	#	foreach my $el (@rv)
	#		{$el = unquote($el)}
	#}
	
	# remove empty elements
	@rv = grep {length($_)} @rv;
	
	
	return @rv;
}
# 
# sql_split
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# misc short subs
# 
sub joinfield {
	my($val) = join('', @_);
	$val =~ s|^\s+||s;
	$val =~ s|\s+$||s;
	return $val;
}

# this could probably be done a lot more efficiently
sub unquote {
	my ($rv) = @_;
	
	# remove outer quotes
	if ($rv =~ s|^'(.*)'$|$1|s)
		{$rv =~ s|''|'|sg}
	elsif ($rv =~ s|^"(.*)"$|$1|s)
		{$rv =~ s|""|"|sg}
	
	# escapes
	my @sets = split m|(\\.)|, $rv;
	
	grep {
		s|\\0|$nullchar|o;
		s|\\z|$wineof|o;
		s|\\t|\t|;
		s|\\r|\r|;
		s|\\n|\n|;
		s|\\b|\b|;
		s|\\(.)|$1|;
		} @sets;	
	
	return join('', @sets);
}

sub count_ops {
	return
		keys(%SQL::YASP::Expr::bin) + 
		keys(%SQL::YASP::Expr::functions);
}

sub default_ops {
	return [@SQL::YASP::Expr::dbin];
}

sub default_functions {
	return {%SQL::YASP::Expr::dfuncs};
}


# 
# misc short subs
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# arr_split
# 
# splits an array into an array of arrays
# 
sub arr_split {
	my ($del_arr, $outer, %opts) = @_;
	my (@current, @rv, %dels, $firstdone);
	ref($outer) or return $outer;
	$opts{'max'} and $opts{'max'}--;
	@dels{@$del_arr} = ();
	
	foreach my $el (@$outer) {

		if (  (! ref $el) && exists($dels{$el}) && ($opts{'max'} ? @rv<$opts{'max'} : 1)  ) {
			if ($opts{'keep_del_back'})
				{push @current, $el}
			
			if ($firstdone || @current)
				{push @rv, [@current]}
			$firstdone = 1;
			
			@current = ();
			
			if ($opts{'keep_del_front'})
				{push @current, $el}
		}
		else
			{push @current, $el}
	}
	
	# add last element
	push @rv, [@current];
	
	wantarray and return @rv;
	return \@rv;
}

# comma_split
sub comma_split {arr_split([','], @_)}

# 
# arr_split
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# object_list
# 
# used for situations where the argument list is a comma delimited
# list of single objects, e.g. table names
# 
sub object_list {
	my @list = deref_args($_[0]);
	
	my @rv = grep {$_ ne ','} @list;
	wantarray and return @rv;
	return \@rv;
}
# 
# object_list
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# get_ixhash
# 
sub get_ixhash {
	my(%hash);
	tie(%hash, 'Tie::IxHash')
		or die "unable to tie hash: $!";
	return \%hash;
}
# 
# get_ixhash
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# deref_args
# 
sub deref_args {
	my @args = @_;
	
	# dereference arguments
	while ( (@args == 1) && (UNIVERSAL::isa($args[0], 'ARRAY')) )
		{@args = @{$args[0]}}
	
	return @args;
}
# 
# deref_args
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# restring
# 
sub restring {
	my @args = deref_args(@_);
	my (@rv);
	
	# loop through arguments
	foreach my $arg (@args) {
		if (ref $arg) {
			# if the arg is a placeholder
			if (UNIVERSAL::isa($arg, 'HASH') && $arg->{'placeholder'})
				{push @rv, ' ?'}
			else
				{push @rv, '(', restring($arg), ')'}
		}
		
		else {
			if (@rv && ($arg ne ',') )
				{push @rv, ' '}
			push @rv, $arg;
		}
	}
	
	return join('', @rv);
}
# 
# restring
#------------------------------------------------------------------------------


# optsref
# turns option hash into anonymous hash
sub optsref{return ref($_[0]) ? $_[0] : {@_}}



###############################################################################
# SQL::YASP::Statement
# 
package SQL::YASP::Statement;
use strict;
use Carp 'croak';

#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $sql) = @_;
	
	if (defined $sql)
		{return SQL::YASP->parse($sql)}
	
	return bless({}, $class);
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# select_fields
# 
sub select_fields {
	my ($self, %opts) = @_;
	my $rv = {};
	my $sendopts = {%opts};
	delete $sendopts->{'set'};
	
	# error checking
	$opts{'db_record'} or croak 'select_fields requires a db_record argument';
	
	# loop through fields
	while (my($n, $v) = each(%{$self->{'fields'}})) {
		if ($n eq '*') {
			while (my($on, $ov) = each(%{$opts{'db_record'}}) )
				{$rv->{$on} = $ov}
		}
		
		else {
			my ($val);
			$v->evalexpr($sendopts, $val) or return undef;
			$rv->{$n} = $val;
		}
	}
	
	# store results	
	if (exists $opts{'set'}) {
		my $i = 1;
		
		while ($i < @_) {
			if ($_[$i] eq 'set') {
				$_[$i+1] = $rv;
				return 1;
			}
			
			$i+=2;
		}
	}
	
	return $rv;
}
# 
# select_fields
#------------------------------------------------------------------------------


# 
# SQL::YASP::Statement
###############################################################################



###############################################################################
# SQL::YASP::Expr
# 
package SQL::YASP::Expr;
use strict;
use Carp 'croak', 'confess';
use vars qw[@dbin %dfuncs];

# debug tools
# use Debug::ShowStuff ':all';

# comparison types
use constant CMP_AGNOSTIC => 0;
use constant CMP_STRING   => 1;
use constant CMP_NUMBER   => 2;

# operator precedence levels
use constant OP_BETWEEN => SQL::YASP::OP_BETWEEN;
use constant OP_LOGICAL => SQL::YASP::OP_LOGICAL;
use constant OP_ADD     => SQL::YASP::OP_ADD;
use constant OP_MULT    => SQL::YASP::OP_MULT;
use constant OP_EXP     => SQL::YASP::OP_EXP;
use constant OP_MISC    => SQL::YASP::OP_MISC;

# ARGUMENT TYPES
use constant ARG_STRING    => SQL::YASP::ARG_STRING;
use constant ARG_NONE      => SQL::YASP::ARG_NONE;
use constant ARG_RAW       => SQL::YASP::ARG_RAW;
use constant ARG_NUMERIC   => SQL::YASP::ARG_NUMERIC;
use constant ARG_SENDNULLS => SQL::YASP::ARG_SENDNULLS;

# RETURN TYPES
use constant RV_LOOSE => 0;
use constant RV_BOOL  => 1;

# misc constants
use constant EE_BYVAL => 1;
use constant EE_STARTARGS => 2;

# alias some subs from main class
sub deref_args{SQL::YASP::deref_args(@_)}
sub arr_split{SQL::YASP::arr_split(@_)}
sub comma_split{SQL::YASP::comma_split(@_)}
sub unquote{SQL::YASP::unquote(@_)}
sub restring{SQL::YASP::restring(@_)}


#------------------------------------------------------------------------------
# new
# 
sub new {
	my $class = shift;
	my $stmt = shift;
	my $self = bless({}, $class);
	
	$self->{'parser'} = $stmt->{'parser'};
	$self->{'expr'} = [deref_args(@_)];
	
	return $self;
}
# 
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# evalexpr
# 
sub evalexpr {
	my ($setval, $org_args, $opts, @args, %allops, $funcs, @oplevels, $rv, $typefix, $parser, $lukas);
	
	# get first argument, which is either an array ref or an Expr object
	$org_args = $_[0];
	
	# if second arg is a ref
	# it's the options hash ref
	# and the third is the value to set
	if (ref $_[1]) {
		$opts = $_[1];
		$setval = 2;
	}
	
	# get the options, and find out if one of them is the set value
	else {
		$opts = {@_[1..$#_]};
		
		if (exists $opts->{'set'}) {
			my $i = 1;
			
			SETLOOP:
			while ($i < @_) {
				if ($_[$i] eq 'set') {
					$setval = $i+1;
					last SETLOOP;
				}
				
				$i+=2;
			}
		}
	}
	
	# if first arg is a hash, then this is being done as a method call
	if (UNIVERSAL::isa($org_args, 'HASH')) {
		$opts->{'exprob'} = $org_args;
		$opts->{'parser'} = $org_args->{'parser'};
		$org_args = $org_args->{'expr'};
	}
	
	# get arguments
	if (UNIVERSAL::isa($org_args, 'ARRAY'))
		{@args = $org_args}
	elsif (ref $org_args)
		{@args = $org_args->{'expr'}}
	else
		{@args = $org_args}
	
	# dereference arguments
	@args = deref_args(@args);
	
	# get stuff from options
	$parser    =  $opts->{'exprob'}->{'parser'};
	$typefix   =  $parser->{'type_fix'};
	$lukas     =  $parser->{'lukas'};
	$funcs     =  $parser->{'functions'};
	%allops    =  %{$parser->{'allops'}};
	@oplevels  =  @{$parser->{'ops'}};
	
	
	
	#--------------------------------------------------------------------------
	# evaluate expression
	# 
	EVALEXPR:
	{
		# if expression is zero items long, that's a syntax error
		if (! @args) {
			set_err('invalid syntax: no arguments');
			last EVALEXPR;
		}
		
		# if expression is one item long
		if (@args == 1) {
			my $arg = $args[0];
			defined($arg) or die 'no $arg';
			
			# if it's a hash
			if (UNIVERSAL::isa($arg, 'HASH')) {
				# placeholder
				if ($arg->{'placeholder'}) {
					if ( $opts->{'params'} && @{$opts->{'params'}} ) {
						# make sure we have a placeholder for this index
						if ($arg->{'index'} > $#{$opts->{'params'}})
							{set_err('More placeholders than params')}
						
						$rv = $opts->{'params'}->[$arg->{'index'}];
					}
					
					else {
						set_err('Do not have any params to match placeholders');
					}
				}
				
				# else just return it
				else
					{$rv = $arg}
				
				last EVALEXPR;
			}
			
			# if it's an array: should never reach this point
			if (UNIVERSAL::isa($arg, 'ARRAY'))
				{croak 'got single array ref'}
			
			# field name with braces
			if (
				$parser->{'field_braces'} &&
				($arg =~ m|^\[.+\]$|s)
				) {
				# if no db record was sent, that's an error
				if (! $opts->{'db_record'}) {
					set_err('Cannot evaluate field expression w/o database record');
					last EVALEXPR;
				}
				
				# get field name
				my $field_name = $arg;
				$field_name =~ s|^\[(.+)\]$|$1|s;
				
				# normalize
				if ($parser->{'normalize_fields'}) {
					$field_name =~ s|^\s+||s;
					$field_name =~ s|\s+$||s;
					$field_name =~ s|\s+| |gs;
					$field_name = lc($field_name);
				}
				
				# if the field is in the database record OR
				# if we can assume that any field is in the
				# record
				if (
					$opts->{'assume_fields'} ||
					exists($opts->{'db_record'}->{$field_name})
					) {
					$rv = $opts->{'db_record'}->{$field_name};
				}
				
				# else give error that no such field is found
				else {
					set_err('Do not have field named ' . $field_name);
				}
				
				last EVALEXPR;
			}
			
			# function
			if ($funcs->{$arg}) {
				$rv = &{$funcs->{$arg}->{'s'}}($opts);
				sbool($funcs->{$arg}, $rv);
			}
			
			# field name w/o braces
			# TODO: normalize non-braced field names, mainly in terms of upper/lowercase
			elsif (
				$opts->{'db_record'} &&
				($parser->{'field_braces'} != SQL::YASP::FIELD_BRACES_REQUIRE) &&
				exists($opts->{'db_record'}->{$arg})
				){
				$rv = $opts->{'db_record'}->{$arg};
			}
			
			# constant
			elsif ($opts->{'const'} && exists($opts->{'const'}->{$arg}))
				{$rv = $opts->{'const'}->{$arg}}
			
			# literal expression
			elsif ($arg =~ m|^['"]|)
				{$rv = unquote($arg)}
			
			# number
			elsif (is_numeric($arg))
				{$rv = $arg + 0}
			
			# else don't know what it is
			else
				{set_err('cannot interpret expression: ' . $arg)}
			
			last EVALEXPR;
		}
		
		# evaluate expression based on binary operators
		# search for loosest bound first
		foreach my $bg (@oplevels) {
			my $i = $#args - 1;
			
			OPLOOP:
			while ($i > 0) {
				my $carg = $args[$i];
				my ($not);
				
				# if the current argument is a binary operator in this precedence level
				if ( (! ref $carg) && $bg->{$carg} ) {
					
					# KLUDGE: if this operator is ALSO a function, and if the next
					# token back is an operator, then skip this operator
					# typical scenerio where this kludge comes into play:
					#    rank/-2
					if (
						$funcs->{$carg} && 
						($i > 1) && 
						(exists $allops{$args[$i-1]})
						) {
						$i--;
						next OPLOOP;
					}
					
					my @left = @args[0..($i-1)];
					my $argtype = $bg->{$carg}->{'args'} || 0;
					my $rettype = $bg->{$carg}->{'rv'} || 0;
					my $sub = $bg->{$carg}->{'s'};
					
					# determine if we should reverse the logical sense of the expression
					if ($left[-1] eq 'not') {
						$not = 1;
						pop @left;
					}
					
					# ARG_RAW
					if ($argtype == ARG_RAW)
						{$rv = &{$sub}($opts, [@left], [@args[($i+1)..$#args]])}
					
					# else evaluate and send
					else {
						my ($a, $b);
						
						evalexpr(\@left, $opts, $a) or last EVALEXPR;
						evalexpr([@args[($i+1)..$#args]], $opts, $b) or last EVALEXPR;
						
						# if lukas, refuse to send nulls to operators
						# that don't handle them
						if ($lukas) {
							unless (
								($argtype == ARG_SENDNULLS) || 
								(defined($a) && defined($b))
								) {
							undef $rv;
							last EVALEXPR;
							}
						}
						
						# elsif fix_types
						elsif ($typefix) {
							if ($argtype == ARG_NUMERIC) {
								as_number($a);
								as_number($b);
							}
							
							elsif ($argtype == ARG_STRING) {
								defined($a) or $a = '';
								defined($b) or $b = '';
							}
						}
						
						# call operator subroutine
						$rv = &{$sub}($opts, $a, $b);
					}
					
					($rettype == RV_BOOL) and $rv = $rv ?1:0;
					$not and $rv = lnot($rv);
					last EVALEXPR;
				}
				
				$i--;
			}
		}
		
		# if the first arg is a function name
		if (my $function = $funcs->{$args[0]}) {
			my $argtype = $function->{'args'} || 0;
			
			# no arguments
			if ($argtype == ARG_NONE) {
				$rv = &{$function->{'s'}}($opts);
				last EVALEXPR;
			}
			
			# remove first argument (which is the function name)
			# and deref the rest
			shift @args;
			@args = deref_args(@args);
			
			# send arguments raw
			if ($argtype == ARG_RAW) {
				$rv = &{$function->{'s'}}($opts, @args);
				last EVALEXPR;
			}
			
			# split on commas
			@args = comma_split(\@args);
			
			# evaluate arguments
			foreach my $arg (@args)
				{evalexpr($arg, $opts, $arg) or last EVALEXPR}
			
			# evaluate the arguments
			if (! $argtype) {
				$typefix and grep {defined($_) or $_ = ''} @args;
				$rv = &{$function->{'s'}}($opts, @args);
			}
			
			# same as ARG_STRING, but let undef be undef
			elsif ($argtype == ARG_SENDNULLS) {
				$rv = &{$function->{'s'}}($opts, @args);
			}
			
			# same as ARG_STRING, but numify everything
			elsif ($argtype == ARG_NUMERIC) {
				$typefix and grep {as_number($_)} @args;
				$rv = &{$function->{'s'}}($opts, @args);
			}
			
			# else don't know argument type
			else
				{croak 'do not know argument type: ' . $argtype}
			
			
			sbool($function, $rv);
			last EVALEXPR;
		}
		
		set_err('could not evaluate expression: ' . restring(@args));
		last EVALEXPR;
	}
	# 
	# evaluate expression
	#--------------------------------------------------------------------------
	
	
	# if error, return undef
	if ($SQL::YASP::err) {
		if (! $setval)
			{croak 'SQL error: ' . $SQL::YASP::errstr}
		$_[$setval] = undef;
		return undef;
	}
	
	# set byval
	if ($setval) {
		$_[$setval] = $rv;
		return 1;
	}
	
	# return the value
	return $rv;
}
# 
# evalexpr
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# comparetype
# 
sub comparetype {
	my ($self, %opts) = @_;
	
	# quick exit
	exists($self->{'comparetype'}) and return $self->{'comparetype'};
	
	my ($args_ref, $defs);
	my ($parser, $typefix, $lukas, $funcs, %allops, @oplevels, @args);
	
	# dereference arguments
	$args_ref = $opts{'args'} || $self->{'expr'};
	@args = deref_args($args_ref);
	
	# get field definitions
	$defs = $opts{'defs'} or croak 'did not get field definitions';
	
	# get stuff from options
	$parser    =  $self->{'parser'};
	$typefix   =  $parser->{'type_fix'};
	$funcs     =  $parser->{'functions'};
	%allops    =  %{$parser->{'allops'}};
	@oplevels  =  @{$parser->{'ops'}};
	
	
	# if expression is zero items long, that's a syntax error
	if (! @args) {
		set_err('invalid syntax: no arguments');
		last EVALEXPR;
	}
	
	# if expression is one item long
	if (@args == 1){
		my $arg = $args[0];
		defined($arg) or die 'no $arg';
		
		# if it's a hash
		if (UNIVERSAL::isa($arg, 'HASH')) {
			return CMP_AGNOSTIC;
		}
		
		# if it's an array: should never reach this point
		if (UNIVERSAL::isa($arg, 'ARRAY'))
			{croak 'got single array ref'}
		
		# function
		if ($funcs->{$arg}) {
			my $func = $funcs->{$arg};
			
			defined($func->{'c'}) and return $func->{'c'};
			return CMP_STRING;
		}
		
		# field name
		elsif ( exists $defs->{$arg} )
			{ return $defs->{$arg} }
		
		# constant
		elsif ($opts{'const'} && exists($opts{'const'}->{$arg}))
			{return CMP_AGNOSTIC}
		
		# literal expression
		elsif ($arg =~ m|^['"]|)
			{return CMP_AGNOSTIC}
		
		# number
		elsif (is_numeric($arg))
			{return CMP_NUMBER}
		
		# else don't know what it is
		else
			{set_err('cannot interpret expression: ' . $arg)}
		
		last EVALEXPR;
	}
	
	# evaluate expression based on binary operators
	# search for loosest bound first
	foreach my $bg (@oplevels) {
		my $i = $#args - 1;
		
		OPLOOP:
		while ($i > 0) {
			my $carg = $args[$i];
			my ($not);
			
			# if the current argument is a binary operator in this precedence level
			if ( (! ref $carg) && $bg->{$carg} ) {
				my $subdef = $bg->{$carg};
				defined($subdef->{'c'}) and return $subdef->{'c'};
				return CMP_STRING;
			}
			
			$i--;
		}
	}
	
	
	# if the first arg is a function name
	if (my $function = $funcs->{$args[0]}) {
		$function->{'c'} and return $function->{'c'};
		die 'have not implemented recursing if the function is compare type agnostic';
	}
	
	set_err('could not evaluate expression: ' . restring(@args));
}
# 
# comparetype
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# sbool
# 
sub sbool {
	my $rv = $_[0]->{'rv'};
	($rv and ($rv==RV_BOOL)) or return;
	$_[1] = $_[1] ? 1 : 0;
}
# 
# sbool
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# set_err
#
sub set_err {
	$SQL::YASP::err = 1;
	$SQL::YASP::errstr = $_[0];
	return undef;
}
#
# set_err
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# numeric checking and conversion
#
sub is_numeric {
	defined($_[0]) and
	(! ref $_[0]) and
	$_[0] =~ m|^[\+\-]?\d+\.?$|s
	||
	$_[0] =~ m|^[\+\-]?\d*\.\d+$|s;
}

sub as_number {
	is_numeric($_[0]) or $_[0]=0;
}
#
# numeric checking and conversion
#------------------------------------------------------------------------------




# NUM_BETWEEN
$dbin[OP_BETWEEN]{'between'} = {s=>\&num_between,  args=>ARG_RAW, c=>CMP_NUMBER};
sub num_between {
	my ($opts, $expr, $args) = @_;
	my ($min, $max) = arr_split(['and'], $args, max=>2);
	
	# $and_str must be "and"
	unless (defined($min) && defined($max))
		{croak 'syntax for BETWEEN: $expr BETWEEN $min AND $max'}
	
	evalexpr($expr, $opts, $expr) or return;
	evalexpr($min, $opts, $min) or return;
	evalexpr($max, $opts, $max) or return;
	($min, $max) = sort($min, $max);
	
	return ($expr >= $min) && ($expr <= $max);
}


# LOGICAL AND
$dbin[OP_LOGICAL]{'and'} = {args=>ARG_RAW, s=>\&land, c=>CMP_NUMBER};
sub land {
	my ($opts, $left, $right) = @_;
	
	evalexpr($left, $opts, $left) or return;
	
	if (defined($left) or (! $opts->{'parser'}->{'lukas'}))
		{$left or return $left}
	
	evalexpr($right, $opts, $right) or return;
	$right and (! defined $left) and return undef;
	return $right;
}

# LOGICAL OR
$dbin[OP_LOGICAL]{'or'} = {args=>ARG_RAW, c=>CMP_NUMBER, s=>sub{
	my ($opts, $left, $right) = @_;
	
	evalexpr($left, $opts, $left) or return;
	$left and return $left;
	
	evalexpr($right, $opts, $right) or return;
	($right or (! $opts->{'parser'}->{'lukas'})) and return $right;

	defined($left) and defined($right) and return $right;
	return undef;
}};

# LOGICAL NAND
# equivalent to "not and"
$dbin[OP_LOGICAL]{'nand'} = {args=>ARG_RAW, c=>CMP_NUMBER, s=>sub{return lnot($_[0], land(@_))}};

# LOGICAL NOR
# returns true if both arguments are false
$dbin[OP_LOGICAL]{'nor'} = {args=>ARG_RAW, c=>CMP_NUMBER, s=>sub{
	my ($opts, $left, $right) = @_;
	
	evalexpr($left, $opts, $left) or return;
	$left and return 0;
	
	evalexpr($right, $opts, $right) or return;
	$right and return 0;
	
	$opts->{'parser'}->{'lukas'} or return 1;
	defined($left) and defined($right) and return 1;
	return undef;
}};

# LOGICAL XOR
# returns true if truth of arguments are different
$dbin[OP_LOGICAL]{'xor'}  = {s=>sub{$_[1] xor $_[2]}, rv=>RV_BOOL, c=>CMP_NUMBER};

# LOGICAL XNOR
# returns true if truth of arguments are the same
$dbin[OP_LOGICAL]{'xnor'} = {s=>sub{( $_[1] && $_[2] ) || ( (! $_[1]) && (! $_[2]) )}, rv=>RV_BOOL, c=>CMP_NUMBER};

# LIKE
$dbin[OP_MISC]{'like'} = {s=>\&string_like, args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER};
sub string_like {
	my ($opts, $arga, $argb, %bonusopts) = @_;
	my $esc = '\\';
	my $i = 1;
	
	# evaluate $arga
	evalexpr($arga, $opts, $arga) or return;
	
	# look for escape clause
	ESCAPELOOP:
	while ($i < $#{$argb}) {
		if ($argb->[$i] eq 'escape') {
			my @clause = splice(@{$argb}, $i+1);
			pop @{$argb};
			evalexpr(\@clause, $opts, $esc) or return;
			last ESCAPELOOP;
		}
		
		$i++;
	}
	
	# get value of second argument
	evalexpr($argb, $opts, $argb) or return;
	
	# substitute * for % and . for _
	# use Abigail's fake-look-behind technique
	$argb = reverse $argb;
	$esc = quotemeta(reverse $esc);
	$argb =~ s|\%(?!$esc)|\*\.|sg;
	$argb =~ s|_|\.|sg;
	$argb = reverse $argb;
	
	# if case insensitive
	$bonusopts{'i'} and return $arga =~ m/$argb/i;
	
	# case sensitive
	return $arga =~ m/$argb/;
}


# ILIKE: case insensitive LIKE
$dbin[OP_MISC]{'ilike'} = {s=>sub{string_like(@_, i=>1)}, args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER};

# IS
# This one's a little funky.  The rules go like this:
# The second batch of arguments are NOT evaluated.
# There are only two possibilities of what may be
# in the second array of arguments: "null", or "not null"
# NULL is synonymous with UNDEF
$dbin[OP_MISC]{'is'} = {s=>\&string_is, args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER};
sub string_is {
	my ($opts, $arg1, $arg2_ref) = @_;
	my @arg2 = @{$arg2_ref};
	
	evalexpr($arg1, $opts, $arg1) or return;
	
	# set arg1 to true for defined and has a length
	$arg1 = defined($arg1);
	
	if ( (@arg2 == 1) && ($arg2[0] eq 'null') )
		{return ! $arg1}
	if ( (@arg2 == 2) && ($arg2[0] eq 'not') && ($arg2[1] eq 'null') )
		{return $arg1}
	
	croak 'syntax error: the only arguments for "is" are "null" or "not null"';
}


# STRING COMPARISON
$dbin[OP_MISC]{'regexp'} = {s=>sub{$_[1] =~ m/$_[2]/s}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'iregexp'} = {s=>sub{$_[1] =~ m/$_[2]/si}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'<=>'} = $dbin[OP_MISC]{'='} = $dbin[OP_MISC]{'eq'} = {s=>sub{$_[1] eq $_[2]}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'ne'} = {s=>sub{$_[1] ne $_[2]}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'lt'} = {s=>sub{$_[1] lt $_[2]}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'gt'} = {s=>sub{$_[1] gt $_[2]}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'eqi'} = {s=>sub{lc($_[1]) eq lc($_[2])}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'nei'} = {s=>sub{lc($_[1]) ne lc($_[2])}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'lti'} = {s=>sub{lc($_[1]) lt lc($_[2])}, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'gti'} = {s=>sub{lc($_[1]) gt lc($_[2])}, rv=>RV_BOOL, c=>CMP_NUMBER};


# regular expression
$dbin[OP_MISC]{'=~'} = {s=>\&rxmatch, rv=>RV_BOOL, c=>CMP_NUMBER};
sub rxmatch {
	my ($opts, $str, $rx) = @_;
	my $not = 'xism';
	
	$rx->{'params'} and $not =~ s|[$rx->{'params'}]||g;
	$rx = "(?$rx->{'params'}-$not:$rx->{'rx'})";
	$rx =~ s|^(\(\?[xism]{4})-|$1|s;
	$str =~ /$rx/;
}


# IN
$dbin[OP_MISC]{'in'} = {s=>\&string_in, args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER};
sub string_in {
	my ($opts, $arg1, $arg2, %bonusopts) = @_;
	my $ci = $bonusopts{'i'};
	
	# get string value for argument 1
	evalexpr($arg1, $opts, $arg1) or return;
	$ci and $arg1 =~ tr/A-Z/a-z/;
	
	# loop through arg2 values
	foreach my $choice (comma_split([deref_args($arg2)])) {
		evalexpr($choice, $opts, $choice) or return;
		$ci and $choice =~ tr/A-Z/a-z/;
		($arg1 eq $choice) and return 1;
	}
	
	return 0;
}

# IIN: case insensitive IN
# not in MYSQL
$dbin[OP_MISC]{'iin'} = {s=>sub{return string_in(@_, i=>1)}, args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER};

# NUMERIC COMPARISONS
$dbin[OP_MISC]{'>'}  = {s=>sub{$_[1] >  $_[2]}, args=>ARG_NUMERIC, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'<'}  = {s=>sub{$_[1] <  $_[2]}, args=>ARG_NUMERIC, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'>='} = {s=>sub{$_[1] >= $_[2]}, args=>ARG_NUMERIC, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'<='} = {s=>sub{$_[1] <= $_[2]}, args=>ARG_NUMERIC, rv=>RV_BOOL, c=>CMP_NUMBER};
$dbin[OP_MISC]{'=='} = {s=>sub{$_[1] == $_[2]}, args=>ARG_NUMERIC, rv=>RV_BOOL, c=>CMP_NUMBER};

# NUMERIC NOT EQUAL: different than MySql, where <> is the same as !=
$dbin[OP_MISC]{'<>'} = {s=>sub{$_[1] != $_[2]}, args=>ARG_NUMERIC, rv=>RV_BOOL, c=>CMP_NUMBER};


# CONCATENATION
$dbin[OP_MISC]{'||'} = {s=>sub{ (defined($_[1]) ? $_[1] : '') . (defined($_[2]) ? $_[2] : '')}, args=>ARG_SENDNULLS, c=>CMP_STRING};
$dbin[OP_MISC]{'|||'} = {args=>ARG_SENDNULLS, c=>CMP_STRING, s=>sub{
	my $space = (defined($_[1]) && defined($_[2]) && ($_[1] =~ m|\S$|) && ($_[2] =~ m|^\S|) ) ? ' ' : '';
	(defined($_[1]) ? $_[1] : '') . $space . (defined($_[2]) ? $_[2] : '');
	}};

# NUMERIC OPERATIONS
$dbin[OP_ADD]{'-'}  = {s=>sub{$_[1] -  $_[2]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};
$dbin[OP_ADD]{'+'}  = {s=>sub{$_[1] +  $_[2]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};
$dbin[OP_MULT]{'*'} = {s=>sub{$_[1] *  $_[2]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};
$dbin[OP_MULT]{'%'} = {s=>sub{$_[1] %  $_[2]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};
$dbin[OP_EXP]{'^'}  = {s=>sub{$_[1] ** $_[2]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};
$dbin[OP_MULT]{'%'} = {args=>ARG_NUMERIC, c=>CMP_NUMBER, s=>sub{
		$_[2] or return set_err('divide by zero');
		$_[1] % $_[2];
	}};
$dbin[OP_MULT]{'/'} = {args=>ARG_NUMERIC, c=>CMP_NUMBER, s=>sub{
		$_[2] or return set_err('divide by zero');
		$_[1] / $_[2];
	}};


# TOLOWER, LCASE, LOWER
$dfuncs{'tolower'} = 
	$dfuncs{'lcase'} = 
	$dfuncs{'lower'} = 
	{s=>sub{lc($_[1])}, c=>CMP_STRING};

# TOUPPER, UCASE, UPPER
$dfuncs{'toupper'} = 
	$dfuncs{'ucase'} = 
	$dfuncs{'upper'} =
	{ s=>sub{uc($_[1])}, c=>CMP_STRING};

# TOTITLE, TCASE, TITLE
$dfuncs{'totitle'} = 
	$dfuncs{'tcase'} = 
	$dfuncs{'title'} = {
		s=>sub{
			my $rv = lc($_[1]);
			$rv =~ s|\b(.)|\U$1|sg;
			$rv;
		},
		c=>CMP_STRING
	};

# NOT: negate results
$dfuncs{'not'} = {s=>\&lnot, args=>ARG_SENDNULLS, c=>CMP_NUMBER};
sub lnot {
	$_[0]->{'parser'}->{'lukas'} and (! defined $_[1]) and return undef;
	return $_[1] ? 0 : 1;
}

# ERR: sets an error
$dfuncs{'err'} = {s=>sub{return set_err($_[1])}};

# ISNULL: returns true if the given value is NOT defined
$dfuncs{'isnull'} = {s=>sub{! defined $_[1]}, args=>ARG_SENDNULLS, c=>CMP_NUMBER, rv=>RV_BOOL};

# DEFINED: returns true if *all* of the given values are defined
# empty strings count as defined
$dfuncs{'defined'} = {args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER, s=>sub{
	my ($opts, @args) = @_;
	my ($val);
	
	foreach my $arg (comma_split(\@args)) {
		evalexpr($arg, $opts, $val) or return;
		defined($val) or return 0;
	}
	
	return 1;
}};

# HASCONTENT: returns true if the given value is defined
# and has at least one non-space character
$dfuncs{'hascontent'} = {s=>sub{$_[1] =~ m|\S|}, rv=>RV_BOOL, c=>CMP_NUMBER};

# HASNULL: returns true if *any* the given values are null
$dfuncs{'hasnull'} = {args=>ARG_RAW, rv=>RV_BOOL, c=>CMP_NUMBER, s=>sub{
	my ($opts, @args) = @_;
	my ($val);
	
	foreach my $arg (comma_split(\@args)) {
		evalexpr($arg, $opts, $val) or return;
		defined($val) or return 1;
	}
	
	return 0;
}};

# NULL, TRUE, FALSE
$dfuncs{'undef'}  = $dfuncs{'null'}  = {s=>sub{undef}, args=>ARG_NONE, c=>CMP_NUMBER};
$dfuncs{'true'}  = {s=>sub{1},  args=>ARG_NONE, c=>CMP_NUMBER};
$dfuncs{'false'} = {s=>sub{0},  args=>ARG_NONE, c=>CMP_NUMBER};

# IF
$dfuncs{'if'} = {s=>\&func_if, args=>ARG_RAW};
sub func_if {
	my ($opts, @args) = @_;
	my ($expr, $true, $false) = comma_split(\@args);
	my ($val);
	
	evalexpr($expr, $opts, $val) or return;
	
	if ($val) {
		evalexpr($true, $opts, $val) or return;
		return $val
	}
	
	unless ($false and @{$false})
		{return undef}
	
	evalexpr($false, $opts, $val) or return;
	return $val;
}


# CAT, CONCAT
# returns all arguments concatenated together
# Following the MySql documentation, this function returns NULL
# if any argument is null.  That seems a little harsh to me.  If
# you feel like I misread the documentation on that feel free
# to drop me an email on the matter: miko@idocs.com
$dfuncs{'cat'} = $dfuncs{'concat'} = {c=>CMP_STRING, s=>sub{shift;grep {defined($_) or return undef} @_;join('', @_)}};


# CONCAT_WS
# returns all arguments concatenated together with a separator
# Following the MySql documentation, this function returns NULL
# if the first argument is null, but nulls after that are ignored
# (not counted as part of the returned string).
$dfuncs{'cat_ws'} = $dfuncs{'concat_ws'} = {s=>\&concat_ws, c=>CMP_STRING};
sub concat_ws {
	shift;
	my ($sep, @args) = @_;
	defined($sep) or return(undef);
	return join($sep, grep {defined $_} @args);
}

# COALESCE
$dfuncs{'coalesce'} = {s=>\&coalesce};
sub coalesce {
	shift;
	foreach (@_)
		{defined($_) and return $_}
	return undef;
}

# LOAD_FILE
$dfuncs{'load_file'} = {s=>\&load_file, c=>CMP_STRING};
sub load_file {
	require FileHandle;
	my $fh = FileHandle->new($_[1]) or return undef;
	return join('', <$fh>);
}

#------------------------------------------------------------------------------
# mathematical functions
# 

# ORD, OCT, HEX, ABS, SIGN
$dfuncs{'ord'} = {s=>sub{ord $_[1]}, c=>CMP_NUMBER};
$dfuncs{'oct'} = {s=>sub{oct $_[1]}, c=>CMP_NUMBER};
$dfuncs{'hex'} = {s=>sub{hex $_[1]}, c=>CMP_NUMBER};
$dfuncs{'abs'} = {s=>sub{abs $_[1]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};
$dfuncs{'sign'} = {s=>sub{$_[1] or return 0;($_[1] > 0) ? 1 : -1;}, args=>ARG_NUMERIC, c=>CMP_NUMBER};

# MOD
$dfuncs{'mod'} = {s=>sub{$_[1] % $_[2]}, c=>CMP_NUMBER};

# POW, POWER
$dfuncs{'pow'} = $dfuncs{'power'} = {s=>sub{$_[1] ** $_[2]}, c=>CMP_NUMBER};

# FLOOR
$dfuncs{'floor'} = {s=>\&floor, c=>CMP_NUMBER};
sub floor {
	($_[1] >= 0) and return int($_[1]);
	($_[1] =~ m|\.0*[1-9]|) ? int($_[1]-1) : $_[1];
}

# CEILING
$dfuncs{'ceil'} = $dfuncs{'ceiling'} = {s=>\&ceil, c=>CMP_NUMBER};
sub ceil {
	($_[1] <= 0) and return int($_[1]);
	($_[1] =~ m|\.0*[1-9]|) ? int($_[1]+1) : $_[1];
}

# INT
$dfuncs{'int'} = $dfuncs{'ceiling'} = {s=>sub{int($_[1])}, c=>CMP_NUMBER};


# SQUARE, SQUARED
$dfuncs{'square'} = $dfuncs{'squared'} = {s=>sub{$_[1] ** 2}, c=>CMP_NUMBER};


# unary minus
$dfuncs{'-'} = {s=>sub{$_[1] * -1}, args=>ARG_NUMERIC, c=>CMP_NUMBER};

# unary plus
# this rather useless looking function allows us to
# have expressions like this:  1/+2
$dfuncs{'+'} = {s=>sub{$_[1]}, args=>ARG_NUMERIC, c=>CMP_NUMBER};

# 
# mathematical functions
#------------------------------------------------------------------------------


# CHAR
$dfuncs{'char'} = {s=>\&char, c=>CMP_STRING};
sub char {
	shift;
	my(@rv);
	foreach my $el (@_)
		{push @rv, chr int $el}
	return join('', @rv);
}


# STRING MANIPULATION AND INFORMATION
$dfuncs{'length'}  = {s=>sub{length $_[1]}, c=>CMP_NUMBER};
$dfuncs{'ltrim'}   = {s=>sub{$_[1] =~ s|\s+$||s;$_[1];}, c=>CMP_STRING};
$dfuncs{'rtrim'}   = {s=>sub{$_[1]=~s|^\s+||s;$_[1];}, c=>CMP_STRING};
$dfuncs{'left'}    = {s=>sub{substr($_[1],0,$_[2])}, c=>CMP_STRING};
$dfuncs{'right'}   = {s=>sub{reverse(substr(reverse($_[1]), 0, $_[2]))}, c=>CMP_STRING};
$dfuncs{'reverse'} = {s=>sub{reverse($_[1])}, c=>CMP_STRING};
$dfuncs{'space'}   = {s=>sub{' ' x $_[1]}, c=>CMP_STRING};
$dfuncs{'repeat'}  = {s=>sub{defined($_[1]) && defined($_[2]) or return(undef);$_[1] x $_[2]}, c=>CMP_STRING};
$dfuncs{'insert'}  = {s=>sub{substr($_[1], $_[2]-1, $_[3]) = $_[4];$_[1]}, c=>CMP_STRING};


# REPLACE
$dfuncs{'replace'} = {s=>\&replace, c=>CMP_STRING};
sub replace {
	shift;
	my ($str, $from, $to) = @_;
	$from = quotemeta($from);
	$str =~ s/$from/$to/i;
	$str;
}

# QUOTE
# needs to be fixed, doesn't quote enough stuff
# $dfuncs{'quote'} = {s=>sub{my($v)=@_;$v =~ s|'|\\'|gs;$v}, c=>CMP_STRING};


# SOUNDEX
# this function returns shorter values than the 
# MySql documentation, so this function may not work as expected
$dfuncs{'soundex'} = {s=>sub{require Text::Soundex;Text::Soundex::soundex($_[1])}, c=>CMP_STRING};

# STRCMP
$dfuncs{'strcmp'} = $dfuncs{'cmp'} = {s=>sub{$_[1] cmp $_[2]}, c=>CMP_NUMBER};

# LOCATE and friends
$dfuncs{'locate'} = $dfuncs{'position'} = {s=>\&locate, c=>CMP_NUMBER};
$dfuncs{'instr'} = {s=>sub{locate(@_[2,1,3])}};
sub locate {
	$_[3] ||= 1;
	index(lc($_[2]), lc($_[1]), $_[3]-1)+1;
}

# CRUNCH
# remove leading and trailing spaces, 
# reduce internal contigous spaces to single spaces
$dfuncs{'crunch'} = {s=>\&crunch, c=>CMP_STRING};
sub crunch {
	my $rv = $_[1];
	$rv =~ s|^\s+||s;
	$rv =~ s|\s+$||s;
	$rv =~ s|\s+| |sg;
	$rv;
}

# TRIM
# syntax: TRIM([[BOTH | LEADING | TRAILING] [remstr] FROM] str) 
$dfuncs{'trim'} = {s=>\&trim, args=>ARG_RAW, c=>CMP_STRING};
sub trim {
	shift;
	my ($opts, @args) = @_;
	my ($leading, $trailing, $next, $left, $str, $regex);
	
	# get  before and after FROM
	($left, $str) = arr_split(['from'], @args);
	
	# early exit: no FROM, so just trim and return
	if (! $str) {
		evalexpr($left, $opts, $str) or return;
		$str =~ s|^\s+||s;
		$str =~ s|\s+$||s;
		return $str;
	}
	
	evalexpr($str, $opts, $str) or return;
	@args = @$left;
	
	# determine leading and trailing trim actions
	while (
		@args &&
		($args[0] =~ m/^(both|leading|trailing)$/)
		) {
		$leading ||= $args[0] =~ m/^(both|leading)$/;
		$trailing ||= $args[0] =~ m/^(both|trailing)$/;
		shift @args;
	}
	
	# "If none of the specifiers BOTH, LEADING or TRAILING are given, BOTH is assumed."
	# -- MySql docs
	unless ($leading || $trailing)
		{$leading = $trailing = 1}
	
	# left defaults to \s
	if (@args) {
		evalexpr(\@args, $opts, $regex) or return;
		$regex = quotemeta($regex);
	}
	else
		{$regex = '\s'}
	
	$leading and $str =~ s/^($regex)+//s;
	$trailing and $str =~ s/($regex)+$//s;
	return $str;
}


# LPAD
$dfuncs{'lpad'} = {s=>\&lpad, c=>CMP_STRING};
sub lpad {
	shift;
	my @str = split('', shift);
	my $len = shift;
	my @padstr = split('', shift);
	@padstr or @padstr = (' ');
	
	while (@str < $len)
		{unshift @str, @padstr}
	while (@str > $len)
		{shift @str}
	
	return join('', @str);
}


# RPAD
$dfuncs{'rpad'} = {s=>\&rpad, c=>CMP_STRING};
sub rpad {
	shift;
	my @str = split('', shift);
	my $len = shift;
	my @padstr = split('', shift);
	@padstr or @padstr = (' ');
	
	while (@str < $len)
		{push @str, @padstr}
	while (@str > $len)
		{pop @str}
	
	return join('', @str);
}


# SUBSTRING
$dfuncs{'substring'} =
	$dfuncs{'mid'} =
	$dfuncs{'substr'} =
	{s=>\&substring, args=>ARG_RAW, c=>CMP_STRING};
sub substring {
	my ($opts, @args) = @_;
	my ($str, $pos, $len) = arr_split([',', 'from', 'for'], @args);
	evalexpr($str, $opts, $str) or return;
	evalexpr($pos, $opts, $pos) or return;
	
	if ($len)
		{evalexpr($len, $opts, $len) or return}
	else
		{$len = length($str)}
	
	return substr($str, $pos-1, $len);
}


# SUBSTRING_INDEX
$dfuncs{'substring_index'} = {s=>\&substring_index, c=>CMP_STRING};
sub substring_index {
	shift;
	my ($str, $del, $count) = @_;
	my (@arr, $reverse, $del_esc);
	
	$del_esc = quotemeta($del);	
	
	if ($count < 0) {
		$reverse = 1;
		$count *= -1;	
	}
	
	@arr = split($del_esc, $str);
	$reverse and @arr = reverse @arr;
	
	if (@arr > $count)
		{@arr = @arr[0..($count-1)]}
	
	$reverse and @arr = reverse @arr;
	return join($del, @arr);
}


# ELT
$dfuncs{'elt'} = {s=>\&elt, c=>CMP_AGNOSTIC};
sub elt {
	shift;
	my $val=shift;
	return $_[$val-1];
}

# FIELD
$dfuncs{'field'} = {s=>\&field, c=>CMP_AGNOSTIC};
sub field {
	shift;
	my $val=lc(shift);
	my $i = 0;
	
	while ($i <= $#_) {
		if (lc($_[$i]) eq $val)
			{return $i+1}
		$i++;
	}
	
	return undef;
}

# 
# SQL::YASP::Expr
###############################################################################


# return true;
1;

__END__


=head1 NAME

SQL::YASP - SQL parser and evaluater

=head1 NO LONGER BEING DEVELOPED

SQL::YASP is no longer being developed. That being said, I still think it's a
pretty cool module, so I hope you'll look through it for anything you might need.

=head1 SYNOPSIS

 use SQL::YASP;
 my ($sql, $stmt, $dbrec, $params);

 $sql = <<'(SQL)';
    select 
        -- supports single and multi-line comments
        -- supports "as fieldname" format for select clauses
        first ||| last as fullname

    from members

    where
        /*
        over 100 built in SQL functions and operators
        including most MySQL functions and operators
        */
        ucase(first) ilike 'Joe' and

        -- Perl-like regular expressions
        first =~ m/ (Joe) | (Steve) /ix and

        -- handles quoted strings and escapes in quotes
        last = 'O''Sullivan' and

        -- any level of nested parens
        -- full support for placeholders
        ((rank >= ?) and (rank <= ?))
 (SQL)
 
 
 # get statement object
 $stmt = SQL::YASP::Statement->new($sql);

 # database record: populate this hash from your database
 $dbrec = 
    {
    first=>'Joe',
    last=>'Smith',
    email=>'joe@idocs.com',
    rank=>10,
    };

 # input parameters
 $params = [10, 20];

 # test if this record passes the where clause
 if ($stmt->{'where'}->evalexpr(db_record=>$dbrec, params=>$params)) {
     # get the record as indicated by the select clause
     my $retrec = $stmt->select_fields(db_record=>$dbrec);
     print $retrec->{'fullname'}, "\n";
 }

=head1 INSTALLATION

SQL::YASP can be installed with the usual routine:

    perl Makefile.PL
    make
    make test
    make install

You can also just copy Eval.pm into the SQL/ directory of one of your library trees.


=head1 A NOTE ABOUT THE STATE OF DOCUMENTATION

I'm still working on the documentaton for YASP.  Documenting everything YASP
does has proved a daunting task.  In the spirit of Eric Raymond's motto
"Release Early, Release Often" I decided to go ahead and release YASP before
I finish the docs.

Sections that are not completed are noted with [*] in the title.

=head1 A GUIDED TOUR OF YASP

YASP is an SQL parser and evaluator for Perl.  It parses SQL statements,
allows you to discover various properties of them, and helps evaluate
expressions in the statement.  Let's look at some code that provides an
example of the features of YASP.

    1   $sql = <<'(SQL)';
    2   select
    3      rank,
    4      first ||| last as fullname
    5   from members
    6   where first=?
    7   (SQL)
    8  
    9   $stmt = SQL::YASP->parse($sql);
    10  $dbrec = {first=>'Starflower', last=>"O'Sullivan", rank=>10};
    11  $params = ['Starflower'];
    12  
    13  if ($stmt->{'where'}->evalexpr(db_record=>$dbrec, params=>$params)) {
    14     my $calcrec = $stmt->select_fields(db_record=>$dbrec);
    15     print $calcrec->{'rank'}, "\t", $calcrec->{'fullname'}, "\n";
    16  }


Lines 1- 7 create the SQL Select statement string we're going to parse.  Line
2 begins the select statement.  Line 3 indicates that the C<rank> field should
be returned.  Line 4 indicates that the C<first> and C<last> fields should be
concatenated together using C<|||> operator (see operator documentation below),
and the results should be named "fullname".

Line 5 indicates that the fields should be selected from the C<members> table.
The name of the table is given by the C<from> property of the statement object.
Line 6 gives the where clause, which will be revealed by the C<where> clause
of the statement object. 

Line 9 creates statement object, passing the SQL string as the only argument.
Line 10 create an anonymous hash will store data from the database.  Your
application can retrieve and populate this data in whatever manner you choose.
Line 11 creates an anonymous array of parameters that will be used to evaluate
the where clause. 

Line 13 evaluates the where clause, using the database record and parameters.
If the expression returns true, then 14 calls the select_fields(, again using
the database record hash, to return an anonymous hash of the database fields
as indicated by the expressions in the select clause. Line 15 outputs the
results. 

=head2 Lukasiewiczian Algebra

By default, YASP implements Lukasiewiczian algebra in evaluating SQL
expressions. If you would prefer to turn off Lukasiewiczian then set the parser's
C<lukas> property to false.

Lukasiewiczian algebra is the standard in most databases such as MySql and
Oracle. Lukasiewiczian algebra is a variation on Boolean Algebra invented by
Jan Lukasiewicz. In Boolean algreba there are two values: true and false.
Lukasiewiczian algrebra adds a third possible value: unknown, also known as
null. If an expression depends on null, than the expression evaluates to null.
If the expression can be determined as true or false even though it contains
nulls, it returns true or false. 

For example, consider the following AND expression: 

    null AND true

We don't know if the expression is true because we don't know if the first
argument is true. Ergo, the expression evaluates to null. However, in this
expression... 

    null AND false

... we know that the expression is false, because we know that the second
argument is false (and therefore we know that it's not true that both arguments
are true). Ergo the expression evaluates to false. In a similar way, the expression
C<true or x> evaluates to true because only one of the arguments needs to be
true in an OR, and we know the first argument is true. 

One of the funkiest ways that Lukasiewiczian algrebra is different from
Boolean is in the NOT operator. Not true is false. Not false is true. Not null
is ... null. That's because we don't know the negation of a value we don't
know. 

=head1 SQL COMMANDS [*]

YASP currently recognizes five SQL commands: CREATE, SELECT, DELETE, UPDATE,
and INSERT.   The statement object returned by the parser contains properties
of the command.  We'll start by looking at properties common to all types of
commands, then describe properties specific to each of the commands listed
above.

Each statement object has the following properties.

=over 4

=item command (scalar)

The command being run.  E.g., "select", "create", "inset"

=item placeholders (array)

Array of information about the placeholders in the command

=item placeholder_count (scalar)

how many placeholders were in the command

=back 4

Now let's look at properties specific to each command.

=head2 CREATE

=over 4

=item table_name (scalar)

Name of the object being created

=item create_type (scalar)

The type of object being created.  Right now only "table" is handled

=item fields (hash)

An array of information about the fields being created. The key for each hash
element is the name of the field. The hash is indexed, so each element is
returned in the order it is defined in the SQL command.

Each field definition (i.e. each element in the fields hash) has two elements.
"data_type" is the parsed command indicating the data type of the field.
"modifiers" is an array of all other options defining the field, e.g.
"unique", "undef", etc.

=back 4


=head2 SELECT

=over 4

=item where

An expression object.  See the documentation for expression objects
objects below.

=item from

This property is a hash of information about the tables from which records
should be selected.  The key of each element is the alias of the table if an
alias is used, or the name of the table itself.  The value is the name of the
table.  For example, this SQL command:

 select name, payment from members, registrations reg where members.id=reg.id

produces a C<from> clause with these keys and values:

  KEY       VALUE
  reg       registrations
  members   members

=item fields

An indexed hash describing each field that should be returned by the select
statement.  The key of each hash element is the alias of the field (if an
alias was given), the name of the field (if only a single field is requested,
or the full expression.  The value of each element is an Expression object.
See the documentation for expression objects below.

=back 4


=head2 DELETE

Statement objects for the DELETE command have C<where> and C<from>
properties like SELECT statements.

=head2 UPDATE

=over 4

=item table_name

This property holds the name of the table being updated.

=item set

An indexed hash describing which fields should be updated and what they should
be updated to.  The key of each hash element is the name of the field to be
updated.  The value of each element is an Expression object.  See the
documentation for expression objects below.

=back 4


=head2 INSERT

Statement objects for the INSERT command have C<set> and C<table_name>
properties like UPDATE statements.

=head1 EXPRESSION OBJECTS

Expression objects allow you to evaluate an SQL expression against one or more
database records.  Expression objects only have one public method, C<evalexpr>,
so let's get right to looking at how that method works.

Consider the following code:

 1   $sql = 'select name from members where id=?';
 2   $dbrec = { id=>10, name => 'Starflower'};
 3   $params = [10];
 4   $stmt = SQL::YASP->parse($sql);
 5   
 6   if ($stmt->{'where'}->evalexpr(db_record=>$dbrec, params=>$params))
 7       {print $dbrec->{'name'}, "\n"}

Line 1 creates an SQL statement to select the name field from the members table.
Notice that the where clause uses a placeholder instead of a hardcoded values.
Line 2 creates a hash reference that represents a database record.  Line 3
creates an array reference that is a list of parameters that will be
substituted for placeholders in the SQL statement. Line 4 creates an SQL
statement object.

In Line 6 we use the expression object that is stored as the C<where> property
of the statement.  We pass in the database record and the parameter list, and
get back true or false.


=head1 EXTENDING YASP

YASP is designed to simplify overriding any of its functionality.  Although
YASP works out-of-the box, developers may want to tune it to parse and
interpret specific flavors of SQL.

=head2 The Basic Concepts

The first and only required step for extending YASP is to create a new package
and set its @ISA to point to YASP.  Let's say you want to call you package
"Extended", and that you want to put it in a file named "Extended.pm". The
following code at the top of the package does the extending:

    package Extended;
    use strict;
    use SQL::YASP ':all';
    @Extended::ISA = 'SQL::YASP';

As always, be sure that the last line in Extended.pm is 1 so that you can load
it into a script.  You're now ready to use your new package.  First, load the
package:

    use Extended;

then use it to parse SQL:

    $stmt = Extended->parse($sql);

Of course, the point of extending is to change the default functionality.
Generally this is done in three ways for YASP: modifying the parsing options,
modifying the operators and functions, and overriding object methods.

Except for overriding methods, all of these options and properties should be
set in the C<new> function.  Any of the options that are not explicitly set
in C<new> are set in C<after_new>, which should I<always> be called at the
end of C<new>.  So, for example, suppose you wanted to remove Perl-style
regexes and /* style comments.  Your C<new> function could look like this:

    sub new {
        my ($class) = @_;
        my $self = bless({}, $class);
        
        # parsing options
        $self->{'star_comments'} = 0;
        $self->{'perl_regex'} = 0;
        
        # always call after_new just before
        # returning new parser
        $self->after_new;
        
        return $self;
    }


=head2 Parsing Options

The following options can be set in the C<new> function.  See their
documentation for specifics about what each property does.

    !_is_not
    backslash_escape
    dash_comments
    dquote_escape
    lukas
    perl_regex
    pound_comments
    quotes
    star_comments

=head2 DEFINING SQL OPERATORS

SQL operators are stored as a set sub references in the parser object.  The
parser's C<ops> property is an array.  Each element of the array is a hash,
and each element of the hash is a hash of information about a specific
operator.  Was that a little confusing?  Here's an example.  Suppose we only
wanted the parser to recognize four operators:  =, >, *, and +.  We would set
the C<ops> property in C<new> like this:

    sub new {
        my ($class) = @_;
        my $self = bless({}, $class);
        
        # operators
        $self->{'ops'} = [
            # comparison operators
            {
            '='  => { s=>sub{$_[0] eq $_[1]} }, 
            '>' => { s=>sub{$_[0] > $_[1]} }, 
            },
            
            # mathematical operators
            {
            '*'  => { s=>sub{$_[0] eq $_[1]},  args=>ARG_NUMERIC} ,  
            '+' => { s=>sub{$_[0] > $_[1]},    args=>ARG_NUMERIC}, 
            },
        ];
        
        # always call after_new just
        # before returning new parser
        $self->after_new;
        
        return $self;
    }

Let's look at how the ops property is constructed.  Each element in the array
represents a level of operator precedence. Loosest bound operators are in the
first element, and ops of increasingly tighter binding are in higher array
elements. Operators in the same array element have equal precedence. 

Each array element is itself a hash of operator definitions. The hash key is
the name of operator itself.  Where letters are part of the operator name,
always use lowercase. 

The operator definition itself is a hash of properties about the operator.
Only one property is required, the C<s> (for "sub") property.  The C<s>
property should reference the subroutine that actually performs the operation.
For short subs it is usually easiest to simply use an anonymous subroutine, as
in the example above. By default, the subroutine receives two arguments: the
value on the left and the value on the right.  The sub should return whatever
the result of the operation is.

In a moment we'll look at how each op function is contructed, as well as the
other properties of the operator definition, but first a note about the
operations that are available by default from YASP.  Constructing all of your
operators in a long array like above could get pretty obnoxious, especially
considering that a good portion of the operators you are likely to want are
already available by default from YASP.  Let's suppose that you only wanted
to make one change in the default operators: you want to change C<||> from
a concatenator to an C<or> as it is in MySql.  You could do that in the
C<new> function like this:

    sub new {
        my ($class) = @_;
        my $self = bless({}, $class);
        
        # get default operators
        $self->{'ops'} = SQL::YASP::default_ops();
        
        # get rid of the default || operator
        delete $self->{'ops'}->[OP_MISC]->{'||'};
        
        # alias || to or
        $self->{'ops'}->[OP_LOGICAL]->{'||'} = $self->{'ops'}->[OP_LOGICAL]->{'or'};
        
        # always call after_new just
        # before returning new parser
        $self->after_new;
        
        return $self;
    }

After blessing the object, the function sets its C<ops>
property to the default YASP operators using the SQL::YASP::default_ops()
function, which returns an anonymous array of operator definitions.  Next,
it removes the C<||> definition from the C<OP_MISC> level of operators.
There are six operator precedence levels in the default definitions:
C<OP_BETWEEN>, C<OP_LOGICAL>, C<OP_ADD>, C<OP_MULT>, C<OP_EXP>, and
C<OP_MISC>.  The sub then redefines C<||> into the OP_LOGICAL level, setting
its definition to the same as the C<or> operator.

Turning our attention back to the other properties of an operator definition,
the other property is C<args>, which indicates what kind of arguments the sub
expects.  There are four possible values. C<ARG_STRING> (which is the default,
so you can leave it out) indicates that the sub expects two strings.
C<ARG_STRING> is null-safe: YASP will send empty strings instead of spaces to
such subs. If you want your operator to see nulls when they are indicated, set
C<args> to C<ARG_SENDNULLS>.  C<ARG_NUMERIC> indicates that the sub expects
numbers.  For C<ARG_NUMERIC> operators, zero will be sent instead of null. 

C<ARG_RAW> is for the situation where you don't want YASP to evaluate the
expressions on the left and right of the operator, but instead to allow your
sub to decide how to interpret the expressions.  C<ARG_RAW> subs receieve three
arguments. The first two are anonymous arrays of the expressions to the left
and right of the operator.  The third argument, $opts, is a hash of values
passed through the recursion of the C<evalexpr> ("evaluate expression") sub.

To evalute one of the expressions, call C<evalexpr> passing three value:
$opts, the expression, and a variable into which the results will be stored.
Contrary to what might be expected, C<evalexpr> does I<not> return the results
of the expression when called in this manner.  The results of the expression are
stored in the third argument. The I<success> of the evaulation is returned by
C<evalexpr>.  If C<evalexpr> returns false then there was a fatal error in the
SQL expression (e.g. a divide by zero) and your function should proceed
no further.

For example, YASP's default C<and> operator looks like this:

    $dbin[OP_LOGICAL]{'and'}  = {args=>ARG_RAW, s=>sub{
        my ($left, $right, $opts) = @_;
        my ($val);
        
        evalexpr($left, $opts, $val) or return;
        $val or return 0;
        
        evalexpr($right, $opts, $val) or return;
        return $val;
    }};

In the first call to C<evalexpr> passes $left, $opts, and $val.  The results
of the expression are stored in $val.  If C<evalexpr> returns false then the
function returns, proceeding no further.

C<and> is an C<ARG_RAW> operator so that it short ciruits: the right expression
is never evaluted if the left argument is false.  That's why Cand> is an
C<ARG_RAW> operator: so that it never has to evaluate the second expression
if the first is false.

If your code discovers that the expression is invalid in some way, you can
throw an error to indicate that the SQL is invalid. To do so, set
$SQL::YASP::err to true, set $SQL::YASP::errstr to a description of the error,
and return undef from the function.  For example, dividing by zero is an error,
so your C</> operator could look like this:

    $dbin[OP_MULT]{'/'} = {args=>ARG_NUMERIC, s=>sub{
        unless ($_[1]) {
            $SQL::YASP::err = 1;
            $SQL::YASP::errstr = 'divide by zero';
            return undef;
        }
        
        $_[0] / $_[1];
    }};

Putting all of that code in your function can become burdensome, so you can
also just return the results of the C<set_err> function in a single line.
C<set_err> sets $SQL::YASP::err to true, set $SQL::YASP::errstr to its single
argument, and returns undef. So, for example, the divide operator function
can look like this:

    $dbin[OP_MULT]{'/'} = {args=>ARG_NUMERIC, s=>sub{
        $_[1] or return set_err('divide by zero');
        $_[0] / $_[1];
    }};

Be sure to I<return> the results of C<set_err>, not just call it.

=head2 A NOTE ABOUT THE C<NOT> OPERATOR

Any operator is negated by preceding it with C<not>.  For example, our C<=>
operator above can be negated like this:

    where first not = 'Joe"

If the parser's C<!_is_not> property is true (which it is by default), then
C<!> can be used as an alias for C<not>. Because C<!> does not require any
space after it to be parsed out, we already have a not-equals operator
without having to define one:
    
    where first != 'Joe"

=head2 Defining SQL Functions

Like operators, SQL functions are stored as a set sub references in the parser
object.  The parser's C<functions> property is a hash of function definitions.
Suppose, for example, that you want your parser to recognize two functions:
C<upper>, which uppercases its argument, and C<larger>, which returns the
larger of its two arguments.  We would set the C<functions> property in
C<new> like this:

    sub new {
        my ($class) = @_;
        my $self = bless({}, $class);
        
        # operators
        $self->{'functions'} = 
            {
            'upper'  => { s=>sub{uc $_[0]} },
            'larger' => { s=>sub{$_[0]>$_[1] ? $_[0] : $_[1]}}, 
            };
        
        # always call after_new just
        # before returning new parser
        $self->after_new;
        
        return $self;
    }

Each hash key is the name of the functon itself.  Functions may consist of
letters, numbers, and underscores, and must start with a letter.  Use lowercase
letters only.  The value of the hash element is a function definition much like
the operator definitions above.  The only required property is C<s> which
references the subroutine to process the function.  For short functions it is
usually easiest to reference an anonymous subroutine.  The C<args> property
can take the same values as for operators: 
C<ARG_STRING>, 
C<ARG_RAW>, 
C<ARG_NUMERIC>, and 
C<ARG_SENDNULLS>.  For any of those type the subroutine will receive one
argument: the value of the expression within the parens.  There are also one
other argument types for functions: C<ARG_NONE>, which means that the function
takes no arguments.

You might prefer to set your functions by grabbing a hash of all of the
default functions, then adding to and deleting from the hash as needed.  For
example, suppose you wanted use all of the default functions, except that you
want to delete the C<trim> and C<reverse> functions.  You could do that with a
C<new> method like this:

    sub new {
        my ($class) = @_;
        my $self = bless({}, $class);
        
        # get default operators
        $self->{'functions'} = SQL::YASP::default_functions();
        
        # delete some functions we don't want
        delete $self->{'functions'}->{'trim'};
        delete $self->{'functions'}->{'reverse'};
        
        # always call after_new just
        # before returning new parser
        $self->after_new;
        
        return $self;
    }

This code loads the defaults into the C<functions> property by calling
SQL::YASP::default_functions(), which returns an anonymous hash of all the
default functions.  Then it simply deletes C<trim> and C<reverse> from the
hash.

=head2 OVERRIDING OBJECT METHODS

Your extending class can override any method, but there are several methods
that were particularly designed for overriding. Those methods are described in
more detail in the "Overrideable Methods" section below.

=head1 PARSER OBJECT [*]

=head2 Properties [*]

=over 4

=item ops

This property provides a set of SQL operators.  See "Setting SQL Operators"
for more details.

=item functions

This property provides a set of SQL functions.  See "Setting SQL Functions"
for more details.

=item lukas [*]


=item star_comments

If true, the parser recognizes comments that begin with /* and end with */.
Defaults to true.

=item dash_comments

If true, the parser recognizes comments that begin with -- and continue for
the rest of the line. Defaults to true.

=item pound_comments

If true, the parser recognizes comments that begin with # and continue for the
rest of the line. Defaults to true.

=item quotes

An array of which characters are recognized as quotes.  Defaults to single and
double quotes. Other characters are not currently supported.  This property
is changed from an array to a hash in after_new().

=item !_is_not

If true, the parser aliases the bang (aka the exclamation point: !) to the
word "not". Defaults to true.

=item perl_regex

If true, the parser allows Perl-style regular expressions in the SQL.  For
example, the following code would be allowed:

    where
        first =~ m/ (Miko) | (Starflower) /ix

Defaults to true.

=item keep_org_sql

If true, statement objects hold on to the original SQL string in the org_sql
property. Defaults to false.

=item dquote_escape

If true, quotes inside quotes can be escaped by putting two quotes in a row.
For example, the following expression set name to O'Sullivan:

    name='O''Sullivan'

Defaults to true.

=item backslash_escape

If true, quotes inside quotes can be escaped by putting a backslash in front
of the quote.  For example, the following expression set name to O'Sullivan:

    name='O\'Sullivan'

Defaults to true.

=item commands

This hash of hashes is used for specific situations where it may be ambiguous
if the set of arguments is intended to be interpreted as a command or as an a
field or table name. Currently, this property is only used in CREATE TABLE
commands to interpret which in the list of arguments is a field name and
which is a qualifier for the command.

=item double_word_tokens

A hash of tokens that consist of two words.  Each key of the hash should be
the first word of the token.  The value of each element should be another
hash, each key of which consists of a second word in the token, and each
value of which consists of any true string.  The default double_word_tokens
property is created with code like this:

    $self->{'double_word_tokens'} ||= {
        primary  =>  {key=>1},
        current  =>  {date=>1},
        order    =>  {by=>1},
    };

=back 4

=head2 OVERRIDEABLE METHODS [*]



=over 4

=item new



=item build_tree

=item tree_create

=item tree_create_table

=item tree_select

=item tree_delete

=item tree_insert

=item tree_update

=item get_sections

=item select_fields

=item field_set_list

=back 4

UTILITY FUNCTIONS
add_args
sql_split
arr_split
comma_split
object_list
get_ixhash
deref_args

=head1 STATEMENT OBJECT [*]


=head1 BINARY OPERATORS

Here's a quick list of operators before we get to the full documentation:

    -
    %
    &&
    *
    /
    ^
    ||
    +
    <
    <=
    <=>
    <>
    =
    ==
    >
    >=
    and
    between
    eq
    eqi
    gt
    gti
    iin
    ilike
    in
    is
    like
    lt
    lti
    nand
    ne
    nei
    nor
    or
    xnor
    xor


=head2 -

Unary minus.  Changes positive arguments to negative, negative arguments
to positive. 

    - 4

returns

    -4

=head2 %

Modulus.  Returns the remainder from dividing the first argument
by the second.

    11 % 3

returns

    2

=head2 *

Multiplication.  Multiplies the numeric value of the first argument by
the numeric value of the second.

    2*3

returns

    6

=head2 /

Division.  Divides the numeric value of the first argument by the numeric
    value of the second.

    6/3

returns

    2


=head2 ^

Exponentiation.  Raises the numeric value of the first argument by
the numeric value of the second.

    2^3

returns

    8

=head2 ||

Concatenation.  Returns the first argument concatenated with
the second argument.

    'x' || 'y'

returns

    xy

=head2 |||

Concatenate with space in between.

    'x' ||| 'y'

returns

    x y

If either of the arguments is null then the space is not added. So,
this expression

    'x' ||| null

returns a string consisting solely of 'x'.  Also, the first expression must
end with a non-space and the second expression must begin with a non-space,
or the operator returns the strings concatenated directly without an extra
space in between them.

=head2 +

Addition. Adds the numeric value of the first argument to the numeric
value of the second.

    5-3

returns

    2

=head2 <

Numeric less-than.  Returns true if the numeric value of the first argument
is less than the numeric value of the second.

    5 < 3

returns false.

=head2 <=

Numeric less-than-or-equal-to.  Returns true if the numeric value of the
first argument is less than or equal to the numeric value of the second.

    3<=5

returns true.

=head2 <=>

Same as =.

=head2 <>

Numeric not-equal.  Returns true if the numeric value of the first argument
is not equal to the numeric value of the second.

    1 <> 0

returns true.


=head2 =

String equality.  Returns true if the two arguments are identical strings.
    
    'Joe'='Joe'

returns true.  This operator is case sensitive, so 

    'Joe'='joe'

returns false.  This operator does I<not> compare numerically, so 

    '1.0' = '1'

returns false.  However, unquoted numbers are always normalized, so

    1.0 = 1

returns true.

=head2 ==

Numeric equality.  Returns true if the numeric value of the first argument
is equal to the numeric value of the second.

    '1.0' == '1'

returns true.

=head2 =~

Good old fashioned Perl regular expression matches.  This operator allows you
to do test if a string matches using familiar regex syntax.  For example:

    name =~ m/
        (Joe) |   # regexes can include Perl-style 
        (Steve)   # comments if you use the x param
        /xis

returns true if name contains the strings "Joe" or "Steve", case insensitively.
Like in Perl, the x param means to ignore whitespace, the i means
case-insensitive, and the s means to treat the entire expression like
a single line.

=head2 >

Numeric greater-than.  Returns true if the numeric value of the first argument
is greater than the numeric value of the second.

    5 < 3

returns true.

=head2 >=

Numeric greater-than-or-equal-to.  Returns true if the numeric value of the
first argument is greater than or equal to the numeric value of the second.

    5<=3

returns true.

=head2 AND

Logical and.  Identical to &&.

=head2 BETWEEN

Syntax: I<NumberA> BETWEEN I<NumberB> AND I<NumberC>

Returns true if the NumberA is greater than or equal to NumberB and is also
less than or equal to NumberC.

    1 between -3 and 10

returns true.

=head2 EQ

Case sensitive string equality. 

    'Joe' eq 'Joe'

returns true.

=head2 EQI

Case insensitive string equality.  

    'JOE' eq 'joe'

returns true.

=head2 GT

Case-sensitive string greater-than.  Returns true if the first string is
alphabetically after the second string.

    'pear' gt 'apple'

returns true.  Because it is a case-sensitive comparison, lower-case
characters are greater then upper case characters:

    'Pear' gt 'apple'

returns false.

=head2 GTI

Case-insensitive string greater-than.  Returns true if the first string is
alphabetically after the second string on a case-insensitive basis.

    'Pear' gti 'apple'

returns true.

=head2 IIN

Case-insensitive version of IN.  See IN below.

=head2 ILIKE

Case-insensitive version of LIKE.  See LIKE below.

=head2 IN

Returns true if the argument before IN is in the list
of arguments after IN.  

    'Joe' in 'Steve', 'Joe', 'Fred'

returns true.  IN is case-sensitive.  Use IIN for case-insensitivity.

=head2 IREGEXP

Case-insensitive version of REGEXP.

=head2 IS NULL, IS NOT NULL

C<IS NULL> returns true of the preceding argument is null (that's undef to us
Perl folk).  An empty string is *not* null. C<IS NOT NULL> return true if
the preceding argument is not null.


=head2 LIKE

Like, y'know, returns true if the second argument can be found anywhere in
the first argument. 

    'Hi there Joey!' like 'there'

returns true.  LIKE recognizes two special characters.  C<_> means "any one
character", and C<%> means "zero or more of any character".  So, for example,
the following expression matches if NAME contains a string that begins with
"J", then any one character, then "e".  So "Hi Joe!", "Yo, Jae!", and "Jxe"
would all match, but not "Jake".

    NAME like 'J_e'

For another example, the following expression returns true if NAME contains
a string that starts with "J", then zero or more characters, then "e".  So "Je",
and "Yo, Jack, how are ya?" would both match:

    NAME like 'J%e'

ILIKE works just like LIKE, but is case-insensitive.

=head2 LT

String less-than. 

    'apple' lt 'pear'

returns true.

=head2 LTI

Case-insensitive string less-than. 

    'apple' lt 'Pear'

returns true.

=head2 NAND

Logical NAND.  Returns true unless I<both> arguments are true.

    true  nand true    -- returns false
    true  nand false   -- returns true
    false nand true    -- returns true
    false nand false   -- returns true

=head2 NE

String not-equal.  Returns true if the string values of the two
arguments are not the same.

    'Joe' ne 'Fred'

returns true.  This function is case-sensitive.

=head2 NEI

Case-insensitive string not-equal.  Returns true if the string
values of the two arguments are case-insensitively not the same.

    'Joe' nei 'Fred'

returns true, whereas 

    'JOE' nei 'joe'

returns false.

=head2 NOR

Logical NOR.  Returns true if I<both> arguments are false.

    true  nor true    -- returns false
    true  nor false   -- returns false
    false nor true    -- returns false
    false nor false   -- returns true

=head2 OR

Logical OR.  Returns true if either of the arguments is true.

    true  or true    -- returns true
    true  or false   -- returns true
    false or true    -- returns true
    false or false   -- returns false

=head2 REGEXP

Regular expression.  Returns the results of matching the first argument
against the second. Uses plain old Perl regular expression syntax.

    'whatever' regexp 'e*v'

returns true.  This operator is case sensitive.  Use IREGEXP for a case-insensitivity.

See also the C<=~> operator for regexes that work like good old fashioned Perl regexes. 

=head2 XNOR

Logical XNOR.  Returns true if the truth of both arguments is equal.  

    true  xnor true    -- returns true
    true  xnor false   -- returns false
    false xnor true    -- returns false
    false xnor false   -- returns true

=head2 XOR

Logical XOR.  Returns true if the truth of both arguments is I<not> equal.

    true  xor true    -- returns false
    true  xor false   -- returns true
    false xor true    -- returns true
    false xor false   -- returns false

=head1 FUNCTIONS [*]

I'm still working on documenting all the functions.  Here's a list of
implemented functions so far to tide you over until I've gotten them
all properly documented.

    -
    +
    abs
    cat
    cat_ws
    ceil
    ceiling
    char
    cmp
    coalesce
    concat
    concat_ws
    crunch
    defined
    elt
    err
    false
    field
    floor
    hascontent
    hasnull
    hex
    if
    insert
    instr
    int
    isnull
    lcase
    left
    length
    load_file
    locate
    lower
    lpad
    ltrim
    mid
    mod
    not
    null
    oct
    ord
    position
    pow
    power
    repeat
    replace
    reverse
    right
    rpad
    rtrim
    sign
    soundex
    space
    square
    squared
    strcmp
    substr
    substring
    substring_index
    tcase
    title
    tolower
    totitle
    toupper
    trim
    true
    ucase
    undef
    upper

=head1 TO DO

Operators I haven't implemented yet:
    ascii
    conv
    bin
    octet_length
    char_length
    character_length
    bit_length
    
    find_in_set
    make_set
    export_set
    
    many math functions

=head1 TERMS AND CONDITIONS

Copyright (c) 2003 by Miko O'Sullivan.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. This software comes with B<NO WARRANTY>
of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>


=head1 VERSION

=over

=item Version 0.10    June 12, 2003

Initial release

=item Version 0.11    June 28, 2003

Removed Debug::ShowStuff from module, which was only
there for (as you might expect) debugging.

=item Version 0.12    January 2, 2015

Cleaned up test.pl. Noting that this module is no longer being developed.
Noting some prerequisites. Changed CR's to Unix style. Changed encoding to
UTF-8.

=back



=cut

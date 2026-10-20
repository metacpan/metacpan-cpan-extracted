package Term::Fabulous::Theme::Document;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

class Term::Fabulous::Theme::Document :strict(params) {
	use File::Basename ();
	use File::Spec;
	use Encode qw(decode encode FB_CROAK);
	use Feature::Compat::Try;
	use List::Util qw(any first max);
	use Storable qw(dclone);
	use Text::KDL::XS::Parser;
	use Term::Fabulous::Check qw(color describe);
	use Term::Fabulous::Theme;

	my %IS_STATE = map { $_ => 1 } grep { $_ ne 'normal' } Term::Fabulous::Theme::states();
	my %IS_TOKEN = map { $_ => 1 } Term::Fabulous::Theme::tokens();
	my %IS_BASE  = map { $_ => 1 } Term::Fabulous::Theme::builtin_names();

	# Words KDL 2 does not take as bare strings.
	my %KEYWORD = map { $_ => 1 } qw(true false null inf -inf nan);

	field $text :param :reader;

	# The source split into lines, each with its line end; line N of the
	# messages is $lines[N - 1].
	field @lines;

	# The tree of the document: containers ({ children, tail }) and items
	# (nodes, comments, slashdashed nodes) with the lines they span. undef
	# when the text is not valid KDL.
	field $root;
	field $kdl_version = 2;
	field $indent_unit = "\t";
	field $newline     = "\n";

	# What the document sets: key => { spec, line, path, prop, family,
	# variant, slot, state }, and the keys in document order.
	field %setting;
	field @setting_keys;
	field @variant_names;
	field %variant_line;

	field @errors;
	field $theme;
	field $theme_built = 0;

	ADJUST {
		die "Term::Fabulous::Theme::Document: the text must be a character string, got " . describe($text) unless defined $text && !ref $text;
		@lines   = split /(?<=\n)/, $text;
		$newline = "\r\n" if @lines && $lines[0] =~ /\r\n\z/;

		my $events = $self->_events;
		if ( defined $events ) {
			$root = _tree( $events, \@lines );
			_measure( $root, \@lines, 0, scalar(@lines) + 1 );
			$indent_unit = _indent_unit( $root, \@lines ) // "\t";
			$self->_walk;
		}
	}

	# ---------------------------------------------------------------------
	# Construction
	# ---------------------------------------------------------------------

	method parse :common ($kdl) {
		return $class->new( text => $kdl );
	}

	method read_file :common ($path) {
		die "Term::Fabulous::Theme::Document: read_file needs a file name, got " . describe($path) unless defined $path && !ref $path && length $path;
		open my $handle, '<:raw', $path or die "Term::Fabulous::Theme::Document: cannot open '$path': $!\n";
		my $bytes = do { local $/; <$handle> };
		close $handle;
		my $kdl;
		try {
			$kdl = decode( 'UTF-8', $bytes, FB_CROAK );
		}
		catch ($error) {
			die "Term::Fabulous::Theme::Document: '$path' is not UTF-8 text\n";
		}
		$kdl =~ s/\A\x{FEFF}//;
		return $class->new( text => $kdl );
	}

	# Writes the text to a new file next to the target and renames it over
	# the target, so the target is never half written; an existing file
	# keeps its permissions, a symbolic link its target.
	method write_file ($path) {
		die "Term::Fabulous::Theme::Document: write_file needs a file name, got " . describe($path) unless defined $path && !ref $path && length $path;
		$path = _link_target($path) if -l $path;    # a link stays a link: its target is written
		die "Term::Fabulous::Theme::Document: cannot write '$path': it is read-only\n" if -e $path && !-w $path;
		my $mode      = ( stat $path )[2];
		my $temporary = "$path.tmp-$$";
		open my $handle, '>:raw', $temporary or die "Term::Fabulous::Theme::Document: cannot write '$temporary': $!\n";
		my $written = print {$handle} encode( 'UTF-8', $text );
		my $closed  = close $handle;

		unless ( $written && $closed ) {
			my $reason = $!;
			unlink $temporary;
			die "Term::Fabulous::Theme::Document: cannot write '$temporary': $reason\n";
		}
		chmod $mode & oct(7777), $temporary if defined $mode;
		unless ( rename $temporary, $path ) {
			my $reason = $!;
			unlink $temporary;
			die "Term::Fabulous::Theme::Document: cannot replace '$path': $reason\n";
		}
		return $self;
	}

	# Where a symbolic link points, also when that file does not exist yet.
	sub _link_target ($link) {
		my $target = readlink $link // die "Term::Fabulous::Theme::Document: cannot read the link '$link': $!\n";
		$target = File::Spec->catfile( File::Basename::dirname($link), $target ) unless File::Spec->file_name_is_absolute($target);
		return -l $target ? _link_target($target) : $target;
	}

	# ---------------------------------------------------------------------
	# Parsing: events with their lines
	# ---------------------------------------------------------------------

	# The events of the text as KDL 2, or else as KDL 1; undef with the
	# error of the KDL 2 attempt recorded when neither reads it.
	method _events () {
		my ( $events, $error ) = _events_as( \@lines, 2 );
		return $events if defined $events;
		my ($legacy) = _events_as( \@lines, 1 );
		if ( defined $legacy ) {
			$kdl_version = 1;
			return $legacy;
		}
		push @errors, $error;
		return undef;
	}

	# The parser reads one line per call of its source, so an event comes
	# while its own line is the last one read.
	sub _events_as ( $lines, $version ) {
		my $read   = 0;
		my $source = sub { return $read < @$lines ? $lines->[ $read++ ] : undef };
		my @events;
		try {
			my $parser = Text::KDL::XS::Parser->new( $source, version => $version, emit_comments => 1 );
			while ( my $event = $parser->next_event ) {
				push @events, { %$event, line => $read };
			}
		}
		catch ($error) {
			$error =~ s/\AKDL parse error: //;
			return ( undef, { line => max( 1, $read ), message => 'KDL syntax: ' . _without_location($error) } );
		}
		return ( \@events );
	}

	sub _without_location ($message) {
		$message =~ s/\s+at \S+ line \d+\.?\n?\z//;
		$message =~ s/\n\z//;
		return $message;
	}

	# ---------------------------------------------------------------------
	# The tree
	# ---------------------------------------------------------------------

	sub _value_of ($value) {
		return { type => $value->type, value => $value->is_string ? $value->value : $value->as_string };
	}

	# The nodes and comments of the events. A slashdashed node (/-) is an
	# item of its own, kept with its content; slashdashed arguments and
	# properties of a node are kept on the node (slashed). A comment on a
	# block's closing line, after its last node, belongs to the block.
	sub _tree ( $events, $lines ) {
		my $document = { children => [] };
		my @open     = ($document);
		foreach my $event (@$events) {
			my ( $kind, $line ) = @{$event}{qw(event line)};
			my $inside = $open[-1]{commented_scope};
			if ( $kind eq 'comment' ) {
				_add_comment( $open[-1], $event->{text}, $line );
				next;
			}
			if ( $kind eq 'start_node' ) {
				my $slashed = $event->{commented} && !$inside;
				my $node    = {
					type            => $slashed ? 'slashdash' : 'node',
					name            => $event->{name},
					args            => [],
					props           => [],
					children        => [],
					first           => $line,
					last            => $line,
					commented_scope => $inside || $slashed ? 1 : 0,
				};
				push @{ $open[-1]{children} }, $node;
				push @open,                    $node;
				next;
			}
			if ( $kind eq 'argument' || $kind eq 'property' ) {
				my $value = _value_of( $event->{value} );
				my $entry = $kind eq 'argument' ? $value : [ $event->{name}, $value ];
				if ( $event->{commented} && !$inside ) {
					$value->{bare} = 1 if $kind eq 'property' && $event->{name} =~ /style\z/;    # written as it most likely was
					push @{ $open[-1]{slashed} }, [ $kind, $entry ];
					next;
				}
				push @{ $open[-1]{ $kind eq 'argument' ? 'args' : 'props' } }, $entry;
				next;
			}
			my $node = pop @open;
			$node->{last} = $line;
			my $kids = $node->{children};
			my @closing;
			unshift @closing, pop @$kids while @$kids && $kids->[-1]{type} eq 'comment' && $kids->[-1]{last} == $line && grep { $_->{type} ne 'comment' } @$kids;
			$node->{closing_comment} = join ' ', map { $_->{text} } @closing if @closing;
		}
		return $document;
	}

	# A comment on the line a node starts, before its children, belongs to
	# the node (it follows the head); any other is an item of its own.
	sub _add_comment ( $container, $comment, $line ) {
		my $first = $line - ( $comment =~ tr/\n// );
		if ( ( $container->{type} // '' ) eq 'node' && !@{ $container->{children} } && $first == $container->{first} && !defined $container->{comment} ) {
			$container->{comment} = $comment;
			return;
		}
		push @{ $container->{children} }, { type => 'comment', text => $comment, first => $first, last => $line };
		return;
	}

	# Records, for every item, the blank lines before it (gap), whether it
	# shares a line with what comes before it, and whether it shares one
	# with the head or the end of its container; and for every container,
	# the blank lines before its end (tail). Lines between items that are
	# not blank (a head spread over several lines) make the item share.
	sub _measure ( $container, $lines, $start, $end ) {
		my $previous_last = $start;
		foreach my $item ( @{ $container->{children} } ) {
			$item->{gap}         = _blank_lines( $lines, $previous_last + 1, $item->{first} - 1 );
			$item->{shares_line} = ( $item->{first} <= $previous_last || !defined $item->{gap} ) ? 1 : 0;
			$item->{gap} //= '';
			$item->{shares_parent} = ( $item->{first} <= $start || $item->{last} >= $end ) ? 1 : 0;
			$previous_last = max( $previous_last, $item->{last} );
			_measure( $item, $lines, $item->{first}, $item->{last} ) if $item->{type} ne 'comment';
		}
		$container->{tail}        = _blank_lines( $lines, $previous_last + 1, $end - 1 );
		$container->{tail_shares} = ( $previous_last >= $end || !defined $container->{tail} ) ? 1 : 0;
		$container->{tail} //= '';
		return;
	}

	sub _blank_lines ( $lines, $from, $to ) {
		my $blank = '';
		foreach my $number ( $from .. $to ) {
			my $line = $lines->[ $number - 1 ] // return undef;
			return undef if $line =~ /\S/;
			$blank .= $line;
		}
		return $blank;
	}

	# The indentation of the first indented child line, if any.
	sub _indent_unit ( $document, $lines ) {
		foreach my $node ( grep { $_->{type} eq 'node' } @{ $document->{children} } ) {
			my $child = first { !$_->{shares_line} } @{ $node->{children} } or next;
			my ($indent) = $lines->[ $child->{first} - 1 ] =~ /\A([ \t]+)/;
			return $indent if defined $indent;
		}
		return undef;
	}

	# ---------------------------------------------------------------------
	# The theme the tree describes: settings, checked, with their lines
	# ---------------------------------------------------------------------

	method _error ( $item, $message ) {
		push @errors, { line => $item->{first}, message => $message };
		return;
	}

	method _walk () {
		my ( $theme_node, $palette_node );
		my $children = $root->{children};
		foreach my $index ( 0 .. $#$children ) {
			my $node = $children->[$index];
			next unless $node->{type} eq 'node';
			my $name = $node->{name};
			if ( $name eq 'theme' ) {
				$theme_node ? $self->_error( $node, "the 'theme' node may appear only once" ) : $self->_walk_theme( $node, [$index] );
				$theme_node = $node;
			}
			elsif ( $name eq 'palette' ) {
				$palette_node ? $self->_error( $node, "the 'palette' node may appear only once" ) : $self->_walk_palette( $node, [$index] );
				$palette_node = $node;
			}
			elsif ( !Term::Fabulous::Theme::is_family($name) ) {
				$self->_error( $node, "unknown top-level node '$name' (known: theme, palette and the families " . join( ', ', Term::Fabulous::Theme::families() ) . ")" );
			}
			elsif ( @{ $node->{args} } || @{ $node->{props} } ) {
				$self->_error( $node, "$name: a family node takes no arguments or properties" );
			}
			else {
				$self->_walk_block( $node, $name, 'normal', undef, [$index] );
			}
		}
		@errors = sort { $a->{line} <=> $b->{line} } @errors;
		return;
	}

	method _record ( $key, $value, $item, $path, $prop, %parts ) {
		$setting{$key} = { %parts, key => $key, spec => $value->{type} eq 'null' ? 'none' : $value->{value}, line => $item->{first}, path => $path, prop => $prop };
		push @setting_keys, $key;
		return;
	}

	method _walk_theme ( $node, $path ) {
		my @args = @{ $node->{args} };
		return $self->_error( $node, "the 'theme' node takes at most one argument, the theme's name" ) if @args > 1;
		return $self->_error( $node, "the theme's name must be a string" ) if @args && $args[0]{type} ne 'string';
		return $self->_error( $node, "the 'theme' node has no children" ) if any { $_->{type} eq 'node' } @{ $node->{children} };
		foreach my $prop ( @{ $node->{props} } ) {
			my ( $key, $value ) = @$prop;
			return $self->_error( $node, "the 'theme' node knows only the property 'extends', got '$key'" ) unless $key eq 'extends';
			return $self->_error( $node, "extends must be the name of a built-in theme (" . join( ', ', Term::Fabulous::Theme::builtin_names() ) . "), got " . _shown($value) )
				unless $value->{type} eq 'string' && $IS_BASE{ $value->{value} };
		}
		$self->_record( 'theme.name',    $args[0], $node, $path, undef,     section => 'theme', field => 'name' ) if @args;
		$self->_record( 'theme.extends', $_->[1],  $node, $path, 'extends', section => 'theme', field => 'extends' ) foreach @{ $node->{props} };
		return;
	}

	sub _shown ($value) {
		return $value->{type} eq 'string' ? "'$value->{value}'" : $value->{type} eq 'null' ? '#null' : $value->{value};
	}

	method _walk_palette ( $node, $path ) {
		return $self->_error( $node, "the 'palette' node takes no arguments or properties" ) if @{ $node->{args} } || @{ $node->{props} };
		my $children = $node->{children};
		foreach my $index ( grep { $children->[$_]{type} eq 'node' } 0 .. $#$children ) {
			my $kid   = $children->[$index];
			my $error = _palette_error($kid) // ( exists $setting{"palette.$kid->{name}"} ? "palette: the token '$kid->{name}' is set twice" : undef );
			if ( defined $error ) {
				$self->_error( $kid, $error );
				next;
			}
			$self->_record( "palette.$kid->{name}", $kid->{args}[0], $kid, [ @$path, $index ], undef, section => 'palette', token => $kid->{name} );
		}
		return;
	}

	# What is wrong with a token node of the palette, or undef.
	sub _palette_error ($kid) {
		my $token = $kid->{name};
		return "palette: unknown token '$token' (known: " . join( ', ', Term::Fabulous::Theme::tokens() ) . ")" unless $IS_TOKEN{$token};
		my @args = @{ $kid->{args} };
		return "palette token '$token' needs exactly one string argument"
			unless @args == 1 && $args[0]{type} eq 'string' && !@{ $kid->{props} } && !any { $_->{type} eq 'node' } @{ $kid->{children} };
		return _failure( sub { color( 'Term::Fabulous::Theme', "palette token $token", $args[0]{value} ) } );
	}

	# The message of a check that dies, or undef when it passes.
	sub _failure ($check) {
		try {
			$check->();
		}
		catch ($error) {
			return _theme_message($error);
		}
		return undef;
	}

	sub _theme_message ($error) {
		$error = _without_location($error);
		$error =~ s/\ATerm::Fabulous::Theme: //;
		return $error;
	}

	# The nodes of a family block, or of a state or variant block in it.
	method _walk_block ( $block, $family, $state, $variant, $path ) {
		my $children = $block->{children};
		foreach my $index ( grep { $children->[$_]{type} eq 'node' } 0 .. $#$children ) {
			my $kid  = $children->[$index];
			my $name = $kid->{name};
			if ( $name eq 'variant' ) {
				$self->_walk_variant( $kid, $family, $state, $variant, [ @$path, $index ] );
			}
			elsif ( !$IS_STATE{$name} ) {
				$self->_walk_slot_node( $kid, $family, $state, $variant, [ @$path, $index ] );
			}
			elsif ( $state ne 'normal' ) {
				$self->_error( $kid, "$family: a state cannot be inside another state" );
			}
			elsif ( @{ $kid->{args} } || @{ $kid->{props} } ) {
				$self->_error( $kid, "$family: a state node takes no arguments or properties" );
			}
			else {
				$self->_walk_block( $kid, $family, $name, $variant, [ @$path, $index ] );
			}
		}
		return;
	}

	method _walk_variant ( $node, $family, $state, $variant, $path ) {
		return $self->_error( $node, "$family: a variant cannot be inside a state or another variant" ) if $state ne 'normal' || defined $variant;
		my @args = @{ $node->{args} };
		return $self->_error( $node, "$family: a variant needs exactly one string argument" ) unless @args == 1 && $args[0]{type} eq 'string' && !@{ $node->{props} };
		my $name = $args[0]{value};
		return $self->_error( $node, "$family: a variant name must be a word" ) unless $name =~ /\A[A-Za-z0-9_-]+\z/;
		$variant_line{"$family\[$name]"} //= $node->{first};
		$self->_walk_block( $node, $family, 'normal', $name, $path );
		return;
	}

	method _walk_slot_node ( $node, $family, $state, $variant, $path ) {
		my $name  = $node->{name};
		my @args  = @{ $node->{args} };
		my @props = @{ $node->{props} };
		return $self->_error( $node, "$family: the node '$name' has no children" ) if any { $_->{type} eq 'node' } @{ $node->{children} };
		return $self->_error( $node, "$family: the node '$name' needs either one value or key=value properties" ) if ( @args && @props ) || ( !@args && !@props ) || @args > 1;

		my $where = defined $variant ? "$family: variant '$variant': " : "$family: ";
		my @pairs = @args            ? ( [ $name, $args[0], undef ] )  : map { [ "$name.$_->[0]", $_->[1], $_->[0] ] } @props;
		foreach my $pair (@pairs) {
			my ( $slot_name, $value, $prop ) = @$pair;
			my $full = $state eq 'normal' ? $slot_name : "$slot_name.$state";
			my ( $slot, $slot_state );
			my $error = _failure( sub { ( $slot, $slot_state ) = _slot_and_state( $family, $full ) } );
			$error = defined $error ? ( defined $variant ? "variant '$variant': " : '' ) . $error : _value_error( $family, $slot, $slot_state, $slot_name, $value );
			my $key = defined $error ? undef : key_for( family => $family, variant => $variant, slot => $slot, state => $slot_state );
			$error //= "${where}the slot '$full' is set twice" if defined $key && exists $setting{$key};
			if ( defined $error ) {
				$self->_error( $node, $error );
				next;
			}

			$value->{bare} = 1 if Term::Fabulous::Theme::slot_info( $family, $slot )->{kind} eq 'style';
			push @variant_names, "$family\[$variant]" if defined $variant && !grep { $_ eq "$family\[$variant]" } @variant_names;
			$self->_record( $key, $value, $node, $path, $prop, section => 'slot', family => $family, variant => $variant, slot => $slot, state => $slot_state );
		}
		return;
	}

	# What is wrong with the value of a slot, or undef: a boolean slot
	# takes #true or #false, every other slot a string or #null.
	sub _value_error ( $family, $slot, $state, $slot_name, $value ) {
		my $wanted = Term::Fabulous::Theme::slot_info( $family, $slot )->{kind} eq 'boolean' ? 'bool' : 'string';
		return "$family.$slot_name must be " . ( $wanted eq 'bool' ? '#true or #false' : 'a string or #null' ) unless $value->{type} eq $wanted || $value->{type} eq 'null';
		return _failure( sub { Term::Fabulous::Theme::check_value( $family, $slot, $state, $value->{type} eq 'null' ? undef : $value->{value} ) } );
	}

	# ( slot, state ) of "slot" or "slot.state" in a family.
	sub _slot_and_state ( $family, $name ) {
		return ( $name, 'normal' ) if Term::Fabulous::Theme::has_slot( $family, $name );
		if ( my ( $slot, $state ) = $name =~ /\A(.+)\.([a-z]+)\z/ ) {
			if ( Term::Fabulous::Theme::has_slot( $family, $slot ) ) {
				my $states = Term::Fabulous::Theme::slot_info( $family, $slot )->{states};
				die "the slot $family.$slot has no state '$state' (" . ( @$states ? 'its states: ' . join( ', ', @$states ) : 'it has the normal state only' ) . ")\n"
					unless grep { $_ eq $state } 'normal', @$states;
				return ( $slot, $state );
			}
		}
		my %slots = Term::Fabulous::Theme::slots($family);
		die "the family $family has no slot '$name' (known: " . join( ', ', sort keys %slots ) . ")\n";
	}

	# ---------------------------------------------------------------------
	# Keys
	# ---------------------------------------------------------------------

	sub key_for (%parts) {
		return "theme.$parts{field}" if defined $parts{field};
		return "palette.$parts{token}" if defined $parts{token};
		my $state = $parts{state} // 'normal';
		return $parts{family} . ( defined $parts{variant} ? "[$parts{variant}]" : '' ) . ".$parts{slot}" . ( $state eq 'normal' ? '' : ".$state" );
	}

	sub parse_key ($key) {
		die "Term::Fabulous::Theme::Document: a setting key must be a string, got " . describe($key) unless defined $key && !ref $key;
		return { section => 'theme', field => $1 } if $key =~ /\Atheme\.(name|extends)\z/;
		if ( $key =~ /\Apalette\.(.+)\z/ ) {
			die "Term::Fabulous::Theme::Document: '$key' names an unknown token (known: " . join( ', ', Term::Fabulous::Theme::tokens() ) . ")\n" unless $IS_TOKEN{$1};
			return { section => 'palette', token => $1 };
		}
		my ( $family, $variant, $rest ) = $key =~ /\A([a-z_]+)(?:\[([A-Za-z0-9_-]+)\])?\.(.+)\z/
			or die "Term::Fabulous::Theme::Document: '$key' is not a setting key (theme.name, theme.extends, palette.TOKEN, FAMILY.SLOT[.STATE] or FAMILY[VARIANT].SLOT[.STATE])\n";
		die "Term::Fabulous::Theme::Document: '$key' names an unknown family '$family' (known: " . join( ', ', Term::Fabulous::Theme::families() ) . ")\n"
			unless Term::Fabulous::Theme::is_family($family);
		my ( $slot, $state );
		try {
			( $slot, $state ) = _slot_and_state( $family, $rest );
		}
		catch ($error) {
			die "Term::Fabulous::Theme::Document: '$key': $error";
		}
		return { section => 'slot', family => $family, variant => $variant, slot => $slot, state => $state };
	}

	# ---------------------------------------------------------------------
	# Reading
	# ---------------------------------------------------------------------

	method errors () {
		$self->theme;    # a theme the walk let through but Term::Fabulous::Theme rejects adds its error
		return map {
			{ %$_ }
		} @errors;
	}

	method is_valid () {
		return @errors ? 0 : defined $self->theme ? 1 : 0;
	}

	method has_syntax_error () {
		return defined $root ? 0 : 1;
	}

	# Built from the text by Term::Fabulous::Theme itself, once, when first
	# asked for: what a program that loads the file gets.
	method theme () {
		return $theme if $theme_built;
		$theme_built = 1;
		return undef if @errors;
		try {
			$theme = Term::Fabulous::Theme->from_string($text);
		}
		catch ($error) {
			$error = _without_location($error);
			$error =~ s/\ATerm::Fabulous::Theme: theme: //;
			push @errors, { line => 1, message => $error };
		}
		return $theme;
	}

	method name () {
		return $self->setting('theme.name');
	}

	method extends () {
		return $self->setting('theme.extends') // 'dark';
	}

	method kdl_version () {
		return $kdl_version;
	}

	method setting ($key) {
		my $info = $setting{ key_for( %{ parse_key($key) } ) } // return undef;
		return $info->{spec};
	}

	method setting_keys () {
		return @setting_keys;
	}

	method line_of ($key) {
		return $variant_line{$key} if $key =~ /\A[a-z_]+\[[A-Za-z0-9_-]+\]\z/;
		my $info = $setting{ key_for( %{ parse_key($key) } ) } // return undef;
		return $info->{line};
	}

	method variants () {
		return map { [/\A([a-z_]+)\[(.+)\]\z/] } @variant_names;
	}

	# What a setting is worth when the document does not set it, and where
	# that comes from: the base theme (dark or light) for a palette token,
	# the vocabulary's default for a slot, the normal state for a state
	# that looks like it, the family for a variant.
	method effective_setting ($key) {
		my $parsed = parse_key($key);
		$key = key_for(%$parsed);
		return { spec => $setting{$key}{spec}, origin => 'set' } if exists $setting{$key};
		my $section = $parsed->{section};
		if ( $section eq 'theme' ) {
			return { spec => undef,  origin => 'default' } if $parsed->{field} eq 'name';
			return { spec => 'dark', origin => 'default' };
		}
		if ( $section eq 'palette' ) {
			my $base = $self->extends;
			return { spec => _hex( Term::Fabulous::Theme->builtin($base)->token( $parsed->{token} ) ), origin => $base };
		}
		my ( $family, $variant, $slot, $state ) = @{$parsed}{qw(family variant slot state)};
		if ( defined $variant ) {
			my $of_family = $self->effective_setting( key_for( family => $family, slot => $slot, state => $state ) );
			return { spec => $of_family->{spec}, origin => 'family' } if $state eq 'normal' || $of_family->{origin} ne 'normal';
			return { spec => $self->effective_setting( key_for( family => $family, variant => $variant, slot => $slot ) )->{spec}, origin => 'normal' };
		}
		my $default = Term::Fabulous::Theme::slot_info( $family, $slot )->{default}{$state};
		return { spec => $default, origin => 'default' } unless $default eq 'normal';
		return { spec => $self->effective_setting( key_for( family => $family, slot => $slot ) )->{spec}, origin => 'normal' };
	}

	sub _hex ($rgba) {
		my ( $red, $green, $blue, $alpha ) = @$rgba;
		return sprintf( '#%02x%02x%02x', $red, $green, $blue ) if $alpha == 255;
		return sprintf( '#%02x%02x%02x%02x', $red, $green, $blue, $alpha );
	}

	# ---------------------------------------------------------------------
	# Changing: every change returns a new document
	# ---------------------------------------------------------------------

	method _require_tree ($what) {
		return if defined $root;
		my $error = $errors[0];
		die "Term::Fabulous::Theme::Document: $what needs a document that is valid KDL; line $error->{line}: $error->{message}\n";
	}

	method with_setting ( $key, $value ) {
		$self->_require_tree('with_setting');
		my $parsed = parse_key($key);
		my $spec   = _checked_spec( $parsed, $value );
		my $tree   = dclone($root);
		my $info   = $setting{ key_for(%$parsed) };
		defined $info ? _replace_value( $tree, $info, $spec ) : $self->_insert_setting( $tree, $parsed, $spec );
		return $self->_changed_to($tree);
	}

	method without_setting ($key) {
		$self->_require_tree('without_setting');
		my $info = $setting{ key_for( %{ parse_key($key) } ) } // return $self;
		my $tree = dclone($root);
		_remove_setting( $tree, $info );
		return $self->_changed_to($tree);
	}

	# Applies several changes in order; undef as a value removes the
	# setting.
	method with_settings ($changes) {
		die "Term::Fabulous::Theme::Document: with_settings needs an array reference of [ key, value ] pairs, got " . describe($changes) unless ref $changes eq 'ARRAY';
		my $document = $self;
		foreach my $change (@$changes) {
			die "Term::Fabulous::Theme::Document: with_settings: a change must be [ key, value ], got " . describe($change) unless ref $change eq 'ARRAY' && @$change == 2;
			my ( $key, $value ) = @$change;
			$document = defined $value ? $document->with_setting( $key, $value ) : $document->without_setting($key);
		}
		return $document;
	}

	method without_variant ( $family, $variant ) {
		$self->_require_tree('without_variant');
		die "Term::Fabulous::Theme::Document: unknown family " . describe($family) unless Term::Fabulous::Theme::is_family($family);
		my $tree    = dclone($root);
		my $removed = 0;
		foreach my $block ( grep { $_->{type} eq 'node' && $_->{name} eq $family } @{ $tree->{children} } ) {
			my @indexes = grep { _is_variant( $block->{children}[$_], $variant ) } 0 .. $#{ $block->{children} };
			$removed += @indexes;
			_remove_item( $block, $_ ) foreach reverse @indexes;
		}
		return $self unless $removed;
		_prune_empty( $tree, [] );
		return $self->_changed_to($tree);
	}

	# The document of a changed tree. A change never makes a text worse: one
	# that would leave a syntax error or more errors than the text had dies
	# (a bug in the writer, reported before anything is written).
	method _changed_to ($tree) {
		my $changed = __CLASS__->new( text => $self->_render($tree) );
		my @before  = $self->errors;
		my @after   = $changed->errors;
		return $changed unless $changed->has_syntax_error || @after > @before;
		die "Term::Fabulous::Theme::Document: internal error: the change would break the text ("
			. join( '; ', map { "line $_->{line}: $_->{message}" } @after[ 0 .. 0 ] )
			. "); the document is left as it was\n";
	}

	sub _is_variant ( $item, $variant ) {
		return $item->{type} eq 'node' && $item->{name} eq 'variant' && @{ $item->{args} } && $item->{args}[0]{value} eq $variant;
	}

	# The value as the file will hold it, checked as the theme checks it.
	sub _checked_spec ( $parsed, $value ) {
		die "Term::Fabulous::Theme::Document: a setting needs a string value (use without_setting to remove one), got " . describe($value) unless defined $value && !ref $value;
		my $section = $parsed->{section};
		if ( $section eq 'theme' ) {
			die "Term::Fabulous::Theme::Document: theme.extends must be the name of a built-in theme (" . join( ', ', Term::Fabulous::Theme::builtin_names() ) . "), got '$value'\n"
				if $parsed->{field} eq 'extends' && !$IS_BASE{$value};
			return { type => 'string', value => $value };
		}
		my $checked;
		try {
			$checked
				= $section eq 'palette'
				? color( 'Term::Fabulous::Theme', "palette token $parsed->{token}", $value )
				: Term::Fabulous::Theme::check_value( @{$parsed}{qw(family slot state)}, $value );
		}
		catch ($error) {
			die "Term::Fabulous::Theme::Document: " . _theme_message($error) . "\n";
		}
		my $kind = $section eq 'slot' ? Term::Fabulous::Theme::slot_info( @{$parsed}{qw(family slot)} )->{kind} : 'color';
		return { type => 'bool', value => $checked } if $kind eq 'boolean';    # 'true' or 'false'
		return { type => 'string', value => $value, ( $kind eq 'style' ? ( bare => 1 ) : () ) };
	}

	sub _item_at ( $tree, $path ) {
		my $item = $tree;
		$item = $item->{children}[$_] foreach @$path;
		return $item;
	}

	sub _replace_value ( $tree, $info, $spec ) {
		my $node = _item_at( $tree, $info->{path} );
		if ( defined $info->{prop} ) {
			$_->[1] = $spec foreach grep { $_->[0] eq $info->{prop} } @{ $node->{props} };
		}
		else {
			$node->{args}[0] = $spec;
		}
		$node->{dirty} = 1;
		return;
	}

	sub _new_node ( $name, %parts ) {
		return {
			type => 'node', name => $name, args => $parts{args} // [], props => $parts{props} // [], children => [], gap => $parts{gap} // '', shares_line => 0, tail => '',
			block => $parts{block} // 0
		};
	}

	sub _first_node_named ( $container, $name, $test = sub { 1 } ) {
		return first { $_->{type} eq 'node' && $_->{name} eq $name && $test->($_) } @{ $container->{children} };
	}

	# Puts an item into a container at an index; the container has changed.
	sub _insert_item ( $container, $index, $item ) {
		splice @{ $container->{children} }, $index, 0, $item;
		$container->{changed} = 1;
		return $item;
	}

	# The index before the leading comments of the first node: where a
	# theme or palette node goes at the top of a document.
	sub _top_index ($tree) {
		my $children = $tree->{children};
		my $index    = first { $children->[$_]{type} eq 'node' } 0 .. $#$children;
		return scalar @$children unless defined $index;
		$index-- while $index > 0 && _is_attached_comment( $children, $index - 1 );
		return $index;
	}

	# A comment on lines of its own right above the next item, with no
	# blank line between: it belongs to that item.
	sub _is_attached_comment ( $children, $index ) {
		my ( $comment, $next ) = @{$children}[ $index, $index + 1 ];
		return 0 unless defined $next && $comment->{type} eq 'comment';
		return !$comment->{shares_line} && !$next->{shares_line} && $next->{gap} eq '' ? 1 : 0;
	}

	# Inserts a top-level node, separated by a blank line from its
	# neighbors.
	sub _insert_top ( $tree, $index, $node ) {
		my $children = $tree->{children};
		$node->{gap} = $index > 0 ? "\n" : '';
		my $next = $children->[$index];
		$next->{gap} = "\n" if defined $next && $next->{gap} eq '' && !$next->{shares_line};
		return _insert_item( $tree, $index, $node );
	}

	method _insert_setting ( $tree, $parsed, $spec ) {
		my $section = $parsed->{section};
		if ( $section eq 'theme' ) {
			my $node = _first_node_named( $tree, 'theme' );
			if ( !defined $node ) {
				$node = _insert_top( $tree, _top_index($tree), _new_node('theme') );
			}
			$parsed->{field} eq 'name' ? unshift( @{ $node->{args} }, $spec ) : push( @{ $node->{props} }, [ extends => $spec ] );
			$node->{dirty} = 1;
			return;
		}
		if ( $section eq 'palette' ) {
			my $palette = _first_node_named( $tree, 'palette' );
			if ( !defined $palette ) {
				my $theme_node = first { $tree->{children}[$_]{type} eq 'node' && $tree->{children}[$_]{name} eq 'theme' } 0 .. $#{ $tree->{children} };
				$palette = _insert_top( $tree, defined $theme_node ? $theme_node + 1 : _top_index($tree), _new_node( 'palette', block => 1 ) );
			}
			_insert_item( $palette, _end_index($palette), _new_node( $parsed->{token}, args => [$spec] ) );
			return;
		}

		my ( $family, $variant, $slot, $state ) = @{$parsed}{qw(family variant slot state)};
		my $target = _first_node_named( $tree, $family ) // _insert_top( $tree, scalar @{ $tree->{children} }, _new_node( $family, block => 1 ) );
		$target = _first_node_named( $target, 'variant', sub ($node) { _is_variant( $node, $variant ) } )
			// _insert_item( $target, _end_index($target), _new_node( 'variant', args => [ { type => 'string', value => $variant } ], block => 1 ) )
			if defined $variant;
		$target = _first_node_named( $target, $state, sub ($node) { !@{ $node->{args} } && !@{ $node->{props} } } )
			// _insert_item( $target, _index_before( $target, sub ($name) { $name eq 'variant' } ), _new_node( $state, block => 1 ) )
			unless $state eq 'normal';

		if ( my ( $head, $key ) = $slot =~ /\A(.+)\.([^.]+)\z/ ) {
			my $grouped = _first_node_named( $target, $head, sub ($node) { !@{ $node->{args} } && @{ $node->{props} } } );
			if ( defined $grouped ) {
				push @{ $grouped->{props} }, [ $key, $spec ];
				$grouped->{dirty} = 1;
				return;
			}
			_insert_item( $target, _index_before( $target, \&_is_block_name ), _new_node( $head, props => [ [ $key, $spec ] ] ) );
			return;
		}
		_insert_item( $target, _index_before( $target, \&_is_block_name ), _new_node( $slot, args => [$spec] ) );
		return;
	}

	# After the last item of a container.
	sub _end_index ($container) {
		return scalar @{ $container->{children} };
	}

	sub _is_block_name ($name) {
		return $IS_STATE{$name} || $name eq 'variant' ? 1 : 0;
	}

	# Where a new item goes in a block: before the first node whose name
	# passes the test (and the comments attached to it), else at the end.
	# Slots go before the state and variant blocks, states before the
	# variants.
	sub _index_before ( $container, $test ) {
		my $children = $container->{children};
		my $index    = first { $children->[$_]{type} eq 'node' && $test->( $children->[$_]{name} ) } 0 .. $#$children;
		return scalar @$children unless defined $index;
		$index-- while $index > 0 && _is_attached_comment( $children, $index - 1 );
		return $index;
	}

	sub _remove_setting ( $tree, $info ) {
		my @path   = @{ $info->{path} };
		my $node   = _item_at( $tree, \@path );
		my $parent = _item_at( $tree, [ @path[ 0 .. $#path - 1 ] ] );
		if ( defined $info->{prop} ) {
			$node->{props} = [ grep { $_->[0] ne $info->{prop} } @{ $node->{props} } ];
		}
		elsif ( ( $info->{section} // '' ) eq 'theme' ) {
			shift @{ $node->{args} };
		}
		else {
			$node->{args} = [];
		}
		$node->{dirty} = 1;
		_remove_item( $parent, $path[-1] ) unless @{ $node->{args} } || @{ $node->{props} };
		_prune_empty( $tree, [] );
		return;
	}

	# Removes an item with the comments attached to it.
	sub _remove_item ( $container, $index ) {
		my $children = $container->{children};
		my $from     = $index;
		$from-- while $from > 0 && _is_attached_comment( $children, $from - 1 );
		my $next = $children->[ $index + 1 ];
		$next->{gap} = $children->[$from]{gap} if defined $next && $from == 0 && !$next->{shares_line};

		# Neighbors that shared a line with the removed items cannot copy
		# that line any more.
		$children->[ $from - 1 ]{dirty} = 1 if $from > 0 && $children->[$from]{shares_line};
		$next->{dirty} = 1 if defined $next && $next->{shares_line};
		splice @$children, $from, $index - $from + 1;
		$container->{changed} = 1;
		return $from;
	}

	# Removes palette, family, state and variant blocks that hold nothing
	# any more (a block with a comment or a slashdashed node stays).
	sub _prune_empty ( $container, $path ) {
		my $children = $container->{children};
		my $index    = $#$children;
		while ( $index >= 0 ) {
			my $item = $children->[$index];
			if ( $item->{type} eq 'node' && _is_block( $item, $path ) ) {
				_prune_empty( $item, [ @$path, $item->{name} ] );
				$index = _remove_item( $container, $index ) unless @{ $item->{children} };
			}
			$index--;
		}
		return;
	}

	# Palette and family nodes at the top, state and variant nodes inside
	# them, are blocks; a theme node and slot nodes are not.
	sub _is_block ( $node, $path ) {
		my $name = $node->{name};
		return $name eq 'palette' || Term::Fabulous::Theme::is_family($name) ? 1 : 0 unless @$path;
		return 0 if $path->[0] eq 'palette';
		return $IS_STATE{$name} || $name eq 'variant' ? 1 : 0;
	}

	# ---------------------------------------------------------------------
	# Writing: untouched lines are copied, changed nodes written anew
	# ---------------------------------------------------------------------

	method _render ($tree) {
		return $self->_render_items( $tree, 0 );
	}

	sub _is_pristine ($item) {
		return 0 unless defined $item->{first};
		return 0 if $item->{dirty} || $item->{changed};
		return 1 if $item->{type} eq 'comment';
		return _all_pristine( $item->{children} );
	}

	sub _all_pristine ($items) {
		return ( any { !_is_pristine($_) } @$items ) ? 0 : 1;
	}

	method _source ( $from, $to ) {
		return join '', @lines[ $from - 1 .. $to - 1 ];
	}

	# The children of a container: runs of items that share lines are
	# copied as they were when nothing in them changed.
	method _render_items ( $container, $depth ) {
		my $children = $container->{children};
		my $out      = '';
		my $index    = 0;
		while ( $index < @$children ) {
			my $last = $index;
			$last++ while $last + 1 < @$children && $children->[ $last + 1 ]{shares_line};
			my @run         = @{$children}[ $index .. $last ];
			my $whole_lines = !$run[0]{shares_line} && !any { $_->{shares_parent} } @run;
			if ( $whole_lines && _all_pristine( \@run ) ) {
				$out .= $run[0]{gap} . $self->_source( $run[0]{first}, max map { $_->{last} } @run );
			}
			else {
				# Items that share lines are written anew, each on its own;
				# copying their lines would copy their neighbors too.
				$out .= $run[0]{gap};
				$out .= $self->_render_item( $_, $depth, $whole_lines && @run == 1 ) foreach @run;
			}
			$index = $last + 1;
		}
		$out .= $container->{tail} unless $container->{tail_shares};
		return $out;
	}

	# An item, from its source lines when it owns them and did not change,
	# else written anew.
	method _render_item ( $item, $depth, $owns_lines ) {
		my $indent = $indent_unit x $depth;
		return $self->_source( $item->{first}, $item->{last} ) if $owns_lines && _is_pristine($item);
		return $indent . $item->{text} . $newline if $item->{type} eq 'comment';

		my $comment  = defined $item->{comment}         ? " $item->{comment}"         : '';
		my $closing  = defined $item->{closing_comment} ? " $item->{closing_comment}" : '';
		my $head     = $indent . $self->_node_head($item);
		my $has_kids = @{ $item->{children} } ? 1 : 0;
		return $head . $comment . $newline unless $has_kids || $item->{block};
		return $head . " {$comment$newline" . $indent . "}$closing$newline" unless $has_kids;
		return $indent . $self->_one_line($item) . $newline if defined $item->{first} && $item->{first} == $item->{last};    # with its comments
		return $self->_source( $item->{first}, $item->{first} ) . $self->_render_items( $item, $depth + 1 ) . $self->_source( $item->{last}, $item->{last} )
			if $self->_keeps_frame($item);
		return $head . " {$comment$newline" . $self->_render_items( $item, $depth + 1 ) . $indent . "}$closing$newline";
	}

	# A node whose own head did not change keeps its head line and its
	# closing line when they hold nothing else.
	method _keeps_frame ($node) {
		return 0 if $node->{dirty} || !defined $node->{first} || $node->{first} == $node->{last} || $node->{shares_line} || $node->{shares_parent};
		my $children = $node->{children};
		return 0 if @$children && ( $children->[0]{shares_line} || $node->{tail_shares} );
		return 0 unless $lines[ $node->{first} - 1 ] =~ /\{\s*(?:\/\/.*)?\R?\z/;
		return 0 unless $lines[ $node->{last} - 1 ]  =~ /\A\s*\}\s*(?:\/\/.*|\/\*.*\*\/\s*)?\R?\z/;
		return 1;
	}

	# A block that was written on one line stays on one line, with its
	# block comments and slashdashed nodes.
	method _one_line ($node) {
		my @kids = grep { $_->{type} ne 'comment' || $_->{text} =~ m{\A/\*} } @{ $node->{children} };
		my $head = $self->_node_head($node) . ( defined $node->{comment} && $node->{comment} =~ m{\A/\*} ? " $node->{comment}" : '' );
		my $end  = defined $node->{closing_comment} ? " $node->{closing_comment}" : '';
		return $head . $end unless @kids || $node->{block};

		# A node ends with ; before whatever follows it; a comment needs no ;.
		my ( $inside, $after_node ) = ( '', 0 );
		foreach my $kid (@kids) {
			my $is_comment = $kid->{type} eq 'comment';
			$inside .= ( $after_node ? '; ' : length $inside ? ' ' : '' ) . ( $is_comment ? $kid->{text} : $self->_one_line($kid) );
			$after_node = !$is_comment;
		}
		return "$head { $inside }$end";
	}

	method _node_head ($node) {
		my @slashed = map { $_->[0] eq 'argument' ? '/-' . $self->_value( $_->[1] ) : '/-' . _name( $_->[1][0] ) . '=' . $self->_value( $_->[1][1] ) } @{ $node->{slashed} // [] };
		return ( $node->{type} eq 'slashdash' ? '/-' : '' ) . join ' ', _name( $node->{name} ), ( map { $self->_value($_) } @{ $node->{args} } ),
			( map { _name( $_->[0] ) . '=' . $self->_value( $_->[1] ) } @{ $node->{props} } ), @slashed;
	}

	sub _is_bare_word ($word) {
		return $word =~ /\A[A-Za-z_][A-Za-z0-9_.\-]*\z/ && !$KEYWORD{$word} ? 1 : 0;
	}

	sub _name ($word) {
		return _is_bare_word($word) ? $word : _quoted($word);
	}

	method _value ($value) {
		my $type = $value->{type};
		return $kdl_version == 1 ? 'null' : '#null' if $type eq 'null';
		return ( $kdl_version == 1 ? '' : '#' ) . $value->{value} if $type eq 'bool';
		return $value->{value} if $type eq 'number';
		return $value->{value} if $value->{bare} && $kdl_version == 2 && _is_bare_word( $value->{value} );
		return _quoted( $value->{value} );
	}

	my %ESCAPE = ( "\\" => "\\\\", '"' => '\\"', "\n" => '\\n', "\r" => '\\r', "\t" => '\\t', "\b" => '\\b', "\f" => '\\f' );

	sub _quoted ($string) {
		( my $escaped = $string ) =~ s/(["\\\n\r\t\b\f])/$ESCAPE{$1}/g;
		$escaped =~ s/([\x00-\x1F\x7F])/sprintf('\\u{%x}', ord $1)/ge;
		return qq{"$escaped"};
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Theme::Document - A theme file you can read, check and
change, keeping its comments and layout

=head1 SYNOPSIS

	use Term::Fabulous::Theme::Document;

	my $document = Term::Fabulous::Theme::Document->read_file('themes/ocean.kdl');

	# Is it a theme Term::Fabulous can load?
	foreach my $error ( $document->errors ) {
		printf "line %d: %s\n", $error->{line}, $error->{message};
	}
	my $theme = $document->theme;    # a Term::Fabulous::Theme, or undef

	# What it sets, and what a key is worth when it sets nothing.
	say $document->setting('palette.accent');                       # #5fd3c0
	say $document->effective_setting('button.border.color.focused')->{spec};    # accent

	# Changes return a new document; the old one stays as it was.
	my $warmer = $document
		->with_setting( 'palette.accent', '#ff9e64' )
		->with_setting( 'button[primary].text', 'accent' )
		->without_setting('divider.line.style');
	$warmer->write_file('themes/ocean-warm.kdl');

=head1 DESCRIPTION

A theme file (see L<Term::Fabulous::Theme/THEME FILES>) is a KDL
document. This class reads one as text, checks it the way
L<Term::Fabulous::Theme> does, and tells for every mistake the line it
is on, which C<< Term::Fabulous::Theme->from_file >> cannot. It also
changes settings in the text: a change rewrites only the lines that
hold the changed setting and adds new settings where they belong (a
slot in its family's block, a state in its state block), so comments,
blank lines, indentation, line ends and the order of everything else
stay as they were. A setting removed with L</without_setting> takes the
comment right above it along, and a block that becomes empty goes too.

L<Term::Fabulous::ThemeEditor> works on this class: its form changes
the text with L</with_setting>, and its text mode shows the
L</errors> at their lines. Use it on its own to check theme files in a
test or to change them from a script.

A document never changes. L</with_setting>, L</without_setting>,
L</with_settings> and L</without_variant> return a new document with
the new text; reading it again with L</parse> gives the same document.

=head2 Setting keys

A setting is named by a key:

=for highlighter language=text

	theme.name                          the name in the theme node
	theme.extends                       the built-in theme it starts from
	palette.TOKEN                       a palette token: palette.accent
	FAMILY.SLOT                         a slot in the normal state: button.border.color
	FAMILY.SLOT.STATE                   a slot in a state: button.border.color.focused
	FAMILY[VARIANT].SLOT[.STATE]        a slot of a variant: button[primary].text

The families, slots, states and tokens are those of
L<Term::Fabulous::Theme/VOCABULARY>; an unknown name dies, naming the
known ones. C<FAMILY.SLOT.normal> is the same key as C<FAMILY.SLOT>.
A key names one setting, wherever it is in the file: C<border
style=Round color="border"> in the C<button> block holds the keys
C<button.border.style> and C<button.border.color>, and
C<focused { text "accent" }> in it holds C<button.text.focused>.

=head2 Values

Values are strings as the file holds them: a token name (C<accent>), a
color in a format L<Term::Fabulous::Color> reads (C<#5fd3c0>), a
border style name (C<Round>), C<none> (also for C<#null> in the file),
C<reverse>, or C<true> or C<false> for C<border.enabled>, which the file
holds as C<#true> or C<#false> (C<true> or C<false> in a KDL 1 file).
L</with_setting> checks a value as the theme does before it writes it,
so a document never gets a value its slot cannot take from this class.

=head1 CONSTRUCTORS

=head2 parse

	my $document = Term::Fabulous::Theme::Document->parse($kdl);

A document of a character string. It never dies for what the text
holds: mistakes become L</errors>. Dies only when the text is not a
string. An empty string is an empty theme (one that changes nothing in
the built-in C<dark>).

=head2 read_file

	my $document = Term::Fabulous::Theme::Document->read_file($path);

A document of a file, read as UTF-8; a byte order mark at its start is
dropped. Dies when the file cannot be read or is not UTF-8 text.

=head1 METHODS

=head2 text

The text of the document, a character string.

=head2 errors

	foreach my $error ( $document->errors ) {
		warn "theme.kdl line $error->{line}: $error->{message}\n";
	}

Every mistake in the text, sorted by line, each a hash reference with
C<line> (counted from 1) and C<message>. A text that is not valid KDL
has a single error, at the line where the KDL parser stopped, with a
message that starts with C<KDL syntax:>. Otherwise every mistake of
the theme is listed: an unknown node, token, family, slot or state, a
node with the wrong arguments, properties or children, a value its
slot cannot take, a setting given twice. Empty for a valid theme.

=head2 is_valid

1 when L</errors> is empty, else 0.

=head2 has_syntax_error

1 when the text is not valid KDL, else 0. Such a document cannot be
changed: the change methods die.

=head2 theme

	my $theme = $document->theme;

The L<Term::Fabulous::Theme> the text describes, built by
L<Term::Fabulous::Theme/from_string> when first asked for, or C<undef>
when the text has errors.

=head2 name

The theme's name (C<theme.name>), or C<undef>.

=head2 extends

The built-in theme it starts from: C<theme.extends>, or C<dark> when
the text does not say.

=head2 kdl_version

2, or 1 for a text that only KDL 1 reads. Changes to a KDL 1 text are
written in KDL 1.

=head2 setting

	my $value = $document->setting('button.border.color.focused');

The value the text gives a key (see L</Values>), or C<undef> when it
gives none. Dies for a key that is not one (see L</Setting keys>).

=head2 setting_keys

The keys the text sets, in the order they appear in it.

=head2 variants

	foreach my $variant ( $document->variants ) {
		my ( $family, $name ) = @$variant;
	}

The variants the text defines with at least one setting, as
C<[ family, name ]> pairs in the order they appear in it.

=head2 line_of

	my $line = $document->line_of('palette.accent');
	my $line = $document->line_of('button[primary]');

The line a key is set on, or the line of a variant's first block given
as C<FAMILY[VARIANT]>; C<undef> when the text does not set it.

=head2 effective_setting

	my $effective = $document->effective_setting('button.text.hovered');
	# { spec => 'text', origin => 'normal' }

What a key is worth in the theme, as a hash reference with C<spec>
(the value, see L</Values>) and C<origin>, which says where it comes
from:

=over

=item C<set>

the text sets it;

=item C<dark> or C<light>

a palette token the text does not set: the base theme's color, as
C<#rrggbb> (or C<#rrggbbaa> for a translucent one);

=item C<default>

a slot the text does not set: the vocabulary's default
(L<Term::Fabulous::Theme/slot_info>), the same in both base themes;

=item C<normal>

a state that looks like the slot's normal state, unless a theme sets
it: C<spec> is the normal state's value;

=item C<family>

a slot of a variant that the variant does not set: the family's value.

=back

C<theme.name> without a name has the C<spec> C<undef>; C<theme.extends>
without one is C<dark> (C<default>).

=head2 with_setting

	my $changed = $document->with_setting( 'button.border.color.focused', 'danger' );

A new document in which the key has the value. The value is checked as
the theme checks it and dies with the reason when the slot cannot take
it (C<Term::Fabulous::Theme::Document: tabs.line.style cannot be
'none'>); C<undef> dies, see L</without_setting>. A key the text sets
gets the new value in its place; the line holding it is written anew,
the rest of the text stays. A value for C<border.enabled> may also be C<1> or
C<0>; the file gets C<#true> or C<#false>. A new key is added: to the
family's first block (made at the end of the text when there is none),
in its state block or variant block (made as needed), next to a node
with the same head (C<border color="accent"> gets C<style=Round>
added); a token to
the palette block, the name and the base to the theme node. Dies when
the text is not valid KDL (L</has_syntax_error>); other errors do not
stop changes.

=head2 without_setting

	my $changed = $document->without_setting('palette.accent');

A new document without the key's setting, so the key falls back to
what L</effective_setting> then says. The node holding it goes (or the
property, when the node holds others), with the comment right above
it; a palette, family, state or variant block left without settings
goes too. A key the text does not set returns the document itself.

=head2 with_settings

	my $changed = $document->with_settings( [
		[ 'palette.accent',     '#ff9e64' ],
		[ 'button.text.hovered', undef ],      # removed
	] );

Several changes in order, each as L</with_setting>, or as
L</without_setting> for C<undef>.

=head2 without_variant

	my $changed = $document->without_variant( 'button', 'primary' );

A new document without the variant's blocks and everything in them; the
document itself when it has none. Dies for an unknown family.

=head2 write_file

	$document->write_file('themes/ocean.kdl');

Writes the text to a file as UTF-8 and returns the document. The text
goes to a temporary file in the same directory first, which is then
renamed over the target, so the target is never half written; an
existing target keeps its permissions. Dies when the file cannot be
written.

=head1 FUNCTIONS

=head2 parse_key

	my $parsed = Term::Fabulous::Theme::Document::parse_key('button[primary].text.focused');
	# { section => 'slot', family => 'button', variant => 'primary', slot => 'text', state => 'focused' }

A key taken apart: C<section> is C<theme> (with C<field>), C<palette>
(with C<token>) or C<slot> (with C<family>, C<variant> or C<undef>,
C<slot> and C<state>). Dies for a key that is not one.

=head2 key_for

	my $key = Term::Fabulous::Theme::Document::key_for( family => 'button', slot => 'text', state => 'focused' );

The key of the parts L</parse_key> returns; a C<normal> state is left
out.

=head1 SEE ALSO

L<Term::Fabulous::Theme>, L<Term::Fabulous::ThemeEditor>,
L<Term::Fabulous::Manual::Looks/THEMES>, L<Text::KDL::XS>.

=cut

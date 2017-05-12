package Ravenel::Tag;

use strict;
use Data::Dumper;
use Carp qw(confess cluck);

use fields qw(
	action type depth
	start_pos end_pos tag_inner arguments
	close_start_pos close_end_pos document inner_block
	parent_document parent_tags child_tags
	code expanded simple
	dynamic static_pos
	format_arguments
);

use lib qw(..);
use Ravenel::Block;
use Ravenel::Document;
use Ravenel::Tag::Replace;

sub parse_flags {
	my $class       = shift if ( $_[0] eq 'Ravenel::Tag' );
	my $flag_string = shift;

	my %flags;
	foreach my $f ( split(" ", $flag_string) ) {
		if ( $f eq 'simple' ) {
			$flags{'simple'} = 1;
		} elsif ( $f eq 'format' ) {
			$flags{'format'} = 1;
		} else {
			my ( $key, $value ) = split(/=/, $f);
			$value =~ s/^"//;
			$value =~ s/"$//;
			$flags{$key} = $value;
		}
	}
	return \%flags;
}

sub new {
	my Ravenel::Tag $self = shift;
	my $option            = shift;

	unless ( ref($self) ) {
		$self = fields::new($self);
	}

	$self->{'tag_inner'}       = $option->{'inner'};
	my ( $action, $flags )     = $self->{'tag_inner'} =~ /^([^\s]+)[\s\=]*(.*)$/;
	$self->{'action'}          = $action;

	$self->{'start_pos'}       = $option->{'start_pos'};
	$self->{'end_pos'}         = $option->{'end_pos'};
	$self->{'close_start_pos'} = $option->{'close_start_pos'};
	$self->{'close_end_pos'}   = $option->{'close_end_pos'};
	$self->{'type'}            = $option->{'type'};
	$self->{'parent_document'} = $option->{'parent_document'};
	$self->{'dynamic'}         = $option->{'dynamic'};
	my $content                = $self->{'parent_document'}->{'document'};

	my $flag_struct = &parse_flags($flags);

	foreach my $key ( keys(%{$flag_struct}) ) {
		if ( $key eq 'depth' ) {
			$self->{'depth'} = $flag_struct->{$key};
		} elsif ( $key eq 'simple' ) {
			$self->{'simple'} = 1;
		} else {
			$self->{'arguments'}->{$key} = $flag_struct->{$key};
		}
	}
	return $self;
}

sub calculate_inner_block {
	my Ravenel::Tag $self = shift;

	my $content = $self->{'parent_document'}->{'document'};

	$self->{'inner_block'} = substr($content, $self->{'end_pos'} + 1, $self->{'close_start_pos'} - $self->{'end_pos'} - 1);

	return;
}

sub _escape_double_quotes {
	my $block = shift;
	confess("Internal function only") if ( ref($block) eq 'Ravenel::Tag' );

	$block =~ s/\"/\\\"/g;
	return $block;
}

sub _determine_action {
	my Ravenel::Tag $self     = shift;
	my Ravenel::Document $doc = $self->{'parent_document'};

	my ( $package, $sub_name ) = $self->{'action'} =~ /^([\w:]+)\:(.+)$/;
	$package =~ s/:/::/g; # any sub-classes get expanded accordingly

	if ( $package ) {
		return ( $package, $sub_name );
	} else {
		my $pack_can;
		eval ( "\$pack_can = " . $doc->{'name'} . "->can('$self->{'action'}');" );

		if ( $pack_can ) {
			if ( $doc->{'dynamic'} ) {
				my $s;
				eval ( "\$s = \\&$doc->{'name'}::$self->{'action'};" );
				return ( undef, $s );
			} else {
				return (undef, $self->{'action'});
			}
		}

		# We may be looking for a function defined in main, if so, return that
		if ( main->can($self->{'action'}) ) {
			if ( $doc->{'dynamic'} ) {
				my $s;
				eval ( "\$s = \\&main::$self->{'action'};" );
				return ( undef, $s );
			} else {
				return (undef, $self->{'action'});
			}
		}

		if ( $doc->{'functions'} ) {
			confess("Local function: $self->{'action'} not found") if ( not $doc->{'functions'}->{$self->{'action'}} );
			confess("Local function: $self->{'action'} is not a function reference!") if ( ref($doc->{'functions'}->{$self->{'action'}}) ne 'CODE' );

			if ( $doc->{'dynamic'} ) {
				return ( undef, $doc->{'functions'}->{$self->{'action'}} );
			} else {
				return ( undef, $self->{'action'} );
			}

		} else {
			#print Dumper($doc);
			confess("Local function '$sub_name' not defined in 'functions' code ref hash, see perldoc for details");
		}
	}
	return;
}

sub _stringify_array {
	my $structure = shift;
	my $array = "[ ";
	foreach my $key ( @{$structure} ) {
		$array .= '"' . &_escape_double_quotes($key) . '", ';
	}
	$array .= " ]";
	return $array;
}

sub _stringify_hash {
	my $structure = shift;
	my $hsh = "{ ";
	foreach my $key ( keys(%{$structure}) ) {
		my $value = $structure->{$key};
		if ( ref($value) eq 'ARRAY' ) {
			$hsh .= "'$key' => " . &_stringify_array($value) . ', ';
		} else {
			$hsh .= "'$key' => " . '"' . &_escape_double_quotes($value) . '", ';
		}
	}
	$hsh .= "}";
	return $hsh;
}

sub expand {
	my Ravenel::Tag $self     = shift;
	my Ravenel::Document $doc = $self->{'parent_document'};
	my $content_type          = $doc->{'content_type'};

	my ( $package, $sub_name ) = $self->_determine_action();

	$doc->add_packages($package) if ( $package );

	if ( $self->{'dynamic'} ) {
		if ( $package ) {
			my $package_filename = $package;
			$package_filename =~ s/::/\//g;
			$package_filename .= '.pm';
			require $package_filename if ( ! $INC{$package_filename} );
		}

		my $args = $doc->{'arguments'};

		my $blocks_by_name = $self->get_blocks();

		my $block;
		my $ravenel_block = new Ravenel::Block( { 
			'tag_arguments'    => $self->{'arguments'}, 
			'blocks_by_name'   => $blocks_by_name, 
			'arguments'        => $args, 
			'content_type'     => $content_type, 
			'format_arguments' => $self->{'format_arguments'} 
		} );

		if ( $package ) {
			$block = $package->$sub_name( $ravenel_block );
		} elsif ( ref($sub_name) ) {
			$block = &{$sub_name}( $ravenel_block );
		} else {
			confess("Unknown error determing function!");
		}
		$block = defined($block) ? $block : ''; # returning undef in a tag shorts out lots of logic

		if ( ref($block) ) {
			$self->{'expanded'} = Ravenel::Document->scan($doc->{'prefix'}, $content_type, $block, $doc->{'functions'}, $doc->{'name'}, $doc->{'arguments'});
		} else {
			if ( $self->{'simple'} ) {
				$self->{'expanded'} = $block;
			} else {
				$self->{'expanded'} = Ravenel::Document->scan($doc->{'prefix'}, $content_type, $block, $doc->{'functions'}, $doc->{'name'}, $doc->{'arguments'});
			}
		}
	} else {
		my $func;

		if ( $package ) { 
			$func      = $package . '->' . $sub_name;
		} else {
			$func      = $sub_name; 
		}
		my $ib             = &_stringify_hash($self->get_blocks());
		my $tag_hsh        = &_stringify_hash($self->{'arguments'});
		my $format_hsh     = &_stringify_hash($self->{'format_arguments'});

		my $ravenel_block = "new Ravenel::Block( { 
		'tag_arguments'    => $tag_hsh, 
		'blocks_by_name'   => $ib, 
		'arguments'        => \$args, 
		'content_type'     => \$content_type, 
		'format_arguments' => $format_hsh,
	} )";

		# I need a tag ID here, and pass it as an argument
		if ( $self->{'simple'} ) {
			$self->{'expanded'} = "$func( $ravenel_block )";
		} else {
			$self->{'expanded'} = "Ravenel::Document->scan(\"$doc->{'prefix'}\", '$doc->{'content_type'}', $func( $ravenel_block ), undef, '$doc->{'name'}', \$args)";
		}
	}
	return;
}

sub parent_tags_all_higher_depth {
	my Ravenel::Tag $self     = shift;
	if ( $self->{'parent_tags'} ) {	
		foreach my Ravenel::Tag $pt ( @{$self->{'parent_tags'}} ) {
			if ( $pt->{'depth'} < $self->{'depth'} ) {
				return 0;
			}
		}
		return 1;
	} else {
		return 1;
	}
}

sub get_end_pos {
	my Ravenel::Tag $self     = shift;
	if ( $self->{'type'} eq 'open' ) {
		return $self->{'close_end_pos'};
	} else {
		return $self->{'end_pos'} + 1;
	}
}

my $block_tag = '<block';

sub get_blocks {
	my Ravenel::Tag $self     = shift;

	my $blocks_by_name = {};

	if ( index($self->{'inner_block'}, $block_tag ) >= 0 ) {
		my $pos = 0;
		my @block_tags;
		while ( my $sp = index($self->{'inner_block'}, $block_tag, $pos) ) {
			last if ( $sp == -1 );
			my $ep = index($self->{'inner_block'}, '>', $sp);

			if ( substr($self->{'inner_block'}, $ep - 1, 1) ne '/' ) {
				confess("Block tag is a singleton: " . $self->{'inner_block'});
			}

			my $block_tag = substr($self->{'inner_block'}, $sp, $ep - $sp + 1);
			my ( $block_id ) = $block_tag =~ /id="([^"]+)"/;
			confess("Block does not have a valid id! $block_tag") if ( not $block_id );

			push( @block_tags, { 'sp' => $sp, 'ep' => $ep, 'block_id' => $block_id });
			$pos = $sp + 1;
		}

		# oh boy
		my Ravenel::Document $doc = $self->{'parent_document'};
		my Ravenel::Document $inner_doc = new Ravenel::Document({
			'data'                        => $self->{'inner_block'},
			'prefix'                      => $doc->{'prefix'},
			'content_type'                => $doc->{'content_type'},
			'dynamic'                     => undef,
			'document_is_totally_dynamic' => $doc->{'document_is_totally_dynamic'},
			'functions'                   => $doc->{'functions'},
			'name'                        => 'get_blocks_fake',
		});
		$inner_doc->get_all_tags();
		#$inner_doc->expand_tags(); # XXX pretty sure I don't need this

		# Block tags are only considered if they are not nested within a child tag
		my @applicable_block_tags;
		foreach my $bt ( @block_tags ) {
			foreach my Ravenel::Tag $t ( @{$inner_doc->{'tags'}} ) {
				if ( $t->isa("Ravenel::Tag::Static") ) {
					if ( $bt->{'sp'} > $t->{'start_pos'} 
						and ( 
							not $t->{'end_pos'} 	
							or $bt->{'ep'} < $t->{'end_pos'} 
						)
					) {
						push(@applicable_block_tags, $bt);
					}
				}
			}
		}

		if ( @applicable_block_tags ) {
			my $block_id = 'default';
			my $pos = 0;
			foreach my $bt ( @applicable_block_tags ) {

				my $content = substr($self->{'inner_block'}, $pos, $bt->{'sp'} - $pos );
				$pos = $bt->{'ep'};

				# Store the block by name
				$blocks_by_name->{$block_id} = $content;
				$block_id                    = $bt->{'block_id'};
			}

			my $final_content = substr($self->{'inner_block'}, $pos + 1);
			$blocks_by_name->{$block_id} = $final_content;

		} else {
			$blocks_by_name->{'default'} = $self->{'inner_block'};
		}
	} else {
		$blocks_by_name->{'default'} = $self->{'inner_block'};
	}

	if ( $self->{'arguments'}{'format'} ) {
		$self->{'format_arguments'} = {};
		foreach my $bba ( keys(%{$blocks_by_name}) ) {
			$blocks_by_name->{$bba} =~ s/%/%%/; # sprintf needs escaped percent signs

			while ( my ( $full_k, $k ) = $blocks_by_name->{$bba} =~ /(\{([\w_]+)\})/ ) {
				push(@{$self->{'format_arguments'}->{$bba}}, $k);
				$blocks_by_name->{$bba} =~ s/$full_k/%s/;
			}
		}
	}

	return $blocks_by_name;
}

1;

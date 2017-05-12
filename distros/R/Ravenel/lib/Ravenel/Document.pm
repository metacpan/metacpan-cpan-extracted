package Ravenel::Document;

use strict;
use Data::Dumper;
use Carp qw(cluck confess);
use Ravenel::Redirect;
use Ravenel::Tag;
use Ravenel::Tag::Static;
use Ravenel::Tag::Include;
use Ravenel::Tag::Replace;
use Ravenel::SubScraper;

use fields qw(
	document name prefix content_type docroot
	tags tags_by_depth static_content
	packages arguments
	dynamic document_is_totally_dynamic
	functions
	default_post default_put default_delete
	caller
	lib_path
);

sub new {
	my Ravenel::Document $self = shift;
	my $option                 = shift;

	unless ( ref($self) ) {
		$self = fields::new($self);

		$self->{'docroot'} = $option->{'docroot'} if ( $option->{'docroot'} );

		if ( $self->{'docroot'} and $self->{'docroot'} !~ /\/$/ ) {
			$self->{'docroot'} = "$self->{'docroot'}/";
		}

		if ( $option->{'data'} ) {
			$self->{'document'} = $option->{'data'};
			$self->{'content_type'} = $option->{'content_type'} || 'html'; # XXX Might change my mind :-(
			$self->{'name'}     = $option->{'name'};
		} elsif ( $option->{'file'} ) {

			if ( $option->{'content_type'} ) {
				$self->{'content_type'} = $option->{'content_type'};
			} else {
				( $self->{'content_type'} ) = $option->{'file'} =~ ( /\.(.+)$/ );
			}
			if ( $option->{'name'} ) {
				$self->{'name'}     = $option->{'name'};
			} else {
				( $self->{'name'} ) = $option->{'file'} =~ ( /\/?([^\/\.]+)\..+$/ );
			}

			my $filename = ( $self->{'docroot'} ? $self->{'docroot'} . $option->{'file'} : $option->{'file'} );
			confess("File not found: $filename, $!") if ( not -f $filename );

			open(F, $filename);
			$self->{'document'} = do { local $/; <F> };
			close F;
		}
		$self->{'prefix'}                    ||= 'r:';
		$self->{'dynamic'}                     = $option->{'dynamic'};

		confess("'arguments' is invalid when generating a package (dynamic=$self->{'dynamic'})") if ( $self->{'arguments'} and $self->{'dynamic'} == 0 );

		$self->{'document_is_totally_dynamic'} = $option->{'document_is_totally_dynamic'};
		$self->{'arguments'}                   = $option->{'arguments'};
		$self->{'tags'}                        = [];
		$self->{'functions'}                   = $option->{'functions'};
		$self->{'caller'}                      = $option->{'caller'} || (caller)[1];
 		if ( not $self->{'dynamic'} ) { # if static
			confess("'name' required if not dynamically generated (dynamic=$self->{'dynamic'}, name=$self->{'name'})") if ( not $self->{'name'} );

			# get the libraries
			$self->{'lib_path'} = &get_libraries();
		}

		# replace wrap!
		$self->{'document'} = "<r:replace>$self->{'document'}</r:replace>" if ( $option->{'replace_wrap'} );
	}
	return $self;
}

#########################################
#########################################
# Built in tag handling below

sub _look_for_tag {
        my Ravenel::Document $self = shift;
        my $tag                    = shift || '';
        my $pos                    = shift || 0;
        my $get_close_tag          = shift;
	my $expect_singleton       = shift;

        $get_close_tag = ( $get_close_tag ? '/' : '' );

        my $start_pos = index($self->{'document'}, '<' . $get_close_tag . $self->{'prefix'} . $tag, $pos);

        return if ( $start_pos == -1 );

        my $end_pos = index($self->{'document'}, '>', $start_pos);

        my $beginning_of_tag_content = $start_pos + length("<$self->{'prefix'}");
        my $end_of_tag_content       = $end_pos - $start_pos - length($self->{'prefix'});

        if ( $get_close_tag) { # account for "</" closing tag
                $beginning_of_tag_content++;
                $end_of_tag_content -= 2;
        }

        my $inner = substr( $self->{'document'}, $beginning_of_tag_content, $end_of_tag_content );

        if ( $get_close_tag ) {
                return { 'close_start_pos' => $start_pos, 'close_end_pos' => $end_pos };
        } else {
                if ( $inner =~ /\/>$/ ) {
                        $inner =~ s|/?>||;
                        my ( $action, $option ) = $inner =~ /^([^\s]+)[\s\=]*([^\/]+)?$/;
                        #print "inner=$inner, start_pos=$start_pos, end_pos=$end_pos, action=$action, option=$option\n";
                        return { 'start_pos' => $start_pos, 'end_pos' => $end_pos, 'inner' => $inner, 'action' => $action, 'option' => $option, 'pos' => $end_pos };
		} elsif ( $expect_singleton ) {
			confess("Expected a singleton for tag '$tag'");
                } else {
        		$inner = substr( $self->{'document'}, $beginning_of_tag_content, $end_of_tag_content -1 );

                        my ( $action, $option ) = $inner =~ /^([^\s]+)[\s\=]*([^\/]+)?>$/;
                        #print "look for end tag, action=$action, option=$option\n";

                        my $et = $self->_look_for_tag($action, $end_pos, 'close_tag');
			#print Dumper($et);
			#print "^^^et^^^\n";

                        my $block = substr($self->{'document'}, $end_pos + 1, $et->{'close_start_pos'} - $end_pos - 1);
			#print "|$block|\n";
			#print "^^^inner tag content^^^\n";

			my $ret = { 
				'start_pos'       => $start_pos, 
				'end_pos'         => $end_pos, 
				'close_start_pos' => $et->{'close_start_pos'},
				'close_end_pos'   => $et->{'close_end_pos'},
				'inner'           => $inner, 
				'option'          => $option 
			};

                        return $ret;
                }
        }
}

sub look_for_include {
        my Ravenel::Document $self = shift;

	# Look from the beginning for tag named include that isn't a close tag, but a singleton
        while ( my $res = $self->_look_for_tag('include', 0, 0, 1) ) {

		my Ravenel::Tag::Include $t = new Ravenel::Tag::Include($res, $self);
		$t->expand('replace_content');
        }
        return;
}

sub look_for_action {
        my Ravenel::Document $self = shift;
	my $type                   = shift;

	my $found_cb = 0;

	# Look from the beginning for tag named callback that isn't a close tag, but a singleton
        while ( my $res = $self->_look_for_tag($type, 0, 0, 1) ) { 
		confess("Multiple default callbacks defined for $type") if ( $found_cb );
		$found_cb++;

		my $chop = 2;
		my Ravenel::Tag $t = $self->get_tag_content($res->{'start_pos'}, $res->{'end_pos'}, 'singleton', $chop);
		confess("'name' required in default $type tag in document: $self->{'name'}") if ( not $t->{'arguments'}->{'name'} );

		my ( $package, $sub_name ) = $t->{'arguments'}->{'name'} =~ /^([\w:]+)\:(.+)$/;
		confess("malformed 'name', expecting PACKAGE:SUB_NAME in document: $self->{'name'}") if ( not $package or not $sub_name );

		$package =~ s/:/::/g; # any sub-classes get expanded accordingly
		delete($t->{'arguments'}->{'name'});

		$self->{"default_$type"} = { 'package' => $package, 'sub' => $sub_name, 'arguments' => $t->{'arguments'}, };

                substr(
                        $self->{'document'},
                        $res->{'start_pos'},
                        $res->{'end_pos'} - $res->{'start_pos'} + length($self->{'prefix'}) - 1,
			'',
                );
	}
	return;
}

sub look_for_actions {
        my Ravenel::Document $self = shift;
	$self->look_for_include();
	$self->look_for_action('post');
	$self->look_for_action('put');
	$self->look_for_action('delete');
	return;
}

# End built in tag handling
#########################################
#########################################

sub get_all_tags {
	my Ravenel::Document $self = shift;
	my $tag_name               = shift || '';
	my $get_static_content     = shift;

	$self->{'tags'}          = [];
	$self->{'tags_by_depth'} = [];
	
	my @tags;
	my $pos = 0;

	while ( 1 ) {
		my $t1 = index($self->{'document'}, "<$self->{'prefix'}${tag_name}", $pos);
		my $t2 = index($self->{'document'}, "</$self->{'prefix'}${tag_name}", $pos);

		print "(get_all_tags): pos=$pos,t1=$t1,t2=$t2\n" if ( $Ravenel::debug );

		$t1 = undef if ( $t1 == -1 );
		$t2 = undef if ( $t2 == -1 );

		if ( defined($t1) and defined($t2) ) {
			if ( $t1 < $t2 ) {
				push(@tags, $self->get_tag($t1));
				$pos = $t1 + 1;
			} elsif ( $t2 < $t1 ) {
				push(@tags, $self->get_tag($t2));
				$pos = $t2 + 1;
			}
		} elsif ( defined($t1) ) {
			push(@tags, $self->get_tag($t1));
			$pos = $t1 + 1;
		} elsif ( defined($t2) ) {
			push(@tags, $self->get_tag($t2));
			$pos = $t2 + 1;
		} else {
			last;
		}
	}

	return \@tags if ( $tag_name );

	$self->{'tags'} = \@tags;
	$self->finalize_tags();
	return scalar(@tags);
}

sub get_tag {
	my Ravenel::Document $self = shift;
	my $start_pos    = shift;

	my $end_pos = index($self->{'document'}, '>', $start_pos);

	print "\t(get_tag): start_pos=$start_pos,end_pos=$end_pos\n" if ( $Ravenel::debug );
	print "\t(get_tag): tag=" . substr($self->{'document'}, $start_pos, $end_pos - $start_pos) . "\n" if ( $Ravenel::debug );

	if ( substr($self->{'document'}, $end_pos -1, 1) eq '/' ) {
		print "\t(get_tag): singleton\n" if ( $Ravenel::debug );
		my $chop = 2; # /> = two characters at the end of the tag to remove
		return $self->get_tag_content($start_pos, $end_pos, 'singleton', $chop);

	} elsif ( substr($self->{'document'}, $start_pos + 1, 1) eq '/' ) {
		my $chop   = 2; #
		my $offset = 1; # 
		return $self->get_tag_content($start_pos, $end_pos, 'close', $chop, $offset);

	} else {
		$self->get_tag_content($start_pos, $end_pos, 'open', 1);
	}
}

sub get_tag_content {
	my Ravenel::Document $self = shift;
	my $start_pos              = shift;
	my $end_pos                = shift;
	my $type                   = shift;
	my $chop_end               = shift || 2;
	my $offset                 = shift || 0;

	my $beginning_of_tag_content = $start_pos + length("<$self->{'prefix'}") + $offset;
	my $char_count_inside_tag    = $end_pos - $start_pos - length($self->{'prefix'}) - $chop_end;
	my $inner                    = substr( $self->{'document'}, $beginning_of_tag_content, $char_count_inside_tag );

	print "(get_tag_content): type=$type,inner=$inner\n" if ( $Ravenel::debug );

	my $t;
	if ( $inner =~ /^replace/ ) {
		$t = new Ravenel::Tag::Replace( { 
			'inner'           => $inner, 
			'start_pos'       => $start_pos,
			'end_pos'         => $end_pos,
			'type'            => $type,
			'parent_document' => $self,
			'dynamic'         => $self->{'dynamic'},
		} );
	} else {
		$t = new Ravenel::Tag( { 
			'inner'           => $inner, 
			'start_pos'       => $start_pos,
			'end_pos'         => $end_pos,
			'type'            => $type,
			'parent_document' => $self,
			'dynamic'         => $self->{'dynamic'},
		} );
	}
	return $t;
}

sub finalize_tags {
	my Ravenel::Document $self = shift;

	# Let's get this nested and depth stuff sorted out..
	my @tag_stack;
	foreach my Ravenel::Tag $t ( @{$self->{'tags'}} ) {
		if ( @tag_stack ) {
			if ( $t->{'type'} ne 'close' ) {
				my Ravenel::Tag $parent_tag = $tag_stack[$#tag_stack];
				$t->{'parent_tags'} = [ @tag_stack ];
				push(@{$parent_tag->{'child_tags'}}, $t);
			}
		}

		if ( $t->{'type'} eq 'open' ) {
			push(@tag_stack, $t);

		} elsif ( $t->{'type'} eq 'close' ) {
			confess("Tag stack empty! Looking for close tag? (action=$t->{'action'})\n") unless ( @tag_stack );
			my Ravenel::Tag $open_tag = pop(@tag_stack);

			if ( $t->{'action'} ne $open_tag->{'action'} ) {
				confess("Close tag mismatch, looking for: $open_tag->{'action'}, found: $t->{'action'} (tag_stack: " . scalar(@tag_stack) . ")");
			}
			$open_tag->{'close_start_pos'} = $t->{'start_pos'};
			$open_tag->{'close_end_pos'}   = $t->{'end_pos'} + 1;

			$open_tag->calculate_inner_block();

			$self->add_tag_to_depth_class($open_tag);
			$t = undef;

		} elsif ( $t->{'type'} eq 'singleton' ) {
			$self->add_tag_to_depth_class($t);
		}
	}
	$self->{'tags'} = [ grep { $_ } @{$self->{'tags'}} ]; # filter out the close tags we don't need anymore

	# make sure we have all the closing tags for each open tag
	foreach my Ravenel::Tag $t ( @{$self->{'tags'}} ) {
		confess("End tag not found for $t->{'action'}") if ( $t->{'type'} eq 'open' and not $t->{'end_pos'} );
	}
	
	# now inject static content
	$self->{'tags'} = $self->inject_static_content() if ( not $self->{'dynamic'} );

	return;
}

sub add_tag_to_depth_class {
	my Ravenel::Document $self = shift;
	my Ravenel::Tag $t         = shift;

	if ( defined($t->{'depth'}) ) {
		push(@{$self->{'tags_by_depth'}->[$t->{'depth'}]}, $t);
	} else {
		push(@{$self->{'tags_by_depth'}->[100]}, $t);
	}
	return;
}

sub inject_static_content {
	my Ravenel::Document $self = shift;
	
	my $pos = 0;
	my @tags;

	foreach my Ravenel::Tag $t ( @{$self->{'tags'}} ) {
		if ( $t->{'parent_tags'} ) {
			push(@tags, $t);
			next;
		} else {
			if ( $t->{'start_pos'} > $pos ) {
				push(@tags, new Ravenel::Tag::Static( { 
					'start_pos'       => $pos, 
					'end_pos'         => $t->{'start_pos'}, 
					'parent_document' => $self 
				} ) );
			}
			$pos = $t->get_end_pos();
			push(@tags, $t);
		}
	}

	# If there is static content AFTER the last tag we look at, add that content as a static tag
	# however, the last tag we look at, could be at the end of the document, in which case, don't add one
	my $length_of_document = length($self->{'document'});
	if ( $pos != $length_of_document ) {
		push(@tags, new Ravenel::Tag::Static( { 
			'start_pos' => $pos, 
			'parent_document' => $self 
		} ) );
	}
	return \@tags;
}

sub get_expandable_tags {
        my Ravenel $self   = shift;

	my @expandable_tags;

        foreach my $tag_ref ( @{$self->{'tags_by_depth'}} ) {
                if ( ref($tag_ref) eq 'ARRAY' ) {
                        foreach my Ravenel::Tag $t ( @{$tag_ref} ) {
				my $depth = ( defined($t->{'depth'}) ? $t->{'depth'} : 100 );
			
				if ( $t->{'parent_tags'} ) {
					# if we have nested tags that expand BEFORE this tag, then it cannot be expanded, because it is dynamic
					my $break = 0;
					foreach my Ravenel::Tag $pt ( @{$t->{'parent_tags'}} ) {
						my $parent_depth = ( defined($pt->{'depth'}) ? $pt->{'depth'} : 100 );
						if ( $parent_depth <= $depth ) {
							$break = 1;
							last;
						}
					}
					next if ( $break );
				} 
				push(@expandable_tags, $t);
                        }
                }
		if ( scalar(@expandable_tags) and $self->{'dynamic'} ) {
			#print "Last!!!\n";
			last;
		}
        }
	return \@expandable_tags;
}

sub expand_tags {
        my Ravenel $self   = shift;

	foreach my Ravenel::Tag $t ( @{$self->get_expandable_tags()} ) {
		$t->expand();
	}
	return;
}

sub add_packages {
	my Ravenel::Document $self = shift;
	my $package                = shift;

	$self->{'packages'}->{$package} = 1;
	return;
}

sub build_document {
	my Ravenel::Document $self = shift;

	my $module = qq(
package $self->{'name'};

use strict;
use warnings;
);

	$module .= "use lib qw(" . join(' ', @{$self->{'lib_path'}}) . ");";

	$module .= qq(
use Ravenel;
use Ravenel::Block;
use Ravenel::Document;
use Data::Dumper;

);


	# We should go ahead and scrape these and dump them out of the program so they can be used
	if ( $self->{'functions'} ) {
		my $local_subs = Ravenel::SubScraper->scrape_subs($self->{'caller'});
		foreach my $sub_name ( keys(%{$local_subs}) ) {
			$module .= "\n$local_subs->{$sub_name}\n";
		}
	}

	my $content = qq(sub get_$self->{'content_type'}_content {
	my \$class           = shift if \( \$_[0] eq '$self->{'name'}' \);
	my \$args            = shift;
	my \$dynamic_content = [];
	my \$content_type    = '$self->{'content_type'}';

);

=item
	foreach my $r ( @{$self->{'tags_by_depth'}} ) {
		foreach my Ravenel::Tag $t ( @{$r} ) {
			$t->{'static_pos'} = $static_pos++;
			$content .= "\t\t$t->{'expanded'},\n";
		}
	}
=cut

	my $static_pos = 0;
	my %tags_with_expanded_children;
	foreach my Ravenel::Tag $t ( @{$self->get_expandable_tags()} ) {
		$t->{'static_pos'} = $static_pos++;
=item
		if ( $t->{'child_tags'} ) {
			foreach my Ravenel::Tag $ct ( @{$t->{'child_tags'}} ) {
				if ( $ct->{'expanded'} and $t->{'depth'} > $ct->{'depth'} ) {
					$tags_with_expanded_children{$t} = 1;
				}
			}
		} else {
			$content .= "\t\t\$dynamic_content->[$t->{'static_pos'}] = $t->{'expanded'};\n";
		}
=cut
	}

	#print $self->{'document'} . "\n";
	#map { print $_->{'action'} . "\n"; } @{$self->{'tags'}};

	my $interpolated_document = '';

	foreach my Ravenel::Tag $t ( reverse(@{$self->{'tags'}}) ) {
		if ( $t->isa("Ravenel::Tag::Static") ) {
			$interpolated_document = $t->{'inner_block'} . $interpolated_document;
			next;
		}
		my $sp = $t->{'start_pos'};
		my $ep = $t->get_end_pos();

		if ( not $t->{'parent_tags'} or $t->parent_tags_all_higher_depth() ) {
			if ( $t->{'child_tags'} ) {
				foreach my Ravenel::Tag $ct ( reverse(@{$t->{'child_tags'}}) ) {
					my $t_depth  = ( defined($t->{'depth'})  ? $t->{'depth'}  : 100 );
					my $ct_depth = ( defined($ct->{'depth'}) ? $ct->{'depth'} : 100 );

					print "\t(build_content): action=$t->{'action'},depth=$t_depth,ct_depth=$ct_depth\n" if ( $Ravenel::debug );

					#if ( $ct->{'expanded'} and $t_depth > $ct_depth ) { # XXX this worked before
					if ( defined($ct->{'static_pos'}) and $t_depth > $ct_depth ) { # XXX this worked before
						# Figure out the offset of this tag's start / end, and the child tags, to determine the new offset
						# Replace the child block with it's static_pos

						my $inner_offset = $t->{'end_pos'};

						my $ct_start = $ct->{'start_pos'};
						my $ct_end   = $ct->get_end_pos();

=item
						print "inner_offset = $inner_offset\n";
						print "ct_start     = $ct_start\n";
						print "ct_end       = $ct_end\n";
						print "len1         = " . ( $ct_end - $ct_start ) . "\n";
						print "len2         = " . length($ct->{'tag_inner'}) . "\n";
						
						print "BEFORE: $t->{'inner_block'}\n";
=cut
						substr($t->{'inner_block'}, 
							$ct_start - $inner_offset - 1,
							$ct_end - $ct_start,
							"\$dynamic_content->[$ct->{'static_pos'}]"
						);
=item
						print "AFTER:  $t->{'inner_block'}\n";
						
						print "index    = " . index($t->{'inner_block'}, "<r:m:laa") . "\n";
						print "eindex   = " . index($t->{'inner_block'}, "/>") . "\n";

						my $offset_sp = $ct_start - $t_start - 1;
						my $offset_ep = $ct_end - $t_start;


						print $t->{'inner_block'} . "\n";
						print "offset_sp=$offset_sp, offset_ep=$offset_ep (parent=$t->{'action'}, child=$ct->{'action'})\n";

						substr($t->{'inner_block'}, $offset_sp, $offset_ep - $offset_sp, "\$dynamic_content->[$ct->{'static_pos'}]");
						print "Inner block after=$t->{'inner_block'}\n";
						print "--------------\n\n";
=cut
					}
				}
			}

			if ( not $t->{'parent_tags'} ) {
				$interpolated_document = "\$dynamic_content->[$t->{'static_pos'}]" . $interpolated_document;
			}
		}
	}

	$self->expand_tags();

	foreach my $r ( @{$self->{'tags_by_depth'}} ) {
		foreach my Ravenel::Tag $t ( @{$r} ) {
			if ( defined($t->{'static_pos'}) ) {
				$content .= "\t\$dynamic_content->[$t->{'static_pos'}] = $t->{'expanded'};\n";
			}
		}
	}

	foreach my $p ( keys(%{$self->{'packages'}}) ) {
		$module .= "use $p;\n";
	}

	$module .= "\n$content\n";

	$module .= "\tmy \$body = <<HERE_I_AM_DONE\n${interpolated_document}\nHERE_I_AM_DONE\n;\n";
	$module .= qq(
	chomp\(\$body\);
	return \$body;
}

);

	if ( $self->{'default_post'} ) {
		my $p = $self->{'default_post'}->{'package'};
		my $a = $self->{'default_post'}->{'sub_name'};
		$module .= qq(
sub post {
	my \$class = shift if \( \$_[0] eq '$self->{'name'}' \);

	return Ravenel->handle_post_response\( ${p}->${a}\(\\\@_\) \);
}
);
	}

	$module .= "\n1;\n";

	return $module;
}

sub replace_tags_with_content {
	my Ravenel::Document $self = shift;

	foreach my Ravenel::Tag $t ( reverse(@{$self->{'tags'}}) ) {
		if ( defined($t->{'expanded'}) ) {
			my $sp = $t->{'start_pos'};
			my $ep = $t->get_end_pos();

			#print "~~$t->{'expanded'}~~\n";

                       	substr($self->{'document'}, $sp, $ep - $sp, $t->{'expanded'});

                       	#substr($self->{'document'}, $sp, $ep - $sp + 1, $t->{'expanded'});
		}
	}
}

sub scan {
	my $class        = shift;
	my $prefix       = shift;
	my $content_type = shift;
	my $block        = shift;
	my $functions    = shift;
	my $name         = shift;
	my $arguments    = shift;

	if ( ref($block) ) {
		if ( $block->isa("Ravenel::Redirect") ) {
			# XXX handle redirect
		} else {
			confess("Invalid return type: " . ref($block));
		}
	} else {
		if ( index($block, "<$prefix") >= 0 ) {
			my Ravenel::Document $doc = new Ravenel::Document( {
				'data'         => $block,
				'prefix'       => $prefix,
				'content_type' => $content_type,
				'dynamic'      => 1,
				'functions'    => $functions,
				'name'         => $name,
				'arguments'    => $arguments,
			} );
			return $doc->parse('dynamic');
		} else {
			return $block;
		}
	}
	return;
}

sub get_libraries {
	my $VAR1;
	my $reg_lib = `perl -MData::Dumper -e "print Dumper(\\\@INC);"`;

	eval $reg_lib;
	my %seen;
	my @unique = grep { $seen{$_} == 1 } map { $seen{$_}++; $_ } @{$VAR1}, @INC;
	return \@unique;
}

sub parse {
	my Ravenel::Document $self = shift;

	$self->look_for_actions();

	if ( $self->{'dynamic'} ) {
		while ( $self->get_all_tags() ) {
			$self->expand_tags();
			$self->replace_tags_with_content();
			$self->look_for_actions();
		}
		return $self->{'document'};
	} else {
		$self->get_all_tags();
		return $self->build_document();
	}
	return;
}

sub render {
	my $class  = shift;
        my $option = shift;
        
        confess("Option hash required") if ( not $option or not ref($option) );

        $option->{'dynamic'} = ( defined($option->{'dynamic'}) ? $option->{'dynamic'} : 1 );
	$option->{'caller'} = (caller)[1];

        my Ravenel::Document $document = new Ravenel::Document($option);

        $document->{'document_is_totally_dynamic'} = $option->{'dynamic'};

	return $document->parse();
}

1;

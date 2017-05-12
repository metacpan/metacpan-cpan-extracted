package Pod::Peapod;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.42';

use Data::Dumper;

use  Pod::Simple::Methody;

our @ISA;
BEGIN { push(@ISA,'Pod::Simple'); }

#######################################################################

my %start_new_line_for_element =
	(
	head => 1,
	for => 1,
	Document => 1,
	Para => 1,
	Verbatim => 1,

	'over_bullet' => 0,
	'item_bullet' => 1,

	'over_text' => 0,
	'item_text' => 1,

	'I' => 0,	# italics
	'B' => 0,	# bold
	'C' => 0,	# code

	'L' => 0,	# hyperlink
	);

#######################################################################
sub New
#######################################################################
{
	my ($class) = @_;
	my $parser = $class->SUPER::new();
	$parser->{_show_section_numbers}=1;

	$parser->{_current_attributes}=[ {} ];
	$parser->SetAttribute('_left_margin',0);
	return $parser;
}

#######################################################################
sub parse_string_document
#######################################################################
{
	my ($parser, $string)=@_;

	# call method to clear any preexisting document

	$parser->SUPER::parse_string_document($string);

	# call method to post process
}

#######################################################################
# the following elements are initialized by this subroutine:
#	_start_end
# 	_element_type
#	_head_index	(if =head1, =head2, =head3, etc)
# any attributes created by Pod::Simple will also be aggregated
# into the current attributes. they will NOT be prefixed with an underscore,
# so there should be no collisions between Pod::Simple and 
# Pod::Peapod::Base attributes.
#
# All other methods will then be called to track their own attributes.
# 
#######################################################################
# this method is called by Pod::Simple at the start of every element
#######################################################################
sub _handle_element_start
#######################################################################
{
	my $parser = shift(@_);

	my $element= shift(@_);
	my $attrs = shift(@_);

	my %attributes = %$attrs;

	$attributes{_start_end}='start';


	#############################################################
	# convert _element_type head1 to 
	# _element_type head and a _head_index of 1
	#############################################################
	if($element =~ s{head(\d+)}{head})
		{
		$attributes{_head_index}=$1;
		}

	#############################################################
	# convert hypens in element type to underscores
	# this is so element type fits \w+
	#############################################################
	$element =~ s{\-}{_}g;


	#############################################################
	# now store the filtered element type
	#############################################################
	$attributes{_element_type}=$element;

	#############################################################
	# now that we know element type (and stripped head1 to head)
	# check to see if we should output a newline character.
	#############################################################
	if(exists($start_new_line_for_element{$element}))
		{
		if($start_new_line_for_element{$element})
			{
			$parser->OutputPodNewLine;
			}
		}
	else
		{
		die "Error: unknown element type '$element'";
		}

	if($element eq 'head')
		{
		$parser->OutputTocNewLine;
		}

	#############################################################
	# make sure an array exists to hold current attributes
	#############################################################
	unless(exists($parser->{_current_attributes}))
		{ $parser->{_current_attributes} = []; }

	#############################################################
	# push basic current attributes onto array.
	#############################################################
	push(@{$parser->{_current_attributes}}, \%attributes);

	#############################################################
	# with basic current attributes set, call generated attributes
	#############################################################
	$parser->TrackGeneratedAttributes;

	#############################################################
	# handle section number if enabled.
	#############################################################
	if(
		1 
		and ($element eq 'head')
		and exists($parser->{_show_section_numbers})
		and       ($parser->{_show_section_numbers})
	)
		{ 
		my $section_number = $parser->GetAttribute('_section_number');
		$parser->SetAttribute('_text_string',$section_number);
		$parser->OutputPodText;

		my $head_index = $parser->GetAttribute('_head_index');
		my $pad = ' 'x($head_index);
		$parser->SetAttribute('_text_string',$pad.$section_number);
		$parser->OutputTocText;
		}

	#############################################################
	# call any specific element handlers that have been declared.
	#############################################################
	$parser->_specific_element_handler;
}


#######################################################################
# croak gets confused and goes too far back up the call chain sometimes.
# 'diecaller' just dies from the point of view of two callers ago.
#######################################################################
sub diecaller
#######################################################################
{
	my $error_string  = shift(@_);

	my @caller = caller(1);

	print Dumper \@caller;
	my $module = $caller[1];
	my $line   = $caller[2];

	my $string = "$error_string at $module line $line\n";
	die $string;

}


#######################################################################
# use the following methods to search for existence of attribute 
# anywhere in the array of attribute history.
# might have 'head' followed by 'I' (Italic), and will want the
# Italicized text to also be part of the 'head' element.
#
# this method will allow you to see if the 'history'
# has an attribute '_element_type' with a value of 'head'
#######################################################################
sub SearchHistoryForAttributeMatchingValue
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);
	diecaller("not enough parameters to SearchHistoryForAttributeMatchingValue")if(scalar(@_)==0);
	my $value=shift(@_);

	diecaller("Too many parameters to SearchHistoryForAttributeMatchingValue") if(scalar(@_));

	my $match=0;
	my $ref = $parser->{_current_attributes};

	#eval
	#	{
		foreach my $attrs (@$ref)
			{
			if( exists($attrs->{$attribute}) and ($attrs->{$attribute} eq $value) )
					{
					$match=1 ;
					last;
					}
			}
	#	};
	#diecaller($@) if ($@);

	return $match;
}



#######################################################################
# use the following methods to get a current attribute value
#######################################################################
sub GetAttribute
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);

	diecaller("Too many parameters to GetAttribute") if(scalar(@_));

	my $value;

	eval
		{
		$value = $parser->{_current_attributes}->[-1]->{$attribute};
		};
	diecaller($@) if ($@);

	return $value;
}

#######################################################################
# use the following methods to test for existence of a current attribute
#######################################################################
sub ExistsAttribute
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);

	diecaller("Too many parameters to ExistsAttribute") if(scalar(@_));

	my $exists;

	eval
		{
		$exists = exists($parser->{_current_attributes}->[-1]->{$attribute});
		};
	diecaller($@) if ($@);

	return $exists;
}

#######################################################################
# use the following methods to set a current attribute to a new value
#######################################################################
sub SetAttribute
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);

	diecaller("not enough parameters to SetAttribute") if(scalar(@_)==0);

	my $value=shift(@_);

	croak "Too many parameters to SetAttribute" if(scalar(@_));

	eval
		{
		$parser->{_current_attributes}->[-1]->{$attribute}=$value;
		};
	diecaller($@) if ($@);

	return $value;
}


#######################################################################
# use the following methods to get the previous attribute value
#######################################################################
sub GetPreviousAttribute
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);

	diecaller("Too many parameters to GetPreviousAttribute") if(scalar(@_));

	my $value;

	eval
		{
		$value = $parser->{_current_attributes}->[-2]->{$attribute};
		};
	diecaller($@) if ($@);

	return $value;
}

#######################################################################
# use the following methods to test for existence of a current attribute
#######################################################################
sub ExistsPreviousAttribute
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);

	diecaller("Too many parameters to ExistsPreviousAttribute")if(scalar(@_));

	my $exists;

	return 0 if(scalar(@{$parser->{_current_attributes}}) < 2);

	eval
		{
		$exists = exists($parser->{_current_attributes}->[-2]->{$attribute});
		};
	diecaller($@) if ($@);

	return $exists;
}

#######################################################################
# use the following methods to set a current attribute to a new value
#######################################################################
sub SetPreviousAttribute
#######################################################################
{
	my $parser=shift(@_);
	my $attribute=shift(@_);

	diecaller("not enough parameters to SetAttribute")if(scalar(@_)==0);

	my $value=shift(@_);

	diecaller("Too many parameters to SetPreviousAttribute")if(scalar(@_));

	eval
		{
		$parser->{_current_attributes}->[-2]->{$attribute}=$value;
		};
	diecaller($@) if ($@);

	return $value;
}

#######################################################################
# this method is called by Pod::Simple at the end of every element
#######################################################################
sub _handle_element_end
#######################################################################
{
	my $parser = shift(@_);

	$parser->SetAttribute('_start_end', 'end');

	$parser->TrackGeneratedAttributes;

	$parser->_specific_element_handler;

	pop(@{$parser->{_current_attributes}});

}


#######################################################################
# start_end is either 'start' or 'end'
# element type is whatever element type that Pod::Simple uses
# this will call a ->start_Para method if it exists.
# allows Base classes to add their own behavior easily at specific points.
# i.e. want to do something at the start of a Link, just declare a 
# sub start_L {} method in a base class and it will get called automatically
#######################################################################
sub _specific_element_handler
#######################################################################
{
	my $parser = shift(@_);

	my $element = $parser->GetAttribute('_element_type');
	my $startend     = $parser->GetAttribute('_start_end');

	my $method = $startend .'_'.$element;

	if($parser->can($method))
		{
		$parser->$method;
		}
}


#######################################################################
sub TrackGeneratedAttributes
#######################################################################
{
	my $parser = shift(@_);

	$parser->_track_marker;
	$parser->_track_font;
	$parser->_track_left_margin;
	$parser->_track_section_number;
}



#######################################################################
# some applications, such as a pod viewer using Tk::Text, will need
# unique marker names for each element in the document. This method 
# keeps a runnning counter for each type of element and concatenates
# the counter number to the element type to generate a unique marker name.
# Note that this marker is identical for start, text, and end.
# It is up to the OutputMarker method to concat the start or end string
# to generate a completely unique marker name. This marker name can then
# be inserted at the current 'insert' position. i.e. at the end of the
# document. OutputText will then insert the text at the end, and the 
# marker will stay at the beginning of that text block permanently.
# this can provide a location to tie links to for jumping locations, etc. 
#######################################################################
sub _track_marker
#######################################################################
{
	my $parser=shift(@_);
	my $element = $parser->GetAttribute('_element_type');

	my $marker_type = 'MARKER_'.$element.'_';

	unless(exists($parser->{_marker_counters}->{$marker_type}))
		{
		$parser->{_marker_counters}->{$marker_type}=1;
		}

	my $counter = $parser->{_marker_counters}->{$marker_type}++;

	my $marker_name = $marker_type .'_'. $counter.'_';

	$parser->SetAttribute('_position_marker', $marker_name);

	$parser->OutputMarker;


}

#######################################################################
# base class can override this to set marker if needed. (example: Tk::Text)
# Will want to create a marker based on the two following attributes
# 	marker_name = _position_marker . _start_end
# this will allow programs to "box" in text on either side with unique
# marker names.
#
# If your application needs a marker, simply insert the marker at the
# current 'insert' position. Use the 'insert' position for OutputText 
# method as well, and all your text elements will be boxed by unique markers.
#
# if you dont need markers, then don't override this method and nothing
# will happen.
#######################################################################
sub OutputMarker 
#######################################################################
{
	my $parser = shift(@_);
	my $position_marker = $parser->GetAttribute('_position_marker');
	my $start_end       = $parser->GetAttribute('_start_end');
	my $marker_name = $position_marker . $start_end;

	# if you want to override this method, duplicate this method
	# in your base class, and then do something with $marker_name here.

}

#######################################################################
#######################################################################
sub _track_font
#######################################################################
{
	my $parser=shift(@_);
	my $startend = $parser->GetAttribute('_start_end');
	my $element = $parser->GetAttribute('_element_type');

	if($startend eq 'start')
		{
		if($parser->ExistsPreviousAttribute('_font_family'))
			{
			$parser->SetAttribute('_font_family',
				$parser->GetPreviousAttribute('_font_family') );
			$parser->SetAttribute('_font_size', 
				$parser->GetPreviousAttribute('_font_size') );
			$parser->SetAttribute('_font_weight', 	
				$parser->GetPreviousAttribute('_font_weight') );
			$parser->SetAttribute('_font_slant', 
				$parser->GetPreviousAttribute('_font_slant') );
			$parser->SetAttribute('_font_underline', 
				$parser->GetPreviousAttribute('_font_underline') );
			}
		else
			{
			$parser->SetAttribute('_font_family','lucida');		# lucida, courier
			$parser->SetAttribute('_font_size', 4);			# 1,2,3,4
			$parser->SetAttribute('_font_weight', 'normal');	# normal, bold	
			$parser->SetAttribute('_font_slant', 'roman'); 		# roman, italic
			$parser->SetAttribute('_font_underline', 'nounder');	# yesunder, nounder 
			}

		if(0) {}
		elsif($element eq 'C')
			{ 
			$parser->SetAttribute('_font_family','courier');
			}
		elsif($element eq 'head')
			{
			my $hindex = $parser->GetAttribute('_head_index');
			$parser->SetAttribute('_font_underline', 'yesunder');
			$parser->SetAttribute('_font_size',      $hindex);
			$parser->SetAttribute('_font_weight',    'bold');
			}
		elsif($element eq 'I')
			{ 
			$parser->SetAttribute('_font_slant', 'italic');
			}
		elsif($element eq 'B')
			{ 
			$parser->SetAttribute('_font_weight', 'bold');
			}

		elsif($element eq 'L')
			{ 
			$parser->SetAttribute('_font_underline', 'yesunder');
			}


		}
}

#######################################################################
sub _current_font
#######################################################################
{
	my $parser=shift(@_);
	my $font_string = 
		  ($parser->GetAttribute('_font_family'))
		. ($parser->GetAttribute('_font_size'))
		. ($parser->GetAttribute('_font_weight'))
		. ($parser->GetAttribute('_font_slant'))
		. ($parser->GetAttribute('_font_underline'))
		;

	return $font_string;
}

#######################################################################
sub _track_left_margin
#######################################################################
{
	my $parser=shift(@_);

	my $startend = $parser->GetAttribute('_start_end');

	if($parser->ExistsPreviousAttribute('_left_margin'))
		{
		$parser->SetAttribute
			(
			'_left_margin',
			$parser->GetPreviousAttribute('_left_margin') 
			);
		}
	else
		{
		$parser->SetAttribute('_left_margin',0)
		}

	# the 'indent' attribute comes from Pod::Simple
	# if it exists, grab it and store it.
	# it only exists on 'start' so need to keep it around for 'end'

	unless(exists($parser->{_accumulated_indent_values}))
		{
		$parser->{_accumulated_indent_values}=[];
		}


	my $indent=0;
	if($startend eq 'start')
		{
		if($parser->ExistsAttribute('indent'))	
			{
			$indent=$parser->GetAttribute('indent');
			}
		elsif(!($parser->ExistsAttribute('~type')))
			{
			if($parser->ExistsPreviousAttribute('~type'))	
				{
				$indent += 4;
				}
			}

		push(@{$parser->{_accumulated_indent_values}}, $indent);
		}

	elsif($startend eq 'end')
		{
		$indent = pop(@{$parser->{_accumulated_indent_values}});
		$indent *= -1;
		}

# warn "indent is '$indent'";

	$parser->SetAttribute('_left_margin', 
	$parser->GetAttribute('_left_margin') + $indent);

}


#######################################################################
sub _label_current_section
#######################################################################
{
	my $parser=shift(@_);

	my $temp_ref = $parser->{_stack_of_section_numbers};
	my @section_number;
	my $object_to_label = $temp_ref->[-1];

	while(1)
		{
		push(@section_number, scalar(@$temp_ref));
		$temp_ref = $temp_ref->[-1]->{Subparagraph};
		last unless(scalar( @$temp_ref ));
		$object_to_label = $temp_ref->[-1];
		}

	my $section_string = join('.', @section_number) . ': ';
	$object_to_label->{Section}=$section_string;

	return $section_string;
}

#######################################################################
sub _new_toc_hash
#######################################################################
{
	my $parser=shift(@_);
	my $depth=shift(@_);

	# using a scalar to hold text so when take
	# a reference, it will be a reference to a scalar,
	# (which can be changed) rather than a reference
	# to a literal
	my $temp_text = 'This Paragraph number skipped';

	my $href=
		{
		TextRef => $temp_text,
		Depth=>$depth,
		Subparagraph => [],
		};

	return $href;
}

#######################################################################
sub _track_section_number
#######################################################################
{
	my ($parser)=@_;

	my $element = $parser->GetAttribute('_element_type');
	my $start_end = $parser->GetAttribute('_start_end');

	return unless( ($element eq 'head') and ($start_end eq 'start') );

	unless(exists($parser->{_stack_of_section_numbers}))
		{
		$parser->{_stack_of_section_numbers}=[];
		}

	my $depth = $parser->GetAttribute('_head_index');

	my $href= $parser->_new_toc_hash($depth);

	###############################################################
	# first, figure out where to put the $href entry...
	###############################################################

	my $arr_ref = $parser->{_stack_of_section_numbers};

	for(my $cnt=1; $cnt<$depth; $cnt++)
		{
		unless(scalar(@$arr_ref))
			{
			my $temp= $parser->_new_toc_hash($depth);

			# push it onto end and label it
			push(@$arr_ref, $temp);
			$parser->_label_current_section;
			}

		$arr_ref = $arr_ref->[-1]->{Subparagraph};
		}

	# push it onto end and label it.
	push(@$arr_ref,$href);
	my $section_string = $parser->_label_current_section;

	# set an attribute to point to toc text
	# this will allow someone to modify toc text later
	# when toc text is actually a known value.
	my $toc_text_ref = \$href->{TextRef};
	$parser->SetAttribute('_toc_text_ref', $toc_text_ref);

	$parser->SetAttribute('_section_number', $section_string);
}




#######################################################################
# insert a dummy method here. subclass can override this method and
# have it do whatever it needs.
#######################################################################
sub OutputPodNewLine
#######################################################################
{
	my $parser = shift(@_);

	print "calling Base default method for 'OutputPodNewLine'\n";
}


#######################################################################
# insert a dummy method here. subclass can override this method and
# have it do whatever it needs.
#######################################################################
sub OutputTocNewLine
#######################################################################
{
	my $parser = shift(@_);

	print "calling Base default method for 'OutputTocNewLine'\n";
}




#######################################################################
#######################################################################
#######################################################################
#######################################################################
# this method is called by Pod::Simple when text is encountered.
# the handle_element_start method above makes sure that ALL attributes
# are current by the time the code enters _handle_text.
#######################################################################
#######################################################################
#######################################################################
#######################################################################
#######################################################################
sub _handle_text 
#######################################################################
#######################################################################
#######################################################################
#######################################################################
#######################################################################
{
	my $parser = shift(@_);

#print Dumper \@_;
	my $text = shift(@_);

	my $element = $parser->GetAttribute('_element_type');

	# put bullet in front of bulleted items
	if($element eq 'item_bullet')
		{
		my $bullet = $parser->GetAttribute('~orig_content');
		$text = $bullet.' '.$text;
		}

	$parser->SetAttribute('_text_string', $text);

	if($parser->SearchHistoryForAttributeMatchingValue('_element_type', 'head'))
		{
		my $toc_text_ref = $parser->GetAttribute('_toc_text_ref');
		$$toc_text_ref=$text;
		$parser->OutputTocText;
		}

	###################################################################
	# if a base class wishes to handle links differently,
	# simply create a method called 'output_L' 
	# it will get called any time a link is encountered.
	# 'output_L' could insert the text differently, adding
	# a callback routine so the user can click on link and
	# it will take the user to the file.
	#
	# otherwise, if no special handler exists, call normal OutputPodText.
	###################################################################
	my $method = 'output_'.$element;

	if($parser->can($method))
		{
		$parser->$method;
		}
	else
		{
		$parser->OutputPodText;
		}
}

#######################################################################
# insert a dummy method here. subclass can override this method and
# have it do whatever it needs.
#######################################################################
sub OutputPodText
#######################################################################
{
	my $parser = shift(@_);
	my $text_string = $parser->GetAttribute('_text_string');

	print "calling Base default method for 'OutputPodText'\n";
	print "$text_string \n";
}


#######################################################################
sub OutputTocText
#######################################################################
{
	my $parser = shift(@_);
	my $text_string = $parser->GetAttribute('_text_string');

	print "calling Base default method for 'OutputTocText'\n";
	print "$text_string \n";

}






#######################################################################
#######################################################################
#######################################################################
#######################################################################
sub DESTROY
#######################################################################
#######################################################################
#######################################################################
{
	return;

	my $parser = shift(@_);
	my $toc = $parser->{_stack_of_section_numbers};
	print Dumper $toc;
}

#######################################################################
#######################################################################
#######################################################################

1;
__END__


=head1 NAME

Pod::Peapod - Perl module to provide an easy interface to parsing POD

=head1 SYNOPSIS

  use Pod::Peapod;


=head1 ABSTRACT


=head1 DESCRIPTION



=head2 EXPORT




=head1 SEE ALSO

Pod::Simple

=head1 AUTHOR

Greg London, E<lt>DELETEALLCAPSemail@greglondon.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Greg London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package Regexp::Ignore;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

#############################################################
# new($original_text, $delimiter_pattern)
#############################################################
# the constructor
sub new {
    my $proto = shift; # get the class name
    my $class = ref($proto) || $proto;
    my $self  = {};

    $self->{TEXT} = shift;
    $self->{DELIMITER_PATTERN} = shift;
    
    $self->{DELIMITER_PATTERN_REGULAR_EXPRESSION} = $self->{DELIMITER_PATTERN};
    $self->{DELIMITER_PATTERN_REGULAR_EXPRESSION} = 
	quotemeta($self->{DELIMITER_PATTERN_REGULAR_EXPRESSION});
    $self->{DELIMITER_PATTERN_REGULAR_EXPRESSION} =~ 
	s/__INDEX__/\(\?\:[\\d\]\+\)/g;
    $self->{DELIMITER_PATTERN_REGULAR_EXPRESSION} = 
	qr/$self->{DELIMITER_PATTERN_REGULAR_EXPRESSION}/;
    $self->{TRANSLATION_POSITION_FACTOR} = 0;
    bless ($self, $class);
    return $self;
} # of new

#################
# text
#################
sub text {
    my $self = shift;
    if (@_) { $self->{TEXT} = shift }
    return $self->{TEXT};
} # of text

#################
# delimited_text
#################
sub delimited_text {
    my $self = shift;
    return $self->{DELIMITED_TEXT};
} # of delimited_text

#################
# cleaned_text
#################
sub cleaned_text {
    my $self = shift;
    if (@_) { $self->{CLEANED_TEXT} = shift }
    return $self->{CLEANED_TEXT};
} # of cleaned_text

######################
# delimiter_pattern
######################
sub delimiter_pattern {
    my $self = shift;
    if (@_) { $self->{DELIMITER_PATTERN} = shift }
    return $self->{DELIMITER_PATTERN};
} # of delimiter_pattern

######################
# translation_position_factor
######################
sub translation_position_factor {
    my $self = shift;
    if (@_) { $self->{TRANSLATION_POSITION_FACTOR} = shift }
    return $self->{TRANSLATION_POSITION_FACTOR};
} # of translation_position_factor

########################
# get_tokens
########################
sub get_tokens {
    my $self = shift;
    die("This is an abstract method");
} # of get_tokens

#####################
# split
#####################
sub split {
    my $self = shift;
    # get the tokens
    $self->{TOKENS} = [];
    $self->{FLAGS} = [];    
    ($self->{TOKENS}, $self->{FLAGS}) = $self->get_tokens();

    # now build the delimited text which will hold the wanted tokens and 
    # for each token, a delimiter just before it, that represents the token.
    # build also the cleaned text and the positions translation between them
    $self->{DELIMITED_TEXT} = "";
    $self->{CLEANED_TEXT} = "";
    my $index = 0;    
    my $cleaned_position = 0;
    my $delimited_position = 0;
    my $delimiter_length = length($self->{DELIMITER_PATTERN});
    my @cleaned_to_delimited_positions;
    while (defined($self->{TOKENS}[$index])) {
	if ($self->{FLAGS}[$index]) { # if the flag is 1, the text is clean
	    my $token = $self->{TOKENS}[$index];
	    my $token_length = length($token);

	    # add the token to the cleaned text with the delimiter
	    $self->{DELIMITED_TEXT} .= $token;
	    $self->{CLEANED_TEXT} .= $token;

	    # now keep the positions
	    if ($token_length > 0) {
		for (my $j = 0; $j < $token_length; $j++) {
		    $cleaned_to_delimited_positions[$cleaned_position + $j] = 
			$delimited_position + $j;
#		    print "".($cleaned_position + $j)." ==> ".
#			($delimited_position + $j)."\n";
		}
		$cleaned_position += $token_length;
		$delimited_position += $token_length;
	    }
	}
	else {
	    # create the delimiter and add it to the delimited text. 
	    my $delimiter = $self->{DELIMITER_PATTERN};
	    my $index_string = sprintf("%09d", $index);
	    $delimiter =~ s/__INDEX__/$index_string/g;
	    $self->{DELIMITED_TEXT} .= $delimiter;
	    # add the delimiter length to the $delimited_position
	    $delimited_position += $delimiter_length;
	}
	$index++; # increment the index
    }
    # save the translation hash as a data member
    $self->{CLEANED_TO_DELIMITED_POSITIONS} = \@cleaned_to_delimited_positions;
} # of split

#######################
# s 
#  
# switches: 
#                   e   Evaluate the right side as an expression.
#            second e   The replacement portion is `eval'ed before being 
#                       run as a Perl expression
# e is not yet implemented.
#                   g   Replace globally, i.e., all occurrences.
#                   i   Do case-insensitive pattern matching.
#                   m   Treat string as multiple lines.
#                   o   Compile pattern only once.
#                   s   Treat string as single line.
#                   x   Use extended regular expressions.
#######################
sub s {
    my $self = shift;
    my $pattern = shift;
    my $replacer = shift || "";
    my $switches = shift || "";

    # if there is a g switch, remember it and remove it from 
    # the switches string
    my $g_switch = ($switches =~ s/g//g);
    # the same with e switches
    my $e_switch = ($switches =~ s/e//g);

    # calculate the compiled pattern - include the switches
    my $compiled_pattern = eval("qr/$pattern/$switches");

    # we build the resulted cleaned text (after replacing) in the buffer
    my $buffer = "";
    my $last_position = 0; # holds the position just after each match

    # the translation factor fix the translation table, when we have 
    # a replacer that is different in its size from the match. 
    $self->{TRANSLATION_POSITION_FACTOR} = 0;

    # a flag that we use to implement the g switch.
    my $no_g_counter = 1;

    # counter will count the number of substitutions
    my $counter = 0;

    # the main loop where we match and replace
    while ($no_g_counter && $self->{CLEANED_TEXT} =~ /$compiled_pattern/gc) {
	$no_g_counter = $g_switch; 
	# keep the matching varibales. note that we do not keep the variables
	# $` and $'.
	my $variables = { 1 => $1,
			  2 => $2,
			  3 => $3, 
			  4 => $4, 
			  5 => $5,
			  6 => $6,
			  7 => $7,
			  8 => $8,
			  9 => $9,
		          '&' => $& };
	my $match = $&; # the match itself
	# get the position of the end of the match, the start of the match,
	# and the match length
	my $end_match_position = pos($self->{CLEANED_TEXT}) - 1;
	my $match_length = length($match);
	my $start_match_position = $end_match_position - $match_length + 1;
	# calculate the replacer and its length
	my $this_replacer = $replacer;
	$this_replacer =~ s/\$([0-9])/$variables->{$1}/g;	
	
# here I tried to create the e_switch. there are two problems with it:
# 1. lexical variables from the code that calls this method are not 
#    available for this method.
# 2. I didn't fully understand the way it is done with the real s// 
#    operator - when it is evaled, how to eval the expression without the 
#    variable etc. 
# so meanwhile, use replace.
#	if ($e_switch) {
#	    my ($package, $filename, $line) = caller;
#	    if ($e_switch >= 1) {		
#		my $put_quotes = sub {
#		    my $one = shift || "";
#		    my $two = shift || "";
#		    my $three = shift || "";
#		    if ($one eq '"' && $three eq '"') {
#			return "\'\$$two\'";
#		    }
#		    else {
#			return "$one\'\$$two\'$three";
#		    }
#		};
#		$this_replacer =~ 
#		    s/(\"?)\$(\w+)(\"?)/&$put_quotes($1, $2, $3)/ge;
#		$this_replacer =~ s/\&(\w+)/\&$package\:\:$1/g;
#		print "eval($this_replacer)\n";	    
#		$this_replacer = eval($this_replacer);
#	    }
#	    if ($e_switch == 2) {
#		$this_replacer =~ s/\$(\w+)/\$$package\:\:$1/g;
#		print "eval($this_replacer)\n";
#		$this_replacer = eval($this_replacer);
#	    }
#	}

	my $replacer_length = length($this_replacer);
	
#	print $self->{CLEANED_TEXT}."\n";
	$self->replace(\$buffer,
		       \$last_position,
		       $start_match_position,
		       $end_match_position,
		       $this_replacer);
	$counter++;
    }
    # add the rest of the text in the cleaned text
    $buffer .= substr($self->{CLEANED_TEXT}, $last_position);
    $self->{CLEANED_TEXT} = $buffer;
    return $counter;
} # of s

#####################
# replace
#####################
sub replace {
    my $self = shift;
    my $buffer_ref = shift;
    my $last_position_ref = shift;
    my $start_match_position = shift;
    my $end_match_position = shift;
    my $this_replacer = shift;

    my $match_length = $end_match_position - $start_match_position + 1;
    my $replacer_length = length($this_replacer);

#    print "replace: \$start_match_position=$start_match_position\n";
#    print "replace: \$end_match_position=$end_match_position\n";
#    print "replace: \$match_length=$match_length\n";
#    print "replace: \$replacer_length=$replacer_length\n";
#    print "replace: \$this_replacer=$this_replacer==\n";
#    print "replace: TRANSLATION_POSITION_FACTOR=".
#	$self->{TRANSLATION_POSITION_FACTOR}."\n";
    
    my $translation_array = 
	$self->{CLEANED_TO_DELIMITED_POSITIONS};
	
    # build the buffer of the cleaned text
    $$buffer_ref .= 
	substr($self->{CLEANED_TEXT}, 
	       $$last_position_ref, 
	       $start_match_position - $$last_position_ref).$this_replacer;
    
    # get the start and end positions of the match in the delimited text
    my $delimited_start_match_position = 
	$translation_array->[$start_match_position + 
			     $self->{TRANSLATION_POSITION_FACTOR}];
    my $delimited_end_match_position = 
	$translation_array->[$end_match_position + 
			     $self->{TRANSLATION_POSITION_FACTOR}];
    my $delimited_match_length = $delimited_end_match_position - 
	$delimited_start_match_position + 1;
    
    # get that delimited text in the matched position
    my $delimited_match = substr($self->{DELIMITED_TEXT},
				 $delimited_start_match_position,
				 $delimited_match_length);
#    print "delimited_match=$delimited_match\n";
    my $re = $self->{DELIMITER_PATTERN_REGULAR_EXPRESSION};
    my @delimiters = ($delimited_match =~ /$re/g);
    my $delimited_replacer = $this_replacer.join("",@delimiters);
    $self->{DELIMITED_TEXT} = 
	substr($self->{DELIMITED_TEXT},
	       0, $delimited_start_match_position).
		   $delimited_replacer.
		       substr($self->{DELIMITED_TEXT},
			      $delimited_end_match_position + 1);
    
    # calculate the translation position factor
    my $new_translation_position_factor = $replacer_length - $match_length;

    # fix the translation array
    # first of all we should push (or pull) all the indexes after the 
    # replacer. 
    my $translation_array_size = scalar(@$translation_array);
    
    if ($new_translation_position_factor < 0) {
	# if the factor is negative we should copy the cells in the array
	# from the start to the end (so we do not run over the cells we 
	# want to copy from)
	for (my $i = 
	     $end_match_position + $self->{TRANSLATION_POSITION_FACTOR} + 1; 
	     $i < $translation_array_size; $i++) {
	    $translation_array->[$i + $new_translation_position_factor] = 
		$translation_array->[$i] + $new_translation_position_factor;
	}
    }
    elsif ($new_translation_position_factor > 0) {
	# if the factor is positive we should copy the cells in the array
	# from the end to the start (so we do not run over the cells we 
	# want to copy from)
	for (my $i = $translation_array_size - 1; 
	     $i > $end_match_position + $self->{TRANSLATION_POSITION_FACTOR};
	     $i--) {
	    $translation_array->[$i + $new_translation_position_factor] = 
		$translation_array->[$i] + $new_translation_position_factor;
	}	
    }

    # now we should create the translation for the new replacer. we know,
    # though, that the replacer is put in the start of the region in the 
    # delimited_text (and after it we put all the delimiters). so the 
    # translation is simple:
    for (my $i = 0; $i < $replacer_length; $i++) {	
	$translation_array->[$start_match_position + 
			     $self->{TRANSLATION_POSITION_FACTOR} + $i] =
	    $delimited_start_match_position + $i;
    }
    
    # fix the translation position factor for the next replace calls
    $self->{TRANSLATION_POSITION_FACTOR} += $new_translation_position_factor;

    # set the last_position
    $$last_position_ref = $end_match_position + 1;
} # of replace

#####################
# merge
#####################
sub merge {
    my $self = shift;
    
    my $delimited_text = $self->{DELIMITED_TEXT};

    # $re will hold the regular expression to match a
    # delimiter. yet, it will have around the index a paranthesis, 
    # so the index will go to $1 when there is a match.
    my $re = quotemeta($self->{DELIMITER_PATTERN});
    $re =~ s/__INDEX__/\(\[\\d\]\+\)/g;
    $re = qr/$re/;
    # the buffer will hold the resulted text
    my $buffer = $delimited_text;
    # instead of the pattern, put back the unwanted tokens 
    $buffer =~ s/$re/$self->{TOKENS}[$1]/g;

    # return all the tokens as the text
    $self->{TEXT} = $buffer;
    return $self->{TEXT};
} # of merge

1;
__END__

=head1 NAME

Regexp::Ignore - Let us ignore unwanted parts, while parsing text.

=head1 WARNING

This is an alpha code. Really. It was written in the end of 2001. It is 
not yet checked much. The only reason I submit it to CPAN that early is 
to get feedback about the idea, and hopefully to get some help in finding
the many bugs that must still be in it. 
In our company we use this code, though, and for B<our> needs it runs well. 

=head1 SYNOPSIS

  use Regexp::IgnoreXXX;

  my $rei = new Regexp::IgnoreXXX($text, 
				  "<!-- __INDEX__ -->");
  # split the wanted text from the unwanted text
  $rei->split();  

  # use substitution function
  $rei->s('(var)_(\d+)', '$2$1', 'gi');
  $rei->s('(\d+):(\d+)', '$2:$1');

  # merge back to get the resulted text
  my $changed_text = $rei->merge();

=head1 DESCRIPTION

Markup languages, like HTML, are difficult to parse. The reason is that
you can have a line like:

  <font size=+1>H</font>ello <font size=+1>W</font>orld

How can we find the string "Hello World", in the above line, and replace 
it by "Hello Universe" (which is a lot deeper)? Or how can we run a speller 
on the text and replace the mistakes with suggestions for the correct 
spelling?

This module come to help you doing exactly that. 

Actually the module let you first split the text to the parts you are
interested in and the unwanted parts. For example, all the HTML tags
can be taken as unwanted parts. 

Then it let you parse the part you are interested in (while totally
ignoring the unwanted parts). 

In the end it let you merge back the unwanted parts with the possibly
changed parts you were interested in. 

There is just one catch. It uses the assumption that when you replace
the above "Hello World" to "Hello Universe", all the unwanted parts
between the start of the match to the end of the match, will be pushed
after the text that will replace the match. This is not really
understood right? Look at the example:

The text:

  <font size=+1>H</font>ello <font size=+1>W</font>orld

will be first split and we will get the "cleaned" text:

  Hello World

Then we can parse it using something like:

  s/Hello World/Hello Universe/;

This will give us the changed "cleaned" text:

  Hello Universe

When we will merge with the unwanted parts we will get
  
  <font size=+1>Hello Universe</font><font size=+1></font>

So, the unwanted parts in the match were pushed after the replacer.

Why this assumption? 

Because. Actually, I could not find any better assumption. I can not
guess what will be the unwanted parts in a match and the replacer of
the match might be longer or shorter then the match itself. So, in
fact, we have three reasonable possibilities:
  1. Push the unwanted parts before the replacer.
  2. Push the unwanted parts after the replacer.
  3. Spread the unwanted parts in the replacer in the same 
     proportions that they are spread in the match.

So I chose the second option. It is very similar to the first, and by
far a lot simpler (to implement and to use) then the third. 

As you see in the example above, usually it should not break the
markup language. It might, though, give some surprises - in the
example above, "Hello Universe" is all marked to be with bigger
fonts. 

All in all, I believe that it provides big help when parsing
formatted texts.

So now, that we know what the module can give us, let's check how we
use the module. 

The class Regexp::Ignore is an abstract class: there is a method,
B<get_tokens>, in the class that is not implemented. So the user of
this class must inherit it and implement the B<get_tokens> method.
The B<get_tokens> method actually splits the text into tokens and mark
them "wanted" or "unwanted".

Don't panic - it might sound very difficult, but it is not. Moreover, 
the module comes with some classes that already inherit from
Regexp::Ignore, and you can use them. For more details about
implementing the B<get_tokens> method and an implementation example, 
see below. 

After we have the inherited class that implements the B<get_tokens> 
method, and we call B<split> to split the text, we can go on with our 
parsing like the SYNOPSIS above. We can use the method B<s> which 
is parallel to the perl s// operator, and if we need more complex 
text manipulation, we can replace text directly using the b<replace> 
method.

When we finish to change the text, we can call the B<merge> method
that will build the resulted text from the changed "cleaned" text and
the unwanted parts.

=head1 HOW IT WORKS

OK, you don't have to read this part if you just want to use the
class. However, if you are the curious type, you might find it
interesting.

The B<get_tokens> method splits the text to tokens that are kept in a
list. It also creates other list that contains "wanted" flags. So
actually we get a list of tokens and for each the information if it is
wanted or unwanted.

The B<split> method uses the B<get_tokens> to create the CLEANED_TEXT
and the DELIMITED_TEXT. 

Let's take the example:

  <p><b>bla</b><b>_</b><b>123</b></p>
  <p><b>bLa</b><b>_</b><b>1234567</b></p>

And assuming our B<get_tokens> mark all the HTML tags as unwanted, we
will get:

      tokens list               flags list
  ---------------------      ---------------
   0:   <p>                         0
   1:   <b>                         0
   2:   bla                         1
   3:   </b>                        0   
   4:   <b>                         0
   5:   _                           1
   6:   </b>                        0
   7:   <b>                         0
   8:   123                         1
   9:   </b>                        0
  10:   </p>                        0
  11:   <p>                         0
  12:   <b>                         0
  13:   bLa                         1
  14:   </b>                        0   
  15:   <b>                         0
  16:   _                           1
  17:   </b>                        0
  18:   <b>                         0
  19:   123456                      1
  20:   </b>                        0
  21:   </p>                        0

The CLEANED_TEXT will be:

   bla_123bLa_1234567

And if the delimiter pattern is "<!-- __INDEX__ -->" the
DELIMITED_TEXT will be:  

   <!-- 000000000 --><!-- 000000001 -->bla
   <!-- 000000003 --><!-- 000000004 -->_
   <!-- 000000006 --><!-- 000000007 -->123
   <!-- 000000009 --><!-- 000000010 -->
   <!-- 000000011 --><!-- 000000012 -->bLa
   <!-- 000000014 --><!-- 000000015 -->_
   <!-- 000000017 --><!-- 000000018 -->1234567
   <!-- 000000020 --><!-- 000000021 -->


Now the B<split> method generates an array that contains a translation
of the positions between the cleaned text and the delimited text:

   CLEANED_TO_DELIMITED_POSITIONS array
   ------------------------------------
   0:     36
   1:     37 
   2:     38
   3:     75
   4:    112
   5:    113
   6:    114
   7:    187
   8:    188
   9:    189
  10:    226
  11:    263
  12:    264
  13:    265
  14:    266
  15:    267
  16:    268
  17:    269
 
The following rulers with the cleaned and delimited texts might help
you understand this the translation table:

The CLEANED_TEXT:

             1
   012345678901234567
   bla_123bLa_1234567
   
The DELIMITED_TEXT:

   0         1         2         3        
   012345678901234567890123456789012345678
   <!-- 000000000 --><!-- 000000001 -->bla

    4         5         6         7       
   9012345678901234567890123456789012345  
   <!-- 000000003 --><!-- 000000004 -->_

       8         9         0         1    
   678901234567890123456789012345678901234
   <!-- 000000006 --><!-- 000000007 -->123

        2         3         4         5   
   567890123456789012345678901234567890   
   <!-- 000000009 --><!-- 000000010 -->

            6         7         8         
   123456789012345678901234567890123456789
   <!-- 000000011 --><!-- 000000012 -->bLa

   9         0         1         2
   0123456789012345678901234567890123456
   <!-- 000000014 --><!-- 000000015 -->_

      3         4         5         6 
   7890123456789012345678901234567890123456789
   <!-- 000000017 --><!-- 000000018 -->1234567

   7         8         9         0
   012345678901234567890123456789012345
   <!-- 000000020 --><!-- 000000021 -->


As an example, we call now the B<s> method with something similar to:

   s/(bla)_(\d+)/<font color=red>$2</font>_$1/gi

which will be the call:

   $rei->s('(bla)_(\d+)','<font color=red>$2</font>_$1','gi');

the following will happen:

We will use the m// operator to have the match against the cleaned
text:
  
   m/(bla)_(\d+)/i

This will match first with 'bla_123' in the cleaned text. Now we keep 
the matching variables B<$&> and B<$1>..B<$9>. Then we create the
replacer string by substituting those variables in the string:

   '<font color=red>$2</font>_$1'

We will also keep the exact position where the match happened in the
cleaned text, and the length of the match.

Using the positions of the start and end of the match, we define a
region in the clean text where the match happened, and where the
replacer should be placed. 

In our example this region is 0 to 6.

We can now use the translation array to translate this region to
positions in the delimited text. 

We will get the region 36 to 114 in the delimited text. 

Now we can get deal with those two regions: 

In the clean text it is simple to place the replacer instead of
anything that was in that region.

In the delimited text, we will first put all the delimiters in that
region together. Then we add the replacer before them, and we place
all of this in the region. 

Now the only thing we have to do is to fix the translation table - 
the translation table will not be correct from the start of the
matched region, and if the replacer is different in size from the
match, also after the matched region.

This is why we use the TRANSLATION_POSITION_FACTOR data member. It
keeps the built up difference between the match regions and the
replacers while we parse along the text.

The fix of the translation table is boring indexing manipulations. We
first fix the region of the replacer to represent the new replacer,
and then if there is a difference between the lengths of the match and
the replacer, we fix all the indexes after the match.

After we finish to manipulate the text, we build back our text by
replacing the delimiters in the delimited text by the tokens that
those delimiters represent. This is done by the B<merge> method.

And voila! We get back our text manipulated. 

=head1 CONSTRUCTOR

=over 4

=item new (TEXT, DELIMITER_PATTERN)

Constructs an object of the class. TEXT is the text that we want to
parse. DELIMITER_PATTERN is a string that will be used to create
delimiters while processing the text. It should contain the string
'__INDEX__' that will be replaced by an index, for example: '000000073'. 

That delimiter should be chosen to fit the text that should be
parsed, and to the B<get_tokens> results. For example for HTML text 
we can choose '<!-- __INDEX__ -->' or even <__INDEX__>.
This might be a good delimiter if our B<get_tokens> takes all the HTML
tags as unwanted tokens.

So our choice for a delimiter should be anything that can be used
as a delimiter for the "cleaned" text (after the unwanted parts were
taken away from the text). 

=back

=head1 METHODS

=over 4

=item get_tokens ( )

This is an abstract method. It should be implemented in a daughter
class of this class. Moreover, you will never call this method
directly in your code. The B<split> method will call the B<get_tokens>
method that you implement.

The method should use the B<text> method to get the text it takes as
input. It should return a list of two array references. The first
reference refers to a list of all the tokens, and the second reference
refers to a list of flags (perl TRUE or FALSE, so one or zero for
example). If the flag is FALSE, it means that the token in the other
list in the same index is unwanted. 

As one example is better then many words, here is an implementation of 
the B<get_tokens> method that takes all the HTML tags as unwanted parts:

 sub get_tokens {
     my $self = shift;

     my $tokens = [];
     my $flags = [];
     my $index = 0;
     # we should create tokens from the TEXT.
     my $text = $self->text();
     while (defined($text) && 
 	 # the regular expression will try to match:
 	 #  - HTML remarks - all the remark will be matched. 
 	 #  - HTML other tags 
 	 $text =~ /(<\!\-\-[\s\S]+?\-\->)|(<\/?[^\>]*?>)/i) {
 	 if ($`) { # if there is text before, take it as clean
 	     $tokens->[$index] = $`;
	     # the text before the match is clean. 
 	     $flags->[$index] = 1; 
 	     $index++; # increment the index
 	 }
 	 $tokens->[$index] = $&;
 	 $flags->[$index] = 0; # the match itself is unwanted.
 	 $index++; # increment the index again
  	
 	 $text = $'; # update the original text to after the match.
     }
 
     # if we are done or we had no match at all, check if there is 
     # still something in the $text. this will be also a clean text.
     if (defined($text) && $text) {
 	 $tokens->[$index] = $text;
 	 $flags->[$index] = 1; 
     }
     # return the two list
     return ($tokens, $flags);
 } # of get_tokens

Classes that implement the B<get_tokens> come with this module. Check
first if one of them does not implement the B<get_tokens> you need.

And if you feel you wrote a B<get_tokens> that might be useful for
the rest of us, please let me know about it.

=item split ( )

This method should be called before the B<s> or B<replace> methods are
called. It will use the B<get_tokens> method to split the text to
unwanted tokens and the "cleaned" text. After this method is called
the CLEANED_TEXT and the DELIMITED_TEXT data members are available.

=item s (PATTERN, REPLACEMENT, SWITCHES)

This method implements the perl s// operator while ignoring the
unwanted tokens. See the INTRODUCTION section above, and L<perlop> for
more details. 

You can call this method several times between a call to B<split> and
a call to B<merge>.

B<Important Note>: The 'e' and the double 'e' switches are not yet
implemented. It is very difficult to implement and maybe impossible
without a very sophisticated hack as the method B<s> suppose to see
the values of lexical variables in the code that calls that method. I
do not know how to do that. If someone has ideas - please contact me
or send the patch. Other problem is the way to correctly eval the
REPLACEMENT. It is not totally clear to me how to do that
correctly. Again - if someone can help - please! Meanwhile, though,
you can use the B<replace> method below.

=item replace ( BUFFER_REF, 
                LAST_POSITION_REF, 
		START_MATCH_POSITION,
                END_MATCH_POSITION, 
		REPLACER )

The B<replace> method is used by the B<s> method, and usually should
not be used directly. However, it might be that the advanced programmer
will want to have special manipulation that is done better using the
B<replace>. It also gives us a way to by-pass my failure to implement the
'e' and double 'e' switches in the B<s> method.  

The B<replace> builds a buffer every time it is called. This buffer is
the manipulated cleaned text till the place of the last match and
replace. It does not work directly on the CLEANED_TEXT data member in
order not to change the cleaned text between the matches (so to gain
in performance).

Before we call the replace, we suppose to zero the
TANSLATION_POSITION_FACTOR, so previous replaces along the text will
not affect the current replaces.

Then we should prepare an empty buffer, and a variable that will hold
the position after the last match. This variable should be zero as well.

Now we should send to the B<replace> method a reference to the
buffer, a reference to the last position variable, the positions 
of the start and end of a match in the cleaned text, and a replacer. 

The B<replace> method will place the replacer instead of the match,
and will build the buffer till the end of the replacer. It will also
set the last position variable to the correct value.

Again, example might make it a lot simpler: 

      my $name = "Rani";
      ...
      $rei->translation_position_factor(0);
      my $cleaned_text = $rei->cleaned_text();
      my $after_the_matach;
      my $buffer = "";
      my $last_position = 0;
      # for each word
      while ($cleaned_text =~ /$pattern/g) {
          my $match = $&;	    
          my $end_match_position = pos($cleaned_text) - 1;
          my $match_length = length($match);
          my $start_match_position = 
	      $end_match_position - $match_length + 1;
	  # as an example we call a function 
          my $replacer = func($name, $2, $1);
          $rei->replace(\$buffer,
			\$last_position,
			$start_match_position,
			$end_match_position,
			$replacer);
      }
      $buffer .= substr($rei->cleaned_text(), $last_position);
      $rei->cleaned_text($buffer);

This will actually do the same as calling the B<s> method like this:

      s/$pattern/&func($name,$2,$1)/ge;

Of course the B<replace> method can be more useful in other cases. For
example, if we change our regular expression in the above while block.
Or if , before the while block, we copy part of the CLEANED_TEXT to
the buffer and set the last position variable accordingly in order to
start to match from the middle of the CLEANED_TEXT. 

=item merge ( )

This method will build back our text from the manipulated CLEANED_TEXT
and the unwanted tokens. It saves the resulted text in the TEXT data
member and also returns it.

=back

=head1 ACCESS METHODS

=over 4

=item text ( TEXT ) 

Represents the text we input in order to manipulate, and the resulted
text we get after we had the manipulations and merged.

=item delimited_text ( )

Represents the "cleaned" text after we called the B<split> method,
with delimiters that represent the unwanted tokens.

=item cleaned_text ( )

Represents the "cleaned" text after we called the B<split> method and
took out the unwanted parts.

=item delimiter_pattern ( DELIMITER_PATTERN ) 

Represents the DELIMITER_PATTERN data member. See the CONSTRUCTOR for
more details.

=back

=head1 BUGS AND OTHER PROBLEMS

Who knows?!? You should tell me. Please!  

I guess there are bugs because this module is new - a baby module - that was
created in the holidays of the end of 2001. And also because the algorithm
that is implemented in it is not simple for me.

Besides, I am quite certain it does not perform as you expect. So, part
of this problem is in your expectations ;-) This module come to kill
a huge problem, that if you try to solve it other way, it will probably
perform less good (and if not - tell me how you do it!).
However, many parts in it can be for sure implemented differently to 
give better performances. Please - let me know what you think, send 
me patches or ideas.

=head1 AUTHOR

Rani Pinchuk, E<lt>rani@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Ockham Technology N.V. & Rani Pinchuk. All rights 
reserved. This package is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself. 

=head1 SEE ALSO

L<perl>, 
L<perlop>,
L<perlre>.

=cut

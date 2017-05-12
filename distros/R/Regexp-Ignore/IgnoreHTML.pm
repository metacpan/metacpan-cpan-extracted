package Regexp::IgnoreHTML;
use Regexp::Ignore;
our @ISA = ("Regexp::Ignore"); # inherit from Regexp::Ignore class

########################
# new
########################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    # by default it does not add spaces
    $self->{SPACE_AFTER_NON_TEXT_CHARACTERISTICS_HTML} = 0; 
    return $self;
} # of new

#############################################
# space_after_non_text_characteristics_html
#############################################
sub space_after_non_text_characteristics_html {
    my $self = shift;
    if (@_) { $self->{SPACE_AFTER_NON_TEXT_CHARACTERISTICS_HTML} = shift }
    return $self->{SPACE_AFTER_NON_TEXT_CHARACTERISTICS_HTML};
} # of space_after_non_text_characteristics_html

###########################################
#
#
#
########################
# get_tokens
########################
sub get_tokens {
    my $self = shift;

    my $tokens = [];
    my $flags = [];
    my $index = 0;
    # we should create tokens from the TEXT.
    my $text = $self->text();

    # the regular expression will try to match:
    #  - HTML remarks - all the remark will be matched.
    #  - HTML tags 
    my $re1 = qr/(<\!\-\-[\s\S]+?\-\->)|(<\/?[^\>]*?>)/is;
    
    my $re2;
    if ($self->space_after_non_text_characteristics_html()) {
	# if the tag that we found is one of the following, we do not 
	# put space after it: B, BASEFONT, BIG, BLINK, CITE, CODE, EM, 
	# FONT, I, KBD, PLAINTEXT, S, SMALL, STRIKE, STRONG, SUB, SUP, 
	# TT, U, VAR, A, SPAN, WBR 
	$re2 = '<\!\-\-.+?\-\->|'.
	    '\<\!\[[^\]]*?\]\>|'.
	    '<\/?\s*B(\s[^>]*?>|\s*>)|'.
	    '<\/?\s*BASEFONT(\s[^>]*?>|\s*>)|'.
	    '<\/?\s*BIG(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*BLINK(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*CITE(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*CODE(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*EM(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*FONT(\s[^>]*?>|\s*>)|'.
	    '<\/?\s*I(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*KBD(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*PLAINTEXT(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*S(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*SMALL(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*STRIKE(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*STRONG(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*SUB(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*SUP(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*TT(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*U(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*VAR(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*A(\s[^>]*?>|\s*>)|'. 
	    '<\/?\s*SPAN(\s[^>]*?>|\s*>)|'. 
 	    '<\/?\s*WBR(\s[^>]*?>|\s*>)|'.
	    '<\/?\s*[OVWXP]\:[^>]*?>';
	$re2 = qr/$re2/is;
    }
    
    while (defined($text) && $text =~ /$re1/) {
	if ($`) { # if there is a text before, take it as clean
	    $tokens->[$index] = $`;
	    $flags->[$index] = 1; # the text before the match is clean. 
	    $index++; # increment the index	    	    
	}
	$tokens->[$index] = $&;	
	$flags->[$index] = 0; # the match itself is unwanted.
	$text = $'; # update the original text to after the match.
	$index++; # increment the index again	
	# check if we should add space after the text
	if ($self->space_after_non_text_characteristics_html() &&
	    $tokens->[$index - 1] !~ /$re2/) { # this tag is not text 
	                                       # characteristic tag
	    # we add a space token after this tag
	    $tokens->[$index] = " ";
	    $flags->[$index] = 1;
	    $index++;
	}
    }

    # if we had no match, check if there is still something in the 
    # $text. this will be also a clean text.
    if (defined($text) && $text) {
	$tokens->[$index] = $text;
	$flags->[$index] = 1; 
    }
    # return the two lists
    return ($tokens, $flags);
} # of get_tokens

1; # make perl happy

__END__

=head1 NAME

Regexp::IgnoreHTML - Let us ignore the HTML tags when parsing HTML text

=head1 SYNOPSIS

  use Regexp::IgnoreHTML;

  my $rei = new Regexp::IgnoreHTML($text, 
				   "<!-- __INDEX__ -->");
  # split the wanted text from the unwanted text
  $rei->split();  

  # use substitution function
  $rei->s('(var)_(\d+)', '$2$1', 'gi');
  $rei->s('(\d+):(\d+)', '$2:$1');

  # merge back to get the resulted text
  my $changed_text = $rei->merge();

=head1 DESCRIPTION

Inherit from B<Regexp:Ignore> and implements the B<get_tokens>
method. The tokens that are returned by the B<get_tokens> are all the
HTML tags.  

Note that for some HTML code, it might be better to use different 
B<get_tokens> then this one. Suppose for example we have the following code

  <table>
    <tr>
      <td>Hi</td><td>There</td>
    </tr>
  </table>

The "cleaned" text that will be generated after using the
B<get_tokens> method that comes from this class will look like: 

   HiThere

If we try to match the work "hit" we might match by mistake the HiT of
B<HiT>here. 

One way to solve it is to place after each clean text a space. However,
this might introduce other look to your results (for example inside
E<lt>preE<gt> block.  

Other way is to try to place the space only after certain tags (so
after E<lt>tdE<gt> but not after E<lt>pre<gt>). See the access method 
B<space_after_non_text_characteristics_html> for more details about
this possibility. 

The class B<Regexp::IgnoreTextCharacteristicsHTML> provides
implementation of B<get_tokens> that mark as unwanted only HTML tags
that are text characteristics tags (like E<lt>bE<gt> that make the
text bold). After all we do not expect to have line like the following
line: 
  
   <td>H</td><td>ello</td>

In some cases, the B<Regexp::IgnoreTextCharacteristicsHTML> class
provides a good solution for parsing HTML text. 

=head1 ACCESS METHODS

=over 4

=item space_after_non_text_characteristics_html ( BOOLEAN )

If true (by default it is false), a space token will be placed after
any tag that is not text characteristics tag. To be specific, the
tags:  
E<lt>BE<gt>, E<lt>BASEFONTE<gt>, E<lt>BIGE<gt>, E<lt>BLINKE<gt>,
E<lt>CITEE<gt>, E<lt>CODEE<gt>, E<lt>EME<gt>, E<lt>FONTE<gt>,
E<lt>IE<gt>, E<lt>KBDE<gt>, E<lt>PLAINTEXTE<gt>, E<lt>SE<gt>,
E<lt>SMALLE<gt>, E<lt>STRIKEE<gt>, E<lt>STRONGE<gt>, E<lt>SUBE<gt>,
E<lt>SUPE<gt>, E<lt>TTE<gt>, E<lt>UE<gt>, E<lt>VARE<gt>, E<lt>AE<gt>,
E<lt>SPANE<gt>, and E<lt>WBRE<gt>. 

=back

=head1 AUTHOR

Rani Pinchuk, E<lt>rani@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Ockham Technology N.V. & Rani Pinchuk. All rights 
reserved. This package is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself. 

=head1 SEE ALSO

L<perl>, 
L<perlop>,
L<perlre>,
L<Regexp::Ignore>.

=cut

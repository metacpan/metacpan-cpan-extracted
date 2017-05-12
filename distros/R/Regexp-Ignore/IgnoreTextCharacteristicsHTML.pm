package Regexp::IgnoreTextCharacteristicsHTML;
use Regexp::Ignore;
our @ISA = ("Regexp::Ignore"); # inherit from Regexp::Ignore class

########################
# new
########################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->{IGNORE_HTML_REMARKS} = 1; # by default it ignores html remarks
    $self->{IGNORE_WORD_REMARKS} = 1; # by default it ignores word remarks
    # the tags to be ignored
    $self->{IGNORE_TAGS} = { B => 1,
			     BASEFONT => 1,
			     BIG => 1,
			     BLINK => 1,
			     CITE => 1,
			     CODE => 1,
			     EM => 1,
			     FONT => 1,
			     I => 1,
			     KBD => 1,
			     PLAINTEXT => 1,
			     S => 1,
			     SMALL => 1,
			     STRIKE => 1,
			     STRONG => 1,
			     SUB => 1,
			     SUP => 1,
			     TT => 1,
			     U => 1,
			     VAR => 1,
			     A => 1,
			     SPAN => 1,
			     WBR => 1 };
    $self->build_regular_expressions();
    return $self;
} # of new

############################
# build_regular_expressions
############################
sub build_regular_expressions {
    my $self = shift;

    # the regular first expression will try to match:
    #  - HTML remarks - all the remark will be matched. this will 
    #    clean out all the special tags of MSWord (that comes inside 
    #    remarks)
    #  - MSWord remarks - starting with <![ and ending with ]>
    #  - HTML tags 
    my $re1 = '(<\/?[^\>]*?>)';
    if ($self->{IGNORE_WORD_REMARKS}) {
	$re1 = '(<\!\[[^\]]*?\]>)|'.$re1;
    }
    if ($self->{IGNORE_HTML_REMARKS}) {
	$re1 = '(<\!\-\-.+?\-\->)|'.$re1;
    }
    $self->{RE1} = qr/$re1/is;

    # if the tag that we found is one of the following, it is unwanted
    # token. 
    my $re2 = "";
    if ($self->{IGNORE_HTML_REMARKS}) {
	$re2 = '(<\!\-\-.+?\-\->)|';
    }
    if ($self->{IGNORE_WORD_REMARKS}) {
	$re2 .= '(<\!\[[^\]]*?\]>)|<\/?\s*[OVWXP]\:[^>]*?>|';
    }
    foreach my $tag ($self->tags_to_ignore()) {
	$re2 .= '<\/?\s*'.$tag.'(\s[^>]*?>|\s*>)|';
    }

    chop($re2);
    $self->{RE2} = qr/$re2/is;
} # of build_regular_expressions

#####################
# do_not_ignore
#####################
sub do_not_ignore { 
    my $self = shift;
    while (@_) {
	my $tag = shift;
	if (exists($self->{IGNORE_TAGS}{uc($tag)})) {
	    $self->{IGNORE_TAGS}{uc($tag)} = 0;
	}
    }    
    $self->build_regular_expressions();
} # of do_not_ignore

#####################
# tags_to_ignore
#####################
sub tags_to_ignore {
    my $self = shift;
    my $changed = 0;
    while (@_) {
	my $tag = shift;
	$changed = 1;
	$self->{IGNORE_TAGS}{uc($tag)} = 1;
    }
    if ($changed) {
	$self->build_regular_expressions();
    }
    return unless defined (wantarray);  # void context, do nothing
    my @tags_to_ignore = ();
    foreach my $tag (keys(% { $self->{IGNORE_TAGS} })) {
	if ($self->{IGNORE_TAGS}{$tag}) {
	    push(@tags_to_ignore, $tag);
	}
    }
    return @tags_to_ignore;
} # of tags_to_ignore

######################
# ignore_html_remarks
######################
sub ignore_html_remarks {
    my $self = shift;
    if (@_) { 
	$self->{IGNORE_HTML_REMARKS} = shift;
    	$self->build_regular_expressions();
    }
    return $self->{IGNORE_HTML_REMARKS};
} # of ignore_html_remarks

######################
# ignore_word_remarks
######################
sub ignore_word_remarks {
    my $self = shift;
    if (@_) { 
	$self->{IGNORE_WORD_REMARKS} = shift;
	$self->build_regular_expressions();
    }
    return $self->{IGNORE_WORD_REMARKS};
} # of ignore_word_remarks

##########################################################################
# Our get_tokens will treat any html tag that change the style of the 
# text as unwanted. It will also treat HTML remarks as unwanted. This 
# will let us parse HTML documents that were saved by MSWord - where
# sometimes varibale_one becomes something like:
# <tag>varibale</tag><tag>_</tag><tag>one</tag>.
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

    # the regular expressions
    my $re1 = $self->{RE1};
    my $re2 = $self->{RE2};

    while (defined($text) && $text =~ /$re1/) {
	if (length($`)) { # if there is a text before, take it as clean
	    $tokens->[$index] = $`;
	    $flags->[$index] = 1; # the text before the match is clean. 
	    $index++; # increment the index
	}
	
	$tokens->[$index] = $&; # this is the match. it might be unwanted
	                        # or wanted, as you can see below.
	$text = $'; # update the original text to after the match.

	if ($tokens->[$index] =~ /$re2/) {
	    $flags->[$index] = 0; # the match itself is unwanted.
	}
	else {
	    $flags->[$index] = 1; # the match itself is ok.
	}
	$index++; # increment the index again	
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

Regexp::IgnoreTextCharacteristicsHTML - Let us ignore the HTML tags
when parsing HTML text  

=head1 SYNOPSIS

  use Regexp::IgnoreTextCharacteristicsHTML;

  my $rei = 
    new Regexp::IgnoreTextCharacteristicsHTML($text, 
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
method. The tokens that are returned by the B<get_tokens> as unwanted 
are text characteristics HTML tags. To be specific, the tags:
E<lt>BE<gt>, E<lt>BASEFONTE<gt>, E<lt>BIGE<gt>, E<lt>BLINKE<gt>,
E<lt>CITEE<gt>, E<lt>CODEE<gt>, E<lt>EME<gt>, E<lt>FONTE<gt>,
E<lt>IE<gt>, E<lt>KBDE<gt>, E<lt>PLAINTEXTE<gt>, E<lt>SE<gt>,
E<lt>SMALLE<gt>, E<lt>STRIKEE<gt>, E<lt>STRONGE<gt>, E<lt>SUBE<gt>,
E<lt>SUPE<gt>, E<lt>TTE<gt>, E<lt>UE<gt>, E<lt>VARE<gt>, E<lt>AE<gt>,
E<lt>SPANE<gt>, and E<lt>WBRE<gt>. 

It will also take as unwanted tokens any HTML remarks and any remarks
that MSWord creates when saving a document as HTML. However this
behaviour can be changed using the class members IGNORE_HTML_REMARKS
and IGNORE_WORD_REMARKS.

=head1 ACCESS METHODS

=over 4

=item ignore_html_remarks ( BOOLEAN ) 

If true (which is also the default), the B<get_tokens> method will
take the HTML remarks as unwanted tokens. So, any E<lt>!-- ... --E<gt>
will be ignored. Should be called before B<split> is called.

=item ignore_word_remarks ( BOOLEAN ) 

If true (which is also the default), the B<get_tokens> method will
take the WORD remarks as unwanted tokens. So, any E<lt>![ ... ]E<gt>
will be ignored. Should be called before B<split> is called.

=item do_not_ignore ( TAGS )

TAGS is a list of strings, each is a name of a tag. For example: 

   ("B", "FONT")

The tags that will be sent to this method, will not be ignored by the 
object.

=item tags_to_ignore ( TAGS )

TAGS is a list of strings, each is a name of a tag. See B<do_not_ignore> 
above, for example. The tags that are sent to this method will be ignored 
by the object. You can send already ignored tags, tags that were canceled 
by a call to B<do_not_ignore> or totally new tags. All of them will be 
ignored. In a list context, it will return a list of all the tags that 
will be ignored. 

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



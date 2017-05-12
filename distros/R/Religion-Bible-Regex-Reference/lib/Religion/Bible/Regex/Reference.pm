package Religion::Bible::Regex::Reference;

use strict;
use warnings;

# Input files are assumed to be in the UTF-8 strict character encoding.
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use Carp;
use Storable qw(store retrieve freeze thaw dclone);
use Data::Dumper;

use Religion::Bible::Regex::Config;
use version; our $VERSION = '0.95';

##################################################################################
# Configuration options:
# reference.full_book_name: true/false
# reference.abbreviation.map: true/false
# reference.cvs: Chapitre/Verset Separateur
##################################################################################I

# Defaults and Constants
# our %configuration_defaults = (
#     verse_list_separateur => ', ',
#     chapter_list_separateur => '; ',
#     book_list_separateur => '; ',
# );

# These constants are defined in several places and probably should be moved to a common file
# Move these to Constants.pm
use constant BOOK    => 'BOOK';
use constant CHAPTER => 'CHAPTER';
use constant VERSE   => 'VERSE'; 
use constant UNKNOWN => 'UNKNOWN';
use constant TRUE => 1;
use constant FALSE => 0;

sub new {
    my ($class, $config, $regex) = @_;
    my ($self) = {};
    bless $self, $class;
    $self->{'regex'} = $regex;
    $self->{'config'} = $config;
    return $self;
}

# sub _initialize_default_configuration {
#     my $self = shift; 
#     my $defaults = shift; 

#     while ( my ($key, $value) = each(%{$defaults}) ) {    
#        $self->set($key, $value) unless defined($self->{mainconfig}{$key});  
#     }
# }

# Subroutines related to getting information
# Returns a reference to a Religion::Bible::Regex::Builder object.
sub get_regexes {
    my $self = shift;
    confess "regex is not defined\n" unless defined($self->{regex});
    return $self->{regex};
}

# Returns a reference to a Religion::Bible::Regex::Config object.
sub get_configuration {
    my $self = shift;
    confess "config is not defined\n" unless defined($self->{config});
    return $self->{config};
}

# Returns the private hash that contains the Bible Reference
sub get_reference_hash { return shift->{'reference'}; }
sub reference { get_reference_hash(@_); }

# Getters 
sub key  { shift->{'reference'}{'data'}{'key'}; }
sub c    { shift->{'reference'}{'data'}{'c'};   }
sub v    { shift->{'reference'}{'data'}{'v'};   }

sub key2 { shift->{'reference'}{'data'}{'key2'}; }
sub c2   { shift->{'reference'}{'data'}{'c2'};   }
sub v2   { shift->{'reference'}{'data'}{'v2'};   }

sub ob   { shift->{'reference'}{'original'}{'b'};  }
sub ob2  { shift->{'reference'}{'original'}{'b2'}; }
sub oc   { shift->{'reference'}{'original'}{'c'};  }
sub oc2  { shift->{'reference'}{'original'}{'c2'}; }
sub ov   { shift->{'reference'}{'original'}{'v'};  }
sub ov2  { shift->{'reference'}{'original'}{'v2'}; }

# We could simply write these functions as 
# sub s2   { shift->{'reference'}{'spaces'}{'s2'}; }
# However, if there are no spaces defined this code will defined an empty hash, shift->{'reference'}{'spaces'}.
# I want these functions to have absolutely no side-effects, so therefore I'm going to write them in a bit longer style
sub s2   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s2'}; }
sub s3   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s3'}; }
sub s4   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s4'}; }
sub s5   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s5'}; }
sub s6   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s6'}; }
sub s7   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s7'}; }
sub s8   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s8'}; }
sub s9   { my $s = shift; return unless defined($s->{'reference'}{'spaces'}); return $s->{'reference'}{'spaces'}{'s9'}; }

sub book { 
    my $self = shift;
    return $self->get_regexes->book($self->key);
}
sub book2 { 
    my $self = shift;
    return $self->get_regexes->book($self->key2);
}
sub abbreviation  {
    my $self = shift;
    return $self->get_regexes->abbreviation($self->key);
}
sub abbreviation2  {
    my $self = shift;
    return $self->get_regexes->abbreviation($self->key2);
}
sub context_words  { shift->{'reference'}{'data'}{'context_words'}; }
sub cvs            { shift->{'reference'}{'info'}{'cvs'}; }
sub dash           { shift->{'reference'}{'info'}{'dash'}; }

# Subroutines for book, abbreviation and key conversions
sub abbreviation2book {}
sub book2abbreviation {}
sub key2book {}
sub key2abbreviation {}
sub book2key {}
sub abbreviation2key {}

# Subroutines for setting
sub set_key   {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'key'} = $e; 
}
sub set_c     {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'c'}   = $e; 
    $self->{'reference'}{'original'}{'c'}   = $e; 
}
sub set_v     {
    my $self = shift;
    my $e = shift;

    my $r = $self->get_regexes;
    return unless (_non_empty($e));
    if ($e =~ m/($r->{'verse_number'})($r->{'verse_letter'})/) {
	$self->{'reference'}{'data'}{'v'}   = $1 if defined($1);
	$self->{'reference'}{'data'}{'vletter'} = $2 if defined($2);
    } else {
	$self->{'reference'}{'data'}{'v'}   = $e;
    }
    $self->{'reference'}{'original'}{'v'}   = $e; 
}

 sub set_key2  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'key2'} = $e; 
}

 sub set_ob  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'original'}{'b'} = $e; 
}

 sub set_ob2  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'original'}{'b2'} = $e; 
}

sub set_b     {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'original'}{'b'}  = $e; 

    # If there is a key then create the book2key and abbreviation2key associations
    my $key = $self->get_regexes->key($e);
    unless (defined($key)) {
      print Dumper $self->{'regex'}{'book2key'};
  	  print Dumper $self->{'regex'}{'abbreviation2key'};
	    croak "Book or Abbreviation must be defined in the configuration file: $e\n";
    }
    $self->{'reference'}{'data'}{'key'} = $self->get_regexes->key($e);
}
sub set_b2    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));

    $self->{'reference'}{'original'}{'b2'}  = $e; 
    $self->{'reference'}{'data'}{'key2'} = $self->get_regexes->key($e);
}
sub set_c2    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'c2'}   = $e; 
    $self->{'reference'}{'original'}{'c2'}   = $e; 
}
sub set_v2    {
    my $self = shift;
    my $e = shift;

    my $r = $self->get_regexes;
    return unless (_non_empty($e));
    if ($e =~ m/($r->{'verse_number'})($r->{'verse_letter'})/) {
	$self->{'reference'}{'data'}{'v2'} = $1 if (defined($1));
	$self->{'reference'}{'data'}{'v2letter'} = $2 if (defined($1));
    } else {
	$self->{'reference'}{'data'}{'v2'}   = $e;
    }
    $self->{'reference'}{'original'}{'v2'}   = $e;  
}
sub set_context_words  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'context_words'} = $e; 
}

# Setors for spaces
# Ge 1:1-Ap 21:22
# This shows how each of the areas that have the potential
# for a space are defined.
# Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
sub set_s2    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s2'} = $e; 
}
sub set_s3    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s3'} = $e; 
}
sub set_s4    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s4'} = $e; 
}
sub set_s5    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s5'} = $e; 
}
sub set_s6    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s6'} = $e; 
}
sub set_s7    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s7'} = $e; 
}
sub set_s8    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s8'} = $e; 
}
sub set_s9    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s9'} = $e; 
}


sub set_cvs   {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'info'}{'cvs'} = $e; 
}
sub set_dash  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'info'}{'dash'} = $e; 
}

sub book_type {
    my $self = shift;
    return 'NONE' unless (_non_empty($self->ob));
    return 'CANONICAL_NAME' if ($self->ob =~ m/@{[$self->get_regexes->{'livres'}]}/);
    return 'ABBREVIATION' if ($self->ob =~ m/@{[$self->get_regexes->{'abbreviations'}]}/);
    return 'UNKNOWN';
}

sub formatted_book {
    my $self = shift;
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';

    # Check to be sure that book_format has a proper value, if it doesn't then warn and set it
    if (!($book_format eq 'ORIGINAL' || $book_format eq 'CANONICAL_NAME' || $book_format eq 'ABBREVIATION')) {
        confess "book_format should be either 'ORIGINAL', 'CANONICAL_NAME', 'ABBREVIATION'";
        $book_format = 'ORIGINAL';
    }

    if ($book_format eq 'ABBREVIATION' || ($book_format eq 'ORIGINAL' && $self->book_type eq 'ABBREVIATION')) {
    	$ret .= $self->abbreviation || '';
    } else {
    	$ret .= $self->book || '';
    }

    return $ret;
} 

sub formatted_book2 {
    my $self = shift;
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';

    # Check to be sure that book_format has a proper value, if it doesn't then warn and set it
    if (!($book_format eq 'ORIGINAL' || $book_format eq 'CANONICAL_NAME' || $book_format eq 'ABBREVIATION')) {
	confess "book_format should be either 'ORIGINAL', 'CANONICAL_NAME', 'ABBREVIATION'";
	$book_format = 'ORIGINAL';
    }

    if ($book_format eq 'ABBREVIATION' || ($book_format eq 'ORIGINAL' && $self->book_type eq 'ABBREVIATION')) {
    	$ret .= $self->abbreviation2 || '';
    } else {
    	$ret .= $self->book2 || '';
    }

    return $ret;
} 

sub set {
    my $self = shift;
    my $r = shift;
    my $context = shift;

    $self->{reference} = {};
    $self->{reference} = dclone($context->{reference}) if defined($context->{reference});

    # $r must be a defined hash
    return unless(defined($r) && ref($r) eq 'HASH');

    # Save the words that provide context
    $self->set_context_words($r->{context_words});

    # Set the main part of the reference
    if (defined($r->{key})) {
      $self->set_key($r->{key});   # Key 
    } else {
      $self->set_b($r->{b});   # Match Book
    }

    $self->set_ob($r->{ob});   # Original book or abbreviation 
    $self->set_c($r->{c});   # Chapter
    $self->set_v($r->{v});   # Verse

    # Set the range part of the reference    
    if (defined($r->{key2})) {
      $self->set_key2($r->{key2});   # Key 
    } else {
      $self->set_b2($r->{b2});   # Match Book
    }

    $self->set_ob2($r->{ob2});   # Chapter
    $self->set_c2($r->{c2});  # Chapter
    $self->set_v2($r->{v2});  # Verse

    # Set the formatting and informational parts
    $self->set_cvs($r->{cvs}) if ((defined($r->{c}) && defined($r->{v})) || (defined($r->{c2}) && defined($r->{v2})));   # The Chapter Verse Separtor
    $self->set_dash($r->{dash}); # The reference range operator

    # If this is a book with only one chapter then be sure that chapter is set to '1'
    if(((defined($self->book) && $self->book =~ m/@{[$self->get_regexes->{'livres_avec_un_chapitre'}]}/) ||
	(defined($self->abbreviation) && $self->abbreviation =~ m/@{[$self->get_regexes->{'livres_avec_un_chapitre'}]}/)) &&
       !(defined($self->c) && defined($self->c) && $self->c eq '1')) {
	$self->set_v($self->c);
	$self->set_c('1');
	$self->set_cvs(':');
    }

    # Set the spaces
    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22

    $self->set_s2($r->{s2});
    $self->set_s3($r->{s3});
    $self->set_s4($r->{s4});
    $self->set_s5($r->{s5});
    $self->set_s6($r->{s6});
    $self->set_s7($r->{s7});
    $self->set_s8($r->{s8});
    $self->set_s9($r->{s9});

}

##################################################################################
# Reference Parsing
##################################################################################
sub parse {
    my $self = shift; 
    my $token = shift;
    my $state = shift;
    my $context_words = '';
    ($context_words, $state) = $self->parse_context_words($token, $state);

    my $r = $self->get_regexes;
    my $spaces = '[\s ]*';
    
    # type: LCVLCV
    if ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {

        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, b2=>$12, s7=>$13, c2=>$14, s8=>$15, s9=>$17, v2=>$18,  context_words=>$context_words});
    }   
    
    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: LCVLC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)/x) {
	
	$self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, b2=>$12, s7=>$13, c2=>$14, s8=>$15, context_words=>$context_words });
    }

    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: LCLCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
	
        $self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, b2=>$8, s7=>$9, c2=>$10, s8=>$11, cvs=>$12, s9=>$13, v2=>$14, context_words=>$context_words });
    }

    # type: LCVCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
	
        $self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, c2=>$12, s8=>$13, s9=>$15, v2=>$16, context_words=>$context_words});
    }

    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: LCLC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)/x) {
	
	$self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, b2=>$8, s7=>$9, c2=>$10, s8=>$11, context_words=>$context_words });
    }

    # type: LCCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, c2=>$8, s8=>$9, cvs=>$10, s9=>$11, v2=>$12, context_words=>$context_words});
    }  

    # type: LCVV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'verset'})($spaces)/x) {
        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, v2=>$12, s7=>$13, context_words=>$context_words});
    }

    # type: LCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, context_words=>$context_words});
    } 

    # type: LCC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)/x) {
	
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, c2=>$8, s7=>$9, context_words=>$context_words});
    }

    # type: LC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)/x) {        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, context_words=>$context_words});
    } else {
	$self->parse_chapitre($token, $state, $context_words);
    } 
    return $self;
}

sub parse_chapitre {
    my $self = shift; 
    my $token = shift;
    my $state = shift;
    my $context_words = shift;
    my $r = $self->get_regexes;
    my $spaces = '[\s ]*';

    # We are here!

    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: CVCV
    if ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, cvs=>$4, s4=>$5, v=>$6, s5=>$7, dash=>$8, s6=>$9, c2=>$10, s8=>$11, s9=>$13, v2=>$14, context_words=>$context_words });
    } 

    # type: CCV
    elsif ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, dash=>$4, s6=>$5, c2=>$6, s8=>$7, cvs=>$8, s9=>$9, v2=>$10, context_words=>$context_words });
    } 

    # type: CVV
    elsif ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'verset'})($spaces)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, cvs=>$4, s4=>$5, v=>$6, s5=>$7, dash=>$8, s6=>$9, v2=>$10, s7=>$11, context_words=>$context_words });
    } 

    # type: CV
    elsif ($token =~ m/([\s ]*)($r->{'chapitre'})([\s ]*)($r->{'cv_separateur'})([\s ]*)($r->{'verset'})([\s ]*)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, cvs=>$4, s4=>$5, v=>$6, s5=>$7, context_words=>$context_words });
    }

    # type: CC
    elsif ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)/ && $state eq CHAPTER) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, dash=>$4, s4=>$5, c2=>$6, s7=>$7, context_words=>$context_words });
    } 

    # type: C
    elsif ($token =~ m/([\s ]*)($r->{'chapitre'})([\s ]*)/ && $state eq CHAPTER) {
	# elsif ($token =~ m/([\s ]*)($r->{'chapitre'})([\s ]*)/) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, context_words=>$context_words });
    } 

    # Cet un Verset
    else {
        $self->parse_verset($token, $state, $context_words);
    }
}

sub parse_verset {
    my $self = shift; 
    my $token = shift;
    my $state = shift; 
    my $context_words = shift;
    my $r = $self->get_regexes;

    my $spaces = '[\s ]*';

    unless (defined($state)) {
        carp "\n\n$token: " .__LINE__ ."\n\n";
    }
    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: VV
    if ($token =~ m/($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'verset'})($spaces)/ && $state eq VERSE) {
        $state = 'match';
        $self->set({s2=>$1, v=>$2, s5=>$3, dash=>$4, s6=>$5, v2=>$6, context_words=>$context_words});
    }
    
    # type: V
    elsif ($token =~ m/([\s ]*)($r->{'verset'})([\s ]*)/ && $state eq VERSE) {
        $state = 'match';
        $self->set({s2=>$1, v=>$2, s5=>$3, context_words=>$context_words});
    } 

    # Error
    else {
        $self->set({type => 'Error'});
    }
}

################################################################################
# Format Section
# This section provides a default normalize form that is useful for various
# operations with references
################################################################################
sub parse_context_words {
    my $self = shift;
    my $refstr = shift;
    my $r = $self->get_regexes;
    my $spaces = '[\s ]*';
    my $state = shift;
    my $header = '';

    if ($refstr =~ m/^($r->{'livres_et_abbreviations'})(?:$spaces)(?:$r->{'cv_list'})/) {
#	$header = $1; $state = BOOK;
	$state = BOOK;
    } elsif ($refstr =~ m/^($r->{'chapitre_mots'})(?:$spaces)(?:$r->{'cv_list'})/) {
	$header = $1; $state = CHAPTER;
    } elsif ($refstr =~ m/($r->{'verset_mots'})(?:$spaces)(?:$r->{'cv_list'})/) {
	$header = $1; $state = VERSE;
    }
    return ($header, $state);
}

sub formatted_context_words {
    my $self = shift;
    my $ret = '';
    
    # Only print the context words if state is chapter or verse
    #if ($self->state_is_chapitre || $self->state_is_verset) {
	$ret .= $self->context_words || '';
    #}

    return $ret;
}

sub formatted_c  { shift->c || ''; }
sub formatted_v  { shift->v || ''; }
sub formatted_c2 { shift->c2 || ''; }
sub formatted_v2 { shift->v2 || ''; }

sub formatted_cvs {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    
    # if C and V exist then return ...
    # 1. The value given in the configuation file or ...
    # 2. The value parsed from the original reference
    # 3. ':'
    # if C and V do not exist then return ''
    return (
	(_non_empty($self->c) && _non_empty($self->v)) 
	? 
	(defined($self->get_configuration->get('reference','cvs')) 
	 ? 
	 $self->get_configuration->get('reference','cvs')
	 :
	 (defined( $self->cvs ) ? $self->cvs : ':')) 
	:
	'');
}

sub formatted_cvs2 {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    
    # if C and V exist then return ...
    # 1. The value given in the configuation file or ...
    # 2. The value parsed from the original reference
    # 3. ':'
    # if C and V do not exist then return ''
    return (
	(_non_empty($self->c2) && _non_empty($self->v2)) 
	? 
	(defined($self->get_configuration->get('reference','cvs')) 
	 ? 
	 $self->get_configuration->get('reference','cvs') 
	 :
	 (defined( $self->cvs ) ? $self->cvs : ':')) 
	:
	'');
}

sub formatted_interval {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    
    # if C and V exist then return ...
    # 1. The value given in the configuation file or ...
    # 2. The value parsed from the original reference
    # 3. '-'
    # if C and V do not exist then return ''
    return ((_non_empty($self->formatted_book2) || _non_empty($self->c2) || _non_empty($self->v2) ) 
	    ? 
	    (defined($self->get_configuration->get('reference','intervale'))
	     ? 
	     $self->get_configuration->get('reference','intervale') 
	     :
	     (defined( $self->dash ) ? $self->dash : ':')) 
	    :
	    '');
}

sub formatted_normalize {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';
    
    # These variables are used as caches in this function so we don't need to find there values multiple times
    my ($book, $book2, $c, $c2) = ('','','','');

    if (defined($self->book) && defined($self->book2) || (!(defined($self->v) || defined($self->v2)) && $state eq 'VERSE') ) {
	$state = 'BOOK';
    } elsif (defined($self->c) && defined($self->c2) && $state eq 'VERSE') {
	$state = 'CHAPTER';
    }

    if (_non_empty($self->formatted_context_words)) {
	$ret .= $self->formatted_context_words;
	$ret .= ' ' if defined($self->s2);
    }

    # Write out the context words and the book or abbreviation
    if ($state eq 'BOOK') {	
	$ret .= $book = $self->formatted_book($book_format);
	$ret .= ' ' if defined($self->s2) && _non_empty($self->formatted_book($book_format));
    }

    # Write out the chapter and the chapter/verse separator
    if ($state eq 'BOOK' || $state eq 'CHAPTER') {
	$ret .= $c = $self->formatted_c;
	$ret .= $self->formatted_cvs;
    }

    # Write out the verse
    $ret .= $self->formatted_v;

    # Write out the interval character to connect two references as a range of verses
    if ($self->has_interval) {
	$ret .= '-';	

	# Write out the second book or abbreviation
	$book2 = $self->formatted_book2($book_format);
	$ret .= $book2 if ($book ne $book2);

	# If there is a space defined after book2 and we are not printing the same book twice then ' '
	$ret .= ' ' if (defined($self->s7) && $book ne $book2);

	# Write out the chapter
	$c2 = $self->formatted_c2;
	$ret .= $c2 if ($c ne $c2);

	# Write out the second chapter/verse separator
	$ret .= $self->formatted_cvs2 if defined($self->c2) && defined($self->v2) && ($c ne $c2);

	# Write out the second verse
	$ret .= $self->formatted_v2;
    }
    return $ret;
}

# When debugging I don't want to type normalize over and over again
sub n { return shift->normalize; }

sub bol {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';
    
    # These variables are used as caches in this function so we don't need to find there values multiple times
    my ($book, $book2, $c, $c2) = ('','','','');

    if ((!(defined($self->v) || defined($self->v2)) && $state eq 'VERSE')) {
    	$state = 'BOOK';
    } elsif (defined($self->c) && defined($self->c2) && $state eq 'VERSE') {
    	$state = 'CHAPTER';
    }

    # Write out the context words and the book or abbreviation
    if ($state eq 'BOOK') {	
      #	$ret .= $self->formatted_context_words($state, $book_format);
    	$ret .= $book = $self->formatted_book($book_format);
    	$ret .= ' ' if defined($self->s2);
    }

    # Write out the chapter and the chapter/verse separator
    if ($state eq 'BOOK' || $state eq 'CHAPTER') {
    	$ret .= $c = $self->formatted_c;
    	$ret .= (_non_empty($self->c) && ! _non_empty($self->v)) ? '$' : '';
    	$ret .= $self->formatted_cvs;
    }

    # Write out the verse
    $ret .= $self->formatted_v;

    # Write out the interval character to connect two references as a range of verses
    $ret .= $self->formatted_interval;

    # Get book2 formatted
    $book2 = $self->formatted_book2($book_format);

    # Write out the second book or abbreviation
    if ($state eq 'BOOK' && _non_empty($book2) && $book ne $book2) {
    	$ret .= $book2;

    	# If there is a space defined after book2 and we are not printing the same book twice then ' '
    	$ret .= ' ' if (defined($self->s7));
    }

    # Write out the chapter
    $c2 = $self->formatted_c2;
    if (_non_empty($c) && $c ne $c2 && ($state eq 'BOOK' || $state eq 'CHAPTER')) {
     	$ret .= $c2;
    	$ret .= (_non_empty($self->c2) && ! _non_empty($self->v2)) ? '$' : '';
    	# Write out the second chapter/verse separator
    	$ret .= $self->formatted_cvs2;
    }

    # Write out the second verse
    $ret .= $self->formatted_v2;

    return $ret;
}

sub normalize {
    my $self = shift;
    my $ret = '';
    
    # These variables are used as caches in this function so we don't need to find there values multiple times
    my ($book, $book2, $c, $c2) = ('','','','');

    # Write out the context words and the book or abbreviation
    $ret .= $self->formatted_context_words;
    $ret .= $book = $self->formatted_book('CANONICAL_NAME');
    $ret .= ' ' if defined($self->s2);

    # Write out the chapter and the chapter/verse separator
    $ret .= $c = $self->formatted_c;
    $ret .= ':' if defined($self->c) && defined($self->v);

    # Write out the verse
    $ret .= $self->formatted_v;

    # Write out the interval character to connect two references as a range of verses
    if ($self->has_interval) {
    	$ret .= '-';	

    	# Write out the second book or abbreviation
    	$book2 = $self->formatted_book2('CANONICAL_NAME');
    	$ret .= $book2 if ($book ne $book2);

    	# If there is a space defined after book2 and we are not printing the same book twice then ' '
    	$ret .= ' ' if (defined($self->s7) && $book ne $book2);

    	# Write out the chapter
    	$c2 = $self->formatted_c2;
    	$ret .= $c2 if ($c ne $c2);

    	# Write out the second chapter/verse separator
    	$ret .= ':' if defined($self->c2) && defined($self->v2) && ($c ne $c2);
  
    	# Write out the second verse
    	$ret .= $self->formatted_v2;
    }
    return $ret;
}


##################################################################################
# State Helpers 
#
# The context of a reference refers to the first part of it defined...
# For example: 'Ge 1:1' has its book, chapter and verse parts defined. So its 
#              state is 'explicit'  This means it is a full resolvable reference 
#              '10:1' has its chapter and verse parts defined. So its 
#               context is 'chapitre' 
#              'v. 1' has its verse part defined. So its context is 'verset' 
# 
##################################################################################
sub state_is_chapitre {
    my $self = shift;
    return _non_empty($self->c) && !$self->is_explicit;
}

sub state_is_verset {
    my $self = shift;
    return _non_empty($self->v) && !_non_empty($self->c) && !$self->is_explicit;
}

# The state of a reference can have three values BOOK, CHAPTER or VERSE.
# To find the state of a reference choose the leftmost value that exists in 
# that reference
#
# Examples:
#  'Ge 1:2' has a state of 'BOOK'
#  '1:2' has a state of 'CHAPTER'
#  '2' has a state of 'VERSE'
sub state_is_book {
    my $self = shift;
    return $self->is_explicit;
}

sub state {
    my $self = shift;
    return 'BOOK'    if $self->state_is_book;
    return 'CHAPTER' if $self->state_is_chapitre;
    return 'VERSE'   if $self->state_is_verset;
    return 'UNKNOWN';
}

# The context of a reference can have three values BOOK, CHAPTER or VERSE.
# To find the state of a reference choose the rightmost value that exists in 
# that reference
#
# Examples:
#  'Ge 1:1' has a state of 'VERSE'
#  'Ge 1' has a state of 'CHAPTER'
#  'Ge' has a state of 'BOOK' note: a valid reference must be either CHAPTER or VERSE and not simply BOOK
#  TODO: write tests
sub context_is_verset {
    my $self = shift;
    return _non_empty($self->v) || _non_empty($self->v2);
}

sub context_is_chapitre {
    my $self = shift;
    return (_non_empty($self->c) || _non_empty($self->c2)) && !$self->context_is_verset;
}

sub context_is_book {
    my $self = shift;
    return (_non_empty($self->formatted_book) || _non_empty($self->formatted_book2)) && !$self->context_is_chapitre;
}

sub context {
    my $self = shift;
    return 'BOOK'    if $self->context_is_book;
    return 'CHAPTER' if $self->context_is_chapitre;
    return 'VERSE'   if $self->context_is_verset;
    return 'UNKNOWN';
}

sub is_explicit {
    my $self = shift;
    # Explicit reference must have a book and a chapter
    return (_non_empty($self->key));
}

sub shared_state {
    my $r1 = shift;
    my $r2 = shift;

    # If this reference has an interval ... don't handle it result may be technically 
    # correct but on a practical note ... they are to difficult to read
    # return if $r1->has_interval || $r2->has_interval;

    # Two references can not have shared context if they do not have the same state
    return unless ($r1->state eq $r2->state);

    return VERSE   if ( ((defined($r1->v) && defined($r2->v)) && ($r1->v ne $r2->v))
			&& 
			((defined($r1->c) && defined($r2->c) && ($r1->c eq $r2->c)) || (!(defined($r1->c) && defined($r2->c))))
			&& 
			((defined($r1->key) && defined($r2->key) && ($r1->key eq $r2->key)) || (!(defined($r1->key) && defined($r2->key))))
	);

    return CHAPTER if ((defined($r1->c) && defined($r2->c))     && (($r1->c ne $r2->c) && (!(defined($r1->key) && defined($r2->key)) || (defined($r1->c) && defined($r2->c) && $r1->key eq $r2->key))) );
    return BOOK    if ((defined($r1->key) && defined($r2->key)) && (($r1->key ne $r2->key)));
    return;
}

########################################################################
# Helper Functions
#

sub has_interval {
    my $self = shift;
    return ((defined($self->key) && defined($self->key2) && $self->key ne $self->key2) 
	    || 
	    (defined($self->c) && defined($self->c2) && $self->c ne $self->c2)
	    || 
	    (defined($self->v) && defined($self->v2) && $self->v ne $self->v2)
	);
}

sub begin_interval_reference {
    my $self = shift;
    my $ret = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes); 

    $ret->set({ key => $self->key, 
                ob => $self->ob, 
            		c => $self->oc, 
                v => $self->ov, 
                s2 => $self->s2, 
                s3 => $self->s3, s4 => $self->s4, 
                s5 => $self->s5, cvs => $self->cvs, 
      	        context_words => $self->context_words});

    return $ret;
}
sub end_interval_reference {
    my $self = shift;
    my $ret = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes); 

    my ($b, $c, $s7, $key);

    if (!defined($self->key2) && (defined($self->oc2) || defined($self->ov2) )) {
    	$b = $self->ob;
      $key = $self->key;
    	$s7 = $self->s2;
    } else {
    	$b = $self->ob2;
      $key = $self->key2;
    	$s7 = $self->s7;
    }

    if (!defined($self->oc2) && ( defined($self->ov2) )) {
    	$c = $self->oc;
    } else {
    	$c = $self->oc2;
    }
    
    return unless (_non_empty($b) || _non_empty($c) || _non_empty($self->ov2));

    $ret->set({ key => $key, 
                ob => $b,
                c => $c, 
                v => $self->ov2, 
                s2 => $s7,
                s3 => $self->s8, 
                s4 => $self->s9, 
                cvs => $self->cvs,
                context_words => $self->context_words});

    return $ret;
}

sub interval {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    return $r1 if ($r1->compare($r2) == 0);

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }
    
    my $min = $r1->begin_interval_reference->min($r1->end_interval_reference, $r2->begin_interval_reference, $r2->end_interval_reference);
    my $max = $r1->begin_interval_reference->max($r1->end_interval_reference, $r2->begin_interval_reference, $r2->end_interval_reference);

    my $ret = new Religion::Bible::Regex::Reference($r1->get_configuration, $r1->get_regexes);

    $ret->set({ key => $min->key, 
                ob => $min->ob, 
                c => $min->c, 
                v => $min->v, 
                key2 => $max->key, 
                ob2 => $max->ob,
                c2 => $max->c, 
                v2 => $max->v2 || $max->v,
                cvs => $min->cvs || $max->cvs, 
                dash => '-',
                s2 => $min->s2, 
                s3 => $min->s3, 
                s4 => $min->s4, 
                s5 => $min->s5,  
                s7 => $max->s2, 
                s8 => $max->s3,
                s9 => $max->s4, 
                context_words => $min->context_words
	      });

    return $ret;
}
sub min {
    my $self = shift;
    my @refs = @_; 
    my $ret = $self;

    foreach my $r (@refs) {
#	next unless (defined(ref $r));
        if ($ret->gt($r)) {
            $ret = $r;
        }
    }
    return $ret;
} 

sub max {
    my $self = shift;
    my @refs = @_; 
    my $ret = $self;

    foreach my $r (@refs) {
        if ($ret->lt($r)) {
            $ret = $r;
        }
    }
    return $ret;
} 

# References must be of the forms LCV, CV or V
sub compare {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }

    # Messy logic that compares two references with a context of 'BOOK' 
    # ex. 
    # ('Ge 1:1' and 'Ge 2:1'), ('Ge 1:1' and 'Ge 2'), ('Ge 1' and 'Ge 2:1'), ('Ge 1' and 'Ge 2')   
    # ('Ge 1:1' and 'Ex 2:1'), ('Ge 1:1' and 'Ex 2'), ('Ge 1' and 'Ex 2:1'), ('Ge 1' and 'Ex 2')   
    # ('Ex 1:1' and 'Ge 2:1'), ('Ex 1:1' and 'Ge 2'), ('Ex 1' and 'Ge 2:1'), ('Ex 1' and 'Ge 2')   
    if (defined($r1->key) && defined($r2->key)) {
	if (($r1->key + 0 <=> $r2->key + 0) == 0) {
	    if (defined($r1->c) && defined($r2->c)) {
		if (($r1->c + 0 <=> $r2->c + 0) == 0) {
		    if (defined($r1->v) && defined($r2->v)) {
			return ($r1->v + 0 <=> $r2->v + 0);
		    } else {
			return ($r1->c + 0 <=> $r2->c + 0);
		    }
		} else {
		    return ($r1->c + 0 <=> $r2->c + 0);
		}
	    } else {
		return ($r1->key + 0 <=> $r2->key + 0);
	    }
	} else {
	    return ($r1->key + 0 <=> $r2->key + 0);
	}	
    } 
    # Messy logic that compares two references with a context of 'CHAPTER' 
    # ex.  ('1:1' and '2:1'), ('1:1' and '2'), ('1' and '2:1'), ('1' and '2')
    else {
	if (defined($r1->c) && defined($r2->c)) {
	    if (($r1->c + 0 <=> $r2->c + 0) == 0) {
		if (defined($r1->v) && defined($r2->v)) {
		    return ($r1->v + 0 <=> $r2->v + 0);
		} else {
		    return ($r1->c + 0 <=> $r2->c + 0);
		}
	    } else {
		return ($r1->c + 0 <=> $r2->c + 0);
	    }
	} else {
	    if (defined($r1->v) && defined($r2->v)) {
		return ($r1->v + 0 <=> $r2->v + 0);
	    } else {
		return ($r1->c + 0 <=> $r2->c + 0);
	    }
	}
    }

#    return 1 if ((defined($r1->key) && defined($r2->key)) && ($r1->key + 0 > $r2->key + 0));
#    return 1 if ((defined($r1->c) && defined($r2->c)) && ($r1->c + 0 > $r2->c + 0));
#    return 1 if ((defined($r1->v) && defined($r2->v)) && ($r1->v + 0 > $r2->v + 0));
    return;
}
sub gt {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }

    ($r1->compare($r2) == -1) ? return : return 1;

}
sub lt {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }

    my $ret = $r1->compare($r2);
    ($ret == 1) ? return : return 1;

}


sub combine {
    my $r1 = shift;
    my $r2 = shift;
    my %p; 

    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));
    
    my $ret = new Religion::Bible::Regex::Reference($r1->get_configuration, $r1->get_regexes);

    if ($r2->state eq 'BOOK') {
      $p{'context_words'} = ($r2->context_words) if (defined($r2->context_words));
	    $ret->set( \%p, $r2 );
    } elsif ($r2->state eq 'CHAPTER') {    
      $p{'key'} = ($r1->key2 || $r1->key) if (defined($r1->key2 || $r1->key));
      $p{'ob'} = ($r1->ob2 || $r1->ob) if (defined($r1->ob2 || $r1->ob));
      $p{'c'} = ($r2->c) if (defined($r2->c));
      $p{'v'} = ($r2->v) if (defined($r2->v));
      $p{'c2'} = ($r2->c2) if (defined($r2->c2));
      $p{'v2'} = ($r2->v2) if (defined($r2->v2));
      $p{'cvs'} = ($r2->cvs ||  $r1->cvs) if (defined($r2->cvs ||  $r1->cvs));
      $p{'dash'} = ($r2->dash || $r1->dash) if (defined($r2->dash || $r1->dash));
      $p{'context_words'} = ($r2->context_words) if (defined($r2->context_words));
      $p{'s2'} = ($r2->s2 || $r1->s2) if (defined( $r2->s2 || $r1->s2 ));
      $p{'s3'} = ($r2->s3 || $r1->s3) if (defined( $r2->s3 || $r1->s3 ));
      $p{'s4'} = ($r2->s4 || $r1->s4) if (defined( $r2->s4 || $r1->s4 ));
      $p{'s5'} = ($r2->s5 || $r1->s5) if (defined( $r2->s5 || $r1->s5 ));
      $p{'s6'} = ($r2->s6 || $r1->s6) if (defined( $r2->s6 || $r1->s6 ));
      $p{'s8'} = ($r2->s8 || $r1->s8) if (defined( $r2->s8 || $r1->s8 ));
      $p{'s9'} = ($r2->s9 || $r1->s9) if (defined( $r2->s9 || $r1->s9 ));
      $ret->set( \%p, $r2);
    } else {
      $p{'key'} = ($r1->key2 || $r1->key) if (defined($r1->key2 || $r1->key));
      $p{'ob'} = ($r1->ob2 || $r1->ob) if (defined($r1->ob2 || $r1->ob));
      $p{'c'} = ($r2->c2 || $r2->c || $r1->c2 || $r1->c,) if (defined($r2->c2 || $r2->c || $r1->c2 || $r1->c,));
      $p{'v'} = ($r2->v) if (defined($r2->v));
      $p{'v2'} = ($r2->v2) if (defined($r2->v2));
      $p{'cvs'} = ($r2->cvs ||  $r1->cvs) if (defined($r2->cvs ||  $r1->cvs));
      $p{'dash'} = ($r2->dash || $r1->dash) if (defined($r2->dash || $r1->dash));
      $p{'context_words'} = ($r2->context_words) if (defined($r2->context_words));
      $p{'s2'} = ($r2->s2 || $r1->s2) if (defined( $r2->s2 || $r1->s2 ));
      $p{'s3'} = ($r2->s3 || $r1->s3) if (defined( $r2->s3 || $r1->s3 ));
      $p{'s4'} = ($r2->s4 || $r1->s4) if (defined( $r2->s4 || $r1->s4 ));
      $p{'s5'} = ($r2->s5 || $r1->s5) if (defined( $r2->s5 || $r1->s5 ));
      $p{'s6'} = ($r2->s6 || $r1->s6) if (defined( $r2->s6 || $r1->s6 ));
      $p{'s8'} = ($r2->s8 || $r1->s8) if (defined( $r2->s8 || $r1->s8 ));
      $p{'s9'} = ($r2->s9 || $r1->s9) if (defined( $r2->s9 || $r1->s9 ));
      $ret->set( \%p, $r2);
    }
    
    return $ret;

}
sub _non_empty {
    my $value = shift;
    return (defined($value) && $value ne '');
}  

# Returns the first _non_empty value or ''
sub _setor {
    foreach my $v (@_) {
        return $v if _non_empty($v);
    }
    
    # if no value is given the default should be a empty string
    return '';
}

1; # Magic true value required at end of module
__END__

    =head1 NAME

    Religion::Bible::Regex::Reference -  this Perl object represents a Biblical reference along with the functions that can be applied to it.

    =head1 VERSION

    This document describes Religion::Bible::Regex::Reference version 0.9

    =head1 SYNOPSIS

    =over 4

    use Religion::Bible::Regex::Config;
    use Religion::Bible::Regex::Builder;
    use Religion::Bible::Regex::Reference;

    # $yaml_config_file is either a YAML string or the path to a YAML file
    $yaml_config_file = 'config.yml';

    my $c = new Religion::Bible::Regex::Config($yaml_config_file);
    my $r = new Religion::Bible::Regex::Builder($c);
    my $ref = new Religion::Bible::Regex::Reference($r, $c);

    $ref->parse('Ge 1:1');

    =back

    =head1 DESCRIPTION

    This class is meant as a building block to enable people and publishing houses 
    to build tools for processing documents which contain Bible references.

    This is the main class for storing state information about a Bible reference and
    can be used to build scripts that perform a variety of useful operations.  
    For example, when preparing a Biblical commentary in electronic format a publishing 
    house can save a lot of time and manual labor by creating scripts that do 
    the following:

    =over 4

    =item * Automatically find and tag Bible references

    =item * Find invalid Bible references

    =item * Check that the abbreviations used are consistent throughout the entire book.

    =item * Create log files of biblical references that need to be reviewed by a person.

    =back

    This class is meant to be a very general-purpose so that any type of tool that needs to manipulate Bible references can use it.


    =head1 Bible Reference Types

    Bible references can be classified into a few different patterns.

    Since this code was originally written and commented in French, we've retained
the French abbreviations for these different Bible reference types. 

=over 4

    'L' stands for 'Livre'    ('Book' in English)
    'C' stands for 'Chapitre' ('Chapter' in English)
    'V' stands for 'Verset'   ('Verse' in English)

=back

Here are the different Bible reference types with an example following each one:

=over 4

    # Explicit Bible Reference Types
    LCVLCV Ge 1:1-Ex 1:1
    LCVCV  Ge 1:1-2:1
    LCCV   Ge 1-2:5
    LCVV   Ge 1:2-5
    LCV    Ge 1:1
    LCC    Ge 1-12
    LC     Ge 1        
            
    # Implicit Bible Reference Types
    CVCV   1:1-2:1
    CCV    1-2:5
    CVV    1:2-5
    CV     1:1
    CC     1-12
    C      1
    VV     1-5
    V      1

=back

=head2 Explicit and Implicit Bible Reference Types	

=head3

We say the Bible reference is explicit when it has enough information within the 
reference to identify an exact location within the Bible. 

Examples of explicit Bible references include:

Genesis 1:1
Ge 1:1
Ge 1
Genesis 1

An explicit reference must have a book and a chapter but not necessarily a verse.

=head3

We say that a Bible reference is implicit when the reference itself does not 
contain enough information to find its location in the Bible. often times within 
a commentary we will find implicit Bible references that use the context of the text
to identify the Bible reference.

Examples of implicit Bible references include:

    in Chapter 4
    in verse 17
    see 4:17
    as we see in chapter 5
    (4:7)

An implicit preference must be proceeded by some identifying phrase or character(s), 
referred to as the context word(s).  Context words allow these Bible reference objects
to identify and distinguish him between Bible references and other numbers that 
might be in the text of the commentary. 

In the examples above the context words are respectively:
    
    'in Chapter'
    'in verse'
    'see'
    'as we see in chapter'
    '('


=head2 Explaination of the Parts of a Bible Reference

When a Bible reference is parsed it is divided up into a number of different parts as follows:

First of all, a Bible reference can have an interval.  Both sides of the interval, '-' can 
have a book, chapter and verse. For example, 'Genesis 1:1 - Revelation 22:21', 'Ge 1:1-2:3', and 'Ge 1:1-5' are all verses with intervals.

=head3 Reference Parts

key: A key is a unique numeric identifier which is defined in the configuration file for a particular book of the Bible. 
For example, Genesis is often defined as '1'.  any alternative spellings and abbreviations will also map to this number. So for example, if the configuration file defines the book of Genesis with French spellings like this:
     
     books:
       1: 
         Match:
           Book: ['Genèse', 'Genese']
           Abbreviation: ['Ge']
         Normalized: 
           Book: Genèse
           Abbreviation: Ge
          
     Then 'Genèse', 'Genese', 'Ge' would all map to a key value of '1'.
          
c  : this is the chapter in the beginning part of the reference.
	For example, for 'Genesis 11', c is '11'
    		  for 'Genesis 1-11', c is '1'
     		  for 'Romans 3:23', c is '3'
     
v  : this is the verse in the beginning part of the reference.
For example, for 'John 14:6', v is '6'.
     		  for 'John 3:16', v is '16'.
     		  for 'Psalm 23:1-3', v is '1'
     
cvs : Chapter And Verse Separator 
      In most English Bibles this character is a ':'.  Often in Europe the '.' character is used as a separator.
For example, 
      
      'Ephesians 2:8', cvs is ':'
      'Actes 1.8', cvs is '.'

cvs2 : Chapter And Verse Separator for the interval part of the Bible reference
      In most English Bibles this character is a ':'.  Often in Europe the '.' character is used as a separator.
For example, 
      
      'Ephesians 2:8-3:10', cvs is ':'
      'Actes 1.8-2.1', cvs is '.'

dash : the interval operator.  In most English Bibles this character is simply a '-'.  However in many European Bibles a long dash is used if the interval separates two chapters, and a normal dash is used if the interval is between two verses.

	'Genesis 1:1 - Revelation 22:21', dash is '-'.
      		   
key2 : The same as key except used when this Bible verse has an interval. So for example, if the configuration file defines the book of Genesis with French spellings like this:
     
     books:
       1: 
         Match:
           Book: ['Genèse', 'Genese']
           Abbreviation: ['Ge']
         Normalized: 
           Book: Genèse
           Abbreviation: Ge
      
       66: 
         Match:
           Book: ['Revelation']
           Abbreviation: ['Re', 'Rev']
         Normalized: 
             Book: Revelation
            Abbreviation: Re
                  
       for example, for 'Genesis 1:1 - Revelation 22:21', key2 is '66'.
     	            
c2  : The same as c except this is the chapter when this Bible verse has an interval. 

For example,

	'Genesis 1:1 - Revelation 22:21', c2 is '22'.

v2  : The same as v except this is the verse when this Bible verse has an interval. 

For example,

	'Genesis 1:1 - Revelation 22:21', v2 is '21'.

=head3 Spaces in a Bible Reference

The various parts of the Bible verse may have spaces, (ascii 32), or non-breakable spaces, (ascii 160), between them.

Here they are defined as s2, s3, s4, s5, s6, s7, s8 and s9.  There are no spaces defined 
before or after a Bible verse, which is why s1 and s10 are no longer present.


Spaces are defined like this on a LCVLCV reference.

	L(s2)C(s3):(s4)V(s5)-(s6)L2(s7)C2(s8):(s9)V2
	s2 : between L and C
	s3 : between C and the CVS
	s4 : between CVS and V
	s5 : between V and the dash
	s6 : between the dash and L2
	s7 : between L2 and C2
	s8 : between C2 and CVS2
	s9 : between CVS2 and V2
	

=head1 INTERFACE 

=head2 new

Creates a new Religion::Bible::Regex::Reference. Requires two parameters a Religion::Bible::Regex::Config object and a Religion::Bible::Regex::Regex object

=head2 get_configuration

Returns the Religion::Bible::Regex::Config object used by this reference.

=head2 get_regexes

Returns the Religion::Bible::Regex::Builder object used by this reference.

=head2 get_reference_hash

Returns the hash that contains all of the parts of the current Bible reference.  

=head2 reference

An alias for get_reference_hash

=head2 is_explicit

Returns true if all the information is there to reference an exact verse or verses in the Bible.

=head2 set

Takes a hash and uses it to define a Bible reference.

For example, this hash defines the LCVLCV reference, Ge 1:1-Ex 2:5.
{b=>'Ge',s2=>' ',c=>'1',cvs=>':',v=>'1', dash=>'-',b2=>'Ex',s7=>' ',c2=>'2',v2=>'5'}

=head2 set_b  

    This function takes a book or an abbreviation as defined under the Match sections in the configurations file and sets the key. 
    Use this function because when you're parsing a Bible reference this function this function will be able to set the correct
book whether you pass it an abbreviation or a book name based upon the possible defined spellings of each. 

For example given the configuration:

     books:
       1: 
         Match:
           Book: ['Genèse', 'Genese']
           Abbreviation: ['Ge']
         Normalized: 
           Book: Genèse
           Abbreviation: Ge

     set_b('Ge'), set_b('Genèse') and set_b('Genese') all set the key to '1'
          
=head2 set_c   

This function sets the chapter for a Bible reference.

=head2 set_v   

This function sets the verse for a Bible reference.

=head2 set_b2 

The same as set_b except used on the interval section of a Bible reference. 
This function takes a book or an abbreviation as defined under the Match sections in the configurations file and sets the key2. 

=head2 set_c2

Sets the chapter for the interval part of the Bible reference.

=head2 set_v2

Sets the verse for the interval part of the Bible reference.

=head2 set_cvs

Sets CVS for the interval part of the Bible reference.

=head2 set_cvs2

Sets the CVS for the interval part of the Bible reference.

=head2 set_dash

Sets the DASH for the Bible reference.

=head2 set_s2 

Sets s2

=head2 set_s3 

Sets s3

=head2 set_s4 

Sets s4

=head2 set_s5 

Sets s5

=head2 set_s6 

Sets s6

=head2 set_s7 

Sets s7

=head2 set_s8 

Sets s8

=head2 set_s9

Sets s9

=head2 key 

Returns key

=head2 c

Returns c

=head2 v

Returns v

=head2 key2 

Returns key2

=head2 c2   

Returns c2

=head2 v2   

Returns v2

=head2 cvs

Returns the cvs for a reference.

=head2 dash  

Returns the dash for a reference.
    
=head2 ob

Returns the original book or abbreviation

=head2 ob2

Returns the original book or abbreviation for the intervale part of the reference

=head2 oc  

Returns the original chapter

=head2 oc2 

Returns the original chapter for the intervale part of the reference

=head2 ov  

Returns the original verse

=head2 ov2 

Returns the original verse for the intervale part of the reference

=head2 s2 

Returns s2

=head2 s3

Returns s3

=head2 s4 

Returns s4

=head2 s5 

Returns s5

=head2 s6 

Returns s6

=head2 s7 

Returns s7

=head2 s8 

Returns s8

=head2 s9 

Returns s9

=head2 book

Returns the canonical book defined by the key

=head2 book2

Returns the canonical book defined by the key for the intervale part of the reference.

=head2 abbreviation

Returns the normalize abbreviation for a reference.

=head2 abbreviation2 

Returns the normalize abbreviation for a reference  for the intervale part of the reference.

=head2 	formatted_c

Returns the chapter as a number.  Usually this is the same as the getter $self->c except when $self->c is a roman number.

=head2 	formatted_c2

Returns the chapter as a number for the intervale part of the reference.  Usually this is the same as the getter $self->c2 except when $self->c2 is a roman number.

=head2 	formatted_context_words

Returns the context words. context words or phrases that begin an implicit biblical reference.
For example, 'in the chapter', or 'see verses'.
 
=head2 	formatted_cvs

This function follows the following rules to return a chapter for separator:

If a chapter and a verse are defined and the configuration file defines a character to use for the CVS then return it. Otherwise returns the CVS character that was parsed from the original reference. otherwise return ':'

If the chapter and verse are not defined then return a null string.

=head2 	formatted_cvs2

This function follows the following rules to return a chapter for separator:

If a chapter and a verse are defined and the configuration file defines a character to use for the CVS then return it. Otherwise returns the CVS character that was parsed from the original reference. otherwise return ':'

If the chapter and verse are not defined then return a null string.

=head2 	formatted_interval

This function follows the following rules to return a chapter for separator:

If any part of the interval part of the Bible verse is defined then return the dash character defined in the configuration file. Otherwise returns the dash character that was parsed from the original reference. otherwise return '-'

If The current reference has no interval and then return a null string.

=head2 	formatted_v

Returns the verse as a number.  Usually this is the same as the getter $self->v except when $self->v is a roman number.

=head2 	formatted_v2

Returns the verse as a number for the intervale part of the reference.  Usually this is the same as the getter $self->v2 except when $self->v2 is a roman number.

=head2 abbreviation2book

Given any of the abbreviations defined under the match section of a reference in the configuration file, then returned its normalized book name.

=head2 abbreviation2key

Given any of the abbreviations defined under the match section of a reference in the configuration file, then returned its key.

=head2 book2abbreviation

Given any of the book names defined under the match section of a reference in the configuration file, then returned its normalized abbreviation.

=head2 book2key

Given any of the book names defined under the match section of a reference in the configuration file, then returned its key.

=head2 key2abbreviation

Given the key of a reference defined under the match section in the configuration file, then returned its normalize abbreviation.

=head2 key2book

Given the key of a reference defined under the match section in the configuration file, then returned its normalize book name.

=head2 book_type

If this reference is implicit then this function returns 'NONE'.  For example, the reference 'see verse 5:1' returns a book_type of 'NONE'.

If the original reference that was parsed contained an abbreviation for a book of the Bible then this returns 'ABBREVIATION'. For example, the reference 'Ro 12:16' returns a book_type of 'ABBREVIATION'.

If the original reference that was parsed contained a book name then this returns 'CANONICAL_NAME'.  For example, the reference 'Ephesians 4:32' returns a book_type of 'CANONICAL_NAME'.

=head2 formatted_book

This function checks to see if the originally parsed reference was of type 'CANONICAL_NAME' or 'ABBREVIATION' and then returns the corresponding normalized book name or abbreviation for book.

=head2 formatted_book2

This function checks to see if the originally parsed reference was of type 'CANONICAL_NAME' or 'ABBREVIATION' and then returns the corresponding normalized book name or abbreviation for book2.

=head2 compare

Given two references, this function returns -1 if the first reference is before the second reference, 0 if the references are identical, and 1 if the first reference is after the second.

For example, given this configuration file: 
	     
	     books:
	       1: 
	         Match:
	           Book: ['Genèse', 'Genese']
	           Abbreviation: ['Ge']
	         Normalized: 
	           Book: Genèse
	           Abbreviation: Ge
	      
	       66: 
	         Match:
	           Book: ['Revelation']
	           Abbreviation: ['Re', 'Rev']
	         Normalized: 
	             Book: Revelation
            Abbreviation: Re
            
and these references

	$ref1->parse('Genesis 1:1');
	$ref2->parse('Revelation 22:21');
	$ref1->compare($ref2);
	
This function first compares their keys, which are respectively '1' and '66'.  Since 1 < 66, compare returns '-1' which means the first reference is before the second reference.
            
=head2 gt

Given two references, this function returns nil if the first reference is after the second reference, and 1 if the first reference is before or identical to the second reference.

For example, given this configuration file: 
	     
	     books:
	       1: 
	         Match:
	           Book: ['Genèse', 'Genese']
	           Abbreviation: ['Ge']
	         Normalized: 
	           Book: Genèse
	           Abbreviation: Ge
	      
	       66: 
	         Match:
	           Book: ['Revelation']
	           Abbreviation: ['Re', 'Rev']
	         Normalized: 
	             Book: Revelation
            Abbreviation: Re
            
and these references

	$ref1->parse('Genesis 1:1');
	$ref2->parse('Revelation 22:21');
	$ref1->gt($ref2);
	
This function first compares their keys, which are respectively '1' and '66'.  Since 1 < 66, gt returns nil which means the first reference is not after the second reference.

=head2 lt
    
Given two references, this function returns '1' if the first reference is before the second reference, and nil if the first reference is after or identical to the second reference.

For example, given this configuration file: 
	     
	     books:
	       1: 
	         Match:
	           Book: ['Genèse', 'Genese']
	           Abbreviation: ['Ge']
	         Normalized: 
	           Book: Genèse
	           Abbreviation: Ge
	      
	       66: 
	         Match:
	           Book: ['Revelation']
	           Abbreviation: ['Re', 'Rev']
	         Normalized: 
	             Book: Revelation
            Abbreviation: Re
            
and these references

	$ref1->parse('Genesis 1:1');
	$ref2->parse('Revelation 22:21');
	$ref1->lt($ref2);
	
This function first compares their keys, which are respectively '1' and '66'.  Since 1 < 66, gt returns '1' which means the first reference is before the second reference.
    
=head2 interval

Given two references this function returns one reference which is the interval of the two.  The interval reference always sorts the two references.

	$ref1->parse('Genesis 1:1');
	$ref2->parse('Revelation 22:21');
	
	$ref3 = $ref1->interval($ref2);
	print $ref3->normalize;   # Returns 'Genesis 1:1 - Revelation 22:21'

	# If we reverse the order of the references note the output is correctly ordered with 'Genesis' before 'Revelation'	
	$ref1->parse('Revelation 22:21');
	$ref2->parse('Genesis 1:1');
	
	$ref3 = $ref1->interval($ref2);
	print $ref3->normalize;   # Returns 'Genesis 1:1 - Revelation 22:21'

=head2 min

Given an array of references, this function returns the reference that is before all others.

For example assuming the configuration file defines the book used below, 

	$ref1->parse('Galatians 5:13');
	$ref2->parse('Colossians 3:16');	
	$ref3->parse('1 Thessalonians 5:11');
	$ref4->parse('James 5:16');	
	
	# $min is set to 'Galatians 5:13'
	$min = $ref1->min($ref2, $ref3, $ref4);

=head2 max

Given an array of references, this function returns the reference that is after all others.

For example assuming the configuration file defines the book used below, 

	$ref1->parse('Galatians 5:13');
	$ref2->parse('Colossians 3:16');	
	$ref3->parse('1 Thessalonians 5:11');
	$ref4->parse('James 5:16');	
	
	# $max is set to 'James 5:16'
	$max = $ref1->max($ref2, $ref3, $ref4);

=head2 has_interval

Returns '1' if a reference has an inteval component otherwise returns nil.

	$ref1->parse('1 Peter 3:7-8')->has_interval;   	# returns '1'
	$ref2->parse('1 Peter 4:9')->has_interval;	# returns nil

=head2 begin_interval_reference

Given a reference with an interval, this function returns the beginning part of the reference.

	$ref2 = $ref1->parse('Matthew 5:3-11')->begin_interval_reference;
	print $ref2->normalize;    # Prints 'Matthew 5:3'

	$ref2 = $ref1->parse('Matthew 16-17')->begin_interval_reference;
	print $ref2->normalize;    # Prints 'Matthew 16'
	
=head2 end_interval_reference

Given a reference with an interval, this function returns the interval part of the reference.

	$ref2 = $ref1->parse('Matthew 5:3-11')->end_interval_reference;
	print $ref2->normalize;    # Prints 'Matthew 5:11'

	$ref2 = $ref1->parse('Matthew 16-17')->end_interval_reference;
	print $ref2->normalize;    # Prints 'Matthew 17'

=head2 combine

This functions combines two references using the context of the first reference to complete the 
second.  This is useful when parsing references from commentaries or text.

For example: 

If you are using the Religion::Bible::Regex::Lexer to parse a string like :

	'Luke 23:26, 28'
	
There are two references found 'Luke 23:26' and '28'.

The combine function allows the you to combine 'Luke 23:26' and '28' to produce the reference 'Luke 23:28'.

So the key and chapter of 'Luke 23:26' are transfered to 'Luke 23:28'.

In general, if the second verse is implicit this function takes enough information from the first to make it an explicit reference.

=head3 normalize

Prints the Bible reference in a standardized way.

First, the context words and book/abbreviation are printed. This is then followed by a space and then the chapter, cvs and verse.
If there is an interval part then it's printed next.

    For example:
    John 3:16
    Ge 1:1

    =head2 n
    =head2 bol

    =head2 shared_state
    =head2 state
    =head2 	context
    =head2 	context_is_book
    =head2 	context_is_chapitre
    =head2 	context_is_verset
    =head2 	context_words

=head2 	bol
=head2 	bolold
=head2 	context
=head2 	context_is_book
=head2 	context_is_chapitre
=head2 	context_is_verset
=head2 	context_words
=head2 	formatted_normalize
=head2 	n
=head2 	parse
=head2 	parse_chapitre
=head2 	parse_context_words
=head2 	parse_verset
=head2 	set_context_words
=head2 	shared_state
=head2 	state
=head2 	state_is_book
=head2 	state_is_chapitre
=head2 	state_is_verset
=head2  set_key
=head2  set_key2
=head2  set_ob
=head2  set_ob2


    Requires a hash of values to initalize the Bible reference. Optional argument a previous reference which can provide context for initializing a reference

    =head2 state_is_verset

    Returns true if the current the state is VERSE

    =head2 state_is_chapitre

    Returns true if the current the state is CHAPTER

    =head2 state_is_book   

    Returns true if the current the state is BOOK

    =head2 parse
    =head2 parse_chapitre
    =head2 parse_verset
    =head2 parse_context_words
    =head2 set_context_words

    =head1 DIAGNOSTICS

    =for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

    =over

    =item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

    =item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

    =back

    =head1 CONFIGURATION AND ENVIRONMENT

    =for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
    
    Religion::Bible::Regex::Reference requires no configuration files or environment variables.

    =head1 DEPENDENCIES

    =over 4

    =item * Religion::Bible::Regex::Config

    =item * Religion::Bible::Regex::Builder

    =back

    =head1 INCOMPATIBILITIES

    =for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
			 filters are mutually incompatible).

    None reported.


    =head1 BUGS AND LIMITATIONS

    =for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

    No bugs have been reported.

    Please report any bugs or feature requests to
    C<bug-religion-bible-regex-reference@rt.cpan.org>, or through the web interface at
    L<http://rt.cpan.org>.


    =head1 AUTHOR

    Daniel Holmlund  C<< <holmlund.dev@gmail.com> >>


    =head1 LICENCE AND COPYRIGHT

    Copyright (c) 2009, Daniel Holmlund C<< <holmlund.dev@gmail.com> >>. All rights reserved.

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself. See L<perlartistic>.

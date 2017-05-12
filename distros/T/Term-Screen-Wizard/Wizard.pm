package Term::Screen::Wizard;

use strict;
no strict 'refs';

use base qw(Term::Screen::ReadLine);
use Term::Screen::ReadLine;

use vars qw($VERSION);

BEGIN {
  $VERSION=0.56;
}

sub system {
  my $self=shift;
  my $cmd;
  foreach my $f (@_) {
    $cmd.="$f ";
  }
  system "stty -raw echo";
  system @_;
  system "stty raw -echo";
}

sub add_screen {
  my $self = shift;
  my $args = {
    NAME      => "noname",
    HEADER    => "",
    FOOTER    => "",
    CANCEL    => "Esc - Cancel",
    NEXT      => "Ctrl-Enter - Next",
    PREVIOUS  => "F3 - Previous",
    FINISH    => "Ctrl-Enter - Finish",
    NOFINISH  => 0,
    HASPREVIOUS => 0,
    HELPTEXT  => undef,
    HELP      => "F1 - Help",
    ROW       => 2,
    COL       => 2,
    PROMPTS   => undef,
    READONLY  => undef,
    @_,
  };

  my $arr=$self->{SCREENS};
  my @array;

  #$self->del_screen($args->{NAME});
  foreach my $scr (@{ $self->{SCREENS} }) {
     return 0 if ($scr->{NAME} eq $args->{NAME});
  }

  if ($arr) { @array=@$arr; }
  push @array, $args;
  $self->{SCREENS}=\@array;
return 1;
}

sub del_screen {
  my $self = shift;
  my $name = shift;
  my $i;
  my %screen;
  my $scr;
  my $arr=$self->{SCREENS};
  my @array=@$arr;
  my @narray=();
  my $retval=0;

  $self->{SCREENS}=();

  foreach $scr (@array) {
    if ($scr->{NAME} eq $name) {
      $retval=1;
    }
    else {
      push @narray,$scr;
    }
  }
  $self->{SCREENS}=\@narray;
return 0;
}


sub get_keys {
  my $self = shift;
  my $scr;
  my %values;
  my %screens;
  my $screens;

  foreach  $scr (@_) { $screens{$scr}=1;$screens+=1; }
  if ($screens == 0) {my $a;
    foreach $a (@{ $self->{SCREENS} }) {
      $screens{$a->{NAME}}=1;
    }
  }

  for $scr (@{ $self->{SCREENS} }) {
    next if (not exists $screens{$scr->{NAME}});
    my $prompt;
    my $name=$scr->{NAME};
    for $prompt (@{ $scr->{PROMPTS} }) {
       #$self->at(22,0)->puts($prompt->{KEY})->puts(" - ")->puts($prompt->{NEWVALUE})->getch();
      $values{$name}{$prompt->{KEY}}=$prompt->{VALUE};
    }
  }
return %values;
}

sub wizard {
  my $self=shift;
  my $i=0;
  my $arr=$self->{SCREENS};
  my @array=@$arr;
  my $scr;
  my $i;
  my $N;
  my $what;
  my $footer;
  my $space=chr(32).chr(32).chr(32);
  my $scr_name;

  my @screens;
  $N=0;

  if ($self->{COLS} <= 0) {
    die "Term::Screen::COLS <= 0, please set environment variable \$COLUMNS\n";
  }
  if ($self->{ROWS} <= 0) {
    die "Term::Screen::ROWS <= 0, please set environment variable \$LINES\n";
  }

  foreach $i (@_) {
    push @screens,$i;
  }
  $N=scalar @screens;
  if ($N == 0) {my $a;
    foreach $a (@array) {
      push @screens,$a->{NAME};
    }
  }
  $N=scalar @screens;

  $i=0;
  while ($i < $N) {
    $scr_name=$screens[$i];
    foreach my $a ( @array ) {
      if ($scr_name eq $a->{NAME}) {
	$scr=$a;
	last;
      }
    }

    $footer="";
    if ($scr->{HELPTEXT}) { $footer.=$space.$scr->{HELP}; }
    $footer.=$space.$scr->{CANCEL};
    if ($i  >  0  or $scr->{HASPREVIOUS} ) { $footer.=$space.$scr->{PREVIOUS}; }
    if ($i  < $N-1 or $scr->{NOFINISH} ) { $footer.=$space.$scr->{NEXT}; }
    if ($i == $N-1 and not $scr->{NOFINISH} ) { $footer.=$space.$scr->{FINISH}; }
    $scr->{FOOTER}=$footer;

    $what=$self->_display_screen($scr);

    if ($what eq "previous") {
      if ($i==0 and $scr->{HASPREVIOUS}) { last; }
      if ($i >0) { $i-=1; }
    }
    elsif ($what eq "next") {
      $i++;
      if ($i == $N) { last; }
    }
    else {
      last;
    }
  }

  if ($what ne "cancel") {
    my $scr_name;
    $what="finish" if ($what ne "previous");
    foreach $scr_name (@screens) {
      foreach my $a ( @array ) {
        if ($scr_name eq $a->{NAME}) {
	  $scr=$a;
	  last;
        }
      }

      my $prompt;

      if ($scr->{NOFINISH}) {
        $what="next" if ($what ne "previous");
      }
      else {
        $what="finish" if ($what ne "previous");
      }

      foreach $prompt (@{ $scr->{PROMPTS} }) {
	$prompt->{VALUE}=$prompt->{NEWVALUE};
	$prompt->{NEWVALUE}=undef;
      }
    }
  }
  else {
    foreach $scr_name (@screens) {
      foreach my $a ( @array ) {
        if ($scr_name eq $a->{NAME}) {
	  $scr=$a;
	  last;
        }
      }
      foreach my $prompt (@{ $scr->{PROMPTS} }) {
	$prompt->{NEWVALUE}=undef;
      }
    }
  }

return $what;
}

sub _display_screen {
  my $self   = shift;
  my $scr    = shift;
  my $prompt;
  my $promptlen;
  my $displen;
  my $i;
  my $key;
  my @prompts=@{ $scr->{PROMPTS} };
  my $line;
  my $N;
  my $val;
  my $only;
  my $convert;
  my $dashes;
  my %keys;
  my $valid;


  %keys = ( "esc"	=> 1,
	    "ctrl-enter" => 1,
	    "pgdn"	 => 1,
	    "pgup"	 => 1,
	    "k3"	 => 1,
	    "k4"	 => 1,
	    "k1"	 => 2,
	   );


  {my $i;
     for(1..$self->{COLS}) {
       $dashes.="-";
     }
  }

  $N=scalar @prompts;
  $key="none";

  while (not defined $keys{$key} or $keys{$key} == 2) {

    $self->clrscr();

    if ($scr->{HEADER}) {
      $self->at(0,0)->puts($scr->{HEADER});
      $self->at(1,0)->puts($dashes);
    }
    if ($scr->{FOOTER}) {
      $self->at($self->{ROWS}-1,0)->puts($scr->{FOOTER});
      $self->at($self->{ROWS}-2,0)->puts($dashes);
    }

    if ($key eq "k1") {
      $self->at(3,0)->puts($scr->{HELPTEXT});
      $self->getch();
      $key="";
      next;
    }

    $key="";
    $promptlen=0;
    $i=3;
    foreach $prompt ( @prompts ) {
      my $s=$prompt->{PROMPT};
      if (($prompt->{KEY} ne "NIL") and (not $prompt->{NIL})) {
        if (length $s > $promptlen) { $promptlen=length $s; }
      }
      else {
        $prompt->{NIL}=1;
      }
      $self->at($i,0)->puts($prompt->{PROMPT});
      $i++;
    }

    $promptlen++;
    $displen=$self->{COLS}-$promptlen-3;     # see increment of promptlen below

    $i=3;
    foreach $prompt ( @prompts	) {
      if (not defined $prompt->{NEWVALUE}) {
	$val=$prompt->{VALUE};
	$prompt->{NEWVALUE}=$val;
      }
      else {
	$val=$prompt->{NEWVALUE};
      }

      my $L=length $val;

      if ($prompt->{PASSWORD}) {
         $val=$self->setstr("*",$L);
      }

      if ($L>$displen) { $L=$displen; }
      $val=substr($val,0,$L);

      if (not $prompt->{NIL}) {
        $self->at($i,$promptlen)->puts(": $val");
      }
      $i++;
    }

    $promptlen+=2;

    $i=0;
    while (($i < $N) and $prompts[$i]->{NIL}) {
      $i+=1;
    }
    #print "$i\n";getc();

    while (not defined $keys{$key}) {

      if ($prompts[$i]->{ONLYVALID}) {
	$only=$prompts[$i]->{ONLYVALID};
      }
      else {
	$only=undef;
      }

      if ($prompts[$i]->{CONVERT}) {
	$convert=$prompts[$i]->{CONVERT};
      }
      else {
	$convert=undef;
      }

      my $readonly=$scr->{READONLY};
      if (not defined $readonly) {
        $readonly=$prompts[$i]->{READONLY};
      }

      $line=$self->readline(ROW => $i+3, COL => $promptlen,
			    LEN => $prompts[$i]->{LEN},
			    DISPLAYLEN => $displen,
			    LINE => $prompts[$i]->{NEWVALUE},
			    EXITS => { "pgup" => "pgup", "pgdn" => "pgdn", "k1" => "k1", "k3" => "k3", "k4" => "k4" },
			    ONLYVALID => $only,
			    CONVERT => $convert,
			    PASSWORD => $prompts[$i]->{PASSWORD},
			    NOCOMMIT => $prompts[$i]->{NOCOMMIT},
			    READONLY => $readonly,
			   );

      {my $L=length $line;
       my $val=$line;
	 if ($L>$displen) { $L=$displen; }
	 if ($prompts[$i]->{PASSWORD}) {
           $val=$self->setstr("*",$L);
	 }
	 $val=substr($val,0,$L);
	 $self->at($i+3,$promptlen)->puts($val);
      }

      if ((exists $prompts[$i]->{VALIDATOR}) and ($self->lastkey() ne "esc")) {
        my $expr=$prompts[$i]->{VALIDATOR};
        if (not $expr=~/::/) { $expr="::".$expr; }
        $valid=&$expr($self,$line);
      }
      else {
        $valid=1;
      }

      if ($valid) {
        $prompts[$i]->{NEWVALUE}=$line;
        $key=$self->lastkey();
        #$self->at(22,0)->puts(" $key - $line")->getch();
      }
      else {
        $key=$self->lastkey();
        if ($key ne "k1" and $key ne "esc" and $key ne "k3") { $key=""; }
      }

      if ($key eq "tab" or $key eq "enter" or $key eq "kd") {
        if ($prompts[$i]->{READY} and ((length $line) gt 0)) {
           $i=$N;
        }
        else {
	  $i+=1;
          while ($prompts[$i]->{NIL} and ($i < $N)) {
            $i++;
          }
        }
	if ($i >= $N) {
	  $i=0;
	  if ($key eq "enter") {
	    $key="ctrl-enter";
	  }
	}
      }
      elsif ( $key eq "ku" ) {
	$i--;
        while ($prompts[$i]->{NIL} and ($i >= 0)) {
          $i--;
        }
	if ($i < 0 ) { $i=$N-1; 
          while ($prompts[$i]->{NIL} and ($i >= 0)) {
            $i--;
          }
        }
      }

    }
  }

  if ($key eq "esc") {
    return "cancel";
  }
  elsif ($key eq "ctrl-enter" or $key eq "pgdn" or $key eq "k4" ) {
    return "next";
  }
  elsif ($key eq "pgup" or $key eq "k3" ) {
    return "previous";
  }
}

sub set {
  my $self   = shift;
  my $screen = shift;
  my $scr    = $self->_get_screen($screen)
	or die "unknown screen \"$screen\"";
  my $id     = shift;

  if (exists $scr->{$id}) {
    if ($id eq "PROMPTS") {
     my $key=shift;
     my $found=0;
     my @prompts=@{$scr->{PROMPTS}};
     my $prompt;
      foreach $prompt (@prompts) {
        if ($prompt->{KEY} eq $key) {
         my $id=shift;
         my $val=shift;
          $found=1;
          $prompt->{$id}=$val;
        }
      }
      if (not $found) {
        die "Can't find key <$key> in prompts of screen\n";
      }
    }
    else {
      $scr->{$id}=shift;
    }
  }
  else {
    my $found=0;
    my $prompt;
    my @prompts=@{$scr->{PROMPTS}};
    foreach $prompt (@prompts) {
      if ($prompt->{KEY} eq $id) {
         $prompt->{VALUE}=shift;
         $found=1;
         last;
      }
    }
    if (not $found) {
      die "Can't find key <$id> in screen or prompts of screen\n";
    }
  }

return $self;
}

sub get {
  my $self   = shift;
  my $screen = shift;
  my $scr    = $self->_get_screen($screen)
	or die "unknown screen \"$screen\"";
  my $id     = shift;

  if (exists $scr->{$id}) {
    if ($id eq "PROMPTS") {
     my $key=shift;
     my $found=0;
     my @prompts=@{$scr->{PROMPTS}};
     my $prompt;
      foreach $prompt (@prompts) {
        if ($prompt->{KEY} eq $key) {
         my $id=shift;
          #$self->at(17,0)->puts("$key");
          #$self->at(18,0)->puts("$id=")->puts($prompt->{$id})->getch();
          $found=1;
          return $prompt->{$id};
        }
      }
      if (not $found) {
        die "Can't find key <$key> in prompts of screen\n";
      }
    }
    else {
      return $scr->{$id};
    }
  }
  else {
    my $found=0;
    my $prompt;
    my @prompts=@{$scr->{PROMPTS}};
    foreach $prompt (@prompts) {
      if ($prompt->{KEY} eq $id) {
         return $prompt->{VALUE};
         $found=1;
         last;
      }
    }
    if (not $found) {
      die "Can't find key <$id> in screen or prompts of screen\n";
    }
  }
}


sub _get_screen {
  my $self = shift;
  my $name = shift;
  my %screen;
  my $scr;
  my $arr=$self->{SCREENS};
  my @array=@$arr;

  foreach $scr (@array) {
    if ($scr->{NAME} eq $name) {
      return $scr;
    }
  }

return undef;
}

=pod

=head1 NAME

Term::Screen::Wizard - A wizard on your terminal...

=head1 SYNOPSIS

	use Term::Screen::Wizard;

	$scr = new Term::Screen::Wizard;

	$scr->clrscr();

	$scr->add_screen(
	      NAME => "PROCES",
	      HEADER => "Give me the new process id",
	      CANCEL => "Esc - Annuleren",
	      NEXT   => "Ctrl-Enter - Volgende",
	      PREVIOUS => "F3 - Vorige",
	      FINISH => "Ctrl-Enter - Klaar",
	      PROMPTS => [
		 { KEY => "PROCESID", PROMPT => "Proces Id", LEN=>32, VALUE=>"123456789.00.04" , ONLYVALID => "[a-zA-Z0-9.]*" },
		 { KEY => "TYPE", PROMPT => "Intern or Extern Process (I/E)", CONVERT => "up", LEN=>1, ONLYVALID=>"[ieIE]*" },
		 { KEY => "OMSCHRIJVING", PROMPT => "Description of Proces", LEN=>75 },
		 { KEY => "PASSWORD", PROMPT => "Enter a password", LEN=>14, PASSWORD=>1 }
			],

#
# OK This helptext is in Dutch, but it's clear how it works isn't it?
#
	      HELPTEXT => "\n\n\n".
		      "  In dit scherm kan een nieuw proces Id worden opgevoerd\n".
		      "\n".
		      "  ProcesId      - is het ingevoerde Proces Id\n".
		      "  Intern/Extern - is het proces belastingdienst intern of niet?\n".
		      "  Omschrijving  - Een korte omschrijving van het proces.\n"
	     );

	$scr->add_screen(
	   NAME => "X.400",,
	   HEADER => "Voer het X.400 adres in",
#
# So the point is you can change the Wizard 'buttons'.
#
	   CANCEL => "Esc - Annuleren",
	   NEXT   => "Ctrl-Enter - Volgende",
	   PREVIOUS => "F3 - Vorige",
	   FINISH => "Ctrl-Enter - Klaar",
	   PROMPTS => [
	     { KEY => "COUNTRY", PROMPT => "COUNTRY", LEN => 2, CONVERT => "up", ONLYVALID => "[^/]*" },
	     { KEY => "AMDM",	 PROMPT => "AMDM",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
	     { KEY => "PRDM",	 PROMPT => "PRDM",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
	     { KEY => "ORG",	 PROMPT => "ORGANISATION",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
	     { KEY => "OU1",	 PROMPT => "UNIT1",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
	     { KEY => "OU2",	 PROMPT => "UNIT2",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
	     { KEY => "OU3",	 PROMPT => "UNIT3",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
	   ],
	   HELPTEXT => "\n\n\n".
		   "  In dit scherm kan een standaard X.400 adres worden ingevoerd voor een ProcesId",
	);

	$scr->add_screen(
	   NAME => "GETALLEN",,
	   HEADER => "Voer getallen in",
	   CANCEL => "Esc - Annuleren",
	   NEXT   => "Ctrl-Enter - Volgende",
	   PREVIOUS => "F3 - Vorige",
	   FINISH => "Ctrl-Enter - Klaar",
	   PROMPTS => [
	     { KEY => "ANINT",	   PROMPT => "INT",	LEN => 10, CONVERT => "up", ONLYVALID => "[0-9]*" },
	     { KEY => "ADOUBLE",  PROMPT => "DOUBLE",  LEN => 16, CONVERT => "up", ONLYVALID => "[0-9]+([.,][0-9]*)?" },
	   ],
	);

	$scr->wizard();

	$scr->wizard("PROCES","GETALLEN");

	$scr->clrscr();

	%values=$scr->get_keys();
	@array=( "PROCES", "X.400", "GETALLEN" );

	for $i (@array) {
	  print "\n$i\n\r";
	  for $key (keys % { $values{$i} }) {
	    my $val=$values{$i}{$key};
	    print "  $key=$val\n\r";
	  }
	}

	%values=$scr->get_keys("X.400","PROCES");

	exit;

=head1 DESCRIPTION

This is a module to have a Wizard on a Terminal. It inherits from
Term::Screen::ReadLine. The module provides some functions to add
screens. The result is a Hash with keys that have the (validated)
values that the used inputted on the different screens.

=head1 USAGE

Description of the interface.

 add_screen(
    NAME      => <name of screen>,
    HEADER    => <header to put on top of screen>,
    CANCEL    => <text of cancel 'button', defaults to 'Esc - Cancel'>,
    NEXT      => <text of next 'button', defaults to 'Ctrl-Enter - Next'>,
    PREVIOUS  => <text of previous 'button', defaults tro 'PgUp - Previous'>,
    FINISH    => <text of finish 'button', defaults to 'Ctrl-Enter - Finish>,
    HELP      => <text of help 'button', defaults to 'F1 - Help'>,
    HELPTEXT  => <text to put on your helpscreen>
    NOFINISH  => <1/0 - Inidicates that this wizard is/is not (1/0) part
			of an ongoing 'wizard sequence'>
    READONLY  => <1/0 - read only option to get a read only screen>
    PROMPTS   => <array of fields to input>
 )

   This function add's a screen to the list of screens that the wizards goes
   through sequentially. If NOFINISH==1, the finish 'button' is not used. Use
   this, if the last screen of this wizard is not actually the last screen
   of a sequence of wizards.

   For instance, if you need to go one way or the other after the first screen,
   you provide a wizard with one screen and no FINISH button. After that you
   call the next sequence of screens.

	   PROMPTS => [
	     { KEY => "ANINT",	   PROMPT => "INT",	LEN => 10, CONVERT => "up", ONLYVALID => "[0-9]*", READONLY => 1 },
	     { KEY => "ADOUBLE",  PROMPT => "DOUBLE",  LEN => 16, CONVERT => "up", ONLYVALID => "[0-9]+([.,][0-9]*)?" },
	     { KEY => "DATE",  PROMPT => "DATE",  LEN => 8, CONVERT => "up", ONLYVALID => "[0-9]+", VALIDATOR => "ValidateCCYYMMDD" },
	   ]

     sub ValidateCCYYMMDD {
       my $wizard=shift;
       my $line=shift;
       (...)

       return <1/0>
     }

  Note the entries in PROMPTS :

     KEY	 is the hash key with what you can access the field.
     PROMPT	 is the prompt to use for the field.
     LEN	 is the maximum length of the field.
     CONVERT	 'up' or 'lo' for uppercase or lowercase. If not used
		 it won't convert.
     ONLYVALID	 is a regex to use for validation. Note: validation is
		 done *before* conversion! If not used, no validation is
		 done.
     VALUE	 a default value to use. This value will change if the
		 wizard is used.
     VALIDATOR   a validator sub to validate a line of input, after it has
                 been inputted.
     READONLY    Set this prompt readonly.
     NOCOMMIT    defined/undefined ==> This field will not ask for a return,
                 works great for choices (LEN=1).
     READY       If this field has had it's input, go to the next screen.


 del_screen(<name>)

   This function deletes a screen with given name from the list of screens.


 get_keys([screens])

   Optional arguments are screens to use. Example:

      %values=$a->get_keys()			-> gives all screens.
      %values=$a->get_keys("PROCESS","NUMBERS") -> gives only screens PROCESS and NUMBERS.

   This function gives you all the keys in a hash of a hash. Actually
   a hash of screens and each screen a hash of keys. See synopsis for
   usage.


 set(SCREEN,KEY,VALUE,...)

   To set key KEY of screen SCREEN equal to VALUE. Example:

      $wizard->set("NUMBERS",HEADER,"This is the new header");

   sets the HEADER of screen NUMBERS to a new value.

      $wizard->set("NUMBERS","ADOUBLE",999.999);

   sets the prompt ADOUBLE of screen NUMBERS to 999.999

   More examples:

        $scr->set("GETALLEN",HEADER,"dit is de header");
        $scr->set("GETALLEN","ADOUBLE",999.99);
        $scr->set("PROCES",READONLY,1);
        $scr->set("PROCES",HEADER,"proces scherm is read only nu");
        $scr->set("GETALLEN",PROMPTS,ANINT,READONLY,1);

 get(SCREEN,KEY,...)

    To get the value of key KEY of screen SCREEN. Example:
    
       $wizard->get(NUMBERS,HEADER);
       $wizard->get(NUMBERS,PROMPTS,ANINT,PROMPT);
       

 wizard([screens])

    Optional arguments are screens to use. Example:

      $result=$a->wizard()	    -> processes all screens.
      $result=$a->wizard("PROCESS") -> processes only screen PROCESS.

   This function starts the wizard.
   Possible results are:

	    ="cancel",	the user canceled the wizard; values are not updated.
	    ="finish",	the user finished the wizard.
	    ="next",	the user finished the wizard and the last prompt
			has option "NOFINISH".

=head1 AUTHOR

  Hans Dijkema <hans@oesterholt-dijkema.emailt.nl>

=cut

1;


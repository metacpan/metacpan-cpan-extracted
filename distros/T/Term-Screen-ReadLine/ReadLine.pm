package Term::Screen::ReadLine;

use strict;
use base qw(Term::Screen);
use Term::Screen;
use vars qw($VERSION);

BEGIN {
  $VERSION=0.38;
}

sub readline {
  my $self	 = shift;
  my $args	 = {
    ROW 	=> 0,
    COL 	=> 0,
    LEN 	=> 40,
    DISPLAYLEN	=> undef,
    LINE	=> "",
    EXITS	=> {},
    ONLYVALID	=> undef,
    CONVERT	=> undef,
    PASSWORD	=> undef,
    NOCOMMIT    => 0,
    READONLY    => 0,
    OVERWRITE   => 0,
    @_
  };
  my $row	 = $args->{ROW};
  my $column	 = $args->{COL};
  my $lineLen	 = $args->{LEN};
  my $displayLen = $args->{DISPLAYLEN};
  my $line	 = $args->{LINE};
  my %exits	 = %{ $args->{EXITS} };
  my $onlyvalid  = $args->{ONLYVALID};
  my $convert	 = $args->{CONVERT};
  my $cursor     = length $line;
  my $nocommit   = $args->{NOCOMMIT};
  my $readonly   = $args->{READONLY};
  my $overwrite  = $args->{OVERWRITE};
  
  if (length $line == 1) { $cursor=0; }

  $self->{PASSWORD}=$args->{PASSWORD};

  if (defined $convert) {
    $convert=~tr/a-z/A-Z/;
    if ("UPPERCASE"=~/^$convert/) {
      $convert="up";
    }
    elsif ("LOWERCASE"=~/^$convert/) {
      $convert="lo";
    }
    else {
      $convert="";
    }
  }
  else {
    $convert="";
  }

  if ($convert eq "up") { $line=~tr/a-z/A-Z/; }
  elsif ($convert eq "lo") { $line=~tr/A-Z/a-z/; }

  my $c;
  my $ordc;

  if (not defined $displayLen) { $displayLen = $args->{LEN}; }

  $self->_print_line($line,$displayLen,$row,$column,$cursor,2,$overwrite);

  $exits{"013"}="enter"   if not exists $exits{"013"};
  $exits{"ku"}="ku"	  if not exists $exits{"ku"};
  $exits{"kd"}="kd"	  if not exists $exits{"kd"};
  $exits{"027"}="esc"	  if not exists $exits{"027"};
  $exits{"009"}="tab"	  if not exists $exits{"009"};
  $exits{"010"}="ctrl-enter" if not exists $exits{"010"};

  $self->noecho();

  $c=$self->getch();
  $ordc=sprintf("%03d",ord($c));

  while ( (not exists $exits{$c}) and (not exists $exits{$ordc}) ) {


   if ($readonly) {
     ## next if readonly
   }
   elsif ($lineLen == 1) {
     ## If the requested line length is 1 don't try any line processing

      if (($c ge " ") and ($c le "~") and (length $c == 1)) {
       my $input=0;

        if ($convert eq "up") { $c=~tr/a-z/A-Z/; }
        elsif ($convert eq "lo") { $c=~tr/A-Z/a-z/; }

        if (defined $onlyvalid) {
	  if ($c=~/^$onlyvalid$/) { 
            $input=1;
          }
        }
        else {
          $input=1;
        }

        if ($input==1) {
          $line=$c;
          $self->_print_line($line,$displayLen,$row,$column,$cursor,2);
          if ($nocommit) { $c=chr(13);$ordc="013";last; }
        }

      }

   }
   else {

    ## Else do difficult processing
    #print "ordc=$ordc\n";

    if ($ordc==8 || $ordc==127) {my $L;
      $self->_print_line($line,$displayLen,$row,$column,$cursor,1);
      $L=length $line;
      $L--;
      $line=substr($line,0,$L);
    }
    elsif (($c ge ' ') and ($c le '~') and (length $c == 1)) {

      if ($convert eq "up") { $c=~tr/a-z/A-Z/; }
      elsif ($convert eq "lo") { $c=~tr/A-Z/a-z/; }

      my $L=length $line;
      if ($L < $lineLen) {my $extend=0;
	if (defined $onlyvalid) {
	  my $s=$line.$c;
	  if ($s=~/^$onlyvalid$/) {
            $extend=1;
          }
	}
        if (not defined $onlyvalid) {
          $extend=1;
        }
        if ($extend) {
	    $line=$line.$c;
	    $self->_print_line($line,$displayLen,$row,$column,$cursor,0);
	}
      }
    }
   }
   $c=$self->getch();
   $ordc=sprintf("%03d",ord($c));
  }

  #$self->at(20,0)->puts("$ordc")->getch();

  $self->{LASTKEY}=$c;
  $self->{LASTKEY}=$exits{$c}	 if exists $exits{$c};
  $self->{LASTKEY}=$exits{$ordc} if exists $exits{$ordc};

return $line;
}

sub two_esc {
  my $self=shift;
  $self->{READLINEGETCH}=0;
}

sub one_esc {
  my $self=shift;
  $self->{READLINEGETCH}=1;
}

# Redefinition of getch() to have the Escape key fixed.
# This one only works from STDIN!

sub getch {
  my $self = shift;
  my $c;
  my $L;

  if (not defined $self->{READLINEGETCH}) {
    $self->one_esc;
  }
  if (not $self->{READLINEGETCH})  {
    return $self->Term::Screen::getch();
  }

  sysread STDIN,$c,1;
  if (ord($c)==0) { exit 100; }

  if ($c eq "\e") {
    while ($self->key_pressed(0)) {my $cc;
      sysread STDIN,$cc,1;
      $c.=$cc;
      if ($self->{KEYS}{$c}) {
	$c=$self->{KEYS}{$c};
      }
    }
  }
  else {
      if (exists $self->{KEYS}{$c}) {
	$c=$self->{KEYS}{$c};
      }
  }
return $c;
}

sub lastkey {
  my $self=shift;
  return $self->{LASTKEY};
}

#####################################################################
# Internal routines
#####################################################################

#
# $mode = 0 --> normal mode
# $mode = 1 --> delete mode
# $mode = 2 --> initial mode
#

sub _print_line {
  my ($self, $line,  $displaylen, $row, $column, $cursor, $mode, $overwrite) = @_;
  my $L;

  $L=length $line;

  if ($self->{PASSWORD}) {
    $line=$self->setstr("*",$L);
  }
      #my $a=$L-$displaylen;
      #my $ll=length $line;
      #$self->at(22,0)->puts("$line - $ll - $a - $L - $displaylen");


  if ($L>$displaylen) {
    if ($mode == 1) {
      $self->at($row,$column)->puts(substr($line,$L-$displaylen-1,$displaylen));
    }
    else {
      $self->at($row,$column)->puts(substr($line,$L-$displaylen,$displaylen));
    }
  }
  else {
    if ($mode == 1 and $L > 0) {
      print chr(8).chr(32).chr(8);
    }
    elsif ($mode == 2 ) {
       my $str='';
	   my $i;
       unless($overwrite) {
      for(1..$displaylen-$L) {
	$str.=" ";
      }
      }
      $self->at($row,$column)->puts($line)->puts($str);
      $self->at($row,$column+$L);
    }
    elsif ($L <= $displaylen) {
      print substr($line,$L-1,1);
    }
  }
}

sub setstr {
  my ($self,$char,$len)=@_;

  if ($len <= 0) {
    return "";
  }
  elsif ($len==1) {
    return $char;
  }
  elsif ($len%2==1) {
    return $char.$self->setstr($char,$len-1);
  }
  else {
    return $self->setstr($char.$char,$len>>1);
  }
}


=pod

=head1 NAME

Term::Screen::ReadLine - Term::Screen extended with ReadLine

=head1 SYNOPSIS

  use lib "./blib/lib";

  use Term::Screen::ReadLine;

  $scr = new Term::Screen::ReadLine;

  $scr->clrscr();
  $a=$scr->getch();
  print $a," ",length $a," ",ord($a),"\n";
  $scr->two_esc;
  $a=$scr->getch();
  print $a," ",length $a," ",ord($a),"\n";
  $scr->one_esc;


  $scr->clrscr();
  $scr->at(4,4)->puts("input? ");
  $line=$scr->readline(ROW => 4, COL => 12);
  $line=$scr->readline(ROW => 5, COL => 12, DISPLAYLEN => 20);
  $scr->at(10,4)->puts($line);
  $scr->two_esc;
  $line=$scr->readline(ROW => 6, COL => 12, DISPLAYLEN => 20, ONLYVALID => "[ieIE]+", CONVERT => "up");

  print "\n";
  print $scr->lastkey(),"\n";

  $r=$scr->getch();
  print $r,ord($r),"\n";
  $r=ord($r);
  print $r,"\n";
  if ($r eq 13) { 
    print "aja!\n";
  }


exit;


=head1 DESCRIPTION

This module extends Term::Screen with a readline() function.
It also makes it possible to use a *single* Esc to escape instead
of the Term::Screen double Esc.

=head1 USAGE

=head2 readline()

  readline(
    ROW 	=> 0,
    COL 	=> 0,
    LEN 	=> 40,
    DISPLAYLEN	=> undef,
    LINE	=> "",
    ONLYVALID	=> undef,
    CONVERT	=> undef,
    PASSWORD	=> undef,
    OVERWRITE   => undef,
  )

I<B<Parameters>>

=over 1

=item ROW,COL

'at(ROW,COL) readline()...'.

=item LEN

The maximum length of the line to read.

=item DISPLAYLEN

The maximum length of the displayed field. The display will scroll if C<DISPLAYLEN> is exceeded.

=item EXITS

Explained below.

=item LINE

A default value for readline to use.

=item ONLYVALID

A regex to validate the input.

=item CONVERT

B<"up"> or B<"lo"> for uppercase or lowercase. Empty (B<"">) if not used. 
I<Note: conversion will take place B<after> validation>.

=item PASSWORD

Display stars ('*') instead of what is being typed in.

=item OVERWRITE

By default readline will clear characters from the current position to the end
of the given field length. By setting OVERWRITE to a non-zero value will any
characters visible in the field to be overwritten rather than removed.

=back

I<B<Return value>>

=over 1

Returns The inputted line.

=back

I<B<Notes>>

=over 1

=item *

The readline() function does always return on the following keys:
C<Enter>, C<Arrow Up>, C<Arrow Down>, C<Esc>, C<Tab> and C<Ctrl-Enter/F4>.

This can be extended using the EXITS argument, which must be a hash of
keys (see Term::Screen) and a description that will be returned for that key.

example: C<EXITS =E<gt> { "k1" =E<gt> "help", "k3" =E<gt> "cancel" }>.

This will bind 'F1' to a 'help' message and 'F3' to a 'cancel' message. 

=item *

The readline() function will issue an C<exit(100)>, if a '\0' character is 
read. This is what usually happens when reading from STDIN does not 
give 'eof()' condition as would be nice, if a telnet session is suddenly
killed. Not exiting on a '\0' character will result in a racing perl
script.

=back

=head2 last_key()

returns the last key pressed, that made the readline function return.

=head2 one_esc()

Makes it possible to press only one time Esc to make readline return.
This is the default for Term::Screen::ReadLine.

=head2 two_esc()

Revert back to the standard Term::Screen behaviour for the Esc key.

=head1 AUTHOR

Hans Dijkema <oesterhol@cpan.org>

=head1 LICENSE

Artistic

=cut

1;


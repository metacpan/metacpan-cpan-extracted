package Sys::Sig;

use strict;
use Config;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

require Exporter;

$VERSION = do { my @r = (q$Revision: 0.05 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw(Exporter);

@EXPORT_OK = split(/\s+/,$Config{sig_name});
%EXPORT_TAGS = (
	all	=> [@EXPORT_OK],
);

my %signal;
@signal{@EXPORT_OK} = split(/\s+/,$Config{sig_num});

sub DESTROY {};

sub AUTOLOAD {
  no strict;
  ($_ = uc $AUTOLOAD) =~ /[^:]+$/;
  return $signal{$&} if exists $signal{$&};
  croak "your system has not defined SIGNAL '$&'";
}

sub new {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = \$class;
  bless ($self, $class);
  return $self;
}

sub print {
  local *FH = shift || 'STDOUT';
  my $fh = *FH;
  foreach (sort keys %signal) {
    print $fh $_, "\t=> $signal{$_}\n";
  }
}

sub printN {
  local *FH = shift || 'STDOUT';
  my $fh = *FH;
  foreach(sort {
	$signal{$a} <=> $signal{$b}
		||
	$a cmp $b } keys %signal) {
    print $fh $_, "\t=> $signal{$_}\n";
  }
}

=head1 NAME

  Sys::Sig -- return signal constants for this host

=head1 SYNOPSIS

=head2 AS METHODS

  use Sys::Sig;


  my $TERM = Sys::Sig->TERM;

  kill $TERM, $pid;

	or

  my $Sig = new Sys::Sig;

  my $TERM = $Sig->TERM;
  ...

NOTE: the signal name is not case sensitive. 
The following will work just as well for METHODS ONLY:

 my $TERM = $Sig->TeRm;

=head2 AS FUNCTIONS

  use Sys::Sig qw(:all)
  use Sys::Sig qw(
	HUP
	TERM
	etc...
  );

Use this syntax with care. Depending on the usage, perl may not interpret
the bare word correctly.

  i.e. my $term = TERM;

Better:

  my $term = &TERM;
  my $term = TERM();

or, without the import

  my $term = &Sys::Sig::TERM;

or, case insensitive for full package function call

  my $term = &Sys::Sig::term;
  my $term = Sys::Sig::term();

=head2 PRINT SIGNALS VALUES

Print an alphabetical list of all signals to the FILEHANDLE or
STDOUT if no filehandle is specified.

  Sys::Sig::print(*FILEHANDLE);

Print a numeric sorted list of all signals to the FILEHANDLE or          
STDOUT if no filehandle is specified.

  Sys::Sig::printN(*FILEHANDLE);

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT AND LICENCE

  Copyright 2006-2014, Michael Robinton <michael@bizsystems.com>
 
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 

=cut

1;

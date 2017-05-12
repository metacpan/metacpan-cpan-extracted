package Moot::TokPP;
use Moot::Waste::Annotator;
use Carp;
use strict;
use utf8;

our @ISA = qw();

our $ANNOTATOR = undef;

## $obj = CLASS->new
sub new {
  my $that = shift;
  return bless({wa=>Moot::Waste::Annotator->new()},ref($that)||$that)
}

## $annotator = CLASS_OR_OBJECT->annotator()
sub annotator {
  return ref($_[0]) && $_[0]{wa} ? $_[0]{wa} : ($ANNOTATOR // ($ANNOTATOR=Moot::Waste::Annotator->new()));
}

## $str = CLASS_OR_OBJECT->analyze_text($str)
sub analyze_text {
  my $a = $_[0]->annotator->annotate({text=>$_[1]})->{analyses};
  return join("\t", '', map {$_->{details}//$_->{tag}} @$a) if ($a && @$a);
  return undef;
}

## $w = CLASS_OR_OBJECT->analyze_token($w)
sub analyze_token {
  %{$_[1]} = %{$_[0]->annotator->annotate($_[1])};
  return $_[1];
}

## $line = CLASS_OR_OBJECT->analyze_line($line)
sub analyze_line {
  return $_[1] if ($_[1] =~ /^%%/);
  if ($_[1] =~ /^([^\t\r\n]*)(.*)\R?/) {
    my $a = $_[0]->analyze_text($1);
    return "$1$2$a\n" if (defined($a));
  }
  return $_[1];
}

## undef = CLASS_OR_OBJECT->analyze_stream(\*IN, \*OUT)
sub analyze_stream {
  my ($that,$in,$out) = @_;
  my ($w,$rest,$a);
  while (<$in>) {
    chomp;
    next if (/^$/ || /^%%/);
    ($w,$rest) = split(/\t/,$_,2);
    $_ .= $a if (defined($a=$that->analyze_text($w)));
  } continue {
    print $out $_,"\n";
  }
}

## \$obuf = CLASS_OR_OBJECT->analyze_buffer(\$ibuf, \$obuf)
sub analyze_buffer {
  my ($that,$iref,$oref) = @_;
  if (!defined($oref)) {
    my $obuf = '';
    $oref = \$obuf;
  }
  open(my $infh,  "<:utf8", $iref);
  open(my $outfh, ">:utf8", $oref);
  $that->analyze_stream($infh,$outfh);
  $infh->close;
  $outfh->close;
  return $oref;
}

1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::TokPP - libmoot : heuristic token analyzer (pseudo-morphology, wraps for Moot::Waste::Annotator)

=head1 SYNOPSIS

  use Moot::TokPP;

  ##=====================================================================
  ## Usage

  $pp = Moot::TokPP->new();    ##-- create a new pseudo-morphology

  $astr = $pp->analyze_text($str);             ##-- analyze a single token text string
  $w    = $pp->analyze_token($w);              ##-- analyze a token HASH-ref
  $line = $pp->analyze_line($line);	       ##-- analyze a 'native' text line
  undef = $pp->analyze_stream($infh,$outfh);   ##-- analyze a 'native' text stream
  $oref = $pp->analyze_buffer(\$ibuf);         ##-- analyze a 'native' text buffer

=head1 DESCRIPTION

The Moot::TokPP module provides a drop-in replacement for dwds_tomasotath-style tokenizer-supplied
pseudo-morphological analyses.

This module is currently implemented as a thin wrapper around L<Moot::Waste::Annotator|Moot::Waste::Annotator>, which see.

=head1 SEE ALSO

Moot::Waste(3perl),
Moot(3perl),
waste(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


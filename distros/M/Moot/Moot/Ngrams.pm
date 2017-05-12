package Moot::Ngrams;
use IO::File;
use Carp;
use strict;

##======================================================================
## wrappers: lookup

BEGIN {
  *n_1grams = \&n_unigrams;
  *n_2grams = \&n_bigrams;
  *n_3grams = \&n_trigrams;
  *n_tokens = \&ugtotal;
}

##======================================================================
## wrappers: I/O

## $lf_or_undef = $CLASS_OR_OBJ->load($filename_or_fh,[$filename])
sub load {
  my ($lf,$file,$name) = @_;
  $lf = $lf->new() if (!ref($lf));
  if (!ref($file)) {
    $lf->loadFile($file) or return undef;
  } else {
    $lf->loadFh($file,($name||"$file")) or return undef;
  }
  return $lf;
}

## $bool = $obj->save($filename_or_fh,[$compact,[$filename]])
sub save {
  my ($lf,$file,$compact,$name) = @_;
  if (!ref($file)) {
    $lf->saveFile($file,$compact) or return undef;
  } else {
    $lf->saveFh($file,$compact,($name||"$file")) or return undef;
  }
  return $lf;
}


1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::Ngrams - libmoot : n-gram frequencies

=head1 SYNOPSIS

  use Moot;

  ##=====================================================================
  ## Constructors etc
  $ng = Moot::Ngrams->new;
  $ng->clear();

  ##=====================================================================
  ## Accessors

  $n_1g  = $ng->n_1grams;
  $n_2g  = $ng->n_2grams;
  $n_3g  = $ng->n_3grams;
  $n_tok = $ng->n_tokens;

  $f1   = $ng->lookup($tag1);
  $f12  = $ng->lookup($tag1,$tag2);
  $f123 = $ng->lookup($tag1,$tag2,$tag3);

  $ng->add_count($tag1,             $f1);
  $ng->add_count($tag1,$tag2,       $f12);
  $ng->add_count($tag1,$tag2,$tag3, $f123);

  ##=====================================================================
  ## I/O

  $bool = $ng->loadFile($filename);
  $bool = $ng->loadFh($fh, $name);
  $ng   = $CLASS_OR_OBJECT->load($filename_or_fh, $name)

  $bool = $ng->saveFile($filename, $compact=0);
  $bool = $ng->saveFh($fh, $name="$fh", $compact=0);
  $bool = $ng->save($filename_or_fh, $name="$fh", $compact=0);

=head1 DESCRIPTION

The Moot module provides an object-oriented interface to the libmoot library
for Hidden Markov Model part-of-speech tagging.

=head1 SEE ALSO

Moot::constants(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


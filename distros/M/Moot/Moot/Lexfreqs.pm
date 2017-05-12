package Moot::Lexfreqs;
use IO::File;
use Carp;
use strict;

##======================================================================
## wrappers: lookup

## $f_wt = lookup($word,$tag)
## $f_w  = lookup($word)
## $f_t  = lookup(undef,$tag)
sub lookup {
  return (defined($_[1])
	  ? (defined($_[2])
	     ? $_[0]->f_word_tag($_[1],$_[2])
	     : $_[0]->f_word($_[1]))
	  : $_[0]->f_tag($_[2]));
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

## $bool = $obj->save($filename_or_fh,[$filename])
sub save {
  my ($lf,$file,$name) = @_;
  if (!ref($file)) {
    $lf->saveFile($file) or return undef;
  } else {
    $lf->saveFh($file,($name||"$file")) or return undef;
  }
  return $lf;
}


1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::Lexfreqs - libmoot : lexical frequencies

=head1 SYNOPSIS

  use Moot;

  ##=====================================================================
  ## Constructors etc
  $lf = Moot::Lexfreqs->new;
  $lf->clear();

  ##=====================================================================
  ## Accessors
  $lf->add_count($word,$tag,$count);
  $lf->compute_specials();

  $npairs = $lf->n_pairs;
  $ntoks  = $lf->n_tokens;

  $f = $lf->f_word($word);
  $f = $lf->f_tag($tag);
  $f = $lf->f_word_tag($word,$tag);

  $f = $lf->lookup($word);          ##-- wrapper for f_word($word)
  $f = $lf->lookup(undef,$tag);     ##-- wrapper for f_tag($tag)
  $f = $lf->lookup($word,$tag);     ##-- wrapper for f_word_tag($word,$tag)

  ##=====================================================================
  ## I/O

  $bool = $lf->loadFile($filename);
  $bool = $lf->loadFh($fh,$name);
  $lf   = $CLASS_OR_OBJECT->load($filename_or_fh, $name)

  $bool = $lf->saveFile($filename);
  $bool = $lf->saveFh($fh,$name);
  $bool = $lf->save($filename_or_fh, $name);

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


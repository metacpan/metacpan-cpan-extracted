package Moot::HMM;
use Carp;
use strict;

##======================================================================
## wrappers: config

## $hmm = $CLASS->new()
## $hmm = $CLASS->new($opts)
sub new {
  my ($that,$opts) = @_;
  my $hmm = $that->_new();
  $hmm->config($opts) if ($opts);
  return $hmm;
}

## \%opts = $hmm->config()
## \%opts = $hmm->config(\%opts)
##  + get/set HMM options
our %hmmOpts = (map {($_=>__PACKAGE__->can($_))}
		qw(verbose ndots),
		qw(save_ambiguities save_flavors save_mark_unknown),
		qw(hash_ngrams relax use_lex_classes),
		qw(start_tagid),
		qw(unknown_lex_threshhold unknown_class_threshhold),
		qw(nglambda1 nglambda2 nglambda3),
		qw(wlambda0 wlambda1),
		qw(clambda0 clambda1),
		qw(beamwd),
		qw(nsents ntokens nnewtokens nunclassed nnewclasses nunknown nfallbacks),
	       );
sub config {
  my ($hmm,$opts) = @_;
  if ($opts) {
    $hmmOpts{$_}->($hmm,$opts->{$_}) foreach (grep {$hmmOpts{$_}} keys %$opts);
  }
  return {map {($_=>$hmmOpts{$_}->($hmm))} keys %hmmOpts};
}

##======================================================================
## wrappers: I/O

BEGIN {
  *loadModel = \&load;
  *load_model = \&_load_model;
}

sub load {
  my ($that,$modelfile) = @_;
  $that = $that->new if (!ref($that));
  return undef if (!$that->_load_model($modelfile));
  return $that;
}

sub loadBin {
  my ($that,$binfile) = @_;
  $that = $that->new if (!ref($that));
  return undef if (!$that->_load($binfile));
  return $that;
}

BEGIN {
  *saveBin = \&_save;
}


1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::HMM - libmoot : HMM

=head1 SYNOPSIS

  use Moot;

  ##=====================================================================
  ## Constructors etc
 
  $hmm  = Moot::HMM->new(\%opts);
  $opts = $hmm->config(\%opts);
  $opts = $hmm->config();

  ##=====================================================================
  ## Accessors
  ##  + all of the following are get/set methods, e.g.
  ##    `$hmm->verbose()' gets the value of the 'verbose' property, and
  ##    `$hmm->verbose($i)' sets it
 
  $val = $hmm->verbose();
  $ndots = $hmm->ndots();
 
  $save_ambiguities = $hmm->save_ambiguities();
  $save_flavors = $hmm->save_flavors();
  $save_mark_unknown = $hmm->save_mark_unknown();
 
  $hash_ngrams = $hmm->hash_ngrams();
  $relax = $hmm->relax();
  $use_lex_classes = $hmm->use_lex_classes();
 
  $start_tagid = $hmm->start_tagid();
 
  $unknown_lex_threshhold = $hmm->unknown_lex_threshhold();
  $unknown_class_threshhold = $hmm->unknown_class_threshhold();
 
  $nglambda1 = $hmm->nglambda1();
  $nglambda2 = $hmm->nglambda2();
  $nglambda3 = $hmm->nglambda3();
 
  $wlambda0 = $hmm->wlambda0();
  $wlambda1 = $hmm->wlambda1();
 
  $clambda0 = $hmm->clambda0();
  $clambda1 = $hmm->clambda1();
 
  $beamwd = $hmm->beamwd();
 
  $nsents = $hmm->nsents();
  $ntokens = $hmm->ntokens();
  $nnewtokens = $hmm->nnewtokens();
  $nunclassed = $hmm->nunclassed();
  $nnewclasses = $hmm->nnewclasses();
  $nunknown = $hmm->nunknown();
  $nfallbacks = $hmm->nfallbacks();

  ##=====================================================================
  ## Low-Level Lookup
 
  $logp = $hmm->wordp($word, $tag);          ##-- log p($word|$tag)
 
  $logp = $hmm->classp(\@tagset, $tag);      ##-- log p(\@tagset|$tag)
 
  $logp = $hmm->tagp($tag1);                 ##-- log p($tag1)              : raw
  $logp = $hmm->tagp($tag1,$tag2);           ##-- log p($tag2|$tag1)        : raw
  $logp = $hmm->tagp($tag1,$tag2,$tag3);     ##-- log p($tag3|$tag1,$tag2)  : raw?

  ##=====================================================================
  ## Tagging
 
  ## sentences are tagged in-place; structure:
  @sent = (
           {text=>'This'},
           {text=>'is',    tag=>'this_will_be_overwritten'},
           {text=>'a'      tag=>'this_too'},
           {text=>'test',  analyses=>[{tag=>'N',details=>'test/N'},
                                      {tag=>'V',details=>'test/V',prob=>42}] },
           {text=>'.'      analyses=>[{tag=>'$.'}]},
          );
 
  $hmm->tag_sentence(\@sent,$utf8=1,$trace=0);  ##-- clobbers 'tag' key of each token hash
 
  $hmm->tag_io    ( $reader, $writer );         ##-- sentence-stream tagging
  $hmm->tag_stream( $reader, $writer );         ##-- token-stream tagging

  ##=====================================================================
  ## I/O
 
  $hmm = $CLASS_OR_OBJECT->load($model);
  $hmm = $CLASS_OR_OBJECT->loadBin($binfile);
 
  $bool = $hmm->saveBin($binfile, $zlevel=-1);
  undef = $hmm->txtdump($filename='-');

=head1 DESCRIPTION

The Moot module provides an object-oriented interface to the libmoot library
for Hidden Markov Model part-of-speech tagging.

=head1 SEE ALSO

Moot(3perl),
Moot::Constants(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


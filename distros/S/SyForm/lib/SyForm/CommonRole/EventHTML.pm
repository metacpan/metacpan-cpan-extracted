package SyForm::CommonRole::EventHTML;
BEGIN {
  $SyForm::CommonRole::EventHTML::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Standard role for objects with HTML event attributes
$SyForm::CommonRole::EventHTML::VERSION = '0.102';
use Moo::Role;

our @events = qw(
  afterprint
  beforeprint
  beforeunload
  error
  haschange
  load
  message
  offline
  online
  pagehide
  pageshow
  popstate
  redo
  resize
  storage
  undo
  unload

  blur
  change
  contextmenu
  focus
  formchange
  forminput
  input
  invalid
  reset
  select
  submit

  keydown
  keypress
  keyup

  click
  dblclick
  drag
  dragend
  dragenter
  dragleave
  dragover
  dragstart
  drop
  mousedown
  mousemove
  mouseout
  mouseover
  mouseup
  mousewheel
  scroll

  abort
  canplay
  canplaythrough
  durationchange
  emptied
  ended
  loadeddata
  loadedmetadata
  loadstart
  pause
  play
  playing
  progress
  ratechange
  readystatechange
  seeked
  seeking
  stalled
  suspend
  timeupdate
  volumechange
  waiting
);

our @attributes = map { 'on'.$_ } @events;

for my $attribute (@attributes) {
  has $attribute => (
    is => 'ro',
    predicate => 1,
  );
}

1;

__END__

=pod

=head1 NAME

SyForm::CommonRole::EventHTML - Standard role for objects with HTML event attributes

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

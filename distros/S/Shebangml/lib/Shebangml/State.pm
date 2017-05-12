package Shebangml::State;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

Shebangml::State - input/parser state holder

=head1 SYNOPSIS

=cut

=head2 new

  my $state = Shebangml::State->new($source, %opts);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;

  my $source = (@_ % 2) ? shift(@_) : undef;
  my %opts = @_; # TODO if I have opts, do I need to clone them?

  my $self = {%opts};

  defined($source) or croak("no source");
  unless(ref($source)) {
    my $filename = $source;
    $source = undef;
    $self->{filename} = $filename;
    open($source, '<', $filename) or croak("cannot open '$filename' $!");
  }
  else {
    unless(defined(eval{fileno($source)})) {
      my $string = $$source;
      $source = undef;
      open($source, '<', \$string) or croak("cannot refopen string $!");
    }
  }

  $self->{in_fh} = $source;
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 next

Reads another line into $state->current and returns a reference to it.

  my $CL = $state->next;

=cut

sub next {
  my $self = shift;

  defined(my $line = readline($self->{in_fh})) or return();
  # return a reference to our inner buffer
  return($self->{current} = \($self->{line} = $line));
} # end subroutine next definition
########################################################################

=head2 current

A reference to the current line.

=cut

sub current {shift(@_)->{current}}
########################################################################

=head1 Parser Bits

=head2 skip_comment

  $state->skip_comment;

=cut

sub skip_comment {
  my $self = shift;

  my $CL = $self->current;
  if($$CL =~ m/^\s*#{/) {
    while($CL = $self->next) {
      return if($$CL =~ m/^\s*#}/);
    }
  }
} # end subroutine skip_comment definition
########################################################################

=head2 skip_whitespace

  $state->skip_whitespace;

=cut

sub skip_whitespace {
  my $self = shift;

  while(my $CL = $self->next) {
    $$CL =~ s/^\s*//;
    return if(length($$CL));
  }
} # end subroutine skip_whitespace definition
########################################################################

=head2 read_literal

  my $string = $state->read_literal($tag, $cr);

=cut

sub read_literal {
  my $self = shift;
  my ($tag, $cr) = @_;

  my $out = '';
  if($cr) { # end of that line
    $out .= "\n";
    while(my $CL = $self->next) {
      if($$CL =~ s/^\s*\}\}\}(?:#([\.\w]+);)?//) {
        croak("$1 not $tag") if($1 and $1 ne $tag);
        return($out);
      }
      $out .= $$CL;
    }
    die "ASSERT: no fall-through case";
  }
  else {
    my $CL = $self->current;

    $$CL =~ s/(.*?)}}}// or croak("no end on $tag");
    $out .= $1;
    return($out);
  }

  die "ASSERT: no fall-through case";
} # end subroutine read_literal definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;

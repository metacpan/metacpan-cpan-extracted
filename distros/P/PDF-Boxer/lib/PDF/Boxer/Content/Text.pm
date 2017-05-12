package PDF::Boxer::Content::Text;
{
  $PDF::Boxer::Content::Text::VERSION = '0.004';
}
use Moose;
# ABSTRACT: a box that displays text

use namespace::autoclean;

extends 'PDF::Boxer::Content::Box';
with 'PDF::Boxer::Role::Text';

sub get_default_size{
  my ($self) = @_;
  my $space = $self->boxer->max_width;
  my ($width, $height) = $self->find_smallest_block($space);
  warn sprintf "Text %s default size: %s x %s\n", $self->name, $width, $height if $self->debug && $self->name; 
  return (int($width+1), int($height+1));
}

around 'update' => sub{
  my ($orig, $self) = @_;

  my ($width, $height) = $self->find_smallest_block($self->width);
  warn sprintf "Text %s smallest_block %s x %s\n", ($self->name, $width, $height) if $self->debug && $self->name;
  $self->set_height($height) if $self->height < $height;

  warn sprintf "Text %s child_adjusted_height? %s < %s\n", $self->name, $self->margin_bottom, $self->parent->content_bottom if $self->debug && $self->name;
  if ($self->margin_bottom < $self->parent->content_bottom){
    warn "Text child_adjusted_height\n" if $self->debug;
    $self->parent->child_adjusted_height($self);
  }
  
};

around 'render' => sub{
  my ($orig, $self) = @_;

  my $text = $self->prepare_text;

  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $self->width);

  my $longest_line_length = $self->longest_line($wrapped_lines);

  my $font = $self->get_font;

  my $x = $self->content_left;
  my $y = $self->baseline_top($font, $self->size);
  my $align_method = 'text';

  foreach($self->align || ()){
    /^rig/ && do { $x = $self->content_right; $align_method = 'text_right' };
    /^cen/ && do { $x += ($self->width/2);    $align_method = 'text_center' };
  }

  $text->translate($x,$y);
  foreach(@$wrapped_lines){
    $text->$align_method( $_ );
    $text->cr;
  }

  $self->$orig();

};




sub find_smallest_block{
  my ($self, $space) = @_;
  return if $space > 1000;
  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $space);
  my $width = $self->longest_line($wrapped_lines);
  my $height = $self->lead * scalar @$wrapped_lines;
  warn sprintf "Text %s find_smallest_block: %s x %s\n", $self->name, $width, $height if $self->debug && $self->name; 
  return ($width, $height); # if 1 - $width/($height || 1) < .2;
}

sub longest_line{
  my ($self, $lines) = @_;
  my $text = $self->prepare_text;
  my $longest_line_length = 0;
  foreach my $line (@$lines){
    my $len = $text->advancewidth($line);
    $longest_line_length = $len if $len > $longest_line_length;
  }
  return $longest_line_length;
}

sub wrapped_lines{
  my ($self, $lines, $space) = @_;
  my @wrapped_lines;
  my $text = $self->prepare_text;
  foreach my $line (@$lines){
    my $len = $text->advancewidth($line);
    if ($len > $space){
      my $wrapped_lines = $self->split_line($line, $space);
      push(@wrapped_lines, @$wrapped_lines);
    } else {
      push(@wrapped_lines, $line);
    }
  }
  return (\@wrapped_lines);
}

sub split_line{
  my ($self, $line, $width) = @_;
  my @words = ref $line ? @$line : split(/\s+/, $line);
  my @wrapped_lines;  
  my $text = $self->prepare_text;
  while (@words){
    my $new_line = shift @words;
    while (@words && $text->advancewidth($new_line.' '.$words[0]) < $width){
      last unless @words;
      $new_line .= ' ' . shift @words;
    }
    push(@wrapped_lines, $new_line);  
  }
  return \@wrapped_lines;
}


__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

PDF::Boxer::Content::Text - a box that displays text

=head1 VERSION

version 0.004

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


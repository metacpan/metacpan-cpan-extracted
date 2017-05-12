package PDF::Boxer::Role::Text;
{
  $PDF::Boxer::Role::Text::VERSION = '0.004';
}
use Moose::Role;
# ABSTRACT: methods & attributes for text boxes

has 'size' => ( isa => 'Int', is => 'ro', default => 14 );
has 'font' => ( isa => 'Str', is => 'ro', default => 'Helvetica' );
has 'font_bold' => ( isa => 'Str', is => 'ro', default => 'Helvetica-Bold' );
has 'color' => ( isa => 'Str', is => 'ro', default => 'black' );
has 'value' => ( isa => 'ArrayRef', is => 'ro' );
has 'align' => ( isa => 'Str', is => 'ro' );

has 'lead' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_lead{
  my ($self) = @_;
  return int($self->size + $self->size*$self->lead_spacing);
}

has 'lead_spacing' => ( isa => 'Num', is => 'ro', lazy_build => 1 );
sub _build_lead_spacing{
  return 20/100;
}

sub get_font{
  my ($self, $font_name) = @_;
  return $self->boxer->doc->font( $font_name || $self->font );
}

sub baseline_top{
  my ($self, $font, $size) = @_;
  my $asc = $font->ascender();
  my $desc = $font->descender();
  my $adjust_perc = $asc / (($desc < 0 ? abs($desc) : $desc) + $asc);
  my $adjust = $self->size*$adjust_perc;
  return $self->content_top - $adjust;
}

sub prepare_text{
  my ($self) = @_;
  my $text = $self->boxer->doc->text;
  my $font = $self->get_font;
  $text->font($font, $self->size);
  $text->fillcolor($self->color);
  $text->lead($self->lead);
  return $text;
}

sub dump_attr{
  my ($self) = @_;
  my @lines = (
    '== Text Attr ==',
    (sprintf 'Text: %s', "\n\t".join("\n\t", @{$self->value})),
    (sprintf 'Size: %s', $self->size || 'none'),
    (sprintf 'Color: %s', $self->color || 'none'),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

1;

__END__
=pod

=head1 NAME

PDF::Boxer::Role::Text - methods & attributes for text boxes

=head1 VERSION

version 0.004

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


package PDF::Boxer::SpecParser;
{
  $PDF::Boxer::SpecParser::VERSION = '0.004';
}
use Moose;
# ABSTRACT: Convert markup to Perl data

use namespace::autoclean;

use XML::Parser;

has 'clean_whitespace' => ( isa => 'Bool', is => 'ro', default => 1 );

has 'xml_parser' => ( isa => 'XML::Parser', is => 'ro', lazy_build => 1 );

sub _build_xml_parser{
  XML::Parser->new(Style => 'Tree');
}

sub parse{
  my ($self, $xml) = @_;
  my $data = $self->xml_parser->parse($xml);

  my $spec = {};
  $self->mangle_spec($spec, $data);
  $spec = $spec->{children}[0];

  return $spec;
}

sub mangle_spec{
  my ($self, $spec, $data) = @_;
  while(@$data){
    my $tag = shift @$data;
    my $element = shift @$data;
    if ($tag eq '0'){
# !!??
#      push(@{$spec->{value}}, $element);
    } elsif ($tag eq 'text'){
      $element->[0]{type} = 'Text';
      my $kid = shift @$element;
      $kid->{value} = [$self->clean_text($element->[1])];
      push(@{$spec->{children}}, $kid);
    } elsif ($tag eq 'textblock'){
      $element->[0]{type} = 'TextBlock';
      my $kid = shift @$element;
      $kid->{value} = [$self->clean_text($element->[1])];
      push(@{$spec->{children}}, $kid);
    } elsif (lc($tag) eq 'image'){
      $element->[0]{type} = 'Image';
      push(@{$spec->{children}}, shift @$element);
    } elsif (lc($tag) eq 'row'){
      $element->[0]{type} = 'Row';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    } elsif (lc($tag) eq 'column'){
      $element->[0]{type} = 'Column';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    } elsif (lc($tag) eq 'grid'){
      $element->[0]{type} = 'Grid';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    } elsif (lc($tag) eq 'doc'){
      $element->[0]{type} = 'Doc';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    } else {
      $element->[0]{type} = 'Box';
      push(@{$spec->{children}}, shift @$element);
      $self->mangle_spec($spec->{children}->[-1], $element);
    }
  }
}

sub clean_text{
  my ($self, $element) = @_;
  return unless $element;
  return if $element =~ /^[\s\n\r]*$/;
  if ($self->clean_whitespace){
    $element =~ s/^[\s\n\r]+//;
    $element =~ s/[\s\n\r]+$//;
  }
  my @el = split(/\n/,$element);
  if ($self->clean_whitespace){
    foreach(@el){
      s/^\s+//;
      s/\s+$//;
    }
  }
  return @el;
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

PDF::Boxer::SpecParser - Convert markup to Perl data

=head1 VERSION

version 0.004

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



package Mojo::IOLoop::LineReader;
$Mojo::IOLoop::LineReader::VERSION = '0.3';
# ABSTRACT: Non-blocking line-oriented input stream

use Mojo::Base 'Mojo::IOLoop::Stream';

use Scalar::Util ();

has 'input_record_separator';

sub new {
  my $self = shift->SUPER::new(@_);
  $self->input_record_separator($/);
  return $self->_setup;
}

sub _setup {
  my $self = shift;

  Scalar::Util::weaken($self);
  $self->on(close => sub { shift; $self->_closeln(@_) });
  $self->on(read  => sub { shift; $self->_readln(@_) });

  return $self;
}

sub _closeln {
  my ($self) = @_;
  $self->emit(readln => $self->{lr_chunk}) if length $self->{lr_chunk};
  $self->{lr_chunk} = '';
}

sub _readln {
  my ($self, $bytes) = @_;

  open my $r, '<', \$bytes;
  my $n = delete $self->{lr_chunk} // '';
  local $/ = $self->input_record_separator;
  my $i;
  while (<$r>) {
    $n .= $_, next unless $i++;
    $self->emit(readln => $n);
    $n = $_;
  }
  if (chomp(my $tmp = $n)) {
    $self->emit(readln => $n);
    $n = '';
  }
  $self->{lr_chunk} = $n;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::IOLoop::LineReader - Non-blocking line-oriented input stream

=head1 VERSION

version 0.3

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Adriano Ferreira

Adriano Ferreira <a.r.ferreira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

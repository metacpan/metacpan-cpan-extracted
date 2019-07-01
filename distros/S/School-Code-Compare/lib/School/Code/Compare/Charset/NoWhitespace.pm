package School::Code::Compare::Charset::NoWhitespace;
# ABSTRACT: trim whitespace since it's mostly irrelevant
$School::Code::Compare::Charset::NoWhitespace::VERSION = '0.101';
use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {
               };
    bless $self, $class;

    return $self;
}

sub filter {
    my $self      = shift;
    my $lines_ref = shift;

    my @no_whitespace;

    foreach my $row (@{$lines_ref}) {
      $row =~ s/\s*//g;
      next if ($row eq '');
      push @no_whitespace, $row;
    }

    return \@no_whitespace;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Charset::NoWhitespace - trim whitespace since it's mostly irrelevant

=head1 VERSION

version 0.101

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

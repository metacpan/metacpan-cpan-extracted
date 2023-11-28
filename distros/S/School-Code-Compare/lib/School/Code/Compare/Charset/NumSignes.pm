package School::Code::Compare::Charset::NumSignes;
# ABSTRACT: collapse words and numbers into abstract placeholders
$School::Code::Compare::Charset::NumSignes::VERSION = '0.201';
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
    my $self   = shift;
    my $lines_ref = shift;

    my @numsignes;

    foreach my $row (@{$lines_ref}) {

        #$row =~ s/[:alpha:]/a/g;
      $row =~ s/[[:alpha:]]+/a/g;
      $row =~ s/\d+/0/g;
      next if ($row eq '');

      push @numsignes, $row;
    }

    return \@numsignes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Charset::NumSignes - collapse words and numbers into abstract placeholders

=head1 VERSION

version 0.201

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

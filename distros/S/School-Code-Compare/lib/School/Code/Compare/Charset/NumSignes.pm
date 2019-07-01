package School::Code::Compare::Charset::NumSignes;
# ABSTRACT: trim english letters
$School::Code::Compare::Charset::NumSignes::VERSION = '0.101';
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

School::Code::Compare::Charset::NumSignes - trim english letters

=head1 VERSION

version 0.101

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

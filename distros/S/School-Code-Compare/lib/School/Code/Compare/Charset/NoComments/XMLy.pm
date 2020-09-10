package School::Code::Compare::Charset::NoComments::XMLy;
# ABSTRACT: trim comments
$School::Code::Compare::Charset::NoComments::XMLy::VERSION = '0.104';
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

    my @no_comments;

    foreach my $row (@{$lines_ref}) {
      next if ($row =~ m/^<!--/);
      $row = $1 if ($row =~ m/(.*)<!--.*/);
      $row =~ s/\s*//g;
      next if ($row eq '');

      push @no_comments, $row;
    }

    return \@no_comments;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Charset::NoComments::XMLy - trim comments

=head1 VERSION

version 0.104

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

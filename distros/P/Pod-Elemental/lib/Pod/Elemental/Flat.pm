package Pod::Elemental::Flat 0.103006;
# ABSTRACT: a content-only pod paragraph

use Moose::Role;

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod Pod::Elemental::Flat is a role that is included to indicate that a class
#pod represents a Pod paragraph that will have no children, and represents only its
#pod own content.  Generally it is used for text paragraphs.
#pod
#pod =cut

with 'Pod::Elemental::Paragraph';
excludes 'Pod::Elemental::Node';

sub as_debug_string {
  my ($self) = @_;

  my $moniker = ref $self;
  $moniker =~ s/\APod::Elemental::Element:://;

  my $summary = $self->_summarize_string($self->content);

  return "$moniker <$summary>";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Flat - a content-only pod paragraph

=head1 VERSION

version 0.103006

=head1 OVERVIEW

Pod::Elemental::Flat is a role that is included to indicate that a class
represents a Pod paragraph that will have no children, and represents only its
own content.  Generally it is used for text paragraphs.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

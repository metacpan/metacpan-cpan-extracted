package Slack::BlockKit::Types 0.003;
# ABSTRACT: Moose type constraints used internally by Slack::Block Kit
use v5.36.0;

#pod =head1 OVERVIEW
#pod
#pod This library has some types used by Slack::BlockKit.  Generally, you shouldn't
#pod need to think about them, and they're not being documented, so that they can be
#pod rejiggered whenever convenient.  You can always read the source!
#pod
#pod =cut

use MooseX::Types -declare => [qw(
  RichTextBlocks
  ExpansiveElementList
  Pixels
  RichTextArray
  RichTextStyle
  RichTextMentionStyle
)];

use MooseX::Types::Moose qw(ArrayRef Bool Int);
use MooseX::Types::Structured qw(Dict Optional);

subtype RichTextBlocks, as ArrayRef[
  union([
    map {; class_type("Slack::BlockKit::Block::RichText::$_") }
      (qw( List Quote Preformatted Section ))
  ])
];

subtype ExpansiveElementList, as ArrayRef[
  union([
    map {; class_type("Slack::BlockKit::Block::RichText::$_") }
      (qw( Channel Date Emoji Link Text User UserGroup ))
  ])
];

subtype RichTextArray, as ArrayRef[
  class_type("Slack::BlockKit::Block::RichText::Section")
];

subtype Pixels, as Int, where { $_ >= 0 },
  message { "Pixel attributes must be integers, >= 0" };

# RichListStyle - enum( ordered, bullet )

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Types - Moose type constraints used internally by Slack::Block Kit

=head1 VERSION

version 0.003

=head1 OVERVIEW

This library has some types used by Slack::BlockKit.  Generally, you shouldn't
need to think about them, and they're not being documented, so that they can be
rejiggered whenever convenient.  You can always read the source!

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

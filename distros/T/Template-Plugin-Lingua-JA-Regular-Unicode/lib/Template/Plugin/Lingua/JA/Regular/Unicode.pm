package Template::Plugin::Lingua::JA::Regular::Unicode;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Template::Plugin);
use Lingua::JA::Regular::Unicode;

sub new {
    my ( $self, $context, @args ) = @_;
    for my $method (@Lingua::JA::Regular::Unicode::EXPORT) {
        $context->define_filter( $method,
            \&{"Lingua::JA::Regular::Unicode::$method"}, 0 );
    }
    return $self;
}

1;
__END__

=encoding utf8

=head1 NAME

Template::Plugin::Lingua::JA::Regular::Unicode - TT Filter Plugin for Lingua::JA::Regular::Unicode.

=head1 SYNOPSIS

  [% USE Lingua.JA.Regular.Unicode %]
  [% 'およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ' | hiragana2katakana %] # オヨヨＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ

  [% FILTER katakana2hiragana -%]
  およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
  [% END -%]
  # およよＡＢＣＤＥＦＧｂｆｅge１２３123およよおよよ

All methods

  [% something | alnum_z2h %]
  [% something | hiragana2katakana %]
  [% something | space_z2h %]
  [% something | katakana2hiragana %]
  [% something | katakana_h2z %]
  [% something | katakana_z2h %]
  [% something | space_h2z %]

=head1 DESCRIPTION

Template::Plugin::Lingua::JA::Regular::Unicode is a TT Filter Plugin for Lingua::JA::Regular::Unicode.
See L<Lingua::JA::Regular::Unicode> for available methods.

=head1 AUTHOR

YAMAMOTO Ryuzo (dragon3) E<lt>ryuzo.yamamoto@gmail.comE<gt>

=head1 SEE ALSO

L<Lingua::JA::Regular::Unicode>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Pod::PerldocJp::ToText;

use strict;
use warnings;
use base 'Pod::Perldoc::ToText';
use Encode;
use Encode::Guess;
use Term::Encoding;

my $term_encoding = Term::Encoding::get_encoding() || 'utf-8';
my @encodings =
  split ' ', $ENV{PERLDOCJP_ENCODINGS} || 'euc-jp shiftjis utf8';

{
  no warnings 'redefine';

  sub _decode_if_necessary {
    my ($self, $text) = @_;
    return $text if Encode::is_utf8($text);
    if ($self->{encoding}) {
      return decode($self->{encoding}, $text);
    }
    my $enc = guess_encoding($text, @encodings);
    if (ref $enc && grep { $_ eq $enc->name } @encodings) {
      $self->{encoding} = $enc->name;
      return decode($self->{encoding}, $text);
    }
    return $text;
  }

  sub Pod::Text::cmd_encoding {
    my ($self, $text, $line) = @_;
    ($self->{encoding}) = $text =~ /^(\S+)/;
  }

  sub Pod::Text::preprocess_paragraph {
    my $self = shift;
    local $_ = shift;
    $_ = _decode_if_necessary($self, $_);

    1 while s/^(.*?)(\t+)/$1 . ' ' x (length ($2) * 8 - length ($1) % 8)/me;
    $self->output_code ($_) if $self->cutting;
    $_;
  }

  sub Pod::Text::wrap {
    my $self = shift;
    local $_ = shift;
    $_ = _decode_if_necessary($self, $_);

    my $output = '';
    my $spaces = ' ' x $$self{MARGIN};
    my $width = $$self{opt_width} - $$self{MARGIN};
    my $current = 0;
    my $pos = 0;
    my $length = length;
    while (--$length) {
      if (length and ord(substr($_, $pos, 1)) > 255) {
        $current++;
      }
      $current++;
      if ($current >= $width) {
        if (s/^([^\n]{$pos})//) {
          my $got = $1;
          # a long word divided in two
          if ($got =~ /[!-~]$/ and $_ =~ /^[!-~]/) {
             # if the whole line is a word (maybe a long url etc)
             # take the rest of the word from the next line
             if ($got =~ /^[!-~]+$/) {
               if (s/^([!-~]+)//) {
                 $got .= $1;
               }
             }
             # otherwise, move the word to the next line
             else {
               if ($got =~ s/([!-~]+)$//) {
                 $_ = $1 . $_;
               }
             }
          }
          s/^\s+//;
          $output .= $spaces . $got . "\n";
          $current = $pos = 0;
          $length  = length;
          # this may happen if the whole of the next line is taken
          last unless $length;
          next;
        }
        else {
          last;
        }
      }
      $pos++;
    }
    $output .= $spaces . $_;
    $output =~ s/\s+$/\n\n/;
    return $output;
  }

  sub Pod::Text::output {
    my ($self, $text) = @_;

    $text = _decode_if_necessary($self, $text);

    $text =~ tr/\240\255/ /d;
    $text = Encode::encode($term_encoding, $text, Encode::PERLQQ);
    print { $$self{output_fh} } $text;
  }
}

1;

__END__

=head1 NAME

Pod::PerldocJp::ToText

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

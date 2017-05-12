#
# $Id: TruncateByWord.pm,v 1.3 2008/06/20 06:17:12 oneroad Exp $
#
package Template::Plugin::TruncateByWord;

use strict;
use warnings;

our $VERSION = '0.11';

use Template::Plugin::Filter;
use base 'Template::Plugin::Filter';

use Encode;

our $FILTER_NAME_DEFAULT = 'truncate_by_word';
our $ORG_ENC_DEFAULT = 'utf8';

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_CONFIG}->{name}||$FILTER_NAME_DEFAULT);
    $self->{_CONFIG}->{enc} ||= $self->{_ARGS}->[0] || $ORG_ENC_DEFAULT;
    return $self;
}

sub filter {
    my($self, $string, $args, $conf) = @_;

    return '' unless $string;

    # decode
    my $org_enc;
    unless ( utf8::is_utf8($string) ) {
        $org_enc = $self->{_CONFIG}->{enc};
        $string = Encode::decode($org_enc, $string);
    }

    my $org_length = CORE::length($string);
    my $length = $args->[0] || $org_length;
    return if $length =~ /\D/;
    $string = CORE::substr($string, 0, $length);

    my $suffix = $args->[1]||'';
    # revive encode
    $string = Encode::encode($org_enc, $string) if $org_enc;
    return $org_length > $length ? $string.$suffix : $string ;
}

1;
__END__

=head1 NAME

Template::Plugin::TruncateByWord - A Template Toolkit filter to truncate not the number of bytes but characters

=head1 SYNOPSIS

  # result is 'ab'
  [% USE TruncateByWord %]
  [% 'abcdefg' | truncate_by_word(2) %]

  # result is 'abc....'
  [% USE TruncateByWord %]
  [% FILTER truncate_by_word(3,'....') %]
  abcdefg
  [% END %]

  # default charset = 'utf8'. you can change this.
  # result is 'abcd'
  [% USE TruncateByWord 'euc-jp' %]
  [% FILTER truncate_by_word(4) %]
  abcdefg
  [% END %]

=head1 DESCRIPTION

Template::Plugin::TruncateByWord is a filter plugin for Template Toolkit which truncate text not the number of bytes but the number of characters.

=head1 BUGS

If found, please Email me. I tested utf8, euc-jp, shiftjis, 7bit-jis, big5, and euc-kr. Please send me more test cases.

=head1 SEE ALSO

L<Template>, L<Template::Plugin::Filter>, and t/*.t

=head1 AUTHOR

User & KAWABATA Kazumichi (Higemaru) E<lt>kawabata@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008- KAWABATA Kazumichi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

package TX::Escape;

use 5.008008;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK=qw(html_esc url_esc url_unesc);
our %EXPORT_TAGS=(all=>[@EXPORT_OK]);

our $VERSION='0.01';

{
  my %h=(
	 '"' => '&quot;',
	 '<' => '&lt;',
	 '>' => '&gt;',
	 '&' => '&amp;',
	 ' ' => '&nbsp;',
	 "\n" => '<br />',
	);
  sub html_esc ($;$) {
    my ($s, $esc_space)=@_;
    return '' unless defined $s;
    if( $esc_space ) {
      $s=~s/([<>"& \n])/$h{$1}/ge;
    } else {
      $s=~s/([<>"&])/$h{$1}/ge;
    }
    return $s;
  }
}

sub url_esc ($) {
  my $v=shift;
  return '' unless defined $v;
  $v =~ s{([^A-Za-z0-9\-_.!~*'()/])}{sprintf("%%%02X",ord($1))}eg;
  return $v;
}

sub url_unesc ($) {
  my $v=shift;
  return '' unless defined $v;
  $v =~ s/%([0-9a-f]{2})|\+/defined $1 ? pack('H2', $1) : ' '/egi;
  return $v;
}

1;
__END__

=encoding utf8

=head1 NAME

TX::Escape - simple HTML escaping routines

=head1 SYNOPSIS

 use TX::Escape qw/:all/;
 my $escaped=url_esc( $string );
 my $plain=url_unesc( $escaped );
 print html_esc( $text, $flag );

=head1 DESCRIPTION

This module contains 3 simple functions that are often used in combination
with HTML processing.

=over 4

=item B<$escaped=url_esc $string>

returns C<$string> with all characters except of

 A .. Z, a .. z, 0 .. 9, -, _, ., !, ~, *, ', (, ) and /

replaced by their C<%HH> notation where C<HH> are 2 hexadecimal digits.

This function does not check if the string contains UTF8 characters greater
than C<\x{ff}>. If you want to escape those you first have to convert the
string into octets:

 use Encode ();
 $escaped=url_esc Encode::encode( 'utf-8', $string );

=item B<$plain=url_unesc $escaped>

This is just the reverse of C<url_esc>.

Again, if you want to process UTF8 characters you have to decode the unescaped
octet string:

 use Encode ();
 $plain=Encode::decode( 'utf-8', url_esc $escaped );

=item B<$html=html_esc $text, $flag>

This function replaces the 4 reserved characters in HTML

 ", <, >, and &

by their HTML entities

 &quot;, &lt;, &gt; and &amp;

If the optional flag parameter is true also whitespace
characters are escaped. Each space is replaced by C<&nbsp;>, newlines by
C<E<lt>br /E<gt>>.

In a future version the C<$flag> parameter is probably renamed into
C<$tabwidth> and C<html_esc> will handle C<tab> characters as well.

=back

=head1 SEE ALSO

L<TX>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

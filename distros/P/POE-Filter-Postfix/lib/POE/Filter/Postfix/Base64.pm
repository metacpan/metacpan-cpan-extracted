use strict;
use warnings;

package POE::Filter::Postfix::Base64;
our $VERSION = '0.003';


use base qw(POE::Filter::Postfix);
use MIME::Base64 qw(encode_base64 decode_base64);

sub attribute_separator  { ":" }
sub attribute_terminator { "\n" }
sub request_terminator   { "\n" }

sub encode_key   { encode_base64($_[1], '') }
sub encode_value { encode_base64($_[1], '') }

sub decode_key   { decode_base64($_[1]) }
sub decode_value { decode_base64($_[1]) }

1;

__END__
=head1 NAME

POE::Filter::Postfix::Base64

=head1 VERSION

version 0.003

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.


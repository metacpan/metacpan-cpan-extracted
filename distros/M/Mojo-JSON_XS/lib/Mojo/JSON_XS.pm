package Mojo::JSON_XS;
use strict;
use warnings;

our $VERSION = 1.011;
# From groups.google.com/forum/#!msg/mojolicious/a4jDdz-gTH0/Exs0-E1NgQEJ

use Cpanel::JSON::XS;
use Mojo::JSON;
use Mojo::Util 'monkey_patch';

my $Binary = Cpanel::JSON::XS->new->utf8;
my $Text   = Cpanel::JSON::XS->new;
$_->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed
  ->stringify_infnan->escape_slash->allow_dupkeys
  for $Binary, $Text;

monkey_patch 'Mojo::JSON', encode_json => sub { $Binary->encode(shift) };
monkey_patch 'Mojo::JSON', decode_json => sub { $Binary->decode(shift) };

monkey_patch 'Mojo::JSON', to_json   => sub { $Text->encode(shift) };
monkey_patch 'Mojo::JSON', from_json => sub { $Text->decode(shift) };

1;
__END__

=head1 NAME

Mojo::JSON_XS - Faster JSON processing for Mojolicious

=head1 SYNOPSIS

  use Mojo::JSON_XS;  # Must be earlier than Mojo::JSON
  use Mojo::JSON qw(to_json from_json ...);

=head1 DESCRIPTION

Using Mojo::JSON_XS overrides Mojo::JSON, so your JSON processing will be done
by compiled C code rather than pure perl.  L<Cpanel::JSON::XS> is a hard
dependency, so is required both at installation time and run time.

=head2 DEPRECATED

This code was merged into Mojolicious v7.87, so it only makes sense to continue
using this module if you are constrained to a Mojolicious earlier than that.

=head1 USAGE

You absolutely must C<use Mojo::JSON_XS> before anything uses C<Mojo::JSON>.

I suggest that in your top-level file (C<myapp.pl> for a lite app and
C<script/my_app> for a full app) you use this module very early in the file
(even if you do not mention any other JSON in that file).

=head1 CAVEATS

The underlying module Cpanel::JSON::XS generates slightly different results
(since it is maintaining compatibility with JSON::XS) from the results you would
get from Mojo::JSON.  Be sure to check each of the differences noted below and
consider the impact on your application.  Clearly it is no use generating the
wrong output quickly when you could have the correct output (less quickly).

The examples below show C<to_json> because it is slightly shorter, but usually
it is C<encode_json> that you will want.  Remember too that C<j> is available
(L<Mojo::JSON/FUNCTIONS>) particularly for commandline testing.

=head2 Slashes

Mojo::JSON escapes slashes when encoding (to mitigate script-injection attacks).

  perl -MMojo::JSON=to_json -E'say to_json(q{/})'
  # produces "\/"

  perl -MMojo::JSON_XS -MMojo::JSON=to_json -E'say to_json(q{/})'
  # produces "/"

and similar for C<encode_json>.

=head2 Unicode

Mojo::JSON uses uppercase for hex values when encoding

  perl -MMojo::JSON=to_json -E'say to_json(qq{\x1f})'
  # produces "\u001F"

  perl -MMojo::JSON_XS -MMojo::JSON=to_json -E'say to_json(qq{\x1f})'
  # produces "\u001f"

and similar for C<encode_json>.  Cf L<http://tools.ietf.org/html/rfc7159>.

Mojo::JSON makes special cases for security, so u2028 and u2029 are rendered in
their codepoint form.

  perl -MMojo::JSON=to_json -E'say to_json(qq{\x{2028}})'
  # produces "\u2028"

  perl -MMojo::JSON_XS -MMojo::JSON=to_json -E'say to_json(qq{\x{2028}})'
  # produces the unicode character

=head2 References

Mojo::JSON can encode references (as Boolean).

  perl -MMojo::JSON=to_json -E'$a = q{string}; say to_json(\$a)'
  # produces "true"

  perl -MMojo::JSON_XS -MMojo::JSON=to_json -E'$a = q{string}; say to_json(\$a)'
  # produces error
  # "cannot encode reference to scalar unless the scalar is 0 or 1"

=head2 Numbers

Mojo::JSON detects numbers much better.

  perl -MMojo::JSON=to_json -E'$a = 2; say to_json(["$a", $a])'
  # produces "["2",2]"

  perl -MMojo::JSON_XS -MMojo::JSON=to_json -E'$a = 2; say to_json(["$a", $a])'
  # produces "["2","2"]"

Mojo::JSON encodes inf and nan as strings.

  perl -MMojo::JSON=to_json -E'say to_json(9**9**9)'
  # produces "inf"

  perl -MMojo::JSON_XS -MMojo::JSON=to_json -E'say to_json(9**9**9)'
  # produces inf

=head2 Error Messages

The handling and format of error messages is different between the two modules,
as you would expect.

=head1 SUPPORT

Although the code is gifted by Sebastian Riedel, this is not part of the
Mojolicious distribution.  Saying that, it is likely you can find someone on the
IRC channel happy to discuss this module.  Any bugs or issues should be logged
in the specific Github account.

=head2 IRC

C<#mojo> on C<irc.perl.org>

=head2 Github Issue Tracker

L<https://github.com/niczero/mojo-jsonxs/issues>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014--17, Sebastian Riedel, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::JSON>, L<Cpanel::JSON::XS>.

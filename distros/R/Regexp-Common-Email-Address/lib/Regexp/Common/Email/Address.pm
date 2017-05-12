package Regexp::Common::Email::Address;
# $Id: Address.pm,v 1.1 2005/01/06 16:10:10 cwest Exp $
use strict;

use vars qw[$VERSION];
$VERSION = sprintf "%d.%02d", split m/\./, (qw$Revision: 1.1 $)[1];

use Regexp::Common qw[pattern];
use Email::Address;

pattern name   => [qw[Email Address]],
        create => qq[(?k:$Email::Address::mailbox)];

1;

__END__

=head1 NAME

Regexp::Common::Email::Address - Returns a pattern for Email Addresses

=head1 SYNOPSIS

  use Regexp::Common qw[Email::Address];
  use Email::Address;

  while (<>) {
      my (@found) = /($RE{Email}{Address})/g;
      my (@addrs) = map $_->address,
                        Email::Address->parse("@found");
      print "X-Addresses: ",
            join(", ", @addrs),
            "\n";
  }

=head1 DESCRIPTION

=head2 C<$RE{Email}{Address}>

Provides a regex to match email addresses as defined by RFC 2822. Under
C<{-keep}>, the entire match is kept as C<$1>. If you want to parse that
further then pass it to C<< Email::Address->parse() >>. Don't worry,
it's fast.

=head1 SEE ALSO

L<Email::Address>,
L<Regexp::Common>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

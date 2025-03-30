package WithUTF8;
use strict;
use warnings;
use utf8;

sub latin { "welp" }
sub kroužek { "guff" }
sub tečka { "jrolp" }

my $foo = kroužek();

1;
__END__

=encoding UTF-8

=head1 METHODS

=head2 latin

=head2 kroužek

=head2 tečka

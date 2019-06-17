package OpenTracing::Common;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

=encoding utf8

=head1 NAME

OpenTracing::Common - provides common logic between OpenTracing classes

=head1 DESCRIPTION

No user-serviceable parts inside.

=cut

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.


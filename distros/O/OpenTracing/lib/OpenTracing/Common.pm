package OpenTracing::Common;

use strict;
use warnings;

our $VERSION = '1.006'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Common - provides common logic between OpenTracing classes

=head1 DESCRIPTION

No user-serviceable parts inside. Currently just provides a standard constructor.

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

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.


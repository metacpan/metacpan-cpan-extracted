package Myriad::Util::Secret;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=head1 Name

Myriad::Util::Secret - To protect secrets from getting exposed accidentally.

=head1 SYNOPSIS

    my $secret = Myriad::Util::Secret->new('shh.. secret!');

=head1 DESCRIPTION

Override the actual string value with "***"

=cut

use overload
    q{""} => sub { "***" },
    fallback => 1;

sub new {
    my $class = shift;
    bless \(my $str = shift), $class
}

sub secret_value {
    my ($self) = @_;
    $$self
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.


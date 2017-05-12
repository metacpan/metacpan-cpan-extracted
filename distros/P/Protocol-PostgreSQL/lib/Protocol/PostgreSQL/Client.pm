package Protocol::PostgreSQL::Client;
BEGIN {
  $Protocol::PostgreSQL::Client::VERSION = '0.008';
}
use strict;
use warnings;
use parent q{Protocol::PostgreSQL};

=head1 NAME

Protocol::PostgreSQL::Client - support for the PostgreSQL wire protocol

=head1 VERSION

version 0.008

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

1;

__END__

=head1 SEE ALSO

L<DBD::Pg>, which uses the official library and has had far more testing.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2011. Licensed under the same terms as Perl itself.

package Tapper::Reports::Web::Model::TestrunDB;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Model::TestrunDB::VERSION = '5.0.14';
use strict;
use warnings;

use Tapper::Config;

use parent 'Tapper::Reports::Web::Model';

__PACKAGE__->config(
                    schema_class => 'Tapper::Schema::TestrunDB',
                    connect_info => [
                                     Tapper::Config->subconfig->{database}{TestrunDB}{dsn},
                                     Tapper::Config->subconfig->{database}{TestrunDB}{username},
                                     Tapper::Config->subconfig->{database}{TestrunDB}{password},
                                    ],
                   );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Model::TestrunDB

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Tapper::Schema::TestrunDB>

=head1 NAME

Tapper::Reports::Web::Model::TestrunDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Tapper::Reports::Web>

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

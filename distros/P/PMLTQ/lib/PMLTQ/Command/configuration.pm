package PMLTQ::Command::configuration;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::configuration::VERSION = '1.4.0';
# ABSTRACT: GET current configuration

use PMLTQ::Base 'PMLTQ::Command';
use JSON;
use YAML::Tiny;
use Hash::Merge 'merge';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my $config = $self->config;
  print YAML::Tiny->new( $config)->write_string;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Command::configuration - GET current configuration

=head1 VERSION

version 1.4.0

=head1 SYNOPSIS

  pmltq configuration

=head1 DESCRIPTION

Returns current configuration in yaml format (a merge of defaults, config file and command line options)

=head1 OPTIONS

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

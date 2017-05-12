use v5.14.0;
use warnings;

package OS::Package::Log;

use File::ShareDir qw(dist_file);
use base qw(Exporter);
use Log::Log4perl;

# ABSTRACT: Load OS::Package LOGGER object.
our $VERSION = '0.2.7'; # VERSION

our @EXPORT = qw( $LOGGER );

Log::Log4perl::init_once( dist_file( 'OS-Package', 'log.conf' ) );

our $LOGGER = Log::Log4perl->get_logger('ospkg');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Log - Load OS::Package LOGGER object.

=head1 VERSION

version 0.2.7

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

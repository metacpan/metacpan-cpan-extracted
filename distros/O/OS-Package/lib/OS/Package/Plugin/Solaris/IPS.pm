use v5.14.0;
use warnings;

package OS::Package::Plugin::Solaris::IPS;

# ABSTRACT: Solaris 11 package plugin.
our $VERSION = '0.2.7'; # VERSION

use Moo;

extends 'OS::Package';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Plugin::Solaris::IPS - Solaris 11 package plugin.

=head1 VERSION

version 0.2.7

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

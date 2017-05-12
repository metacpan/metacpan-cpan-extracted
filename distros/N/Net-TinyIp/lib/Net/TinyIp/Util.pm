package Net::TinyIp::Util;
use strict;
use warnings;
use Carp qw( carp );

sub import_methods { ( ) }

sub import {
    my $class  = shift;
    my $target = caller;

    for my $method ( $class->import_methods) {
        my $sub = $class->can( $method );

        unless ( $sub ) {
            carp "No $method in $class";
            next;
        }

        no strict "refs";
        *{ "${target}::$method" } = $sub;
    }
}

1;
__END__

=head1 NAME

Net::TinyIp::Util - a base class of util methods importer

=head1 SYNOPSIS

  package Net::TinyIp::Util::NewWithNoCheck;
  use base "Net::TinyIp::Util";
  sub import_methods { "new_with_no_check" }
  sub new_with_no_check { bless { splice @_, 1 }, shift }

  package main;
  use Net::TinyIp;
  my $ip = Net::TinyIp->new_with_no_check( foo => "foo" );

=head1 DESCRIPTION

Net::TinyIp::Util is a base class which importing util methods.

=head1 AUTHOR

kuniyoshi E<lt>kuniyoshi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package Scope::Container;

use strict;
use warnings;
use 5.008_001;
use Carp qw//;
use base qw/Exporter/;

our $VERSION = '0.04';
our @EXPORT = qw/start_scope_container scope_container in_scope_container/;

my $CONTEXT;
my $C = 0;

sub start_scope_container {
    my %args = @_;
    my $old;
    if ( defined $CONTEXT and !$args{-clear} ) {
        $old = $CONTEXT;
        $CONTEXT = { map { $_ => $old->{$_} } keys %$old };
    }
    else {
        $CONTEXT = {};
    }

    return bless { c => $C++, old => $old }, __PACKAGE__;
}

sub DESTROY {
    my($self) = @_;
    if ( $self->{c} != --$C ) {
        Carp::carp("nested scope_container found, remove all data");
        undef $CONTEXT;
    }
    else {
        $CONTEXT = $self->{old};
    }
    return;
}

sub in_scope_container {
    defined $CONTEXT;
}

sub scope_container {
    my $key = shift;
    die "undefined key" if ! defined $key;
    if ( ! defined $CONTEXT ) {
        Carp::carp("scope_container is not initilized");
        return;
    }
    if ( @_ ) {
        return $CONTEXT->{$key} = shift;
    }
    return if ! exists $CONTEXT->{$key};
    $CONTEXT->{$key};
}

1;
__END__

=head1 NAME

Scope::Container - scope based container

=head1 SYNOPSIS

  use Scope::Container;

  sub getdb {
      if ( my $dbh = scope_container('db') ) {
          return $dbh;
      } else {
          my $dbh = DBI->connect(...);
          scope_container('db', $dbh)
          return $dbh;
      }
  }

  for (1..3) {
    my $contaier = start_scope_container();
    getdb(); # do connect
    getdb(); # from container
    getdb(); # from container
    # $container scope out and disconnect from db
  }

  getdb(); # do connect

=head1 DESCRIPTION

Scope::Container is scope based container for temporary items and Database Connections.

=head1 EXPORTED FUNCTION

=over 4

=item my $scope_container = start_scope_container([-clear => 1]);

Initializing container. The default behavior is inherited all the previous container's data.
If set -clear arguments, save previous container's data and create new data.

return values is Scope::Container object. if this object scope exits, current container will be removed, return to the previous state.

=item my $value = scope_container($key:Str[,$val:Any]);

getter, setter of container data.

=item in_scope_container

Check if context is initialized

=back

=head1 LIMITATION

There is a limit to the order in which the Scope::Container object is deleted. 
If race condition found, remove all data. 

  my $sc = start_scope_container();
  scope_container('bar', 'foo');
  my $sc2 = start_scope_container();
  scope_container('bar', 'baz');

  undef $sc;
  scope_container('bar'); #null


=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

Fuji, Goro (gfx)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

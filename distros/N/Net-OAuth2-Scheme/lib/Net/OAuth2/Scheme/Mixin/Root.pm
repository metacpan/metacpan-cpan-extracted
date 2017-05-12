use warnings;
use strict;

package Net::OAuth2::Scheme::Mixin::Root;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::Root::VERSION = '0.03';
}
# ABSTRACT: defines the root group setup

use Net::OAuth2::Scheme::Option::Defines;

Define_Group(root => 'setup');

my %defined_usage = map {$_,1} qw(
  access
  refresh
  authcode
);

my %defined_context = map {$_,1} qw(
  client
  auth_server
  resource_server
);

sub is_access { return $_[0]->uses('is_access'); }

# sub is_client ...
# sub is_auth_server ...
# sub is_resource_server ...
{
    no strict 'refs';
    for my $whatever (keys %defined_context) {
        *{"is_${whatever}"} = sub () {
            # assume not if we have not otherwise said so.
            return $_[0]->uses("is_$whatever", 0);
        };
    }
}

sub pkg_root_setup {
    my __PACKAGE__ $self = shift;

    my $usage = $self->uses(usage => 'access');
    $self->croak("unknown usage '$usage'")
      unless $defined_usage{$usage};
    my $is_access = $self->ensure("is_access", $usage eq 'access');

    my $context = $self->uses(context => ($is_access ? () : ([])));
    for my $c (ref($context) ? @$context : ($context)) {
        $self->croak("unknown implementation context '$c'")
          unless $defined_context{$c};
        $self->ensure("is_$c", 1);
    }
    unless ($is_access) {
        $self->ensure(format_no_params => 1);
        $self->ensure(is_client => 0, 'client implementations do not need refresh-token/authcode schemes');
        $self->ensure(is_auth_server => 1);
        $self->ensure(is_resource_server => 1);
    }
    $self->export
      (
       (!$self->is_client ? ()
        : (
           'token_accept',
           ($is_access ? ('http_insert') : ()),
          )),
       (!$self->is_resource_server ? ()
        : (
           ($is_access ? ('psgi_extract') : ()),
           'token_validate',
          )),
       (!$self->is_auth_server ? ()
        : (
           'token_create'
          )),
      );

    $self->install(root => 'done');
    return $self;
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::Root - defines the root group setup

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an internal module that defines implementation contexts.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


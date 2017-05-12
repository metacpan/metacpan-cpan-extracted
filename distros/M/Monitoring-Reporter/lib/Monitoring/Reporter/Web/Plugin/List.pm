package Monitoring::Reporter::Web::Plugin::List;
{
  $Monitoring::Reporter::Web::Plugin::List::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Web::Plugin::List::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: List all active triggers

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use Template;

# extends ...
extends 'Monitoring::Reporter::Web::Plugin';
# has ...
# with ...
# initializers ...
sub _init_fields { return [qw(limit offset refresh)]; }

sub _init_alias { return 'list_triggers'; }

# your code here ...
sub execute {
    my $self = shift;
    my $request = shift;

    my $triggers = $self->mr()->triggers();
    my $refresh  = $request->{'refresh'} || 30;

    my $body;
    $self->tt()->process(
        'list_triggers.tpl',
        {
            'triggers' => $triggers,
            'refresh'  => $refresh,
        },
        \$body,
    ) or $self->logger()->log( message => 'TT error: '.$self->tt()->error, level => 'warning', );

    return [ 200, [
      'Content-Type', 'text/html',
      'Cache-Control', 'max-age='.($refresh-1).', private',
    ], [$body] ];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Web::Plugin::List - List all active triggers

=head1 METHODS

=head2 execute

List all active triggers.

=head1 NAME

Monitoring::Reporter::Web::API::Plugin::List - List all active triggers

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

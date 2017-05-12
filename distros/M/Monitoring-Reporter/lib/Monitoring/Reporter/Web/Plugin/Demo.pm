package Monitoring::Reporter::Web::Plugin::Demo;
{
  $Monitoring::Reporter::Web::Plugin::Demo::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Web::Plugin::Demo::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: List a set of demo triggers to showcase the interfaces and tweak the UI

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
sub _init_fields { return [qw(refresh acked allgood)]; }

sub _init_alias { return 'demo_triggers'; }

# your code here ...
sub execute {
    my $self = shift;
    my $request = shift;

    my $triggers = [
      {
         'severity'     => 'disaster',
         'host'         => 'samplehost.example.org',
         'description'  => 'DNS Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a nameserver which is unreachable',
      },
      {
         'severity'     => 'high',
         'host'         => 'samplehost.example.org',
         'description'  => 'Webserver Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
      },
      {
         'severity'     => 'average',
         'host'         => 'samplehost.example.org',
         'description'  => 'Webserver Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
      },
      {
         'severity'     => 'warning',
         'host'         => 'samplehost.example.org',
         'description'  => 'HDD almost full',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a HDD which is almost full',
      },
      {
         'severity'     => 'information',
         'host'         => 'samplehost.example.org',
         'description'  => '/etc/passwd was just changed',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
      },
      {
         'severity'     => 'nc',
         'host'         => 'samplehost.example.org',
         'description'  => 'Webserver Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
      },
   ];
   my $triggers_acked = [
      {
         'severity'     => 'disaster',
         'host'         => 'samplehost.example.org',
         'description'  => 'DNS Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a nameserver which is unreachable',
         'acknowledged' => 1,
      },
      {
         'severity'     => 'high',
         'host'         => 'samplehost.example.org',
         'description'  => 'Webserver Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
         'acknowledged' => 1,
      },
      {
         'severity'     => 'average',
         'host'         => 'samplehost.example.org',
         'description'  => 'Webserver Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
         'acknowledged' => 1,
      },
      {
         'severity'     => 'warning',
         'host'         => 'samplehost.example.org',
         'description'  => 'HDD almost full',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a HDD which is almost full',
         'acknowledged' => 1,
      },
      {
         'severity'     => 'information',
         'host'         => 'samplehost.example.org',
         'description'  => '/etc/passwd was just changed',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
         'acknowledged' => 1,
      },
      {
         'severity'     => 'nc',
         'host'         => 'samplehost.example.org',
         'description'  => 'Webserver Down',
         'lastchange'   => '1368300364',
         'comments'     => 'This shows a webserver which is unreachable',
         'acknowledged' => 1,
      },
    ];
    my $refresh  = $request->{'refresh'} || 30;

    # include acked triggers
    if($request->{'acked'}) {
      @{$triggers} = (@{$triggers},@{$triggers_acked});
    }

    # show OK sign
    if($request->{'allgood'}) {
      $triggers = [];
    }

    my $body;
    $self->tt()->process(
        'list_triggers.tpl',
        {
            'triggers' => $triggers,
            'refresh'  => $refresh,
        },
        \$body,
    ) or $self->logger()->log( message => 'TT error: '.$self->tt()->error, level => 'warning', );

    return [ 200, [ 'Content-Type', 'text/html' ], [$body] ];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Web::Plugin::Demo - List a set of demo triggers to showcase the interfaces and tweak the UI

=head1 METHODS

=head2 execute

List a set of fake triggers.

=head1 demo

        <div class="trigger [% trigger.severity %]">
            <div class="field severity">[% trigger.severity | ucfirst %]</div>
            <div class="field icon">
                [% IF trigger.acked %]
                <embed src="img/checkbox_yes.svg" type="image/svg+xml" width="20" height="20" />
                [% ELSE %]
                <embed src="img/checkbox_no.svg" type="image/svg+xml" width="20" height="20" />
                [% END %]
            </div>
            <div class="field host">[% trigger.host %]</div>
            <div class="field name">[% trigger.description %]</div>
            <div class="field time">since [% trigger.lastchange | localtime %]</div>
            <div class="field button"><!-- placeholder for details button --></div>
            <div class="clear"></div>
            <div class="details">[% trigger.comments %]</div>
        </div>

=head1 NAME

Monitoring::Reporter::Web::API::Plugin::Demo - List a set of fake triggers

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Plack::Middleware::Debug::CatalystStash;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

use Catalyst;

use Class::Method::Modifiers qw(install_modifier);
use Data::Dumper;
use HTML::Entities qw/encode_entities_numeric/;

our $VERSION = '1.000000';

install_modifier 'Catalyst', 'before', 'finalize' => sub {
    my $c = shift;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Deparse = 1;
    $c->req->env->{'plack.middleware.catalyst_stash'} =
        encode_entities_numeric( Dumper( $c->stash ) );
};

sub run {
    my($self, $env, $panel) = @_;

    return sub {
        my $res = shift;

        my $stash = delete $env->{'plack.middleware.catalyst_stash'} || 'No Stash';
        $panel->content("<pre>$stash</pre>");
    };
}

=head1 NAME

Plack::Middleware::Debug::CatalystStash - Debug panel to inspect the Catalyst Stash

=head1 SYNOPSIS

  builder {
      enable "Debug";
      enable "Debug::CatalystStash";
      sub { MyApp->run(@_) };
  };

=head1 DESCRIPTION

This debug panel displays the stash content from Catalyst applications.

=head1 AUTHOR

Mark Ellis E<lt>markellis@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=head1 LICENSE

Copyright 2014 Mark Ellis E<lt>markellis@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

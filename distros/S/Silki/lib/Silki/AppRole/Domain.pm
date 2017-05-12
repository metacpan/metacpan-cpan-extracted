package Silki::AppRole::Domain;
{
  $Silki::AppRole::Domain::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema::Domain;

use Moose::Role;

has 'domain' => (
    is      => 'ro',
    isa     => 'Silki::Schema::Domain',
    lazy    => 1,
    builder => '_build_domain',
);

sub _build_domain {
    my $self = shift;

    my $host = $self->request()->uri()->host();

    my $domain = Silki::Schema::Domain->new( web_hostname => $host )
        or die "No domain found for hostname ($host)\n";

    return $domain;
}

1;

# ABSTRACT: Adds $c->domain() to the Catalyst object

__END__
=pod

=head1 NAME

Silki::AppRole::Domain - Adds $c->domain() to the Catalyst object

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut


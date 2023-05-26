#! /usr/bin/perl -w
use strict;
use lib '../lib', './lib';
use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

{
    package MetaCPAN::Client;
    use Moo;
    with 'MooX::Role::REST';
    1;
}

{
    package MetaCPAN::API;
    use Moo;
    use Types::Standard qw( InstanceOf );
    has client => (
        is       => 'ro',
        isa      => InstanceOf(['MetaCPAN::Client']),
        handles  => [qw< call >],
        required => 1,
    );

    sub fetch_release {
        my $self = shift;
        my ($query) = @_;
        return $self->call(GET => 'release/_search', $query);
    }
    1;
}

package main;
use MetaCPAN::Client;
use MetaCPAN::API;

{ no warnings 'once'; $MooX::Role::REST::DEBUG = 1; }
my $client = MetaCPAN::Client->new(
    base_uri => 'https://fastapi.metacpan.org/v1/',
);
my $api = MetaCPAN::API->new(client => $client);

if (! @ARGV) {
    print "usage: $0 module-name[ ...]\n";
}
for my $module (@ARGV) {
    (my $query = $module) =~ s{ :: }{-}xg;
    my $response = $api->fetch_release({q => $query});
    print Dumper($response->{hits}{hits}[0]);
}

package Search::Elasticsearch::Client::6_0::Direct::XPack::Monitoring;
$Search::Elasticsearch::Client::6_0::Direct::XPack::Monitoring::VERSION = '6.81';
use Moo;
with 'Search::Elasticsearch::Client::6_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('xpack.monitoring');

1;

# ABSTRACT: Plugin providing Monitoring for Search::Elasticsearch 6.x

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::6_0::Direct::XPack::Monitoring - Plugin providing Monitoring for Search::Elasticsearch 6.x

=head1 VERSION

version 6.81

=head1 SYNOPSIS

    my $response = $es->xpack->monitoring( body => {...} )

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

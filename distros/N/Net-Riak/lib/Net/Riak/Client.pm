package Net::Riak::Client;
{
  $Net::Riak::Client::VERSION = '0.1702';
}

use Moose;
use MIME::Base64;

with 'MooseX::Traits';

has prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => 'riak'
);
has mapred_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => 'mapred'
);
has search_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => 'solr'
);
has [qw/r w dw/] => (
    is      => 'rw',
    isa     => 'Int',
    default => 2
);
has client_id => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_client_id {
    "perl_net_riak" . encode_base64(int(rand(10737411824)), '');
}


1;

__END__

=pod

=head1 NAME

Net::Riak::Client

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

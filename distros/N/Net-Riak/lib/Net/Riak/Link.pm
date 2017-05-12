package Net::Riak::Link;
{
  $Net::Riak::Link::VERSION = '0.1702';
}

# ABSTRACT: the riaklink object represents a link from one Riak object to another

use Moose;

with 'Net::Riak::Role::Base' => {classes =>
      [{name => 'client', required => 0}, {name => 'bucket', required => 1},]};

has key => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '_',
);
has tag => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {(shift)->bucket->name}
);

1;

__END__

=pod

=head1 NAME

Net::Riak::Link - the riaklink object represents a link from one Riak object to another

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

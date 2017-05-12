package Net::Riak::Transport::REST;
{
  $Net::Riak::Transport::REST::VERSION = '0.1702';
}

use Moose::Role;

with qw/
  Net::Riak::Role::UserAgent
  Net::Riak::Role::REST
  Net::Riak::Role::Hosts
  /;

1;

__END__

=pod

=head1 NAME

Net::Riak::Transport::REST

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

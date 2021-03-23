package Search::Typesense::Role::UserAgentInterface;

use v5.16.0;
use Moo::Role;

use Search::Typesense::Types qw(
  InstanceOf
);

our $VERSION = '0.06';

sub _ua;
has _ua => (
    is       => 'lazy',
    isa      => InstanceOf ['Mojo::UserAgent'],
    weak_ref => 1,
    init_arg => 'user_agent',
    required => 1,
);

sub _url_base;
has _url_base => (
    is       => 'lazy',
    isa      => InstanceOf ['Mojo::URL'],
    weak_ref => 1,
    init_arg => 'url',
    required => 1,
);

1;

__END__

=head1 NAME

Search::Typesense::Role::UserAgentInterface - No user-serviceable parts inside

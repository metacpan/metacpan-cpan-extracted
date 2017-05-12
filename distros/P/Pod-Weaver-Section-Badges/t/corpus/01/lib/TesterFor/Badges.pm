use 5.10.1;
use strict;
use warnings;

# VERSION
# ABSTRACT: A tester

package TesterFor::Badges;

use Moose;
use Types::Standard qw/HashRef Str/;
with 'Pod::Weaver::Section::Badges::Utils';

has badge_args => (
    is => 'ro',
    isa => HashRef[Str],
    default => sub { +{} },
    traits => ['Hash'],
    handles => {
        badge_args_kv => 'kv',
    },
);

1;

__END__

=pod

=head1 ATTRIBUTES

Some attributes.

=cut

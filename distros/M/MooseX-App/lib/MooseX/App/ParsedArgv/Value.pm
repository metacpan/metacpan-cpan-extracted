# ============================================================================
package MooseX::App::ParsedArgv::Value;
# ============================================================================

use 5.010;
use utf8;

use Moose;

has 'raw' => (
    is              => 'ro',
    isa             => 'Str',
    predicate       => 'has_raw',
);

has 'value' => (
    is              => 'ro',
    required        => 1,
);

has 'position' => (
    is              => 'ro',
    isa             => 'Int',
    default         => 999,
);

__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 NAME

MooseX::App::ParsedArgv::Value - Parsed value from @ARGV

=head1 DESCRIPTION

Every instance of this class represents a value from @ARGV

=head1 METHODS

=head2 key

Parameter value or option key

=head2 value

Scalar value

=head2 raw

Raw value as supplied by the user

=cut
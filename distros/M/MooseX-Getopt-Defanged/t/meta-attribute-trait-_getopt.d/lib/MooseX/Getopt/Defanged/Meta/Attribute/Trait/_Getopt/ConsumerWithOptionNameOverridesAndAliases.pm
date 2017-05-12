package MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithOptionNameOverridesAndAliases;

use 5.010;
use utf8;

use Moose;

use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';

has option_with_name_override => (
    traits      => [ qw< MooseX::Getopt::Defanged::Option > ],
    is          => 'rw',
    isa         => 'Str',
    getopt_name => 'foo',
);

has option_with_aliases => (
    traits          => [ qw< MooseX::Getopt::Defanged::Option > ],
    is              => 'rw',
    isa             => 'Str',
    getopt_aliases  => [ qw< eat a car > ],
);

has option_with_name_override_and_aliases => (
    traits          => [ qw< MooseX::Getopt::Defanged::Option > ],
    is              => 'rw',
    isa             => 'Str',
    getopt_name     => 'foo',
    getopt_aliases  => [ qw< eat a car > ],
);

no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=encoding utf8

=head1 NAME

MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerWithOptionNameOverridesAndAliases - Consumer of L<MooseX::Getopt::Defanged> role that has attributes with alternate option names and with aliases.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :

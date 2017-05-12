package MooseX::Getopt::Defanged::ConsumerWithGetoptRequiredAttributes;

use 5.010;
use utf8;

use Moose;
use MooseX::Accessors::ReadWritePrivate;


use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';


has without_default => (
    traits          => [ qw< MooseX::Getopt::Defanged::Option > ],
    is              => 'rw',
    isa             => 'Str',
    getopt_required => 1,
);

# Whether an attribute has a default value or not should not change the fact
# that a value has got to be specified.
has with_default => (
    traits          => [ qw< MooseX::Getopt::Defanged::Option > ],
    is              => 'rw',
    isa             => 'Str',
    default         => '<default>',
    getopt_required => 1,
);


no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=encoding utf8

=head1 NAME

MooseX::Getopt::Defanged::ConsumerWithGetoptRequiredAttributes - Consumer of L<MooseX::Getopt::Defanged> role that has attributes with the C<getopt_required> option set.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :

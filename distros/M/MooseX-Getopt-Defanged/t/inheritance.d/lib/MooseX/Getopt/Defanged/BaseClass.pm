package MooseX::Getopt::Defanged::BaseClass;

use 5.010;
use utf8;

use Moose;

use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';

has test3 => (
    traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
    is      => 'ro',
    isa     => 'Str',
);

has test4 => (
    traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
    is      => 'ro',
    isa     => 'Str',
);


no Moose;

__PACKAGE__->meta()->make_immutable();


1;

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :

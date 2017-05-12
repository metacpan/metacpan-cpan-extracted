package MooseX::Getopt::Defanged::MinimalConsumer;

use 5.010;
use utf8;

use Moose;

use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';


no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=encoding utf8

=head1 NAME

MooseX::Getopt::Defanged::MinimalConsumer - Minimal consumer of the L<MooseX::Getopt::Defanged> role used for testing.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :

package MooseX::Getopt::Defanged::ConsumerWithRegexpRefAttributes;

use 5.010;
use utf8;

use Moose;
use MooseX::Accessors::ReadWritePrivate;


use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';


has regex_default => (
    traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
    is                      => 'rw',
    isa                     => 'RegexpRef',
);

foreach my $modifier ( qw< m s i x p > ) {
    has "regex_$modifier" => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'RegexpRef',
        getopt_regex_modifiers  => [ $modifier ],
    );
} # end if

has regex_no_modifiers => (
    traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
    is                      => 'rw',
    isa                     => 'RegexpRef',
    getopt_regex_modifiers  => [ ],
);


no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=encoding utf8

=head1 NAME

MooseX::Getopt::Defanged::ConsumerWithRegexpRefAttributes - Consumer of L<MooseX::Getopt::Defanged> role that has C<RegexpRef> attributes.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :

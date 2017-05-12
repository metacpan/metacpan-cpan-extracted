package MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerOfAllTypesWithDefaults;

use 5.010;
use utf8;

use Moose;


use version; our $VERSION = qv('v1.18.0');


with 'MooseX::Getopt::Defanged';

foreach my $type (
    qw<
        Bool
        Str
        Int
        Num
        RegexpRef
        ArrayRef
        ArrayRef[Str]
        ArrayRef[Int]
        ArrayRef[Num]
        HashRef
        HashRef[Str]
        HashRef[Int]
        HashRef[Num]
    >
) {
    my $attribute_name = lc $type;
    $attribute_name =~ s/ \[ /_/xms;
    $attribute_name =~ s/ \] //xms;

    has $attribute_name => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => $type,
    );

    has "maybe_$attribute_name" => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => "Maybe[$type]",
    );
} # end foreach

no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=encoding utf8

=head1 NAME

MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::ConsumerOfAllTypesWithDefaults - Consumer of L<MooseX::Getopt::Defanged> role that has an attribute of each supported type with no overrides of the default values.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :

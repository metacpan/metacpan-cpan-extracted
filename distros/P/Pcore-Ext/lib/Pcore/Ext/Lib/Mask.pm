package Pcore::Ext::Lib::Mask;

use Pcore;

# view.mask({ xtype: "$type{'/pcore/Mask/loading'}" });
sub EXT_loading : Extend('Ext.Mask') : Type('widget') {
    return {
        transparent => \0,
        html        => qq[<img src="@{[ $cdn->('/static/loader4.gif') ]}" width="100"/>],
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Mask

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

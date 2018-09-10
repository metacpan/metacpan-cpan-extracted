package Pcore::Ext::Base;

use Pcore;

sub MODIFY_CODE_ATTRIBUTES ( $pkg, $ref, @attrs ) {
    my @bad;

    for my $attr (@attrs) {
        if ( $attr =~ /(Define|Ext|Extend|Override|Type) [(] (?:'(.+?)')? [)]/smxx ) {
            my ( $attr, $val ) = ( $1, $2 );

            ${"$pkg\::_EXT_MAP"}->{$ref}->{ lc $attr } = $val;
        }
        else {
            push @bad, $attr;
        }
    }

    return @bad;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Base

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

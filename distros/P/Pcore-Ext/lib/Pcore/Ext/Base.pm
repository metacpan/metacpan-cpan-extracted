package Pcore::Ext::Base;

use Pcore -const;

sub MODIFY_CODE_ATTRIBUTES ( $pkg, $ref, @attrs ) {
    my ( $sub, $extend, @bad );

    for my $attr (@attrs) {
        if ( $attr =~ /Extend [(] (?:'(.+?)')? [)]/smxx ) {
            $extend = $1;

            no strict qw[refs];

            for my $sym ( values %{"$pkg\::"} ) {
                if ( *{$sym}{CODE} && *{$sym}{CODE} == $ref ) {
                    $sub = *{$sym}{NAME};

                    if ( $sub =~ s/\AEXT_//sm ) {
                        ${"$pkg\::_EXT_MAP"}->{$sub} = $extend;
                    }
                    else {
                        push @bad, $attr;
                    }

                    last;
                }
            }
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

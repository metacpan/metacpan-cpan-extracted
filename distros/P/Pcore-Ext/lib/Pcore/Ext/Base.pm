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

                        # extend is not defined, this is a singleton
                        if ( !defined $extend ) {
                            ${"$pkg\::_EXT_MAP"}->{$sub} = undef;
                        }
                        else {
                            my $extend_class;

                            # type
                            if ( $extend =~ /\A[[:lower:].]+\z/sm ) {
                                if ( index( $extend, '.' ) == -1 ) {
                                    if ( exists $Pcore::Ext::EXT->{'classic'}->{alias_class}->{"widget.$extend"} ) {
                                        $extend_class = $Pcore::Ext::EXT->{$Pcore::Ext::EXT_FRAMEWORK}->{alias_class}->{"widget.$extend"};
                                    }
                                }
                                elsif ( exists $Pcore::Ext::EXT->{'classic'}->{alias_class}->{$extend} ) {
                                    $extend_class = $Pcore::Ext::EXT->{$Pcore::Ext::EXT_FRAMEWORK}->{alias_class}->{$extend};
                                }
                            }

                            # ExtJS class name
                            else {
                                $extend_class = $extend;
                            }

                            if ($extend_class) {
                                ${"$pkg\::_EXT_MAP"}->{$sub} = $extend_class;
                            }
                            else {
                                die qq[ExtJS extend attribute "$extend" can't be resolved for sub "$pkg\::$sub"];
                            }
                        }
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
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 21, 28, 29, 30, 44   | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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

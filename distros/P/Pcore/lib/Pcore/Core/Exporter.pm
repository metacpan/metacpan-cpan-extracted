package Pcore::Core::Exporter;

use common::header;

our $EXPORT_PRAGMA = {    #
    export => 1,
};

our $CACHE;

sub import {
    my $self = shift;

    # parse tags and pragmas
    my $import = parse_import( $self, @_ );

    # find caller
    my $caller = $import->{pragma}->{caller} // caller( $import->{pragma}->{level} // 0 );

    # process -export pragma
    if ( !exists $CACHE->{$caller} ) {
        $import->{pragma}->{export} = { ALL => $import->{pragma}->{export} } if ref $import->{pragma}->{export} eq 'ARRAY';

        my $tags;    # 0 - processing, 1 - done

        my $process_tag = sub ($tag) {

            # tag is already processed
            return if $tags->{$tag};

            die qq[Cyclic reference found whils processing export tag "$tag"] if exists $tags->{$tag} && !$tags->{$tag};

            $tags->{$tag} = 0;

            for ( $import->{pragma}->{export}->{$tag}->@* ) {
                my $sym = $_;

                my $type = $sym =~ s/\A([:&\$@%*])//sm ? $1 : q[];

                if ( $type ne q[:] ) {
                    $type = q[] if $type eq q[&];

                    $CACHE->{$caller}->{$tag}->{ $type . $sym } = 1;

                    $CACHE->{$caller}->{ALL}->{ $type . $sym } = [ $sym, $type ];
                }
                else {
                    die qq["ALL" export tag can not contain references to the other tags in package "$caller"] if $tag eq 'ALL';

                    __SUB__->($sym);

                    $CACHE->{$caller}->{$tag}->@{ keys $CACHE->{$caller}->{$sym}->%* } = values $CACHE->{$caller}->{$sym}->%*;
                }
            }

            # mark tag as processed
            $tags->{$tag} = 1;

            return;
        };

        for my $tag ( keys $import->{pragma}->{export}->%* ) {
            $process_tag->($tag);
        }
    }

    # export import method
    {
        no strict qw[refs];

        *{"$caller\::import"} = \&_import;
    }

    return;
}

sub parse_import {
    my $caller = shift;

    my $res;

    my $export_pragma = do {
        no strict qw[refs];

        ${"$caller\::EXPORT_PRAGMA"};
    };

    while ( my $arg = shift ) {
        if ( ref $arg ) {
            die q[Invalid value in the import specification. References are not supported.];
        }
        elsif ( substr( $arg, 0, 1 ) eq q[-] ) {
            substr $arg, 0, 1, q[];

            if ( $arg eq 'level' || $arg eq 'caller' ) {
                $res->{pragma}->{$arg} = shift;
            }
            elsif ( $export_pragma && exists $export_pragma->{$arg} ) {
                $res->{pragma}->{$arg} = $export_pragma->{$arg} ? shift : 1;
            }
            else {
                die qq[Unknown exporter pragma found "-$arg" while importing package "$caller"];
            }
        }
        else {
            $res->{import}->{$arg} = undef;
        }
    }

    return $res;
}

sub _import {
    my $self = shift;

    # parse tags and pragmas
    my $import = parse_import( $self, @_ );

    # find caller
    my $caller = $import->{pragma}->{caller} // caller( $import->{pragma}->{level} // 0 );

    # protection from re-exporting to myself
    return if $caller eq $self;

    _export_tags( $self, $caller, $import->{import} );

    return;
}

sub _export_tags ( $self, $caller, $import ) {
    my $export = $CACHE->{$self};

    if ( !$import ) {
        if ( !exists $export->{DEFAULT} ) {
            return;
        }
        else {
            $import->{':DEFAULT'} = undef;
        }
    }
    else {
        die qq[Package "$self" doesn't export anything] if !$export;
    }

    # gather symbols to export
    my $symbols;

    for my $sym ( keys $import->%* ) {
        my $no_export;

        my $is_tag;

        if ( $sym =~ s/\A([!:])//sm ) {
            if ( $1 eq q[!] ) {
                $no_export = 1;

                $is_tag = 1 if $sym =~ s/\A://sm;
            }
            else {
                $is_tag = 1;
            }
        }

        if ($is_tag) {
            die qq[Unknown tag ":$sym" to import from "$self"] if !exists $export->{$sym};

            if ($no_export) {
                delete $symbols->@{ keys $export->{$sym}->%* };
            }
            else {
                $symbols->@{ keys $export->{$sym}->%* } = ();
            }
        }
        else {

            # remove "&" sigil
            $sym =~ s/\A&//sm;

            my $alias;

            ( $sym, $alias ) = $sym =~ /(.+)=(.+)/sm if index( $sym, q[=] ) > 0;

            die qq[Unknown symbol "$sym" to import from package "$self"] if !exists $export->{ALL}->{$sym};

            if ($no_export) {
                delete $symbols->{$sym};
            }
            else {
                $symbols->{$sym} = $alias;
            }
        }
    }

    # export
    if ( $symbols->%* ) {
        my $export_all = $export->{ALL};

        for my $sym ( keys $symbols->%* ) {

            # skip symbol if it is not exists in symbol table
            next if !defined *{"$self\::$export_all->{$sym}->[0]"};

            my $type = $export_all->{$sym}->[1];

            my $alias = $symbols->{$sym} // $export_all->{$sym}->[0];

            {
                no strict qw[refs];

                no warnings qw[once];

                *{"$caller\::$alias"}
                  = $type eq q[]  ? \&{"$self\::$export_all->{$sym}->[0]"}
                  : $type eq q[$] ? \${"$self\::$export_all->{$sym}->[0]"}
                  : $type eq q[@] ? \@{"$self\::$export_all->{$sym}->[0]"}
                  : $type eq q[%] ? \%{"$self\::$export_all->{$sym}->[0]"}
                  : $type eq q[*] ? *{"$self\::$export_all->{$sym}->[0]"}
                  :                 die;
            }
        }
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "common" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 31, 48, 90, 102,     | ErrorHandling::RequireCarping - "die" used instead of "croak"                                                  |
## |      | 142, 165, 183, 218   |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 130                  | Subroutines::ProhibitExcessComplexity - Subroutine "_export_tags" with high complexity score (28)              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 1                    | Modules::RequireVersionVar - No package-scoped "$VERSION" variable found                                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Exporter

=head1 SYNOPSIS

    use Pcore::Core::Exporter;

    our $EXPORT = [ ...SYMBOLS TO EXPORT... ];

        or

    our $EXPORT = {
        TAG1    => [qw[sub1 $var1 ... ]],
        TAG2    => [qw[:TAG1 sub2 $var2 ... ]],
        DEFAULT => [qw[:TAG1 :TAG2 sym3 ...]],
    };

    our $EXPORT_PRAGMA = {
        trigger => 0,
        option  => 1,
    };

    ...

    use Package qw[-trigger -option OPTION_VALUE :TAG1 !:TAG2 sub1 !sub2 $var1 !$var2 @arr1 !@arr2 %hash1 !%hash2 *sym1 !*sym2], {};

    # export aliases
    use Package qw[$SYM=alias1 @SYM=alias2 sub=alias3]

=head1 DESCRIPTION

Tag ":ALL" is reserver and is created automatically.

If no symbols / tags are specified for import - ":DEFAULT" tag will be exported, if defined.

=head1 SEE ALSO

=cut

package Pcore::Core::L10N;

use Pcore -export => {    #
    DEFAULT => [qw[l10n l10np l10n_ l10np_ $l10n]],
};
use Pcore::Util::Scalar qw[is_plain_hashref];

our $PACKAGE_DOMAIN     = {};
our $DEFAULT_LOCALE     = undef;
our $MESSAGES           = {};
our $LOCALE_PLURAL_FORM = {};

tie our $l10n->%*, 'Pcore::Core::L10N::_l10n';

sub set_locale ($locale = undef) {
    $DEFAULT_LOCALE = $locale if @_;

    return $DEFAULT_LOCALE;
}

sub register_package_domain ( $package, $domain ) {
    $PACKAGE_DOMAIN->{$package} = $domain;

    return;
}

sub load_domain_locale ( $domain, $locale ) : prototype($$) {
    my $dist = $ENV->{_dist_idx}->{$domain};

    die qq[l10n domain "$domain" is not registered] if !$domain;

    my $po_path = "$dist->{share_dir}l10n/$locale.po";

    if ( !-f $po_path ) {
        $MESSAGES->{$domain}->{$locale} = {};

        return;
    }

    my ( $messages, $plural_form, $msgid );

    for my $line ( P->file->read_lines($po_path)->@* ) {

        # skip comments
        next if substr( $line, 0, 1 ) eq '#';

        if ( $line =~ /\Amsgid\s"(.+?)"/sm ) {
            $msgid = $1;

            $messages->{$msgid} = [];
        }
        elsif ( $line =~ /\Amsgid_plural\s/sm ) {
            next;
        }
        elsif ( $line =~ /\Amsgstr\s"(.+?)"/sm ) {
            $messages->{$msgid}->[0] = $1;
        }
        elsif ( $line =~ /\Amsgstr\[(\d+)\]\s"(.+?)"/sm ) {
            $messages->{$msgid}->[$1] = $2;
        }
        elsif ( $line =~ /"(.+?):\s(.+?)\\n"/sm ) {
            $plural_form = $2 if $1 eq 'Plural-Forms';
        }
    }

    if ($plural_form) {
        if ( $plural_form =~ /.+?;\s+plural=[(](.+?)[)];/sm ) {
            my $exp = $1;

            if ( exists $LOCALE_PLURAL_FORM->{$locale}->{exp} ) {
                die qq[Plural form expression for locale "$locale" redefined] if $LOCALE_PLURAL_FORM->{$locale}->{exp} ne $exp;
            }
            else {
                $LOCALE_PLURAL_FORM->{$locale}->{exp} = $exp;
            }

            $exp =~ s/n/\$_[0]/smg;

            $LOCALE_PLURAL_FORM->{$locale}->{code} = eval "sub { return $exp }";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        }
    }

    $MESSAGES->{$domain}->{$locale} = $messages;

    return;
}

sub l10n ( $msgid, $locale = $DEFAULT_LOCALE, $domain = undef ) : prototype($;$$) {
    if ( ref $msgid eq 'Pcore::Core::L10N::_deferred' ) {
        ( $msgid, $domain ) = ( $msgid->{msgid}, $msgid->{domain} );
    }
    else {
        $domain //= $PACKAGE_DOMAIN->{ caller() };
    }

    return $msgid if !defined $locale;

    load_domain_locale $domain, $locale if !exists $MESSAGES->{$domain}->{$locale};

    return $MESSAGES->{$domain}->{$locale}->{$msgid}->[0] // $msgid;
}

sub l10np ( $msgid, $msgid_plural, $num = undef, $locale = $DEFAULT_LOCALE, $domain = undef ) : prototype($$;$$$) {
    if ( ref $msgid eq 'Pcore::Core::L10N::_deferred' ) {
        ( $msgid, $msgid_plural, $num, $locale, $domain ) = ( $msgid->{msgid}, $msgid->{msgid_plural}, $msgid_plural, $num // $DEFAULT_LOCALE, $msgid->{domain} );
    }
    else {
        $domain //= $PACKAGE_DOMAIN->{ caller() };
    }

    $num //= 1;

    goto ENGLISH if !defined $locale;

    load_domain_locale $domain, $locale if !exists $MESSAGES->{$domain}->{$locale};

    goto ENGLISH if !defined $LOCALE_PLURAL_FORM->{$locale}->{code};

    my $idx = $LOCALE_PLURAL_FORM->{$locale}->{code}->($num);

    return $MESSAGES->{$domain}->{$locale}->{$msgid}->[$idx] if defined $MESSAGES->{$domain}->{$locale}->{$msgid}->[$idx];

  ENGLISH:
    if ( $num == 1 ) {
        return $msgid;
    }
    else {
        return $msgid_plural;
    }

    return;
}

sub l10n_ ( $msgid, $domain = undef ) : prototype($;$) {
    return bless {
        is_plural => 0,
        msgid     => $msgid,
        domain    => $domain // $PACKAGE_DOMAIN->{ caller() },
      },
      'Pcore::Core::L10N::_deferred';
}

sub l10np_ ( $msgid, $msgid_plural, $domain = undef ) : prototype($$;$) {
    return bless {
        is_plural    => 1,
        msgid        => $msgid,
        msgid_plural => $msgid_plural,
        domain       => $domain // $PACKAGE_DOMAIN->{ caller() },
      },
      'Pcore::Core::L10N::_deferred';
}

package Pcore::Core::L10N::_deferred {
    use Pcore -class;
    use overload    #
      q[""] => sub {
        return &Pcore::Core::L10N::l10n( $_[0] );    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
      },
      bool => sub {
        return 1;
      },
      fallback => undef;

    has is_plural => ( is => 'ro', isa => Bool, required => 1 );
    has msgid     => ( is => 'ro', isa => Str,  required => 1 );
    has domain    => ( is => 'ro', isa => Str,  required => 1 );
    has msgid_plural => ( is => 'ro', isa => Maybe [Str] );
}

package Pcore::Core::L10N::_l10n {
    use Pcore::Util::Scalar qw[is_plain_arrayref];

    sub TIEHASH ( $self, @args ) {
        return bless {}, $self;
    }

    sub FETCH {

        ## no critic qw[Subroutines::ProhibitAmpersandSigils]

        if ( is_plain_arrayref $_[1] ) {
            if ( $_[1]->[0]->{is_plural} ) {
                return &Pcore::Core::L10N::l10np( $_[1]->[0], $_[1]->[1], $_[1]->[2] );
            }
            else {
                return &Pcore::Core::L10N::l10n( $_[1]->[0], $_[1]->[1] );
            }
        }
        elsif ( ref $_[1] eq 'Pcore::Core::L10N::_deferred' ) {
            return &Pcore::Core::L10N::l10n( $_[1] );
        }
        else {
            return &Pcore::Core::L10N::l10n( $_[1], undef, $PACKAGE_DOMAIN->{ caller() } );
        }
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 103                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 13                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 93, 108, 138, 148,   | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## |      | 193                  |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::L10N - localization subsystem.

=head1 SYNOPSIS

    use Pcore -l10n => 'Domain';

    say l10n 'text';
    say l10n 'text', 'en';

    say l10np 'text', 'text plural', 3;
    say l10np 'text', 'text plural', 3, 'en';

    my $const = l10n_ 'text';
    say const;
    say l10n $const;

    my $const_plural = l10np_ 'text', 'text_plural';
    say $const_plural;
    say l10n $const_plural;
    say l10n $const_plural, 'en';
    say l10np $const_plural, 3;
    say l10np $const_plural, 3, 'en';

    say $l10n->{'text'};
    say $l10n->{$const};
    say $l10n->{[$const, 'en']};

    say $l10n->{[ $const_plural, 3 ]};
    say $l10n->{[ $const_plural, 3, 'en' ]};

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut

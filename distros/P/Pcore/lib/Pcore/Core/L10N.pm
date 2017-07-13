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

        if ( $line =~ /\Amsgid\s"(.*?)"/sm ) {
            $msgid = $1;

            $messages->{$msgid} = [];
        }
        elsif ( $line =~ /\Amsgid_plural\s/sm ) {
            next;
        }
        elsif ( $line =~ /\Amsgstr\s"(.*?)"/sm ) {
            $messages->{$msgid}->[0] = $1;
        }
        elsif ( $line =~ /\Amsgstr\[(\d+)\]\s"(.*?)"/sm ) {
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
    return $msgid if !defined $locale;

    $domain //= $PACKAGE_DOMAIN->{ caller() };

    load_domain_locale $domain, $locale if !exists $MESSAGES->{$domain}->{$locale};

    return $MESSAGES->{$domain}->{$locale}->{$msgid}->[0] // $msgid;
}

sub l10np ( $msgid, $msgid_plural, $num, $locale = $DEFAULT_LOCALE, $domain = undef ) : prototype($$$;$$) {
    goto ENGLISH if !defined $locale;

    $domain //= $PACKAGE_DOMAIN->{ caller() };

    load_domain_locale $domain, $locale if !exists $MESSAGES->{$domain}->{$locale};

    goto ENGLISH if !defined $LOCALE_PLURAL_FORM->{$locale}->{code};

    my $idx = $LOCALE_PLURAL_FORM->{$locale}->{code}->( $num // 1 );

    return $MESSAGES->{$domain}->{$locale}->{$msgid}->[$idx] if defined $MESSAGES->{$domain}->{$locale}->{$msgid}->[$idx];

  ENGLISH:
    if ( !defined $num ) {
        return $msgid;
    }
    elsif ( $num == 1 ) {
        return $msgid;
    }
    else {
        return $msgid_plural;
    }

    return;
}

sub l10n_ ( $msgid, $locale = undef, $domain = undef ) : prototype($;$$) {
    return bless {
        is_plural => 0,
        msgid     => $msgid,
        domain    => $domain // $PACKAGE_DOMAIN->{ caller() },
        locale    => $locale,
      },
      'Pcore::Core::L10N::_deferred';
}

sub l10np_ ( $msgid, $msgid_plural, $num, $locale = undef, $domain = undef ) : prototype($$$;$$) {
    return bless {
        is_plural    => 1,
        msgid        => $msgid,
        msgid_plural => $msgid_plural,
        num          => $num,
        domain       => $domain // $PACKAGE_DOMAIN->{ caller() },
        locale       => $locale,
      },
      'Pcore::Core::L10N::_deferred';
}

package Pcore::Core::L10N::_deferred {
    use Pcore -class;
    use overload    #
      q[""] => sub {
        if ( $_[0]->{is_plural} ) {
            return l10np $_[0]->{msgid}, $_[0]->{msgid_plural}, $_[0]->{num}, $_[0]->{locale}, $_[0]->{domain};
        }
        else {
            return l10n $_[0]->{msgid}, $_[0]->{locale}, $_[0]->{domain};
        }
      },
      bool => sub {
        return 1;
      },
      fallback => undef;

    has is_plural => ( is => 'ro', isa => Bool, required => 1 );
    has msgid     => ( is => 'ro', isa => Str,  required => 1 );
    has domain    => ( is => 'ro', isa => Str );

    has msgid_plural => ( is => 'ro', isa => Maybe [Str] );
    has num          => ( is => 'ro', isa => Maybe [Int] );
    has locale       => ( is => 'ro', isa => Maybe [Str] );

    sub l10n ( $self, $locale = undef ) {
        return Pcore::Core::L10N::l10n $self->{msgid}, $locale // $self->{locale}, $self->{domain};
    }

    sub l10np ( $self, $num = undef, $locale = undef ) {
        die q[l10n string has no plural form] if !$self->{is_plural};

        return Pcore::Core::L10N::l10np $self->{msgid}, $self->{msgid_plural}, $num // $self->{num}, $locale // $self->{locale}, $self->{domain};
    }
}

package Pcore::Core::L10N::_l10n {

    sub TIEHASH ( $self, @args ) {
        return bless {}, $self;
    }

    sub FETCH {
        return Pcore::Core::L10N::l10n $_[1], $DEFAULT_LOCALE, $PACKAGE_DOMAIN->{ caller() };
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 98, 135              | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 13                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 91, 101, 129, 141,   | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## |      | 189                  |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::L10N - localization subsystem.

=head1 SYNOPSIS

=cut

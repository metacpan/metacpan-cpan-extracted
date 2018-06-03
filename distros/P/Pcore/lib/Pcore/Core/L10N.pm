package Pcore::Core::L10N;

use Pcore -export;
use Pcore::Util::Scalar qw[is_plain_hashref];

our $EXPORT = {    #
    DEFAULT => [qw[l10n $l10n]],
};

our $LOCALE             = undef;    # current locale
our $MESSAGES           = {};
our $LOCALE_PLURAL_FORM = {};

tie our $l10n->%*, 'Pcore::Core::L10N::_l10n';

sub set_locale ($locale = undef) {
    $LOCALE = $locale if @_;

    return $LOCALE;
}

sub load_locale ( $locale ) : prototype($) {
    my $messages = $MESSAGES->{$locale} //= {};

    my ( $plural_form, $domains, $msgid );

    for my $dist ( values $ENV->{_dist_idx}->%* ) {
        my $po_path = "$dist->{share_dir}l10n/$locale.po";

        next if !-f $po_path;

        for my $line ( P->file->read_lines($po_path)->@* ) {
            if ( $line =~ /\A#/sm ) {
                if ( $line =~ /\A#:\s*(.+)/sm ) {
                    undef $domains;

                    my $references = $1;

                    while ( $references =~ /\s*([^:]+):\d+/smg ) {
                        my $domain = $1;

                        $domain =~ s/[.]pm\z//sm;
                        $domain =~ s[\Alib/][]sm;
                        $domain =~ s[/][::]smg;

                        $domains->{$domain} = 1;
                    }
                }

                # skip comments
                else {
                    next;
                }
            }

            # msgid
            elsif ( $line =~ /\Amsgid\s"(.+?)"/sm ) {
                $msgid = $1;
            }

            # skip msgid_plural
            elsif ( $line =~ /\Amsgid_plural\s/sm ) {
                next;
            }

            # message
            elsif ( $line =~ /\Amsgstr\s"(.+?)"/sm ) {
                for my $domain ( keys $domains->%* ) {
                    $messages->{$domain}->{$msgid}->[0] = $1;
                }
            }

            # message plural forms
            elsif ( $line =~ /\Amsgstr\[(\d+)\]\s"(.+?)"/sm ) {
                for my $domain ( keys $domains->%* ) {
                    $messages->{$domain}->{$msgid}->[$1] = $2;
                }
            }

            # plural form expression
            elsif ( $line =~ /"(.+?):\s(.+?)\\n"/sm ) {
                $plural_form = $2 if $1 eq 'Plural-Forms';
            }
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

    return;
}

sub l10n ( $msgid, $msgid_plural = undef, $num = undef ) : prototype($;$$) {
    return bless {
        domain       => caller,
        msgid        => $msgid,
        msgid_plural => $msgid_plural,
        num          => $num // 1,
      },
      'Pcore::Core::L10N::_deferred';
}

package Pcore::Core::L10N::_deferred;

use Pcore -class;

use overload    #
  q[""] => sub {
    return $_[0]->to_string;
  },
  q[&{}] => sub {
    my $self = $_[0];

    return sub { $self->to_string(@_) };
  },
  bool => sub {
    return 1;
  },
  fallback => undef;

has domain       => ();
has msgid        => ();
has msgid_plural => ();
has num          => ();

sub to_string ( $self, $num = undef ) {
    goto DEFAULT if !defined $LOCALE;

    # load locale, if not loaded
    Pcore::Core::L10N::load_locale($LOCALE) if !exists $Pcore::Core::L10N::MESSAGES->{$LOCALE};

    if ( my $domain = $Pcore::Core::L10N::MESSAGES->{$LOCALE}->{ $self->{domain} } ) {
        if ( my $msg = $domain->{ $self->{msgid} } ) {
            my $idx = 0;

            if ( $self->{msgid_plural} ) {
                goto DEFAULT if !defined $LOCALE_PLURAL_FORM->{$LOCALE}->{code};

                $idx = $LOCALE_PLURAL_FORM->{$LOCALE}->{code}->( $num // $self->{num} // 1 );
            }

            return $msg->[$idx] if defined $msg->[$idx];
        }
    }

  DEFAULT:
    if ( !defined $num || $num == 1 ) {
        return $self->{msgid};
    }
    else {
        return $self->{msgid_plural} // $self->{msgid};
    }
}

package Pcore::Core::L10N::_l10n;

sub TIEHASH ( $self, @args ) {
    return bless {}, $self;
}

sub FETCH {
    return bless {
        domain => caller,
        msgid  => $_[1],
      },
      'Pcore::Core::L10N::_deferred';
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 22                   | Subroutines::ProhibitExcessComplexity - Subroutine "load_locale" with high complexity score (21)               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 14                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::L10N - localization subsystem.

=head1 SYNOPSIS

    use Pcore -l10n;

    P->set_locale('ru');

    say l10n('single');
    say l10n( 'single', 'plural', 1 );
    say l10n( 'single', 'plural' )->(5);
    say $l10n->{'single'};

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut

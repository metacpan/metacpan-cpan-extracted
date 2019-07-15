package Pcore::Core::L10N;

use Pcore -export;
use Pcore::Lib::Scalar qw[is_plain_hashref];

our $EXPORT = {    #
    DEFAULT => [qw[l10n %l10n]],
};

our $LOCALE             = undef;    # current locale
our $MESSAGES           = {};
our $LOCALE_PLURAL_FORM = {};
our $PROCESSED;                     # all dists are processed
our $LOADED_DIST_LOCALES;

tie our %l10n, 'Pcore::Core::L10N::_l10n';

sub set_locale ($locale = undef) {
    $LOCALE = $locale if @_;

    return $LOCALE;
}

sub load_locale : prototype($) ($locale) {
    return if $PROCESSED && exists $Pcore::Core::L10N::MESSAGES->{$locale};

    $PROCESSED = 1;

    my $messages = $MESSAGES->{$locale} //= {};

    for my $dist ( $ENV->{dists_order}->@* ) {
        next if $LOADED_DIST_LOCALES->{ $dist->{name} }->{$locale};

        $LOADED_DIST_LOCALES->{ $dist->{name} }->{$locale} = 1;

        my $po_path = "$dist->{share_dir}/l10n/$locale.po";

        next if !-f $po_path;

        my ( $msg, $current_tag );

        for my $line ( P->file->read_lines( $po_path, empty_lines => 1 )->@* ) {

            # NOTE https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
            # #<space> - translator comments
            # #. - extracted comments
            # #: - references to the program’s source code
            # #, - flags
            # #| - previous untranslated string
            # msgid
            # msgstr

            # end of block
            if ( !$line ) {
                if ( exists $msg->{msgstr} ) {

                    # header
                    if ( !exists $msg->{msgid} ) {
                        if ( $msg->{msgstr}->[0] =~ /\nPlural-Forms:.+?plural=[(](.+?)[)];\n/sm ) {
                            my $exp = $1;

                            if ( exists $LOCALE_PLURAL_FORM->{$locale}->{exp} ) {
                                die qq[Plural form expression for locale "$locale" redefined:\n$LOCALE_PLURAL_FORM->{$locale}->{exp}\n$exp] if $LOCALE_PLURAL_FORM->{$locale}->{exp} ne $exp;
                            }
                            else {
                                $LOCALE_PLURAL_FORM->{$locale}->{exp} = $exp;
                            }

                            $exp =~ s/n/\$_[0]/smg;

                            $LOCALE_PLURAL_FORM->{$locale}->{code} = eval "sub { return $exp }";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
                        }
                    }
                    else {
                        $messages->{ $msg->{msgid} } = $msg->{msgstr};
                    }
                }

                undef $msg;
                undef $current_tag;
            }

            # comment
            elsif ( $line =~ /\A#/sm ) {
                undef $current_tag;

                if ( $line =~ /\A#:\s*(.+)/sm ) {
                    my $refs = $1;

                    while ( $refs =~ /\s*([^:]+):\d+/smg ) {
                        my $ref = $1;

                        $ref =~ s/[.]pm\z//sm;
                        $ref =~ s[\Alib/][]sm;

                        # $ref =~ s[/][::]smg;

                        $msg->{refs}->{$ref} = 1;
                    }
                }
            }

            elsif ( $line =~ /\A([^"\s]+)?\s*"(.*)"\z/sm ) {
                $current_tag = $1 if $1;

                if ($current_tag) {
                    my $str = $2;

                    # unescape
                    $str =~ s/\\"/"/smg;
                    $str =~ s/\\n/\n/smg;

                    if ( $str ne $EMPTY ) {
                        if ( $current_tag eq 'msgstr' ) {
                            $msg->{msgstr}->[0] .= $str;
                        }
                        elsif ( $current_tag =~ /msgstr\[(\d+)\]/sm ) {
                            $msg->{msgstr}->[$1] .= $str;
                        }
                        else {
                            $msg->{$current_tag} .= $str;
                        }
                    }
                }
            }
        }
    }

    return;
}

sub l10n : prototype($;$$) ( $msgid, $msgid_plural = undef, $num = undef ) {
    return bless {
        caller       => caller,
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

has caller       => ();
has msgid        => ();
has msgid_plural => ();
has num          => ();

sub to_string ( $self, $num = undef ) {
    goto DEFAULT if !defined $LOCALE;

    # load locale, if not loaded
    Pcore::Core::L10N::load_locale($LOCALE) if !$PROCESSED || !exists $Pcore::Core::L10N::MESSAGES->{$LOCALE};

    if ( my $msg = $Pcore::Core::L10N::MESSAGES->{$LOCALE}->{ $self->{msgid} } ) {
        my $idx = 0;

        if ( $self->{msgid_plural} ) {
            goto DEFAULT if !defined $LOCALE_PLURAL_FORM->{$LOCALE}->{code};

            $idx = $LOCALE_PLURAL_FORM->{$LOCALE}->{code}->( $num // $self->{num} // 1 );
        }

        return $msg->[$idx] if defined $msg->[$idx];
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
        caller => caller,
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
## |    3 | 24                   | Subroutines::ProhibitExcessComplexity - Subroutine "load_locale" with high complexity score (25)               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 59, 62, 114          | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 16                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
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
    say $l10n{'single'};

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut

use strictures;

package Number::Format::FixedLocale;

our $VERSION = '1.121780'; # VERSION

# ABSTRACT: a Number::Format that ignores the system locale

#
# This file is part of Number-Format-FixedLocale
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


use base 'Number::Format';

use Carp 'croak';

sub new
{
    my $type = shift;
    my %args = @_;

    # Fetch defaults from current locale, or failing that, using globals
    my $me            = {};

    my $arg;

    while(my($arg, $default) = each %$Number::Format::DEFAULT_LOCALE)
    {
        $me->{$arg} = $default;

        foreach ($arg, uc $arg, "-$arg", uc "-$arg")
        {
            next unless defined $args{$_};
            $me->{$arg} = $args{$_};
            delete $args{$_};
            last;
        }
    }

    #
    # Some broken locales define the decimal_point but not the
    # thousands_sep.  If decimal_point is set to "," the default
    # thousands_sep will be a conflict.  In that case, set
    # thousands_sep to empty string.  Suggested by Moritz Onken.
    #
    foreach my $prefix ("", "mon_")
    {
        $me->{"${prefix}thousands_sep"} = ""
            if ($me->{"${prefix}decimal_point"} eq
                $me->{"${prefix}thousands_sep"});
    }

    croak "Invalid argument(s)" if %args;
    bless $me, $type;
    $me;
}

1;

__END__
=pod

=head1 NAME

Number::Format::FixedLocale - a Number::Format that ignores the system locale

=head1 VERSION

version 1.121780

=head1 SYNOPSIS

    use Number::Format::FixedLocale;
    my $f = Number::Format::FixedLocale->new(
        -mon_thousands_sep => '.',
        -mon_decimal_point => ',',
        -int_curr_symbol   => 'EUR',
        -n_cs_precedes     => 0,
        -p_cs_precedes     => 0,
    );
    print $f->format_price( -45208.23 ); # "-45.208,23 EUR"

=head1 DESCRIPTION

L<Number::Format> is a very useful module, however in environments with many
systems it can be a liability due to the fact that it gathers its default
settings from the system locale, which can lead to surprising results when
formatting numbers in production.

Number::Format::FixedLocale is a sub-class of L<Number::Format> that contains
only a slightly modified constructor, which will only use a fixed set of en_US
default settings. Thus any results from this module will be predictable no
matter how the system it is being run on is configured.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Number-Format-FixedLocale>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/number-format-fixedlocale>

  git clone https://github.com/wchristian/number-format-fixedlocale.git

=head1 AUTHOR

Christian Walde <walde.christian@googlemail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut


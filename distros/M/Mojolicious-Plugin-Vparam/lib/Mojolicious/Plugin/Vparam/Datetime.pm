package Mojolicious::Plugin::Vparam::Datetime;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub check_date($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

sub check_time($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

sub check_datetime($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

# Get a string and return DateTime or undef.
# Have a hack for parse Russian data and time.
sub parse_date($;$) {
    my ($str, $tz) = @_;

    return undef unless defined $str;
    s{^\s+}{}, s{\s+$}{} for $str;
    return undef unless length $str;

    my $dt;

    if( $str =~ m{^\d+$} ) {
        $dt = DateTime->from_epoch( epoch => int $str, time_zone => 'local' );
    } elsif( $str =~ m{^[+-]} ) {
        my @relative = $str =~ m{
            ^([+-])             # sign
            \s*
            (?:(\d+)\s+)?       # days
            (?:(\d+):)??        # hours
            (\d+)               # minutes
            (?::(\d+))?         # seconds
        $}x;
        $dt = DateTime->now(time_zone => 'local');
        my $sub = $relative[0] eq '+' ? 'add' : 'subtract';
        $dt->$sub(days      => int $relative[1])    if defined $relative[1];
        $dt->$sub(hours     => int $relative[2])    if defined $relative[2];
        $dt->$sub(minutes   => int $relative[3])    if defined $relative[3];
        $dt->$sub(seconds   => int $relative[4])    if defined $relative[4];
    } else {
        # RU format
        if( $str =~ s{^(\d{1,2})\.(\d{1,2})\.(\d{1,4})(.*)$}{$3-$2-$1$4} ) {
            my $cur_year = DateTime->now(time_zone => 'local')->strftime('%Y');
            my $cur_len  = length( $cur_year ) - 1;
            # Less digit year
            if( my ($year) = $str =~ m{^(\d{1,$cur_len})-} ) {
                $str = substr($cur_year, 0, 4 - length($year)) . $str;
            }
        }
        # If looks like time add it
        $str = DateTime->now(time_zone => 'local')->strftime('%F ') . $str
            if $str =~ m{^\d{2}:};

        $dt = eval { DateTime::Format::DateParse->parse_datetime( $str ); };
        return undef if $@;
    }

    return undef unless $dt;

    # Always local timezone
    $tz //= DateTime->now(time_zone => 'local')->strftime('%z');
    $dt->set_time_zone( $tz );

    return $dt;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        date        =>
            load    => ['DateTime', 'DateTime::Format::DateParse'],
            pre     => sub { parse_date trim  $_[1] },
            valid   => sub { check_date       $_[1] },
            post    => sub {
                return unless defined $_[1];
                return ref($_[1]) && ( $conf->{date} || ! $_[2]->{blessed} )
                    ? $_[1]->strftime( $conf->{date} )
                    : $_[1];
            },
    );

    $app->vtype(
        time        =>
            load    => ['DateTime', 'DateTime::Format::DateParse'],
            pre     => sub { parse_date trim  $_[1] },
            valid   => sub { check_time       $_[1] },
            post    => sub {
                return unless defined $_[1];
                return ref($_[1]) && ( $conf->{time} || ! $_[2]->{blessed} )
                    ? $_[1]->strftime( $conf->{time} )
                    : $_[1];
            },
    );

    $app->vtype(
        datetime    =>
            load    => ['DateTime', 'DateTime::Format::DateParse'],
            pre     => sub { parse_date trim  $_[1] },
            valid   => sub { check_datetime   $_[1] },
            post    => sub {
                return unless defined $_[1];
                return ref($_[1]) && ( $conf->{datetime} || ! $_[2]->{blessed} )
                    ? $_[1]->strftime( $conf->{datetime} )
                    : $_[1];
            },
    );


    return;
}

1;

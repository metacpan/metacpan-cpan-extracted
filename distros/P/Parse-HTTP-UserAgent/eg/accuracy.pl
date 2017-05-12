#!/usr/bin/env perl
# (c) Burak Gursoy. Distributed under the Perl License.
use strict;
use warnings;
use subs qw(_p);
use lib  qw( .. );
use constant HUNDRED => 100;

use Carp qw( croak );
use Data::Dumper;
use Getopt::Long;
use HTTP::BrowserDetect;
use HTTP::DetectUserAgent;
use HTML::ParseBrowser;
use Parse::HTTP::UserAgent;
use Text::Table;

GetOptions(\my %opt, qw(
    debug
));

our $SILENT = 1;

do 't/db.pl';

run();

sub run {
    my @tests = database({ thaw => 1 });

    welcome( scalar @tests );

    my @fail_common = map { $_ => 0 } qw( lang os version  );
    my %fail        = (
        'Parse::HTTP::UserAgent' => { name => {}, @fail_common },
        'HTML::ParseBrowser'     => { name => {}, @fail_common },
        'HTTP::DetectUserAgent'  => { name => {}, @fail_common },
        'HTTP::BrowserDetect'    => { name => {}, @fail_common },
    );

    my %total;
    foreach my $test ( @tests ) {
        my %ok   = parse_http_useragent( $test->{string} );
        my %hdua = http_detectuseragent( $test->{string} );
        my %hpb  = html_parsebrowser(    $test->{string} );
        my %hbd  = http_browserdetect(   $test->{string} );
        my %is   = set_is( \%ok, \%hpb, \%hbd, \%hdua, $test->{string} );

        foreach my $adjust ( qw( name lang version os ) ) {
            ++$total{ $adjust } if $is{ $adjust };
        }

        $hdua{name} = q{} if $hdua{name} && $hdua{name} eq 'Unknown';

        failures( \%fail, \%is, \%ok, \%hdua, \%hbd, \%hpb );

        my $phua_fail = ( $is{lang}  && ! $ok{lang} ) ||
                          $is{v_nok}                  ||
                        ( $is{os}    && ! $ok{os}   ) ||
                        ( $is{name}  && ! $ok{name} );

        if ( $opt{debug} && $phua_fail ) {
            debug_fail( \%is, \%ok, \%hdua, \%hpb, \%hbd, $test->{string} );
        }
    }

    results( \%fail, \%total );

    return;
}

sub welcome {
    my $total = shift;
    return _p <<"ATTENTION";
*** This is a test to compare the accuracy of the parsers.
*** The data set is from the test suite. There are $total UA strings
*** Parse::HTTP::UserAgent will detect all of them
*** A tiny fraction of the regressions can be related to wrong parsing.
*** Equation tests are not performed. Tests are boolean.

This may take a while. Please stand by ...

ATTENTION
}

sub set_is {
    my($ok, $hpb, $hbd, $hdua, $string) = @_;
    my $fetch = sub {
        my($field, @slots) = @_;
        my @rv = grep { $_ }
                 map  { $_->{ $field } }
                    $ok, $hpb, $hbd, $hdua;
        return $rv[0];
    };

    my %is = map { $_ => $fetch->( $_ ) } qw( name lang version os );

    $is{v_nok} = $is{version}
                    && ! $ok->{version}
                    && _valid_v( $is{version}, $string );
    return %is;
}

sub debug_fail {
    my($is, $ok, $hdua, $hpb, $hbd, $string) = @_;
    _p "$string\n",
    _p "LANG   : $is->{lang}\n"    if $is->{lang}   && ! $ok->{lang};
    _p "VERSION: $is->{version}\n" if $is->{v_nok};
    _p "OS     : $is->{os}\n"      if $is->{os}     && ! $ok->{os};
    _p "NAME   : $is->{name}\n"    if $is->{name}   && ! $ok->{name};
    _p Dumper({
        parse_http_useragent => $ok,
        http_detectuseragent => $hdua,
        html_parsebrowser    => $hpb,
        http_browserdetect   => $hbd,
    });
    _p q{-} x '80', "\n";
    return;
}

sub results {
    my($fail, $total) = @_;
    my $tb = Text::Table->new(
                q{|}, 'Parser',
                q{|}, 'Name FAILS',
                q{|}, 'Version FAILS',
                q{|}, 'Language FAILS',
                q{|}, 'OS FAILS',
                q{|},
            );

    foreach my $parser ( keys %{$fail} ) {
        my $all = $fail->{$parser}{name};
        my $name = 0;
        $name += $all->{$_} for keys %{ $all };
        my $v  = ratio( $fail->{$parser}{version}, $total->{version} );
        my $l  = ratio( $fail->{$parser}{lang}   , $total->{lang}    );
        my $os = ratio( $fail->{$parser}{os}     , $total->{os}      );
        $name  = ratio( $name                    , $total->{name}    );

        $tb->load([
            q{|}, $parser,
            q{|}, $name,
            q{|}, $v,
            q{|}, $l,
            q{|}, $os,
            q{|},
        ]);
    }

    _p    $tb->rule( qw( - + ) )
        . $tb->title
        . $tb->rule( qw( - + ) )
        . $tb->body
        . $tb->rule( qw( - + ) )
    ;

    return;
}

sub ratio {
    my $v   = shift;
    my $tot = shift;
    my $r   = $v ? sprintf('%.2f', ($v*HUNDRED)/$tot) : '0.00';
    return sprintf '% 4d - % 6s%%', $v, $r;
}

sub parse_http_useragent {
    my $ua    = Parse::HTTP::UserAgent->new( shift );
    my %rv    = $ua->as_hash;
    $rv{name} = 'Internet Explorer' if $rv{name} && $rv{name} eq 'MSIE';
    return %rv;
}

sub html_parsebrowser {
    my $ua = HTML::ParseBrowser->new( shift );
    my %rv = map { $_ => $ua->$_() } qw(
        user_agent
        languages
        language
        langs
        lang
        detail
        useragents
        properties
        name
        version
        v
        major
        minor
        os
        ostype
        osvers
        osarc
    );
    # version is a hash with major/minor crap
    $rv{_version} = delete $rv{version};
    $rv{version}  = $rv{v};
    return %rv;
}

sub http_browserdetect {
    # can not detect lang
    my $ua = HTTP::BrowserDetect->new( shift );
    return version => $ua->version,
           os      => $ua->os_string,
           name    => $ua->browser_string,
           ;
}

sub http_detectuseragent  {
    my $ua = HTTP::DetectUserAgent->new(  shift );
    my %rv = map { $_ => $ua->$_() } qw (name version vendor type os);
    return %rv;
}

sub failures {
    my($fail, $is, $ok, $hdua, $hbd, $hpb) = @_;
    no strict qw( refs );
    foreach my $name ( qw( lang version os name ) ) {
        &{ '_fail_' . $name }(
            $fail, $is, $ok, $hdua, $hbd, $hpb
        );
    }
    return;
}

sub _fail_lang {
    my($fail, $is, $ok, $hdua, $hbd, $hpb) = @_;
    my $L = $is->{lang};
    $fail->{'Parse::HTTP::UserAgent'}->{lang}++ if $L && ! $ok->{lang};
    $fail->{'HTTP::DetectUserAgent' }->{lang}++ if $L && ! $hdua->{lang};
    $fail->{'HTML::ParseBrowser'    }->{lang}++ if $L && ! $hpb->{lang};
    $fail->{'HTTP::BrowserDetect'   }->{lang}++ if $L && ! $hbd->{lang};
    return;
}

sub _fail_version {
    my($fail, $is, $ok, $hdua, $hbd, $hpb) = @_;
    my $v = $is->{version};
    $fail->{'Parse::HTTP::UserAgent'}->{version}++ if $is->{v_nok};
    $fail->{'HTTP::DetectUserAgent' }->{version}++ if $v && ! $hdua->{version};
    $fail->{'HTML::ParseBrowser'    }->{version}++ if $v && ! $hpb->{v};
    $fail->{'HTTP::BrowserDetect'   }->{version}++ if $v && ! $hbd->{version};
    return;
}

sub _fail_os {
    my($fail, $is, $ok, $hdua, $hbd, $hpb) = @_;
    my $os = $is->{os};
    $fail->{'Parse::HTTP::UserAgent'}->{os}++ if $os && ! $ok->{os};
    $fail->{'HTTP::DetectUserAgent' }->{os}++ if $os && ! $hdua->{os};
    $fail->{'HTML::ParseBrowser'    }->{os}++ if $os && ! $hpb->{os};
    $fail->{'HTTP::BrowserDetect'   }->{os}++ if $os && ! $hbd->{os};
    return;
}

sub _fail_name {
    my($fail, $is, $ok, $hdua, $hbd, $hpb) = @_;
    my $n = $is->{name};
    ++$fail->{'Parse::HTTP::UserAgent'}->{name}{ $n } if $n && ! $ok->{name};
    ++$fail->{'HTTP::DetectUserAgent' }->{name}{ $n } if $n && ! $hdua->{name};
    ++$fail->{'HTML::ParseBrowser'    }->{name}{ $n } if $n && ! $hpb->{name};
    ++$fail->{'HTTP::BrowserDetect'   }->{name}{ $n } if $n && ! $hbd->{name};
    return;
}

sub _valid_v { # prevent false-positives
    my($v, $str)= @_;
    return $str !~ m{ \A Mozilla [/] $v \s }xms;
}

sub _p {
    print {*STDOUT} @_ or croak "Can't print: $!";
}

1;

__END__

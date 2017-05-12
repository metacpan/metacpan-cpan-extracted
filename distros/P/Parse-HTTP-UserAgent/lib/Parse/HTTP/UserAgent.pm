package Parse::HTTP::UserAgent;
use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '0.39';

use base qw(
    Parse::HTTP::UserAgent::Base::IS
    Parse::HTTP::UserAgent::Base::Parsers
    Parse::HTTP::UserAgent::Base::Dumper
    Parse::HTTP::UserAgent::Base::Accessors
);
use overload '""',    => 'name',
             '0+',    => 'version',
             fallback => 1,
;
use version;
use Carp qw( croak );
use Parse::HTTP::UserAgent::Constants qw(:all);

BEGIN {
    constant->import( DEBUG => 0 ) if not defined &DEBUG;
}

my %OSFIX = (
    'WinNT4.0'       => 'Windows NT 4.0',
    'WinNT'          => 'Windows NT',
    'Windows 4.0'    => 'Windows 95',
    'Win95'          => 'Windows 95',
    'Win98'          => 'Windows 98',
    'Windows 4.10'   => 'Windows 98',
    'Win 9x 4.90'    => 'Windows Me',
    'Windows NT 5.0' => 'Windows 2000',
    'Windows NT 5.1' => 'Windows XP',
    'Windows NT 5.2' => 'Windows Server 2003',
    'Windows NT 6.0' => 'Windows Vista / Server 2008',
    'Windows NT 6.1' => 'Windows 7',
);

sub new {
    my $class = shift;
    my $ua    = shift || croak 'No user agent string specified';
    my $opt   = shift || {};
    croak 'Options must be a hash reference' if ref $opt ne 'HASH';
    my $self  = [ map { undef } 0..MAXID ];
    bless $self, $class;
    @{ $self }[ UA_STRING, UA_STRING_ORIGINAL ] = ($ua) x 2;
    $self->[IS_EXTENDED] = exists $opt->{extended} ? $opt->{extended} : 1;
    $self->_normalize( $opt->{normalize} ) if $opt->{normalize};
    $self->_parse;
    return $self;
}

sub as_hash {
    my $self = shift;
    my %struct;
    foreach my $id ( $self->_object_ids ) {
        (my $name = $id) =~ s{ \A UA_ }{}xms;
        $struct{ lc $name } = $self->[ $self->$id() ];
    }
    return %struct;
}

sub trim {
    my $self = shift;
    my $s    = shift;
    return $s if ! $s;
    $s =~ s{ \A \s+    }{}xms;
    $s =~ s{    \s+ \z }{}xms;
    return $s;
}

sub _normalize {
    my $self = shift;
    my $nopt = shift;
    my $type = ref $nopt;

    my @o = ! $type            ? ':all'
          :   $type eq 'ARRAY' ? @{ $nopt }
          :                      croak "Normalization option $nopt is invalid";

    my %mode      = map { $_ => 1 } @o;
    my @all       = qw( plus_to_space trim_spaces );
    @mode{ @all } = (1) x @all if delete $mode{':all'};

    my $s = \$self->[UA_STRING];
    ${$s} =~ s{[+]}{ }xmsg if $mode{plus_to_space};
    ${$s} =~ s<\s+>< >xmsg if $mode{trim_spaces};
    return;
}

sub _parse {
    my $self = shift;
    return $self if $self->[IS_PARSED];
    $self->_do_parse( $self->_pre_parse );
    $self->[IS_PARSED] = 1;
    $self->_post_parse if ! $self->[UA_UNKNOWN];
    return;
}

sub _pre_parse {
    my $self = shift;
    $self->[IS_MAXTHON] = index(uc $self->[UA_STRING], 'MAXTHON') != NO_IMATCH;
    my $ua = $self->[UA_STRING];

    my @parts;
    my $i     = 0;
    my $depth = 0;
    foreach my $token ( split RE_SPLIT_PARSE, $ua ) {
        if ( $token eq '(' ) {
            $i++ if ++$depth == 1;
            next;
        }
        if ( $token eq ')' ) {
            $i++ if --$depth == 0;
            next;
        }
        push @{ $parts[$i] ||= [] }, $token;
    }

    # Hopefully the above code was successful and now we can set the actual
    # tokens to use inside parsers.
    my($moz)    = join ' ', @{ shift(@parts) || []  };
    my($thing)  = join ' ', @{ shift(@parts) || []  };
    my($extra)  = join ' ', @{ shift(@parts) || []  };
    my(@others) = map { @{ $_ } } @parts;

    $thing = $thing ? [ split RE_SC_WS, $thing ] : [];
    $extra = [ split RE_WHITESPACE, $extra ] if $extra;

    $self->_debug_pre_parse( $moz, $thing, $extra, @others ) if DEBUG;
    return $moz, $thing, $extra, @others;
}

sub _do_parse {
    my($self, $m, $t, $e, @o) = @_;
    my $c = $t->[0] && $t->[0] eq 'compatible';

    if ( $c && shift @{$t} && ! $e && ! $self->[IS_MAXTHON] ) {
        my($n, $v) = split RE_WHITESPACE, $t->[0];
        if ( $n eq 'MSIE' && index($m, q{ }) == NO_IMATCH ) {
            return $self->_parse_msie($m, $t, $e, $n, $v);
        }
    }

    my $rv =  $self->[IS_MAXTHON]        ? [maxthon    => $m, $t, $e, @o       ]
            : $self->_is_opera_pre($m)   ? [opera_pre  => $m, $t, $e           ]
            : $self->_is_opera_post($e)  ? [opera_post => $m, $t, $e, $c       ]
            : $self->_is_opera_ff($e)    ? [opera_pre  => "$e->[2]/$e->[3]", $t]
            : $self->_is_ff($e)          ? [firefox    => $m, $t, $e, @o       ]
            : $self->_is_safari($e, \@o) ? [safari     => $m, $t, $e, @o       ]
            : $self->_is_chrome($e, \@o) ? [chrome     => $m, $t, $e, @o       ]
            : $self->_is_android($t,\@o) ? [android    => $m, $t, $e, @o       ]
            : undef;

    if ( $rv ) {
        my $pname  = shift @{ $rv };
        my $method = '_parse_' . $pname;
        my $rvx    = $self->$method( @{ $rv } );
        if ( $rvx ) {
            $self->[UA_PARSER] ||= $pname;
            return $rvx;
        }
    }

    return $self->_extended_probe($m, $t, $e, $c, @o) if $self->[IS_EXTENDED];

    $self->[UA_UNKNOWN] = 1; # give up
    return;
}

sub _post_parse {
    my $self = shift;
    $self->[UA_VERSION] = $self->_numify( $self->[UA_VERSION_RAW] )
        if $self->[UA_VERSION_RAW];

    my @buf;
    foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
        if ( $self->_is_strength( $e ) ) {
            $self->[UA_STRENGTH] = $e ;
            next;
        }
        push @buf, $e;
    }

    $self->[UA_EXTRAS] = [ @buf ];

    if ( $self->[UA_TOOLKIT] ) {
        my $v = $self->[UA_TOOLKIT][TK_ORIGINAL_VERSION];
        push @{ $self->[UA_TOOLKIT] }, defined $v ? $self->_numify( $v ) : 0;
    }

    if( $self->[UA_MOZILLA] ) {
        $self->[UA_MOZILLA] =~ tr/a-z://d;
        $self->[UA_MOZILLA] = [ $self->[UA_MOZILLA],
                                $self->_numify( $self->[UA_MOZILLA] ) ];
    }

    if ( $self->[UA_OS] ) {
        $self->[UA_OS] = $OSFIX{ $self->[UA_OS] } || $self->[UA_OS];
    }

    foreach my $robo ( LIST_ROBOTS ) { # regex???
        next if lc $robo ne lc $self->[UA_NAME];
        $self->[UA_ROBOT] = 1;
        last;
    }
    return;
}

sub _extended_probe {
    my($self, @args) = @_;

    return if $self->_is_gecko             && $self->_parse_gecko(    @args );
    return if $self->_is_netscape( @args ) && $self->_parse_netscape( @args );
    return if $self->_is_docomo(   @args ) && $self->_parse_docomo(   @args );
    return if $self->_is_generic(  @args );
    return if $self->_is_emacs(    @args ) && $self->_parse_emacs(    @args );
    return if $self->_is_moz_only( @args ) && $self->_parse_moz_only( @args );
    return if $self->_is_hotjava(  @args ) && $self->_parse_hotjava(  @args );

    $self->[UA_UNKNOWN] = 1;
    return;
}

sub _object_ids {
    return grep { $_ =~ RE_OBJECT_ID } keys %Parse::HTTP::UserAgent::;
}

sub _numify {
    my $self = shift;
    my $v    = shift || return 0;
    my @removed;

    if (
        $v =~ s{(
                pre      |
                rel      |
                alpha    |
                beta     |
                \-stable |
                gold     |
                [ab]\d+  |
                a\-XXXX  |
                [+]
               )}{}xmsig
    ){
        push @removed, $1 if INSIDE_VERBOSE_TEST;
    }

    if (
        $v =~ s{(
                (?:[^0-9]+)? # usually dash
                rc           # nonsense
                [\-_.]?      # usually dash
                ([0-9])      # teh candidate revision
            )}{.0.$2}xmsi    # yeah, hacky
    ) {
        push @removed, $1 if INSIDE_VERBOSE_TEST;
    }

    # workaround another stupidity (1.2.3-4)
    if ( my $rc = $v =~ tr/-/./ ) {
        push @removed, '-' x $rc if INSIDE_VERBOSE_TEST;
    }

    # Finally, be aggressive to prevent dying on bogus stuff.
    # It's interesting how people provide highly stupid version "numbers".
    # Version parameters are probably more stupid than the UA string itself.
    if ( $v =~ s<([^0-9._v])><.>xmsg ) {
        push @removed, $1 if INSIDE_VERBOSE_TEST;
    }

    if ( $v =~ s<([.]{2,})><.>xmsg ) {
        push @removed, $1 if INSIDE_VERBOSE_TEST;
    }

    if ( INSIDE_VERBOSE_TEST ) {
        if ( @removed ) {
            my $r = join q{','}, @removed;
            Test::More::diag("[DEBUG] _numify: removed '$r' from version string");
        }
    }

    # Gecko revisions like: "20080915000512" will cause an
    #   integer overflow warning. use bigint?
    local $SIG{__WARN__} = sub {
        my $msg = shift;
        warn "$msg\n" if $msg !~ RE_WARN_OVERFLOW && $msg !~ RE_WARN_INVALID;
    };
    # if version::vpp is used it'll identify 420 as a v-string
    # add a floating point to fool it
    $v .= q{.0} if index($v, q{.}) == NO_IMATCH;
    (my $check = $v) =~ tr/0-9//cd;
    return 0 if ! $check; # A string parsed as version (i.e.: AppleWebKit/en_SG)
    my $rv;
    eval {
        $rv = version->new("$v")->numify;
        1;
    } or do {
        my $error = $@ || '[unknown error while parsing version]';
        if ( INSIDE_UNIT_TEST ) {
            chomp $error;
            if ( INSIDE_VERBOSE_TEST ) {
                Test::More::diag( "[FATAL] _numify: version said: $error for '$v'" );
                Test::More::diag(
                    sprintf '[FATAL] _numify: UA with bogus version (%s) is: %s',
                                $v, $self->[UA_STRING]
                );
                Test::More::diag( '[FATAL] _numify: ' . $self->dumper );
            }
            croak $error;
        }
        else {
            croak $error;
        }
    };
    return $rv;
}

sub _debug_pre_parse {
    my($self, $moz, $thing, $extra, @others) = @_;

    my $raw = [
                { qw/ name moz    value / => $moz     },
                { qw/ name thing  value / => $thing   },
                { qw/ name extra  value / => $extra   },
                { qw/ name others value / => \@others },
            ];
    my $pok = print "-------------- PRE PARSE DUMP --------------\n"
                  . $self->dumper(args => $raw)
                  . "--------------------------------------------\n";
    return;
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent - Parser for the User Agent string

=head1 SYNOPSIS

   use Parse::HTTP::UserAgent;
   my $ua = Parse::HTTP::UserAgent->new( $str );
   die "Unable to parse!" if $ua->unknown;
   print $ua->name;
   print $ua->version;
   print $ua->os;
   # or just dump for debugging:
   print $ua->dumper;

=head1 DESCRIPTION

This document describes version C<0.39> of C<Parse::HTTP::UserAgent>
released on C<2 December 2013>.

Quoting L<http://www.webaim.org/blog/user-agent-string-history/>:

   " ... and then Google built Chrome, and Chrome used Webkit, and it was like
   Safari, and wanted pages built for Safari, and so pretended to be Safari.
   And thus Chrome used WebKit, and pretended to be Safari, and WebKit pretended
   to be KHTML, and KHTML pretended to be Gecko, and all browsers pretended to
   be Mozilla, (...) , and the user agent string was a complete mess, and near
   useless, and everyone pretended to be everyone else, and confusion
   abounded."

User agent strings are a complete mess since there is no standard format for
them. They can be in various formats and can include more or less information
depending on the vendor's (or the user's) choice. Also, it is not dependable
since it is some arbitrary identification string. Any user agent can fake
another. So, why deal with such a useless mess? You may want to see the choice
of your visitors and can get some reliable data (even if some are fake) and
generate some nice charts out of them or just want to send an C<HttpOnly> cookie
if the user agent seems to support it (and send a normal one if this is not the
case). However, browser sniffing for client-side coding is considered a bad
habit.

This module implements a rules-based parser and tries to identify
MSIE, FireFox, Opera, Safari & Chrome first. It then tries to identify Mozilla,
Netscape, Robots and the rest will be tried with a generic parser. There is
also a structure dumper, useful for debugging.

=head1 METHODS

=head2 new STRING [, OPTIONS ]

Constructor. Takes the user agent string as the first parameter and returns
an object based on the parsed structure.

The optional C<OPTIONS> parameter (must be a hashref) can be used to pass
several parameters:

=over 4

=item *

C<extended>: controls if the extended probe will be used or not. Default
is true. Set this to false to disable:

   $ua = Parse::HTTP::UserAgent->new( $str, { extended => 0 } );

Can be used to speed up the parser by disabling detection of non-major browsers,
robots and most mobile agents.

=back

=head2 trim STRING

Trims the string.

=head2 as_hash

Returns a hash representation of the parsed structure.

=head2 dumper

See L<Parse::HTTP::UserAgent::Base::Dumper>.

=head2 accessors

See L<Parse::HTTP::UserAgent::Base::Accessors> for the available accessors you can
use on the parsed object.

=head1 OVERLOADED INTERFACE

The object returned, overloads stringification (C<name>) and numification
(C<version>) operators. So that you can write this:

    print 42 if $ua eq 'Opera' && $ua >= 9;

instead of this

    print 42 if $ua->name eq 'Opera' && $ua->version >= 9;

=head1 ERROR HANDLING

=over 4

=item *

If you pass a false value to the constructor, it'll croak.

=item *

If you pass a non-hashref option to the constructor, it'll croak.

=item *

If you pass a wrong parameter to the dumper, it'll croak.

=back

=head1 SEE ALSO

=head2 Similar Functionality

=over 4

=item *

L<HTML::ParseBrowser>

=item *

L<HTTP::BrowserDetect>

=item *

L<HTTP::DetectUserAgent>

=item *

L<HTTP::MobileAgent>

=item *

L<Mobile::UserAgent>

=back

=head2 Resources

=over 4

=item *

L<http://en.wikipedia.org/wiki/User_agent>

=item *

L<http://www.zytrax.com/tech/web/browser_ids.htm>

=item *

L<http://www.zytrax.com/tech/web/mobile_ids.html>

=item *

L<http://www.webaim.org/blog/user-agent-string-history/>

=item *

L<https://developer.mozilla.org/en/Gecko_user_agent_string_reference>

=item *

L<http://www.useragentstring.com>

=back

=head2 Module Reviews

=over 4

=item *

CPAN modules for parsing User-Agent strings by B<Neil Bowers>:
L<http://blogs.perl.org/users/neilb/2011/10/cpan-modules-for-parsing-user-agent-strings.html>
(23 October 2011).

=item *

Parse::HTTP::UserAgent: yet another user agent string parser by B<Burak Gursoy>:
L<http://use.perl.org/~Burak/journal/39577> (4 September 2009).

=back

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut

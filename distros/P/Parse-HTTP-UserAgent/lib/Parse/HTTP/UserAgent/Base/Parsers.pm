package Parse::HTTP::UserAgent::Base::Parsers;
use strict;
use warnings;
use vars qw( $VERSION );
use Parse::HTTP::UserAgent::Constants qw(:all);

$VERSION = '0.39';

sub _extract_dotnet {
    my($self, @args) = @_;
    my @raw  = map { ref($_) eq 'ARRAY' ? @{$_} : $_ } grep { $_ } @args;
    my(@extras,@dotnet);

    foreach my $e ( @raw ) {
        if ( my @match = $e =~ RE_DOTNET ) {
            push @dotnet, $match[0];
            next;
        }
        if ( $e =~ RE_WINDOWS_OS ) {
            if ( $1 && $1 ne '64' ) {
                # Maxthon stupidity: multiple OS definitions
                $self->[UA_OS] ||= $e;
                next;
            }
        }
        push @extras, $e;
    }

    return [@extras], [@dotnet];
}

sub _fix_opera {
    my $self = shift;
    return 1 if ! $self->[UA_EXTRAS];
    my @buf;
    foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
        if ( $e =~ RE_OPERA_MINI ) {
            $self->[UA_ORIGINAL_NAME]    = $1;
            $self->[UA_ORIGINAL_VERSION] = $2;
            $self->[UA_MOBILE]           = 1;
            next;
        }
        push @buf, $e;
    }
    $self->_fix_os_lang;
    $self->_fix_windows_nt('skip_os');
    $self->[UA_EXTRAS] = [ @buf ];
    return 1;
}

sub _fix_generic {
    my($self, $os_ref, $name_ref, $v_ref, $e_ref) = @_;
    if ( ${$v_ref} && ${$v_ref} !~ RE_DIGIT) {
        ${$name_ref} .= q{ } . ${$v_ref};
        ${$v_ref}     = undef;
    }

    if ( ${$os_ref} && ${$os_ref} =~ RE_HTTP ) {
        ${$os_ref} =~ s{ \A \+ }{}xms;
        push @{ $e_ref }, ${$os_ref};
        ${$os_ref} = undef;
    }
    return;
}

sub _parse_maxthon {
    my($self, $moz, $thing, $extra, @others) = @_;
    my $is_30 =    $extra
                && $extra->[0]
                && index( $extra->[0], 'AppleWebKit' ) != NO_IMATCH;
    my($maxthon, $msie, @buf);

    if ( $is_30 ) {
        # yay, new nonsense with the new version
        my @new;
        for my $i (0..$#others) {
            if ( index( $others[$i], 'Maxthon') != NO_IMATCH ) {
                @new        = split m{\s+}xms, $others[$i];
                $maxthon    = shift @new;
                $extra    ||= [];
                unshift @{ $extra }, shift @new;
                $others[$i] = '';
                last;
            }
        }
        @others = grep { $_ } @others, @new;
        $self->_parse_safari( $moz, $thing, $extra, @others );
        $self->[UA_NAME] = 'Maxthon';
    }
    else {
    my @omap = grep { $_ } map { split RE_SC_WS_MULTI, $_ } @others;

    foreach my $e ( @omap, @{$thing} ) { # $extra -> junk
        if ( index(uc $e, 'MAXTHON') != NO_IMATCH ) {
            $maxthon = $e;
            next;
        }
        if ( index(uc $e, 'MSIE' ) != NO_IMATCH ) {
            # Maxthon stupidity: multiple MSIE strings
            $msie ||= $e;
            next;
        }
        push @buf, $e;
    }
    }

    if ( ! $maxthon ) {
        warn ERROR_MAXTHON_VERSION . "\n";
        $self->[UA_UNKNOWN] = 1;
        return;
    }

    if ( $is_30 ) {
        if ( $self->[UA_LANG] ) {
            push @{ $self->[UA_EXTRAS] }, $self->[UA_LANG];
            $self->[UA_LANG] = undef;
        }
    }
    else {
        if ( ! $msie ) {
            warn ERROR_MAXTHON_MSIE . "\n";
            $self->[UA_UNKNOWN] = 1;
            return;
        }
        $self->_parse_msie(
            $moz, [ undef, @buf ], undef, split RE_WHITESPACE, $msie
        );
    }

    my(undef, $mv) = split $is_30 ? RE_SLASH : RE_WHITESPACE, $maxthon;
    my $v = $mv      ? $mv
          : $maxthon ? '1.0'
          :            do { warn ERROR_MAXTHON_VERSION . "\n"; 0 }
          ;

    $self->[UA_ORIGINAL_VERSION] = $v;
    $self->[UA_ORIGINAL_NAME]    = 'Maxthon';
    $self->[UA_PARSER]           = 'maxthon';
    return 1;
}

sub _parse_msie {
    my($self, $moz, $thing, $extra, $name, $version) = @_;
    my $junk = shift @{ $thing }; # already used
    my($extras,$dotnet) = $self->_extract_dotnet( $thing, $extra );

    if ( @{$extras} == 2 && index( $extras->[1], 'Lunascape' ) != NO_IMATCH ) {
        ($name, $version) = split RE_CHAR_SLASH_WS, pop @{ $extras };
    }

    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_DOTNET]      = [ @{ $dotnet } ] if @{$dotnet};

    if ( $extras->[0] && $extras->[0] eq 'Mac_PowerPC' ) {
        $self->[UA_OS] = shift @{ $extras };
    }

    my @buf;
    foreach my $e ( @{ $extras } ) {
        if ( $e =~ RE_TRIDENT ) {
            $self->[UA_TOOLKIT] = [ $1, $2 ];
            next;
        }
        push @buf, $e;
    }

    $self->[UA_EXTRAS] = [
        map  { $self->trim( $_ ) }
        grep { $_ !~ m{ \s+ compatible \z }xms }
        @buf
    ];

    $self->[UA_PARSER] = 'msie';

    return 1;
}

sub _parse_firefox {
    my($self, @args) = @_;
    $self->_parse_mozilla_family( @args );
    my $e = $self->[UA_EXTRAS];

    if ( ref $e eq 'ARRAY'
        && @{ $e } > 0
        && index( lc $e->[-1], 'fennec' ) != NO_IMATCH
    ) {
        $self->_fix_fennec( $e );
    }

    $self->[UA_NAME] = 'Firefox';

    return 1;
}

sub _fix_fennec {
    my($self, $e) = @_;
    my($name, $version) = split RE_SLASH, pop @{ $e };
    $self->[UA_ORIGINAL_NAME]    = $name;
    $self->[UA_ORIGINAL_VERSION] = $version;
    $self->[UA_MOBILE]           = 1;
    return if ! $self->[UA_LANG];

    if ( lc $self->[UA_LANG] eq 'tablet' ) {
        $self->[UA_TABLET] = 1;
        $self->[UA_LANG]   = undef;
    }
    elsif ( index( $self->[UA_LANG], q{ } ) != NO_IMATCH ) {
        push @{ $self->[UA_EXTRAS] }, $self->[UA_LANG];
        $self->[UA_LANG] = undef;
    }
    else {
        # Do nothing
    }

    return;
}

sub _parse_safari {
    my($self, $moz, $thing, $extra, @others) = @_;
    my $ipad            = $thing && lc( $thing->[0] || q{} ) eq 'ipad';
    my($version, @junk) = split RE_WHITESPACE, pop @others;
    my $ep              = $version &&
                            index( lc($version), 'epiphany' ) != NO_IMATCH;
    my($junkv, $vx)     = split RE_SLASH, $version;

    if ( $ipad ) {
        shift @{ $thing }; # remove iPad
        if ( $junkv && $junkv eq 'Mobile' ) {
            unshift @junk, join q{/}, $junkv, $vx;
            $vx = undef;
        }
        $self->[UA_MOBILE] = 1;
        $self->[UA_TABLET] = 1;
    }

    $self->[UA_NAME]        = $ep   ? 'Epiphany'
                            : $ipad ? 'iPad'
                            :         'Safari';
    $self->[UA_VERSION_RAW] = $vx;
    $self->[UA_TOOLKIT]     = $extra ? [ split RE_SLASH, shift @{ $extra } ] : [];
    if ( $thing->[-1] && length($thing->[LAST_ELEMENT]) <= 5 ) {
        # todo: $self->_is_lang_field($junk)
        # in here or in _post_parse()
        $self->[UA_LANG]    = pop @{ $thing };
    }
    $self->[UA_OS]          = @{$thing} && length $thing->[LAST_ELEMENT] > 1
                            ? pop   @{ $thing }
                            : shift @{ $thing }
                            ;
    if ( $self->[UA_OS] && lc $self->[UA_OS] eq 'macintosh' ) {
        $self->[UA_OS]   = $self->[UA_LANG];
        $self->[UA_LANG] = undef;
    }

    if ( $thing->[0] && lc $thing->[0] eq 'iphone' ) {
        $self->[UA_MOBILE] = 1;
        $self->[UA_DEVICE] = shift @{$thing};
        my $check_os       = $thing->[LAST_ELEMENT];

        if ( $check_os && index( $check_os, 'Mac OS X' ) != NO_IMATCH ) {
            if ( $self->[UA_OS] ) {
                push @{$self->[UA_EXTRAS]}, $self->[UA_OS];
            }
            $self->[UA_OS] = pop @{ $thing };
            # Another oddity: tk as "AppleWebKit/en_SG"
            if ( ! $self->[UA_LANG] && $self->[UA_TOOLKIT] ) {
                my $v = $self->[UA_TOOLKIT][TK_ORIGINAL_VERSION];
                if ( $v && $v =~ m< [a-zA-Z]{2}_[a-zA-Z]{2} >xms ) {
                    $self->[UA_LANG] = $v;
                    $self->[UA_TOOLKIT][TK_ORIGINAL_VERSION] = undef;
                }
            }
        }
    }

    $self->[UA_EXTRAS] = [ @{$thing}, @others ];

    if ( $self->[UA_OS] && length($self->[UA_OS]) == 1 ) {
        push @{$self->[UA_EXTRAS]}, $self->[UA_OS];
        $self->[UA_OS] = undef;
    }

    push @{$self->[UA_EXTRAS]}, @junk if @junk;
    push @{$self->[UA_EXTRAS]}, @{$extra} if $extra;

    return 1;
}

sub _parse_chrome {
    my($self, $moz, $thing, $extra, @others) = @_;
    my $chx = pop @others;
    my($chrome, $safari, @rest) = split RE_WHITESPACE, $chx;
    my $opera;
    if ( $rest[0] && index( $rest[0], 'OPR/', 0) != NO_IMATCH ) {
        $opera = shift @rest;
        if ( ref $extra eq 'ARRAY' ) {
            unshift @{ $extra }, $chrome;
        }
        push @others, @rest, $safari;
    }
    else {
        push @others, $safari;
    }
    $self->_parse_safari($moz, $thing, $extra, @others);
    my($name, $version)      = split RE_SLASH, $opera || $chrome;
    $self->[UA_NAME]         = $opera ? 'Opera' : $name;
    $self->[UA_VERSION_RAW]  = $version;
    return 1;
}

sub _parse_android {
    my($self, $moz, $thing, $extra, @others) = @_;
    (undef, @{$self}[UA_STRENGTH, UA_OS, UA_LANG, UA_DEVICE]) = @{ $thing };
    if ( ! $extra
        && $others[0]
        && index( $others[0], 'AppleWebKit' ) != NO_IMATCH
    ) {
        $extra = [ shift @others ];
        $self->[UA_PARSER] = 'android:paren_fixer';
    }
    $self->[UA_TOOLKIT] = [ split RE_SLASH, $extra->[0] ] if $extra;
    my(@extras, $is_phone);

    my @junkions = map { split m{\s+}xms } @others;
    foreach my $junk ( @junkions ) {
        if ( $junk eq 'Mobile' ) {
            $is_phone = 1;
            next;
        }
        if ( index( $junk, 'Version' ) != NO_IMATCH ) {
            my(undef, $v) = split RE_SLASH, $junk;
            $self->[UA_VERSION_RAW] = $v; # looks_like_number?
            next;
        }
        push @extras, $junk;
    }

    if ( $self->[UA_DEVICE] ) {
        my @build = split RE_WHITESPACE, $self->[UA_DEVICE];
        my @btest;
        while ( @build && index($build[-1], 'Build') == NO_IMATCH ) {
            unshift @btest, pop @build;
        }
        unshift @btest, pop @build if @build;
        my $device = @build ? join ' ', @build : undef;
        my $build  = shift @btest;

        if ( $device && $build ) {
            $build =~ s{ Build/ }{}xms;
            my $os = $self->[UA_OS] || 'Android';
            $self->[UA_DEVICE] = $device;
            $self->[UA_OS]     = "$os ($build)";
            if ( @btest ) {
                $self->[UA_TOOLKIT] = [ split RE_SLASH, $btest[0] ];
            }
        }
    }

    if ( @extras >= 3 && $extras[0] && $extras[0] eq 'KHTML,') {
        unshift @extras, join ' ', map { shift @extras } 1..3;
    }

    $self->[UA_NAME]   = 'Android';
    $self->[UA_MOBILE] = 1;
    $self->[UA_TABLET] = $is_phone ? undef : 1;
    $self->[UA_EXTRAS] = [ grep { $_ } @extras ];

    return 1;
}

sub _parse_opera_pre {
    # opera 5,9
    my($self, $moz, $thing, $extra) = @_;
    my $ffaker = @{$thing} && index($thing->[LAST_ELEMENT], 'rv:') != NO_IMATCH
               ? pop @{$thing}
               : 0;
    my($name, $version)     = split RE_SLASH, $moz;
    return if $name ne 'Opera';
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version;
    my $lang;

    if ( $extra ) {
        # opera changed version string to workaround lame browser sniffers
        # http://dev.opera.com/articles/view/opera-ua-string-changes/
        my $swap = @{$extra}
                   && index($extra->[LAST_ELEMENT], 'Version/') != NO_IMATCH;
        ($lang = $swap ? shift @{$extra} : pop @{$extra}) =~ tr/[]//d;
        if ( $swap ) {
            my $vjunk = pop @{$extra};
            $self->[UA_VERSION_RAW] = ( split RE_SLASH, $vjunk )[1] if $vjunk;
        }
    }

    $lang ||= pop @{$thing} if $ffaker;

    my $tk_parsed_as_lang = ! $self->[UA_TOOLKIT]
                            && $self->_numify( $version ) >= OPERA9
                            && $lang
                            && length( $lang ) > OPERA_TK_LENGTH;

    if ( $tk_parsed_as_lang ) {
        $self->[UA_TOOLKIT] = [ split RE_SLASH, $lang ];
       ($lang = pop @{$thing}) =~ tr/[]//d if $extra;
    }

    $self->[UA_LANG] = $lang;
    $self->[UA_OS]   = @{$thing} && $self->_is_strength( $thing->[LAST_ELEMENT] )
                     ? shift @{$thing}
                     : pop   @{$thing}
                     ;

    $self->[UA_EXTRAS] = [ @{ $thing }, ( $extra ? @{$extra} : () ) ];
    return $self->_fix_opera;
}

sub _parse_opera_post {
    # opera 5,6,7
    my($self, $moz, $thing, $extra, $compatible) = @_;
    shift @{ $thing } if $compatible;
    $self->[UA_NAME]        = shift @{$extra};
    $self->[UA_VERSION_RAW] = shift @{$extra};
   ($self->[UA_LANG]        = shift @{$extra} || q{}) =~ tr/[]//d;
    $self->[UA_OS]          = @{$thing} && $self->_is_strength($thing->[LAST_ELEMENT])
                            ? shift @{$thing}
                            : pop   @{$thing}
                            ;
    $self->[UA_EXTRAS]      = [ @{ $thing }, ( $extra ? @{$extra} : () ) ];
    return $self->_fix_opera;
}

sub _parse_mozilla_family {
    my($self, $moz, $thing, $extra, @others) = @_;
    # firefox variation or just mozilla itself
    my($name, $version)      = split RE_SLASH, defined $extra->[1] ? $extra->[1]
                             :                                       $moz
                             ;
    if ( $version ) {
        $extra->[1] = '';
    }
    $self->[UA_NAME]         = $name;
    $self->[UA_VERSION_RAW]  = $version;
    $self->[UA_TOOLKIT]      = $extra->[0]
                             ? [ split RE_SLASH, shift @{ $extra } ]
                             : []
                             ;

    if ( @{$thing} && index($thing->[LAST_ELEMENT], 'rv:') != NO_IMATCH ) {
        $self->[UA_MOZILLA]  = pop @{ $thing };
        if ( @{ $thing } <= 3 ) {
            $self->[UA_OS] = shift @{ $thing };
            if ( $self->[UA_OS] && $self->[UA_OS] eq 'Macintosh' ) {
                $self->[UA_OS] = shift @{ $thing };
            }
            $self->[UA_LANG] = pop @{ $thing } if @{ $thing };
        }
        else {
            $self->[UA_LANG]     = pop @{ $thing };
            $self->[UA_OS]       = pop @{ $thing };
        }
    }

    $self->[UA_EXTRAS] = [
        grep { $_ }
        @{ $thing },
        @others,
        $extra ? @{ $extra } : (),
    ];
    return 1;
}

sub _parse_gecko {
    my($self, $moz, $thing, $extra, @others) = @_;
    $self->_parse_mozilla_family($moz, $thing, $extra, @others);

    # we got some name & version
    if ( $self->[UA_NAME] && $self->[UA_VERSION_RAW] ) {
        # Change SeaMonkey too?
        my $before = $self->[UA_NAME];
        $self->[UA_NAME]   = 'Netscape' if $self->[UA_NAME] eq 'Netscape6';
        $self->[UA_NAME]   = 'Mozilla'  if $self->[UA_NAME] eq 'Beonex';
        $self->[UA_PARSER] = 'mozilla_family:generic';
        my @buf;

        foreach my $e ( @{ $self->[UA_EXTRAS] } ) {
            next if ! $e;
            if ( my $s = $self->_is_strength($e) ) {
                $self->[UA_STRENGTH] = $s;
                next;
            }
            if ( $e =~ RE_IX86 ) {
                my($os,$lang) = split RE_COMMA, $e;
                $self->[UA_OS]   = $os   if $os;
                $self->[UA_LANG] = $self->trim($lang) if $lang;
                next;
            }
            if ( ! $self->[UA_OS] && $e =~ m{ Win(?:NT|dows) }xmsi ) {
                $self->[UA_OS] = $e;
                next;
            }
            if ( $e =~ RE_TWO_LETTER_LANG ) {
                $self->[UA_LANG] = $e;
                next;
            }
            if ( $e =~ RE_EPIPHANY_GECKO ) {
                $self->[UA_NAME]        = $before = $1;
                $self->[UA_VERSION_RAW] = $2;
            }
            push @buf, $e;
        }

        $self->[UA_EXTRAS]        = [ @buf ];
        $self->[UA_ORIGINAL_NAME] = $before if $before ne $self->[UA_NAME];
        $self->_fix_windows_nt;
        return 1 ;
    }

    if ( $self->[UA_TOOLKIT] && $self->[UA_TOOLKIT][TK_NAME] eq 'Gecko' ) {
        ($self->[UA_NAME], $self->[UA_VERSION_RAW]) = split RE_SLASH, $moz;
        if ( $self->[UA_NAME] && $self->[UA_VERSION_RAW] ) {
            $self->[UA_PARSER] = 'mozilla_family:gecko';
            return 1;
        }
    }

    return;
}

sub _fix_os_lang {
    my $self = shift;
    if ( $self->[UA_OS] && length $self->[UA_OS] == 2 ) {
        $self->[UA_LANG] = $self->[UA_OS];
        $self->[UA_OS]   = undef;
    }
    return;
}

sub _fix_windows_nt {
    my $self    = shift;
    my $skip_os = shift; # ie os can be undef
    my $os      = $self->[UA_OS] || q{};
    return if ( ! $os              && ! $skip_os )
        ||    (   $os ne 'windows' && ! $skip_os )
        ||      ! $self->[UA_EXTRAS][0]
        ||        $self->[UA_EXTRAS][0] !~ m{ NT\s?(\d.*?) \z }xmsi;
    $self->[UA_EXTRAS][0] = $self->[UA_OS]; # restore
    $self->[UA_OS] = "Windows NT $1"; # fix
    return;
}

sub _parse_netscape {
    my($self, $moz, $thing) = @_;
    my($mozx, $junk)    = split RE_WHITESPACE, $moz;
    my(undef, $version) = split RE_SLASH     , $mozx;
    my @buf;
    foreach my $e ( @{ $thing } ) {
        if ( my $s = $self->_is_strength($e) ) {
            $self->[UA_STRENGTH] = $s;
            next;
        }
        push @buf, $e;
    }
    $self->[UA_VERSION_RAW] = $version;
    $self->[UA_OS]          = $buf[0] eq 'X11' ? pop @buf : shift @buf;
    $self->[UA_NAME]        = 'Netscape';
    $self->[UA_EXTRAS]      = [ @buf ];
    if ( $junk ) {
        $junk =~ s{ \[ (.+?) \] .* \z}{$1}xms;
        $self->[UA_LANG] = $junk if $junk;
    }
    $self->[UA_PARSER] = 'netscape';
    return 1;
}

sub _generic_moz_thing {
    my($self, $moz, $t, $extra, $compatible, @others) = @_;
    return if ! @{ $t };
    my($mname, $mversion, @rest) = split RE_CHAR_SLASH_WS, $moz;
    return if $mname eq 'Mozilla' || $mname eq 'Emacs-W3';

    $self->[UA_NAME]        = $mname;
    $self->[UA_VERSION_RAW] = $mversion || ( $mname eq 'Links' ? shift @{$t} : 0 );
    $self->[UA_OS] = @rest                                     ? join(q{ }, @rest)
                   : $t->[0] && $t->[0] !~ RE_DIGIT_DOT_DIGIT  ? shift @{$t}
                   :                                             undef;
    my @extras = (@{$t}, $extra ? @{$extra} : (), @others );

    $self->_fix_generic(
        \$self->[UA_OS], \$self->[UA_NAME], \$self->[UA_VERSION_RAW], \@extras
    );

    $self->[UA_EXTRAS]      = [ @extras ] if @extras;
    $self->[UA_GENERIC]     = 1;
    $self->[UA_PARSER]      = 'generic_moz_thing';

    return 1;
}

sub _generic_name_version {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my $ok = $moz && ! @{$thing} && ! $extra && ! $compatible && ! @others;
    return if not $ok;

    my @moz = split RE_WHITESPACE, $moz;
    if ( @moz == 1 ) {
        my($name, $version) = split RE_SLASH, $moz;
        if ($name && $version) {
            $self->[UA_NAME]        = $name;
            $self->[UA_VERSION_RAW] = $version;
            $self->[UA_GENERIC]     = 1;
            $self->[UA_PARSER]      = 'generic_name_version';
            return 1;
        }
    }
    return;
}

sub _generic_compatible {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my @orig_thing = @{ $thing }; # see edge case below

    return if ! ( $compatible && @{$thing} );

    my($mname, $mversion) = split RE_CHAR_SLASH_WS, $moz;
    my($name, $version)   = $mname eq 'Mozilla'
                          ? split( RE_CHAR_SLASH_WS, shift @{ $thing } )
                          : ($mname, $mversion)
                          ;
    shift @{$thing} if  $thing->[0] &&
                      ( $thing->[0] eq $name || $thing->[0] eq $moz);
    my $os     = shift @{$thing};
    my $lang   = pop   @{$thing};
    my @extras;

    if ( $name eq 'MSIE') {
        if ( $self->_is_generic_bogus_ie( $extra ) ) {
            # edge case
            my($n, $v) = split RE_WHITESPACE, shift @orig_thing;
            my $e = [ split RE_SC_WS, join q{ }, @{ $extra } ];
            my $t = \@orig_thing;
            push @{ $e }, grep { $_ } map { split RE_SC_WS, $_ } @others;
            $self->_parse_msie( $moz, $thing, $e, $n, $v );
            return 1;
        }
        elsif ( $extra ) { # Sleipnir?
            ($name, $version)   = split RE_SLASH, pop @{$extra};
            my($extras,$dotnet) = $self->_extract_dotnet( $thing, $extra );
            $self->[UA_DOTNET]  = [ @{$dotnet} ] if @{$dotnet};
            @extras = (@{ $extras }, @others);
        }
        else {
            return if index($moz, q{ }) != NO_IMATCH; # WebTV
        }
    }

    @extras = (@{$thing}, $extra ? @{$extra} : (), @others ) if ! @extras;

    $self->_fix_generic( \$os, \$name, \$version, \@extras );

    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version || 0;
    $self->[UA_OS]          = $os;
    $self->[UA_LANG]        = $lang;
    $self->[UA_EXTRAS]      = [ @extras ] if @extras;
    $self->[UA_GENERIC]     = 1;
    $self->[UA_PARSER]      = 'generic_compatible';

    return 1;
}

sub _parse_emacs {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my @moz = split RE_WHITESPACE, $moz;
    my $emacs = shift @moz;
    my($name, $version) = split RE_SLASH, $emacs;
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version || 0;
    $self->[UA_OS]          = shift @{ $thing };
    $self->[UA_OS]          = $self->trim( $self->[UA_OS] ) if $self->[UA_OS];
    my @rest = (  @{ $thing }, @moz );
    push @rest, @{ $extra } if $extra && ref $extra eq 'ARRAY';
    push @rest, ( map { split RE_SC_WS, $_ } @others ) if @others;
    $self->[UA_EXTRAS]      = [ grep { $_ } map { $self->trim( $_ ) } @rest ];
    $self->[UA_PARSER]      = 'emacs';
    return 1;
}

sub _parse_moz_only {
    my($self, $moz) = @_;
    my @parts = split RE_WHITESPACE, $moz;
    my $id = shift @parts;
    my($name, $version) = split RE_SLASH, $id;
    if ( $name eq 'Mozilla' && @parts ) {
        ($name, $version) = split RE_SLASH, shift @parts;
        return if ! $name || ! $version;
    }
    $self->[UA_NAME]        = $name;
    $self->[UA_VERSION_RAW] = $version || 0;
    $self->[UA_EXTRAS]      = [ @parts ];
    $self->[UA_PARSER]      = 'moz_only';
    return 1;
}

sub _parse_hotjava {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    my $parsable            = shift @{ $thing };
    my($name, $version)     = split RE_SLASH, $moz;
    $self->[UA_NAME]        = 'HotJava';
    $self->[UA_VERSION_RAW] = $version || 0;
    if ( $parsable ) {
        my @parts = split m{[\[\]]}xms, $parsable;
        if ( @parts > 2 ) {
            @parts = map { $self->trim( $_ ) } @parts;
            $self->[UA_OS]     = pop @parts;
            $self->[UA_LANG]   = pop @parts;
            $self->[UA_EXTRAS] = [ @parts ];
        }
    }
    return 1;
}

sub _parse_docomo {
    my($self, $moz, $thing, $extra, $compatible, @others) = @_;
    if ( $thing->[0] && index(lc $thing->[0], 'googlebot-mobile') != NO_IMATCH ) {
        my($name, $version)     = split RE_SLASH, shift @{ $thing };
        $self->[UA_NAME]        = $name;
        $self->[UA_VERSION_RAW] = $version;
        $self->[UA_EXTRAS]      = [ @{ $thing } ];
        $self->[UA_MOBILE]      = 1;
        $self->[UA_ROBOT]       = 1;
        $self->[UA_PARSER]      = 'docomo';
        return 1;
    }
    #$self->[UA_PARSER] = 'docomo';
    #require Data::Dumper;warn "DoCoMo unsupported: ".Data::Dumper::Dumper( [ $moz, $thing, $extra, $compatible, \@others ] );
    return;
}

1;

__END__

=pod

=head1 NAME

Parse::HTTP::UserAgent::Base::Parsers - Base class

=head1 DESCRIPTION

This document describes version C<0.39> of C<Parse::HTTP::UserAgent::Base::Parsers>
released on C<2 December 2013>.

Internal module.

=head1 SEE ALSO

L<Parse::HTTP::UserAgent>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut

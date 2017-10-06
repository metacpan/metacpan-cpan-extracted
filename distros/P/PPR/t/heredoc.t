use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


use PPR;

local $/ = "\n
####\n";
while ( my $source = readline *DATA ) {
    chomp $source;

    my $matched
        = $source =~ m{ \A (?&PerlOWS) (?&PerlBlock) (?&PerlOWS) \Z $PPR::GRAMMAR }xms;

    ok $matched             => "Matched heredoc'd block $.";
    diag $source if !$matched;
}

done_testing();

__DATA__
{
    say <<'END', '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<~    "END"
        Heredoc text
        }
        More text
        END
    , $foo, <<'ETC', '...';
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<`END`, '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<"END", '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<END, '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<~END, '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<\END, '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<~\END, '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<~`END`, '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<~'END', '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<~"END", '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<    'END', '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<    `END`, '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<    "END", '...';
Heredoc text
    END
}
More text
END
    say 'done';
}

####
{
    say <<~    'END', '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<~    `END`, '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<~    "END", '...';
        Heredoc text
        }
        More text
        END
    say 'done';
}

####
{
    say <<'END', '...', <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<`END`, $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<"END", $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<END, $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~END, $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    say 'done';
    et
    cetera
ETC
}

####
{
    say <<\END, $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~\END, $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~`END`, $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~'END', $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~"END", $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<    'END', $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<    `END`, $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<    "END", $foo, <<'ETC', '...';
Heredoc text
    END
}
More text
END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~    'END', $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~    `END`, $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~    "END", $foo, <<'ETC', '...';
        Heredoc text
        }
        More text
        END
    et
    cetera
ETC
    say 'done';
}

####
{
    say <<~    "END",
        Heredoc text
        }
        More text
        END
    $foo, <<'ETC', '...';
    et
    cetera
ETC
    say 'done';
}

####

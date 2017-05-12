#!perl -T
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/01-test.t
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Software-License-OrLaterPack.
#
#   perl-Software-License-OrLaterPack is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Software-License-OrLaterPack is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Software-License-OrLaterPack. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use Test::More;
use Scalar::Util qw{ blessed };

#   Licenses to test.
my %licenses = (
    # Module name  # Full license name
    AGPL    => 'GNU Affero General Public License',
    GPL     => 'GNU General Public License',
    LGPL    => 'GNU Lesser General Public License',
);
my @modules = qw{ AGPL_3 GPL_1 GPL_2 GPL_3 LGPL_2_1 LGPL_3_0 };

plan tests => @modules * 27;

foreach my $mod ( @modules ) {

    diag( "Checking $mod..." );

    $mod =~ m{\A([A-Z]+)_([0-9_]+)\z} or die;   # $mod is a license module name, e. g. `LGPL_2_1`.

    my ( $abbr, $ver ) = ( $1, $2 );             # $abbr is a license short name, e. g. `LGPL`.
    $ver =~ s{_}{.}g;                           # $ver is a license version, e. g. `2.1`.

    my $super = "Software::License::${mod}";   # Parent class name.
    my $class = "${super}::or_later";          # Our license class name.

    use_ok( $super ) or next;
    use_ok( $class ) or next;

    my $s = new_ok( $super => [ { holder => 'John Doe', year => '2010' } ] );
    my $l = new_ok( $class => [ { holder => 'John Doe', year => '2010' } ] );

    is( $l->_abbr,   $abbr,              'bare abbr' );
    is( $l->abbr,    "${abbr}v${ver}+",  'abbr' );
    is( $l->_name,   $licenses{ $abbr }, 'bare name' );
    is( $l->name,    "The $licenses{ $abbr } version $ver or later", 'name' );
    is( $l->program, "this program",     'default program' );
    is( $l->Program, "This program",     'default Program' );
    {
        local $l->{ program } = 'assa';
        is( $l->program, "assa",     'non-default program' );
        is( $l->Program, "assa",     'computed Program' );
    }
    {
        local $l->{ Program } = 'ASSA';
        is( $l->Program, "ASSA",     'non-default Program' );
        is( $l->program, "ASSA",     'computed program' );
    }
    {
        local $l->{ program } = 'assa';
        local $l->{ Program } = 'Assa';
        is( $l->program, "assa",     'explicit program' );
        is( $l->Program, "Assa",     'explicit Program' );
    }
    is( $l->version,  "${ver}+", 'version' );

    my $b = $l->base;
    is( blessed( $b ), $super,    'base blessed' );
    is( $b->holder,  $l->holder,  'base holder'  );
    is( $b->year,    $l->year,    'base year'    );
    is( $b->name,    $s->name,    'base name'    );
    is( $b->version, $s->version, 'base version' );

    #   Verify notice. Standard `Software::Licence` notice looks like
    #
    #       This software is Copyright (c) YEAR by HOLDER.
    #
    #       This is free software, licensed under:
    #
    #           license name
    #
    #   Our notice is copyright statement is standard GNU notice:
    #
    #       Copyright (C) YEAR HOLDER
    #
    #       PROGRAM is free software: you can redistribute it and/or modify it under the terms
    #       of the LICENSE as published by the Free Software Foundation, either version 3 of the
    #       License, or (at your option) any later version.
    #
    #       PROGRAM is distributed in the hope that it will be useful, but WITHOUT ANY
    #       WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
    #       PARTICULAR PURPOSE.  See the LICENSE for more details.
    #
    #       You should have received a copy of the LICENSE along with PROGRAM.  If not, see
    #       <http://www.gnu.org/licenses/>.
    #
    #   where *LICENSE* is the name of particular license, and *PROGARM* is a name of program
    #   ("this program" by default).
    #

    my %RE;

    #   We cannot search for plain license name because it may be wrapped across lines. Let us
    #   construct regexp by replacing every space in the license name with `\s+`:
    $RE{ license } = $licenses{ $abbr };
    $RE{ license } =~ s{ }{\\s+}g;

    $RE{ tail1 } = qr{
        \s is \s free \s software: \s you \s can \s redistribute \s it \s and/or \s modify \s it \s
        under \s the \s terms \s of \s the \s $RE{ license } \s as \s published \s by \s the \s
        Free \s Software \s Foundation, \s either \s version \s \Q$ver\E \s of \s the \s License,
        \s or \s \(at \s your \s option\) \s any \s later \s version\. \n
    }x;
    $RE{ tail2 } = qr{
        \s is \s distributed \s in \s the \s hope \s that \s it \s will \s be \s useful, \s but \s
        WITHOUT \s ANY \s WARRANTY; \s without \s even \s the \s implied \s warranty \s of \s
        MERCHANTABILITY \s or \s FITNESS \s FOR \s A \s PARTICULAR \s PURPOSE\. \s See \s the \s
        $RE{ license } \s for \s more \s details\. \n
    }x;
    $RE{ head3 } = qr{
        You \s should \s have \s received \s a \s copy \s of \s the \s $RE{ license } \s along \s
        with \s
    }x;
    $RE{ tail3 } = qr{
        \. \s If \s not, \s see \s \Q<http://www.gnu.org/licenses/>\E\. \n
    }x;

    like(
        $l->notice,
        qr{
            \A
            \QCopyright (C) 2010 John Doe\E \n
            \n
            This \s program $RE{ tail1 }
            \n
            This \s program $RE{ tail2 }
            \n
            $RE{ head3 } this \s program $RE{ tail3 }
            \z
        }sx,
        'Notice with default program name',
    );

    like(
        do {
            local $l->{ program } = 'that program';
            local $l->{ Program } = 'That program';
            $l->notice();
        },
        qr{
            \A
            \QCopyright (C) 2010 John Doe\E \n
            \n
            That \s program $RE{ tail1 }
            \n
            That \s program $RE{ tail2 }
            \n
            $RE{ head3 } that \s program $RE{ tail3 }
            \z
        }sx,
        'Notice with explicit program and Program',
    );

    like(
        do {
            local $l->{ program } = 'perl-Foo';
            $l->notice();
        },
        qr{
            \A
            \QCopyright (C) 2010 John Doe\E \n
            \n
            perl-Foo $RE{ tail1 }
            \n
            perl-Foo $RE{ tail2 }
            \n
            $RE{ head3 } perl-Foo $RE{ tail3 }
            \z
        }sx,
        'Notice with explicit program',
    );

    like(
        do {
            local $l->{ program } = 'perl-Bar';
            $l->notice();
        },
        qr{
            \A
            \QCopyright (C) 2010 John Doe\E \n
            \n
            perl-Bar $RE{ tail1 }
            \n
            perl-Bar $RE{ tail2 }
            \n
            $RE{ head3 } perl-Bar $RE{ tail3 }
            \z
        }sx,
        'Notice with explicit Program',
    );

    # Shorter note.
    like(
        $l->notice( 'short' ),
        qr{
            \A
            \QCopyright (C) 2010 John Doe\E \n
            \n
            \QLicense ${abbr}v${ver}+:\E \s The \s $RE{ license } \s version \s \Q$ver\E \s
                or \s later \s <http://www\.gnu\.org/licenses/[^>]+>\. \n
            \n
            This \s is \s free \s software: \s you \s are \s free \s to \s change \s and \s
            redistribute \s it. \s There \s is \s NO \s WARRANTY, \s to \s the \s extent \s
            permitted \s by \s law. \s
            \Z
        }sx,
        'Short notice'
    );

};

# end of file #

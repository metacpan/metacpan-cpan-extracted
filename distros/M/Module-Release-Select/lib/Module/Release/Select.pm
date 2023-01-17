package Module::Release::Select;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

require String::Escape;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-15'; # DATE
our $DIST = 'Module-Release-Select'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       $RE
                       parse_releases_expr
                       select_releases
                       select_release
               );

sub _remove_space {
    my $str = shift;
    $str =~ s/\s+//g;
    $str;
}

sub _parse_regexp {
    require Regexp::Util;
    my $str = shift;
    my $re = Regexp::Util::deserialize_regexp("qr".$str."i");
    die "Regexp '$str' contains eval" if Regexp::Util::regexp_seen_evals($re);
    $re;
}

sub _parse_date {
    require DateTime::Format::Natural;
    my $str = shift;
    my $dt = DateTime::Format::Natural->new->parse_datetime($str);
    die "Unknown datetime expression $str" unless defined $dt;
    $dt;
}
sub _parse_string {
    require String::Escape;
    my $str = shift;
    {literal=>String::Escape::unqqbackslash($str)};
}

our $RE =
    qr{
          (?&EXPR) (?{ $_ = $^R->[1] })
          #(?&SIMPLE_EXPR) (?{ $_ = $^R->[1] })

          (?(DEFINE)
              (?<EXPR>
                  (?{ [$^R, []] })
                  (?&AND_EXPR)
                  (?{ [$^R->[0][0], [$^R->[1]]] })
                  (?:
                      \s*[,|]\s*
                      (?&AND_EXPR)
                      (?{
                          push @{$^R->[0][1]}, $^R->[1];
                          $^R->[0];
                      })
                  )*
                  \s*
              ) # EXPR

              (?<AND_EXPR>
                  (?{ [$^R, []] })
                  (?&SIMPLE_EXPR)
                  (?{ [$^R->[0][0], [$^R->[1]]] })
                  (?:
                      \s*[&]\s*
                      (?&SIMPLE_EXPR)
                      (?{
                          push @{$^R->[0][1]}, $^R->[1];
                          $^R->[0];
                      })
                  )*
                  \s*
              ) # AND_EXPR

              (?<SIMPLE_EXPR>
                  (?:
                      (?:
                          # ver_comp
                          (?: version \s*)?
                          ((?&OP))? \s*
                          (?{ [$^R, {type=>"version", op=> $^N // "=" }] })
                          (?:
                              ((?&VER_VALUE))
                              (?{ $^R->[0][1]{val} = $^R->[1]; $^R->[0] })
                          |
                              ((?&REGEX))
                              (?{ $^R->[0][1]{val} = $^R->[1]; $^R->[0] })
                          )
                      )
                  |
                      (?:
                          # date_comp
                          date \s*
                          ((?&OP)) \s*
                          (?{ [$^R, {type=>"date", op=> $^N }] })
                          (?:
                              # DATE_VALUE
                              \{ ([^\{]+) \}
                              (?{ $^R->[1]{val} = {datetime=>_parse_date($^N)}; $^R })
                          |
                              ((?&REGEX))
                              (?{ $^R->[0][1]{val} = $^R->[1]; $^R->[0] })
                          )
                      )
                  |
                      (?:
                          # author_comp
                          author \s*
                          ((?&OP)) \s*
                          (?{ [$^R, {type=>"author", op=> $^N }] })
                          (?:
                              # STR_VALUE
                              (\" (?:[^"]+|\\\\|\\")* \")
                              (?{ $^R->[1]{val} = _parse_string($^N); $^R })
                          |
                              ((?&REGEX))
                              (?{ $^R->[0][1]{val} = $^R->[1]; $^R->[0] })
                          )
                      )
                  )
              ) # SIMPLE_EXPR

              (?<OP>
                  =|!=|<|>|<=|>=|=~|!~
              )

              (?<VER_VALUE>
                  ((?&VER_LITERAL)) \s*
                  (?{ [$^R, {literal=>$^N, offset=>0}] })
                  (?:
                      \s* ([+-] \s* [0-9]+) \s*
                      (?{ $^R->[1]{offset} = _remove_space($^N); $^R })
                  )?
              )

              (?<REGEX>
                  (/(?:[^/]+|\\/)*/)
                  (?{ [$^R, {regexp=>_parse_regexp($^N)}] })
              )

              (?<VER_LITERAL>
                  (
                      v?
                      (
                          [0-9]+(?:\.[0-9]+)+(?:_[0-9]+)
                      |
                          [0-9]+(?:\.[0-9]+)*
                      )
                  )
              |   latest
              |   oldest
              ) # VER_LITERAL

          ) # DEFINE
  }x;

sub parse_releases_expr {
    state $re = qr{\A\s*$RE\s*\z};

    local $_ = shift;
    local $^R;
    eval { $_ =~ $re } and return $_;
    die $@ if $@;
    return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
}

sub _get_verobj {
    my ($pver, $rels) = @_;
    my ($ver0, $verobj0, $index0);
    if ($pver->{literal} eq 'latest') {
        $index0 = 0;
        $ver0 = $rels->[0]{version};
        $verobj0 = version->parse($ver0);
    } elsif ($pver->{literal} eq 'oldest') {
        $index0 = $#{$rels};
        $ver0 = $rels->[-1]{version};
        $verobj0 = version->parse($ver0);
    } else {
        eval { $verobj0 = version->parse($pver->{literal}) };
        die "Invalid version literal '$pver->{literal}': $@" if $@;
        for my $i (0 .. $#{$rels}) {
            my $verobj2 = version->parse($rels->[$i]{version});
            if ($verobj2 == $verobj0) {
                $index0 = $i;
                $ver0 = $rels->[$i]{version};
                last;
            }
        }
    }

    return ($ver0, $verobj0) unless $pver->{offset};
    die "Can't compute version $pver->{literal} ".
        ($pver->{offset} > 0 ? "+ $pver->{offset}" : "- ".abs($pver->{offset})).
        " because that version is not found in releases"
        unless defined $index0;
    my $index = $index0 - $pver->{offset};
    if ($index < 0) {
        warn "There are no releases newer than (".
            abs($pver->{offset})." release(s) ".($pver->{offset} > 0 ? "after" : "before")." $pver->{literal}".
            "), will be using the newest release ($rels->[0]{version})";
        $index = 0;
    } elsif ($index > $#{$rels}) {
        warn "There are no releases older than (".
            abs($pver->{offset})." release(s) ".($pver->{offset} > 0 ? "before" : "after")." $pver->{literal}".
            "), will be using the oldest release ($rels->[-1]{version})";
        $index = $#{$rels};
    }
    ($rels->[$index]{version}, version->parse($rels->[$index]{version}));
}

sub select_releases {
    my $opts = ref $_[0] eq 'HASH' ? {%{shift @_}} : {};
    my $expr = shift;
    my $rels = [ map {ref $_ eq 'HASH' ? $_ : {version=>$_}} @{ shift @_ }];

  CHECK_RELEASES:
    {
        my $last_verobj;
        for my $i (0..$#{$rels}) {
            my $rel = $rels->[$i];
            if (!defined($rel->{version})) {
                die "releases[$i]: No version defined";
            }
            my $verobj;
            eval { $verobj = version->parse($rel->{version}) };
            if ($@) {
                die "releases[$i]: Invalid version '$rel->{version}': $@";
            }
            if (defined $last_verobj) {
                unless ($verobj < $last_verobj) {
                    die "releases[$i]: Not older than previous record; releases must contain release in descending order";
                }
            }
            $last_verobj = $verobj;
        }
    }

    my $pexpr = parse_releases_expr($expr); # "p" = parsed
    die "Can't parse releases expr '$expr'" unless defined $pexpr;

    return unless @$rels;

    my @selected_and_rels;
    for my $and_pexpr (@$pexpr) {
        my @selected_comp_rels = @$rels;
        for my $comp_pexpr (@$and_pexpr) {
            my $type = $comp_pexpr->{type};
            my $op   = $comp_pexpr->{op};
            my $code;
            if ($type eq 'version') {
                if ($op eq '=') {
                    die "Version literal expected after '='" unless defined $comp_pexpr->{val}{literal};
                    my ($ver, $verobj) = _get_verobj($comp_pexpr->{val}, $rels);
                    $code = sub { version->parse($_[0]{version}) == $verobj };
                } elsif ($op eq '!=') {
                    die "Version literal expected after '!='" unless defined $comp_pexpr->{val}{literal};
                    my ($ver, $verobj) = _get_verobj($comp_pexpr->{val}, $rels);
                    $code = sub { version->parse($_[0]{version}) != $verobj };
                } elsif ($op eq '>') {
                    die "Version literal expected after '='" unless defined $comp_pexpr->{val}{literal};
                    my ($ver, $verobj) = _get_verobj($comp_pexpr->{val}, $rels);
                    $code = sub { version->parse($_[0]{version}) > $verobj };
                } elsif ($op eq '>=') {
                    die "Version literal expected after '='" unless defined $comp_pexpr->{val}{literal};
                    my ($ver, $verobj) = _get_verobj($comp_pexpr->{val}, $rels);
                    $code = sub { version->parse($_[0]{version}) >= $verobj };
                } elsif ($op eq '<') {
                    die "Version literal expected after '='" unless defined $comp_pexpr->{val}{literal};
                    my ($ver, $verobj) = _get_verobj($comp_pexpr->{val}, $rels);
                    $code = sub { version->parse($_[0]{version}) < $verobj };
                } elsif ($op eq '<=') {
                    die "Version literal expected after '='" unless defined $comp_pexpr->{val}{literal};
                    my ($ver, $verobj) = _get_verobj($comp_pexpr->{val}, $rels);
                    $code = sub { version->parse($_[0]{version}) <= $verobj };
                } elsif ($op eq '=~') {
                    die "Regexp expected after '=~'" unless defined $comp_pexpr->{val}{regexp};
                    $code = sub { $_[0]{version} =~ $comp_pexpr->{val}{regexp} };
                } elsif ($op eq '!~') {
                    die "Regexp expected after '=~'" unless defined $comp_pexpr->{val}{regexp};
                    $code = sub { $_[0]{version} =~ $comp_pexpr->{val}{regexp} };
                } else {
                    die "BUG: Unknown operator '$op'";
                }
            } elsif ($type eq 'author') {
                if ($op eq '=') {
                    die "String literal expected after '='" unless defined $comp_pexpr->{val}{literal};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; lc($_[0]{author}) eq lc($comp_pexpr->{val}{literal}) };
                } elsif ($op eq '!=') {
                    die "String literal expected after '!='" unless defined $comp_pexpr->{val}{literal};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; lc($_[0]{author}) ne lc($comp_pexpr->{val}{literal}) };
                } elsif ($op eq '>') {
                    die "String literal expected after '>'" unless defined $comp_pexpr->{val}{literal};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; lc($_[0]{author}) gt lc($comp_pexpr->{val}{literal}) };
                } elsif ($op eq '>=') {
                    die "String literal expected after '>='" unless defined $comp_pexpr->{val}{literal};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; lc($_[0]{author}) ge lc($comp_pexpr->{val}{literal}) };
                } elsif ($op eq '<') {
                    die "String literal expected after '<'" unless defined $comp_pexpr->{val}{literal};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; lc($_[0]{author}) lt lc($comp_pexpr->{val}{literal}) };
                } elsif ($op eq '<=') {
                    die "String literal expected after '<='" unless defined $comp_pexpr->{val}{literal};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; lc($_[0]{author}) le lc($comp_pexpr->{val}{literal}) };
                } elsif ($op eq '=~') {
                    die "Regexp expected after '=~'" unless defined $comp_pexpr->{val}{regexp};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; $_[0]{author} =~ $comp_pexpr->{val}{regexp} };
                } elsif ($op eq '!~') {
                    die "Regexp expected after '=~'" unless defined $comp_pexpr->{val}{regexp};
                    $code = sub { die "Release $_[0]{version} does not have author" unless defined $_[0]{author}; $_[0]{author} !~ $comp_pexpr->{val}{regexp} };
                } else {
                    die "BUG: Unknown operator '$op'";
                }
            } elsif ($type eq 'date') {
                require DateTime;
                require DateTime::Format::Natural;
                if ($op eq '=') {
                    die "Date literal expected after '='" unless defined $comp_pexpr->{val}{datetime};
                    $code = sub { my $dt0 = $_[0]{date}; die "Release $_[0]{version} does not have date" unless defined $dt0; my $dt = DateTime::Format::Natural->new->parse_datetime($dt0) or die "Can't parse date literal '$dt0'"; DateTime->compare($dt, $comp_pexpr->{val}{datetime}) == 0 };
                } elsif ($op eq '!=') {
                    die "Date literal expected after '='" unless defined $comp_pexpr->{val}{datetime};
                    $code = sub { my $dt0 = $_[0]{date}; die "Release $_[0]{version} does not have date" unless defined $dt0; my $dt = DateTime::Format::Natural->new->parse_datetime($dt0) or die "Can't parse date literal '$dt0'"; DateTime->compare($dt, $comp_pexpr->{val}{datetime}) != 0 };
                } elsif ($op eq '>') {
                    die "Date literal expected after '='" unless defined $comp_pexpr->{val}{datetime};
                    $code = sub { my $dt0 = $_[0]{date}; die "Release $_[0]{version} does not have date" unless defined $dt0; my $dt = DateTime::Format::Natural->new->parse_datetime($dt0) or die "Can't parse date literal '$dt0'"; DateTime->compare($dt, $comp_pexpr->{val}{datetime}) > 0 };
                } elsif ($op eq '>=') {
                    die "Date literal expected after '='" unless defined $comp_pexpr->{val}{datetime};
                    $code = sub { my $dt0 = $_[0]{date}; die "Release $_[0]{version} does not have date" unless defined $dt0; my $dt = DateTime::Format::Natural->new->parse_datetime($dt0) or die "Can't parse date literal '$dt0'"; DateTime->compare($dt, $comp_pexpr->{val}{datetime}) >= 0 };
                } elsif ($op eq '<') {
                    die "Date literal expected after '='" unless defined $comp_pexpr->{val}{datetime};
                    $code = sub { my $dt0 = $_[0]{date}; die "Release $_[0]{version} does not have date" unless defined $dt0; my $dt = DateTime::Format::Natural->new->parse_datetime($dt0) or die "Can't parse date literal '$dt0'"; DateTime->compare($dt, $comp_pexpr->{val}{datetime}) < 0 };
                } elsif ($op eq '<=') {
                    die "Date literal expected after '='" unless defined $comp_pexpr->{val}{datetime};
                    $code = sub { my $dt0 = $_[0]{date}; die "Release $_[0]{version} does not have date" unless defined $dt0; my $dt = DateTime::Format::Natural->new->parse_datetime($dt0) or die "Can't parse date literal '$dt0'"; DateTime->compare($dt, $comp_pexpr->{val}{datetime}) <= 0 };
                } elsif ($op eq '=~') {
                    die "Regexp expected after '=~'" unless defined $comp_pexpr->{val}{regexp};
                    $code = sub { die "Release $_[0]{version} does not have date" unless defined $_[0]{date}; $_[0]{date} =~ $comp_pexpr->{val}{regexp} };
                } elsif ($op eq '!~') {
                    die "Regexp expected after '=~'" unless defined $comp_pexpr->{val}{regexp};
                    $code = sub { die "Release $_[0]{version} does not have date" unless defined $_[0]{date}; $_[0]{date} !~ $comp_pexpr->{val}{regexp} };
                } else {
                    die "BUG: Unknown operator '$op'";
                }
            } else {
                die "BUG: Unknown comparison type '$type'";
            }

            @selected_comp_rels = grep { $code->($_) } @selected_comp_rels;
            #use Data::Dmp (); use DD; print "result of selecting ".Data::Dmp::dmp($comp_pexpr).": "; dd \@selected_comp_rels;
        } # for comp_pexpr

      L1:
        for my $rel (@selected_comp_rels) {
            # do not add if already added
            for (@selected_and_rels) { last L1 if "$_" eq "$rel" }
            push @selected_and_rels, $rel;
        }
    } # for and_expr

    # sort
    @selected_and_rels = sort { version->parse($b->{version}) <=> version->parse($a->{version}) } @selected_and_rels;

    if ($opts->{single}) {
        if ($opts->{oldest}) {
            @selected_and_rels = @selected_and_rels ? ($selected_and_rels[-1]) : ();
        } else {
            @selected_and_rels = @selected_and_rels ? ($selected_and_rels[0]) : ();
        }
    }

    if ($opts->{detail}) {
        @selected_and_rels;
    } else {
        map {$_->{version}} @selected_and_rels;
    }
}

sub select_release {
    my $opts = ref $_[0] eq 'HASH' ? {%{shift @_}} : {};
    my $expr = shift;
    my $rels = shift;

    $opts->{single} = 1;
    my @rels = select_releases($opts, $expr, $rels);
    return undef unless @rels; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    $rels[0];
}

1;
# ABSTRACT: Notation to select release(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Release::Select - Notation to select release(s)

=head1 VERSION

This document describes version 0.002 of Module::Release::Select (from Perl distribution Module-Release-Select), released on 2023-01-15.

=head1 SYNOPSIS

 use Module::Release::Select qw(select_release select_releases);

 my @releases = (0.005, 0.004, 0.003, 0.002, 0.001);

 my $rel = select_release('0.002', \@releases);       # => 0.002
 my $rel = select_release('0.002 + 1', \@releases);   # => 0.003
 my $rel = select_release('> 0.002', \@releases);     # => 0.005
 my $rel = select_release('latest', \@releases);      # => 0.005
 my $rel = select_release('latest-1', \@releases);    # => 0.004

 my @rels = select_releases('> oldest', \@releases);  # => (0.005, 0.004, 0.003, 0.002)

=head1 DESCRIPTION

This module lets you select one or more releases via an expression. Some example
expressions:

 # exact version number ('=')
 0.002
 =0.002     # ditto

 # version number range with '>', '>=', '<', '<=', '!='. use '&' to join
 # multiple conditions with "and" logic, use '|' or ',' to join with "or" logic.
 >0.002
 >=0.002
 >=0.002 & <=0.015
 <0.002 | >0.015
 0.001, 0.002, 0.003

 # "latest" and "oldest" can replace version number
 latest
 =latest
 <latest           # all releases except the latest
 != latest         # ditto
 >oldest           # all releases except the oldest

 # +n and -m to refer to n releases after and n releases before
 latest-1       # the release before the latest
 0.002 + 1      # the release after 0.002
 > (oldest+1)   # all releases except the oldest and one after that (oldest+1)

 # select by date, any date supported by DateTime::Format::Natural is supported
 date < {yesterday}      # all releases released 2 days ago
 date > {2 months ago}   # all releases after 2 months ago

 # select by author
 author="PERLANCAR"             # all releases released by PERLANCAR
 author != "PERLANCAR"          # all releases not released by PERLANCAR
 author="PERLANCAR" & > 0.005   # all releases after 0.005 that are released by PERLANCAR

To actually select releases, you provide a list of releases in the form of
version numbers in descending order. If you want to select by date or author,
each release will need to be a hashref containing C<date> and C<author> keys.
Below is an example of a list of releases for L<App::orgadb> distribution. This
structure is returned by L<App::MetaCPANUtils>' C<list_metacpan_release>:

 my @releases = (
    {
      abstract     => "An opinionated Org addressbook toolset",
      author       => "PERLANCAR",
      date         => "2022-11-04T12:57:07",
      distribution => "App-orgadb",
      first        => "",
      maturity     => "released",
      release      => "App-orgadb-0.015",
      status       => "latest",
      version      => 0.015,
    },
    ...
    {
      abstract     => "An opinionated Org addressbook tool",
      author       => "PERLANCAR",
      date         => "2022-06-23T23:21:58",
      distribution => "App-orgadb",
      first        => "",
      maturity     => "released",
      release      => "App-orgadb-0.002",
      status       => "backpan",
      version      => 0.002,
    },
    {
      abstract     => "An opinionated Org addressbook tool",
      author       => "PERLANCAR",
      date         => "2022-06-13T00:15:18",
      distribution => "App-orgadb",
      first        => 1,
      maturity     => "released",
      release      => "App-orgadb-0.001",
      status       => "backpan",
      version      => 0.001,
    },
 );

Some examples on selecting release(s):

 # select a single release, if notation selects multiple releases, the latest
 # one will be picked. returns undef when no releases are selected.
 my $rel = select_release('0.002', \@releases);       # => 0.002
 my $rel = select_release('0.002 + 1', \@releases);   # => 0.003
 my $rel = select_release('> 0.002', \@releases);     # => 0.015

 # instead of returning the latest one when multiple releases are selected,
 # select the oldest instead.
 my $rel = select_release({oldest=>1}, '> 0.002', \@releases);     # => 0.003

 # return detailed record instead of just version
 my $rel = select_release({detail=>1}, '0.002', \@releases); # => {version=>0.002, date=>'2022-06-23T23:21:58', ...}

 # select releases, returns empty list when no releases are selected
 my $rel = select_releases('>= latest-2 & <= latest', \@releases);   # => 0.015, 0.014, 0.013

=head2 Expression grammar

 EXPR ::= AND_EXPR ( ("," | "|") AND_EXPR )*

 AND_EXPR ::= SIMPLE_EXPR ( "&" SIMPLE_EXPR )*

 SIMPLE_EXPR ::= COMP

 COMP ::= VER_COMP
        | DATE_COMP
        | AUTHOR_COMP

 VER_COMP ::= "version" OP VER_VALUE
            | OP VER_VALUE
            | VER_VALUE              ; for when OP ='='

 DATE_COMP ::= "date" OP DATE_VAL

 AUTHOR_COMP ::= "author" OP STR_VAL

 OP ::= "=" | "!=" | ">" | ">=" | "<" | "<=" | "=~" | "!~"

 VER_VALUE ::= VER_LITERAL
             | VER_OFFSET

 VER_OFFSET ::= VER_LITERAL ("+" | "-") [0-9]+

 STR_VAL ::= STR_LITERAL

 STR_LITERAL ::= '"' ( [^"\] | "\\" | "\" '"' )* '"'

 DATE_VAL ::= DATE_LITERAL

 DATE_LITERAL ::= "{" [^{]+ "}"

 VER_LITERAL ::= ("v")? [0-9]+ ( "." [0-9]+ )*
               | ("v")? [0-9]+ ( "." [0-9]+ )+ ( "_" [0-9]+ )?
               | "latest"
               | "oldest"

=head1 FUNCTIONS

=head2 parse_releases_expr

 my $parsed = parse_releases_expr($expr_str);

Parse an expression string and return parsed structure. Mostly for internal use
only.

=head2 select_releases

 my @rels = select_release( [ \%opts , ] $expr, \@releases );

Select releases from C<@releases> using expression C<$expr>. Will die on invalid
syntax in expression or on invalid entry in C<@releases>.

Known options:

=over

=item * detail

Bool. If true, will return detailed release records instead of just version
numbers.

=item * single

Bool. If true, will return only a single release instead of multiple.

=item * oldest

Bool. By default, when expression selects multiple releases and only one is
requested, the newest is returned. If this option is set to true, then the
oldest will be returned instead.

=back

=head2 select_release

Usage:

 my $rel = select_release( [ \%opts , ] $expr, \@releases );

Equivalent to C<< select_releases({%opts, single=>1}, $expr, \@releases) >>. See
L</select_releases> for more details on list of known options.

=head1 TODO

These notations are not yet supported but might be supported in the future:

 # "latest" & "oldest" can take argument
 latest(author="PERLANCAR")       # the latest release by PERLANCAR
 latest(author="PERLANCAR") + 1   # the release after the latest release by PERLANCAR
 oldest(date > {2022-10-01})      # the oldest release after 2022-10-01

 # functions

 # abstract =~ /foo/              # all releases with abstract matching a regex

 # distribution ne "App-orgadb"   # all releases with distribution not equal to "App-orgadb"

 # first is true                  # all releases with "first" key being true

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Release-Select>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Release-Select>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Release-Select>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

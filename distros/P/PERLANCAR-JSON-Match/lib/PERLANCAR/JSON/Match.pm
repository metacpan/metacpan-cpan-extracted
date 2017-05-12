package PERLANCAR::JSON::Match;

our $DATE = '2016-02-18'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

#use Data::Dumper;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(match_json);

our $MATCH_JSON = qr{

(?&VALUE) (?{ $_ = $^R->[1] if 0 })

(?(DEFINE)

(?<OBJECT>
  #(?{ [$^R, {}] })
  \{\s*
    (?: (?&KV) # [[$^R, {}], $k, $v]
    #  (?{ # warn Dumper { obj1 => $^R };
    #      die "Duplicate key '$^R->[1]'" if exists $^R->[0][1]->{$^R->[1]};
    #      [$^R->[0][0], {$^R->[1] => $^R->[2]}] })
      (?: \s*,\s* (?&KV) # [[$^R, {...}], $k, $v]
    #    (?{ # warn Dumper { obj2 => $^R };
    #        die "Duplicate key '$^R->[1]'" if exists $^R->[0][1]->{$^R->[1]};
    #        [$^R->[0][0], {%{$^R->[0][1]}, $^R->[1] => $^R->[2]}] })
      )*
    )?
  \s*\}
)

(?<KV>
  (?&STRING) # [$^R, "string"]
  \s*:\s* (?&VALUE) # [[$^R, "string"], $value]
  #(?{ # warn Dumper { kv => $^R };
  #   [$^R->[0][0], $^R->[0][1], $^R->[1]] })
)

(?<ARRAY>
  #(?{ [$^R, []] })
  \[\s*
    (?: (?&VALUE) #(?{ [$^R->[0][0], [$^R->[1]]] })
      (?: \s*,\s* (?&VALUE) #(?{ # warn Dumper { atwo => $^R };
			 #[$^R->[0][0], [@{$^R->[0][1]}, $^R->[1]]] })
      )*
    )?
  \s*\]
)

(?<VALUE>
  \s*
  (
      (?&STRING)
    |
      (?&NUMBER)
    |
      (?&OBJECT)
    |
      (?&ARRAY)
    |
    true #(?{ [$^R, 1] })
  |
    false #(?{ [$^R, 0] })
  |
    null #(?{ [$^R, undef] })
  )
  \s*
)

(?<STRING>
  (
    "
    (?:
      [^\\"]+
    |
      \\ ["\\/bfnrt]
#    |
#      \\ u [0-9a-fA-f]{4}
    )*
    "
  )

  #(?{ [$^R, eval $^N] })
)

(?<NUMBER>
  (
    -?
    (?: 0 | [1-9]\d* )
    (?: \. \d+ )?
    (?: [eE] [-+]? \d+ )?
  )

  #(?{ [$^R, eval $^N] })
)

) }xms;

sub match_json {
    state $re = qr/\A$MATCH_JSON\z/;
    shift =~ $re ? 1:0;
}

1;
# ABSTRACT: Match JSON string using regex

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::JSON::Match - Match JSON string using regex

=head1 VERSION

This document describes version 0.02 of PERLANCAR::JSON::Match (from Perl distribution PERLANCAR-JSON-Match), released on 2016-02-18.

=head1 SYNOPSIS

 use PERLANCAR::JSON::Match qw(match_json);
 print "Data is JSON" if match_json($data);

=head1 DESCRIPTION

This module is basically just L<JSON::Decode::Regexp> with all the embedded Perl
code removed. So the regexp cannot build decoded JSON and can only match
instead. Used for testing/benchmarking only.

=head1 FUNCTIONS

=head2 match_json($str) => bool

Match JSON in C<$str>. Return true if input is a valid JSON, false otherwise.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-JSON-Match>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-JSON-Match>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-JSON-Match>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<JSON::Decode::Regexp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Syntax::Feature::Qn;
use strict;
use warnings;
use Devel::Declare;

our $VERSION = 0.06;

sub _parse {
    my ($op, $offset) = @_;

    my $token_len = Devel::Declare::toke_scan_word( $offset, 1 );
    my $white_len = Devel::Declare::toke_skipspace( $offset + $token_len );

    my $block_len = Devel::Declare::toke_scan_str( $offset + $token_len + $white_len );
    my $block_str = Devel::Declare::get_lex_stuff();
    Devel::Declare::clear_lex_stuff();

    die 'uh oh: strange length'
        unless defined $block_len and $block_len >= 0;

    my @ar = map { s/^\s+//; s/\s+$//; $_ }
        split /\n/, $block_str, -1;

    shift @ar if @ar > 0 and $ar[0]  eq '';
    pop   @ar if @ar > 0 and $ar[-1] eq '';

    my $linestr = Devel::Declare::get_linestr();
    my $pack    = Devel::Declare::get_curstash_name();

    my ($anon, $repl);

    if ($op eq 'qn') {
        $repl = '';
        $anon = eval {sub () { @ar }};
    }
    else {
        $repl = join ',', map { "\"$_\"" } @ar;
        $anon = eval {sub (@) { @_ }};
    }

    substr $linestr, $offset+$token_len, $white_len+$block_len, "( $repl )";

    Devel::Declare::set_linestr( $linestr );
    Devel::Declare::shadow_sub( "${pack}::$op", $anon );
}

sub install {
    shift;
    Devel::Declare->setup_for( {@_}->{into}, {
        qn  => { const => \&_parse },
    });
}

1;

__END__

=head1 NAME

Syntax::Feature::Qn - Perl syntax extension for line-based quoting

=head1 SYNOPSIS

  use qn;

  @foo = qn {
    line one
    line two
    line three
  };
  # ("line one", "line two", "line three")

  $bar = 'BAR';
  @foo = qqn {
    foo
    $bar
    bam
  };
  # ("foo", "BAR", "bam")

=head1 DESCRIPTION

This module adds line-based quoting operators to Perl, similar to
here-docs, but without the required outdenting.

The qn() and qqn() operators are drop-in replacements for q() and qq(),
respectively. The same delimiter rules apply.

The quote body is split on "\n" and each resulting list item is stripped
of leading and trailing whitespace. Inner whitespace is preserved.

Empty lines, or lines consisting of only whitespace, translate to empty
string list items.

The first and last items can be on the same line as the delimiter, or
not. So, these are the same:

  @foo = qn {
    first
    second
    third
    fourth
  };
  # ("first", "second", "third", "fourth")

  @foo = qn { first
    second
    third
    fourth };
  # ("first", "second", "third", "fourth")

You could even get away with this:

  @foo = qn { first };
  # ("first")

=head1 SEE ALSO

q, qq in perlfunc.

=head1 AUTHOR

Rick Myers, <jrm@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rick Myers.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.20.1 or, at
your option, any later version of Perl 5 you may have available.


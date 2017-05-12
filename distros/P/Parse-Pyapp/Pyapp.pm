package Parse::Pyapp;
use 5.006;
use strict;
our $VERSION = '0.01';

use Parse::Pyapp::Parser;
our @ISA = qw( Parse::Pyapp::Parser);

sub new {
    bless {
        symcount => 0,
    }, shift;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Parse::Pyapp - PCFG Parser

=head1 SYNOPSIS

  use Parse::Pyapp;

  my $parser = Parse::Pyapp->new();

  $parser->addrule($LHS, [ $RHS_1, $P_RHS_1 ], [ $RHS_2, $P_RHS_2 ]);

  $parser->addlex($LHS, [ $RHS_1, $P_RHS_1 ], [ $RHS_2, $P_RHS_2 ]);

  $parser->start($LHS);

  $parser->parse(@words) or print "Parse error\n";

=head1 DESCRIPTION

This module is a (PCFG | SCFG) parser. You may use this module to do stochastic parsing.

=head1 USAGE

=head2 Initiation of a parser

    $parser = Parse::Pyapp->new();

=head2 Adding lexicons

    $parser->addlex('N',
		      [ 'house', .5 ],
		      [ 'book', .5 ]
		      );

You can hook an semantic action to alexicon. For instance,

    $parser->addlex('N',
			[ 'house', .5 ],
			[ 'book', .5 ],
                        sub { print $_[1] }
		      );

L<Parse::Pyapp> passes the parser itself as the first parameter, and the lexicon comes in the second place. The left-hand-side symbol can be accessed with $_[0]->{lhs}.

=head2 Adding rules

    $parser->addrule('VP',
		   [ 'V', 0.5 ],
		   [ 'V', 'NP', .5 ]
		   );

First one is the LHS symbol, and then follow all the possible right-hand-side derivations with their probabilities.

Similarly, you can hook semantic actions to the end of a derivation. For instance,

    $parser->addrule('VP',
		   [ 'V', 0.5, sub { print $_[1] } ],
		   [ 'V', 'NP', .5 ]
		   );

L<Parse::Pyapp> passes the parser itself as the first parameter, and the corresponding tokens as the rest. The left-hand-side symbol can be accessed with $_[0]->{lhs}, and right-hand POS tags with @{$_->{pos}}

I<Currently, this module does not check if the sum of probabilities going out from a non-terminal is equal to 1.>

=head2 Setting the starting symbol

    $parser->start('S');

=head2 Parsing a sentence

You need to tokenize the sentence yourself.

    $parser->parse(@words);

It returns non-undef if there is no error.

=head1 CAVEATS

This is still an alpha version, and everything is subject to change. Use it with your cautions. By the way, since it's all written in Perl, thus slowness is the fate.

=head1 TO DO

=over 

Grammar learning, lexical relations, structural modeling, yacc-like input, error handling, etc. There is a lot of room for improvement.

=back


=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut

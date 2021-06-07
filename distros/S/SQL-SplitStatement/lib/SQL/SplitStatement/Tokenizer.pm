use strict;
use warnings;
package SQL::SplitStatement::Tokenizer;


use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK= qw(tokenize_sql);

our $VERSION = '1.00023';

my $re= qr{
    (
        (?:--|\#)[\ \t\S]*      # single line comments
        |
        (?:<>|<=>|>=|<=|==|=|!=|!|<<|>>|<|>|\|\||\||&&|&|-|\+|\*(?!/)|/(?!\*)|\%|~|\^|\?)
                                # operators and tests
        |
        [\[\]\(\)\{\},;.]            # punctuation (parenthesis, comma)
        |
        \'\'(?!\')              # empty single quoted string
        |
        \"\"(?!\"")             # empty double quoted string
        |
        "(?>(?:(?>[^"\\]+)|""|\\.)*)+"
                                # anything inside double quotes, ungreedy
        |
        `(?>(?:(?>[^`\\]+)|``|\\.)*)+`
                                # anything inside backticks quotes, ungreedy
        |
        '(?>(?:(?>[^'\\]+)|''|\\.)*)+'
                                # anything inside single quotes, ungreedy.
        |
        /\*[\ \t\r\n\S]*?\*/      # C style comments
        |
        (?:[\w:@]+(?:\.(?:\w+|\*)?)*)
                                # words, standard named placeholders, db.table.*, db.*
        |
        (?: \$_\$ | \$\d+ | \${1,2} )
                                # dollar expressions - eg $_$ $3 $$
        |
        \n                      # newline
        |
        [\t\ ]+                 # any kind of white spaces
    )
}smx;

sub tokenize_sql {
    my ( $query, $remove_white_tokens )= @_;

    my @query= $query =~ m{$re}smxg;

    if ($remove_white_tokens) {
        @query= grep( !/^[\s\n\r]*$/, @query );
    }

    return wantarray ? @query : \@query;
}

1;

=pod

=head1 NAME

SQL::SplitStatement::Tokenizer - A simple SQL tokenizer.

=head1 SYNOPSIS

 use SQL::SplitStatement::Tokenizer qw(tokenize_sql);

 my $query= q{SELECT 1 + 1};
 my @tokens= tokenize_sql($query);

 # @tokens now contains ('SELECT', ' ', '1', ' ', '+', ' ', '1')

=head1 DESCRIPTION

SQL::SplitStatement::Tokenizer is a simple tokenizer for SQL queries. It does
not claim to be a parser or query verifier. It just creates sane tokens from a
valid SQL query.

It supports SQL with comments like:

 -- This query is used to insert a message into
 -- logs table
 INSERT INTO log (application, message) VALUES (?, ?)

Also supports C<''>, C<""> and C<\'> escaping methods, so tokenizing queries
like the one below should not be a problem:

 INSERT INTO log (application, message)
 VALUES ('myapp', 'Hey, this is a ''single quoted string''!')

=head1 API

=over 4

=item tokenize_sql

    use SQL::SplitStatement::Tokenizer qw(tokenize_sql);

    my @tokens = tokenize_sql($query);
    my $tokens = tokenize_sql($query);

    $tokens = tokenize_sql( $query, $remove_white_tokens );

C<tokenize_sql> can be imported to current namespace on request. It receives a
SQL query, and returns an array of tokens if called in list context, or an
arrayref if called in scalar context.


If C<$remove_white_tokens> is true, white spaces only tokens will be removed from
result.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item 

Igor Sutton Lopes for writing SQL::Tokenizer, which this was forked from.

=item

Evan Harris, for implementing Shell comment style and SQL operators.

=item

Charlie Hills, for spotting a lot of important issues I haven't thought.

=item

Jonas Kramer, for fixing MySQL quoted strings and treating dot as punctuation character correctly.

=item

Emanuele Zeppieri, for asking to fix SQL::Tokenizer to support dollars as well.

=item

Nigel Metheringham, for extending the dollar signal support.

=item

Devin Withers, for making it not choke on CR+LF in comments.

=item

Luc Lanthier, for simplifying the regex and make it not choke on backslashes.

=back

=head1 AUTHOR

Copyright (c) 2007, 2008, 2009, 2010, 2011 Igor Sutton Lopes "<IZUT@cpan.org>". All rights
reserved.

Copyright (c) 2021 Veesh Goldman "<veesh@cpan.org>"

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


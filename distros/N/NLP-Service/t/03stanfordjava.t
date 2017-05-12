use Test::More;
use Test::Moose;

BEGIN {
    use_ok('NLP::StanfordParser');
}

is( PARSER_RELEASE_DATE, '2010-11-30',
    'The parser is of the right release date' );
can_ok('NLP::StanfordParser', 'relations');
my $nlp = new_ok( 'NLP::StanfordParser' );
meta_ok($nlp);
has_attribute_ok( $nlp, 'parser' );
has_attribute_ok( $nlp, 'model' );
can_ok( $nlp, 'relations' );
isa_ok( $nlp->relations, 'HASH' );
cmp_ok( scalar(keys %{$nlp->relations}), '>', 1, 'There are keys in the hash' );
done_testing();
__END__
COPYRIGHT: 2011. Vikas Naresh Kumar.
AUTHOR: Vikas Naresh Kumar
DATE: 11th Jun 2011
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


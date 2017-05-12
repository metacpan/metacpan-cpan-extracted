use strict;
use warnings;
use utf8;
use Search::Fulltext;
use Test::More;

use_ok 'Search::Fulltext::Tokenizer::Bigram';

for my $tokenizer_name (qw/Unigram Bigram Trigram/) {
  subtest "$tokenizer_name tokenizer" => sub {
    my $class_name = "Search::Fulltext::Tokenizer::$tokenizer_name";
    use_ok $class_name;

    my $iterator_generator_factory = "${class_name}::get_tokenizer";

    my $search_engine = Search::Fulltext->new(
      docs => [
        'ハンプティ・ダンプティ 塀の上',
        'ハンプティ・ダンプティ 落っこちた',
        '王様の馬みんなと 王様の家来みんなでも',
        'ハンプティを元に 戻せなかった',
      ],
      tokenizer => "perl '$iterator_generator_factory'",
    );

    is_deeply($search_engine->search('ハンプティ'), [0, 1, 3]);

    is_deeply($search_engine->search('"ハンプティ" AND "ダンプティ"'), [0, 1]);

    # Trigram index does not contain 2-letter tokens, of course.
    my $hit_documents = $search_engine->search('王様');
    is_deeply($hit_documents, $tokenizer_name eq 'Trigram' ? [] : [2]);
  };
}

done_testing;

use strict;
use warnings;

use Pod::L10N::Model;
use Data::Dumper;
use Test::More tests => 3;
use Test::Exception;

my $in;
my $out;

#

$in = <<'EOF';

=head1 original

(translated)
EOF

$out = Pod::L10N::Model::decode($in);
is_deeply(
    $out,
    [
        [
            '=head1 original',
            '(translated)'
        ]
    ],
    'substituted head'
    );

#

$in = <<'EOF';

=begin original

original text

=end original

translated text

untranslated text
EOF

$out = Pod::L10N::Model::decode($in);
note Dumper($out);
is_deeply(
    $out,
    [
        [
            'original text',
            'translated text'
            ],
        [
            'untranslated text',
            undef
            ]
        ],
    'substituted text'
    );

#

$in = <<'EOF';
=end original
EOF

throws_ok {
    Pod::L10N::Model::decode($in)
  } qr/end without begin/, "end without begin";

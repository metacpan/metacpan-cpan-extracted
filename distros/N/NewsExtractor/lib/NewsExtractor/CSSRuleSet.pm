package NewsExtractor::CSSRuleSet;
use v5.18;
use utf8;
use Moo;

use Types::Common::String qw( NonEmptySimpleStr );

has headline => (
    required => 1,
    is => 'ro',
    isa => NonEmptySimpleStr,
);

has journalist => (
    required => 1,
    is => 'ro',
    isa => NonEmptySimpleStr,
);

has dateline => (
    required => 1,
    is => 'ro',
    isa => NonEmptySimpleStr,
);

has content_text => (
    required => 1,
    is => 'ro',
    isa => NonEmptySimpleStr,
);

1;

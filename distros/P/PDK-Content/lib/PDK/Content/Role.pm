package PDK::Content::Role;

use 5.030;
use Moose::Role;
use namespace::autoclean;

has id => (is => 'ro', isa => 'Int', required => 1,);

has name => (is => 'ro', isa => 'Str', required => 1,);

has type => (is => 'ro', isa => 'Str', required => 1,);

has sign => (is => 'ro', isa => 'Str', required => 1,);

has timestamp => (is => 'ro', isa => 'Str', required => 1,);

has lineParsedFlags => (is => 'ro', isa => 'ArrayRef[Int]', builder => '_buildLineParsedFlags',);

has debug => (is => 'ro', isa => 'Int', required => 0,);


requires 'config';
requires 'confContent';
requires 'cursor';
requires 'goToHead';
requires 'nextLine';
requires 'prevLine';
requires 'nextUnParsedLine';
requires 'backtrack';
requires 'ignore';
requires 'getUnParsedLines';

1;

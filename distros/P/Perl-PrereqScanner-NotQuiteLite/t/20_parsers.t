use strict;
use warnings;
use Test::More;
use t::Util;

$t::Util::PARSERS = [qw/:default/];

test('default', <<'END', {Moose => 0, Foo => 0, 'Test::More' => 0});
use Test::More;
use Moose;
extends qw/Foo/;
done_testing;
END

$t::Util::PARSERS = [qw/:default -Moose/];

test('exclude with minus', <<'END', {Moose => 0});
use Moose;
extends qw/Foo/;  # this should not be recognized
END

$t::Util::PARSERS = [qw/:default TestMore/];

test('extra parser', <<'END', {'Test::More' => 0.88});
use Test::More;
done_testing;
END

$t::Util::PARSERS = [qw/:default Perl::PrereqScanner::NotQuiteLite::Parser::TestMore/];

test('full qualified extra parser', <<'END', {'Test::More' => 0.88});
use Test::More;
done_testing;
END

$t::Util::PARSERS = [qw/:default +Perl::PrereqScanner::NotQuiteLite::Parser::TestMore/];

test('full qualified extra parser with plus', <<'END', {'Test::More' => 0.88});
use Test::More;
done_testing;
END

done_testing;

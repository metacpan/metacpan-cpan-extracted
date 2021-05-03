#!/usr/bin/env perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Test::More;
use Template::Tiny::Strict;

sub process ($$$$) {
    my ( $stash, $template, $expected, $message ) = @_;
    my $output = '';
    Template::Tiny::Strict->new( forbid_undef => 1, forbid_unused => 1 )
      ->process( \$template, $stash, \$output );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( $output, $expected, $message );
}

sub check_fail ($$$$) {
    my ( $stash, $template, $expected_error, $message ) = @_;
    my $output;
    eval {
        Template::Tiny::Strict->new(
            forbid_undef => 1, forbid_unused => 1,
            name         => 'my template'
        )->process( \$template, $stash, \$output );
    };
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $error = $@;
    ok $error, 'We should have an error';
    like $error, qr/$expected_error/, $message;
    ok !$output, '... and no output should be generated';
}

######################################################################
# Main Tests

process { foo => 'World' }, <<'END', <<'END_EXPECTED', 'Trivial ok';
Hello [% foo %]!
END
Hello World!
END_EXPECTED

check_fail { foo => undef },
  <<'END', "Undefined value in template path 'foo'", 'forbid_undef should fail on undef variables';
Hello [% foo %]!
END

check_fail { foo => [qw/this/] },
  <<'END', "Undefined value in template path 'foo.1'", 'Even deeper "undef" variables will cause failures';
First: [% foo.0 %] Second: [% foo.1 %]
END

check_fail { foo => 'World', bar => undef },
  <<'END', "The following variables were passed to the template but unused: 'bar'", 'Unused variables should also cause a failure';
Hello [% foo %]!
END

check_fail { foo => 'World', bar => undef, baz => 1 },
  <<'END', "The following variables were passed to the template but unused: 'bar, baz'", 'Unused variables should also cause a failure';
Hello [% foo %]!
END

chomp( my $expected = <<'END');
Template::Tiny::Strict processing for 'my template' failed:
Undefined value in template path 'foo'
The following variables were passed to the template but unused: 'bar'
END

check_fail { foo => undef, bar => 1 },
  <<'END', $expected, 'All errors should be reported at once, including the name of the temoplate';
Hello [% foo %]!
END

done_testing;

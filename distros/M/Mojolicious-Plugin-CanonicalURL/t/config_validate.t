use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;
use Mojo::Util;

lives_ok { plugin 'CanonicalURL' } 'no config lives';
lives_ok { plugin CanonicalURL => {} } 'empty hash config lives';

# cannot test throws when config isn't a hashref, because Mojolicious::Plugins::register_plugin wraps arguments in a hashref

# test should_canonicalize_request and should_not_canonicalize_request
for my $option (qw(should_canonicalize_request should_not_canonicalize_request)) {
    throws_ok { plugin CanonicalURL => {$option => \\'ref'} }
    qr{$option must be a scalar that evaluates to true and starts with a '/', a REGEXP, a SCALAR, a subroutine, an array reference, or a hash reference},
    "$option passed ref throws";

    throws_ok { plugin CanonicalURL => {$option => undef} }
    qr{$option must be a scalar that evaluates to true and starts with a '/', a REGEXP, a SCALAR, a subroutine, an array reference, or a hash reference},
    "$option passed undef throws";

    throws_ok { plugin CanonicalURL => {$option => ''} }
    qr{$option must be a scalar that evaluates to true and starts with a '/', a REGEXP, a SCALAR, a subroutine, an array reference, or a hash reference},
    "$option passed empty string throws";

    throws_ok { plugin CanonicalURL => {$option => 'path'} }
    qr{$option must be a scalar that evaluates to true and starts with a '/', a REGEXP, a SCALAR, a subroutine, an array reference, or a hash reference},
    "$option passed scalar that doesn't start with / throws";

    lives_ok { plugin CanonicalURL => {$option => '/path'} }
    "$option with scalar that starts with / lives";

    lives_ok { plugin CanonicalURL => {$option => qr//} }
    "$option passed regex lives";

    lives_ok { plugin CanonicalURL => {$option => \'return $next->()'} }
    "$option passed scalar reference lives";

    lives_ok {
        plugin CanonicalURL => {
            $option => sub { }
        }
    } "$option passed subroutine lives";

    # test array
    throws_ok { plugin CanonicalURL => {$option => []} }
    qr/array passed to $option must not be empty/,
    "$option passed empty array throws";

    throws_ok { plugin CanonicalURL => {$option => [undef]} }
    qr/elements of $option must be a true value/,
    "$option passed array with undef element throws";

    throws_ok { plugin CanonicalURL => {$option => ['']} }
    qr/elements of $option must be a true value/,
    "$option passed array with empty string element throws";

    throws_ok { plugin CanonicalURL => {$option => [0]} }
    qr/elements of $option must be a true value/,
    "$option passed array with empty zero element throws";

    lives_ok { plugin CanonicalURL => {$option => [qr//]} }
    "$option passed array with true element lives";

    throws_ok { plugin CanonicalURL => {$option => [[]]} }
    qr/elements of $option must have a reftype of undef \(scalar\), CODE, HASH, REGEXP, or SCALAR but was 'ARRAY'/,
    "$option passed array with array element throws";

    lives_ok { plugin CanonicalURL => {$option => [sub {}]} }
    "$option passed array with code element lives";

    lives_ok { plugin CanonicalURL => {$option => [\q{$c->req->url->path eq '/foo'}]} }
    "$option passed array with scalar reference element lives";

    lives_ok { plugin CanonicalURL => {$option => [qr//]} }
    "$option passed array with regex element lives";

    throws_ok { plugin CanonicalURL => {$option => ['path']} }
    qr{elements of $option must begin with a '/' when they are scalar},
    "$option passed array with scalar element that does not begin with a slash throws";

    lives_ok { plugin CanonicalURL => {$option => ['/path']} }
    "$option passed array with a scalar element that begins with a slash lives";

    test_starts_with_hash('array', $option, sub { [$_[0]] });

    # test hash
    test_starts_with_hash('hash', $option, sub { $_[0] });
}

lives_ok {
    plugin CanonicalURL => {
        should_canonicalize_request => '/path',
        should_not_canonicalize_request => qr/^path/,
    }
} 'should_canonicalize_request and should_not_canonicalize_request passed together live';

# test inline_code
throws_ok { plugin CanonicalURL => {inline_code => undef} }
qr/inline_code must be a true scalar value/,
'inline_code passed undef throws';

throws_ok { plugin CanonicalURL => {inline_code => ''} }
qr/inline_code must be a true scalar value/,
'inline_code passed empty string throws';

throws_ok { plugin CanonicalURL => {inline_code => 0} }
qr/inline_code must be a true scalar value/,
'inline_code passed zero throws';

throws_ok { plugin CanonicalURL => {inline_code => []} }
qr/inline_code must be a true scalar value/,
'inline_code passed non-scalar value (array) throws';

lives_ok { plugin CanonicalURL => {inline_code => 'print "hi\n";'} }
'inline_code passed a true scalar value lives';

throws_ok { plugin CanonicalURL => {canonicalize_before_render => []} }
qr/canonicalize_before_render must be a scalar value/,
'canonicalize_before_render passed non-scalar value (array) throws';

lives_ok { plugin CanonicalURL => {canonicalize_before_render => undef} }
'canonicalize_before_render passed scalar value (undef) lives';

lives_ok { plugin CanonicalURL => {canonicalize_before_render => '0'} }
q{canonicalize_before_render passed scalar value ('0') lives};

lives_ok { plugin CanonicalURL => {canonicalize_before_render => 1} }
'canonicalize_before_render passed scalar value (1) lives';

throws_ok { plugin CanonicalURL => {inline_code => 'print "hi\n";', captures => {}} }
qr/captures cannot be empty/,
'empty captures throws';

throws_ok { plugin CanonicalURL => {should_canonicalize_request => '/path', captures => {}} }
qr/captures only applies when inline_code is set or a scalar reference is passed to should_canonicalize_request or should_not_canonicalize_request/,
'captures not used with scalar ref or inline_code (should_canonicalize_request) throws';

throws_ok { plugin CanonicalURL => {should_not_canonicalize_request => '/path', captures => {}} }
qr/captures only applies when inline_code is set or a scalar reference is passed to should_canonicalize_request or should_not_canonicalize_request/,
'captures not used with scalar ref or inline_code (should_not_canonicalize_request) throws';

lives_ok { plugin CanonicalURL => {should_canonicalize_request => \'$c->req->url->path eq $my_var', captures => {'$my_var' => '/path'}} }
'captures used with scalar ref for should_canonicalize_request lives';

lives_ok { plugin CanonicalURL => {should_canonicalize_request => [\'$c->req->url->path eq $my_var'], captures => {'$my_var' => '/path'}} }
'captures used with scalar ref in array for should_canonicalize_request lives';

lives_ok { plugin CanonicalURL => {should_not_canonicalize_request => \'$c->req->url->path eq $my_var', captures => {'$my_var' => '/path'}} }
'captures used with scalar ref for should_not_canonicalize_request lives';

lives_ok { plugin CanonicalURL => {should_not_canonicalize_request => [\'$c->req->url->path eq $my_var'], captures => {'$my_var' => '/path'}} }
'captures used with scalar ref in array for should_not_canonicalize_request lives';

lives_ok { plugin CanonicalURL => {inline_code => 'return $next->() if $c->req->url->path eq $my_var;', captures => {'$my_var' => '/path'}} }
'captures used with inline_code lives';

my $key_value_dump = Mojo::Util::dumper {unknown_key => undef};
throws_ok { plugin CanonicalURL => {should_canonicalize_request => '/path', unknown_key => undef} }
qr/unknown keys passed in config: \Q$key_value_dump\E/,
'unknown key passed to config throws';

done_testing;

sub test_starts_with_hash {
    my ($name, $option, $get_option_config_sub) = @_;

    throws_ok { plugin CanonicalURL => {$option => $get_option_config_sub->({})} }
    qr/must provide key 'starts_with' to hash in $option/,
    "$name $option no starts_with key provided throws";

    throws_ok { plugin CanonicalURL => {$option => $get_option_config_sub->({ starts_with => undef })} }
    qr/value for starts_with must not be undef/,
    "$name $option starts_with value undef throws";

    throws_ok { plugin CanonicalURL => {$option => $get_option_config_sub->({ starts_with => [] })} }
    qr/value for starts_with must be a scalar/,
    "$name $option starts_with non-scalar value (array) throws";

    throws_ok { plugin CanonicalURL => {$option => $get_option_config_sub->({ starts_with => 'path' })} }
    qr{value for starts_with must begin with a '/'},
    "$name $option starts_with scalar value that doesn't begin with a slash throws";

    lives_ok { plugin CanonicalURL => {$option => $get_option_config_sub->({ starts_with => '/path' })} }
    "$name $option starts_with scalar value that begins with a slash lives";

    my $key_value_dump = Mojo::Util::dumper {unknown_key => undef};
    throws_ok { plugin CanonicalURL => {$option => $get_option_config_sub->({ starts_with => '/path', unknown_key => undef })} }
    qr{unknown keys/values passed in hash inside of $option: \Q$key_value_dump\E},
    "$name $option extra key throws";
}

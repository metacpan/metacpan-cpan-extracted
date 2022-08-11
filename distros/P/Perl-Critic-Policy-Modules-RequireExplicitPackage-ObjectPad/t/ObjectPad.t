use strict;
use warnings;
use Test::More;
use PPI;
use Scalar::Util qw(refaddr);
use Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad;

my ($code, $expected_code, $doc, $processed_doc);
$code = <<EOF;
# some commit
package Abc;
use Def;
EOF
$expected_code = $code;
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code, "the original doc not changed");
is("$processed_doc", $code, "the source code not changed because there is no class");

$code = <<EOF;
# Some comment
use Object::Pad;
# other comment
class Abc ;
# comment 3
EOF
$expected_code = <<EOF;
# Some comment

# other comment
package Abc;class Abc ;
# comment 3
EOF
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code,          "the original doc not changed");
is("$processed_doc", $expected_code, "Object::Pad and class is replaced");

$code = <<'EOF';
# Some comment
use Object::Pad;
# other comment
class Abc :isa("P1") {
    has $abc :reader :writer ;
};
# comment 3
EOF
$expected_code = <<'EOF';
# Some comment

# other comment
package Abc;class Abc :isa("P1") {
    has $abc :reader :writer ;
};
# comment 3
EOF
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code,          "the original doc not changed");
is("$processed_doc", $expected_code, "Object::Pad and class is replaced");

$code = <<'EOF';
# Some comment
use Object::Pad;
# other comment
class Abc :attr {
    has $abc :reader :writer ;
};
# comment 3
EOF
$expected_code = <<'EOF';
# Some comment

# other comment
package Abc;class Abc :attr {
    has $abc :reader :writer ;
};
# comment 3
EOF
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code,          "the original doc not changed");
is("$processed_doc", $expected_code, "Object::Pad and class is replaced");

$code = <<'EOF';
# Some comment
use Object::Pad;
# other comment
class Abc {
    has $abc :reader :writer ;
};
# comment 3
EOF
$expected_code = <<'EOF';
# Some comment

# other comment
package Abc;class Abc {
    has $abc :reader :writer ;
};
# comment 3
EOF
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code,          "the original doc not changed");
is("$processed_doc", $expected_code, "Object::Pad and class is replaced");

$code = <<'EOF';
# Some comment
use Object::Pad;
# other comment
# comment 3
EOF
$expected_code = $code;
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code,          "the original doc not changed");
is("$processed_doc", $expected_code, "code not changed becasue there is no class");

$code = <<'EOF';
# Some comment
# other comment
class Abc ;
# comment 3
EOF
$expected_code = $code;
$doc           = PPI::Document->new(\$code);
$processed_doc = Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad::_replace_class($doc);
isnt(refaddr($doc), refaddr($processed_doc), "not same doc");
is("$doc",           $code,          "the original doc not changed");
is("$processed_doc", $expected_code, "code not changed becasue there is no Object::Pad");

done_testing();

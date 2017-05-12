use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

use PPI;

# Hopefully, functionality is tested in other tests.

BEGIN {
    use_ok('Module::AnyEvent::Helper::PPI::Transform', qw(
        function_name is_function_declaration delete_function_declaration
        copy_children
        emit_cv emit_cv_into_function
        replace_as_async
    ));
}

my $pkg = 'Module::AnyEvent::Helper::PPI::Transform';

throws_ok { function_name } qr/function_name: MUST be called with an argument of PPI::Element object/, 'function_name arg1';
throws_ok { $pkg->function_name } qr/function_name: MUST be called with an argument of PPI::Element object/, 'function_name arg1';
throws_ok { is_function_declaration } qr/is_function_declaration: MUST be called with an argument of PPI::Token::Word object/, 'is_function_declaration arg1';
throws_ok { $pkg->is_function_declaration } qr/is_function_declaration: MUST be called with an argument of PPI::Token::Word object/, 'is_function_declaration arg1';
throws_ok { delete_function_declaration } qr/delete_function_declaration: MUST be called with an argument of PPI::Token::Word object/, 'delete_function_declaration arg1';
throws_ok { $pkg->delete_function_declaration } qr/delete_function_declaration: MUST be called with an argument of PPI::Token::Word object/, 'delete_function_declaration arg1';
throws_ok { copy_children } qr/copy_children: Both of prev and next are not PPI::Element objects/, 'copy_children arg1 and arg2';
throws_ok { $pkg->copy_children } qr/copy_children: Both of prev and next are not PPI::Element objects/, 'copy_children arg1 and arg2';
throws_ok { copy_children(PPI::Document->new) } qr/copy_children: target is not a PPI::Element object/, 'copy_children arg3';
throws_ok { $pkg->copy_children(PPI::Document->new) } qr/copy_children: target is not a PPI::Element object/, 'copy_children arg3';
throws_ok { emit_cv } qr/emit_cv: target is not a PPI::Structure::Block object/, 'emit_cv arg1';
throws_ok { $pkg->emit_cv } qr/emit_cv: target is not a PPI::Structure::Block object/, 'emit_cv arg1';
throws_ok { emit_cv_into_function } qr/emit_cv_into_function: the first argument is not a PPI::Token::Word object/, 'emit_cv_into_function arg1';
throws_ok { $pkg->emit_cv_into_function } qr/emit_cv_into_function: the first argument is not a PPI::Token::Word object/, 'emit_cv_into_function arg1';
throws_ok { replace_as_async } qr/replace_as_async: the first argument is not a PPI::Element object/, 'replace_as_async arg1';
throws_ok { $pkg->replace_as_async } qr/replace_as_async: the first argument is not a PPI::Element object/, 'replace_as_async arg1';

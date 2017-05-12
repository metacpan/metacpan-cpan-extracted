package t::TryCatch;

use Moove types => \'t::TryCatch::typelib', -trycatch;

func test1() {

    try {
        die "abc\n"
    } catch {
        return $@
    }

    return;
}

func test2() {

    try {
        die "def\n"
    } catch ($e) {
        return $e
    }

    return;
}

func test3() {

    try {
        die "ghi\n"
    } catch ($e) {
        die "$e: jkl\n"
    }

    return;
}

func test4($x) {

    try {
        die $x;
    } catch (IntErr $e) {
        return "Int[$e]"
    } catch (StrErr $e) {
        return "Str[$e]"
    }

    return;
}

1;

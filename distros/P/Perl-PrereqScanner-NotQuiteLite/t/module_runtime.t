use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('use_module', <<'END', {'Module::Runtime' => 0, 'Test::More' => 0});
use Module::Runtime 'use_module';
use_module('Test::More');
END

test('conditional use_module', <<'END', {'Module::Runtime' => 0}, {}, {'Test::More' => 0});
use Module::Runtime 'use_module';
if (1) { use_module('Test::More'); }
END

test('use_module in a sub', <<'END', {'Module::Runtime' => 0}, {}, {'Test::More' => 0});
use Module::Runtime 'use_module';
sub foo { use_module('Test::More'); }
END

test('use_module in BEGIN', <<'END', {'Module::Runtime' => 0, 'Test::More' => 0});
use Module::Runtime 'use_module';
BEGIN { use_module('Test::More'); }
END

test('use_module with version', <<'END', {'Module::Runtime' => 0, 'Test::More' => '0.01'});
use Module::Runtime 'use_module';
use_module('Test::More', '0.01');
END

test('require_module', <<'END', {'Module::Runtime' => 0, 'Test::More' => 0});
use Module::Runtime 'require_module';
require_module('Test::More');
END

test('use_package_optimistically', <<'END', {'Module::Runtime' => 0, 'Test::More' => 0});
use Module::Runtime 'use_package_optimistically';
use_package_optimistically('Test::More');
END

test('use_package_optimistically with version', <<'END', {'Module::Runtime' => 0, 'Test::More' => '0.01'});
use Module::Runtime 'use_package_optimistically';
use_package_optimistically('Test::More', '0.01');
END

test('use_module', <<'END', {'Module::Runtime' => 0, 'Test::More' => 0});
use Module::Runtime;
Module::Runtime::use_module('Test::More');
END

done_testing;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

# JHTHORSEN/Mandel-0.29/lib/Mandel/Model.pm
test('basic', <<'END', {'Mojo::Base' => 0, 'Mandel::Document' => 0});
use Mojo::Base 'Mandel::Document';
END

# JHTHORSEN/Mandel-0.29/lib/Mandel.pm
test('Mojo::Base itself', <<'END', {'Mojo::Base' => 0});
use Mojo::Base 'Mojo::Base';
END

test('-base', <<'END', {'Mojo::Base' => 0});
use Mojo::Base -base;
END

test('-strict', <<'END', {'Mojo::Base' => 0});
use Mojo::Base '-strict';
END

test('package with a single quote', <<'END', {'Mojo::Base' => 0, 'Mojo::BaseTestTest' => 0});
use Mojo::Base "Mojo'BaseTestTest";
END

done_testing;

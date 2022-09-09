#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir tempfile);
use IO::Barf qw(barf);

# Temp directory for generated module
my $temp_dir = tempdir(CLEANUP => 1);

# File with versions.
my (undef, $versions_file) = tempfile();

make_path(catfile($temp_dir, 'Schema', 'Data', 'Foo'));

my $package_schema_foo = catfile($temp_dir, 'Schema', 'Data', 'Foo.pm');
barf($package_schema_foo, <<"END");
package Schema::Data::Foo;

use base qw(Schema::Data);

use IO::Barf qw(barf);

sub _versions_file {
        barf('$versions_file', "0.2.0\\n0.1.0\\n0.1.1");

        return '$versions_file';
}

1;
END

my $package_schema_foo_0_1_0 = catfile($temp_dir, 'Schema', 'Data', 'Foo', '0_1_0.pm');
barf($package_schema_foo_0_1_0, <<'END');
package Schema::Data::Foo::0_1_0;

1;
END

my $package_schema_foo_0_1_1 = catfile($temp_dir, 'Schema', 'Data', 'Foo', '0_1_1.pm');
barf($package_schema_foo_0_1_1, <<'END');
package Schema::Data::Foo::0_1_1;

1;
END

my $package_schema_foo_0_2_0 = catfile($temp_dir, 'Schema', 'Data', 'Foo', '0_2_0.pm');
barf($package_schema_foo_0_2_0, <<'END');
package Schema::Data::Foo::0_2_0;

1;
END

unshift @INC, $temp_dir;

require Schema::Data::Foo;

my $obj = Schema::Data::Foo->new;

my @versions = $obj->list_versions;

print join "\n", @versions;

unlink $versions_file;

# Output:
# 0.1.0
# 0.1.1
# 0.2.0
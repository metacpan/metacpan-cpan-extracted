use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 16 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Filter/perl/PhysicalQuantity/check_type.pm',
    'Data/Sah/Filter/perl/PhysicalQuantity/convert_from_str.pm',
    'Data/Sah/Filter/perl/PhysicalQuantity/convert_unit.pm',
    'Sah/Schema/physical/distance.pm',
    'Sah/Schema/physical/mass.pm',
    'Sah/Schema/physical/mass_in_kg.pm',
    'Sah/Schema/physical/quantity.pm',
    'Sah/Schema/physical/type.pm',
    'Sah/Schema/physical/unit.pm',
    'Sah/SchemaR/physical/distance.pm',
    'Sah/SchemaR/physical/mass.pm',
    'Sah/SchemaR/physical/mass_in_kg.pm',
    'Sah/SchemaR/physical/quantity.pm',
    'Sah/SchemaR/physical/type.pm',
    'Sah/SchemaR/physical/unit.pm',
    'Sah/Schemas/PhysicalQuantity.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};



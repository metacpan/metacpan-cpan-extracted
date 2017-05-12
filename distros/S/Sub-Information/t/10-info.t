#!/usr/bin/perl -w

use strict;
use Test::More tests => 24;

use lib 'lib';
my $CLASS;

BEGIN {
    $CLASS = 'Sub::Information';
    use_ok $CLASS, as => 'peek'
      or die;
}

ok defined &peek, 'peek() should be exported to our namespace';
ok my $info = peek( \&peek ),
  '... and calling it with a valid sub reference should succeed';
isa_ok $info, $CLASS, '... and the object it returns';

can_ok $info, 'name';

ok !exists $INC{'Sub/Identify.pm'},
  '... and its helper module should not be loaded before it is needed';
is $info->name, "inspect",
  '... and it should return the original name of the subroutine';

ok exists $INC{'Sub/Identify.pm'},
  '... and its helper module should be loaded after it is needed';

can_ok $info, 'package';
is $info->package, $CLASS,
  '... and it should tell us the package the sub is from';

can_ok $info, 'fullname';
is $info->fullname, "$CLASS\::inspect",
  '... and it should give us the fully qualified sub name';

can_ok $info, 'code';
like $info->code, qr/sub {.*_croak.*}/s,
  '... and it should return the source code';

can_ok $info, 'address';
like $info->address, qr/^\d+$/, '... and it should return the address';

sub foo { my $x = 3; my @y = ( 4, 5 ) }
can_ok $info, 'variables';
is_deeply peek( \&foo )->variables, { '$x' => \undef, '@y' => [] },
  '... and the variable values should be undef if the sub is not in use';

my $bar = peek( \&bar );
bar();

sub bar {
    my $x = 3;
    my @y = ( 4, 5 );

    # we need to do this since all 'my' variables present in a subroutine are
    # returned by 'variables'.
    $::variables = $bar->variables;
    delete $::variables->{'$bar'};
    is_deeply $::variables, { '$x' => \3, '@y' => [ 4, 5 ] },
      '... and the variable values should be defined if the sub is in use';
}
my $vars = $bar->variables;
delete $vars->{'$bar'};
is_deeply $vars, { '$x' => \undef, '@y' => [] },
  '... but variable values should not be cached';

my $line_file_test = peek(\&line_file_test);
can_ok $line_file_test, 'line';
is $line_file_test->line, 24,
  '... and it should report the correct line number';

can_ok $line_file_test, 'file';
is $line_file_test->file, "'foo/some_file.t'",
    '... and it should report the correct file name';

# line 23 'foo/some_file.t'
sub line_file_test {
    my $x = 2;
}

# sub foo {
#   my $sub = sub { ... };
# }
# can I get foo() from $sub?

# find out what the exported subs name is
__END__

# can I get the size in memory?
my $sub = sub {
    my $x = shift;
    my $y = 3;
    return $x + $y;
};

use strict;
use warnings;

use IPC::Open3;
use Test::More;

# Make sure Module::Util::is_valid_module_name agrees with perl for every module
# on CPAN

my @modules;

BEGIN {
    require CPAN;

    @modules =
        map  { $_->id }
        CPAN::Shell->expand("Module", "/./");

    plan tests => 1 + @modules;

    use_ok('Module::Util', qw( is_valid_module_name ));
}

# some pragmata that are valid but fail really_valid
my @known_valid = qw(
    open
    if
    sort
);

# build a regex to recognise the names above.
my $known_valid = do { local $" = '|'; qr{^(?:@known_valid)$} };

# Check that the module name is really valid.
# Not all modules reported by CPAN are!
sub really_valid ($) {
    my $module = shift;

    return 1 if $module =~ $known_valid;

    # Check syntax using another perl interpreter. Very time consuming!
    my($in, $out, $err);
    my $pid = open3($in, $out, $err, $^X, '-c', '-e', "require $module")
        or die "Couldn't run $^X: $!";

    close $in;
    close $err if defined $err;

    my $line = <$out>;
    close $out;

    waitpid($pid, 0);

    # if we see syntax OK, the module name must be valid!
    my $valid = $line =~ /syntax OK/;

    # diag "$line: $valid";

    return $valid
}

for my $module (@modules) {
    my $valid = really_valid($module);
    my $ok = not (is_valid_module_name($module) xor $valid);

    ok($ok, "'$module' is ".($valid ? '' : 'not')." valid");
}

__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et

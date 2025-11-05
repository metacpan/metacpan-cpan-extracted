use strict;
use warnings;
use Test::More;
use Capture::Tiny qw(capture);
use FindBin;
use lib "$FindBin::Bin/../lib";

# Test all shell modules
my @shell_modules = (
    'NVMPL::Shell::Bash',
    'NVMPL::Shell::Zsh', 
    'NVMPL::Shell::Cmd',
    'NVMPL::Shell::PowerShell'
);

plan tests => scalar(@shell_modules) * 4;

# --------------------------------------------------------------------
# Test each shell module
# --------------------------------------------------------------------
foreach my $module (@shell_modules) {
    eval "require $module" or die "Failed to load $module: $@";
    
    my $bin_path = '/fake/path/to/bin';
    
    # Test update_path output format
    my ($stdout, $stderr) = capture {
        # Call as FUNCTION, not as METHOD
        no strict 'refs';
        &{"${module}::update_path"}($bin_path);
    };
    
    like($stdout, qr/\Q$bin_path\E/, "update_path contains bin path - $module");
    
    # Test shell-specific output formats
    if ($module eq 'NVMPL::Shell::PowerShell') {
        like($stdout, qr/\$Env:PATH/, "PowerShell format - $module");
    } elsif ($module eq 'NVMPL::Shell::Cmd') {
        like($stdout, qr/set PATH=/, "CMD format - $module");
    } else {
        like($stdout, qr/export PATH/, "Unix shell format - $module");
    }
    
    # Test init_snippet method
    my $snippet;
    ($stdout, $stderr) = capture {
        no strict 'refs';
        $snippet = &{"${module}::init_snippet"}();
    };
    
    ok(defined $snippet, "init_snippet returns defined value - $module");
    like($snippet, qr/current[\\\/]bin/, "init_snippet contains current/bin path - $module");
}

done_testing();
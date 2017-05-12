use strict;
use warnings;

use Test::More tests => 19;

BEGIN { use_ok("Module::Mask") };

use lib qw( t/lib );

my @old_inc = @INC;

my @warnings;
$SIG{'__WARN__'} = sub { push @warnings, @_ };
{
    my $mask = new Module::Mask undef;
    $mask->mask_modules('');
    is($mask->list_masked, 0, 'undef and empty masks are ignored');
}
is(@warnings, 0, 'undef and "" masks are silently ignored')
    or diag "Got warnings:\n".join("\n", @warnings);

@warnings = ();

is_deeply(\@INC, \@old_inc, '@INC is left unchanged by empty mask');

{
    my $mask = new Module::Mask ('Dummy');
    my $file = __FILE__;
    my $line = __LINE__; eval { require Dummy };
    like($@, qr(^Dummy\.pm masked by Module::Mask\b), 'Dummy was masked');

    my ($err_file, $err_line) = $@ =~ /at \s+ (.*?) \s+ line \s+ (\d+)/x
        or diag "Error didn't match expected pattern:\n$@";

    is($err_file, $file, 'file name correct');
    is($err_line, $line, 'line number correct');

    eval { require Dummy };
    ok($@, 'second time still dies');

    ok($mask->is_masked('Dummy'),    'is_masked("Dummy")');
    ok($mask->is_masked('Dummy.pm'), 'is_masked("Dummy.pm")');
    ok(!$mask->is_masked(''),        '!is_masked("")');

    my $path = 't/lib/Dummy.pm';
    $mask->mask_modules($path);
    eval { require $path };
    ok($@, "masked '$path'");

    eval { require Other };
    ok(!$@, 'can still require unmasked modules');
    is($Other::VERSION, '2.00', 'Other.pm was required.');
}

eval { require Dummy };
ok(!$@, 'require Dummy outside masked block succeeded');
is($Dummy::VERSION, 1, 'Got version number from Dummy')
    or diag("Loaded ". $INC{'Dummy.pm'});

is_deeply(\@INC, \@old_inc, '@INC is left unchanged');

is(@warnings, 0, 'No warnings generated')
    or diag "Got warnings:\n".join("\n", @warnings);

{
    # Overriding message
    @My::Mask::ISA = 'Module::Mask';
    sub My::Mask::message {
        my ($self, $filename) = @_;
        return "$filename masked\n";
    }

    my $mask = new My::Mask qw( Dummy );

    eval {
        local %INC; # Dummy is already loaded, let's pretend otherwise..
        require Dummy;
    };

    is($@, "Dummy.pm masked\n", "overriding message() works as advertised");
}

__END__

vim: ft=perl

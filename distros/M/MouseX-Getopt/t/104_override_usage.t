use strict;
use warnings;
use Test::More 0.88;
use Test::Exception;

{
    package MyScript;
    use Mouse;

    with 'MouseX::Getopt';

    has foo => ( isa => 'Int', is => 'ro', documentation => 'A foo' );

    our $usage = 0;
    before _getopt_full_usage => sub { $usage++; };
    our @warnings;
    before _getopt_spec_warnings => sub { shift; push(@warnings, @_) };
    our @exception;
    before _getopt_spec_exception => sub { shift; push(@exception, @{ shift() }, shift()) };
}
{
    local $MyScript::usage; local @MyScript::warnings; local @MyScript::exception;
    local @ARGV = ('--foo', '1');
    my $i = MyScript->new_with_options;
    ok $i;
    is $i->foo, 1;
    is $MyScript::usage, undef;
}
{
    local $MyScript::usage; local @MyScript::warnings; local @MyScript::exception;
    local @ARGV = ('--help');
    throws_ok { MyScript->new_with_options } qr/A foo/;
    is $MyScript::usage, 1;
}
{
    local $MyScript::usage; local @MyScript::warnings; local @MyScript::exception;
    local @ARGV = ('-q'); # Does not exist
    throws_ok { MyScript->new_with_options } qr/A foo/;
    is_deeply \@MyScript::warnings, [
          'Unknown option: q
'
    ];
    my $exp = [
         'Unknown option: q
',
         $Getopt::Long::Descriptive::VERSION < 0.099 ?
         qq{usage: 104_override_usage.t [-?] [long options...]
\t-? --usage --help  Prints this usage information.
\t--foo              A foo
}
        :
         $Getopt::Long::Descriptive::VERSION == 0.099 ?
         qq{usage: 104_override_usage.t [-?] [long options...]
\t-? --usage --help    Prints this usage information.
\t--foo INT            A foo
}
        :
         qq{usage: 104_override_usage.t [-?] [long options...]
\t-? --usage --help  Prints this usage information.
\t--foo INT          A foo
}

     ];

     is_deeply \@MyScript::exception, $exp;
}

done_testing;


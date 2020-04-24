use strict;
use warnings;

{
    # For under Perl 5.14
    # Perl 5.14 or later, it's has been loaded IO::Handle
    require Test::Arrow;
    no strict 'refs'; ## no critic
    no warnings 'redefine';
    *{'Test::Arrow::_need_io_handle'} = sub { !!1 };
    Test::Arrow->import;
}

t()->ok($INC{"IO/Handle.pm"});

done();

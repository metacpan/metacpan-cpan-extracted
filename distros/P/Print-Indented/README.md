# NAME

Print::Indented - Indent outputs indented as per source code indentation

# SYNOPSIS

    use Print::Indented;

    print "foo\n"; # prints "foo"

    {
        print "bar\n"; # prints "    bar";
    }

# DESCRIPTION

Print::Indented indents stdout/stderr outputs according to the source line indentation
where print function called, ex. `print`, `warn`.

# LICENSE

Copyright (C) motemen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

motemen <motemen@gmail.com>

# NAME

Path::Canonical - Simple utility to get canonical paths.

# SYNOPSIS

    use Path::Canonical;

# DESCRIPTION

Path::Canonical is a simple utility to get canonical paths.
Other tools such as Cwd::abs\_path exist, but they need to refer to the actual entry in the file system in order to work.
This is not feasible, for example, when you just want to cleanse the specified path in a web application, where you may
be dealing with a virtual path that does not exist in the file system.

# LICENSE

Copyright (C) mattn.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mattn <mattn.jp@gmail.com>

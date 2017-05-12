# NAME

Template::Plugin::RndString - Plugin to create random strings

# SYNOPSIS

    [% USE RndString(chrset => ['a'..'z']) %]

    Result: [% RndString.make(min_length,max_length) %]

# OPTIONS 

- chrset

    Optional. It must be an array ref of characters to use or a string (e.g 'abcdefgh'). If not defined, default is an alphanumeric symbols from ascii table. If possible, first symbol of output string always will be a letter.

# SEE ALSO

Template Toolkit is a fast, flexible and highly extensible template processing system [http://template-toolkit.org/](http://template-toolkit.org/)
Crypt::GeneratePassword - generate secure random pronounceable passwords [http://search.cpan.org/~neilb/Crypt-GeneratePassword/lib/Crypt/GeneratePassword.pm](http://search.cpan.org/~neilb/Crypt-GeneratePassword/lib/Crypt/GeneratePassword.pm)

# LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

bbon <bbon@mail.ru>

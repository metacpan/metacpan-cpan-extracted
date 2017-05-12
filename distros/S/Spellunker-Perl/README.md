# NAME

Spellunker::Perl - Spelling checker for Perl script

# SYNOPSIS

    use Spellunker::Perl;

    my $spellunker = Spellunker::Perl->new_from_file('path/to/MyModule.pm');
    my @err = $spellunker->check_comment();
    use Data::Dumper; warn Dumper(@err);

# DESCRIPTION

Spellunker::Perl is Spelling checker for Perl script.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

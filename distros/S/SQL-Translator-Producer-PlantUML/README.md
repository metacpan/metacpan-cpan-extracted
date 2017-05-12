# NAME

SQL::Translator::Producer::PlantUML - PlantUML-specific producer for SQL::Translator

# SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Producer::PlantUML;

    my $t = SQL::Translator->new( parser => '...', producer => 'PlantUML', '...' );
    $t->translate;

# DESCRIPTION

This module will produce text output of PlantUML.

# LICENSE

Copyright (C) mix3.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mix3 &lt;himachocost333@hotmail.co.jp>

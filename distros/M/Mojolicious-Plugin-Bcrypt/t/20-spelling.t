#!/usr/bin/perl

use Test::More;

BEGIN {
    plan skip_all => "Spelling tests only for authors"
        unless -e '.author'
}

use Test::Spelling;
set_spell_cmd('aspell list -l en');
add_stopwords(<DATA>);
all_pod_files_spelling_ok('lib');

__END__
GitHub
bcrypt
crypted
crypting
minimalist
minimalistic

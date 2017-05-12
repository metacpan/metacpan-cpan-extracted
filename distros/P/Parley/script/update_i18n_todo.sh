#!/usr/bin/env bash

LANGUAGES="it nl"

for L in $LANGUAGES; do
    perl script/i18n_todo.pl --lang=$L > todo.i18n/$L
done

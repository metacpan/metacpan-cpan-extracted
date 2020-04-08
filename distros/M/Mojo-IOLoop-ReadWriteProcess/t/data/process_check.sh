#!/bin/bash

cleanup() {
    echo "TEST exiting"
}

trap cleanup EXIT

(>&2 echo "TEST error print")
echo "TEST normal print"

while [[ -z "$TESTVAR" ]]
do
	read -p "Enter something: " TESTVAR
done

echo "you entered $TESTVAR"

[[ -n "$@" ]] && echo "$@"

exit 100

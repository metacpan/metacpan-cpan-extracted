#!/usr/bin/env bash
curl -s -XPOST --data-urlencode "q@-" "${PARSER_SERVICE:-http://127.0.0.1:15283/}"

# vim: set ft=sh:

#!/usr/bin/env scripts/a8it --config=t/data/config2
NAME: Test Case 1

SUMMARY: This is a test summary

TAGS:
    - tag1
    - tag2

INSTRUCTIONS:
    - fixture1
    - fixture2: foo
    - fixture3:
        bar: baz
    - fixture4:
        - boo
        - bork

EXPECTED:
    Some output
---
NAME: Test Case 2
ID: custom_id

SUMMARY: This is a test summary

TAGS:
    - tag1

INSTRUCTIONS:
    - fixture1
    - fixture2: foo
    - fixture3:
        bar: baz
    - fixture4:
        - boo
        - bork

EXPECTED:
    Some output
---
NAME: Test Case 3

SUMMARY: This is a test summary

TAGS:
    - tag3

INSTRUCTIONS:
    - fixture1
    - fixture2: foo
    - fixture3:
        bar: baz
    - fixture4:
        - boo
        - bork

ID: some_other_id

EXPECTED:
    Some output

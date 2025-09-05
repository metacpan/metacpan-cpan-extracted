#!/usr/bin/env bats

# Load the helper (which loads bats-support and bats-assert)
load test_helper.bash
# Source getoptlong.sh to make its functions available for testing
. ../getoptlong.sh

# Test: One-liner - basic auto-initialization
@test "getoptlong: one-liner - auto initialization" {
    run bash -c '
        declare -A OPTS=([verbose|v]=)
        . ../getoptlong.sh OPTS --verbose
        echo "verbose:$verbose"
    '
    assert_success
    assert_output "verbose:1"
}

# Test: One-liner - flag option with short and long forms
@test "getoptlong: one-liner - flag option short and long" {
    run bash -c '
        declare -A OPTS=([debug|d]=)
        . ../getoptlong.sh OPTS -d
        echo "debug:$debug"
    '
    assert_success
    assert_output "debug:1"
}

# Test: One-liner - required argument
@test "getoptlong: one-liner - required argument" {
    run bash -c '
        declare -A OPTS=([file|f:]=)
        . ../getoptlong.sh OPTS --file input.txt
        echo "file:$file"
    '
    assert_success
    assert_output "file:input.txt"
}

# Test: One-liner - multiple options
@test "getoptlong: one-liner - multiple options" {
    run bash -c '
        declare -A OPTS=(
            [verbose|v]=
            [file|f:]=
            [count|c:]=
        )
        . ../getoptlong.sh OPTS --verbose -f data.txt --count 5
        echo "verbose:$verbose"
        echo "file:$file"
        echo "count:$count"
    '
    assert_success
    assert_line --index 0 "verbose:1"
    assert_line --index 1 "file:data.txt"
    assert_line --index 2 "count:5"
}

# Test: One-liner - array option
@test "getoptlong: one-liner - array option" {
    run bash -c '
        declare -A OPTS=([item|i@]=)
        . ../getoptlong.sh OPTS --item val1 -i val2 --item val3
        echo "item_count:${#item[@]}"
        echo "item_0:${item[0]}"
        echo "item_1:${item[1]}"
        echo "item_2:${item[2]}"
    '
    assert_success
    assert_line --index 0 "item_count:3"
    assert_line --index 1 "item_0:val1"
    assert_line --index 2 "item_1:val2"
    assert_line --index 3 "item_2:val3"
}

# Test: One-liner - hash option
@test "getoptlong: one-liner - hash option" {
    run bash -c '
        declare -A OPTS=([data|d%]=)
        . ../getoptlong.sh OPTS --data key1=value1 -d key2=value2
        echo "data_key1:${data[key1]}"
        echo "data_key2:${data[key2]}"
    '
    assert_success
    assert_line --index 0 "data_key1:value1"
    assert_line --index 1 "data_key2:value2"
}

# Test: One-liner - optional argument with value
@test "getoptlong: one-liner - optional argument with value" {
    run bash -c '
        declare -A OPTS=([opt|o?]=)
        . ../getoptlong.sh OPTS --opt=test_value
        echo "opt:$opt"
    '
    assert_success
    assert_output "opt:test_value"
}

# Test: One-liner - optional argument without value
@test "getoptlong: one-liner - optional argument without value" {
    run bash -c '
        declare -A OPTS=([opt|o?]=)
        . ../getoptlong.sh OPTS --opt
        echo "opt:${opt:-unset}"
    '
    assert_success
    assert_output "opt:unset"
}

# Test: One-liner - passthru option
@test "getoptlong: one-liner - passthru option" {
    run bash -c '
        declare -A OPTS=([pass|p:>pass_array]=)
        declare -a pass_array=()
        . ../getoptlong.sh OPTS --pass value1 -p value2
        echo "pass_len:${#pass_array[@]}"
        echo "pass_0:${pass_array[0]}"
        echo "pass_1:${pass_array[1]}"
        echo "pass_2:${pass_array[2]}"
        echo "pass_3:${pass_array[3]}"
    '
    assert_success
    assert_line --index 0 "pass_len:4"
    assert_line --index 1 "pass_0:--pass"
    assert_line --index 2 "pass_1:value1"
    assert_line --index 3 "pass_2:-p"
    assert_line --index 4 "pass_3:value2"
}

# Test: One-liner - with validation (integer)
@test "getoptlong: one-liner - integer validation" {
    run bash -c '
        declare -A OPTS=([number|n:=i]=)
        . ../getoptlong.sh OPTS --number 42
        echo "number:$number"
    '
    assert_success
    assert_output "number:42"
}

# Test: One-liner - with validation failure
@test "getoptlong: one-liner - validation failure" {
    run bash -c '
        declare -A OPTS=([number|n:=i]=)
        . ../getoptlong.sh OPTS --number abc
    '
    assert_failure
    assert_output "abc: not an integer"
}

# Test: One-liner - combined short options
@test "getoptlong: one-liner - combined short options" {
    run bash -c '
        declare -A OPTS=(
            [verbose|v]=
            [debug|d]=
            [file|f:]=
        )
        . ../getoptlong.sh OPTS -vdf input.txt
        echo "verbose:$verbose"
        echo "debug:$debug"
        echo "file:$file"
    '
    assert_success
    assert_line --index 0 "verbose:1"
    assert_line --index 1 "debug:1"
    assert_line --index 2 "file:input.txt"
}

# Test: One-liner - with remaining arguments
@test "getoptlong: one-liner - remaining arguments" {
    run bash -c '
        declare -A OPTS=([verbose|v]=)
        . ../getoptlong.sh OPTS --verbose arg1 arg2 arg3
        echo "verbose:$verbose"
        echo "args:$@"
        echo "arg_count:$#"
    '
    assert_success
    assert_line --index 0 "verbose:1"
    assert_line --index 1 "args:arg1 arg2 arg3"
    assert_line --index 2 "arg_count:3"
}

# Test: One-liner - with double dash separator
@test "getoptlong: one-liner - double dash separator" {
    run bash -c '
        declare -A OPTS=([verbose|v]=)
        . ../getoptlong.sh OPTS --verbose -- --not-an-option
        echo "verbose:$verbose"
        echo "args:$@"
    '
    assert_success
    assert_line --index 0 "verbose:1"
    assert_line --index 1 "args:--not-an-option"
}

# Test: One-liner - negated option
@test "getoptlong: one-liner - negated option" {
    run bash -c '
        declare -A OPTS=([feature|f]=1)
        . ../getoptlong.sh OPTS --no-feature
        echo "feature:$feature"
    '
    assert_success
    assert_output "feature:"
}

# Test: One-liner - with initial values
@test "getoptlong: one-liner - with initial values" {
    run bash -c '
        declare -A OPTS=(
            [count|c:]=5
            [mode|m:]=default
        )
        . ../getoptlong.sh OPTS --count 10
        echo "count:$count"
        echo "mode:$mode"
    '
    assert_success
    assert_line --index 0 "count:10"
    assert_line --index 1 "mode:default"
}

# Test: One-liner - complex real-world example
@test "getoptlong: one-liner - complex example" {
    run bash -c '
        declare -A OPTS=(
            [verbose|v]=
            [quiet|q]=
            [output|o:]=output.txt
            [format|f:]=json
            [include|i@]=
            [exclude|e@]=
            [config|c%]=
            [dry-run|n]=
        )
        . ../getoptlong.sh OPTS \
            --verbose \
            --output result.txt \
            --include "*.txt" \
            --include "*.md" \
            --exclude temp \
            --config key1=val1 \
            --config key2=val2 \
            --dry-run \
            file1.txt file2.txt
        
        echo "verbose:$verbose"
        echo "output:$output"
        echo "format:$format"
        echo "include_count:${#include[@]}"
        echo "include_0:${include[0]}"
        echo "include_1:${include[1]}"
        echo "exclude_count:${#exclude[@]}"
        echo "exclude_0:${exclude[0]}"
        echo "config_key1:${config[key1]}"
        echo "config_key2:${config[key2]}"
        echo "dry_run:$dry_run"
        echo "remaining_args:$@"
    '
    assert_success
    assert_line --index 0 "verbose:1"
    assert_line --index 1 "output:result.txt"
    assert_line --index 2 "format:json"
    assert_line --index 3 "include_count:2"
    assert_line --index 4 "include_0:*.txt"
    assert_line --index 5 "include_1:*.md"
    assert_line --index 6 "exclude_count:1"
    assert_line --index 7 "exclude_0:temp"
    assert_line --index 8 "config_key1:val1"
    assert_line --index 9 "config_key2:val2"
    assert_line --index 10 "dry_run:1"
    assert_line --index 11 "remaining_args:file1.txt file2.txt"
}

# Test: One-liner - error handling for unknown option
@test "getoptlong: one-liner - unknown option error" {
    run bash -c '
        declare -A OPTS=([verbose|v]=)
        . ../getoptlong.sh OPTS --unknown-option
    '
    assert_failure
    assert_output "no such option -- --unknown-option"
}

# Test: One-liner - help generation
@test "getoptlong: one-liner - help with comments" {
    run bash -c '
        declare -A OPTS=(
            [verbose|v # Enable verbose output]=
            [file|f: # Input file path]=
            [count|c: # Number of iterations]=5
        )
        . ../getoptlong.sh OPTS --help 2>/dev/null || true
    '
    assert_success
    assert_output --partial "Enable verbose output"
    assert_output --partial "Input file path"
    assert_output --partial "Number of iterations"
}
# perl-option-result

Produce option objects like in Rust.
Here is the Rust doc: https://doc.rust-lang.org/rust-by-example/error/multiple_error_types/option_result.html

# Synopsis

     use Option::Option;

     my $option = Option::Option->new("something");

     # This croaks:
     print $var;

     # This works
     my $var = $option->unwrap();
     print $var;

     # This also works and has a helpful error message
     my $var = $option->expect("get my something");
     print $var;


# Installation

    cpanm -l ~ Option::Option

Future versions should have `Option::Factory`.

    cpanm -l ~ Option::Factory

# Further help

Please use the issues tab on github for interactive help.

Use perldoc for up to date documentation.

```shell
perldoc lib/perl/Option/Option.pm
```

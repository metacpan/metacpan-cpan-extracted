[![Build Status](https://travis-ci.com/worthmine/String-Numeric-Whatever.svg?branch=master)](https://travis-ci.com/worthmine/String-Numeric-Whatever)
# NAME

String::Numeric::Whatever - It's a test implement to
**ignore** the difference between `<=>` and `cmp` 

# SYNOPSIS

    use String::Numeric::Whatever;
    my $str = String::Numeric::Whatever->new('strings');

    say q|Succeeded in comparing with strings by 'eq'| if $str eq 'strings';            
    say q|Succeeded in comparing with Int by 'ne'|     if $str ne 100;            
    say q|Succeeded in comparing with Int by '!='|     if $str != 100;
    say q|Succeeded in comparing with strings by '=='| if $str == 'strings';
              

# DESCRIPTION

## INTRODUCE

If you have knowledge of other language, You may think like that.

_Why strings can't be compared with using `==`?_

I can't answer the reason why, but can give you this module.

It provides us comparable object with using `==`, `eq` or whatever!

## CONSTRUCTORS

I'm sorry that you have to call constructors
before getting the benefits of this module.

### new()

There is no validation. accepts all types of SCALAR

    my $str = String::Numeric::Whatever->new('strings');
    my $num = String::Numeric::Whatever->new(1234);

### tie()

or you can set like this:

    tie my $str => 'String::Numeric::Whatever', 'strings';
    tie my $num => 'String::Numeric::Whatever', 1234;

## THEN

Now you can compare the values with using any operators in below:

    < <= > >= == != <=>
    lt le gt ge eq ne cmp

After you assigned the constructors,
you don't have to care about whatever this is a string or number.

So you can write like below without warnings:

    say $str if $str == 'string';   # strings 
    say $num if $num ne 0;          # 1234 

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

[Yuki Yoshida(worthmine)](https://github.com/worthmine)

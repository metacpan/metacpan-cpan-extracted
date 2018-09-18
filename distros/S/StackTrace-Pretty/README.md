# stacktrace-pretty
Convert stacktrace to more readable one

# SYNOPSIS

~~~
$ cat sample.log | stacktrace-pretty
$ perl sample.pl 2>&1 | stacktrace-pretty
~~~

# Description

This tool converts text which includes stack trace of perl into more readable one.

# Demo

## Normal Output

![image](https://github.com/egawata/stacktrace-pretty/blob/master/images/readme_normal.png)

## Output with stacktrace-pretty

![image](https://github.com/egawata/stacktrace-pretty/blob/master/images/readme_using_tool.png)

# Install

~~~
$ cpanm https://github.com/egawata/stacktrace-pretty.git
~~~

# Options

## simple output only with a specific modules

Use `STACKTRACE_PRETTY_EXCLUDED_MODULES` environment variable.
It is a part of module/function names. 
You can specify more than one names by separating comma `,`. 

~~~
export STACKTRACE_PRETTY_EXCLUDED_MODULES=Some::Module,Another::Module
~~~


# License

Copyright (c)2018 egawata All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See perlartistic.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Author

egawata (https://github.com/egawata)

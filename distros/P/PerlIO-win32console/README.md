# PerlIO::win32console

This is a PerlIO layer intended for use with the Win32 console.

The layer accepts normal text, including wide characters, as :utf8 and
:encoding() do and calls the Win32 console APIs to write wide
characters instead of ANSI.

```
#!perl
use v5.36;
use utf8;
binmode STDOUT, ":win32console";

say "Свободное время";
```

![screenshot of console output in Cyrillic in a basic code page](/readme/demo.png)

So far it's just a proof of concept and needs more work.


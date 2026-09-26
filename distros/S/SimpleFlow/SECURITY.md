# Security policy

## Reporting a vulnerability

Please report security issues privately, by email to dec986@gmail.com,
rather than by opening an issue on the GitHub tracker, which is public.

It helps if you can include the version of SimpleFlow and of perl, the
platform, and either a short script that shows the problem or enough of a
description to reconstruct one.

SimpleFlow is maintained by one person, unpaid, so there is no guaranteed
response time and no bounty. Reports are nevertheless taken seriously, and you
will be credited in `Changes` for anything that leads to a fix unless you would
rather not be.

## Which versions are supported

Only the most recent release on CPAN. Fixes are shipped as a new release
rather than as a patch to an older one.

## Scope

SimpleFlow runs the command it is given. A `cmd` string is handed to the
shell, so a caller that builds one out of untrusted data — a filename from a
directory listing, a field from a downloaded file — has a shell injection in
the *calling* program, and SimpleFlow will faithfully run whatever comes out of
it. That is the caller's responsibility, and the array-ref form of `cmd`, which
runs the command without a shell, is the way to avoid it:

    task(cmd => ['gzip', '-9', $file]);   # $file is never re-parsed by a shell

Reports of that kind are welcome as documentation bugs rather than as
vulnerabilities in SimpleFlow itself. What *is* in scope is SimpleFlow doing
something with a command, its output, its temporary state or its log that the
caller did not ask for and could not predict from the documentation.

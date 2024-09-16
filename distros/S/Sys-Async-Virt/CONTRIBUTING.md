
# Sys::Async::Virt

The distribution aims to provide the same coverage as the
LibVirt C api, with the notable difference that the C api
offers only blocking calls, even when dispatching to a
remote server while this distribution is aimed *only* at
dispatching remotely and thereby preventing the need to
be blocking at all.

# How to contribute

The project takes contributions in many forms:

1. Provide feedback by filing bugs and enhancement requests
2. Support development by discussing prioritization
3. Analyzing bugs and producing reproduction recipes
4. Issuing code enhancements and test expansion through Pull Requests

Bugs, enhancement requests, discussions and pull requests are handled through
https://github.com/ehuelsmann/perl-sys-async-virt/ .  At the moment, the
project does not have a chat channel, but one can be created, if there's
demand for one.

As you can see, there are many ways to contribute to the project other than
by providing code.

# Building the sources

Based on the protocol description in the LibVirt project, much of the
code in this project can be generated.  The `fill-templates` driver script
extracts the description from the libvirt sources, generating the content
of the `lib/` subdirectory.

The driver script clones the
[LibVirt repository](https://gitlab.com/libvirt/libvirt) in the `../libvirt/`
directory (a sibling of the project root directory), or assumes it's the
libvirt project cloned at the correct commit (and only reads from it), if
it already exists.

The content of the `lib/` directory should never be directly edited.  Instead,
the required changes should be made to the templates in `templates/` or to
the driver script `fill-templates`.

The script is invoked as:

```plain
./fill-templates <libvirt-tag> <version> <dep-version>
```

Where `version` is the version of the distribution that's being generated
and `dep-version` is the minimum version of Protocol::Sys::Virt that the
distribution depends on.

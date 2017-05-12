Parser, compiler, and runtime library for Qstructs
==================================================

Description
-----------

This library implements the core of the [Qstruct structure serialisation system](https://github.com/hoytech/Qstruct). It is designed to be embedded into dynamic implementations such as the [Qstruct perl module](https://metacpan.org/pod/Qstruct) and also to be used by the [Qstruct compiler](https://metacpan.org/pod/Qstruct::Compiler).

Qstruct is heavily inspired by Kenton Varda's [Cap'n Proto](http://kentonv.github.io/capnproto/). Compared to Cap'n Proto, the Qstruct implementation is lighter-weight, written in C99 rather than C++11, and is (in my opinion) easier to integrate with dynamic languages. However, Cap'n Proto has many features that Qstruct doesn't (see their format descriptions for more details).


Building and Installing
-----------------------

In order to build this library you need to install a C compiler such as [gcc](http://gcc.gnu.org) and the [Ragel State Machine Compiler](http://www.complang.org/ragel/).

The library can be compiled by simply running `make`:

    $ make

Optionally you may choose to install the compiled library and header files globally:

    $ sudo make install


Usage
-----

The entry point to the schema parser is the `parse_qstructs` function:

    struct qstruct_definition *parse_qstructs(char *schema, size_t schema_size, char *err_buf, size_t err_buf_size);

This will either return a pointer to a linked list of qstruct definitions or `NULL` on error (in which case `err_buf` will be populated with an error message).

When you are done with the definitions, you should destroy them with `free_qstruct_definitions`:

    void free_qstruct_definitions(struct qstruct_definition *def);

Note that you shouldn't free the `schema` buffer until you have freed the definitions since the definitions keep pointers into the `schema` buffer.

The information in the definitions contains offsets and size information parsed from the provided schema. This information should mostly be considered opaque and should be passed to the inline functions specified in the `qstruct_builder.h` and `qstruct_loader.h` headers.

The reference example of a dynamic implementation is the [Qstruct perl implementation](https://github.com/hoytech/Qstruct).

The reference example of a compiler implementation is the [Qstruct::Compiler C compiler](https://metacpan.org/module/Qstruct::Compiler).


Implementation
--------------

This module is designed to be efficient for both the dynamic and compiler use-cases. For the dynamic use-case, it is important that the schema compiler be efficient because it will be parsed every time your application is started. Efficiency is accomplished by processing the schema with a ragel finite state machine that parses the schema in a single non-backtracking pass. There is another pass over the parsed data to compute offsets. Both of these passes are zero-copy in the sense that none of the schema is copied, only pointers into the schema are recorded.

The schema compiler is thread-safe but not re-entrant (because it calls `malloc`).

For the compiler use-case, the efficiency of the schema compiler is less important. What is more important is creating efficient code for building and loading/accessing messages. These efficient routines can then be embedded into other applications. In this use-case, the same schema compiler is used for consistency with the dynamic case. The difference is that instead of creating new objects/methods, this code is emitted in another language (typically C).

Because the fields in messages are at fixed offsets, in the compiled use-case getters and setters are usually very simple and efficient. They typically do some basic bounds checking and then read from or write to a fixed memory offset. Since the getters and setters are so simple, they are generally inlined to avoid the relatively large function call overhead. Also, inlining allows the compiler to perform various constant-folding optimisations since offset and size parameters are typically constants.


Endianness and Alignment
------------------------

In the Qstruct format all integer and floating point values are in little-endian byte order even on big-endian machines. Because the "in-memory" format is equivalent to the "wire" format, we had to pick one endianess and little-endian is the obvious choice because most modern CPUs are natively little-endian.

By default the routines used are agnostic about CPU byte order and alignment requirements. While these routines should work on every system, they may be slightly slow for some purposes.

If you know for sure you are using a little-endian CPU that doesn't require aligned access, you can define `QSTRUCT_LITTLE_ENDIAN_NON_PORTABLE` when compiling generated loader/builder code. This is advisable for the compiled use-case when using x86 or x86-64 CPUs. For the dynamic use-case, this optimisation will likely be negligible compared to your dynamic language's dispatching overhead.



Author and Copyright
--------------------

Copyright (c) 2014 Doug Hoyte

This library is distributed under the 2-clause BSD license so you can basically do whatever you want with it.

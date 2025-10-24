[![Automated Tests](https://github.com/bodo-hugo-barwich/object-meta/actions/workflows/automated_testing.yml/badge.svg)](https://github.com/bodo-hugo-barwich/object-meta/actions/workflows/automated_testing.yml)

# Object::Meta

Object::Meta - Library to manage data and meta data as one object but keeping it separate

Of special importance is the **Index Field** which is used to create an auto-generated index
in the `Object::Meta::List`. The **Index Field** can also be a **Meta Data Field**.
Also the name of the index does not need to match the name of the **Data Field**.

It does not require lengthly creation of definition modules.

This library is especially optimized for fast startup and high performance.

# Features

Some important Features are:
* Access to data objects by value and by insertion order
* Multiple Indices on same data objects
* Indices on meta data which is not part of the raw data
* Small Memory Footprint
* Fast Startup and High Performance

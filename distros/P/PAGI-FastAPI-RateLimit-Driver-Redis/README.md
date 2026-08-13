# PAGI::FastAPI::RateLimit::Driver::CHI

[![CPAN version](https://badge.fury.io/pl/PAGI-FastAPI-RateLimit-Driver-CHI.svg)](https://metacpan.org/pod/PAGI::FastAPI::RateLimit::Driver::CHI)
[![License: Artistic 2.0](https://img.shields.io/badge/License-Artistic_2.0-blue.svg)](https://opensource.org/licenses/Artistic-2.0)

`PAGI::FastAPI::RateLimit::Driver::CHI` is a storage driver plugin for
[`PAGI::FastAPI::Middleware::RateLimit`](https://metacpan.org/pod/PAGI::FastAPI::Middleware::RateLimit).
It enables `PAGI::FastAPI` applications to leverage any caching backend
supported by Perl's [`CHI`](https://metacpan.org/pod/CHI) framework,
including Memcached, Redis, FastMmap, SharedMemory, and File-based storage.

By delegating state management to `CHI`, rate-limiting hit counters can
easily be shared across multiple web worker processes or distributed
application clusters.

---

## INSTALLATION

Install the distribution from CPAN using your preferred client:

```bash
cpanm PAGI::FastAPI::RateLimit::Driver::CHI
```

## LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

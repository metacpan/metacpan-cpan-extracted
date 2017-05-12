[![Build Status](https://travis-ci.org/marmand/Pod-Weaver-Section-SQL.svg?branch=master)](https://travis-ci.org/marmand/Pod-Weaver-Section-SQL)
[![Coverage Status](https://coveralls.io/repos/marmand/Pod-Weaver-Section-SQL/badge.png?branch=master)](https://coveralls.io/r/marmand/Pod-Weaver-Section-SQL?branch=master)

SYNOPSIS
========

Update your weaver.ini file with

```ini
[SQL]
keywords = SELECT, INSERT, DELETE
```

It will then gather all B<=sql> section into one unique SQL section in your
documentation.

You can let keywords to it's default that is all known SQL::Statement keywords.

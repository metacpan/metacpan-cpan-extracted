#!/usr/bin/env python3
"""Regenerate the frozen table of t/view.size.t.

view() writes the size of its data the way pandas writes a DataFrame's memory
usage, so the expected strings come from pandas itself: _sizeof_fmt() in
pandas/io/formats/info.py, the function DataFrame.info() formats its
"memory usage:" line with. This was run with pandas 3.0.4 on Python 3.14.2.

Run it from the distribution root and paste what it prints over the lines
between "BEGIN GENERATED" and "END GENERATED" in t/view.size.t:

    python3 t/view.size.python.py

The test never runs this script, and needs neither Python nor pandas.

Every byte count is written as m * 2**k with m below 2**32, so that the test
can rebuild it exactly on a perl whose integers are 32 bits and whose NV is a
double: a count that is not such a product is left out. That loses nothing the
format depends on -- a tie in the tenths is always such a product -- and the
counts past 2**53, which only a product reaches, are where "PB" stops growing
a unit.
"""
import random

import pandas
from pandas.io.formats.info import _sizeof_fmt


def as_product(n):
    """n as (m, k) with n == m << k and m < 2**32, or None."""
    k = 0
    while n and n % 2 == 0 and k < 63:
        n //= 2
        k += 1
    return (n, k) if n < 2**32 else None


values = set()

# The first unit, and the first counts past it.  23028 is the example in
# _sizeof_fmt()'s own docstring ('22.5 KB'), and 152 and 1023 the kind of
# count pandas' tests pin for small frames ("{n}.0 bytes" in
# pandas/tests/frame/methods/test_info.py).
values.update([0, 1, 2, 10, 152, 999, 1000, 1022, 1023, 1024, 1025, 1075,
               1076, 1077, 1126, 1127, 1128, 1279, 1280, 1281, 1536, 1791,
               1792, 1793, 2007, 2008, 2047, 2048, 23028])

for s in (10, 20, 30, 40, 50, 60):
    unit = 1 << s
    # either side of each unit
    values.update([unit - 1, unit, unit + 1, 1023 * unit, 1024 * unit - 1])
    for mult in (2, 5, 10, 100, 512, 999, 1000):
        values.add(mult * unit)
    # Exact ties in the tenths: bytes * 10 / unit == q + 1/2, which needs
    # bytes == (2q + 1) * unit / 20, an integer only when 5 divides 2q + 1.
    # Python rounds these half to even, and so must view().
    ties = [q for q in range(10, 10240) if (2 * q + 1) % 5 == 0]
    for q in ties[:24] + ties[-4:]:
        tie = (2 * q + 1) * (unit >> 2) // 5
        values.update([tie, tie - 1, tie + 1])
    # a tenth that rounds up into the next whole number, and the last one
    # into "1024.0" of the same unit
    values.update([251 * (unit >> 7), 32767 * (unit >> 5)])

# past 1024 PB there is no larger unit
values.update([3 << 59, 1 << 63, (2**32 - 1) << 31])

rng = random.Random(20261113)
for _ in range(300):
    values.add(rng.getrandbits(rng.randint(1, 32)) << rng.randint(0, 31))

rows = []
for n in sorted(values):
    p = as_product(n)
    if p is None or n >= 2**64:  # view() counts in 64 bits at most
        continue
    rows.append((p[0], p[1], _sizeof_fmt(n, "")))

print(f"# pandas {pandas.__version__}: {len(rows)} rows of [m, k, text], the bytes being m * 2**k")
for m, k, text in rows:
    print(f"\t[{m}, {k}, '{text}'],")

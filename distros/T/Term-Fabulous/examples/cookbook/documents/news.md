# snapback news

What changed in each release, newest first. From 2.1 on, snapback has
a logo:

![The new logo of snapback, from 2.1 on](../../images/rainbow_circle.png)

## Releases

| Version | Released   | What changed                             |
+---------+------------+------------------------------------------+
| 2.1     | 2026-09-01 | keep all; the report lists big files     |
| 2.0     | 2026-03-14 | compress is off by default; no --all     |
| 1.6     | 2025-11-02 | hooks get the name of the backup         |
| 1.5     | 2025-06-20 | a dry run shows what keep deletes        |
| 1.4     | 2025-01-10 | the last release that runs on Perl 5.10  |
| 1.3     | 2024-08-05 | exclude patterns                         |
| 1.2     | 2024-02-11 | the first release on CPAN                |

## 2.1

- `--keep` accepts `all` to keep every backup.
- The report lists the biggest files that were copied.
- Hooks get the name of the backup directory:
    - `before` as `$SNAPBACK_NEXT`, which does not exist yet;
    - `after` as `$SNAPBACK_LAST`.

Upgrading from 2.0 needs no change to `~/.snapback`.

---

## 2.0

1. `compress` is **off** by default. Turn it on in `~/.snapback` if the
   backup disk is small.
2. The ~~`--all`~~ option is gone; a backup always copies every file
   that changed.
3. A dry run shows the files it would delete to honor `keep`.

> Back up before you upgrade. It is what the program is for.

---

## 1.4

The last release of the 1.x line, kept for people who cannot update
Perl: it still runs on 5.10. Download it from
<https://snapback.example.org/old/> and read the
![notes on the 1.x line](old-notes.png) before you install it.

# snapback

**snapback** copies the files of a directory to a backup disk. It copies
*only* the files that changed since the last run, so the first backup takes
a while and every later one takes seconds.

This manual covers the [installation](#Installation), your
[first backup](#Your%20first%20backup), the [settings](#Settings) and
[hooks](#Hooks). Answers to common questions are in the [FAQ](faq.md).

## Installation

snapback is a single Perl script. Copy it to a directory in your `PATH` and
make it executable:

```shell
cp snapback ~/bin/
chmod +x ~/bin/snapback
```

It needs Perl 5.32 or later and no modules outside the core.

## Your first backup

1. Connect the backup disk and note where it is mounted, for example
   `/mnt/backup`.
2. Make a dry run, which lists the files snapback would copy and copies
   nothing.
3. Run the backup itself. The first one copies every file; later ones copy
   only the changes.

```shell
snapback --dry-run ~/Documents /mnt/backup
snapback ~/Documents /mnt/backup
```

Each run creates a directory named after the date and time on the backup
disk. Files that did not change are hard links to the copy of the run
before, so every backup looks complete but takes only the space of the
changes.

## Settings

snapback reads its settings from `~/.snapback` when that file exists. Options
on the command line win over the file.

```ini
# ~/.snapback
target   = /mnt/backup
keep     = 14
exclude  = *.tmp, .cache/, node_modules/
compress = no
```

- `target` is the backup disk, so you can leave it out on the command line.
- `keep` is the number of backups to keep; see [keeping old backups](#Keeping%20old%20backups).
- `exclude` lists patterns of files that are never copied.
- `compress` is ~~yes~~ no by default since version 2.

### Excluding files

A pattern that ends in a slash excludes a directory and everything in it.
Other patterns match file names anywhere below the directory you back up.
Caches and build directories are good candidates: they are large, change
often, and can be made again.

### Keeping old backups

With `keep = 14`, snapback deletes the oldest backups until fourteen remain,
*after* the new backup has finished. It never deletes the backup it has just
made, even with `keep = 0`.

## Hooks

A hook is a Perl script that snapback runs after every backup, with the
directory of the new backup as its argument. Use it to send a message, to
copy the backup further, or to check it.

```perl
#!/usr/bin/env perl
# ~/.snapback-hook: report every new backup.
use v5.32;
use warnings;

use File::Find;

my ($backup) = @ARGV or die "usage: $0 BACKUP-DIRECTORY\n";
my $files = 0;
find( sub { $files++ if -f $_ }, $backup );    # every file counts, also the hard links to unchanged ones
say "snapback: new backup $backup with $files files";
```

Make the script executable and name it in the settings with
`hook = ~/.snapback-hook`. A hook that fails does not undo the backup;
snapback reports its exit status and keeps going.

## Restoring files

A backup is a plain directory, so restoring is copying. Find the backup of
the day you want, then copy the file back:

```shell
ls /mnt/backup
cp -a /mnt/backup/2026-05-31T22:00/Documents/thesis.odt ~/Documents/
```

> Restore a file now and then, even when nothing is lost. A backup that was
> never restored is a hope, not a backup.

## Troubleshooting

### The disk is full

snapback stops before it copies a file that does not fit, and leaves the
backups that are already there untouched. Lower `keep`, exclude more files,
or use a larger disk.

### A file is copied every time

snapback compares the size and the time of the last change. A program that
touches a file without changing it makes snapback copy it again. Exclude
such files, or check the program that touches them.

## See also

The [FAQ](faq.md), the [settings](#Settings), and the project page at
[snapback.example.org](https://snapback.example.org).

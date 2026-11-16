# Example: Acme::Notes

Read this when you create `SPc.pm` or convert `Build.PL`. It is an
application with a config file, templates, a state directory, and logs.
A real-world variant is `meon-Web` (`Build.PL` with `conffiles` and
`srvdir`).

## Layout

```text
Build.PL
MANIFEST
lib/Acme/Notes.pm
lib/Acme/Notes/SPc.pm
script/acme-notes
etc/acme-notes/notes.ini          -> sysconfdir, conffile
etc/cron.d/acme-notes             -> sysconfdir, conffile
share/acme-notes/templates/*.xsl  -> datadir
var/lib/acme-notes/.exists        -> sharedstatedir, created empty
var/log/acme-notes/.exists        -> logdir, created empty
```

## lib/Acme/Notes/SPc.pm

```perl
package Acme::Notes::SPc;

use warnings;
use strict;

our $VERSION = '0.01';

use File::Spec;
use Sys::Path; # remove after install

sub _path_types {qw(
    prefix
    localstatedir
    sysconfdir
    datadir
    logdir
    sharedstatedir
)};

sub prefix        { Sys::Path->find_distribution_root(__PACKAGE__) };
sub localstatedir { File::Spec->catdir(__PACKAGE__->prefix, 'var') };

sub sysconfdir     { File::Spec->catdir(__PACKAGE__->prefix, 'etc') };
sub datadir        { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub logdir         { File::Spec->catdir(__PACKAGE__->localstatedir, 'log') };
sub sharedstatedir { File::Spec->catdir(__PACKAGE__->localstatedir, 'lib') };

1;
```

After `./Build install` with a `/usr` perl, the installed copy contains
lines like `sub sysconfdir { "/etc" };` and no longer loads `Sys::Path`.

## Build.PL

```perl
use strict;
use warnings;
use Module::Build::SysPath;

my $builder = Module::Build::SysPath->new(
    module_name        => 'Acme::Notes',
    license            => 'perl',
    dist_author        => 'Jane Doe <jane@example.com>',
    dist_version_from  => 'lib/Acme/Notes.pm',
    configure_requires => {
        'Module::Build'          => '0.3607',
        'Module::Build::SysPath' => '0.19',
    },
    build_requires => {
        'Module::Build::SysPath' => '0.19',
    },
    script_files   => ['script/acme-notes'],
    add_to_cleanup => ['Acme-Notes-*'],
);

$builder->create_build_script();
```

Files under `sysconfdir` are conffiles automatically. To protect a file that
lives under another type, add `conffiles => [qw(share/acme-notes/x.conf)]`.

If `notes.ini` held a password, require 0.20 in `configure_requires` and
`build_requires` (older versions ignore the option silently), and
restrict it after install with
`file_modes => { 'etc/acme-notes/notes.ini' => 0640 }`. Set its group outside
the build, because a new file belongs to the installing user. From 0.20 on,
upgrades keep that group.

## Custom build actions

```perl
my $class = Module::Build::SysPath->subclass(code => <<'CUSTOM_BUILDER');
    sub ACTION_install {
        my $self = shift;
        $self->SUPER::ACTION_install(@_);
        # post-install step, for example notifying a running service
    }
CUSTOM_BUILDER

my $builder = $class->new(...);    # same arguments as above
```

## Runtime lookup

```perl
use File::Spec;
use Acme::Notes::SPc;

sub config_file {
    File::Spec->catfile(Acme::Notes::SPc->sysconfdir, 'acme-notes', 'notes.ini');
}
sub notes_dir { File::Spec->catdir(Acme::Notes::SPc->sharedstatedir, 'acme-notes') }
```

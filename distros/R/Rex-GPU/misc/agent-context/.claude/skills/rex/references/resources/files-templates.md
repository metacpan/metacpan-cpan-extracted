# Files, templates, byte fidelity, and ownership

## Select the appropriate abstraction

Use `file` for an owned desired-state file or directory, with content or a controller
source path and explicit permissions. Use line-edit helpers only when their ownership
boundary is clear. A `host_entry` or `delete_lines_matching` operation can call file
interfaces internally; neither becomes exec-only because its purpose is small.
Direct `file_write` opens a truncating handle; it is not the same contract as a
high-level managed file resource.

```perl
file $approved_path,
    content => $validated_content,
    mode => 600,
    on_change => sub { $changed = 1; };
```

Use Rex's documented permission representation; a Perl numeric literal with a
leading zero is an octal number before Rex receives it. Verify the installed API
rather than mechanically changing `600` to `0600`. Test the resulting filesystem
mode, owner, and group. Parent directory access and sudo context matter as well.

## Staging is not a universal durability guarantee

The `file` documentation describes staging new content and replacing the target.
That does not grant every low-level backend operation the same guarantee. Direct
LibSSH Fs upload uses `cat > destination`; File write also uses a channel to the
selected path. Distinguish high-level resource staging from these lower-level APIs.
Atomic visibility, same-filesystem rename, durable persistence, permission retention,
symlink handling, and validation-before-activation are separate properties.

**Practice:** stage sensitive configuration under a private parent, validate before
activation, verify exact bytes after writing, and check metadata afterward. Avoid
reading secrets through `run 'cat ...'` because output can be logged and chomped.
Large binaries require a transfer path with an explicit memory/integrity contract.
Do not hash text after normalization if the artifact requires byte-for-byte fidelity.

## Templates and line editing

The selected feature bundle changes the template engine; specify the one expected
by the project. Keep application inputs explicit, deterministic, and validated. Do
not evaluate templates from untrusted authors with controller credentials available.
Avoid mixing a full-file template with unrelated line writers on the same path.

For surgical edits, anchor regexes to the intended record and account for duplicates,
comments, whitespace, and missing trailing newline. The documented successor
`delete_lines_according_to` supports change callbacks. For structured formats,
prefer parsing and schema validation where preserving the format is tractable;
regex editing of nested YAML, JSON, or TOML is not a general configuration parser.

## Evidence and scope

- [Rex::Commands::File (release documentation)](https://metacpan.org/pod/Rex::Commands::File)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
- [lib/Rex/Interface/File/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/File/LibSSH.pm)
- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)

# Rex backend reproduction

## Expected and observed behavior

Expected: [precise operation/result]. Observed: [first failure, not just downstream symptom].
Controller OS/Perl/Rex: [versions]. Module paths: [sanitized].
Backend and native dependency versions: [versions]. Effective drivers: [classes].
Target OS/shell/tool versions: [versions]. Sudo context: [yes/no and scope].

## Minimal reproduction

[Reviewed, non-secret Rexfile fragment that requires explicit target selection.]
Exact sanitized invocation: [command].
Successful prior probes: [trust/auth/exec/metadata]. First failing probe: [operation].
Raw `$?` captured immediately: [value]. Decoding used: [none or tested driver contract].
Exception: [sanitized full text]. Timeout/remote-process state: [evidence].

## Controls and evidence

Same operation with alternative approved backend: [result/not tested].
SFTP enabled/disabled: [verified state/not known].
File bytes/metadata before and after: [digests, no secret contents].
Pinned source method believed relevant: [URL/commit].
Why this is not yet proof of root cause: [remaining alternatives].

## Regression acceptance

[Test that fails before the fix and passes afterward, including failure paths.]
Unrelated behavior that must remain unchanged: [host-key/sudo/status/bytes/etc.].

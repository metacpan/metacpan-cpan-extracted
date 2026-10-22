# Audit of the supplied Rex skill

The original is preserved byte-for-byte at
[audit/original-skill.md](../../audit/original-skill.md). It is evidence of the old
claims, not active guidance. Line numbers below refer to that archived input.
Corrections distinguish core Rex from the optional LibSSH implementation. No upstream
code was changed and no claim of a complete security audit is made.

| Original claim / lines | Disposition | Replacement and evidence |
|---|---|---|
| Feature bundle 1.4 must always be included, 14/174–175 | Qualify | Explicit feature behavior is recommended; 1.4 is a compatibility bundle, not the installed version or a universal mandate for every library. Core Rex.pm import. |
| Explicit Run/File imports required, 15–16 | Qualify | The `-feature` import already imports the common DSL. Additional imports may document dependencies. Rex.pm. |
| Net::SSH2 is the fixed default, 29 | Correct | Core import can prefer Net::OpenSSH when present. Record the selected backend. Rex.pm. |
| OpenSSH uses SFTP for EVERY file operation, 42–43 | Correct | Common metadata and transfer paths use SFTP; inherited operations can also use exec. Fs::OpenSSH and Fs::SSH. |
| Missing SFTP can cause undef->stat, 42–48 | Retain with diagnosis | Connection SFTP initialization can fail independently of exec, then metadata dereferences the result. Missing subsystem is one cause, not the only cause. |
| LibSSH is the universal answer for provider/SFTP-less hosts, 35–36/48/165–166 | Replace | Choose by required operations, target tools, trust and sudo; repair SFTP or use a traced exec-only path when appropriate. Hosting brand is not a capability. |
| All file operations work without qualifications, 115 | Correct | LibSSH avoids SFTP but has target-tool, buffering, filename, status, and forced-driver sudo limitations. Test the exact interfaces. |
| `run` never needs filesystem support, 54 | Correct | `creates` invokes Fs::is_file before command execution. Run.pm. |
| `pkg` and all facts categorically need no SFTP, 59–62 | Remove blanket promise | Trace provider and gatherer call graphs; repository/local-artifact paths can introduce filesystem operations. No universal negative was established. |
| `auto_die => 0` never croaks, 71 | Correct | It suppresses automatic nonzero-status exceptions only; transport, callback and other failures may still throw. Run.pm. |
| Array-form `sh -c` is "no shell injection", 76–77 | Correct | Arguments are quoted then joined into shell source. `sh -c` still interprets its script as code. Run.pm. |
| Host-key checking disabled by default, 127 | Correct for reviewed modern release | Current LibSSH defaults to verification; explicit connect options and limited openssh_opt mapping control it. Requires the documented Net::LibSSH support. |
| `$?` is always shifted left 8, 171–172 | Correct, not merely invert | Core OpenSSH normalizes right; reviewed extension LibSSH shifts left. Preserve raw status; zero/nonzero is portable for ordinary completion, numeric decoding requires a tested driver contract. |
| Global command policy comes from set_fail_flag, 191–192 | Correct | Run.pm uses Rex::Config->get_exec_autodie when no per-call value is supplied. |
| `<> line N` proves actual crash is in C, 168–169 | Reject inference | Input-position context cannot establish a C crash. Obtain stack/signal/core evidence separately. |
| Rex::Exporter is mandatory, 177–179 | Qualify | Appropriate for Rex registration semantics; ordinary Exporter is valid for pure helpers. Rex::Exporter also does not implement ordinary selective import lists. |
| OpenSSH master always stays around; plain ssh -O exit fixes it, 181–183 | Qualify | Identify the actual Net::OpenSSH control socket/lifecycle and close only that approved master. A generic manual SSH command may address a different connection. |
| int(OS version) is a general solution, 185–186 | Qualify | Preserve the version string; extract major only after validating the format and the policy's needs. |
| Pass arrayref for multi-package pkg, 188–189 | Retain | Keep the documented multi-package shape, then verify provider-specific versions and outcomes. |
| Task names may conflict with imported functions, 195–196 | Retain as namespace safeguard | Use distinct task/helper names; do not rely on redefinition or load-order side effects. |
| gpu_detect is just a neutral inventory step, 134–139 implied | Add missing caveat | The default detector may install pciutils. Sysfs is an optional, differently informative detector. GPU.pm. |
| GPU/Rancher examples imply complete readiness, 139/153–160 implied | Qualify | These are side-effectful multi-stage adapters. Preserve preflight, credentials, ownership, partial-failure and health-check boundaries. |

## Additional implementation findings

**Run return fidelity:** inspected Run.pm chomps stdout/stderr and uses callback
return values. A string-return contract is not a binary transfer guarantee.

**Deferred command options:** the `only_notified` callback invokes only the stored
command. It does not forward all the options supplied to the registration call.
Treat this as a pinned implementation detail; test before depending on it.

**LibSSH output timing:** callbacks occur after the initial stdout read. Do not
promise real-time streaming or remote early termination from that interface.

**LibSSH File versus Fs:** File write sends data through a channel while File read
buffers. Fs upload/download buffer content. The observed File close/read paths do
not show the same explicit status checks as Fs transfers. This calls for failure
injection and readback, not an unsupported declaration that every operation is broken.

**Sudo dispatch:** ordinary factories can select Sudo. Directly forcing Fs::LibSSH
uses its hardcoded Exec::LibSSH path; do not generalize that limitation to every
high-level LibSSH operation under sudo.

## How to use this audit

The replacement references contain the operational procedures; this file records
why the old advice changed. Recheck the installed version before applying source
observations. [Source map](source-map.md) links every inspected implementation.
The original's fixed model, read-only tool allowlist, and invocation lock were removed
from the portable frontmatter; host-specific deployment policy remains external.

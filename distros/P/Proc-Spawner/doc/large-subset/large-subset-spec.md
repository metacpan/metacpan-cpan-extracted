# Proc::ShellSubset::Large: the large shell subset (written 2026-11-01, kept in line since)

This document specifies the large shell subset: the grammar that `Proc::ShellSubset::Large` accepts, what it adds to the parse tree, and the rules that `Proc::ShellSpawn`, which runs the trees, follows at run time. It amends the specification of the base grammar, [`doc/parsers/shell-subset-spec.md`](../parsers/shell-subset-spec.md) (*the base spec* below); rule names such as V3, B3, E1 are those of the base spec. The other names are items of the decision pages of the time (A1, F3, T1, X1, N4, …, recorded where they apply), the user's later decisions (IP1: ShellSpawn runs `echo`, `printf`, `test`, `[`, `true`, `false`, `pwd` inside Perl), and rule E's choices (G2, G4, …: [`large-subset-logical.md`](large-subset-logical.md)). Some names stand for items of different lists: B2 and B3 here (sections 3 and 5) are not the base spec's, and P1 names three items of different days; each place says which. *dash* is dash 0.5.12, *bash* is `bash --posix` 5.2.21.

- Sections 1 to 5 are kept in line with the code. Where a later decision changed a rule, the decision is named there (rule E: [`large-subset-logical.md`](large-subset-logical.md)).
- Sections 7 and 8 are history.
- "Since 0.05" names the first release that has a rule. The labels of measured code (pre-0.01, early-post-0.02, …) are defined in the table at the end of [`../README.md`](../README.md).
- *Settings* are the assignments written before a command (`x=1 cmd`), as in the base spec.

### <a id="my-history-and-decisions"></a>History and decisions

- 2026-11-01: the parser was written and tested, as `ShellSubsetLarge.pm` of the old Project (258 lines); it is now [`lib/Proc/ShellSubset/Large.pm`](../../lib/Proc/ShellSubset/Large.pm). The same day the posix_spawn session applied its patch to `Proc::ShellSubset` ([section 7](#my-section-7)), and made its executor run these trees (now [`lib/Proc/ShellSpawn.pm`](../../lib/Proc/ShellSpawn.pm) and [`lib/Proc/ShellSpawn/Large.pm`](../../lib/Proc/ShellSpawn/Large.pm); [`../pspawn-extensions.md`](../pspawn-extensions.md)).
- The evening of 2026-11-01: `for NAME` without `in` ([section 3](#my-section-3)), applied by the posix_spawn session the same evening ([section 7](#my-section-7)).
- 2026-11-02: here-documents inside `"$( … )"`, and `command` with no arguments.

The decisions came from the checklist page "Shell Large Subset" (item IDs A1, F3, … below) and from the user's message of 2026-11-01: implement the large grammar as an addition to [`lib/Proc/ShellSubset.pm`](../../lib/Proc/ShellSubset.pm), which is asked first, in a module named [`lib/Proc/ShellSubset/Large.pm`](../../lib/Proc/ShellSubset/Large.pm). Where the page offered alternatives and the user had not chosen, Claude took the page's recommendation (A3: A, A4: A, F6 `-x`: A; A4's status was then the user's decision of 2026-11-02, section 5).

## <a id="my-section-1"></a>1. How it works

`Proc::ShellSubset::Large::parse($string, %opt)` returns a List or an error hash, exactly like `Proc::ShellSubset::parse`.

1. It calls `Proc::ShellSubset::parse` with the options `if while for case read assign param_ops` on. If that accepts the snippet, its tree is the answer. So everything `Proc::ShellSubset` accepts keeps its tree and its meaning. For example `pwd` keeps the meaning of the base spec's B2, `pwd -L`: by default it runs inside Perl (since 0.11, IP1); with `PROC_SHELLSPAWN_INPROC=none` it runs the program `/bin/pwd -L`. So F12's "pwd as a builtin" is dropped.
2. If `Proc::ShellSubset` rejects the snippet for any reason other than U1 (a snippet starting with `-` or `+`, section 2, which `sh -c` too would take for options), the snippet is parsed again by the large grammar:
   - First the here-document bodies are cut out of the snippet. Positions in errors still refer to the original snippet.
   - The large grammar is `Proc::ShellSubset`'s own code, run with some of its parts replaced for the time of the call (`local`): the subs `shell`, `P`, `simple`, `command`, `dollar`, `redir`, `arith`, `vname`, `word`, `xc` and `bq`, the tables `%BI` and `%SH`, and the regex `$PIECE`. The replacements are in [`lib/Proc/ShellSubset/Large.pm`](../../lib/Proc/ShellSubset/Large.pm).

Options: those of `Proc::ShellSubset`, except `brace`, which is ignored (brace expansion is bash-only; T1). The `check` callback and the test for NUL characters see the whole original snippet.

## <a id="my-section-2"></a>2. Rules that change

### <a id="my-rules-dropped"></a>Rules dropped

These rules of the base spec do not hold in the large grammar:

- V3: the command name may come from an expansion (`$cmd -l`, `"$EDITOR" f`). It is a Word in `argv->[0]`; what it names is decided at run time (F3).
- B3, V19: `exec cmd` may stand anywhere; it runs cmd and ends the shell (or the subshell it is in) with cmd's status. `exec` with redirections only is accepted (F3). A quoted `"exec"` is `exec` too.
- V5: settings before `:` and `exit` are accepted; they stay set afterwards, as in both shells.
- E1's ban on `$0`–`$9`, `${10}`…, `$#`, `$@`, `$*`, `$$` (F1, F9). At the top level they are as in `sh -c` with no arguments: `$0` is `sh`, `$#` is 0.
- The options `assign` and `param_ops` (they are always on); `IFS`, `OPTIND` and `OLDPWD` may now be read and assigned.

### <a id="my-rules-kept"></a>Rules kept

Every other rule of the base spec holds, in particular:

- V4 for literal `return` statuses (for `exit`, P4 since 2026-11-02: up to 9 digits, section 3);
- V7: no `exec -x`, no `exec` of a builtin;
- V15: the forms of `cd` (`cd -` is now allowed);
- `CDPATH` may not be assigned (`HOME` may be set and unset since 0.05; `PPID` and `LINENO` may be read, not assigned);
- every bash-only construct is rejected (A3, alternative A; since 0.04 rule E decides where dash and bash differ, section 5, and what dash lacks altogether is still rejected).

### <a id="my-new-rules"></a>New rules

These rules are also in `Proc::ShellSubset` ([section 7](#my-section-7)): they fix bugs of `Proc::ShellSubset` found on the way.

- U1: a snippet whose first character other than white space is `-` or `+` is rejected. Perl hands it to `sh -c` with no `--`, so sh takes it as options and fails.
- U2: a pattern that can match a whole file name component `.` or `..` is rejected, because dash's globbing includes `.` and `..` and bash 5.2's does not.
  - Only components that start with a written `.` count (`.*`, `.?`, `"."*`, `x/.*`, `.[!]]*`); `.*perf.*`, `.[!.]*`, `./*`, `"$d"/*` are not affected.
  - The rule is over-strict in `case` patterns, where no files are involved.
  - In the large grammar, rule E (G2, since 0.04) replaces U2: patterns never match `.` or `..`, as in bash, so these patterns are accepted there.
- U3: `` "${x:-`echo \"q\"`}" ``: inside backquotes inside a double-quoted `${…}`, `\"` is `"` for dash and stays `\"` for bash, so dash prints `q` and bash `"q"` (probe bqdq); rejected.
- U4: a redirection target of digits directly followed by `<` or `>` (`x >&2>f`, `x >1>f`): dash reads the digits as the next redirection's descriptor and fails; rejected.
- U5: settings before a command may not use the names a shell sets itself (`UID=5 cmd`: bash fails, since its `UID` is read-only); `IFS` stays allowed. In the large grammar, rule E (G15, since 0.05) changes this for `UID`: where the snippet sets `UID`, it is an ordinary variable, as in dash.

## <a id="my-section-3"></a>3. What the large grammar accepts in addition

### <a id="my-functions-loops-and-parameters"></a>Functions, loops and parameters

- **Functions (F1).** `NAME() BODY`, where BODY is a group, a subshell, `if`, `while`, `until`, `for` or `case`, with its redirections (applied at each call).
  - Rejected: a name that is a keyword; a special builtin (`break continue eval exec exit export readonly return set shift times trap unset`); `local` (dash refuses it); `source` (bash refuses it); `alias` or `unalias` (B1); a body that is a simple command; `function f`.
  - A function named `cd`, `read` or another regular builtin is accepted (3A, [section 5](#my-section-5)).
  - Inside a body, `break` and `continue` do not reach loops outside it.
- **`for NAME` without `in`** (`for a; do`, `for a do`, `for a⏎do`) loops over `"$@"`. The tree is the one of `for NAME in "$@"`, so an executor needs nothing new.
- **`return [n]`** inside a function body (also nested in loops). Since 0.04 it is also accepted elsewhere (rule E, G6: an error at run time, as bash). Also **`shift [n]`** and **`set -- …`**.
- **Parameter forms (F2).** `${N:-w} ${N-w} ${N:+w} ${N+w} ${N:=w} ${N=w} ${N:?w} ${N?w} ${N%p} ${N%%p} ${N#p} ${N##p} ${#N}`, where N is a NAME, a positional parameter or one of `? ! # $ @ *`, with these limits:
  - `=` and `:=` take only a NAME.
  - `@` and `*` with `% %% # ##` are accepted since 0.05, and apply to each parameter, as bash does (rule E, G4); dash applies them to the parameters joined into one value.
  - `${#…}` takes a NAME, a positional parameter, or (since 0.05, below) `#`, `?`, `!`, `$`; not `${#@}` or `${#*}` (G4: rejected).
  - In the word, quotes and backslashes work as in sh, and backslash-newline is removed; both shells agree on the cases checked. In a `%`/`#` pattern, unquoted `* ? […]` are pattern characters.
  - Still rejected in the word: unquoted `~`, `{` and newline. Unquoted `* ? [` in a word that is not a pattern were rejected too before 0.05; since then they are accepted ([below](#my-other-forms)).
  - Bash forms (`${x/a/b} ${x:1:2} ${!x} ${x^^}`) stay rejected.
- **`$@` only where it is split.** Where the shells join `$@` into one value instead (dash with the first character of `IFS`, bash with blanks), it is rejected: in setting and declaration values, redirection targets, the word of `case`, the word of `${N=w}` and of any `${…}` inside double quotes, and here-document bodies. Inside `$( … )` and backquotes it is allowed again.
- **Lengths of special parameters** (since 0.05): `${##}`, `${#?}`, `${#!}`, `${#$}` (the lengths of `$#`, `$?`, `$!`, `$$`), which both shells run.
- **Arithmetic (F10).** The assignment operators `= += -= *= /= %= <<= >>= &= ^= |=` (right-associative, lowest precedence; not as the last operand of `?:`); `$1`, `${10}`, `$#`, `$$` as operands. `++` and `--` stay rejected; an assigned name must be assignable.

### <a id="my-here-documents-read-and-declarations"></a>Here-documents, `read` and declarations

- **Here-documents (F4).** `<<WORD` and `<<-WORD`, several per line, also inside `$( … )`, inside `"$( … )"` nested to any depth, and in function bodies.
  - A delimiter with any quote or backslash makes the body literal. Otherwise `$`, `` ` `` and `\` work in the body as inside double quotes, `"` is an ordinary character, and a line ending in an odd number of backslashes is joined to the next before the end line is looked for.
  - `<<-` removes leading tabs.
  - Rejected: a delimiter with `$` or `` ` ``; a body without its end line; `<<<`; a here-document inside backquotes, or in a `( … )` or `$( … )` that closes on the `<<` line; a `<<` whose body was cut out but which the grammar read as text (`${x#<<E}`); `\"` inside backquotes in a body.
- **`read` with names from expansions** (since 0.05): `read $v`, `read -r "$v" y`. The names are checked when `read` runs:
  - a word that is not a name gives dash's message `read: NAME: bad variable name` and status 2 (bash: status 1; rule A5);
  - a read-only name gives `read: NAME: is read only`, status 2 (also for a written name, as dash; before 0.05 that ended the shell);
  - a name the subset may not set (a shell-set variable such as `PPID`) stops the run with status 248 (A4);
  - no name at all gives `read: arg count`, status 2 (dash; bash reads into `REPLY`).

  A name with `[` (an array element) is still refused.
- **Declarations (F5).** `export NAME[=value]…`, `readonly NAME[=value]…`, `local NAME=value…` (only in a function body). The values are not split; `~` is expanded after `=` and `:` (both shells).
  - Rejected: these without arguments (they list); the command's own name written quoted (`"export" x`); an argument that is not `NAME` or `NAME=…`; settings or redirections on them; `local NAME` without a value (dash keeps the outer value, bash unsets it).
  - `unset NAME` of a name that some function makes `local` is rejected (dash and bash then differ in what becomes visible).

### <a id="my-builtins"></a>Builtins

ShellSpawn runs these builtins itself. The table gives the forms accepted when the arguments are literal; an argument from an expansion is checked at run time.

| Builtin | Accepted | Rejected |
|---|---|---|
| `set` (F6) | `-e -u -f -C -a` and `+…`, combined (`-eu`); `-o`/`+o` `errexit nounset noglob noclobber allexport`; operands, `--`; and those that do nothing here (below, and B2's `set -o history`) | no arguments, `-x`, `-v`, `-n`, other letters, `-o` alone, `-o pipefail` |
| `.` (F7) | one argument | none or two or more |
| `eval` (F7) | anything | |
| `trap` (F8) | ACTION and one or more of `EXIT HUP INT QUIT ABRT FPE PIPE ALRM TERM USR1 USR2 KILL STOP` and `0`, named in any case or by number (P6); ACTION `-` or `''`; a literal ACTION must itself be accepted by the large grammar (with the caller's options) | fewer than two arguments, `-p`, a numeric first argument (a signal for sh), `ERR DEBUG RETURN`, a `SIG` prefix, other signals |
| `wait` (F8) | no argument, process IDs | `%1` |
| `umask` (F12) | no argument, an octal mask, `-S` (P4), a symbolic mode (`g+w,o=rx`, since 0.04) | `-S` with a mask |
| `command` (F12) | no argument (does nothing, status 0); `command -v NAME`; `command [-p] PROGRAM ARGS` (`-p`: P4); `command BUILTIN ARGS` for the regular builtins that ShellSpawn runs (`cd`, `read`, `getopts`, `umask`, `wait`, `jobs`, `fg`, `bg`, `hash`, `type`, `ulimit`; 3A, since 0.05) | `-V`, a special builtin or one left to sh after it, a builtin after `command -p` |
| `getopts` (F12) | `OPTSTRING NAME [ARGS]` | fewer than two arguments, a NAME that is not an identifier or is shell-set |
| `unset` | `[-v\|-f] NAME…` | other options, non-identifiers, shell-set names (`CDPATH`, `PPID`, `LINENO`, …; `HOME` may be unset since 0.05), `NAME[…]` |
| `shift`, `exit`, `return` | no argument or a number (`return`: 0–255; `exit`: up to 9 digits, taken modulo 256, P4) | others |
| `cd` | as before, plus `cd -`, `cd -P`, `cd -L` | |
| `alias` (B1) | `NAME=VALUE…`; queries `alias NAME`; the listing `alias`, anywhere. A definition with literal names and values, as a whole top-level command (not in a compound command, a function, an and-or list, a pipeline or the background), is expanded by the parser; since 0.05 a name or value from an expansion, or a definition in a compound command, a function, an and-or list, a pipeline or the background, is accepted too, and is known only when it runs (P1, below) | a value whose first word is a keyword |
| `unalias` (B1) | `-a`, literal names; anywhere since 0.05, as `alias` (the row above) | others |
| `jobs` (B3) | no arguments, `-p`, `-l`, then `%N`, `%%`, `%+`, `%-` (in pipelines and in `$( )` they list the jobs, as bash: rule E, since 0.04; the job IDs since 0.05) | other arguments |
| `times` (B3) | no arguments | any argument |
| `bg`, `fg`, `hash`, `type` (B3) | anything; `hash` with `-r` or names; `type` with names | `hash`, `type` with other options |
| `ulimit` (B3) | reading one limit: `[-H\|-S][-n -s -c -t -v -l -m -d -f]` | setting a limit (it would change the Perl process), `-a`, `-u` (not in dash) |
| `history`, `fc`, `bind`, `help`, `compopt`, `logout`; `set -o history` (B2) | anything, unless the caller's option `interactive` is `reject` | |
| `set -o vi`, `set -o emacs` (B2) | always (they do nothing in both shells) | |
| `kill` (Q1) | as a program | an argument `-SIGNAME`, `-sig…`, or `SIGNAME` after `-s` or `-l`: both shells refuse the `SIG` prefix |
| `[`, `test` (P5, R1, rule F) | every form: coreutils' `[` decides (by default since 0.10 run inside Perl, `Proc::ShellSpawn::Programs` after coreutils 9.4, IP1; with `PROC_SHELLSPAWN_INPROC=none` the program `/usr/bin/[`), except `s1 < s2` and `s1 > s2` alone (also after `!`), which the executor compares itself, by bytes, as both shells (rule F, since 0.05; POSIX 2024 has them: "collates before/after … in the current locale", the same in the C locale) | other forms with `<` or `>` between two operands (`[ a \< b -a c ]`), unless the caller's option `test_lt_gt` is set (then the program runs them, and fails) |

Still left to sh (`X1`: rejected, so that the caller runs the snippet with `/bin/sh`): `chdir source let declare typeset shopt enable builtin caller dirs pushd popd disown mapfile readarray suspend compgen complete` (`compopt` is one of B2's, above).

Also rejected: a command word starting `NAME[` (`a[1]=x`, `x[a; b]`: bash reads an array), a keyword written as a pattern (`[[`), and settings with shell-set names or `CDPATH` before any command (they may outlast special builtins; `HOME` allowed since 0.05).

### <a id="my-redirections-without-a-command-and-backslash-newline"></a>Redirections without a command, and backslash-newline (D2, 2026-11-02)

- **Redirections alone** (`> file`, `> f | grep x`) run as a command with no words.
- **Settings with redirections** (`x=1 >f`). Dash redirects first and then expands the values; bash does it the other way round. So `x=$(cmd) 2>/dev/null` hides the messages of `cmd` in dash only.
  - Before 0.04 such a command was accepted only when neither the command nor a here-document held `$` or a backquote, and was rejected otherwise (A3).
  - Since 0.04 it is accepted (rule E, category effect, as dash: the values are expanded with the redirections in force).
  - At run time, as dash: redirect, then set. A failed redirection sets nothing and gives status 2.
- **Backslash-newline** is removed everywhere except inside `'…'` and comments (so also inside words, `"…"`, backquotes and `$(( ))`), before parsing, in the same pass that cuts out here-document bodies, as both shells do: `ec\<newline>ho` is `echo`, `i\<newline>f` is the keyword `if`.
- **Still rejected**, because the shells differ:
  - `cmd &>file` (dash: `cmd &`, then `>file`);
  - an input redirection without a command, anywhere (`<file` alone; in `$(<file)` dash gives nothing, bash the file);
  - `/dev/tcp/…`, `/dev/udp/…` as targets (bash opens a socket; checked before Proc::ShellSubset too).

### <a id="my-aliases"></a>Aliases

- **Aliases (B1, 2026-11-03).** An alias defined by a top-level `alias NAME=VALUE` holds from the next line on, as in both shells (on the same line it does not).
  - The parser puts VALUE in place of NAME where NAME is the first word of a simple command, also inside function bodies and `$( … )`. A VALUE that ends in a blank makes the next word a candidate too. A name is not expanded again inside its own value (`alias ls=ls`).
  - `unalias` removes it from the next line on.
  - The tree holds the expanded commands; `alias` itself stays a command, which keeps the executor's table for the text of `eval` and `.`.
  - Snippets that define an alias are parsed by the large grammar only (the base grammar knows no aliases).
- **Aliases known only when they run (P1, the user, 2026-11-03: "go with better aliases"; since 0.05).** Both shells read a snippet one complete command at a time, up to the end of a line (with the here-documents that line starts), and expand aliases while reading.
  - So where an alias definition cannot be known while parsing (a word with an expansion, `alias $1=…`, `alias a="echo $v"`; or `alias`/`unalias` inside a compound command, a function, an and-or list, a pipeline or the background), the parser stops after the end of that line, and the tree ends in a node `{ rest => TEXT, lineoff => N }` (N: the lines before TEXT).
  - The executor parses TEXT when it reaches it, with the aliases defined by then, and runs it in the same shell; TEXT may stop again the same way.
  - Example: `{ alias x=y` / `x` / `}` / `x` gives `x: not found` (line 2 was read before the alias existed), then `y`, as both shells.
  - A form outside the subset in TEXT is found only then: the run stops with status 248 (A4) at that point.

### <a id="my-other-forms"></a>Other forms

- **Forms both shells run alike (P6, since 0.04):**
  - `read -p PROMPT NAME…` (at least one name; also `-rp`; the prompt goes to fd 2, and only when fd 0 is a terminal);
  - `cd -P` and `cd -L` (the last one counts; `--` may follow; `cd -P -` and `cd -L -` stay rejected);
  - a pattern in a redirection target is literal text (`echo a >*.log` writes the file `*.log`: dash, and bash in POSIX mode, M:13);
  - `set -o` with `ignoreeof`, `notify`, `nolog`, and `set -b`, `set +m`, which do nothing in a non-interactive shell;
  - `trap` with the signals EXIT, HUP, INT, QUIT, ABRT, FPE, PIPE, ALRM, TERM, USR1, USR2, named in any case (`int`) or by number, and KILL and STOP, which cannot be caught (both shells answer 0).

  Options of `pwd` other than `-L` and `-P` are rejected, as both shells refuse them (rule Q1). `jobs`, `jobs -p`, `jobs -l` (B3) list the shell's jobs also in a pipeline element and in `$( )`, as bash (rule E, 0.04; dash lists nothing there); in a subshell `( )` both shells list nothing, and so does the subset.

  Also accepted since 0.04, as both shells run them alike: reading `$PPID` (assigning it stays rejected), `export "$name"`, symbolic `umask` modes (`umask g+w,o=rx`), redirections on `cd` (`cd - >/dev/null`).

  Still rejected: `set -m`, `set -o monitor`, `set -o pipefail`; `trap` with a `SIG` prefix (`sigint`: dash refuses it) and with any other signal (`chld`, `65`).
- **Bracket expressions with quotes, expansions or `/`** (since 0.05; the base grammar's V12 rejects them; both shells agree: probes brquote, brslash, dqpword): `grep ^[\>\<]`, `ls [a"]"]`, `^["$v"]`, `[$v]`, `something[^/]*`, also in the pattern of `${x%[…]}`.
  - Quoted characters are members, never operators (also `!`, `^`, `-`, `]`); an unquoted expansion's characters are active.
  - In the tree such a bracket expression spans several Parts: `['*', '^[']`, `'><'`, `['*', ']']`. The executor puts a pattern together whole, with quoted text escaped, before it globs or matches.
  - In pathname expansion a bracket expression containing `/` is none: its `[` is literal (both shells; in a `case` pattern it is a bracket expression as usual).
  - A word that matches no file keeps its text, `[^…]` included (rule E: `^` negates, the executor reads it).
  - Unquoted `{`, `}`, `,`, or a `^` that is not first, inside such a bracket expression stay rejected (`a[b^c]*`; a first `^`, as in `[^/]`, negates).
  - `unset NAME[…]` is rejected (bash's arrays; known issue [X26](../pspawn-known-issues.md#my-x26)).
- **`* ? [` in the word of `${N:-w}` and the like (since 0.05)**: literal where the `${…}` is quoted (`"${1:-sure? [y/N]}"`), active where it is not (both shells).
- **A final backslash (Y2, 2026-11-03)** at the very end of the snippet is a literal `\` (both shells: `echo a\` prints `a\`).
- **Literal braces (P1), expansions inside `$(( ))` (P2), shell-set names both shells let a snippet set (P3), `export $v=…`, `exit N` above 255 (P4)**, 2026-11-02: see [`large-subset-state.md`](large-subset-state.md) and the tests LS:212–245.

## <a id="my-section-4"></a>4. Tree additions (to [section 8 of the base spec](../parsers/shell-subset-spec.md#my-section-8))

```perl
Command  = { func => NAME, body => Command }                 # body: a group, subshell or compound command
         | { export => [NAME, Word or undef, ...] } | { readonly => [...] }
         | { local => [NAME, Word, ...] }
         | { exec => 1, redir => [Redir, ...] }               # exec with redirections only
         | { argv => [], redir => [Redir, ...] }               # redirections alone (D2)
         | { set => [...], redir => [Redir, ...] }           # settings with redirections (D2): redirect, then set
         | { argv => [Word, ...], ... }                       # argv->[0] may now be a Word with expansions
Redir    = [ fd, '<<', Word ]                                 # a here-document: the Word is the whole body
Part     = [ '$', N ], [ '"$', N ]                            # N may also be 0-9 (10... when braced), # @ * $
         | [ '${', N, OP, Word ], [ '"${', ... ]              # OP also = := ? :? % %% # ##
         | [ "'", 'text' ]                                    # quoted text in the Word of an unquoted ${N:-w}
```

- In a `%` or `#` Word, `['*', '…']` Parts are pattern text; Parts that are plain Perl strings are literal.
- In the Word of an unquoted `${N:-w}`, Parts that are plain Perl strings are unquoted text (split with the rest of the expansion) and `["'", …]` Parts are quoted text (not split). `""` there gives `["'", '']`.
- A here-document Word is expanded like a word in double quotes: no splitting, no patterns; its trailing newline is part of it. For `<<-` the tabs are already removed.
- `$((…))` text may now contain assignments and positional parameters.
- `set`, `shift`, `eval`, `.`, `trap`, `wait`, `umask`, `command`, `getopts`, `unset`, `return` are ordinary `argv` commands.
- `cd -P` adds `cd_p => 1` to the `cd` node (P6, since 0.04).
- `fn => 1` on an `argv` command (3A, since 0.05) marks a command whose literal name is both a builtin with checks of its own (`cd`, `read`, `jobs`, `kill`, `pwd`, `umask`, …) and defined as a function somewhere in the snippet. The parser finds such definitions by a loose textual scan, so a name in quotes may count. The builtin's checks are left to run time:
  - if a function by that name is defined by then, it runs;
  - otherwise the expanded words are quoted and parsed again, and the builtin runs as if parsed so (or A4, if that parse rejects them).

  Such a call is never a `cd` node.
- `line => N` on every command (G8, since 0.05), only when the snippet mentions `LINENO`: the line where the command starts. Not in the text of `eval` or of a trap action (there `$LINENO` is rejected).

## <a id="my-section-5"></a>5. Rules for the executor at run time

- **A4:** something outside the subset that shows up only at run time writes `Proc::ShellSubset::Large: … is not supported` to standard error and ends with status 248, like `exit 248` at that point (it ends the whole snippet, or the enclosing subshell, `$( … )`, background chain or pipeline element). Such things are, among others named where they apply (`read` into a shell-set name, a `rest` text, a function's reparse):
  - `eval` or `.` text that the large grammar rejects;
  - a command name from an expansion that names a builtin left to sh (the list `X1` above), as `${x}let` becomes `let` (checked 2026-11-19; a name that becomes one of B2's, such as `fc`, runs it);
  - a trap action from an expansion.
- **The builtins of B1–B3 (2026-11-03)** live in `Proc::ShellSpawn::Builtins`, one function each. The executor looks command names up in the list of tables `@Proc::ShellSpawn::CMDS` (B2: other modules add their own tables in front).
  - `alias` and `unalias` inside the text of `eval` or `.` end with status 248, since the lines of the snippet after them were parsed without the new alias.
  - `history` and the other interactive-only builtins do nothing (status 0). With `run(..., interactive => 'dash')` they behave as in dash: a program of that name, or `not found`, 127; `set -o history`: `Illegal option`, status 2.
  - The texts and statuses of `jobs`, `bg`, `fg`, `hash`, `type`, `times`, `ulimit` are dash's; `hash` and `type` know the paths remembered when commands ran.
  - The alias listing is sorted (bash's order; dash uses the order of its hash table).
- **Exit statuses of the module itself** (the user's decision on A4, 2026-11-02: "2 is too common"). The module makes up only one status; every other status is the one dash would give, but where rule E chose bash's (`cd` with `HOME` unset: below; `return` outside a function: section 3).

| Status | Meaning |
|---|---|
| 248 | Something outside the subset showed up only at run time (A4). 248 = 250 − 2: sh's status for a syntax error, moved out of the range that commands commonly use. |

- **Dialect choices.** Where dash and bash differ, rule E holds since 0.04 (the user, 2026-11-03; it replaces A3): the plainly logical behaviour where there is one, otherwise rejection; a difference that shows only at run time follows dash (A5), unless rule E chose bash's (the list below). The choices, item by item, with their categories: [`large-subset-logical.md`](large-subset-logical.md).
- **A5:** where dash and bash differ only at run time, do what dash does:
  - `shift` past the end, `export`/`unset`/`local` of a bad name from an expansion, `local` outside a function reached through a dynamic name, and an assignment to a readonly variable stop the shell with status 2;
  - `${x:?w}` stops with 2;
  - `cd` with `HOME` unset: before 0.04 it stayed and succeeded, as dash; since 0.04 it is an error, `cd: HOME not set`, status 1, as bash (N4, rule E);
  - `command -v` of an unknown name gives 127;
  - `getopts` with grouped options sets `OPTIND` as dash does.
- `eval` and `.` parse with `Proc::ShellSubset::Large::parse`; `.` searches only `PATH` for a name without `/`.
- `$$` (F9) is the Perl process's ID when the snippet started, also in subshells; `kill … $$` is taken by the shell itself (its trap, or the status of a death by that signal).
- `command -v` prints the name for `echo printf test [ kill true false pwd`, as both shells do, although they run as programs (all but `kill` inside Perl by default, IP1: since 0.10, `pwd` since 0.11).
- Patterns never match `.` or `..` (rule E, category harm, as bash; also from expansions).
- **3A** (the user, 2026-11-03; since 0.05): POSIX's order of lookup. A special builtin comes first (no function may take its name), then a function, then the other builtins and the commands run as programs. `command NAME` skips the function; it also reaches the regular builtins that ShellSpawn runs (`cd`, `read`, `getopts`, `umask`, `wait`, `jobs`, `fg`, `bg`, `hash`, `type`, `ulimit`), with their checks done at run time; `command -p` still takes only programs. No function may be named `alias` or `unalias` (their calls must be known at parse time, B1).
- **Rule-E choices of 0.05** ([`large-subset-logical.md`](large-subset-logical.md)):
  - `${@#p}` and `${*%p}` act on each parameter (as bash);
  - `$LINENO` is the line where the command starts (as bash);
  - `UID` is an ordinary variable where the snippet sets it (as dash);
  - `~` without `HOME` is the home of the password file (as bash; `HOME` may be set and unset);
  - `break` and `continue` in a subshell inside a loop end the subshell with status 0 (as dash; also in `$( )` and in a pipeline element).

  Also since 0.05, `jobs` takes `%N`, `%%`, `%+`, `%-` (both shells do), with dash's message and status 2 for a job that does not exist.

## <a id="my-section-6"></a>6. Not done

- [`verify.pl`](../parsers/tools/verify.pl) (trees checked against the shells with recording programs) knows only `Proc::ShellSubset` trees; the large subset's behaviour is checked instead by the batteries and the corpus run ([`large-subset-state.md`](large-subset-state.md#my-section-7), section 7).

Done since 2026-11-02: the executor runs these trees ([`lib/Proc/ShellSpawn/Large.pm`](../../lib/Proc/ShellSpawn/Large.pm)), and the differences from dash that [`tools/large-subset-difffuzz.pl`](tools/large-subset-difffuzz.pl) found, L1–L5, are fixed ([`doc/pspawn-known-issues.md`](../pspawn-known-issues.md)); U1, U2, U4 and U5 are in [`lib/Proc/ShellSubset/Small.pm`](../../lib/Proc/ShellSubset/Small.pm) too.

## <a id="my-section-7"></a>7. Changes to [lib/Proc/ShellSubset.pm](../../lib/Proc/ShellSubset.pm) (history: the patches of 2026-11-01/02, now in lib/)

The old Project kept these changes as patches (`claude/large-subset-shellsubset.patch` and those named below), made against `Proc::ShellSubset` with the P1 fix of 2026-11-01 (`claude/pspawn-parser-setting-name.patch`) applied. The patches are not shipped; their changes have been in [`lib/Proc/ShellSubset.pm`](../../lib/Proc/ShellSubset.pm) since.

- Its tables and regexes (`%KW %BI %SH $NM $END $B $BN %STOP $PIECE $ARITH`) become package variables (`our`), and `%EX` calls `dollar` and `bq` by name, so `Proc::ShellSubset::Large` can replace them for the time of its parse. No change in behaviour.
- `claude/large-subset-forall.patch` (evening of 2026-11-01, applied the same evening): a package variable `$FORALL`, set by `Proc::ShellSubset::Large` only, lets `for NAME` without `in` through, as `for NAME in "$@"`. Without it set, nothing changes: the 222 tests of `shell-subset-tests.pl` and the 612 of `shell-subset-corpus-tests.pl` give 0 unexpected results (222/0, 612/0), and 0 of 1,185 snippets differ from `Proc::ShellSubset::Small`.
- U1–U5 ([section 2](#my-section-2)), with tests OWN:208–222 in [`shell-subset-tests.pl`](../../t/parser/shell-subset-tests.pl); three corpus tests that relied on the old behaviour now expect rejection (NB:11515, NB:6367, BC:ch16/run_screen:48).
- `claude/large-subset-d2-base.patch` (2026-11-02): the check for `break`/`continue` in a pipeline no longer reads the first word of a command that has none (a warning with redirections alone). No change in behaviour: 222/0, 612/0 (as above).

## <a id="my-section-8"></a>8. Tests and measurements

The results of this section were measured on the code labelled pre-0.01 and 0.01 (the labels: the table at the end of [`../README.md`](../README.md)). Those of 0.03 are in [`large-subset-state.md` as shipped in 0.03](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-state.md), section 3, and in [`large-subset-dialect-features.md`](large-subset-dialect-features.md#my-section-8), section 8; the test counts of 0.03 are given below in parentheses.

### <a id="my-the-parser-tests"></a>The parser tests

- [`t/parser/large-subset-tests.pl`](../../t/parser/large-subset-tests.pl) (then `claude/large-subset-tests.pl`): 171 tests in 0.01 (LS:n; 0.03: 232), 23 of them compare the whole tree (also in 0.03). With `-s` it also gives every accepted snippet to `dash -n` and `bash --posix -n`. 0 unexpected.
- [`shell-subset-tests.pl`](../../t/parser/shell-subset-tests.pl): 222 tests, and [`shell-subset-corpus-tests.pl`](../../t/parser/shell-subset-corpus-tests.pl): 612, both with 0 unexpected with the patch (pre-0.01; 0.01 and 0.03 have the same 222 and 612 tests, 0 unexpected).
- [`t/parser/large-subset-crosscheck.pl`](../../t/parser/large-subset-crosscheck.pl) (then `claude/large-subset-crosscheck.pl`) runs the 834 snippets of the two `Proc::ShellSubset` test files. Of those that `Proc::ShellSubset` rejects, the large parser accepted 77 (pre-0.01; 0.01: 86; 0.03: 103). Dash and bash accept the syntax of all 77 (and of all 86 and all 103: the script checks them).

### <a id="my-a-review-and-fuzzing"></a>A review and fuzzing

Before 0.01 a separate agent, which had not seen the work, reviewed it: it fuzzed about 170,000 snippets and checked its findings in both shells. It found 25 problems.

- All are fixed, with tests LS:150–182 and OWN:214–222, except the run-time differences of `getopts`, now under A5. (The other one kept at first, here-documents in `"$( … )"`, is accepted since 2026-11-02.)
- Fuzzing again after the fixes found no crashes, no warnings, and no accepted snippet whose syntax a shell rejects. The remaining differences in behaviour are run-time cases of A4 and A5.

### <a id="my-corpus-acceptance"></a>Corpus acceptance

Measured with 0.01 (the parser of 0.02 too) on 2026-11-02, with D2, the tldr rules and ShellCheck (`shellcheck -s dash`) as the detector of bash-only constructs; the details are in [`large-subset-ceiling.md` (0.03)](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-ceiling.md) (in Proc-Spawner 0.03). The *POSIX ceiling* is the share of the samples that both shells parse and in which the detector finds no bash-only construct. The ShellCheck results were corrected on 2026-11-03 to those of the ceiling document.

| Source | Accepted | POSIX ceiling |
|---|---|---|
| tldr | 98.8% | 99.2% |
| NL2Bash | 92.1% | 94.6% |
| bash Cookbook | 30.9% | 37.0% |
| pure-sh-bible | 95.5% | 100% |
| pure-bash-bible | 39.3% | 44.3% |
| ShellCheck, clean | 58.7% | 67.2% |
| ShellCheck, warned | 57.6% | 61.7% |

The results of the morning of 2026-11-02 (pre-0.01), kept for comparison, used the older ceiling, whose detector was a set of regular expressions. They count whole samples (scripts whole), first accepted by `Proc::ShellSubset` with all options, then by `Proc::ShellSubset::Large`, and the POSIX ceiling of that investigation:

| Source | `Proc::ShellSubset` | `Proc::ShellSubset::Large` | POSIX ceiling |
|---|---|---|---|
| tldr | 97.7% | 98.3% | 98.8% |
| NL2Bash | 89.5% | 92.1% | 93.6% |
| bash Cookbook | 14.8% | 30.9% | 43.2% |
| pure-sh-bible | 47.7% | 93.2% | 93.2% |
| pure-bash-bible | 28.7% | 38.5% | 48.4% |
| ShellCheck, clean | 42.1% | 58.4% | 69.4% |
| ShellCheck, warned | 45.6% | 56.5% | 71.2% |

What was still rejected within the ceiling was almost all deliberate: builtins left to sh (`alias`, `history`, `jobs`, `source`, `help`, `type`, …), tldr's placeholders (`<r>`, `...`), listing forms (`set`, `set -o`, `trap`), `$( … )` inside `$(( ))`, `cd -P`, `return` outside a function. Script: [`tools/large-subset-remeasure.pl`](tools/large-subset-remeasure.pl) (then `claude/large-subset-remeasure.pl`; it needs `large-scan.jsonl` from [`tools/large-subset-scan.pl`](tools/large-subset-scan.pl)).

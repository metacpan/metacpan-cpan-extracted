# Shell subset for Perl: decided rules and parse data structure

Status: round 1 decisions plus corrections from chat, as of 2026-10-29; the parse tree (section 8) was reworked and V14–V20 added while writing the parser; Go items C1–C9 (C5 and C7 behind options, C6 narrowed) and question Q1 of the checklist, and the compound commands and `read` (options, decided in chat on 2026-10-29) "Shell Subset Corpus Round" are applied. Item IDs (P1, E3, …) refer to the checklist page "Perl Shell Subset", where each decision and its discussion are kept. Rules marked with a V-number, such as **(V3)**, are provisional: I chose them while writing this spec. Section 10 lists them for the next checklist round.

## 1. Purpose

Perl's `system()`, `exec`, `qx` and piped `open()` hand a command string to `/bin/sh -c` whenever it contains a shell metacharacter. The goal is a sub-dialect of the Bourne shell that Perl can recognize and parse itself:

- A **parser** takes the string and returns either a parse tree (section 8) or a **rejection** (section 7).
- A rejected string is run with `/bin/sh -c`, as Perl does today (Q2).
- How a parse tree is executed (fork or no fork, `posix_spawn`, and so on) is a separate topic. Notes for the executor appear where a rule depends on it.

The rules aim at the same result as `sh -c`, whether `/bin/sh` is dash or bash. Where dash and bash differ, the construct is rejected unless this document says otherwise (P2, D3). Accepted differences from one of the shells:

- `time` runs the program named `time`, as in dash; bash's keyword times the whole pipeline (P5).
- `echo` and `pwd` run as programs, not as builtins (B2; see section 4).

## 2. Characters and quoting

- The parser works on the Perl string as given. Only ASCII characters can be operators, quotes or separators; every other character is an ordinary word character. The executor passes arguments to the system exactly as Perl's own `system()` would.
- A caller may supply a checker that rejects strings which `/bin/sh` would read differently in the current locale, for example Shift_JIS text in which the second byte of a character equals `\` or `|` (C4). By default there is no such check.
- Words are separated by spaces and tabs (besides operators and newlines) (C2).
- NUL is rejected anywhere. Other unquoted control characters (code points 1–31 and 127, except tab and newline) are rejected; quoted ones are part of the word (C2).
- An unquoted `^` is an ordinary character, as in dash and bash; inside `$((…))` it is the XOR operator. The caller's option `nocaret` rejects it instead, because the original Bourne shell reads it as `|` (C1; default swapped by corpus-round item C3). It is always rejected inside a bracket expression `[…]`, where bash reads it as negation and dash as a literal **(V1)**.
- Quoting follows sh (C3):
  - `'…'`: everything literal.
  - `"…"`: literal except `$`, `` ` `` and `\`. A backslash is special only before `$`, `` ` ``, `"`, `\` and newline; elsewhere it stays.
  - `\x` outside quotes: x literally.
  - Backslash-newline is removed while tokenizing, except inside single quotes and inside comments: line continuation (C3). Inside an unquoted word (`a\⏎b`, `2\⏎>f`) and inside backquotes it is rejected **(V14)**.
- An unquoted `#` at the start of a word starts a comment, which runs to the end of the line (E5).
- Rejected bash forms: `$'…'`, `$"…"`, `$[…]`.
- A `$` is a literal character when it starts no expansion: at the end of a word, or before any character except a letter, `_`, a digit, `{`, `(`, one of `@ * # ? $ ! -`, `'`, `"` or `[`; inside double quotes also before `'` and before the closing `"` (corpus-round item C1; replaces V2). Still rejected (bash only): `$'…'` and `$"…"` outside double quotes, and `$[…]`.

"Unquoted" below means: not inside `'…'` or `"…"`, and not right after a backslash.

## 3. Lists and pipelines

- A string is a **list** of **and-or chains**, separated by `;`, `&` or newlines (P1, P2).
- An and-or chain is one or more pipelines joined by `&&` or `||`. `&` after a chain runs the whole chain in the background, and the next chain starts at once: `a && b & c` runs `a && b` in the background, then `c` (P2). Executor note: in a non-interactive shell, a background chain gets its standard input from `/dev/null`.
- A newline acts like `;`. Newlines at the start, after another newline, and after `;`, `&`, `|`, `&&`, `||`, `(` or `{` are ignored (P1).
- An empty, blank or comment-only string is rejected by default (D5). A caller's option accepts it as an empty list (sh does nothing and exits with 0).
- Bash's `&>file`, `&>>file` and `|&` are rejected (P2).
- A **pipeline** is one or more commands joined by `|`. It may start with one `!`, which inverts its exit status (P5); `! !` is rejected (dash reports a syntax error). The `!` must be followed by a blank; a word `!` anywhere else in command-name position is rejected **(V16)**.

## 4. Commands

A command is one of:

- a **simple command**: environment settings, words and redirections (sections 5, 6);
- a **subshell** `( list )`, followed by optional redirections (P3);
- a **group** `{ list; }`, followed by optional redirections (P4). Unlike a subshell, it runs in the same shell;
- a **cd command** `cd [DIR]` (see below);
- with the caller's options, a **compound command** `if`, `while`, `until`, `for` or `case` (see below).

Rejected (P3, P4, P5):

- These keywords as a command name: `if then else elif fi case esac for while until do done in [[ ]] function select coproc`, except where the options for compound commands allow them (see below). In argument position they are ordinary words.
- Function definitions `f() …`.
- `((` at the start of a command (dash reads `((a))` as two nested subshells, bash as arithmetic). `$((` always starts arithmetic.
- `<(…)`, `>(…)`, `@(…)` and the other extended globs, and arrays `a=(…)`.
- Unquoted `{` or `}`, except as the words that open and close a group, `{}` anywhere in a word (literal, as in `find … -exec cmd {} +` or `xargs -I{}`; bash expands braces only with a comma or `..` inside; corpus-round item C2), and, with the caller's option below, brace expansion. Bash's `{fd}>file` is always rejected.
- Brace expansion (`f{,.bak}`, `{1..3}`) is bash-only. Like patterns (E3), it is a caller's option: with it, an unquoted `{a,b,…}` or `{x..y}` in a word becomes a `brace` part of the parse tree (section 8), and the caller decides what to do with it. Without the option it is rejected **(V13)**.

### Simple commands

- **Environment settings** `NAME=value` are recognized only before the command name, with NAME unquoted and matching `[A-Za-z_][A-Za-z0-9_]*`. After the command name, `NAME=value` is an ordinary argument. Before the command name, a word starting with `NAME+=` is rejected (B4).
- Setting values are expanded (section 5) but never split into words or matched as patterns. Settings take effect left to right: in `A=1 B=$A env`, B gets 1.
- Every simple command must have a command name. A command with only settings or only redirections (`A=1`, `>file`) is rejected (D5). So a string cannot set shell variables (E1).
- With the caller's option `assign` (corpus-round item C5), a command with only settings and no redirections is accepted, as the command kind `{ set => [NAME, Word, ...] }`. The executor keeps the string's own variables in a table: `$NAME` looks there first, then in `%ENV`. Assigning a name already in `%ENV` also changes it for later commands (sh exports every variable it imported), `PATH` included; a new name is not exported. Inside `( … )`, `$( … )`, a background chain or an element of a pipeline of more than one command, the assignment is lost at the end of that part. The command's status is that of its last command substitution, or 0. Still rejected: settings with a redirection, the names E1 rejects (section 5), and assignments to `HOME` and `CDPATH` (the parser checks those two in `%ENV`).
- The command name and the word after `exec` must be literal words: no expansion, no pattern **(V3)**.
- Builtins (B1, B2, B3):
  - `:` does nothing and succeeds. Its arguments are still expanded, so command substitutions in them run, and its redirections are applied: `: >f` creates f.
  - `exit [n]` stops the shell with status n, so nothing after it in the string runs, or with the status of the last command when n is absent. n must be a literal number from 0 to 255 **(V4)**. Inside `( … )`, `$( … )`, a background chain, or a pipeline of more than one command, it stops only that part: `exit 3 | cat; echo $?` prints 0.
  - Settings before `:` or `exit` are rejected, because POSIX shells keep them after the command **(V5)**.
  - A redirection error on `:` or `exit` (as in `: >/nonexistent/f`) stops the shell in dash (status 2) and `bash --posix` (status 1), while bash goes on. The executor follows dash **(V6)**.
  - `exec cmd …` runs cmd in place of the shell, so nothing after it runs: in `{ a; exec b; } >f; c`, b writes to f and c never runs (dash and bash alike). So `exec` is accepted only where nothing could follow it (B3):
    - it is the last pipeline of the last and-or chain of its list (`exec a && b` and `exec a; b` are rejected);
    - if that list is the body of a group, the group must in turn be last in its own list, and so on outwards (`{ a; exec b; } >f; c` is rejected);
    - this check stops at the whole string, at a subshell `( … )` or `$( … )`, at a background chain, and at an element of a pipeline of more than one command, because there `exec` replaces only that part;
    - the pipeline does not start with `!`: `! exec false` exits with 1 in dash and bash, the `!` is lost **(V19)**.
  - `exec` without a command, followed by a word starting with `-`, or followed by a builtin name (`exec cd`, `exec :`, `exec exit`) is rejected **(V7)**.
  - `echo` and `pwd` run as the programs `/bin/echo` and `/bin/pwd` (B2). Known differences from the builtins: dash's echo turns `\n` and other backslash sequences into characters, and `/bin/echo` does not; after `cd` through a symbolic link, builtin `pwd` prints the logical path, `/bin/pwd` the physical one. Since post2-0.03 the executor runs `/bin/pwd -L` with `PWD` set to its own directory, which prints the logical path too (known issue X23).
  - `printf`, `test`, `[`, `kill`, `true` and `false` run as programs found in `PATH`. Job numbers such as `kill %1` then do not work.
  - Rejected as command names (`break`, `continue` and `read`: except as allowed under "Compound commands" below): `. break continue eval export readonly return set shift times trap unset alias unalias read wait umask ulimit jobs fg bg command getopts hash type fc chdir local`, and the bash builtins `source let declare typeset shopt enable builtin caller dirs pushd popd disown mapfile readarray suspend logout help history bind compgen complete compopt`.

### cd

- `cd WORD` and `cd` alone become a vertex of their own in the parse tree (section 8). The word may contain expansions (corpus-round item C8). The executor expands it: one non-empty field not starting with `-`: change to it; no field, or `cd` alone: change to `$HOME`; one empty field (as in `cd "$x"` with `x` empty, or `cd ''`): stay, with status 0, as both shells do; a field that is `-` or starts with `-`, or two or more fields: fail with status 2 (two or more fields: dash's status; bash says "too many arguments" with status 1).
- Rejected at parse time: a literal argument that is `-` or starts with `-`, more than one argument, settings or redirections on `cd`, and any `cd` when `CDPATH` is set in `%ENV` **(V15)**; also `cd` alone and any `cd` whose argument has an unquoted expansion when `HOME` is not in `%ENV`.

### Compound commands (options `if`, `while`, `for`, `case`)

Each construct is accepted only with its own option, off by default. All may be followed by redirections, which apply to the whole construct (`while read l; do …; done <file`). Each part (condition, body) must contain at least one command, except a `case` item's body. Reserved words are recognized only unquoted and in command position, as in sh.

- `if LIST; then LIST; [elif LIST; then LIST; …] [else LIST;] fi` (option `if`). Not quite `A && B || C`: the `else` part runs only when the condition fails, not when the `then` part fails, and an `if` whose condition fails and has no `else` has status 0.
- `while LIST; do LIST; done` and `until LIST; do LIST; done` (option `while`).
- `for NAME in WORD…; do LIST; done` (option `for`). `for NAME` without `in` is rejected: it loops over `$@`, which is always empty here (section 5). NAME follows the rules for assignments (option `assign`, section 4): not a name the shell sets itself, not `HOME` or `CDPATH`. The executor keeps it in the same variable table as assignments.
- `case WORD in [(]PATTERN[|PATTERN…]) LIST;; … esac` (option `case`); the last `;;` before `esac` may be left out. Patterns are words; their unquoted `*`, `?` and `[…]` match as in file name patterns, without the file system.
- `break [N]` and `continue [N]` are accepted inside a `while`, `until` or `for` body, with N a literal number from 1 to the number of enclosing loops. Rejected: outside a loop; inside `( … )`, `$( … )` or backquotes within the loop; in a pipeline of more than one command; with settings or redirections. Each of these runs in a subshell or would be a no-op in sh.
- `exec` (B3): in an `if` condition and anywhere in a loop's condition or body something can follow it (the branch, or the next iteration), so it is rejected there; in an `if` branch or a `case` item it is checked as in a group.
- `read [-r] NAME…` (option `read`): reads a line from standard input and sets the NAMEs, which follow the same rules as `for` and assignments. Settings before it (`IFS= read -r line`) apply only to that `read`; the executor uses that `IFS` for splitting the line. `read` without a NAME, or with other options, is rejected.

## 5. Expansions

Parameter expansion, arithmetic expansion and command substitution are allowed both unquoted and inside double quotes (Q1). Tilde expansion and patterns apply only to unquoted text.

### Parameters (E1)

- Allowed forms: `$NAME`, `${NAME}`, `$?`, `${?}`, `$!` and `${!}`; with the caller's option `param_ops` (corpus-round item C7) also `${NAME:-word}`, `${NAME-word}`, `${NAME:+word}`, `${NAME+word}` and `${#NAME}`. All other forms are rejected, among them `${NAME%…}`, `${NAME#…}`, `${NAME:=…}` and `${NAME:?…}`.
- The word in those forms may contain literal text and blanks, `$NAME`, `${NAME}`, `$?`, `$!`, the same forms nested, `$( … )` and `` `…` ``. It may not contain quotes, backslashes, `~`, `*`, `?`, `[`, `{` or a newline: sh expands `~` and patterns there, and treats quotes inside the word differently within double quotes.
- `$?` is the status of the last command, 0 at the start; `$!` is the process ID of the last background chain, empty if there was none (corpus-round item C6, narrowed to these two). The positional parameters `$0`–`$9`, `$#`, `$@`, `$*` stay rejected: Perl passes no arguments to `sh -c`, so in a `system` string they are always empty (and `$0` is always `sh`); a string that uses them was most likely copied from a script by mistake, and is left to `/bin/sh -c`, which gives the same values. Code that needs arguments uses the list form of `system`.
- The value is read from `%ENV`; an unset name gives an empty string.
- Rejected names, because a shell sets them itself:
  - the special parameters `$0`–`$9`, `${10}` and up, `$$ $# $@ $* $-`;
  - set by both dash and bash: `IFS PS1 PS2 PS4 OPTIND PPID OLDPWD LINENO _`;
  - `PWD` only with the caller's option `nopwd`. Otherwise `$PWD` is allowed (corpus-round item C4): the executor gives it the value both shells give it at startup, which is `$ENV{PWD}` if it starts with `/` and names the current directory, and otherwise the physical current directory. "Names the current directory" means the same device and inode where `stat` reports an inode, otherwise the same canonical path (`Cwd::abs_path` of both). After a `cd` inside the string, `$PWD` and the `PWD` passed to later commands follow it;
  - set by bash: `BASH BASHOPTS BASHPID DIRSTACK EPOCHREALTIME EPOCHSECONDS EUID FUNCNAME GROUPS HISTCMD HOSTTYPE MACHTYPE OPTERR OSTYPE PIPESTATUS POSIXLY_CORRECT RANDOM SECONDS SHELLOPTS SHLVL SRANDOM UID`, and every name starting with `BASH_`, `COMP_` or `READLINE_`;
  - `PATH`, `SHELL`, `TERM` and `HOSTNAME` only when they are not in `%ENV`, because the shells then set a default **(V8)**.

For future reference, the forms rejected now, with what the discussion found about them:

- `${x:-w}`, `${x-w}`, `${x:+w}`, `${x+w}`: inside double quotes, quotes within w are kept literally (`"${x:-'a'}"` gives `'a'`).
- `${x%w}`, `${x%%w}`, `${x#w}`, `${x##w}`: w is a pattern matched against the value, not against file names; inside double quotes, quotes within w are removed (`"${x#'a'}"`).
- `${x:?w}`, `${x?w}`: when x is unset (or empty, with `:`), print w and stop the shell, wherever the expansion appears: in `echo a; : ${x?oops}; echo after`, `after` never runs. Inside a subshell or a pipeline element only that part stops. The exit status differs: dash 2, bash 127 (1 inside a subshell).
- `${#x}`: the length of the value.
- `${x:=w}`, `${x=w}`: assign to x, which E1 excludes in any case.

### Arithmetic (E1)

- `$((expr))` with parentheses, the operators `+ - * / % << >> < <= > >= == != & ^ | && || ! ~ ?:`, constants in decimal, octal (leading `0`) or hex (`0x`), and bare variable names.
- A variable's value must be a decimal integer; anything else is an error at run time. (Bash evaluates a value such as `1+2` as an expression, dash reports an error) **(V9)**.
- `$NAME`, `${NAME}`, `$?` and `$!` may appear inside the expression (corpus-round items C9 and C6). The executor substitutes their values as text, then checks the result against the same expression grammar; if it does not fit, it stops with status 2, as dash does (bash: status 1; like V6, this deliberately follows dash): the whole string, or only the enclosing `( … )`, `$( … )`, background chain or pipeline element, as for `exit`.
- Rejected: assignment operators (`=`, `+=`, …), `++` and `--`; bash's `base#digits` constants; other uses of `$`, and `` ` `` inside the expression **(V9)**.

### Command substitution (E2)

- `$( list )` and `` `list` ``. Both contain a full list (section 3). `$( )` with an empty list is accepted and gives an empty string; empty `( )` and `{ }` are syntax errors in sh and rejected **(V20)**.
- Backquotes (Bourne's reparsing): the text runs to the first backquote not preceded by a backslash, whatever quotes it passes; that text, with its escapes undone (below), is then parsed as a separate string. dash and bash agree here: in `` echo `echo '`'` `` both report an unterminated quote. `$( … )` needs no such second pass: it is parsed recursively in one go.
- The output replaces the expansion, with trailing newlines removed.
- Inside backquotes, a backslash before `$`, `` ` `` or `\` is removed before the inner text is parsed; `$( … )` has no such step.

### Tilde (E4)

- `~` and `~user` at the start of an unquoted word, and after `=` or `:` in environment settings. `~` becomes `$HOME`; `~user` becomes that user's home directory from the password file.
- `~` is rejected when `HOME` is not in `%ENV` (dash then leaves it literal, bash uses the password file) **(V10)**. `~+` and `~-` are rejected (bash only). After `~`, only a user name (letters, digits, `.`, `_`, `-`; not starting with `-`) may come before `/` or the end of the word (or `:` in settings); anything else, such as `~"root"` or `~$x`, is rejected **(V18)**.
- A caller's option also expands `~` in arguments that start with a valid `NAME=`, after the `=` and after each `:` (bash outside POSIX mode, as in `make PREFIX=~/x`). Without the option it stays literal, as in dash and in bash running as `/bin/sh`.

### Word splitting and patterns

- An unquoted parameter, arithmetic or command expansion is split into words at spaces, tabs and newlines. The string never sets IFS (E1), so this default always applies. An unquoted expansion that gives an empty result produces no word.
- A word with an unquoted `*`, `?` or `[`, or with an unquoted expansion, is a possible **pattern**. The caller decides whether to expand it, refuse it, or fall back to `/bin/sh -c` (E3). A pattern that matches nothing stays as it is. The word `[` alone is literal (the test command).

### Here-documents (D1)

`<<`, `<<-` and `<<<` are rejected.

## 6. Redirections

- Operators: `<`, `>`, `>>`, `<>`, `>|`, `<&`, `>&` (D2). They may appear anywhere in a simple command, also before the command name, and are kept in the order written.
- Without a descriptor number, `<`, `<&` and `<>` apply to descriptor 0, the others to descriptor 1.
- A descriptor number is written directly before the operator, with no blank (`2>err`). By default it must be a single digit, and two or more digits directly before an operator (`10>f`) are rejected: dash reads them as an argument, bash as a descriptor. A caller's option accepts several digits, read as bash reads them (D4).
- After `<&` and `>&`, only one digit or `-` is accepted. Bash's `>&file` is rejected (D3).
- The target word must not contain an unquoted pattern character: bash outside POSIX mode globs it, dash does not **(V11)**.
- An unquoted expansion in the target is allowed (corpus-round question Q1; this default confirmed by the user on 2026-10-30). The executor uses its value as it is, as dash and `bash --posix` do, and fails with status 2 when the value is empty. With the caller's option `redir_strict` it instead fails with "ambiguous redirect" when the value is empty or has blanks or pattern characters, as bash outside POSIX mode does (stricter than bash, which uses a pattern that matches exactly one file).

## 7. Rejection

The parser rejects the whole string at the first construct outside these rules. It then returns:

```perl
{ error => 'unquoted ( outside a subshell', pos => 17 }   # pos: character offset in the original string
```

The caller then runs the string with `/bin/sh -c` (Q2).

## 8. Parse tree (Perl data structure)

Implemented in `ShellSubset.pm`: `ShellSubset::parse($string, %options)` returns a List, or the hash of section 7. Strings inside arrays are operators or literal text; references are nodes. A hash key appears only when it has content.

```perl
List     = [ AndOr, ... ]
AndOr    = [ Pipeline, '&&' | '||', Pipeline, ..., '&' ]   # the final '&' only for a background chain
Pipeline = [ '!', Command, ... ]                           # '!' only when negated
Command  = { argv  => [ Word, ... ],                       # argv->[0]: the command name, a plain string
             env   => [ NAME, Word, NAME, Word, ... ],     # settings before the name, in order
             redir => [ Redir, ... ],                      # in the order written
             exec  => 1 }                                  # for 'exec cmd ...'; argv->[0] is then cmd
         | { sub   => List, redir => [ Redir, ... ] }      # ( list )
         | { group => List, redir => [ Redir, ... ] }      # { list; }
         | { cd    => Word }                               # cd alone: { cd => undef }
         | { set   => [ NAME, Word, NAME, Word, ... ] }    # option assign: only settings
         | { if    => [ Cond, Then, Cond, Then, ..., Else ] }   # option if; Else only if present; all Lists
         | { while => Cond, do => List }                   # option while; also { until => Cond, do => List }
         | { for   => NAME, in => [ Word, ... ], do => List }   # option for
         | { case  => Word, in => [ [ Pattern, ... ], List, ... ] }   # option case; patterns are Words
                                                            # (compound commands may also have redir => [...];
                                                            #  break, continue and read are ordinary argv commands)
Redir    = [ fd, op, Word ]                                # op: < > >> <> >|   fd: 0-9, more with D4
         | [ fd, op, 'digit' or '-' ]                      # op: <& >&
Word     = 'text'                                          # no expansion, no pattern
         | [ Part, ... ]                                   # parts are concatenated after expansion
Part     = 'text'                                          # literal, whether it was quoted or not
         | [ '$', NAME ]  | [ '$((', 'expr' ]  | [ '$(', List ]    # unquoted: split into words; NAME may be ? or !
         | [ '"$', NAME ] | [ '"$((', 'expr' ] | [ '"$(', List ]   # inside "…": not split
         | [ '${', NAME, OP, Word ] | [ '${#', NAME ]        # option param_ops; OP is :- - :+ +
                                                            # ('"${', '"${#' inside "…")
         | [ '~', 'user' ]                                 # 'user' is '' for a plain ~
         | [ '*', 'pattern text' ]                         # see below
         | [ '{', Word, Word, ... ]                        # brace option: {a,b,...}
         | [ '{..', 'from', 'to' ]                         # brace option: {from..to}
```

- A `*` part is a maximal run of unquoted text containing `*`, `?` or a bracket expression `[…]`, together with the unquoted ordinary characters next to them. `*"x"*` gives `[ ['*','*'], 'x', ['*','*'] ]`. Literal parts never contain pattern characters with a pattern meaning, so the executor escapes them when it builds a pattern.
- A backquoted substitution gives the same `$(` part as `$( … )`.
- Quotes that give an empty string leave a `''` part: `""` is the word `''`, and `""$x` is `[ '', ['$','x'] ]`, which still gives an argument when `x` is empty.
- In `env` values, `*`, `?` and `[` are literal, and unquoted expansions are not split.
- `:` and `exit` are simple commands with that name in `argv->[0]`.

Example:

```
LANG=C sort -k2 <in.txt 2>/dev/null | uniq -c >"$OUT" && echo done
```

```perl
[ [ [ { env => [ LANG => 'C' ], argv => [ 'sort', '-k2' ],
        redir => [ [ 0, '<', 'in.txt' ], [ 2, '>', '/dev/null' ] ] },
      { argv => [ 'uniq', '-c' ], redir => [ [ 1, '>', [ [ '"$', 'OUT' ] ] ] ] } ],
    '&&',
    [ { argv => [ 'echo', 'done' ] } ] ] ]
```

Note that `>"$OUT"` is allowed: the expansion in the target is quoted (section 6).

## 9. Caller's options

| Option | Default | Item |
|---|---|---|
| Reject `^` (option `nocaret`) | off: `^` is ordinary | C1, C3 |
| Reject `$PWD` (option `nopwd`) | off: `$PWD` allowed | C4 |
| Unquoted expansion in a redirection target: fail when empty, blank-containing or a pattern (option `redir_strict`, executor) | off: value used as it is | Q1 |
| Commands with only settings (option `assign`) | off: rejected | C5 |
| `${x:-w}`, `${x-w}`, `${x:+w}`, `${x+w}`, `${#x}` (option `param_ops`) | off: rejected | C7 |
| `if` … `fi` (option `if`) | off: rejected | chat 2026-10-29 |
| `while`, `until`, with `break` and `continue` (option `while`) | off: rejected | chat 2026-10-29 |
| `for NAME in …`, with `break` and `continue` (option `for`) | off: rejected | chat 2026-10-29 |
| `case` … `esac` (option `case`) | off: rejected | chat 2026-10-29 |
| `read [-r] NAME…` (option `read`) | off: rejected | chat 2026-10-29 |
| Checker for strings sh would read differently in the locale | none | C4 |
| Accept an empty, blank or comment-only string | off: rejected | D5 |
| Several digits as descriptor number | off: rejected | D4 |
| Expand `~` after `NAME=` in arguments | off (dash) | E4 |
| Brace expansion parsed into `{` and `{..` parts | off: rejected | V13 |
| What to do with pattern words | decided by the caller | E3 |

## 10. Provisional decisions

Rules I chose while writing this spec; they were not on the checklist. Each is in force until decided otherwise.

| ID | Rule | Section |
|---|---|---|
| V1 | `^` is rejected inside a bracket expression `[…]` (bash: negation, dash: literal). | 2 |
| V2 | (Replaced by corpus-round item C1: a `$` that starts no expansion is literal.) | 2 |
| V3 | The command name and the word after `exec` must be literal: no expansion, no pattern. (The `cd` argument: corpus-round item C8.) | 4 |
| V4 | `exit n`: n must be a literal number from 0 to 255, without leading zeros. | 4 |
| V5 | Settings before `:` or `exit` are rejected (POSIX shells keep them after the command). | 4 |
| V6 | A redirection error on `:` or `exit` stops the shell with status 2, as in dash. | 4 |
| V7 | `exec` without a command, with an option, or followed by a builtin name is rejected. (Where `exec` may stand is decided: B3, choice A in chat.) | 4 |
| V8 | `PATH`, `SHELL`, `TERM`, `HOSTNAME` are rejected only when not in `%ENV`; the other shell-set names always. | 5 |
| V9 | Arithmetic: bare variable values must be decimal integers; `$NAME`, `${NAME}`, `$?`, `$!` are substituted as text first (corpus-round items C9, C6); no `base#digits`; no other `$`, no `` ` ``; `?` and `:` must pair up; an empty expression is rejected. | 5 |
| V10 | `~` is rejected when `HOME` is not in `%ENV`. | 5 |
| V11 | Redirection targets: no unquoted pattern character. (Unquoted expansions: corpus-round question Q1.) | 6 |
| V12 | An unquoted `[` with a `]` later in the same word must form a bracket expression with no quote, backslash, expansion, `/`, `,`, `{`, `}` or `^` inside; otherwise the string is rejected. A `[` with no later `]` is a pattern character that matches itself. | 8 |
| V13 | With the brace option: only `{a,b,…}` (at least one unquoted comma) and `{x..y}` (integers or single letters) are parsed; nested braces, a `~` at the start of an alternative, and `,` inside a bracket expression are rejected. | 4, 8 |
| V14 | Backslash-newline inside an unquoted word or inside backquotes is rejected; between words and inside `"…"` it is removed. | 2 |
| V15 | `cd` with settings, redirections, an option, or more than one argument is rejected. (`cd ''` is accepted since the corpus round.) | 4 |
| V16 | `!` negates only when followed by a blank; a word `!` elsewhere in command-name position is rejected. | 3 |
| V17 | Keywords are recognized only when the command name is written unquoted (`"if" x` runs the program `if`, as sh does); builtin names are rejected also when quoted (`"set"` is still the builtin in sh). | 4 |
| V18 | After `~`, only a user name may come before `/` or the end of the word (or `:` in settings); `~"root"`, `~$x` are rejected (both shells keep them literal). | 5 |
| V19 | `! exec cmd` is rejected (both shells lose the `!`). | 4 |
| V20 | `$( )` with an empty list is accepted (empty string); empty `( )` and `{ }` are rejected. | 5 |

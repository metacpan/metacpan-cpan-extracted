# The match across environments, messages not compensated

*Not part of the analysis of [section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11).*

[Section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11) compares, for every snippet the large parser accepts, what dash, `bash --posix` and `Proc::ShellSpawn` (*ShellSpawn*) did, over every environment the snippet ran in. There, messages are not compared at all, wherever a redirection sends them, since each shell words them its own way. This page shows the same comparison with messages compared as in the releases up to 0.11: a message that went to standard output (`2>&1`) or into a file (`2>file`) counts as a difference. So the shells' own prefixes and wordings (`dash: 1: x: not found`, `bash: line 1: x: command not found`, `sh: x: not found`, ShellSpawn's) make differences, which rulings for messages then have to legalize.

## <a id="my-how-it-was-made"></a>How it was made

- The runs are those of section 11: the runs of 2026-11-22 (code label post-0.13; with decision IN1: a recorded program logs what the snippet feeds it), over every environment a snippet ran in: the base run, step 2's setups, and step 3's base runs and setups.
- They are reported by [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) with `-raw`. The rulings for messages in its table of known differences, [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv), apply only with `-raw`; without it messages are not compared.

## <a id="my-why-it-is-kept"></a>Why it is kept

It shows what leaving the messages out of the comparison (*compensating* them) changes. Against section 11:

- 11 snippets in which all three agree only when messages are left out: 38,583 agree here, 38,594 there. Here 8 of them are legalized by the ruling "messages" (each shell's own prefix and wording in a file or a pipe; the ruling legalizes 11 here in all), 3 by A5;
- 5 that are chance here, and legalized by A5 there;
- 1 (`test 2>&1 > cow`) that is not legalized here, and legalized by A5 there.

## <a id="my-the-words-and-the-columns"></a>The words and the columns

As in [section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11), where they are defined in full:

- **≠coreutil**: in every environment where ShellSpawn differs from a shell, the snippet runs one of the six commands (`echo`, `printf`, `test`, `[`, `kill`, `pwd`: those the subset runs as programs, but `time`, `true` and `false`) with arguments for which coreutils differs from that shell's builtin, and ShellSpawn does what coreutils does.
- **¬coreutil**: the snippet runs none of the six commands.
- **rest**: it runs one of the six in some environment, but not in every environment where ShellSpawn differs in the way ≠coreutil says.
- *Legalized*: a ruling of the user allows the difference. *Chance*: a result expected to vary from run to run anyway (a race, process IDs, times, …). *Awaiting A12*: a proposed ruling, waiting for the user's decision ([`TODO`, A12](../../TODO.md#my-a12): `~` with `HOME` empty, where dash drops the word and bash gives an empty word).
- *Timeout*: a shell ran out of the runner's time in every environment of the snippet. There is nothing to legalize, so tree 2 does not split that row; the column totals include it (142 + 1,607 + 77 = 1,826 = 13 + 1,813).
- The rulings (A5, G16, B2, Q2, A4, $0, rule E, builtin-vs-coreutils, the runner) are stated in section 11 of that document. Only this page has the ruling *messages*: a message in a file or a pipe, worded with each shell's own prefix, is not a difference; *A5 + messages* is one snippet's record that names both at once.

## <a id="my-tree-1"></a>Tree 1

```
40,409  all snippets the parser accepts; each run by dash, bash and ShellSpawn
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,583  ShellSpawn = dash = bash, in every environment¹
├──     13  timeout                                                   0         11     2
├──      4  dash = bash; ShellSpawn ≠ them                            2          2     0
└──  1,809  dash ≠ bash, in some or all environments
     ├── 1,257  ShellSpawn = dash                                    14      1,194    49
     ├──   355  ShellSpawn = bash                                   117        234     4
     ├──   141  ShellSpawn ≠ dash, ShellSpawn ≠ bash                  8        115    18
     └──    56  depends on the environment                            1         51     4
                ├── 39  ShellSpawn = dash in some, = bash in others         0         36     3
                ├── 11  ShellSpawn = dash in some, ≠ both in others         0         10     1
                ├── 3  ShellSpawn = bash in some, ≠ both in others         1          2     0
                └── 3  ShellSpawn = dash, = bash, ≠ both, by environment         0          3     0
                                                              ─────────  ─────────  ────
                                                                    142      1,607    77
```

¹ The runner did not record which of the six commands these snippets run (it records them only for snippets where ShellSpawn differs from a shell): nothing in them needs a reason, so they have no column counts.

## <a id="my-tree-2"></a>Tree 2

```
40,409  all snippets the parser accepts; each run by dash, bash and ShellSpawn
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,583  ShellSpawn = dash = bash, in every environment¹
├──     13  timeout                                                   0         11     2
├──      4  dash = bash; ShellSpawn ≠ them                            2          2     0
│           ├── 3  legalized by rulings²                              2          1     0
│           └── 1  chance                                             0          1     0
└──  1,809  dash ≠ bash, in some or all environments
     ├── 1,257  ShellSpawn = dash                                    14      1,194    49
     │          ├── 1,237  legalized by rulings³                     14      1,176    47
     │          ├──    19  ~ with HOME empty: awaiting A12            0         17     2
     │          └──     1  chance                                     0          1     0
     ├──   355  ShellSpawn = bash                                   117        234     4
     │          ├── 283  legalized by rulings⁴                      117        166     0
     │          ├──  64  ~ with HOME empty: awaiting A12              0         64     0
     │          └──   8  not legalized                                0          4     4
     ├──   141  ShellSpawn ≠ dash, ShellSpawn ≠ bash                  8        115    18
     │          ├── 100  legalized by rulings⁵                        8         78    14
     │          ├──   1  ~ with HOME empty: awaiting A12              0          1     0
     │          ├──  39  chance                                       0         36     3
     │          └──   1  not legalized                                0          0     1
     └──    56  depends on the environment                            1         51     4
                ├── 39  ShellSpawn = dash in some, = bash in others         0         36     3
                │      ├──  5  legalized by rulings⁶                  0          3     2
                │      ├──  2  ~ with HOME empty: awaiting A12         0          2     0
                │      ├──  2  chance                                 0          1     1
                │      └── 30  not legalized                          0         30     0
                ├── 11  ShellSpawn = dash in some, ≠ both in others         0         10     1
                │      ├── 4  legalized by rulings⁷                   0          4     0
                │      ├── 2  ~ with HOME empty: awaiting A12         0          1     1
                │      └── 5  chance                                  0          5     0
                ├── 3  ShellSpawn = bash in some, ≠ both in others         1          2     0
                │         legalized by rulings⁸
                └── 3  ShellSpawn = dash, = bash, ≠ both, by environment         0          3     0
                          legalized by rulings⁹
                                                              ─────────  ─────────  ────
                                                                    142      1,607    77
```

¹ As above.
² Q2 2, A4 1.
³ A5 1,235, rule E 2.
⁴ G16 126, builtin-vs-coreutils 117, B2 31, rule E 10.
⁵ $0 36, B2 35, A4 8, builtin-vs-coreutils 8, messages 8, A5 4, the runner 1.
⁶ A5 4, rule E 3, builtin-vs-coreutils 2.
⁷ messages 3, A5 1, A5 + messages 1.
⁸ $0 2, builtin-vs-coreutils 1.
⁹ $0 3, A5 3.

In each footnote a snippet counts once under every ruling its record names (a record that names "A5, and messages …" as one rule counts under "A5 + messages" only), so a footnote may add up to more than its row (⁴: 284 for 283 snippets).

## <a id="my-the-totals"></a>The totals

ShellSpawn differs from at least one shell in 1,813 = 4 + 1,809 snippets (4 where dash = bash, 1,809 where dash ≠ bash). They fall into four groups, 1,638 + 88 + 48 + 39 = 1,813:

- legalized by rulings: 1,638;
- awaiting A12: 88;
- chance: 48;
- not legalized: 39 (the 38 of section 11, and `test 2>&1 > cow`).

The rulings, by how many snippets' records name each, whatever the snippet's group (as in section 11). A snippet may need more than one ruling, so these counts add up to more than 1,638. Three count snippets outside the legalized group too: A5 1,306 = 1,247 legalized + 23 awaiting A12 + 5 chance + 31 not legalized; G16 214 = 126 + 88 awaiting A12; B2 67 = 66 + 1 awaiting A12. (On 2026-11-17 also builtin-vs-coreutils, 128 = 127 + 1 chance: `echo $(date) "0" | tee -a log.csv`, legalized now, section 11.) What each ruling says: [section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11).

| Ruling | Snippets |
|---|---|
| A5 | 1,306 |
| G16 | 214 |
| builtin-vs-coreutils | 128 |
| B2 | 67 |
| $0 | 41 |
| rule E | 15 |
| messages | 11 |
| A4 | 9 |
| Q2 | 2 |
| A5 + messages | 1 |
| the runner | 1 |

# The match across environments, messages not compensated

*Not part of the analysis.*  This is [`large-subset-environment.md`](large-subset-environment.md), section 11, with messages compared as before post-0.11: there messages count nowhere, wherever a redirection sends them; here a message that went to standard output (`2>&1`) or into a file (`2>file`) counted as a difference, so the shells' own prefixes and wordings (`dash: 1: x: not found`, `bash: line 1: x: command not found`, `sh: x: not found`) made differences, which rulings for messages then had to legalize.  The same runs, [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) with `-raw` (the rule table's rows for messages apply only there).  Kept because it shows what the compensation changed: 11 snippets where all three agree only with it (7 messages in a file or a pipe, 4 A5), 5 that are chance without it and A5 with it, and 1 (`test 2>&1 > cow`) not legalized without it and A5 with it.  The runs of post-0.11 (2026-11-13), over every environment a snippet ran in, step 3's included, as there.  The words and the columns: section 11 there.

## Tree 1

```
40,410  all snippets the parser accepts; each run by dash, bash and ours
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,592  ours = dash = bash, in every environment¹
├──     14  timeout                                                   0         12     2
├──      6  dash = bash; ours ≠ them                                  2          3     1
└──  1,798  dash ≠ bash, in some or all environments
     ├── 1,250  ours = dash                                          14      1,188    48
     ├──   350  ours = bash                                         110        235     5
     ├──   140  ours ≠ dash, ours ≠ bash                              8        114    18
     └──    58  depends on the environment                            1         54     3
                ├── 40  ours = dash in some, = bash in others         0         38     2
                ├── 12  ours = dash in some, ≠ both in others         0         11     1
                ├── 3  ours = bash in some, ≠ both in others          1          2     0
                └── 3  ours = dash, = bash, ≠ both, by environment    0          3     0
                                                              ─────────  ─────────  ────
                                                                    135      1,606    77
```

¹ Their commands were not recorded: nothing in them needs a reason.

## Tree 2

```
40,410  all snippets the parser accepts; each run by dash, bash and ours
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,592  ours = dash = bash, in every environment¹
├──     14  timeout                                                   0         12     2
├──      6  dash = bash; ours ≠ them                                  2          3     1
│           ├── 3  legalized by rulings²                              2          1     0
│           ├── 1  chance                                             0          1     0
│           └── 2  not legalized (2 already in TODO)                  0          1     1
└──  1,798  dash ≠ bash, in some or all environments
     ├── 1,250  ours = dash                                          14      1,188    48
     │          ├── 1,231  legalized by rulings³                     14      1,171    46
     │          └──    19  ~ with HOME empty: awaiting A12            0         17     2
     ├──   350  ours = bash                                         110        235     5
     │          ├── 276  legalized by rulings⁴                      110        166     0
     │          ├──  64  ~ with HOME empty: awaiting A12              0         64     0
     │          ├──   1  chance                                       0          0     1
     │          └──   9  not legalized                                0          5     4
     ├──   140  ours ≠ dash, ours ≠ bash                              8        114    18
     │          ├── 100  legalized by rulings⁵                        8         78    14
     │          ├──   1  ~ with HOME empty: awaiting A12              0          1     0
     │          ├──  36  chance                                       0         33     3
     │          └──   3  not legalized (2 already in TODO)            0          2     1
     └──    58  depends on the environment                            1         54     3
                ├── 40  ours = dash in some, = bash in others         0         38     2
                │      ├──  5  legalized by rulings⁶                  0          3     2
                │      ├──  2  ~ with HOME empty: awaiting A12        0          2     0
                │      ├──  1  chance                                 0          1     0
                │      └── 32  not legalized                          0         32     0
                ├── 12  ours = dash in some, ≠ both in others         0         11     1
                │      ├── 4  legalized by rulings⁷                   0          4     0
                │      ├── 2  ~ with HOME empty: awaiting A12         0          1     1
                │      └── 6  chance                                  0          6     0
                ├── 3  ours = bash in some, ≠ both in others          1          2     0
                │         legalized by rulings⁸
                └── 3  ours = dash, = bash, ≠ both, by environment    0          3     0
                          legalized by rulings⁹
                                                              ─────────  ─────────  ────
                                                                    135      1,606    77
```

¹ As above.
² Q2 2, A4 1.
³ A5 1,229, rule E 2.
⁴ G16 126, builtin-vs-coreutils 110, B2 31, rule E 10.
⁵ $0 36, B2 35, A4 8, builtin-vs-coreutils 8, messages 8, A5 4, the runner 1.
⁶ A5 4, rule E 3, builtin-vs-coreutils 2.
⁷ messages 3, A5 1, A5 + messages 1.
⁸ $0 2, builtin-vs-coreutils 1.
⁹ $0 3, A5 3.

The 1,804 where ours is not as both shells: legalized by rulings 1,625, awaiting A12 88, chance 45, not legalized 46 (4 marked open, as there).

| Ruling | Snippets |
|---|---|
| A5 | 1,302 |
| G16 | 214 |
| builtin-vs-coreutils | 121 |
| B2 | 67 |
| $0 | 41 |
| rule E | 15 |
| messages | 11 |
| A4 | 9 |
| Q2 | 2 |
| A5 + messages | 1 |
| the runner | 1 |

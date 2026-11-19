# The match across environments, messages not compensated

*Not part of the analysis.*  This is [`large-subset-environment.md`](large-subset-environment.md#my-section-11), section 11, with messages compared as before post-0.11: there messages count nowhere, wherever a redirection sends them; here a message that went to standard output (`2>&1`) or into a file (`2>file`) counted as a difference, so the shells' own prefixes and wordings (`dash: 1: x: not found`, `bash: line 1: x: command not found`, `sh: x: not found`) made differences, which rulings for messages then had to legalize.  The same runs, [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) with `-raw` (the rule table's rows for messages apply only there).  Kept because it shows what the compensation changed: 11 snippets where all three agree only with it (7 messages in a file or a pipe, 4 A5), 5 that are chance without it and A5 with it, and 1 (`test 2>&1 > cow`) not legalized without it and A5 with it.  The runs of post-0.12 (2026-11-17, with IN1), over every environment a snippet ran in, step 3's included, as there.  The words and the columns: [section 11 there](large-subset-environment.md).

## <a id="my-tree-1"></a>Tree 1

```
40,410  all snippets the parser accepts; each run by dash, bash and ours
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,582  ours = dash = bash, in every environment¹
├──     13  timeout                                                   0         11     2
├──      7  dash = bash; ours ≠ them                                  2          4     1
└──  1,808  dash ≠ bash, in some or all environments
     ├── 1,254  ours = dash                                          14      1,192    48
     ├──   355  ours = bash                                         116        234     5
     ├──   143  ours ≠ dash, ours ≠ bash                              8        117    18
     └──    56  depends on the environment                            1         51     4
                ├── 39  ours = dash in some, = bash in others         0         36     3
                ├── 11  ours = dash in some, ≠ both in others         0         10     1
                ├── 3  ours = bash in some, ≠ both in others          1          2     0
                └── 3  ours = dash, = bash, ≠ both, by environment    0          3     0
                                                              ─────────  ─────────  ────
                                                                    141      1,609    78
```

¹ Their commands were not recorded: nothing in them needs a reason.

## <a id="my-tree-2"></a>Tree 2

```
40,410  all snippets the parser accepts; each run by dash, bash and ours
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,582  ours = dash = bash, in every environment¹
├──     13  timeout                                                   0         11     2
├──      7  dash = bash; ours ≠ them                                  2          4     1
│           ├── 3  legalized by rulings²                              2          1     0
│           ├── 2  chance                                             0          2     0
│           └── 2  not legalized (2 already in TODO)                  0          1     1
└──  1,808  dash ≠ bash, in some or all environments
     ├── 1,254  ours = dash                                          14      1,192    48
     │          ├── 1,234  legalized by rulings³                     14      1,174    46
     │          ├──    19  ~ with HOME empty: awaiting A12            0         17     2
     │          └──     1  chance                                     0          1     0
     ├──   355  ours = bash                                         116        234     5
     │          ├── 282  legalized by rulings⁴                      116        166     0
     │          ├──  64  ~ with HOME empty: awaiting A12              0         64     0
     │          ├──   1  chance                                       0          0     1
     │          └──   8  not legalized                                0          4     4
     ├──   143  ours ≠ dash, ours ≠ bash                              8        117    18
     │          ├── 100  legalized by rulings⁵                        8         78    14
     │          ├──   1  ~ with HOME empty: awaiting A12              0          1     0
     │          ├──  39  chance                                       0         36     3
     │          └──   3  not legalized (2 already in TODO)            0          2     1
     └──    56  depends on the environment                            1         51     4
                ├── 39  ours = dash in some, = bash in others         0         36     3
                │      ├──  5  legalized by rulings⁶                  0          3     2
                │      ├──  2  ~ with HOME empty: awaiting A12        0          2     0
                │      ├──  2  chance                                 0          1     1
                │      └── 30  not legalized                          0         30     0
                ├── 11  ours = dash in some, ≠ both in others         0         10     1
                │      ├── 4  legalized by rulings⁷                   0          4     0
                │      ├── 2  ~ with HOME empty: awaiting A12        0          1     1
                │      └── 5  chance                                  0          5     0
                ├── 3  ours = bash in some, ≠ both in others          1          2     0
                │         legalized by rulings⁸
                └── 3  ours = dash, = bash, ≠ both, by environment    0          3     0
                          legalized by rulings⁹
                                                              ─────────  ─────────  ────
                                                                    141      1,609    78
```

¹ As above.
² Q2 2, A4 1.
³ A5 1,232, rule E 2.
⁴ G16 126, builtin-vs-coreutils 116, B2 31, rule E 10.
⁵ $0 36, B2 35, A4 8, builtin-vs-coreutils 8, messages 8, A5 4, the runner 1.
⁶ A5 4, rule E 3, builtin-vs-coreutils 2.
⁷ messages 3, A5 1, A5 + messages 1.
⁸ $0 2, builtin-vs-coreutils 1.
⁹ $0 3, A5 3.

The 1,815 where ours differs from at least one shell (7 where dash = bash, 1,808 where dash ≠ bash): legalized by rulings 1,634, awaiting A12 88, chance 50, not legalized 43 (4 marked open, as there).

| Ruling | Snippets |
|---|---|
| A5 | 1,303 |
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

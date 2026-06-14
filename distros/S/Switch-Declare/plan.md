# Switch::Declare — Implementation Plan

> **Implementation status (v0.01, shipped).** Core complete and tested (83
> tests). Key deviations from the design below, all improvements found during
> implementation:
>
> - **Keyword plugin, not `Devel::CallParser`.** `cv_set_call_parser` wraps the
>   construct in an `entersub` to a stub (a per-evaluation call, ~40% overhead).
>   We register `PL_keyword_plugin` and return the op directly as
>   `KEYWORD_PLUGIN_EXPR`, so the op *replaces* the call. This also made it a
>   true `$^H` lexical pragma (the planned v1.1 item) and dropped **all** CPAN
>   dependencies — pure core C API, matching house style.
> - **Fast path = zero overhead.** A plain variable/constant scrutinee with
>   single-expression arms lowers to a bare conditional expression (no temp, no
>   scope): 0–2% vs hand-written `if/elsif` in the benchmark. Non-trivial
>   scrutinees use the evaluate-once temp; multi-statement arms add one
>   enter/leave.
> - **Dispatch mode = value-map, not coderef hash.** The design's coderef
>   dispatch changes `return`/`last`/`next` semantics and has closure
>   re-entrancy costs. Instead, string-keyed lookup tables with **constant**
>   values compile to a compile-time hash + a single O(1) lookup — correct (no
>   closures), ~2.5× faster than the chain at 20 arms. Threshold `SD_DISPATCH_MIN`
>   = 4 (benchmarked).
> - **Patterns are hand-lexed**, not parsed via `parse_termexpr` (which lexes
>   one token past the term and chokes on the following `{`). Blocks use
>   `parse_block`. `\&name` predicates supported; inline `sub {}` deferred.
> - **Not yet done:** fallthrough; switch-scoped `last`/`next`; numeric dispatch
>   tables; inline `sub {}` predicates. See POD `LIMITATIONS`.

# Original design

# Switch::Declare — Implementation Plan

A lexically-installed `switch`/`case`/`default` construct built on
`Devel::CallParser`. All parsing and code generation happen at **compile
time**; the construct lowers to an ordinary optree, so there is **zero residual
runtime overhead** from the parsing machinery. Runtime speed is whatever optree
we emit — and we choose the lowering per-switch to beat a naive `if/elsif`
chain where we can.

Sibling reference: `Enum-Declare` (`Declare.xs`, `Makefile.PL`). We reuse its
`import` → `cv_set_call_parser` pattern and its `lex_read_*` helpers verbatim
where applicable. The crucial divergence: `enum` returns `newNULLLIST()` with
`CALLPARSER_STATEMENT` (pure declaration, no runtime op). `switch` returns a
**real value-producing optree** and does *not* set `CALLPARSER_STATEMENT`, so it
works both as a statement and as an expression.

---

## 1. Goals & non-goals

### Goals
- A readable, conventional `switch (EXPR) { case PAT { ... } ... default { ... } }`.
- Compile-time only; native-speed dispatch; no source filter, no smartmatch.
- Both **statement** form and **expression** form (`my $x = switch (...) {...}`).
- Multiple pattern kinds: scalar-eq (string/number), regex, range, list
  membership, predicate (coderef). Each arm lowers to the cheapest matching op.
- Compile-time optimisation: all-literal switches above a threshold lower to an
  **O(1) hash dispatch**; everything else to an `if/elsif` chain. Scrutinee
  evaluated exactly once.
- Minimal dependency surface (no `Object::Proto`; just CallParser/CallChecker).

### Non-goals (v1)
- No implicit C-style fallthrough (error-prone). Explicit `fallthrough;` only.
- No full destructuring / `~~` smartmatch semantics. We define our own narrow,
  predictable pattern grammar.
- No `given`/`when` compatibility shim.

---

## 2. Surface syntax

```perl
use Switch::Declare;

# statement form
switch ($value) {
    case 200            { handle_ok()        }   # numeric  -> ==
    case "GET"          { handle_get()       }   # string   -> eq
    case /^\d+$/        { all_digits()       }   # regex    -> =~
    case [400 .. 499]   { client_error()     }   # range    -> >= && <=
    case [qw/a b c/]    { in_set()           }   # list     -> membership
    case \&is_weekend   { weekend()          }   # predicate-> $pred->($topic)
    default             { fallback()         }
}

# expression form (yields the matched arm's value)
my $label = switch ($status) {
    case 200 { "ok" }
    case 404 { "missing" }
    default  { "other" }
};
```

Semantics:
- **Scrutinee** is evaluated once, bound to an internal pad temp; the matched
  topic is also available inside arms as `$_` (localised).
- **No implicit fallthrough.** First matching arm wins; control leaves the
  switch after its block. `fallthrough;` inside a block transfers to the next
  arm's block unconditionally (no re-test). `last;` / `next;` behave as in a
  bare loop block wrapping the switch (so `last` exits the switch).
- **default** matches if no `case` did; at most one, must be last.
- **Value:** the value of the executed block (last expression), else `undef`.

Pattern classification (decided at compile time, in this order):
1. `/.../` literal → regex match (`=~`).
2. `[ EXPR .. EXPR ]` → numeric/string range test.
3. `[ LIST ]` → membership (compile-time hash if all literal, else grep).
4. `\&name`, `sub {...}`, or any term known to be a coderef → call as predicate.
5. quoted string literal → `eq`.
6. number literal → `==`.
7. otherwise → runtime: `eq` if topic looks non-numeric, `==` if numeric
   (decide with a dualvar-aware comparison helper; document the rule).

---

## 3. Architecture (mirrors Enum::Declare)

```
lib/Switch/Declare.pm     # thin loader: use Devel::CallParser; XSLoader::load
Declare.xs                # import + parser callback + optree codegen
callparser1.h             # generated per-perl by Makefile.PL (as in Enum)
```

`import` (XS), called by `use Switch::Declare`, installs into the **caller's**
package a stub CV `switch` and attaches the call parser:

```c
const char *caller = CopSTASHPV(PL_curcop);
SV *fqn = newSVpvf("%s::switch", caller);
CV *cv  = newXS(SvPV_nolen(fqn), xs_switch_stub, __FILE__);
cv_set_call_parser(cv, switch_parser_callback, &PL_sv_undef);
```

`case` / `default` are **not** installed as subs — the `switch` parser callback
consumes the entire `{ ... }` block itself (exactly as `enum` reads its own
braces with `lex_read_variants`), recognising the `case`/`default` barewords
inline. This keeps the caller's namespace clean and avoids ordering hazards.

A matching `unimport` removes the CV so the keyword is lexically uninstalled on
`no Switch::Declare` (optional v1.1; see §8 for a true `$^H` pragma).

---

## 4. Parsing strategy (compile time)

Reuse from `Enum-Declare/Declare.xs`: `lex_read_space`, `lex_peek_unichar`,
`lex_read_unichar`, `lex_read_ident`. New work uses the core lexer/parser API
(all stable since 5.14, matching `MIN_PERL_VERSION`):

- **Scrutinee:** after `switch`, expect `(`, then `parse_fullexpr(0)` to get the
  topic `OP*`, then `)`. (Alternatively accept `switch EXPR {`; v1 requires
  parens for an unambiguous grammar.)
- **Block bodies:** for each arm, `parse_block(0)` returns an `OP*` for the
  `{ ... }`. This gives us native lexical scoping, `my`, and statement parsing
  for free — we do **not** hand-roll statement parsing.
- **Patterns:**
  - regex: detect leading `/`; capture with the lexer and build a `match` op
    (or `parse_termexpr` of a `qr//`-equivalent — prefer building `pmop`).
  - `[ ... ]`: `parse_listexpr(0)` between brackets; inspect the resulting
    `OP*` — if it's a constant `..` flip-flop / range or an all-`OP_CONST`
    list, classify as range vs membership; else keep as runtime list.
  - predicate / scalar: `parse_termexpr(0)` for the pattern expression; classify
    by op type (`OP_ANONCODE`/`OP_REFGEN`/`OP_RV2CV` → predicate; `OP_CONST`
    with NV/IV → numeric; `OP_CONST` PV → string).
- Loop arms until `}`; enforce `default` is last and unique; `croak` with
  precise messages (match Enum's croak style and wording).

The callback returns the assembled `OP*` (see §5) and sets `*flagsp` so the
construct is usable as a term (no `CALLPARSER_STATEMENT`).

---

## 5. Code generation / lowering (the core)

Perl has **no computed-jump opcode**, so a switch must lower to one of two
shapes. We pick at compile time after classifying all arms.

### 5a. `if/elsif` chain — always-correct default
- Evaluate scrutinee once into a pad temp `$topic` (`OP_PADSV` + `OP_SASSIGN`),
  `local $_ = $topic`.
- Each arm → a guard op + the parsed block, chained with `newCONDOP` /
  `newLOGOP(OP_OR, ...)`:
  - eq/==: `newBINOP(OP_SEQ|OP_EQ, ...)`
  - regex: `pmop` against `$topic`
  - range: `($topic >= lo) && ($topic <= hi)`
  - membership: `grep`/hash-exists against the list
  - predicate: `newop` calling the coderef with `$topic`
- Block bodies are inlined (no sub-call) → preserves `last`/`next`/`return`,
  lexicals, and value semantics. O(n) comparisons, same speed as hand-written
  `if/elsif`.

### 5b. Hash dispatch — O(1) for large all-literal switches
- Trigger when **every** `case` is a scalar literal (string or number) and arm
  count ≥ `SWITCH_DISPATCH_MIN` (tunable, default 5), and no predicate/regex/
  range arms.
- At compile time build a constant dispatch `HV` mapping each key → arm index,
  installed as a `pad`/`SVOP` constant (built once, never rebuilt at runtime).
- Wrap each arm body in an anonymous CV captured in a constant `AV` of coderefs
  (also built once at compile time).
- Emit: `my $i = $dispatch{$topic}; defined $i ? $arms[$i]->() : $default->()`.
- Trade-off: one hash lookup + one sub call vs. N comparisons. Wins decisively
  past a handful of arms; the threshold is benchmarked (§7), not guessed.
- Caveat documented: in dispatch mode, `last`/`next` semantics differ (bodies
  are CVs). v1 rule: if any arm contains a loop-control or `fallthrough`,
  **force chain mode** regardless of arm count. Detect by walking the parsed
  body optree for `OP_NEXT`/`OP_LAST`/`OP_REDO`/our fallthrough marker.

### 5c. `fallthrough`
- A pragma-scoped keyword (or recognised bareword) compiling to a marker op.
- In chain mode: implemented by ordering arm blocks so a fallthrough jumps into
  the next block (emit shared entry via `goto`-free op threading, or simplest:
  duplicate-free `if` cascade where fallthrough sets a "sticky" flag). Keep v1
  simple: `fallthrough` lowers to "also run next arm's block unconditionally";
  implement by structuring blocks as a sequence guarded by a running flag.

### Compile-time checks (free, since we have the optree)
- Duplicate literal keys → warn.
- `default` not last / multiple defaults → croak.
- Empty switch → croak.

---

## 6. Runtime semantics summary

| Aspect            | Behaviour                                              |
|-------------------|--------------------------------------------------------|
| scrutinee eval    | exactly once                                           |
| topic in arm      | `$_` (localised), also matched value                   |
| match order       | textual; first match wins                              |
| fallthrough       | none implicit; explicit `fallthrough;`                 |
| `last`/`next`     | exit / restart switch (chain mode); forces chain mode  |
| value             | last expr of executed block, else `undef`              |
| no match          | `default` block, else `undef` / empty                  |

---

## 7. Performance plan

- **Claim to validate:** chain mode == hand-written `if/elsif` (zero overhead);
  dispatch mode beats chain past the threshold for all-literal switches.
- Benchmarks (`xt/bench.pl`, `Benchmark` or `Dumbbench`):
  - 3, 5, 10, 25, 50 string arms — chain vs dispatch vs hand `if/elsif` vs
    hand `%dispatch`. Locate the real crossover; set `SWITCH_DISPATCH_MIN`.
  - numeric arms; mixed; regex arms (chain only).
  - compile-time cost per switch (parse + codegen) — confirm negligible.
- Compare against `given/when` (where still available) and `Switch.pm` to
  document the categorical win in POD.
- Verify "evaluated once" with a side-effecting scrutinee test.

---

## 8. Lexical pragma (`$^H`) — v1.1

To be a true lexical pragma (keyword visible only within the enclosing block,
not the whole package), gate the parser callback on a hints-hash entry:
- `import` sets `$^H{'Switch::Declare'} = 1` (and a hint bit) instead of (or in
  addition to) installing the CV.
- The parser callback checks the cop hints at parse time and no-ops (falls back
  to normal parsing) when the pragma is not in scope.
- This mirrors how lexical pragmas scope; v1 can ship with package-scoped CV
  installation and upgrade to hint-gated scoping in v1.1 without changing
  surface syntax.

---

## 9. Dist layout & build

```
Switch-Declare/
  lib/Switch/Declare.pm     # loader + full POD
  Declare.xs                # all C
  callparser1.h             # generated (clean target)
  Makefile.PL               # ExtUtils::Depends + Devel::CallParser shims
  t/                        # see §10
  xt/bench.pl  xt/boilerplate.t
  Changes  MANIFEST  README  ignore.txt
```

`Makefile.PL` — model on `Enum-Declare/Makefile.PL` but **drop Object::Proto**:
- `use Devel::CallParser 'callparser1_h', 'callparser_linkable';`
- Write `callparser1.h` from `callparser1_h`.
- `ExtUtils::Depends->new('Switch::Declare')` (no second arg).
- `OBJECT => '$(BASEEXT)$(OBJ_EXT) ' . join(' ', map abs2rel($_), callparser_linkable)`.
- `CONFIGURE_REQUIRES`/`PREREQ_PM`: `Devel::CallParser` (>=0.003/0.004),
  `Devel::CallChecker` (>=0.009), `ExtUtils::Depends`. No `Object::Proto`.
- `MIN_PERL_VERSION => '5.014'` (needs `parse_block`/`parse_fullexpr`).
- Keep the `macro => { TARFLAGS => "--format=ustar ..." }` and the EUMM
  back-compat block from the sibling.

`lib/Switch/Declare.pm`: replace the generated stub entirely —
`use Devel::CallParser; require XSLoader; XSLoader::load(...)` plus the real
POD (synopsis from §2, semantics table from §6).

---

## 10. Testing plan (`t/`)

- `00-load.t` — loads, `switch` keyword installed in caller.
- `01-basic.t` — string + numeric exact match, default, no-match → undef.
- `02-expression.t` — expression form returns matched block value.
- `03-regex.t` — `/.../ ` arms; capture vars sane.
- `04-range.t` — `[lo..hi]` numeric + string ranges; boundaries.
- `05-list.t` — `[LIST]` membership, literal and runtime lists.
- `06-predicate.t` — `\&f` / `sub{}` arms get topic; truthiness.
- `07-once.t` — scrutinee with side effect evaluated exactly once.
- `08-control.t` — `last`/`next`; `fallthrough` runs next block.
- `09-dispatch.t` — force >threshold all-literal switch; assert identical
  results to chain mode (behavioural parity across both lowerings).
- `10-errors.t` — multiple/non-last `default`, empty switch, bad syntax →
  expected `croak` messages.
- `11-scope.t` — (v1.1) lexical `$^H` scoping.
- `pod.t`, `pod-coverage.t`, `manifest.t`, `xt/boilerplate.t` — as sibling.

---

## 11. Milestones

1. **Skeleton + build green** — Makefile.PL (CallParser/Depends), loader, empty
   XS that installs a `switch` stub; `00-load.t` passes.
2. **Chain-mode MVP** — parse `(EXPR)` + `case literal { }` + `default`; emit
   `if/elsif` optree; statement + expression form; `01`,`02`,`07`,`10`.
3. **Pattern kinds** — regex, range, list, predicate; `03`–`06`.
4. **Control flow** — `last`/`next`, `fallthrough`; `08`.
5. **Dispatch-mode optimisation** — classification, compile-time hash + CV
   table, threshold, force-chain-on-control detection; `09` + benchmarks (§7).
6. **Docs + polish** — POD, Changes, README, MANIFEST; tune `SWITCH_DISPATCH_MIN`
   from bench data.
7. **(v1.1)** — `$^H` lexical scoping; `unimport`.

---

## 12. Risks & mitigations

- **Optree construction correctness** (the hard part): scope entry/exit,
  refcounts, value context. Mitigate by leaning on `parse_block`/`parse_*` for
  all user code (never hand-build statement ops), keeping our generated ops to
  guards + glue, and testing chain/dispatch parity (`09-dispatch.t`).
- **`last`/`next` in dispatch mode** differ (bodies become CVs): detected at
  compile time → force chain mode. Documented limitation.
- **Cross-version lexer/op API drift**: pinned to 5.14 API; CallParser shims
  smooth the rest. CI across 5.14 → current.
- **Dependency vs zero-dep house style**: CallParser/Depends are *build/parse*
  deps only, vendored via generated `callparser1.h` exactly as Enum-Declare
  already does — acceptable precedent. No runtime CPAN deps.
- **Regex/quote lexing edge cases**: reuse Enum's `lex_read_quoted_string`
  approach; for regex prefer building a `pmop` over re-lexing delimiters.
```

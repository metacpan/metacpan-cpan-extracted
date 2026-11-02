# Pipe::Declare — Implementation Plan

A lexically-installed `pipe { ... }` block that introduces an F#/Elixir-style
`|>` pipeline operator inside its body. All parsing and code generation happen
at **compile time**; the construct lowers to an ordinary Perl optree (a single
chain of nested calls), so there is **zero residual runtime overhead** from the
parsing machinery — the runtime cost is exactly that of the calls the user
wrote, threaded into each other by hand.

Sibling reference: `Switch::Declare` (`Declare.xs`, keyword-plugin + `$^H`
lexical pragma, no CPAN deps). We reuse its `PL_keyword_plugin` chain
installation, its hand-lexer helpers (`sd_lex_read_ident`,
`sd_lex_subname`, `sd_lex_number`) and its block-parsing approach
(`parse_block`/`parse_termexpr`) wholesale. The crucial divergence: `switch`
classifies *patterns* at compile time and lowers to comparisons; `pipe`
classifies *steps* at compile time and lowers to **call ops** with a
threaded-topic argument inserted at the right pad position.

Runtime cousin: `Func::Util::pipeline($x, \&f, \&g, ...)`. `Pipe::Declare` is
the compile-time, infix, optree-emitting form of the same idea; the two are
complementary and the POD will say so explicitly.

---

## 1. Goals & non-goals

### Goals
- A readable, conventional left-to-right pipeline: `pipe { $x |> f |> g(@a) |> $obj->m }`.
- Compile-time only; native call speed; no source filter, no runtime parser.
- Both **statement** form (`pipe { ... };`) and **expression** form
  (`my $y = pipe { ... };`) — yields the value of the last step.
- Multiple step kinds, classified at compile time and lowered to the cheapest
  call op: bareword sub, qualified sub, code-ref expression, method call,
  block, and a generic call-with-extra-args using `_` as the topic placeholder.
- True **lexical pragma** via `$^H` (gated parser callback) from v1 —
  `Switch::Declare` already had to ship this; we ship it on day one.
- Minimal dependency surface: core C API only, no `Devel::CallParser`, no
  `ExtUtils::Depends`, no `Object::Proto`.

### Non-goals (v1)
- No global infix `|>` operator outside a `pipe { ... }` block. (Pre-5.37.7
  there is no portable way; post-5.37.7 we *could* register through
  `PL_infix_plugin`, but that's v1.1 — see §8.)
- No async / promise threading (`Future`, `IO::Async`). The result of each
  step is the input of the next, full stop. Users wanting Future-aware piping
  can pipe through `->then(...)` explicitly.
- No automatic currying / partial-application of bareword steps. We pass the
  topic; everything else is what the user wrote.
- No multi-value (list-context) threading. The topic is one scalar; in list
  contexts the user opts in explicitly with `|> \&f` style (see §5).

---

## 2. Surface syntax

```perl
use Pipe::Declare;

# statement form
pipe { @orders |> grep_paid |> map_amount |> sum_total };

# expression form
my $total = pipe {
    @orders
        |> grep_paid                       # bareword sub  -> grep_paid(@orders)
        |> map { $_->{amount} }            # block         -> map { ... } LIST
        |> List::Util::sum0                # qualified sub -> List::Util::sum0(@)
};

# placeholder _ — topic goes wherever _ appears, not just first arg
my $clipped = pipe {
    $value
        |> max(0, _)                       # max(0, $value)
        |> min(_, 100)                     # min($prev, 100)
};

# method call — topic becomes the invocant
my $json = pipe {
    $response
        |> ->decoded_content               # $response->decoded_content
        |> JSON::PP::decode_json           # JSON::PP::decode_json($body)
        |> ->{data}                        # $hashref->{data}  (deref step)
};

# code-ref / closure RHS
my $shouted = pipe {
    $name
        |> \&trim
        |> sub { uc $_[0] }
        |> $formatter                      # any expression yielding a coderef
};

# tap — run a side-effect, keep the topic
pipe {
    $request
        |> validate
        |> tap { log_debug("ok: $_") }     # block sees topic as $_
        |> dispatch
};
```

Semantics:
- A `pipe { ... }` block contains **exactly one** pipeline expression
  (optionally terminated by `;`). Multiple statements in one block is a
  compile-time error — use multiple `pipe` blocks if that is wanted.
- The **head** (left of the first `|>`) is an arbitrary Perl expression,
  parsed by `parse_termexpr`. It is evaluated once.
- Each **step** (right of a `|>`) is one of: bareword sub name, qualified sub
  name (`Foo::Bar::baz`), code-ref expression, `->method` / `->{key}` /
  `->[idx]` method-or-deref, `\&name`, `sub { ... }`, a code block (treated
  like `map`/`grep`/`tap`), or a function call with an argument list that may
  contain `_` (the topic placeholder).
- **Placeholder rule:** if a step is a call with an argument list, the topic
  is threaded as the **first argument** unless `_` appears in the argument
  list, in which case `_` is replaced by the topic at *every* occurrence and
  the first-argument rule is suppressed. (Same rule as Hack's `|>` and the
  TC39 pipe proposal F2 variant.)
- **Block steps** (`|> map { ... }`, `|> grep { ... }`, `|> tap { ... }`)
  have the topic bound to `$_` inside the block, exactly as `map`/`grep`
  already work. `tap` is a built-in that runs the block for its side effect
  and yields the original topic.
- **Value:** the value of the last step. In an expression context the
  pipeline propagates the calling context to the last step (scalar vs list).
- A `pipe { ... }` with no `|>` is the same as evaluating the head — useful
  for symmetry but lints as a warning.

---

## 3. Architecture (mirrors Switch::Declare)

```
lib/Pipe/Declare.pm     # thin loader: $^H pragma flag + XSLoader::load
Declare.xs              # keyword plugin + parser + optree codegen
ppport.h                # backports of OpSIBLING / pad_add_name_pvn
Makefile.PL             # core C API only — no CPAN build/parse deps
```

`import` (Perl): `sub import { $^H{'Pipe::Declare'} = 1 }`, mirroring
[Switch/Declare.pm](Switch-Declare/lib/Switch/Declare.pm#L12).
`unimport` deletes the hint. The XS side:

```c
static int (*pd_next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int pd_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr) {
    if (kwlen == 4 && memcmp(kw, "pipe", 4) == 0
        && hv_fetchs(GvHV(PL_hintgv), "Pipe::Declare", 0))
    {
        return pd_parse_pipe(aTHX_ op_ptr);          /* KEYWORD_PLUGIN_EXPR */
    }
    return pd_next_keyword_plugin(aTHX_ kw, kwlen, op_ptr);
}
```

Registered once at `BOOT:` time, chained to the previous plugin — identical
shape to Switch::Declare. No CV is installed in any package; `pipe` is a
keyword **only** within the lexical scope where `$^H{'Pipe::Declare'}` is
set. Outside such a scope `pipe` is a normal identifier.

---

## 4. Parsing strategy (compile time)

All API used is stable since 5.14, matching `MIN_PERL_VERSION`.

1. After consuming `pipe`, `lex_read_space(0)`; require `{`; `lex_read_unichar(0)`.
2. **Head expression:** `parse_termexpr(0)` to get the topic `OP*`. The head
   can be any term: a variable, a call, a literal, a parenthesised
   expression. (We deliberately use `parse_termexpr`, not `parse_fullexpr`,
   to stop *before* a low-precedence operator could swallow the rest of the
   pipeline.)
3. **Step loop:** at each iteration `lex_read_space(0)`; if next is `}`
   we're done. Otherwise require `|>` (hand-lexed: a `|` byte immediately
   followed by `>` with no space; anything else is a syntax error with a
   specific message — never silently fall through to bitwise-or). Then
   classify the step by lookahead:
   - leading `\&` or `\` → reference / coderef expression (`parse_termexpr`).
   - leading `sub` keyword → anonymous sub (`parse_termexpr` — it already
     handles `sub { ... }`).
   - leading `->` → method-or-deref step; record the dereference shape
     (`->method`, `->method(ARGS)`, `->{...}`, `->[...]`) and the args.
   - leading bareword followed by `{` and a block-only step name (`map`,
     `grep`, `tap`, or — opt-in via import flag — any user-registered
     block-step name) → **block step**: parse the bareword, then
     `parse_block(0)` for the body.
   - leading bareword (possibly `::`-qualified) followed by `(` → **call
     step**: read the sub name via the sibling's `sd_lex_subname` pattern,
     then `parse_listexpr(0)` between the parens. Scan the parsed list op
     for `_` placeholders (a bareword `_` lowers to a `OP_CONST` with PV
     `"_"` only because no `&_` sub exists — we instead recognise `_` at
     parse time by inspecting the bareword token before `parse_listexpr`
     decides what to do with it; see §5d).
   - leading bareword *not* followed by `(` or `{` → **nullary call step**:
     `name($topic)`.
   - anything else (sigil, paren, literal) → **coderef-expression step**:
     `parse_termexpr(0)`; at runtime its value is called with `$topic`.
4. Trailing `;` allowed (and consumed) before `}`. Multiple statements →
   `croak("pipe: a pipe { } block must contain exactly one pipeline expression")`.
5. Require `}`; consume it; return the assembled `OP*` via `*op_ptr` with
   `KEYWORD_PLUGIN_EXPR` so the construct is a term (statement *and*
   expression form for free, just as in Switch::Declare).

All step parsing **delegates user code to `parse_termexpr` / `parse_listexpr`
/ `parse_block`**. We never hand-roll Perl-expression parsing — we only lex
the framework tokens (`|>`, `_`, `->`, the `pipe` keyword itself, step-shape
prefixes).

---

## 5. Code generation / lowering (the core)

For a head expression `H` and N steps `S_1 .. S_N`, the construct lowers to:

```
($topic_1) = H;
($topic_2) = step_call(S_1, $topic_1);
...
($topic_{N+1}) = step_call(S_N, $topic_N);
                          $topic_{N+1}              # final value
```

In practice we emit this as a single optree — a sequence of pad-store →
call-op pairs threaded by `OpSIBLING`, wrapped in a single
`OP_LEAVE`/`OP_SCOPE` (chosen by whether any step needs `my`/`local`).
The topic temps are pad slots allocated via `pad_add_name_pvn`, mirroring
Switch::Declare's "scrutinee temp" trick.

### 5a. Bareword call step — `|> name` and `|> name(ARGS)`

Lower to `newUNOP(OP_ENTERSUB, ...)` with a `pushmark` + the threaded args
+ an `OP_RV2CV` of a named sub. For the nullary form `|> name`, args are
`($topic)`. For the call form `|> name(a, b, _, c)` we inspect the parsed
arglist:

- if no `_` placeholder is present → prepend `$topic` as first arg.
- if one or more `_` placeholders are present → replace each `OP_CONST`
  PV `"_"` token (recognised at lex time before `parse_listexpr` runs by
  checking the token immediately) with an `OP_PADSV` reading `$topic`.
  When the topic is used more than once, the optimiser will keep it in
  the pad temp — no re-evaluation, ever.

### 5b. Qualified sub — `|> Foo::Bar::baz`

Identical to 5a but `OP_RV2CV` uses a fully-qualified GV. The sibling's
`sd_lex_subname` reader is reused verbatim.

### 5c. Method / deref step — `|> ->method(ARGS)` / `|> ->{k}` / `|> ->[i]`

Lower to the corresponding op directly: `OP_METHOD_NAMED` + `entersub` for
`->method`; `OP_HELEM` / `OP_AELEM` for `->{...}` / `->[...]`. The topic is
the invocant / aggregate. This is faster than going through `$_` because we
know the op type at compile time.

### 5d. Code block step — `|> map { B }` / `|> grep { B }` / `|> tap { B }`

These three are recognised as a closed set in v1 (their semantics are
fixed and well-known; extending the set is a v1.1 export-driven option).

- `map { B }`: emit a real `OP_MAPSTART`/`OP_MAPWHILE` with `B` as the
  block and `$topic` (must be array-typed) as the list.
- `grep { B }`: same with `OP_GREPSTART`/`OP_GREPWHILE`.
- `tap { B }`: emit `B` with `$_` aliased to `$topic` (via `local *_` or
  a `OP_ENTERSUB`-free inline block); discard B's value; yield `$topic`.
  This is the compile-time inline of `Func::Util::tap`.

`B` is parsed with `parse_block(0)`, so `my`, `last`, `next`, `return` all
behave as expected — same trick Switch::Declare uses for arm bodies.

### 5e. Coderef-expression step — `|> EXPR` (EXPR not a step prefix)

Lower to `EXPR->($topic)`: `OP_ENTERSUB` on the term op produced by
`parse_termexpr`, with `$topic` as the single argument. The `EXPR` is
evaluated **once per pipe execution**, not at compile time, so
`|> $dispatch{$key}` works as expected.

### 5f. Context propagation

The last step inherits the calling context of the whole `pipe { ... }`
expression (scalar / list / void). Intermediate steps are all scalar
context — the topic is a single scalar. Documented explicitly; tested in
`t/02-context.t`.

### Compile-time checks (free, since we have the optree)
- Empty pipe (no head, just `}`) → croak.
- Multiple statements / stray `;` mid-pipeline → croak with location.
- `|>` not followed by a recognisable step → croak ("expected pipe step
  after |>, found ...").
- `_` placeholder outside a call-step arglist → croak (it is meaningless
  there; in a coderef step the topic is already threaded).
- Optional warning: a bareword step name that resolves to no sub at the
  end of compilation (via a `CHECK`-block hook on the calling package) —
  off by default, on with `use Pipe::Declare 'strict'`.

---

## 6. Runtime semantics summary

| Aspect                    | Behaviour                                                 |
|---------------------------|-----------------------------------------------------------|
| head expression           | evaluated exactly once                                    |
| step ordering             | left-to-right; strict; no reordering                      |
| topic threading           | first arg, or every `_` placeholder if any are present    |
| `$_` inside a block step  | aliased to topic (as `map`/`grep` already do)             |
| method / deref step       | topic is invocant / aggregate                             |
| context of last step      | inherited from the `pipe { }` expression                  |
| context of inner steps    | scalar                                                    |
| `return` inside a block   | returns from the enclosing sub (block-step bodies are real blocks, not CVs) |
| value of whole pipe       | value of the last step                                    |
| exceptions                | propagate; no implicit `eval`                             |

---

## 7. Performance plan

- **Claim to validate:** a pipe of N bareword/qualified steps compiles to the
  same optree as the hand-written `f3(f2(f1($x, @a1), @a2), @a3)` — bench
  must show ≤ 2% delta (call overhead is the same; the pad-temp threading
  adds at most one `padsv` per step, which the peephole optimiser removes
  when the temp is used once).
- **Comparison points** (in `xt/bench.pl`, `Benchmark` + `Dumbbench`):
  - 3, 5, 10, 25 steps — `pipe { ... }` vs hand-nested vs
    `Func::Util::pipeline` vs Sub::Pipe (old CPAN runtime baseline).
  - Bareword vs qualified vs coderef-expression steps — measure the
    `RV2CV` resolution cost the optimiser saves.
  - Block steps (`map`/`grep`) — must match `map { B } LIST` exactly
    (we emit the same op).
  - Compile-time cost per `pipe { }` — confirm negligible vs a function
    call (≤ tens of microseconds).
- **Memory:** zero extra allocations per step beyond the pad temp. The
  topic is in a register-resident pad slot; intermediate scalars are
  reused (the temp pad slot is the same SV for every step).
- Verify "head evaluated once" with a side-effecting head expression test.

---

## 8. Future work — true infix `|>` (v1.1+)

Pre-5.37.7 there is no portable way to register a new infix operator
without a source filter, so v1 is **block-form only**. From 5.37.7
onwards, `PL_infix_plugin` makes it possible to register `|>` as a real
infix that works at any expression site, with precedence chosen between
`or` and `,`. Plan:

- Detect at `BOOT:` whether `PL_infix_plugin` exists; if so, also install
  an infix hook that recognises `|>` lexically when `$^H{'Pipe::Declare'}`
  is set.
- The infix hook emits the **same step-call op** the block parser would
  emit for one step — so the lowering code is shared.
- Block form remains supported on all perls and is the documented
  portable spelling.

This is intentionally deferred so v1 ships on every supported perl
(5.14+) with one parsing path and one lowering path.

---

## 9. Dist layout & build

```
Pipe-Declare/
  lib/Pipe/Declare.pm     # loader + full POD
  Declare.xs              # all C
  ppport.h                # OpSIBLING etc. backports
  Makefile.PL             # core API only, no CPAN deps
  t/                      # see §10
  xt/bench.pl  xt/boilerplate.t
  Changes  MANIFEST  README  ignore.txt
```

`Makefile.PL` — copy verbatim from [Switch-Declare/Makefile.PL](Switch-Declare/Makefile.PL):
`MIN_PERL_VERSION => '5.014'`, `LICENSE => 'artistic_2'`, no `PREREQ_PM`,
USTAR tar, the EUMM back-compat block. Change `NAME` and `VERSION_FROM`.

`lib/Pipe/Declare.pm` — strip the module-starter boilerplate; replace
with the Switch::Declare-shaped loader:

```perl
package Pipe::Declare;
use 5.014; use strict; use warnings;
our $VERSION = '0.01';
require XSLoader; XSLoader::load('Pipe::Declare', $VERSION);
sub import   { $^H{'Pipe::Declare'} = 1 }
sub unimport { delete $^H{'Pipe::Declare'} }
1;
```

…plus the real POD (synopsis from §2, semantics table from §6, comparison
notes against `Func::Util::pipeline`).

---

## 10. Testing plan (`t/`)

- `00-load.t` — module loads; `pipe` keyword is recognised inside a
  `use Pipe::Declare` scope and **not** outside it.
- `01-basic.t` — bareword chain; expression and statement form; no-step
  pipe yields head value.
- `02-context.t` — last step in scalar / list / void context yields the
  expected shape; intermediate steps are scalar.
- `03-call-step.t` — call with args; topic threaded as first arg; `_`
  placeholder in 1, 2, and 3 positions; multiple `_` in one arglist all
  see the *same* topic.
- `04-coderef-step.t` — `\&f`, `sub {...}`, `$cv`, `$h->{cb}`, all called
  with topic.
- `05-method-step.t` — `->method`, `->method(@a)`, `->{k}`, `->[i]`,
  chained.
- `06-block-step.t` — `map`, `grep`, `tap` block steps; `$_` aliasing;
  `return` inside the enclosing sub works; `last` inside `map` doesn't
  leak.
- `07-once.t` — head with a side effect is evaluated exactly once,
  regardless of step count.
- `08-scope.t` — `$^H` lexical scoping: `pipe` is the keyword only
  inside a `use Pipe::Declare` block, even within one file.
- `09-errors.t` — empty pipe, stray `;`, `|>` with no step, `_` outside a
  call-step arglist, multi-statement body → exact croak messages.
- `10-interop.t` — pipe through `Func::Util::pipeline`,
  `List::Util::sum0`, `JSON::PP::decode_json`; pipe a result *into* a
  `switch (...)` from `Switch::Declare` (uses both pragmas in one scope).
- `11-bench-smoke.t` — assert the compiled optree of a 5-step pipe has
  the expected op count (via `B::Concise`) — guards against accidental
  optree bloat.
- `pod.t`, `pod-coverage.t`, `manifest.t`, `xt/boilerplate.t` — as sibling.

---

## 11. Milestones

1. **Skeleton + build green** — Makefile.PL (no deps), loader, empty XS
   that installs the keyword plugin and recognises `pipe` inside a
   `$^H{'Pipe::Declare'}` scope; `00-load.t` passes.
2. **Head + one bareword step** — minimal `pipe { H |> f }` lowering;
   `01-basic.t` (subset).
3. **All step kinds** — qualified subs, coderef-expression steps, method
   / deref steps, call-with-args with `_` placeholder; `03`–`05`.
4. **Block steps** — `map`, `grep`, `tap`; `06`.
5. **Context + once-eval guarantees** — `02`, `07`.
6. **Lexical scoping + error reporting** — `08`, `09`.
7. **Docs, bench, polish** — POD, `xt/bench.pl`, Changes, README,
   MANIFEST; confirm ≤2% delta vs hand-nested calls.
8. **(v1.1)** — `PL_infix_plugin` registration of a true infix `|>` on
   5.37.7+; shared lowering path.

---

## 12. Risks & mitigations

- **Optree construction correctness** (the hard part, identical to
  Switch::Declare's hardest part): scope entry/exit, refcounts, value
  context, pad slot lifetime. Mitigate by leaning on `parse_termexpr` /
  `parse_listexpr` / `parse_block` for **all** user code (we only build
  call + threading ops), and by reusing Switch::Declare's already-tested
  pad-temp scrutinee pattern.
- **Placeholder ambiguity (`_`):** Perl's `_` is already meaningful in
  filetests and prototypes. We recognise it only inside a `|> name(...)`
  arglist and only as a bareword token, never as `\&_` or `&_()`. The
  error message for `_` elsewhere in a pipe is explicit.
- **`|>` token vs bitwise-or-then-greater:** outside our block we never
  see `|>`; inside, we hand-lex it and require exactly `|>` with no
  space between. Any other use of `|` inside a `pipe` block is a
  compile error with a clear message — we don't try to be clever.
- **Context propagation through call ops:** Perl's call ops already
  propagate context correctly when threaded into the right outer op.
  Verified by `02-context.t` across scalar / list / void.
- **Block steps and `return`:** because block-step bodies are real
  `parse_block` blocks (not anonymous subs), `return` exits the
  enclosing sub — same as `map { ... }` already does. Documented and
  tested.
- **Cross-version lexer/op API drift:** identical surface to
  Switch::Declare; ppport.h covers the OpSIBLING / pad_add_name_pvn
  deltas. CI across 5.14 → current.
- **Dependency vs zero-dep house style:** none added. Core C API only,
  matching `Switch::Declare`, `Func::Util`, and the rest of the family.

---

## Appendix A — relationship to `Func::Util::pipeline`

`Func::Util` already ships [pipeline()](Func-Util/lib/Func/Util.pm#L98):

```perl
my $result = pipeline($data, \&fetch, \&transform, \&process);
```

That is the **runtime, value-level** form: a function that walks an array
of coderefs and threads a value through them. `Pipe::Declare` is the
**compile-time, syntactic** form of the same idea:

|                         | `Func::Util::pipeline`           | `Pipe::Declare`                  |
|-------------------------|----------------------------------|----------------------------------|
| when threading happens  | runtime                          | compile time                     |
| step shape              | coderef only                     | any of §5a–§5e                   |
| extra args per step     | via closures / `\&` wrappers     | inline: `|> f(a, b, _)`          |
| optree cost             | one `entersub` per pipeline call + one array walk + one call per step | one call per step, no wrapper    |
| readability             | data-style: `pipeline($x, ...)`  | code-style: `$x |> f |> g`       |
| can take method / deref | only via wrapper closures        | natively (`->method`, `->{k}`)   |

Both will continue to coexist — `pipeline()` for first-class /
programmatically-built pipelines, `pipe { }` for hand-written code where
left-to-right reading order matters.

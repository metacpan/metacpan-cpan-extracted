# For authors

## Where things are

| Path | What |
|---|---|
| `lib/Peta/NN/Data.pm`, `Model.pm`, `Chain.pm` | the high level: data, models, chains |
| `lib/Peta/NN/Job.pm`, `Inference.pm`, `Pipeline.pm`, `Fused.pm`, `Parallel.pm`, `Codec.pm` | the building blocks |
| `lib/Peta/NN.pm`, `Backend.pm`, `Backend/`, `Layer/`, `Optimizer.pm`, `RNG.pm` | the engine: the network, its three backends, layers, optimizers, the seeded generator |
| `lib/Peta/NN/Teacher/` | readers of the PetaMem lexica: rules of a `.lex` grammar as teachers, word lists; not part of the distribution |
| `bin/peta-nn-info` | what a file is |
| `t/` | the tests; `t/lib/Synthetic.pm` holds the invented rule sets they learn |
| `xt/` | for authors: POD, the code in the docs, the reference |
| `examples/` | [the examples](examples.md); what they write goes to `examples/out` |
| `bench/train.pl`, `scale.pl` | training throughput of a micro model, and time per step from micro to wide, per backend |
| `bench/infer.pl`, `inference.pl` | time per decision: the backends, and a model file |
| `bench/fused.pl` | a pipeline against the same models fused: the same answers, and the time per string |
| `bench/growth.pl` | an experiment: a trained model made wider or given new labels, against training from scratch |
| `bench/kernels.pl`, `jit-fresh-array.pl`, `jit-ternary-store.pl`, `gpu-fork.pl` | hot loops in isolation; checks of pperl behaviour |
| `devbin/build_dist.pl` | builds the CPAN distribution and the bundle of models |
| `devbin/build_docs.pl`, `docs_run.pl`, `docs_links.pl` | the reference from the POD; a page's code run; the links followed |
| `docs/` | this documentation |

## Running the tests

```sh
PP=/data/proj/Perl/PetaPerl/peta-perl/target/release/pperl

prove --exec $PP t             # every backend this perl has
OTHER_PERL=$PP prove t         # on perl5; also runs the inference leg under pperl
prove --exec $PP xt            # for authors: POD, the code in the docs, the reference
$PP examples/inflect.pl
PETA_NN_BACKEND=pdl $PP examples/inflect.pl
$PP bin/peta-nn-info examples/out/inflect.chain
PETA_NN_WORKERS=4 $PP examples/nouns-deu.pl     # its four models side by side
```

What each example needs is in [the examples](examples.md): `inflect.pl`
nothing, `nouns-deu.pl` its data file, which ships, the others the PetaMem
lexica or PMLS. The tests need none of that; they build what they need.

The tests reach 96% of the statements and 99% of the subs of the library on
perl 5.42 (Devel::Cover, one test file at a time: run through `prove` in one
go it loses what the forking tests cover and reports 85%). What they do not
reach there is the GPU backend, which only pperl has.

## Keeping the documentation true

`prove xt` checks that every module's POD is well formed and documents every
public sub, that the Perl in the documentation runs, and that the reference
pages are what the POD gives now.

| After | run |
|---|---|
| changing a module's POD | `perl devbin/build_docs.pl`, which writes `docs/reference` |
| changing what a guide shows | `perl devbin/docs_run.pl --write docs/guides/PAGE.md`, which runs the page's code and puts what each block printed into it |
| adding or moving a page | `perl devbin/docs_links.pl`, which follows every link |

The pages under `docs/blocks` and `docs/measurements` are the building
blocks and the numbers; their code is shown, not run.

## Design decisions

- **Determinism.** Initial weights and shuffling come from the library's own
  generator. On the plain backend the same seed gives bit-identical weights
  on perl5 and pperl; the tests rely on that.
- **Exact state files.** Weights are packed as little-endian doubles before
  Storable sees them, because `nstore` writes doubles as decimal text and
  drops their last bits.
- **Verification by algorithm.** Gradients are checked against numeric
  differentiation for every layer and loss, on every backend. Training is
  checked on functions and rule sets we can compute, on inputs held out from
  training.
- **Plain kernels read as array code.** Each aliases its tensors to lexical
  arrays (`\my @W = ...`, the `refaliasing` feature). That is also the form
  pperl's JIT compiles.

## The distribution

`perl devbin/build_dist.pl` builds the CPAN distribution `Peta-NN` the way
the Lingua distributions are built from PMLIB (Dist::Zilla with the PetaMem profile,
a README and a Changes file written at build time). The version is the day
of the build, `0.YYMMDDX`, with a last digit that counts that day's uploads,
and is stamped into every module of the distribution (in the repository the
modules carry `0.0`). It tests what it built,
and uploads nothing unless told to with `--upload`.

| it makes | holding |
|---|---|
| `devbin/build/Peta-NN/Peta-NN-VERSION.tar.gz` | the library, `peta-nn-info`, the tests, the documentation, and two examples that need nothing else: the invented inflection, and the German nouns with their data (`nouns.tsv`, 45,000 nouns) and the three chains trained from it; 870 kB |
| `devbin/build/Peta-NN-models-VERSION.tar.gz` | every other chain the examples have trained (114 files: the Czech grammar and adjectives, the language identifier, the word-class chain), with a README that says what each is, and without training data; 2.2 MB |

Left out of the distribution: `Peta::NN::Teacher::*`, and the examples,
benchmarks and tests that read the PetaMem lexica. The licence is that of
PetaMem's Lingua distributions on CPAN: Artistic 2.0 or BSD 2-Clause.

The tarball is tested by installing it: `perl Makefile.PL && make test` passes
on perl 5.42.2 with PDL and Parallel::ForkManager (698 tests) and on a bare
perl 5.44.0 (650 tests, what needs PDL or forking skipped), and its tests
pass under pperl (739, the GPU backend, the fused models on the card and
training kept on the card among them).

## pperl gaps

State as of the build of 2026-10-04 with git `20e49bd91d` (features
`native-max,pdl,webgpu`).

1. **No parallelism inside a process.** The plain kernels' outer loops have
   independent iterations that each write their own array elements, which
   the parallelizer does not admit yet. PDL's matrix product runs on one
   core (0.68 ns per multiply-add). The loop shape is on the JIT lane's
   list; the PDL lane is working on a Rayon matrix product.
2. **Float sums that grow past about 1e15 lose the JIT.** Reproduced by the
   "values near 1e11" row of `bench/kernels.pl`; network weights never get
   there.

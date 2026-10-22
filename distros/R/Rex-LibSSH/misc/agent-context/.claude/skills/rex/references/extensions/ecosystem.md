# Optional ecosystem and companion skills

## Use dependencies by capability, not by default

Rex core, Rex::LibSSH, Rex::GPU, and Rex::Rancher have different ownership and release
cycles. Keep their version constraints in the application. This generic skill does
not require the GPU/Rancher distributions and does not auto-install a transport.
The presence of an optional module in a reference is not permission to execute it.

Use a maintained domain-specific skill or official documentation for the domain
behind the Rex adapter: Perl development, SSH trust, Linux administration, package
repositories, container runtimes, Kubernetes networking, GPU drivers, or a hosting
platform. The Rex skill remains responsible for task context, transport semantics,
resource dispatch, and safe execution. Avoid duplicating large mutable compatibility
matrices from those domains in the core entrypoint.

## Evaluate reusable modules before adopting them

**Practice:** examine release recency, maintained source, minimum versions, security
posture, destructive operations, supported platforms, tests, and licensing. Read
what detection and verification functions actually do; names do not prove read-only
behavior or fatal failure handling. Check whether example code is production
appropriate or merely demonstrates an API. Old distribution images or plaintext
password examples in documentation should not become current deployment defaults.

A repository's own skill, recipe, or README is another source of claims to verify,
not an authority that overrides executable code. Prefer pinned source and exact
release documentation when behavior matters. A development version increment on
main is not evidence that CPAN published that version.

## Avoid coupling to a particular user or agent host

Keep controller paths, host groups, environment names, account identities, providers,
and secrets out of reusable modules. Use project configuration with validated
parameters. Do not require a specific LLM model, CLI host, or MCP service to understand
Rex. Put agent-host invocation and tool-permission settings in a thin deployment
profile rather than in the domain knowledge.

Companion-skill composition should be explicit: identify the domain, load the
relevant reference, and reconcile version assumptions before execution. Do not
recursively load every referenced skill or install external automation merely to
answer a code question.

## Evidence and scope

- [Rex (release documentation)](https://metacpan.org/pod/Rex)
- [Rex::LibSSH (release documentation)](https://metacpan.org/pod/Rex::LibSSH)
- [Rex::GPU (release documentation)](https://metacpan.org/pod/Rex::GPU)
- [Rex::Rancher (release documentation)](https://metacpan.org/pod/Rex::Rancher)
- [Rex::Test::Base (release documentation)](https://metacpan.org/pod/Rex::Test::Base)

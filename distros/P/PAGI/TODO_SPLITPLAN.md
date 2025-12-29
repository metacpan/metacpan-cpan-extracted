# PAGI Repository Split Analysis

This document analyzes options for splitting the PAGI repository into multiple distributions.

## Current Structure

| Component | Files | Coupling | Splittable? |
|-----------|-------|----------|-------------|
| **Core Spec** (PAGI.pm, Request, Response, WebSocket, SSE, Lifespan) | 6 | Tight | No - this IS the spec |
| **Server** (Server.pm, Connection, Protocol) | 3 | Tight internal | Yes - reference impl |
| **Middleware** | 37 | None between them | Yes - all independent |
| **Apps** | 19 | Minimal | Yes - mostly standalone |
| **Test Utilities** | 4 | None | Yes - optional |

### Key Observations

1. **Middleware is naturally modular**: 37 completely independent modules with zero inter-dependencies.
2. **Apps have minimal coupling**: 19 apps, mostly independent. Only Router has internal dependencies.
3. **Server is not required by apps**: Core wrappers work with any PAGI-compliant server.
4. **Request subsystem is tightly coupled internally**: 5 files with internal dependencies.
5. **Test utilities are optional**: PAGI::Test::* can be safely removed without affecting production.

---

## Split Options

### Option 1: Keep Unified (Status Quo)

```
PAGI  →  Everything in one distribution
```

**Pros:**
- Single `cpanm PAGI` installs everything
- Coordinated versioning - spec changes update all components together
- Shared test suite validates integration
- Simpler for contributors
- Spec is still "unstable" - tight coordination needed during evolution

**Cons:**
- Users who only want middleware must install Server
- Large dependency tree for minimal use cases
- Version bumps affect everything even for small fixes

---

### Option 2: Split Server Only

```
PAGI              →  Core spec + wrappers + middleware + apps
PAGI::Server      →  Reference IO::Async server + Runner
```

**Pros:**
- Users can use PAGI with alternative servers (Mojo, Twiggy, etc.)
- Server can version independently (bug fixes don't bump spec)
- Clarifies that Server is reference implementation, not required

**Cons:**
- Two distributions to coordinate
- Examples need both installed
- "Getting started" becomes two-step

---

### Option 3: Three-Way Split

```
PAGI              →  Core spec + convenience wrappers only
PAGI::Contrib     →  All 37 middleware + 19 apps
PAGI::Server      →  Reference server + Runner
```

**Pros:**
- Clean separation of concerns
- Contrib can accept community PRs with looser standards
- Minimal core for framework authors
- Middleware/apps can version independently

**Cons:**
- Three packages to install for full experience
- Middleware tests need PAGI::Server for integration testing
- Documentation scattered across repos

---

### Option 4: Full Split (Maximum Modularity)

```
PAGI                    →  Spec only
PAGI::Server            →  Reference server
PAGI::Middleware        →  37 middleware
PAGI::Apps              →  19 apps + Router
PAGI::Test              →  Test utilities
```

**Pros:**
- Maximum flexibility
- Install only what you need
- Each component can evolve independently

**Cons:**
- Dependency management nightmare
- Coordinated releases become painful
- Version matrix testing explodes
- Confusing for new users

---

## Recommendation

### Near-term: Stay unified

The spec is still evolving (0.001.x), and tight coordination helps iterate quickly. Breaking changes to the core protocol affect everything, and a unified repo makes coordinated updates straightforward.

### Medium-term: Option 2 (Split Server)

When the spec stabilizes (perhaps 0.1.x or 1.0), split out the Server:

1. Server is explicitly a "reference implementation"
2. Users may want alternative servers (Mojo::Server::PAGI, etc.)
3. Server bugs/fixes don't need to version-bump the spec
4. Keeps middleware/apps with core for tight integration

### Long-term: Option 3 (Three-Way Split)

Consider if community contributions to middleware/apps grow significantly:

1. Different review standards for contrib vs core
2. Faster iteration on middleware without spec coordination
3. Framework authors get minimal core dependency

---

## Migration Path

If we proceed with splitting:

### Phase 1: Prepare (Current)
- Document component boundaries clearly
- Ensure middleware/apps have no hidden dependencies on Server internals
- Add integration tests that work across package boundaries

### Phase 2: Split Server (When spec stabilizes)
- Create PAGI-Server distribution
- Move lib/PAGI/Server.pm, lib/PAGI/Server/*, lib/PAGI/Runner.pm
- Update PAGI to recommend (not require) PAGI::Server
- Maintain shared test suite via xt/ or separate test distribution

### Phase 3: Split Contrib (If needed)
- Create PAGI-Contrib distribution
- Move lib/PAGI/Middleware/*, lib/PAGI/App/*
- Core PAGI becomes spec + Request/Response/WebSocket/SSE/Lifespan only

---

## Open Questions

1. What's driving the split feedback - lighter installs or contribution workflow?
2. Are there users wanting alternative server implementations?
3. Should PAGI::Test stay with core or become separate?
4. How to handle shared examples that need all components?

---

*Last updated: 2025-12-25*

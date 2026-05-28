# INTENTIONAL_NON_IMPLEMENTATION.md (template)

This file is the per-port allow-list for `scripts/audit_stubs.py`. Copy it to your port's repo root and add an entry every time `audit_stubs.py` flags something legitimate.

`audit_stubs.py` greps for stub-flavored patterns ("stub: in production", `NotImplementedError("todo...")`, `unimplemented!()`, etc.). Most matches are real bugs that must be fixed. A small set are NOT bugs — they're deliberate non-implementations for one of the four reasons below.

If the audit flags a line and the line falls into one of the categories below, add it to this file. If it doesn't, fix the code.

---

## What goes here

Only these four categories are eligible for the allow-list. **Anything else must be fixed, not allow-listed.**

### 1. Optional-extra import guards

A symbol that raises a clear error when an optional Python extra / npm extras / Cargo feature isn't installed. The error must direct the user at the install command.

**OK example:**

```python
def cli_helpers():
    raise NotImplementedError("CLI helpers not available — install with `pip install signalwire[cli]`")
```

### 2. Abstract methods in base classes

Base classes whose subclasses MUST override the method. The base class raises `NotImplementedError` (Python/Ruby), is `abstract` (Java/.NET), is `= 0` (C++), or panics (Rust trait method without default).

**OK example:**

```ruby
class SkillBase
  def name
    raise NotImplementedError, "#{self.class}#name"
  end
end
```

### 3. Documented platform/API restrictions

The upstream service genuinely doesn't support the operation. The error message identifies the upstream restriction, not an SDK gap.

**OK example:**

```python
def create_cxml_application(self, *args, **kwargs):
    raise NotImplementedError(
        "cXML applications cannot be created via this API. "
        "Use the SignalWire web console."
    )
```

### 4. Genuine no-op shims for cross-API compatibility

A no-op implementation of a hook that exists in another framework's API but has no semantic equivalent on the SignalWire platform. The docstring AND the entry here must explain why it's a no-op, not a stub.

**OK example:**

```typescript
// LiveKit shim: SignalWire doesn't have a prewarm phase, so this hook is a
// genuine no-op. Tools written against LiveKit's API can call it harmlessly.
prewarm(): void {}
```

---

## What does NOT go here

If you're tempted to add any of these, fix the code instead.

- "I'll come back to it later." Comment-out the symbol or revert the commit until you do.
- "It's only used in tests." Tests don't run stub bodies; if the symbol is reachable from production, it's production.
- "The other ports also stubbed it." Their being broken doesn't make yours OK.
- "The upstream service is hard to integrate." Hard isn't optional.
- "Feature-gated for the build I happened to run." If the gate isn't enabled by default and there's no working fallback, the gate is a stub disguise.

---

## Format

Every list item is parsed by `audit_stubs.py`. Use this exact shape:

```
- <file:line> — <one-sentence justification, ≤ ~80 chars>
```

The `file` is relative to the port repo root. The `line` is 1-indexed and matches what `audit_stubs.py` reports.

---

## Allow-listed entries

> Empty in this template. Each port's copy of this file should populate this section.

<!--
Example entries (do NOT keep these in your port — they're examples):

- signalwire/__init__.py:52 — optional-extra import guard for CLI helpers
- lib/signalwire/skills/skill_base.rb:17 — abstract method, subclasses must override
- src/livewire/index.ts:775 — LiveKit prewarm hook, SignalWire genuinely doesn't need it
- signalwire/rest/namespaces/fabric.py:125 — cXML applications cannot be created via this API (upstream restriction)
-->

# Params::Filter Call Chain Analysis

## Current Call Structure

```
User Code
    |
    +-- Functional Interface: filter($data, @rules)
    |       |
    |       v
    |   filter() [Does all the work]
    |
    +-- OO Interface: $filter->apply($data)
            |
            v
        apply() [Thin wrapper - extracts object fields]
            |
            v
        filter() [Does all the work]
```

## Call Chain Details

### Functional Interface Path
```
1. User code calls:
   my ($result, $msg) = filter($data, \@required, \@accepted, \@excluded, $debug);

2. filter() is called directly
   - Parses input (hashref/arrayref/scalar)
   - Validates required fields
   - Removes excluded fields
   - Accepts optional fields
   - Returns (filtered_hashref, status_message)
```

### OO Interface Path
```
1. User code creates filter:
   my $filter = Params::Filter->new_filter({
       required => \@fields,
       accepted => \@fields,
       excluded => \@fields,
   });

2. User code calls:
   my ($result, $msg) = $filter->apply($data);

3. apply() is called:
   - Extracts $self->{required}, $self->{accepted}, $self->{excluded}, $self->{debug}
   - Calls filter($data, $req, $ok, $no, $db)
   - Checks wantarray
   - Returns result in appropriate context

4. filter() is called with extracted parameters
   - Same as functional path from here
```

## Simplification Opportunities

### Current Inefficiencies

1. **OO Wrapper Overhead**
   - `apply()` is just a thin wrapper (5 lines of work)
   - Extracts fields from object
   - Calls `filter()`
   - Checks `wantarray` (again - `filter()` also checks it)
   - Returns in context

2. **Double wantarray Check**
   - `apply()` checks `wantarray` at line 300
   - `filter()` checks `wantarray` at line 563 (and throughout)
   - This is redundant

3. **OO State Management**
   - Modifier methods (`set_required`, etc.) just update object fields
   - Object is just a container for arrays
   - No real computation stored in object

### Potential Simplifications

#### Option 1: Inline filter() into apply() (Eliminate wrapper)
```perl
sub apply {
    my ($self, $args) = @_;
    # Inline the filter logic here with $self->{required} directly
    # Eliminates one function call
    # Reduces parameter passing overhead
}
```
**Pros:**
- Eliminates one function call overhead
- No parameter extraction needed
- Direct access to object fields

**Cons:**
- Code duplication (filter logic in two places)
- Harder to maintain
- Can't use functional interface without duplication

#### Option 2: Eliminate apply() wrapper entirely
```perl
# User calls:
my ($result, $msg) = $filter->($data);

# apply() becomes just:
sub apply { shift->filter(@_) }
```
**Pros:**
- Simpler code path
- Less overhead

**Cons:**
- Breaking API change
- Less explicit about what's happening

#### Option 3: Combine filter() and apply() into one function
```perl
# Detect if called as OO or functional:
sub filter {
    my ($args, $req, $ok, $no, $db) = @_;

    # If called as OO method
    if (ref $_[0] eq 'Params::Filter') {
        my ($self, $args) = @_;
        $req = $self->{required};
        $ok = $self->{accepted};
        $no = $self->{excluded};
        $db = $self->{debug};
    }

    # Rest of logic...
}
```
**Pros:**
- Single code path
- No wrapper overhead
- Easier to maintain

**Cons:**
- Mixed paradigms in one function
- Slightly more complex logic at start
- Still has parameter extraction overhead

#### Option 4: Keep current structure (No change)
**Pros:**
- Clean separation of concerns
- Easy to understand
- Functional and OO interfaces are distinct
- `filter()` can be called independently

**Cons:**
- One extra function call for OO interface
- Minimal overhead (~0.3µs from profiling)

## Quantitative Analysis

From profiling data:

```
Total time per filter() call: ~2.85µs
apply() overhead: ~0.37µs (exclusive time)
filter() work: ~2.48µs

apply() does:
- Extract 4 fields from object: ~0.1µs
- Call filter(): ~2.85µs
- Check wantarray: ~0.02µs
- Return in context: ~0.05µs
```

The wrapper overhead is **~13%** of total time, but in absolute terms it's only **0.37µs**.

For comparison:
- Function call overhead in Perl: ~0.5-1µs
- Hash copy operation: ~0.5-1µs
- Array iteration: ~0.1-0.2µs per element

## Recommendation

### Keep Current Structure

**Reasons:**

1. **Overhead is minimal** - 0.37µs is negligible for most use cases
2. **Code clarity** - Separation of concerns is valuable
3. **Maintainability** - Single `filter()` implementation is easier to maintain
4. **API stability** - Users expect both interfaces to work the same way
5. **Flexibility** - Functional interface can be used independently
6. **Test coverage** - Current tests cover both interfaces well

### When Simplification MIGHT Be Worthwhile

Only consider if:
- Profiling shows filter() in a **very tight loop** (millions of iterations)
- Every microsecond matters (high-frequency trading, real-time systems)
- You're willing to break API compatibility

In those cases, **Option 3** (combine functions) would be the best approach.

## Alternative: Document Performance Characteristics

Rather than changing the code, document when to use each interface:

```perl
# For one-time filtering:
use Params::Filter qw/filter/;
my ($result, $msg) = filter($data, \@rules);

# For repeated filtering (slightly better performance):
my $filter = Params::Filter->new_filter(\%rules);
for my $data (@dataset) {
    my ($result, $msg) = $filter->apply($data);
}

# For maximum performance (bypass Params::Filter):
my @keep = qw/field1 field2 field3/;
my %filtered;
@filtered{@keep} = @data{@keep};
```

## Conclusion

The current call structure is **already well-optimized** for clarity and maintainability. The 13% overhead of the OO wrapper is acceptable given:
- The absolute time is tiny (0.37µs)
- Code clarity is more important than micro-optimizations
- The module is already much slower than manual operations (by design)
- Further optimization would require significant complexity for minimal gain

**Recommendation: No changes needed.**

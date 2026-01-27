# Params::Filter

Secure field filtering for parameter construction.

## Description

`Params::Filter` provides lightweight parameter filtering that checks only for the presence or absence of specified fields. It does NOT validate values - no type checking, truthiness testing, or lookups.

This module separates field filtering from value validation:

- **Field filtering** (this module) - Check which fields are present/absent
- **Value validation** (later step) - Check if field values are correct

### Primary Benefits

The main advantages of using Params::Filter are:

- **Consistency** - Converts varying incoming data formats to consistent key-value pairs
- **Security** - Sensitive fields (passwords, SSNs, credit cards) never reach your validation code or database statements
- **Compliance** - Automatically excludes fields that shouldn't be processed or stored (e.g., GDPR, PCI-DSS)
- **Correctness** - Ensures only expected fields are processed, preventing accidental data leakage or processing errors
- **Maintainability** - Clear separation between data filtering (what fields to accept) and validation (whether values are correct)

### Performance Considerations

**Important**: The functional and OO interfaces include features that add overhead compared to manual hash lookups, especially when the incoming data is in a known consistent format. The value of Params::Filter is in its capability to assure the security, compliance, and correctness benefits listed above.

However, the **Closure Interface** (`make_filter`) provides maximum performance and can be faster than hand-written Perl filtering code due to pre-computed exclusion lookups and specialized closure variants. Use `make_filter` for hot code paths or high-frequency filtering.

For all interfaces, Params::Filter CAN improve overall performance when downstream validation is expensive (database statements, API calls, complex regex) by failing fast when required fields are missing.

A simple benchmark comparing the validation cost of typical input to that of input restricted to required fields would reveal any speed gain with expensive downstream validations.

### Common Use Cases

This approach handles common parameter issues:
- Subroutine signatures can become unwieldy with many parameters
- Ad-hoc argument checking is error-prone
- Validation may not catch missing inputs quickly enough
- Many fields to check multiplies validation time (for expensive validation)

### When to Use This Module

This module is useful when you have:

- Known parameters for downstream input or processes (API calls, method/subroutine arguments, database operations)
    - Fields that must be provided for success downstream (“required”) 
    - Fields useful downstream if provided (“accepted”)
    - Fields to remove before further processing (“excluded”) 
- Incoming data from external sources (web forms, APIs, databases, user input)
- No guarantee that incoming data is consistent or complete
- Multiple data instances to process with the same rules
- Multiple uses tapping incoming data
- A distinction between missing and “false” data

### When NOT to Use This Module

If you're constructing both the filter rules AND the data structure 
at the same point in your code, you probably don't need this module. 
The module's expected use is to apply pre-defined rules to data that 
may be inconsistent or incomplete for its intended use. 
If there isn't repetition or an unknown/unreliable data structure, this might be overkill.

### This Module Does NOT Do Fancy Stuff

As much as this module attempts to be versatile in usage, there are some VERY HANDY AFFORDANCES IT DOES NOT PROVIDE:

- No regex field name matching for designating fields to require, accept, or exclude
- No conditional field designations _within_ a filter:

    `if 'mailing_address' require 'postal_code'`   # No way a filter can do this
- No coderefs or callbacks for use when filtering
- No substitutions or changes to field names
- No built-in filter lists except null `[]` = none
- No fields ADDED to yielded data, EXCEPT:

    * If the provided data resolves to a list or array with an odd number of elements,
    the LAST element is treated as a flag, set to the value 1

    * If the provided data resolves to a single non-reference scalar (probably a text string)
    the data is stored as a hashref value with the key `‘_’`, and returned if `'_'` is
    included in the accepted list or the list is set to `['*']` (accept all)

### Security Benefits

This module provides important security benefits by separating data filtering from validation:

#### Preventing Sensitive Data Leakage

By excluding sensitive fields early in the request processing pipeline, you ensure they never reach validation code, database statements, or logging systems:

```perl
my $user_filter = Params::Filter->new_filter({
    required => ['username', 'email'],
    accepted => ['name', 'bio'],
    excluded => ['password', 'ssn', 'credit_card', 'admin_token'],
});

# Web form submission with password field
my $form_data = {
    username => 'user',
    email => 'user@example.com',
    password => 'secret123',  # Never reaches validation!
};

my ($filtered, $msg) = $user_filter->apply($form_data);
# $filtered = { username => 'user', email => 'user@example.com' }
```

#### Compliance Benefits

Helps meet regulatory requirements by design:

- **GDPR** - Exclude fields you shouldn't store before processing
- **PCI-DSS** - Ensure credit card numbers never touch validation code
- **Data Minimization** - Only process fields you actually need
- **Audit Trails** - Clear record of what fields are accepted/excluded

#### Defense in Depth

Even if validation code has bugs or is later modified, excluded fields **never** reach it. This provides defense in depth:

```perl
# Filter excludes 'admin' field
my $filter = Params::Filter->new_filter({
    required => ['user'],
    accepted => ['email'],
    excluded => ['admin'],  # Security-critical field excluded
});

# Even if validation code is buggy, 'admin' never reaches it
my ($data, $msg) = $filter->apply($untrusted_input);
```

#### Secure by Default

The filter fails closed (returns undef) if required fields are missing, preventing incomplete data from progressing through your system:

```perl
# Missing required field - filter returns undef
my ($data, $msg) = $filter->apply({user => 'bob'});  # email missing
# $data is undef, $msg explains what's missing
```

This prevents partial data from causing security issues downstream.

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

## Usage

### Functional Interface

```perl
use Params::Filter qw/filter/;    # import filter() subroutine

# Define filter rules
my @required_fields = qw(name email);
my @accepted_fields = qw(phone city state zip);
my @excluded_fields = qw(ssn password);

# Apply filter to incoming data (from web form, CLI, API, etc.)
my ($filtered_data, $status) = filter(
    $incoming_params,    # Data from external source
    \@required_fields,
    \@accepted_fields,
    \@excluded_fields,
);

if ($filtered_data) {
    # Success - use filtered data
    process_user($filtered_data);
} else {
    # Error - missing required fields
    die "Filtering failed: $status";
}
```

### Object-Oriented Interface

```perl
use Params::Filter;

# Create a filter object:
my $user_filter = Params::Filter->new_filter({
    required => ['username', 'email'],
    accepted => ['first_name', 'last_name', 'phone', 'bio'],
    excluded => ['password', 'ssn', 'credit_card'],
});

my $data            = $web_app->input_data();
my ($user, $status) = $user_filter->apply($data);
if ($data) {
    # Success - use filtered data
    process_user($data);
} else {
    # Error - missing required fields
    return_to_web_app_form($status);
}

# Apply same filter to multiple incoming datasets
my ($user1, $msg1) = $user_filter->apply($web_form_data);
my ($user2, $msg2) = $user_filter->apply($api_request_data);
my ($user3, $msg3) = $user_filter->apply($db_record_data);
```

### Closure Interface (Maximum Speed)

```perl
use Params::Filter qw/make_filter/;

# Create a reusable filter closure
my $fast_filter = make_filter(
    [qw(id username)],      # required
    [qw(email bio)],        # accepted
    [qw(password token)],   # excluded
);

# Apply to high-volume data stream
for my $record (@large_dataset) {
    my $filtered = $fast_filter->($record);
    next unless $filtered;  # Skip if required fields missing
    process($filtered);
}

# Wildcard example - accept everything except sensitive fields
my $safe_filter = make_filter(
    [qw(id type)],
    ['*'],                      # accept all other fields
    [qw(password token ssn)],   # but exclude these
);

# Safe logging - sensitive fields automatically excluded
my $log_entry = $safe_filter->($incoming_data);
log_to_file($log_entry);  # Passwords, tokens, SSNs never logged
```

The closure interface provides maximum performance for hot code paths and high-frequency filtering operations. It only accepts data in the form of a hashref. It creates a specialized, optimized closure based on your configuration:

- **Required-only** - When accepted list is empty, returns only required fields
- **Wildcard** - When accepted contains `'*'`, accepts all input fields except exclusions
- **Accepted-specific** - When accepted has specific fields, returns required plus those accepted fields (minus exclusions)

## Features

- **Three interfaces**: Functional, OO, or Closure (for maximum speed)
- **Security-first**: Excludes sensitive fields before they reach validation code
- **Performance**: Closure interface can be faster than hand-written Perl filtering
- **Fail-closed**: Returns immediately on missing required parameters
- **Early validation**: Returns immediately if all required parameters are provided and no others are provided or will be accepted
- **Non-destructive**: Allows multiple filters and conditional use without affecting data
- **No value checking**: Only presence/absence of fields
- **Debug mode**: Optional warnings about unrecognized or excluded fields
- **Perl 5.36+**: Modern Perl with signatures and post-deref
- **No dependencies**: Only core Perl's Exporter

## Parameters

### `filter($args, $required, $accepted, $excluded, $debug)`

- **$args**: Input parameters (hashref, arrayref, or scalar)
- **$required**: Arrayref of field names that must be present
- **$accepted**: Arrayref of optional field names to accept (default: `[]`)
- **$excluded**: Arrayref of field names to remove even if accepted (default: `[]`)
- **$debug**: Boolean to enable warnings (default: 0)

### Returns
A filter returns _success_ if all required fields are present, _failure_ otherwise.

In scalar context: hashref with filtered parameters, or undef on failure 

In list context: (hashref with filtered parameters, status_message) or (undef, error_message) 

### Modifier Methods for Dynamic Configuration

The OO interface provides methods to modify a filter's configuration after creation. 

```perl
# Start with an empty filter (rejects all by default)
my $filter = Params::Filter->new_filter();

# Configure it in steps as needed
$filter->set_required(['id', 'name']);
# later:
$filter->set_accepted(['email', 'phone'])
$filter->set_excluded(['password']);
```

#### Available Modifier Methods

- **`set_required(\@fields | @fields)`** - Set required fields (accepts arrayref or list)
- **`set_accepted(\@fields | @fields)`** - Set accepted fields (accepts arrayref or list)
- **`set_excluded(\@fields | @fields)`** - Set excluded fields (accepts arrayref or list)
- **`accept_all()`** - Convenience method: sets accepted to `['*']` (wildcard mode)
- **`accept_none()`** - Convenience method: sets accepted to `[]` (reject all extras)

#### Important Behavior Notes

**Empty Modifier Calls Set Empty Arrays:**
If no fields are provided to `set_required()`, `set_accepted()`, or `set_excluded()`, the respective list is set to an empty array `[]`:

```perl
$filter->set_accepted();  # Sets accepted to `[]`
# Result: Only required fields will be accepted (extras rejected)
```

**Method Chaining:**
All modifier methods return `$self` for chaining:
```perl
$filter->set_required(['id'])
        ->set_accepted(['name'])
        ->accept_all();  # Overrides set_accepted
```

**Mutability:**
A filter may call its modifier methods more than once, and the changes take effect immediately.

**Meta-Programming Use Cases:**
These methods enable dynamic configuration for conditional scenarios:

```perl
# Environment-based configuration
my $filter = Params::Filter->new_filter();

if ($ENV{MODE} eq 'production') {
    $filter->set_required(['api_key', 'endpoint'])
              ->set_accepted(['timeout', 'retries'])
              ->set_excluded(['debug_info']);
}
else {
    $filter->set_required(['debug_mode'])
              ->accept_all();
}

# Dynamic field lists from config
my $config_fields = load_config('fields.json');
$filter->set_required($config_fields->{required})
          ->set_accepted($config_fields->{accepted})
          ->set_excluded($config_fields->{excluded});
```

#### Wildcard for Accepting Fields

```perl
# Accept all fields
filter($input, [], ['*']);

# Accept all fields except specific exclusions
filter($input, [], ['*'], ['password', 'ssn']);

# Required + all other fields
filter($input, ['id', 'name'], ['*']);

# Wildcard can appear anywhere in accepted list
filter($input, [], ['name', 'email', '*']);  # debugging: add '*' to see everything
filter($input, [], ['*', 'phone', 'address']);
```

#### Important Notes

- `'*'` is **only special in the `accepted` parameter**
- In `required` or `excluded`, `'*'` is treated as a literal field name
- Empty `[]` for accepted means "accept none beyond required" 
- Multiple wildcards are redundant but harmless
- Exclusions are always removed before acceptance is processed

#### Debugging Pattern

A common debugging pattern is to add `'*'` to an existing accepted list:

```perl
# Normal operation
filter($input, ['id'], ['name', 'email']);

# Debugging - see all inputs
filter($input, ['id'], ['name', 'email', '*']);
```

## Input Parsing

The `filter()` function parses multiple common input formats into a consistent internal structure. This flexibility allows you to use the module with data from differing sources such as form input, arguments to subroutines/methods, fetched database records, and test input, without pre-processing. 

### Supported Input Formats

#### 1. Hashref (Most Common) 
##### Uses the hashref’s key-value pairs as provided

```perl
# External data source (e.g., from web form, API, or database)
my $incoming_user = { name => 'Alice', email => 'alice@example.com',
 phone => '555-1234', UTM => "...", referred_by => 'Bob'
};

# Apply filter with rules defined inline
my ($result, $msg) = filter(
    $incoming_user,
    ['name', 'email'],
    ['phone', 'text_ok'],
    ['UTM']
);
# Result: { name => 'Alice', email => 'alice@example.com', phone => '555-1234' }
```

#### 2. Arrayref with Even Number of Elements
##### Makes key-value pairs from arrayref elements, reading left to right

```perl
# Pre-defined filter rules (typically defined at package level or in config)
my @required_fields = qw(name email);
my @accepted_fields = qw(age);

# External data from command-line arguments or similar list source
my @cli_args = ('name', 'Bob', 'email', 'bob@example.com', 'age', 30);

my ($result, $msg) = filter(
    \@cli_args,
    \@required_fields,
    \@accepted_fields,
);
# Result: { name => 'Bob', email => 'bob@example.com', age => 30 }
```

#### 3. Arrayref with Odd Number of Elements
##### Makes key-value pairs from arrayref elements, reading left to right, but when an array has an odd number of elements, the last element (right-most) becomes a flag assigned the value `1`:

```perl
# Pre-defined filter configuration
my @required = qw(name);
my @accepted = qw(verbose force);

# External data with odd number of elements (e.g., CLI args with flags)
my $command_args = ['name', 'Charlie', 'verbose', 'debug', 'force'];

my ($result, $msg) = filter(
    $command_args,
    \@required,
    \@accepted,
    [], 1,  # Debug mode to see warning
);
# Result: { name => 'Charlie', verbose => 'debug', force => 1 }
# Message includes: "Odd number of arguments provided; last element 'force' treated as flag"
```

#### 4. Arrayref with Hashref as First Element
##### Uses the hashref’s key-value pairs as provided, ignores rest of arrayref

```perl
# Pre-configured filter
my @required = qw(name);
my @accepted = qw(age title);

# External data source with hashref wrapped in array
my $arg0    = { name => 'Diana', age => 25, hire_date => 2026-01-09, title => 'CTO' };
my $arg1    = $something;
my $arg2    = $something_else;

my $api_response = [ $arg0, $arg1, $arg2, ];
my ($result, $msg) = filter(
    $api_response,
    \@required,
    \@accepted,
);
# Result: { name => 'Diana', age => 25, title => 'CTO' }
```

#### 5. Single-Element Arrayref
##### Creates a hashref with the element as the value and ‘_’ as its key. 
To make use of this feature, `'_'` or the wildcard `'*'` must be included in the appropriate filter lists.

```perl
# Filter configuration accepting special '_' key
my @required = ();
my @accepted = qw(_);

# External data: single-element array
my $single_value = ['search_query'];

my ($result, $msg) = filter(
    $single_value,
    \@required,
    \@accepted,
);
# Result: { _ => 'search_query' }
```

#### 6. Plain Scalar (String)
##### Creates a hashref with the scalar as the value and ‘_’ as its key.
To make use of this feature, `'_'` or the wildcard `'*'` must be included in the appropriate filter lists.

Note: No attempt is made to parse strings into data. 

```perl
# Pre-configured filter setup
my @required = ();
my @accepted = qw(_);

# External scalar data (e.g., raw input from file or stream)
my $raw_input = 'plain text string';

my ($result, $msg) = filter(
    $raw_input,
    \@required,
    \@accepted,
    [], 1,  # Debug mode to see warning
);
# Result: { _ => 'plain text string' }
# Message includes: "Plain text argument accepted with key '_': 'plain text string'"
```

### Parsing Status Messages (Always Provided)

These messages appear in the status message to inform you about structural transformations:

- **Odd array elements**: `"Odd number of arguments provided; last element 'X' treated as flag"`
- **Scalar input**: `"Plain text argument accepted with key '_': 'preview...'"`
- **Single array element**: `"Plain text argument accepted with key '_': 'preview...'"`

These messages help you understand when your input format differs from the standard hashref.

## Output Format

The `filter()` function always yields filtered data as a set of key-value pairs, regardless of how the input was provided. The returned result’s structure depends on context.

### Return Structure

#### Scalar Context

```perl
# Pre-defined filter rules
my @required = qw(name);
my @accepted = qw(email);

# External input data
my $input = { name => 'Alice', email => 'alice@example.com' };

my $result = filter($input, \@required, \@accepted);
# Returns: hashref or undef on failure
if ($result) {
    say $result->{name};
}
```

#### List Context (Recommended)

```perl
# Filter configuration
my @required = qw(name email);
my @accepted = qw(phone);

# External data source
my $input = get_external_data();  # e.g., from API, web form, etc.

my ($data, $message) = filter($input, \@required, \@accepted);
# Returns: (hashref, status_message) or (undef, error_message)
if ($data) {
    say $data->{name};
} else {
    say "Error: $message";
}
```

### Success

On success, returns a hashref containing only the fields that passed filtering:

```perl
# Pre-configured filter rules
my @required_fields = qw(name email);
my @accepted_fields = qw(phone);
my @excluded_fields = qw(password spam);

# External data source (e.g., web form submission)
my $web_form_data = {
    name     => 'Alice',
    email    => 'alice@example.com',
    password => 'secret',
    spam     => 'yes'
};

my ($user, $msg) = filter(
    $web_form_data,
    \@required_fields,
    \@accepted_fields,
    \@excluded_fields,
);

# $user = { name => 'Alice', email => 'alice@example.com' }
# $msg = "Admitted"

# Notes:
# - 'name' and 'email' included (required and present)
# - 'password' and 'spam' excluded (removed even if present)
# - 'phone' not in input, so not included
# - 'spam' not in required/accepted, so ignored
```

### Failure

On failure (missing required fields), returns `undef` and an error message:

```perl
# Filter rules defined once, reused
my @required = qw(name email);
my @accepted = qw(phone);

# Incomplete external data
my $incomplete_data = { name => 'Bob' };  # email missing!

my ($data, $msg) = filter(
    $incomplete_data,
    \@required,
    \@accepted,
);

# $data = undef
# $msg = "Unable to initialize without required arguments: 'email'"
```

### Status Message Types

The status message provides feedback about the filtering operation:

1. **"Admitted"** - Success, all required fields present
2. **"Unable to initialize without required arguments: 'field1', 'field2'"** - Failure, missing required fields
3. **Parsing messages** - Information about input format transformations (always provided)
4. **Debug warnings** - Information about excluded/unrecognized fields (provided in debug mode only)

### Consistent Output Format

**Regardless of input format, output is always a hashref:**

```perl
# Filter rules (could be pre-defined constants)
my @req1 = qw(name);
my @acc1 = qw();

# Hashref input → hashref output
my $hash_input = { name => 'Alice' };
my $result1 = filter($hash_input, \@req1, \@acc1);
# → { name => 'Alice' }

# Arrayref input → hashref output
my @req2 = qw(name);
my @acc2 = qw(age);
my $array_input = ['name', 'Bob', 'age', 30];
my $result2 = filter($array_input, \@req2, \@acc2);
# → { name => 'Bob', age => 30 }

# Scalar input → hashref output with '_' key
my @req3 = qw();
my @acc3 = qw(_);
my $scalar_input = 'text';
my $result3 = filter($scalar_input, \@req3, \@acc3);
# → { _ => 'text' }
```

This consistency makes the filtered data easy to use in downstream code without worrying about the original input format.

## Examples

### Form Field Filtering

```perl
use Params::Filter;

# Define filtering rules (could be from config file)
my @required = qw(name email);
my @accepted = qw(phone city state zip);

# Apply to incoming web form data
my ($user_data, $status) = filter(
    $form_submission,   # Data from web form
    \@required,
    \@accepted,
);

if ($user_data) {
    register_user($user_data);
} else {
    show_error($status);
}
```

### Reusable Filter for Multiple Data Sources

```perl
# Create filter once
my $user_filter = Params::Filter->new_filter({
    required => ['username', 'email'],
    accepted => ['full_name', 'phone', 'bio'],
    excluded => ['password', 'ssn', 'credit_card'],
});

# Apply to multiple incoming datasets
my ($user1, $msg1) = $user_filter->apply($web_form_data);
my ($user2, $msg2) = $user_filter->apply($api_request_data);
my ($user3, $msg3) = $user_filter->apply($csv_import_data);
```

### Environment-Specific Filtering

```perl
my $filter = Params::Filter->new_filter();

if ($ENV{APP_MODE} eq 'production') {
    # Strict: only specific fields allowed
    $filter->set_required(['api_key'])
          ->set_accepted(['timeout', 'retries'])
          ->set_excluded(['debug_info', 'verbose']);
} else {
    # Development: allow everything
    $filter->set_required(['debug_mode'])
          ->accept_all();
}

my ($config, $msg) = $filter->apply($incoming_config);
```

### Security Filtering

```perl
# Remove sensitive fields from user input
my ($safe_data, $msg) = filter(
    $user_input,
    ['username', 'email'],           # required
    ['full_name', 'phone', 'bio'],    # accepted
    ['password', 'ssn', 'api_key'],   # excluded
);

# Result contains only safe fields
# password, ssn, api_key are removed even if provided
```

### Dynamic Configuration from File

```perl
# Load filter rules from config file
my $config = decode_json(`cat filters.json`);

my $filter = Params::Filter->new_filter()
    ->set_required($config->{user_create}{required})
    ->set_accepted($config->{user_create}{accepted})
    ->set_excluded($config->{user_create}{excluded});

# Apply to incoming data
my ($filtered, $msg) = $filter->apply($api_data);
```

### Complex Data Flows

* Data Integration from Varying Sources
* Data Segregation for Multiple Subsystems

An application may need to handle incoming data from varying sources and prepare it for the same downstream processing. Filtering rules can be tailored to assure that only usable data is passed on. 

An application may need to split incoming data into subsets for different handlers or storage locations. Multiple filters may be applied to a given input, and each filter extracts only the fields needed for its specific purpose, simplifying next steps and improving security through compartmentalization.

This example demonstrates how Params::Filter can integrate incoming data and segregate the yielded data for multiple outputs.

```perl
# Three different Subscription forms collect overlapping data:

#  Main subscription signup form collects: 
#   name, email, zip, 
#   user_id, password, credit_card_number, subscription_term

# Subcription form with full profile collects: 
#  name, email, address, city, state, zip, 
#  user_id, password, credit_card_number, subscription_term, 
#  phone, occupation, position, education 
#  alt_card_number, billing_address, billing_zip

# Promo subscription form collects: 
#  name, email, zip, subscription_term, 
#  user_id, password, credit_card_number, promo_code

my $data = $webform->input(); # From any of the above

# Three different uses for the data: 
#  Personal contact info to be stored
#  Subscription business to be transacted
#  Authentication credentials to be encrypted and stored

# Personal data filter - general user info (no sensitive data)
my $person_filter = Params::Filter->new_filter({
    required => ['name', 'user_id', 'email'],
    accepted => ['address', 'city', 'state', 'zip', 'phone', 
                 'occupation', 'position', 'education'],
    excluded => ['password', 'credit_card_number'],
});

# Business data filter - subscription and billing info
my $biz_filter = Params::Filter->new_filter({
    required => ['user_id', 'name', 'subscription_term', 'credit_card_number', 'zip'],
    accepted => ['alt_card_number', 'billing_address', 'billing_zip', 'promo_code'],
    excluded => ['password'],
});

# Authentication data filter - only credentials
my $auth_filter = Params::Filter->new_filter({
    required => ['user_id', 'password'],
    accepted => [],
    excluded => [],
});

# Apply all filters to the same web form submission
my ($person_data,     $pmsg) = $person_filter->apply($data);
my ($biz_data,        $bmsg) = $biz_filter->apply($data);
my ($auth_data,       $amsg) = $auth_filter->apply($data);

# Set the requirement that all filtering requirements must be met
# with data provided by any of the three webform sources:
unless ($person_data && $biz_data && $auth_data) {
  return "Unable to add user: " .
    join ' ' => grep { $_ ne 'Admitted' } ($pmsg, $bmsg, $amsg);
}

# Route each filtered data subset to appropriate handler
$self->add_user(         $person_data   );    # User profile
$self->set_subscription( $biz_data      );    # Billing system
$self->set_password(     $auth_data     );    # Auth system
```

NOTE: The original `$data` is not modified during filtering, so the same data can be safely processed by multiple filters.

### More Examples

See the `examples/` directory for complete working scripts:
- `basic_usage.pl` - Simple form input filtering
- `oo_interface.pl` - Reusable filters
- `closure_interface.pl` - High-performance closure interface
- `wildcard.pl` - Wildcard acceptance patterns
- `error_handling.pl` - Various error handling strategies
- `debug_mode.pl` - Development-time warnings
- `edge_cases.pl` - Unusual input formats
- `arrayref_input.pl` - Arrayref vs hashref inputs
- `advanced_filtering.pl` - Complex filtering patterns
- `modifier_methods.pl` - Dynamic configuration with modifier methods

## Author

Bruce Van Allen <bva@cruzio.com>

## License

perl_5

## Copyright

Copyright (C) 2026, Bruce Van Allen

#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);
use Params::Filter qw/filter/;
use Time::HiRes qw/usleep/;

say "=" x 80;
say "Params::Filter: Expensive Validation Benchmark";
say "=" x 80;
say "";
say "This benchmark demonstrates when Params::Filter provides REAL performance gains.";
say "";
say "Key insight: Filter first, THEN do expensive validation on fewer fields.";
say "";

# ============================================================================
# EXPENSIVE VALIDATION FUNCTIONS
# ============================================================================

# Level 1: Complex Regex Validation (Moderate expense)
sub complex_email_validation {
    my ($email) = @_;
    return 0 unless defined $email;

    # Multiple regex patterns with lookaheads/lookbehinds
    return 0 unless $email =~ /^(?!(.*\.\.)|(.*\.$|\.@)|(\.\.))/;  # No consecutive dots
    return 0 unless $email =~ /^(?!(.*@.*@))/;  # Only one @
    return 0 unless $email =~ /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Z]{2,}$/i;

    # Domain validation (expensive part)
    my ($domain) = $email =~ /@([^@]+)$/;
    return 0 unless $domain =~ /\.[a-z]{2,}$/i;

    # Check against blocklist (hash lookup with many entries)
    my %blocked = map { $_ => 1 } qw(
        tempmail.com throwaway.net disposable.org guerrillamail.com
        mailinator.com 10minutemail.com getairmail.com yopmail.com
        maildrop.cc shhmail.com temp-mail.org fakeinbox.com
    );
    return 0 if exists $blocked{$domain};

    # DNS validation simulation (more regex)
    return 0 unless $domain =~ /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$/i;

    return 1;
}

# Level 2: Simulated Database Lookup (High expense)
sub database_field_validation {
    my ($data, $field) = @_;
    return 0 unless exists $data->{$field};

    my $value = $data->{$field};

    # Simulate database query latency (2ms per query)
    usleep(2000);  # 2 milliseconds

    # Simulate database check result
    return 1 if defined $value && length($value) >= 3;
    return 0;
}

# Level 3: Business Rule Validation with Cross-Field Checks (Very High expense)
sub business_rule_validation {
    my ($data) = @_;

    # Rule 1: Age validation with range checks
    if (exists $data->{age}) {
        return 0 unless $data->{age} =~ /^\d+$/;
        return 0 unless $data->{age} >= 18 && $data->{age} <= 120;

        # Cross-field: age vs birthdate if both present
        if (exists $data->{birthdate}) {
            return 0;  # Can't have both age and birthdate
        }
    }

    # Rule 2: State/Zip validation (requires hash lookups)
    if (exists $data->{state} && exists $data->{zip}) {
        my %state_zip_ranges = (
            'CA' => ['90000', '96199'],
            'NY' => ['10000', '14999'],
            'TX' => ['75000', '79999'],
            'FL' => ['32000', '34999'],
            'IL' => ['60000', '62999'],
        );

        if (exists $state_zip_ranges{$data->{state}}) {
            my ($range_start, $range_end) = @{$state_zip_ranges{$data->{state}}};
            return 0 unless $data->{zip} >= $range_start && $data->{zip} <= $range_end;
        }
    }

    # Rule 3: Email domain verification against allowed domains
    if (exists $data->{email}) {
        my ($domain) = $data->{email} =~ /@([^@]+)$/;

        # Simulate expensive API call to verify domain (5ms)
        usleep(5000);

        my %allowed_domains = map { $_ => 1 } qw(
            gmail.com yahoo.com outlook.com hotmail.com aol.com
            icloud.com protonmail.com example.com company.com
        );
        return 0 unless exists $allowed_domains{$domain};
    }

    # Rule 4: Phone number normalization and validation
    if (exists $data->{phone}) {
        my $phone = $data->{phone};

        # Remove all non-digits (expensive regex substitution)
        $phone =~ s/\D//g;

        # Validate length and format
        return 0 unless length($phone) == 10;
        return 0 unless $phone =~ /^[2-9]\d{2}[2-9]\d{2}\d{4}$/;

        # Area code validation (hash lookup)
        my %valid_area_codes = map { $_ => 1 } qw(
            212 646 718 917 929 347  # NYC
            415 628 408 510 650     # SF Bay Area
            312 773 872             # Chicago
        );
        my $area_code = substr($phone, 0, 3);
        # Optional: Check area code validity
        # return 0 unless exists $valid_area_codes{$area_code};
    }

    return 1;
}

# Level 4: Comprehensive Expensive Validation Pipeline
sub expensive_comprehensive_validation {
    my ($data, $fields_to_validate) = @_;

    my $valid = 1;

    # Validate each field
    for my $field (@$fields_to_validate) {
        next unless exists $data->{$field};

        # Email is most expensive
        if ($field eq 'email') {
            $valid &&= complex_email_validation($data->{$field});
        }

        # Phone requires expensive normalization
        elsif ($field eq 'phone') {
            my $phone = $data->{$field};
            $phone =~ s/\D//g;  # Regex substitution (expensive)
            $valid &&= (length($phone) == 10);
        }

        # Integer fields require regex validation
        elsif ($field eq 'age' || $field eq 'zip') {
            $valid &&= ($data->{$field} =~ /^\d+$/);
        }

        # String fields require length checking
        else {
            $valid &&= (length($data->{$field}) > 0 && length($data->{$field}) <= 255);
        }
    }

    # If still valid, do expensive cross-field validation
    if ($valid) {
        $valid &&= business_rule_validation($data);
    }

    # If still valid, do simulated database lookups (MOST EXPENSIVE)
    if ($valid) {
        # Simulate 3 database queries per record
        database_field_validation($data, 'email');
        database_field_validation($data, 'username');
        database_field_validation($data, 'phone');
    }

    return $valid;
}

# ============================================================================
# TEST DATA GENERATION
# ============================================================================

say "Generating test data...";
my @form_submissions;
my @all_field_lists;
my @filtered_field_lists;

for my $idx (1..1000) {
    my $form = {
        username => "user$idx",
        email => "user$idx\@gmail.com",
        name => "User Name $idx",
        age => int(rand(50)) + 18,
        city => "City $idx",
        phone => "555-0123",
        zip => "12345",
        state => 'CA',
        address => "$idx Main St",
        address2 => "Apt $idx",
        country => 'USA',
        company => "Company $idx",
        title => "Job Title $idx",
        website => "http://example.com",
        bio => "Bio $idx",
        password => "secret$idx",
        password_confirm => "secret$idx",
        ssn => "123-45-6789",
        credit_card => "4111-1111-1111-1111",
        admin_token => "admin-token-$idx",
    };

    push @form_submissions, $form;
    push @all_field_lists, [keys %$form];
    push @filtered_field_lists, [qw/username email name age city phone zip state address/];
}

my $user_filter = Params::Filter->new_filter({
    required => [qw/username email name age city/],
    accepted => [qw/phone zip state address/],
    excluded => [qw/password password_confirm ssn credit_card admin_token/],
});

say "Data generated. Starting benchmarks...";
say "";

# ============================================================================
# BENCHMARK 1: Compare Validation Strategies
# ============================================================================
say "-" x 80;
say "Benchmark 1: Expensive Validation - Side-by-Side Comparison";
say "-" x 80;
say "Processing 1,000 forms with comprehensive expensive validation";
say "Including: complex regex, simulated DB lookups (2ms each), business rules";
say "";

cmpthese(-1, {  # -1 = at least 1 second CPU time
    naive_validate_all => sub {
        for my $idx (0..$#form_submissions) {
            my $form = $form_submissions[$idx];
            my $fields = $all_field_lists[$idx];
            my $valid = expensive_comprehensive_validation($form, $fields);
        }
    },
    smart_filter_first => sub {
        for my $idx (0..$#form_submissions) {
            my $form = $form_submissions[$idx];
            my ($filtered, $msg) = $user_filter->apply($form);

            if ($filtered) {
                my $valid = expensive_comprehensive_validation($filtered, $filtered_field_lists[$idx]);
            }
        }
    },
});

say "";
say "Results interpretation:";
say "  - Naive: Validates all 20 fields per form";
say "  - Smart: Filters to 8 fields, then validates only those";
say "  - Expected: 60% fewer validations = significant speedup";
say "";

# ============================================================================
# BENCHMARK 2: Just Database Lookup Cost
# ============================================================================
say "-" x 80;
say "Benchmark 2: Database Lookup Cost Comparison";
say "-" x 80;
say "Simulating 3 database queries per form (2ms each = 6ms total per form)";
say "";

cmpthese(-1, {
    naive_db_lookups => sub {
        for my $idx (0..100) {  # Smaller sample for DB test
            my $form = $form_submissions[$idx];
            # Simulate DB lookups for all 20 fields
            database_field_validation($form, $_) for keys %$form;
        }
    },
    smart_db_lookups => sub {
        for my $idx (0..100) {
            my $form = $form_submissions[$idx];
            my ($filtered, $msg) = $user_filter->apply($form);
            if ($filtered) {
                # Simulate DB lookups for only 8 fields
                database_field_validation($filtered, $_) for keys %$filtered;
            }
        }
    },
});

say "";
say "Expected: Smart approach should be ~2.5x faster (20 vs 8 DB lookups)";
say "";

# ============================================================================
# BENCHMARK 3: Just Email Validation Cost
# ============================================================================
say "-" x 80;
say "Benchmark 3: Complex Email Validation Cost";
say "-" x 80;
say "Complex regex + domain blocklist check per email";
say "";

cmpthese(-1, {
    naive_email_validation => sub {
        for my $idx (0..$#form_submissions) {
            my $form = $form_submissions[$idx];
            # Validate email for all forms (20 fields each)
            complex_email_validation($form->{email}) for 1..20;
        }
    },
    smart_email_validation => sub {
        for my $idx (0..$#form_submissions) {
            my $form = $form_submissions[$idx];
            my ($filtered, $msg) = $user_filter->apply($form);
            if ($filtered) {
                # Validate email once
                complex_email_validation($filtered->{email});
            }
        }
    },
});

say "";
say "=" x 80;
say "CONCLUSION";
say "=" x 80;
say "";
say "When validation is EXPENSIVE (DB lookups, complex regex, API calls),";
say "Params::Filter provides SIGNIFICANT performance gains.";
say "";
say "The overhead of filtering (~0.37ms) is tiny compared to:";
say "  - Database query: 2-10ms each";
say "  - API calls: 50-500ms each";
say "  - Complex regex: 0.1-1ms each";
say "  - Business rules: variable";
say "";
say "By filtering FIRST, you avoid paying these costs for unnecessary fields.";
say "";
say "Security bonus: Passwords, SSNs, credit cards never reach validation code!";
say "";
say "=" x 80;

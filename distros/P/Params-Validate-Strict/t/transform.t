#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 40;

use Params::Validate::Strict qw(validate_strict);

# Helper functions for transformations
sub trim {
	my $str = shift;
	$str =~ s/^\s+|\s+$//g;
	return $str;
}

# Basic string transformation - lowercase and trim
{
    my $schema = {
        username => {
            type => 'string',
            transform => sub { lc(trim($_[0])) },
            matches => qr/^[a-z0-9_]+$/
        }
    };

    # Input with spaces and capitals
    my $result = validate_strict(
        schema => $schema,
        input => { username => '  JohnDoe123  ' }
    );
    ok(defined($result), 'Transformed username passes validation');
    is($result->{username}, 'johndoe123', 'Username lowercased and trimmed');

    # Input that would fail without transform
    $result = validate_strict(
        schema => $schema,
        input => { username => 'ADMIN_USER' }
    );
    is($result->{username}, 'admin_user', 'Uppercase transformed to lowercase');
}

# Array transformation - lowercase all elements
{
    my $schema = {
        tags => {
            type => 'arrayref',
            transform => sub { [map { lc($_) } @{$_[0]}] },
            element_type => 'string'
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { tags => ['Perl', 'VALIDATION', 'Testing'] }
    );
    ok(defined($result), 'Transformed array passes');
    is_deeply($result->{tags}, ['perl', 'validation', 'testing'], 'All tags lowercased');
}

# Numeric transformation - round to integer
{
    my $schema = {
        quantity => {
            type => 'integer',
            transform => sub { int($_[0] + 0.5) },  # Round to nearest
            min => 1,
            max => 100
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { quantity => 5.7 }
    );
    ok(defined($result), 'Rounded number passes');
    is($result->{quantity}, 6, 'Number rounded up correctly');

    $result = validate_strict(
        schema => $schema,
        input => { quantity => 5.2 }
    );
    is($result->{quantity}, 5, 'Number rounded down correctly');
}

# Email normalization - lowercase and trim
{
    my $schema = {
        email => {
            type => 'string',
            transform => sub { lc(trim($_[0])) },
            matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { email => '  User@EXAMPLE.COM  ' }
    );
    ok(defined($result), 'Transformed email passes');
    is($result->{email}, 'user@example.com', 'Email normalized correctly');
}

# String sanitization - remove special characters
{
    my $schema = {
        slug => {
            type => 'string',
            transform => sub {
                my $str = lc(trim($_[0]));
                $str =~ s/[^\w\s-]//g;  # Remove special chars
                $str =~ s/\s+/-/g;      # Replace spaces with hyphens
                return $str;
            },
            matches => qr/^[a-z0-9-]+$/
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { slug => 'Hello World! @2024' }
    );
    ok(defined($result), 'Sanitized slug passes');
    is($result->{slug}, 'hello-world-2024', 'Slug sanitized correctly');
}

# Phone number formatting - remove non-digits
{
    my $schema = {
        phone => {
            type => 'string',
            transform => sub {
                my $str = $_[0];
                $str =~ s/\D//g;  # Remove all non-digits
                return $str;
            },
            matches => qr/^\d{10}$/
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { phone => '(555) 123-4567' }
    );
    ok(defined($result), 'Transformed phone passes');
    is($result->{phone}, '5551234567', 'Phone formatted correctly');
}

# Multiple transformations on different fields
{
    my $schema = {
        username => {
            type => 'string',
            transform => sub { lc(trim($_[0])) }
        },
        tags => {
            type => 'arrayref',
            transform => sub { [map { lc(trim($_)) } @{$_[0]}] }
        },
        score => {
            type => 'integer',
            transform => sub { int($_[0]) }
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => {
            username => '  ADMIN  ',
            tags => ['  Tag1  ', 'TAG2', '  tag3  '],
            score => 95.7
        }
    );
    ok(defined($result), 'Multiple transformations pass');
    is($result->{username}, 'admin', 'Username transformed');
    is_deeply($result->{tags}, ['tag1', 'tag2', 'tag3'], 'Tags transformed');
    is($result->{score}, 95, 'Score transformed');
}

# Transform with validation that depends on transform
{
    my $schema = {
        code => {
            type => 'string',
            transform => sub { uc(trim($_[0])) },  # Must be uppercase
            matches => qr/^[A-Z]{3,6}$/            # Validates after transform
        }
    };

    # Lowercase input gets transformed and passes
    my $result = validate_strict(
        schema => $schema,
        input => { code => 'abc' }
    );
    ok(defined($result), 'Transformed code passes validation');
    is($result->{code}, 'ABC', 'Code uppercased');

    # Still fails if too long after transform
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { code => 'toolong' }
        );
    } qr/must match pattern/, 'Transform doesnt bypass validation';
}

# Array element transformation with deduplication
{
    my $schema = {
        keywords => {
            type => 'arrayref',
            transform => sub {
                my @arr = map { lc(trim($_)) } @{$_[0]};
                my %seen;
                return [grep { !$seen{$_}++ } @arr];  # Remove duplicates
            },
            element_type => 'string',
            min => 1
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { keywords => ['Perl', 'perl', '  PERL  ', 'Testing'] }
    );
    ok(defined($result), 'Deduplicated array passes');
    is_deeply($result->{keywords}, ['perl', 'testing'], 'Duplicates removed, normalized');
    is(scalar(@{$result->{keywords}}), 2, 'Correct count after dedup');
}

# Nested object transformation
{
    my $schema = {
        user => {
            type => 'hashref',
            schema => {
                name => {
                    type => 'string',
                    transform => sub { trim($_[0]) }
                },
                email => {
                    type => 'string',
                    transform => sub { lc(trim($_[0])) }
                }
            }
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => {
            user => {
                name => '  John Doe  ',
                email => '  JOHN@EXAMPLE.COM  '
            }
        }
    );
    ok(defined($result), 'Nested transformations pass');
    is($result->{user}{name}, 'John Doe', 'Nested name trimmed');
    is($result->{user}{email}, 'john@example.com', 'Nested email normalized');
}

# Boolean transformation from various formats
{
    my $schema = {
        enabled => {
            type => 'boolean',
            transform => sub {
                my $val = lc(trim($_[0]));
                return 1 if $val =~ /^(true|yes|on|1)$/;
                return 0 if $val =~ /^(false|no|off|0)$/;
                return $_[0];  # Return original if not recognized
            }
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { enabled => '  YES  ' }
    );
    ok(defined($result), 'Boolean transformation passes');
    is($result->{enabled}, 1, 'YES transformed to 1');

    $result = validate_strict(
        schema => $schema,
        input => { enabled => 'false' }
    );
    is($result->{enabled}, 0, 'false transformed to 0');
}

# Transform with custom types
{
    my $custom_types = {
        email => {
            type => 'string',
            transform => sub { lc(trim($_[0])) },
            matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
        }
    };

    my $schema = {
        primary_email => { type => 'email' },
        backup_email => { type => 'email', optional => 1 }
    };

    my $result = validate_strict(
        schema => $schema,
        input => {
            primary_email => '  USER@EXAMPLE.COM  ',
            backup_email => '  BACKUP@TEST.COM  '
        },
        custom_types => $custom_types
    );
    ok(defined($result), 'Custom type with transform passes');
    is($result->{primary_email}, 'user@example.com', 'Primary email transformed');
    is($result->{backup_email}, 'backup@test.com', 'Backup email transformed');
}

# Transform that prevents validation error
{
    my $schema = {
        age => {
            type => 'integer',
            transform => sub {
                my $val = $_[0];
                $val =~ s/[^\d]//g;  # Remove non-digits
                return $val || 0;
            },
            min => 0,
            max => 150
        }
    };

    # Would fail without transform
    my $result = validate_strict(
        schema => $schema,
        input => { age => '30 years old' }
    );
    ok(defined($result), 'Transform extracts valid value');
    is($result->{age}, 30, 'Age extracted from string');
}

# Optional field with transform
{
    my $schema = {
        nickname => {
            type => 'string',
            optional => 1,
            transform => sub { lc(trim($_[0])) }
        }
    };

    # Optional field provided
    my $result = validate_strict(
        schema => $schema,
        input => { nickname => '  JOHNNY  ' }
    );
    ok(defined($result), 'Optional field with transform passes');
    is($result->{nickname}, 'johnny', 'Optional field transformed');

    # Optional field omitted
    $result = validate_strict(
        schema => $schema,
        input => {}
    );
    ok(defined($result), 'Optional field can be omitted');
    ok(!exists($result->{nickname}), 'Omitted field not in result');
}

# Not a code reference
{
	my $schema = {
		username => {
			type => 'string',
			transform => 'foo',
		}
	};

	throws_ok {
		my $result = validate_strict(
			schema => $schema,
			input => { username => 'Vickie' }
		);
	} qr/must be a code ref/, "Errors if transform isn't a code ref"
}
done_testing();

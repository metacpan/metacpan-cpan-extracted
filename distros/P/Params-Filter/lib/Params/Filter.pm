package Params::Filter;
use v5.36;
our $VERSION = '0.007';

=head1 NAME

Params::Filter - Fast field filtering for parameter construction

=head1 SYNOPSIS

    use Params::Filter	qw/filter/;    # import filter() subroutine

    # Define filter rules
    my @required_fields = qw(name email);
    my @accepted_fields = qw(phone city state zip);
    my @excluded_fields = qw(ssn password);

    # Functional interface
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

    # Object-oriented interface
    my $user_filter = Params::Filter->new_filter({
        required => ['username', 'email'],
        accepted => ['first_name', 'last_name', 'phone', 'bio'],
        excluded => ['password', 'ssn', 'credit_card'],
    });

    # Apply same filter to multiple incoming datasets
    my ($user1, $msg1) = $user_filter->apply($web_form_data);
    my ($user2, $msg2) = $user_filter->apply($api_request_data);
    my ($user3, $msg3) = $user_filter->apply($db_record_data);

=head1 DESCRIPTION

C<Params::Filter> provides fast, lightweight parameter filtering that
checks only for the presence or absence of specified fields. It does B<NOT>
validate values - no type checking, truthiness testing, or lookups.

This module separates field filtering from value validation:

=over 4

=item * **Field filtering** (this module) - Check which fields are present/absent

=item * **Value validation** (later step) - Check if field values are correct

=back

This approach handles common parameter issues:

=over 4

=item * Subroutine signatures can become unwieldy with many parameters

=item * Ad-hoc argument checking is error-prone

=item * Validation may not catch missing inputs quickly enough

=item * Many fields to check multiplies validation time

=back

=head2 When to Use This Module

This module is useful when you have:

=over 4

=item * Known parameters for downstream input or processes (API calls, method/subroutine arguments, database operations)

=over 8

=item * Fields that must be provided for success downstream ("required")

=item * Fields useful downstream if provided ("accepted")

=item * Fields to remove before further processing ("excluded")

=back

=item * Incoming data from external sources (web forms, APIs, databases, user input)

=item * No guarantee that incoming data is consistent or complete

=item * Multiple data instances to process with the same rules

=item * Multiple uses tapping incoming data

=item * A distinction between missing and "false" data

=back

=head2 When NOT to Use This Module

If you're constructing both the filter rules B<and> the data structure
at the same point in your code, you probably don't need this module.
The module's expected use is to apply pre-defined rules to data that
may be inconsistent or incomplete for its intended use.
If there isn't repetition or an unknown/unreliable data structure, this might be overkill.

=cut

=head2 This Module Does NOT Do Fancy Stuff

As much as this module attempts to be versatile in usage, there are some B<VERY HANDY AFFORDANCES IT DOES NOT PROVIDE:>

=over 4

=item * No regex field name matching for designating fields to require, accept, or exclude

=item * No conditional field designations I<within> a filter:

    C<if 'mailing_address' require 'postal_code'>   # No way a filter can do this

=item * No coderefs or callbacks for use when filtering

=item * No substitutions or changes to field names

=item * No built-in filter lists except null C<[]> = none

=item * No fields ADDED to yielded data, EXCEPT:

=over 8

=item * If the provided data resolves to a list or array with an odd number of elements, the LAST element is treated as a flag, set to the value 1

=item * If the provided data resolves to a single non-reference scalar (probably a text string) the data is stored as a hashref value with the key C<'_'>, and returned if C<'_'> is included in the accepted list or the list is set to C<['*']> (accept all)

=back

=back

=cut

use Exporter;
our @ISA		= qw{ Exporter  };
our @EXPORT		= qw{  };
our @EXPORT_OK	= qw{ filter };

sub new_filter {
	my ($class,$args) = @_;
	$args = {} unless ($args and ref($args) =~ /hash/i);
	my $self			= {
		required	=> $args->{required} || [],
		accepted	=> $args->{accepted} || [],
		excluded	=> $args->{excluded} || [],
		debug		=> $args->{DEBUG} || $args->{debug} || 0,
	};
	bless $self, __PACKAGE__;
	return $self;
}

=head1 OBJECT-ORIENTED INTERFACE

=head2 new_filter

    my $filter = Params::Filter->new_filter({
        required => ['field1', 'field2'],
        accepted => ['field3', 'field4', 'field5'],
        excluded => ['forbidden_field'],
        DEBUG    => 1,              # Optional debug mode
    });

    # Empty constructor - rejects all fields by default
    my $strict_filter = Params::Filter->new_filter();

Creates a reusable filter object with predefined field rules. The filter
can then be applied to multiple datasets using the L</apply> method.

=head3 Parameters

=over 4

=item * C<required> - Arrayref of names of required fields (default: [])

=item * C<accepted> - Arrayref of names of optional fields (default: [])

=item * C<excluded> - Arrayref of names of fields to always remove (default: [])

=item * C<DEBUG> - Boolean to enable debug warnings (default: 0)

=back

=head3 Returns

A C<Params::Filter> object

=head3 Example

    # Create filter for user registration data
    my $user_filter = Params::Filter->new_filter({
        required => ['username', 'email'],
        accepted => ['first_name', 'last_name', 'phone', 'bio'],
        excluded => ['password', 'ssn', 'credit_card'],
    });

    # Apply to multiple incoming datasets
    my ($user1, $msg1) = $user_filter->apply($web_form_data);
    my ($user2, $msg2) = $user_filter->apply($api_request_data);

=head2 apply

    my ($filtered, $status) = $filter->apply($input_data);

Applies the filter's predefined rules to input data. This is the OO
equivalent of the L</filter> function.

=head3 Parameters

=over 4

=item * C<$input_data> - Hashref, arrayref, or scalar to filter

=back

=head3 Returns

In list context: C<(hashref, status_message)> or C<(undef, error_message)>

In scalar context: Hashref with filtered parameters, or C<undef> on failure

=head3 Example

    my $filter = Params::Filter->new_filter({
        required => ['id', 'type'],
        accepted => ['name', 'value'],
    });

    # Process multiple records from database
    for my $record (@db_records) {
        my ($filtered, $msg) = $filter->apply($record);
        if ($filtered) {
            process_record($filtered);
        } else {
            log_error("Record failed: $msg");
        }
    }

=cut

sub set_required {
	my ($self, @fields)	= @_;
	@fields 			= ref $fields[0] eq 'ARRAY' ? $fields[0]->@* : @fields;
	my @required		= grep { defined } @fields;
	$self->{required}	= @required ? [ @required ] : [];
	return $self;
}

sub set_accepted {
	my ($self, @fields)	= @_;
	@fields 			= ref $fields[0] eq 'ARRAY' ? $fields[0]->@* : @fields;
	my @accepted		= grep { defined } @fields;
	$self->{accepted}	= @accepted ? [ @accepted ] : [];
	return $self;
}

sub accept_all {
	my ($self)			= @_;
	$self->{accepted}	= ['*'];
	return $self;
}

sub accept_none {
	my ($self)			= @_;
	$self->{accepted}	= [];
	return $self;
}

sub set_excluded {
	my ($self, @fields)	= @_;
	@fields				= ref $fields[0] eq 'ARRAY' ? $fields[0]->@* : @fields;
	my @excluded		= grep { defined } @fields;
	$self->{excluded}	= @excluded ? [ @excluded ] : [];
	return $self;
}

sub apply {
	my ($self,$args) = @_;
	my $req		= $self->{required} || [];
	my $ok		= $self->{accepted} || [];
	my $no		= $self->{excluded} || [];
	my $db		= $self->{debug} || 0;
	my @result	= filter( $args, $req, $ok, $no, $db);
	return wantarray ? @result : $result[0];
}

=head1 MODIFIER METHODS

The OO interface provides methods to modify a filter's configuration after creation.

=head2 Modifier Methods for Dynamic Configuration

The OO interface provides methods to modify a filter's configuration after creation.

    # Start with an empty filter (rejects all by default)
    my $filter = Params::Filter->new_filter();

    # Configure it in steps as needed
    $filter->set_required(['id', 'name']);
    # later:
    $filter->set_accepted(['email', 'phone'])
    $filter->set_excluded(['password']);

=head3 Available Modifier Methods

=over 4

=item * **C<set_required(\@fields | @fields)>** - Set required fields (accepts arrayref or list)

=item * **C<set_accepted(\@fields | @fields)>** - Set accepted fields (accepts arrayref or list)

=item * **C<set_excluded(\@fields | @fields)>** - Set excluded fields (accepts arrayref or list)

=item * **C<accept_all()>** - Convenience method: sets accepted to C<['*']> (wildcard mode)

=item * **C<accept_none()>** - Convenience method: sets accepted to C<[]> (reject all extras)

=back

=head2 Important Behavior Notes

B<Empty Modifier Calls Set Empty Arrays:>

If no fields are provided to C<set_required()>, C<set_accepted()>, or C<set_excluded()>, the respective list is set to an empty array C<[]>:

    $filter->set_accepted();  # Sets accepted to `[]`
    # Result: Only required fields will be accepted (extras rejected)

B<Method Chaining:>

All modifier methods return C<$self> for chaining:

    $filter->set_required(['id'])
            ->set_accepted(['name'])
            ->accept_all();  # Overrides set_accepted

B<Mutability:>

A filter may call its modifier methods more than once, and the changes take effect immediately.

=head2 Meta-Programming Use Cases

These methods enable dynamic configuration for conditional scenarios:

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

=head1 FUNCTIONAL INTERFACE

=head2 filter

    my ($filtered, $status) = filter(
        $input_data,     # Hashref, arrayref, or scalar
        \@required,      # Arrayref of required field names
        \@accepted,      # Arrayref of optional field names (default: [])
        \@excluded,      # Arrayref of names of fields to remove (default: [])
        $debug_mode,     # Boolean: enable warnings (default: 0)
    );

    # Scalar context - returns filtered hashref or undef on failure
    my $result = filter($input, \@required, \@accepted);

Filters input data according to field specifications. Only checks for
presence/absence of fields, not field values.

=head3 Parameters

=over 4

=item * C<$input_data> - Input parameters (hashref, arrayref, or scalar)

=item * C<\@required> - Arrayref of names of fields that B<must> be present

=item * C<\@accepted> - Arrayref of optional names of fields to accept (default: [])

=item * C<\@excluded> - Arrayref of names of fields to remove even if accepted (default: [])

=item * C<$debug_mode> - Boolean to enable warnings (default: 0)

=back

=head3 Returns

In list context: C<(hashref, status_message)> or C<(undef, error_message)>

In scalar context: Hashref with filtered parameters, or C<undef> on failure

=head3 Example

    # Define filter rules (could be from config file)
    my @required = qw(username email);
    my @accepted = qw(full_name phone);
    my @excluded = qw(password ssn);

    # Apply to incoming data from web form
    my ($user_data, $msg) = filter(
        $form_submission,
        \@required,
        \@accepted,
        \@excluded,
    );

    if ($user_data) {
        create_user($user_data);
    } else {
        log_error($msg);
    }

=cut

sub filter ($args,$req,$ok=[],$no=[],$db=0) {
	my %args		= ();
	my @messages	= ();	# Parsing messages (always reported)
	my @warnings	= ();	# Debug warnings (only when $db is true)

	if (ref $args eq 'HASH') {
		%args	= $args->%*
	}
	elsif (ref $args eq 'ARRAY') {
		if (ref($args->[0]) eq 'HASH') {
			%args	= $args->[0]->%*;			# Ignore the rest
		}
		else {
			my @args	= $args->@*;
			if (@args == 1) {
				%args = ( '_' => $args[0] );	# make it a value with key '_'
				my $preview = length($args[0]) > 20
					? substr($args[0], 0, 20) . '...'
					: $args[0];
				push @messages => "Plain text argument accepted with key '_': '$preview'";
			}
			elsif ( @args % 2 ) {
				%args = (@args, 1);				# make last arg element a flag
				push @messages => "Odd number of arguments provided; " .
					"last element '$args[-1]' converted to flag with value 1";
			}
			else {
				%args = @args;					# turn array into hash pairs
			}
		}
	}
	elsif ( !ref $args ) {
		%args	= ( '_' => $args);				# make it a value with key '_'
		my $preview = length($args) > 20
			? substr($args, 0, 20) . '...'
			: $args;
		push @messages => "Plain text argument accepted with key '_': '$preview'";
	}

	my @required_flds	= $req->@*;
	unless ( keys %args ) {
		my $err = "Unable to initialize without required arguments: " .
			join ', ' => map { "'$_'" } @required_flds;
		return wantarray ? (undef, $err) : undef;
	}

	if ( scalar keys(%args) < @required_flds ) {
		my $err	= "Unable to initialize without all required arguments: " .
			join ', ' => map { "'$_'" } @required_flds;
		return wantarray ? (undef, $err) : undef;
	}

	# Now create the output hashref
	my $filtered	= {};

	# Check for each required field
	my @missing_required;
	my $used_keys	= 0;
	for my $fld (@required_flds) {
		if ( exists $args{$fld} ) {
			$filtered->{$fld} = delete $args{$fld};
			$used_keys++;
		}
		else {
			push @missing_required => $fld;
		}
	}
	# Return fast if all set
	# required fields assured and no other fields provided
	if ( keys(%args) == 0 ) {
		return wantarray ? ($filtered, "Admitted") : $filtered;
	}
	# required fields assured and no more fields allowed
	if ( scalar keys $filtered->%* == @required_flds and not $ok->@*) {
		return wantarray ? ($filtered, "Admitted") : $filtered;
	}
	# Can't continue
	if ( @missing_required ) {
		my $err = "Unable to initialize without required arguments: " .
			join ', ' => map { "'$_'" } @missing_required;
		return wantarray ? (undef, $err) : undef;
	}

	# Now remove any excluded fields
	my @excluded;
	for my $fld ($no->@*) {
		if ( exists $args{$fld} ) {
			delete $args{$fld};
			push @excluded => $fld;
		}
	}

	# Check if wildcard '*' appears in accepted list
	my $has_wildcard = grep { $_ eq '*' } $ok->@*;

	if ($has_wildcard) {
		# Wildcard present: accept all remaining fields
		for my $fld (keys %args) {
			$filtered->{$fld} = delete $args{$fld};
		}
	}
	else {
		# Track but don't include if not on @accepted list
		for my $fld ($ok->@*) {
			if ( exists $args{$fld} ) {
				$filtered->{$fld} = delete $args{$fld};
			}
		}
	}

	my @unrecognized	= keys %args;	# Everything left
	if ( $db and @unrecognized > 0 ) {
		push @warnings => "Ignoring unrecognized arguments: " .
			join ', ' => map { "'$_'" } @unrecognized;
	}
	if ( $db and @excluded > 0 ) {
		push @warnings => "Ignoring excluded arguments: " .
			join ', ' => map { "'$_'" } @excluded;
	}

	# Combine parsing messages (always) with debug warnings (if debug mode)
	my @all_msgs	= (@messages, @warnings);
	my $return_msg	= @all_msgs
		? join "\n" => @all_msgs
		: "Admitted";

	return wantarray ? ( $filtered, $return_msg ) : $filtered;
}

=head1 INPUT PARSING

The C<filter()> function parses multiple common input formats into a consistent internal structure. This flexibility allows you to use the module with data from differing sources such as form input, arguments to subroutines/methods, fetched database records, and test input, without pre-processing.

=head2 Supported Input Formats

=head3 1. Hashref (Most Common)

##### Uses the hashref's key-value pairs as provided

    # External data source (e.g., from web form, API, or database)
    my $incoming_user = { name => 'Alice', email => 'alice@example.com', phone => '555-1234' };

    # Apply filter with rules defined inline
    my ($result, $msg) = filter(
        $incoming_user,
        ['name', 'email'],
        ['phone'],
    );
    # Result: { name => 'Alice', email => 'alice@example.com', phone => '555-1234' }

=head3 2. Arrayref with Even Number of Elements

##### Makes key-value pairs from arrayref elements, reading left to right

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

=head3 3. Arrayref with Odd Number of Elements

##### Makes key-value pairs from arrayref elements, reading left to right, but when an array has an odd number of elements, the last element (right-most) becomes a flag assigned the value C<1>:

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

=head3 4. Arrayref with Hashref as First Element

##### Uses the hashref's key-value pairs as provided, ignores rest of arrayref

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

=head3 5. Single-Element Arrayref

##### Creates a hashref with the element as the value and '_' as its key.
To make use of this feature, C<'_'> or the wildcard C<'*'> must be included in the appropriate filter lists.

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

=head3 6. Plain Scalar (String)

##### Creates a hashref with the scalar as the value and '_' as its key.
To make use of this feature, C<'_'> or the wildcard C<'*'> must be included in the appropriate filter lists.

Note: No attempt is made to parse strings into data.

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

=head3 7. List Passed as Arrayref

##### Flattened key-value lists must be wrapped in an arrayref

    # Filter rules defined once, reused
    my @req_fields = qw(name email);
    my @acc_fields = qw(city);

    # External key-value list data must be wrapped in arrayref
    my ($result, $msg) = filter(
        [name => 'Eve', email => 'eve@example.com', city => 'Boston'],
        \@req_fields,
        \@acc_fields,
    );
    # Result: { name => 'Eve', email => 'eve@example.com', city => 'Boston' }

=head2 Special Parsing Keys

=head3 The C<'_'> Key

- Used for scalar input and single-element arrays
- Must be in accepted list or use wildcard C<['*']>
- Stores non-reference data that doesn't fit the hashref pattern

=head2 Parsing Status Messages (Always Provided)

These messages appear in the status message to inform you about structural transformations:

=over 4

=item * **Odd array elements**: C<"Odd number of arguments provided; last element 'X' treated as flag">

=item * **Scalar input**: C<"Plain text argument accepted with key '_': 'preview...'">

=item * **Single array element**: C<"Plain text argument accepted with key '_': 'preview...'">

=back

These messages help you understand when your input format differs from the standard hashref.

=head1 RETURN VALUES

Both L</filter> and L</apply> return data in a consistent format, regardless
of how the input was provided. The returned result's structure depends on context.

=head2 Return Structure

=head3 Scalar Context

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

=head3 List Context (Recommended)

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

=head2 Success

On success, returns a hashref containing only the fields that passed filtering:

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

=head2 Failure

On failure (missing required fields), returns C<undef> and an error message:

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

=head2 Status Message Types

The status message provides feedback about the filtering operation:

=over 4

=item * 1. **"Admitted"** - Success, all required fields present

=item * 2. **"Unable to initialize without required arguments: 'field1', 'field2'"** - Failure, missing required fields

=item * 3. **Parsing messages** - Information about input format transformations (always provided)

=item * 4. **Debug warnings** - Information about excluded/unrecognized fields (provided in debug mode only)

=back

=head2 Consistent Output Format

B<Regardless of input format, output is always a hashref:>

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

This consistency makes the filtered data easy to use in downstream code without worrying about the original input format.

=head1 FEATURES

=over 4

=item * **Dual interface** - Functional or OO usage

=item * **Fast-fail** - Returns immediately on missing required parameters

=item * **Fast-success** - Returns immediately if all required parameters are provided and no others are provided or will be accepted

=item * **Flexible input** - Accepts hashrefs, arrayrefs, or scalars

=item * **Wildcard support** - Use C<'*'> in accepted list to accept all fields

=item * **No value checking** - Only presence/absence of fields

=item * **Debug mode** - Optional warnings about unrecognized or excluded fields

=item * **Method chaining** - Modifier methods return C<$self>

=item * **Perl 5.36+** - Modern Perl with signatures and post-deref

=item * **No dependencies** - Only core Perl's L<Exporter>

=back

=head1 DEBUG MODE

Debug mode provides additional information about field filtering during development:

    my ($filtered, $msg) = filter(
        $input,
        ['name'],
        ['email'],
        ['password'],
        1,  # Enable debug mode
    );

Debug warnings (only shown when debug mode is enabled):

=over 4

=item * Excluded fields that were removed

=item * Unrecognized fields that were ignored

=back

Parsing messages (always shown, regardless of debug mode):

=over 4

=item * Plain text arguments accepted with key '_'

=item * Odd number of array elements converted to flags

=back

Parsing messages inform you about transformations the filter made to your input format.
These are always reported because they affect the structure of the returned data.
Debug warnings help you understand which fields were filtered out during development.

=head1 WILDCARD SUPPORT

=head2 Wildcard for Accepting Fields

    # Accept all fields
    filter($input, [], ['*']);

    # Accept all fields except specific exclusions
    filter($input, [], ['*'], ['password', 'ssn']);

    # Required + all other fields
    filter($input, ['id', 'name'], ['*']);

    # Wildcard can appear anywhere in accepted list
    filter($input, [], ['name', 'email', '*']);  # debugging: add '*' to see everything
    filter($input, [], ['*', 'phone', 'address']);

=head2 Important Notes

=over 4

=item * C<'*'> is B<only special in the C<accepted> parameter>

=item * In C<required> or C<excluded>, C<'*'> is treated as a literal field name

=item * Empty C<[]> for accepted means "accept none beyond required"

=item * Multiple wildcards are redundant but harmless

=item * Exclusions are always removed before acceptance is processed

=back

=head2 Debugging Pattern

A common debugging pattern is to add C<'*'> to an existing accepted list:

    # Normal operation
    filter($input, ['id'], ['name', 'email']);

    # Debugging - see all inputs
    filter($input, ['id'], ['name', 'email', '*']);


=head1 EXAMPLES

=head2 Form Field Filtering

    use Params::Filter	qw/filter/;    # import filter() subroutine

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

=head2 Reusable Filter for Multiple Data Sources

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

=head2 Environment-Specific Filtering

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

=head2 Security Filtering

    # Remove sensitive fields from user input
    my ($safe_data, $msg) = filter(
        $user_input,
        ['username', 'email'],           # required
        ['full_name', 'phone', 'bio'],    # accepted
        ['password', 'ssn', 'api_key'],   # excluded
    );

    # Result contains only safe fields
    # password, ssn, api_key are removed even if provided

=head2 Dynamic Configuration from File

    # Load filter rules from config file
    my $config = decode_json(`cat filters.json`);

    my $filter = Params::Filter->new_filter()
        ->set_required($config->{user_create}{required})
        ->set_accepted($config->{user_create}{accepted})
        ->set_excluded($config->{user_create}{excluded});

    # Apply to incoming data
    my ($filtered, $msg) = $filter->apply($api_data);

=head2 Data Segregation for Multiple Subsystems

B<Complex Data Flows>

An application may need to handle incoming data from varying sources and prepare it for the same downstream processing. Filtering rules can be tailored to assure that only usable data is passed on.

An application may need to split incoming data into subsets for different handlers or storage locations. Multiple filters may be applied to a given input, and each filter extracts only the fields needed for its specific purpose, simplifying next steps and improving security through compartmentalization.

This example demonstrates how Params::Filter can integrate incoming data and segregate the yielded data for multiple outputs.

    # Three different Subscription forms collect overlapping data:

    #  Main subscription signup form collects:
    #   name, email, zip,
    #   user_id, password, credit_card_number, subscription_term

    #  Subscription form with full profile collects:
    #  name, email, address, city, state, zip,
    #  user_id, password, credit_card_number, subscription_term,
    #  phone, occupation, position, education
    #  alt_card_number, billing_address, billing_zip

    #  Promo subscription form collects:
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

B<Note>: The original C<$data> is not modified during filtering, so the same data can be safely processed by multiple filters.

=head1 SEE ALSO

=over 4

=item * L<Params::Validate> - Full-featured parameter validation

=item * L<Data::Verifier> - Data structure validation

=item * L<JSON::Schema::Modern> - JSON Schema validation

=back

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
See L<perlartistic|https://dev.perl.org/licenses/artistic.html>.

=head1 COPYRIGHT

Copyright (C) 2026, Bruce Van Allen

=cut

1;

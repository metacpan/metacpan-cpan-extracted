package Net::Respite::Validate;

# Net::Respite::Validate - lighter weight port of CGI::Ex::Validate

use strict;
use warnings;
use Throw qw(throw);

sub new {
    my ($class, $args) = @_;
    bless $args || {}, $class;
}

sub validate {
    my ($self, $form, $val_hash) = (@_ == 3) ? @_ : (__PACKAGE__->new(), @_);
    throw "args must be a hashref", {ref => ref($form)} if ref $form ne 'HASH';
    my ($fields, $ARGS) = $self->get_ordered_fields($val_hash);
    return if ! @$fields;
    return if $ARGS->{'validate_if'} && ! $self->check_conditional($form, $ARGS->{'validate_if'});

    $self->{'was_checked'} = {};
    $self->{'was_valid'}   = {};
    $self->{'had_error'}   = {};
    my $found  = 1;
    my @errors;
    my $hold_error; # hold the error for a moment - to allow for an "OR" operation
    my %checked;
    foreach (my $i = 0; $i < @$fields; $i++) {
        my $ref = $fields->[$i];
        if (! ref($ref) && $ref eq 'OR') {
            $i++ if $found; # if found skip the OR altogether
            $found = 1; # reset
            next;
        }
        $found = 1;
        my $key = $ref->{'field'} || throw "Missing field key during normal validation";

        # allow for field names that contain regular expressions
        my @keys;
        if ($key =~ m/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/s) {
            my ($not, $pat, $opt) = ($1, $3, $4);
            $opt =~ tr/g//d;
            throw "The e option cannot be used on validation keys on field $key" if $opt =~ /e/;
            foreach my $_key (sort keys %$form) {
                next if ($not && $_key =~ m/(?$opt:$pat)/) || (! $not && $_key !~ m/(?$opt:$pat)/);
                push @keys, [$_key, [undef, $1, $2, $3, $4, $5]];
            }
        } else {
            @keys = ([$key]);
        }

        foreach my $r (@keys) {
            my ($field, $ifs_match) = @$r;
            if (! $checked{$field}++) {
                $self->{'was_checked'}->{$field} = 1;
                $self->{'was_valid'}->{$field} = 1;
                $self->{'had_error'}->{$field} = 0;
            }
            local $ref->{'was_validated'} = 1;
            my $err = $self->validate_buddy($form, $field, $ref, $ifs_match);
            if (!$ref->{'was_validated'}) {
                $self->{'was_valid'}->{$field} = 0;
            }

            # test the error - if errors occur allow for OR - if OR fails use errors from first fail
            if ($err) {
                $self->{'was_valid'}->{$field} = 0;
                $self->{'had_error'}->{$field} = 0;
                if ($i < $#$fields && ! ref($fields->[$i + 1]) && $fields->[$i + 1] eq 'OR') {
                    $hold_error = $err;
                } else {
                    push @errors, $hold_error ? @$hold_error : @$err;
                    $hold_error = undef;
                }
            } else {
                $hold_error = undef;
            }
        }
    }
    push(@errors, @$hold_error) if $hold_error; # allow for final OR to work

    $self->no_extra_fields($form,$fields,$val_hash,\@errors) if ($ARGS->{'no_extra_fields'} || $self->{'no_extra_fields'});

    return if ! @errors; # success

    my %uniq;
    my %error;
    foreach my $err (@errors) {
        my ($field, $type, $fv, $ifs_match) = @$err;
        throw "Missing field name", {err => $err} if ! $field;
        if ($fv->{'delegate_error'}) {
            $field = $fv->{'delegate_error'};
            $field =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
        }
        my $text = $self->get_error_text($err, $ARGS);
        $error{$field} .= "$text\n" if !$uniq{$field}->{$text}++;
    }
    chomp $error{$_} for keys %error;
    throw "Validation failed", {errors => \%error} if $ARGS->{'raise_error'};
    return \%error;
}

sub no_extra_fields {
    my ($self,$form,$fields,$fv,$errors,$field_prefix) = @_;
    $field_prefix ||= '';
    local $self->{'_recurse'} = ($self->{'_recurse'} || 0) + 1;
    throw "Max dependency level reached 10" if $self->{'_recurse'} > 10;

    my %keys = map { ($_->{'field'} => 1) } @$fields;
    foreach my $key (sort keys %$form) {
        if (ref $form->{$key} eq 'HASH') {
            my $field_type = $fv->{$key}->{'type'};
            if(!defined $field_type) {
                # Do nothing
            }
            elsif (ref $field_type ne 'HASH') {
                push @$errors, [$field_prefix.$key, 'no_extra_fields', {}, undef];
                next;
            } else {
                my $f = [map { {field=>$_} } keys %$field_type];
                $self->no_extra_fields($form->{$key},$f,$field_type,$errors,$field_prefix.$key.'.');
            }
        } elsif (ref $form->{$key} eq 'ARRAY') {
            my $field_type = $fv->{$key}->{'type'};
            if (!defined $field_type) {
                # Do nothing
            } elsif (ref $field_type eq 'HASH') {
                my $f = [map { {field=>$_} } keys %$field_type];
                foreach (my $i = 0; $i <= $#{$form->{$key}}; $i ++) {
                    $self->no_extra_fields($form->{$key}->[$i],$f,$field_type,$errors,$field_prefix.$key.':'.$i.'.') if ref $form->{$key}->[$i];
                }
            }
        }
        next if $keys{$key};
        push @$errors, [$field_prefix.$key, 'no_extra_fields', {}, undef];
    }
}

sub get_ordered_fields {
    my ($self, $val_hash) = @_;
    throw "validation must be a hashref" if !$val_hash || ref $val_hash ne 'HASH';
    my %ARGS;
    my @field_keys = grep { /^group\s+(\w+)/ ? do {$ARGS{$1} = $val_hash->{$_}; 0} : 1} sort keys %$val_hash;

    # Look first for items in 'group fields' or 'group order'
    my $fields;
    if (my $ref = $ARGS{'fields'} || $ARGS{'order'}) {
        my $type = $ARGS{'fields'} ? 'group fields' : 'group order';
        throw "Validation '$type' must be an arrayref when passed" if ref($ref) ne 'ARRAY';
        foreach my $field (@$ref) {
            throw "Non-defined value in '$type'" if ! defined $field;
            if (ref $field) {
                throw "Found nonhashref value in '$type'" if ref($field) ne 'HASH';
                throw "Element missing \"field\" key/value in '$type'" if ! defined $field->{'field'};
                push @$fields, $field;
            } elsif ($field eq 'OR') {
                push @$fields, 'OR';
            } else {
                throw "No element found in '$type' for $field" if ! exists $val_hash->{$field};
                throw "Found nonhashref value in '$type'" if ref($val_hash->{$field}) ne 'HASH';
                my $val = $val_hash->{$field};
                $val = {%$val, field => $field} if ! $val->{'field'};  # copy the values to add the key
                push @$fields, $val;
            }
        }

        # limit the keys that need to be searched to those not in fields or order
        my %found = map { ref($_) ? ($_->{'field'} => 1) : () } @$fields;
        @field_keys = grep { ! $found{$_} } @field_keys;
    }

    # add any remaining field_vals from our original hash
    # this is necessary for items that weren't in group fields or group order
    foreach my $field (@field_keys) {
        throw "Found nonhashref value for field $field" if ref($val_hash->{$field}) ne 'HASH';
        if (defined $val_hash->{$field}->{'field'}) {
            push @$fields, $val_hash->{$field};
        } else {
            push @$fields, { %{$val_hash->{$field}}, field => $field };
        }
    }

    return ($fields || [], \%ARGS);
}

# allow for optional validation on groups and on individual items
sub check_conditional {
    my ($self, $form, $ifs, $ifs_match) = @_;
    throw "Need reference passed to check_conditional" if ! $ifs;
    $ifs = [$ifs] if ! ref($ifs) || ref($ifs) eq 'HASH';

    local $self->{'_check_conditional'} = 1;

    # run the if options here
    # multiple items can be passed - all are required unless OR is used to separate
    my $found = 1;
    foreach (my $i = 0; $i <= $#$ifs; $i ++) {
        my $ref = $ifs->[$i];
        if (! ref $ref) {
            if ($ref eq 'OR') {
                $i++ if $found; # if found skip the OR altogether
                $found = 1; # reset
                next;
            } else {
                if ($ref =~ /^function\s*\(/) {
                    next;
                } elsif ($ref =~ /^(.*?)\s+(was_valid|had_error|was_checked)$/) {
                    $ref = {field => $1, $2 => 1};
                } elsif ($ref =~ s/^\s*!\s*//) {
                    $ref = {field => $ref, max_in_set => "0 of $ref"};
                } else {
                    $ref = {field => $ref, required => 1};
                }
            }
        }
        last if ! $found;

        # get the field - allow for custom variables based upon a match
        my $field = $ref->{'field'} || throw "Missing field key during validate_if (possibly used a reference to a main hash *foo -> &foo)";
        $field =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;

        # max_values is properly checked elsewhere, however we need to stub in a value so defaults are properly set
        $ref->{'max_values'} ||= scalar @{$form->{$field}} if ref $form->{$field} eq 'ARRAY';

        my $errs = $self->validate_buddy($form, $field, $ref);

        $found = 0 if $errs;
    }
    return $found;
}


# this is where the main checking goes on
sub validate_buddy {
    my ($self, $form, $field, $fv, $ifs_match, $field_prefix) = @_;
    $field_prefix ||= '';
    local $self->{'_recurse'} = ($self->{'_recurse'} || 0) + 1;
    throw "Max dependency level reached 10" if $self->{'_recurse'} > 10;
    my @errors;

    if ($fv->{'exclude_cgi'}) {
        delete $fv->{'was_validated'};
        return 0;
    }

    # allow for field names that contain regular expressions
    if ($field =~ m/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/s) {
        my ($not,$pat,$opt) = ($1,$3,$4);
        $opt =~ tr/g//d;
        throw "The e option cannot be used on validation keys on field $field" if $opt =~ /e/;
        foreach my $_field (sort keys %$form) {
            next if ($not && $_field =~ m/(?$opt:$pat)/) || (! $not && $_field !~ m/(?$opt:$pat)/);
            my $errs = $self->validate_buddy($form, $_field, $fv, [undef, $1, $2, $3, $4, $5]);
            push @errors, @$errs if $errs;
        }
        return @errors ? \@errors : 0;
    }

    # allow for canonical field name (allows api to present one field name but return a different one)
    # need to do this relatively early since we are changing the value of $field
    if ($fv->{'canonical'}) {
        my $orig = $fv->{'orig_field'} = $field;
        $field = $fv->{'canonical'};
        $form->{$field} = delete $form->{$orig};
    }

    if ($fv->{'was_valid'}   && ! $self->{'was_valid'}->{$field})   { return [[$field_prefix.$field, 'was_valid',   $fv, $ifs_match]]; }
    if ($fv->{'had_error'}   && ! $self->{'had_error'}->{$field})   { return [[$field_prefix.$field, 'had_error',   $fv, $ifs_match]]; }
    if ($fv->{'was_checked'} && ! $self->{'was_checked'}->{$field}) { return [[$field_prefix.$field, 'was_checked', $fv, $ifs_match]]; }

    if (!exists($form->{$field}) && $fv->{'alias'}) {
        foreach my $alias (ref($fv->{'alias'}) ? @{$fv->{'alias'}} : $fv->{'alias'}) {
            next if ! exists $form->{$alias};
            $form->{$field} = delete $form->{$alias};
            last;
        }
    }

    # allow for default value
    if (defined($fv->{'default'})
        && (!defined($form->{$field}) || (ref($form->{$field}) eq 'ARRAY' ? !@{ $form->{$field} } : !length($form->{$field})))) {
        $form->{$field} = $fv->{'default'};
    }

    my $values   = ref($form->{$field}) eq 'ARRAY' ? $form->{$field} : [$form->{$field}];
    my $n_values = @$values;

    # allow for a few form modifiers
    my $modified = 0;
    foreach my $value (@$values) {
        next if ! defined $value;
        if (! $fv->{'do_not_trim'}) { # whitespace
            $modified = 1 if  $value =~ s/( ^\s+ | \s+$ )//xg;
        }
        if ($fv->{'trim_control_chars'}) {
            $modified = 1 if $value =~ y/\t/ /;
            $modified = 1 if $value =~ y/\x00-\x1F//d;
        }
        if ($fv->{'to_upper_case'}) { # uppercase
            $value = uc $value;
            $modified = 1;
        } elsif ($fv->{'to_lower_case'}) { # lowercase
            $value = lc $value;
            $modified = 1;
        }
    }

    my %types;
    foreach (sort keys %$fv) {
        push @{$types{$1}}, $_ if /^ (compare|custom|equals|match|max_in_set|min_in_set|replace|required_if|sql|type|validate_if) _?\d* $/x;
    }

    # allow for inline specified modifications (ie s/foo/bar/)
    if ($types{'replace'}) { foreach my $type (@{ $types{'replace'} }) {
        my $ref = ref($fv->{$type}) eq 'ARRAY' ? $fv->{$type}
        : [split(/\s*\|\|\s*/,$fv->{$type})];
        foreach my $rx (@$ref) {
            if ($rx !~ m/^\s*s([^\s\w])(.+)\1(.*)\1([eigsmx]*)$/s) {
                throw "Not sure how to parse that replace ($rx)";
            }
            my ($pat, $swap, $opt) = ($2, $3, $4);
            throw "The e option cannot be used in swap on field $field" if $opt =~ /e/;
            my $global = $opt =~ s/g//g;
            $swap =~ s/\\n/\n/g;
            my $expand = sub { # code similar to Template::Alloy::VMethod::vmethod_replace
                my ($text, $start, $end) = @_;
                my $copy = $swap;
                $copy =~ s{ \\(\\|\$) | \$ (\d+) }{
                    $1 ? $1
                        : ($2 > $#$start || $2 == 0) ? ''
                        : substr($text, $start->[$2], $end->[$2] - $start->[$2]);
                }exg;
                $modified = 1;
                $copy;
            };
            foreach my $value (@$values) {
                next if ! defined $value;
                if ($global) { $value =~ s{(?$opt:$pat)}{ $expand->($value, [@-], [@+]) }eg }
                else         { $value =~ s{(?$opt:$pat)}{ $expand->($value, [@-], [@+]) }e  }
            }
        }
    } }
    $form->{$field} = $values->[0] if $modified && $n_values == 1; # put them back into the form if we have modified it

    # only continue if a validate_if is not present or passes test
    my $needs_val = 0;
    my $n_vif = 0;
    if ($types{'validate_if'}) { foreach my $type (@{ $types{'validate_if'} }) {
        $n_vif++;
        my $ifs = $fv->{$type};
        my $ret = $self->check_conditional($form, $ifs, $ifs_match);
        $needs_val++ if $ret;
    } }
    if (! $needs_val && $n_vif) {
        delete $fv->{'was_validated'};
        return 0;
    }

    # check for simple existence
    # optionally check only if another condition is met
    my $is_required = $fv->{'required'} ? 'required' : '';
    if (! $is_required) {
        if ($types{'required_if'}) { foreach my $type (@{ $types{'required_if'} }) {
            my $ifs = $fv->{$type};
            next if ! $self->check_conditional($form, $ifs, $ifs_match);
            $is_required = $type;
            last;
        } }
    }
    if ($is_required
        && ($n_values == 0 || ($n_values == 1 && (! defined($values->[0]) || ! length $values->[0])))) {
        return [] if $self->{'_check_conditional'};
        return [[$field_prefix.$field, $is_required, $fv, $ifs_match]];
    }

    my $n = exists($fv->{'min_values'}) ? $fv->{'min_values'} || 0 : 0;
    if ($n_values < $n) {
        return [] if $self->{'_check_conditional'};
        return [[$field_prefix.$field, 'min_values', $fv, $ifs_match]];
    }

    $fv->{'max_values'} = $fv->{'min_values'} || 1 if ! exists $fv->{'max_values'};
    $n = $fv->{'max_values'} || 0;
    if ($n_values > $n) {
        return [] if $self->{'_check_conditional'};
        return [[$field_prefix.$field, 'max_values', $fv, $ifs_match]];
    }

    foreach ([min => $types{'min_in_set'}],
             [max => $types{'max_in_set'}]) {
        my $keys   = $_->[1] || next;
        my $minmax = $_->[0];
        foreach my $type (@$keys) {
            $fv->{$type} =~ m/^\s*(\d+)(?i:\s*of)?\s+(.+)\s*$/
                || throw "Invalid ${minmax}_in_set check $fv->{$type}";
            my $n = $1;
            foreach my $_field (split /[\s,]+/, $2) {
                my $ref = ref($form->{$_field}) eq 'ARRAY' ? $form->{$_field} : [$form->{$_field}];
                foreach my $_value (@$ref) {
                    $n -- if defined($_value) && length($_value);
                }
            }
            if (   ($minmax eq 'min' && $n > 0)
                   || ($minmax eq 'max' && $n < 0)) {
                return [] if $self->{'_check_conditional'};
                return [[$field_prefix.$field, $type, $fv, $ifs_match]];
            }
        }
    }

    # at this point @errors should still be empty
    my $content_checked; # allow later for possible untainting (only happens if content was checked)

    OUTER: foreach my $value (@$values) {

        if (exists $fv->{'enum'}) {
            my $ref = ref($fv->{'enum'}) ? $fv->{'enum'} : [split(/\s*\|\|\s*/,$fv->{'enum'})];
            my $found = 0;
            foreach (@$ref) {
                $found = 1 if defined($value) && $_ eq $value;
            }
            if (! $found) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field_prefix.$field, 'enum', $fv, $ifs_match];
                next OUTER;
            }
            $content_checked = 1;
        }

        # do specific type checks
        if (exists $fv->{'type'}) {
            if (! $self->check_type($value, $fv->{'type'}, $field, $form)){
                return [] if $self->{'_check_conditional'};
                push @errors, [$field_prefix.$field, 'type', $fv, $ifs_match];
                next OUTER;
            } if (ref($fv->{'type'}) eq 'HASH' && $form->{$field}) {
                # recursively check these
                foreach my $key (keys %{$fv->{'type'}}) {
                    foreach my $subform (@{ref($form->{$field}) eq 'ARRAY' ? $form->{$field} : [$form->{$field}]}) {
                        my $errs = $self->validate_buddy($subform, $key, $fv->{'type'}->{$key},[],$field_prefix.$field.'.');
                        push @errors, @$errs if $errs;
                    }
                }
                return @errors ? \@errors : 0;
            }
            $content_checked = 1;
        }

        # field equals another field
        if ($types{'equals'}) { foreach my $type (@{ $types{'equals'} }) {
            my $field2  = $fv->{$type};
            my $not     = ($field2 =~ s/^!\s*//) ? 1 : 0;
            my $success = 0;
            if ($field2 =~ m/^([\"\'])(.*)\1$/) {
                $success = (defined($value) && $value eq $2);
            } else {
                $field2 =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
                if (exists($form->{$field2}) && defined($form->{$field2})) {
                    $success = (defined($value) && $value eq $form->{$field2});
                } elsif (! defined($value)) {
                    $success = 1; # occurs if they are both undefined
                }
            }
            if ($not ? $success : ! $success) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field_prefix.$field, $type, $fv, $ifs_match];
                next OUTER;
            }
            $content_checked = 1;
        } }

        if (exists $fv->{'min_len'}) {
            my $n = $fv->{'min_len'};
            if (! defined($value) || length($value) < $n) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field_prefix.$field, 'min_len', $fv, $ifs_match];
            }
        }

        if (exists $fv->{'max_len'}) {
            my $n = $fv->{'max_len'};
            if (defined($value) && length($value) > $n) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field_prefix.$field, 'max_len', $fv, $ifs_match];
            }
        }

        # now do match types
        if ($types{'match'}) { foreach my $type (@{ $types{'match'} }) {
            my $ref = ref($fv->{$type}) eq 'ARRAY' ? $fv->{$type}
                : ref($fv->{$type}) eq 'Regexp'    ? [$fv->{$type}]
                : [split(/\s*\|\|\s*/,$fv->{$type})];
            foreach my $rx (@$ref) {
                if (ref($rx) eq 'Regexp') {
                    if (! defined($value) || $value !~ $rx) {
                        push @errors, [$field_prefix.$field, $type, $fv, $ifs_match];
                    }
                } else {
                    if ($rx !~ m/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/s) {
                        throw "Not sure how to parse that match ($rx)";
                    }
                    my ($not, $pat, $opt) = ($1, $3, $4);
                    $opt =~ tr/g//d;
                    throw "The e option cannot be used on validation keys on field $field" if $opt =~ /e/;
                    if ( (     $not && (  defined($value) && $value =~ m/(?$opt:$pat)/))
                         || (! $not && (! defined($value) || $value !~ m/(?$opt:$pat)/)) ) {
                        return [] if $self->{'_check_conditional'};
                        push @errors, [$field_prefix.$field, $type, $fv, $ifs_match];
                    }
                }
            }
            $content_checked = 1;
        } }

        # allow for comparison checks
        if ($types{'compare'}) { foreach my $type (@{ $types{'compare'} }) {
            my $ref = ref($fv->{$type}) eq 'ARRAY' ? $fv->{$type} : [split(/\s*\|\|\s*/, $fv->{$type})];
            foreach my $comp (@$ref) {
                next if ! $comp;
                my $test  = 0;
                if ($comp =~ /^\s*(>|<|[><!=]=)\s*([\d\.\-]+|field:(.+))\s*$/) {
                    my ($op, $value2, $field2) = ($1, $2, $3);
                    if ($field2) {
                        $field2 =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
                        $value2 = exists($form->{$field2}) ? $form->{$field2} * 1 : 0;
                    }
                    my $val = $value || 0;
                    $val *= 1;
                    if    ($op eq '>' ) { $test = ($val >  $value2) }
                    elsif ($op eq '<' ) { $test = ($val <  $value2) }
                    elsif ($op eq '>=') { $test = ($val >= $value2) }
                    elsif ($op eq '<=') { $test = ($val <= $value2) }
                    elsif ($op eq '!=') { $test = ($val != $value2) }
                    elsif ($op eq '==') { $test = ($val == $value2) }

                } elsif ($comp =~ /^\s*(eq|ne|gt|ge|lt|le)\s+(field:(.+)|.+?)\s*$/) {
                    my $val = defined($value) ? $value : '';
                    my ($op, $value2, $field2) = ($1, $2, $3);
                    if ($field2) {
                        $field2 =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
                        $value2 = defined($form->{$field2}) ? $form->{$field2} : '';
                    } else {
                        $value2 =~ s/^([\"\'])(.*)\1$/$2/;
                    }
                    if    ($op eq 'gt') { $test = ($val gt $value2) }
                    elsif ($op eq 'lt') { $test = ($val lt $value2) }
                    elsif ($op eq 'ge') { $test = ($val ge $value2) }
                    elsif ($op eq 'le') { $test = ($val le $value2) }
                    elsif ($op eq 'ne') { $test = ($val ne $value2) }
                    elsif ($op eq 'eq') { $test = ($val eq $value2) }

                } else {
                    throw "Not sure how to compare \"$comp\"";
                }
                if (! $test) {
                    return [] if $self->{'_check_conditional'};
                    push @errors, [$field_prefix.$field, $type, $fv, $ifs_match];
                }
            }
            $content_checked = 1;
        } }

        # server side sql type
        if ($types{'sql'}) { foreach my $type (@{ $types{'sql'} }) {
            my $db_type = $fv->{"${type}_db_type"};
            my $dbh = ($db_type) ? $self->{dbhs}->{$db_type} : $self->{dbh};
            if (! $dbh) {
                throw "Missing dbh for $type type on field $field" . ($db_type ? " and db_type $db_type" : "");
            } elsif (ref($dbh) eq 'CODE') {
                $dbh = &$dbh($field, $self) || throw "SQL Coderef did not return a dbh";
            }
            my $sql  = $fv->{$type};
            my @args = ($value) x $sql =~ tr/?//;
            my $return = $dbh->selectrow_array($sql, {}, @args); # is this right - copied from O::FORMS
            $fv->{"${type}_error_if"} = 1 if ! defined $fv->{"${type}_error_if"};
            if ( (! $return && $fv->{"${type}_error_if"})
                 || ($return && ! $fv->{"${type}_error_if"}) ) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field_prefix.$field, $type, $fv, $ifs_match];
            }
            $content_checked = 1;
        } }

        # server side custom type
        if ($types{'custom'}) { foreach my $type (@{ $types{'custom'} }) {
            my $check = $fv->{$type};
            my $err;
            if (ref($check) eq 'CODE') {
                my $ok;
                $err = "$@" if ! eval { $ok = $check->($field, $value, $fv, $type, $form); 1 };
                next if $ok;
                chomp($err) if !ref($@) && defined($err);
            } else {
                next if $check;
            }
            return [] if $self->{'_check_conditional'};
            push @errors, [$field_prefix.$field, $type, $fv, $ifs_match, (defined($err) ? $err : ())];
            $content_checked = 1;
        } }

    }

    # allow for the data to be "untainted"
    # this is only allowable if the user ran some other check for the datatype
    if ($fv->{'untaint'} && $#errors == -1) {
        if (! $content_checked) {
            push @errors, [$field_prefix.$field, 'untaint', $fv, $ifs_match];
        } else {
            # generic untainter - assuming the other required content_checks did good validation
            $_ = /(.*)/ ? $1 : throw "Couldn't match?" foreach @$values;
            if ($n_values == 1) {
                $form->{$field} = $values->[0];
            }
        }
    }

    return @errors ? \@errors : 0;
}

sub check_type {
    my ($self, $value, $type) = @_;
    $type = ref($type) eq 'HASH' ? 'hash' : lc $type;
    return 0 if ! defined $value;
    if ($type eq 'email') {
        return 0 if ! $value;
        my ($local_p,$dom) = ($value =~ /^(.+)\@(.+?)$/) ? ($1,$2) : return 0;
        return 0 if length($local_p) > 60;
        return 0 if length($dom) > 100;
        return 0 if ! $self->check_type($dom,'domain') && ! $self->check_type($dom,'ip');
        return 0 if ! $self->check_type($local_p,'local_part');
    } elsif ($type eq 'hash') {
        return 0 if ref $value ne 'HASH';
    } elsif ($type eq 'local_part') {
        return 0 if ! length($value);
        # ignoring all valid quoted string local parts
        return 0 if $value =~ m/[^\w.~!\#\$%\^&*\-=+?]/;
    } elsif ($type eq 'ip') {
        return 0 if ! $value;
        return (4 == grep {/^\d+$/ && $_ < 256} split /\./, $value, 4);
    } elsif ($type eq 'domain') {
        return 0 if ! $value || length($value) > 255;
        return 0 if $value !~ /^(?:[a-z0-9][a-z0-9\-]{0,62} \.)+ [a-z0-9][a-z0-9\-]{0,62}$/ix
            || $value =~ m/(?:\.\-|\-\.|\.\.)/;
    } elsif ($type eq 'url') {
        return 0 if ! $value;
        $value =~ s|^https?://([^/]+)||i || return 0;
        my $dom = $1;
        return 0 if ! $self->check_type($dom,'domain') && ! $self->check_type($dom,'ip');
        return 0 if $value && ! $self->check_type($value,'uri');
    } elsif ($type eq 'uri') {
        return 0 if ! $value;
        return 0 if $value =~ m/\s+/;
    } elsif ($type eq 'int') {
        return 0 if $value !~ /^-? (?: 0 | [1-9]\d*) $/x;
        return 0 if ($value < 0) ? $value < -2**31 : $value > 2**31-1;
    } elsif ($type eq 'uint') {
        return 0 if $value !~ /^   (?: 0 | [1-9]\d*) $/x;
        return 0 if $value > 2**32-1;
    } elsif ($type eq 'num') {
        return 0 if $value !~ /^-? (?: 0 | [1-9]\d* (?:\.\d+)? | 0?\.\d+) $/x;
    } elsif ($type eq 'unum') {
        return 0 if $value !~ /^   (?: 0 | [1-9]\d* (?:\.\d+)? | 0?\.\d+) $/x;
    } elsif ($type eq 'cc') {
        return 0 if ! $value;
        return 0 if $value =~ /[^\d\-\ ]/;
        $value =~ s/\D//g;
        return 0 if length($value) > 16 || length($value) < 13;

        # simple mod10 check
        my $sum = my $switch = 0;
        foreach my $digit (reverse split //, $value) {
            $switch = 1 if ++$switch > 2;
            my $y = $digit * $switch;
            $y -= 9 if $y > 9;
            $sum += $y;
        }
        return 0 if $sum % 10;
    }

    return 1;
}

sub get_error_text {
    my ($self, $err, $extra) = @_;
    my ($field, $type, $fv, $ifs_match, $custom_err) = @$err;
    return $custom_err if defined($custom_err) && length($custom_err);
    my $dig = ($type =~ s/(_?\d+)$//) ? $1 : '';

    $field = $fv->{'delegate_error'} if $fv->{'delegate_error'};
    my $name = $fv->{'name'} || $field;
    if ($ifs_match) { s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg for $field, $name }

    # type can look like "required" or "required2" or "required100023"
    # allow for fallback from required100023_error through required_error
    # look in the passed hash or self first
    foreach my $key ((length($dig) ? "${type}${dig}_error" : ()), "${type}_error", 'error') {
        my $msg = $fv->{$key} || $extra->{$key} || next;
        $msg =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
        $msg =~ s/\$field/$field/g;
        $msg =~ s/\$name/$name/g;
        if (my $value = $fv->{"$type$dig"}) {
            $msg =~ s/\$value/$value/g if ! ref $value;
        }
        return $msg;
    }

    if ($type eq 'required' || $type eq 'required_if') {
        return "$name is required.";
    } elsif ($type eq 'min_values') {
        my $n = $fv->{"min_values${dig}"};
        my $values = ($n == 1) ? 'value' : 'values';
        return "$name had less than $n $values.";
    } elsif ($type eq 'max_values') {
        my $n = $fv->{"max_values${dig}"};
        my $values = ($n == 1) ? 'value' : 'values';
        return "$name had more than $n $values.";
    } elsif ($type eq 'enum') {
        return "$name is not in the given list.";
    } elsif ($type eq 'equals') {
        my $field2 = $fv->{"equals${dig}"};
        my $name2  = $fv->{"equals${dig}_name"} || "the field $field2";
        $name2 =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
        return "$name did not equal $name2.";
    } elsif ($type eq 'min_len') {
        my $n = $fv->{"min_len${dig}"};
        my $char = ($n == 1) ? 'character' : 'characters';
        return "$name was less than $n $char.";
    } elsif ($type eq 'max_len') {
        my $n = $fv->{"max_len${dig}"};
        my $char = ($n == 1) ? 'character' : 'characters';
        return "$name was more than $n $char.";
    } elsif ($type eq 'max_in_set') {
        my $set = $fv->{"max_in_set${dig}"};
        return "Too many fields were chosen from the set ($set)";
    } elsif ($type eq 'min_in_set') {
        my $set = $fv->{"min_in_set${dig}"};
        return "Not enough fields were chosen from the set ($set)";
    } elsif ($type eq 'match') {
        return "$name contains invalid characters.";
    } elsif ($type eq 'compare') {
        return "$name did not fit comparison.";
    } elsif ($type eq 'sql') {
        return "$name did not match sql test.";
    } elsif ($type eq 'custom') {
        return "$name did not match custom test.";
    } elsif ($type eq 'type') {
        my $_type = $fv->{"type${dig}"};
        $_type = 'hash' if ref($_type) eq 'HASH';
        return "$name did not match type $_type.";
    } elsif ($type eq 'untaint') {
        return "$name cannot be untainted without one of the following checks: enum, equals, match, compare, sql, type, custom";
    } elsif ($type eq 'no_extra_fields') {
        return "$name should not be passed to validate.";
    }
    throw "Missing error on field $field for type $type$dig";
}

1;

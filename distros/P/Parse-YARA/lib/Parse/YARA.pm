package Parse::YARA;

use strict;
use warnings;
use Carp qw(carp);
use Tie::IxHash;
use File::Basename;

our $VERSION = '0.02';

=head1 NAME

Parse::YARA - Parse and create YARA rules

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

	use Parse::YARA;
	
	my $rule_string = 'rule sample_rule : sample
	{
	    meta:
	        info = "sample rule"
	
	    strings:
	        $ = "anon1"
	        $ = "anon2"
	        $test_string = "test_string"
	
	    condition:
	        any of them
	}';
	my $rule_string_obj = Parse::YARA->new();
	$rule_string_obj->parse($rule_string);
	$rule_string_obj->add_string_modifier('sample_rule', '$test_string', 'all');
	print $rule_string_obj->as_string;
	
	my $rule_element_hashref = { 
	                            modifier => 'private',
	                            rule_id => 'sample_hash_rule',
	                            tag => [
	                                    'tag1',
	                                    'tag2'
	                                   ],  
	                            meta => {
	                                     'info' => 'sample hash rule',
	                                     'site' => 'http://search.cpan.org/~moofu/'
	                                    },  
	                            strings => {
	                                        '$' => {
	                                                value => 'anon1',
	                                                type => 'text',
	                                               },  
	                                        '$$' => {
	                                                 value => 'anon2',
	                                                 type => 'text'
	                                                },  
	                                        '$test_string' => {
	                                                           value => 'test_string',
	                                                           type => 'text'
	                                                          },  
	                                        '$test_hex_string' => {
	                                                               value => '{ AA BB CC DD }',
	                                                               type => 'hex'
	                                                              },  
	                                        '$test_regex_string' => {
	                                                                 value => '/.*/',
	                                                                  type => 'regex'
	                                                                },  
	                                       },  
	                            condition => 'true'
	                           };
	my $rule_hash_obj = Parse::YARA->new(rulehash => $rule_element_hashref);
	print $rule_hash_obj->as_string;
	
	my $rule_file = '/path/to/rules.yar';
	my $rule_file_obj = Parse::YARA->new(file => $rule_file);
	
	my $rule_obj = Parse::YARA->new();
	$rule_obj->set_rule_modifier('new_rule', 'global');
	$rule_obj->set_condition('new_rule', 'one of them');
	$rule_obj->add_tag('new_rule', 'test_only');
	$rule_obj->add_meta('new_rule', 'author', 'Leigh');
	$rule_obj->add_meta('new_rule', 'site', 'http://search.cpan.org/~moofu/');
	$rule_obj->add_anonymous_string('new_rule', 'anonymous', 'text');
	$rule_obj->add_string('new_rule', '$string1', 'A test string', 'text');
	$rule_obj->add_string('new_rule', '$string2', 'Another example', 'text');
	$rule_obj->add_string_modifier('new_rule', '$string1', 'ascii');
	print $rule_obj->as_string;
	
	$rule_obj->modify_meta('new_rule', 'author', 'Leigh Thompson');
	$rule_obj->modify_string('new_rule', '$string1', 'An example string');
	print $rule_obj->as_string;
	
	$rule_obj->remove_string_modifier('new_rule', '$string1', 'ascii');
	$rule_obj->remove_tag('new_rule', 'test_only');
	$rule_obj->remove_meta('new_rule', 'site');
	$rule_obj->remove_anonymous_string('new_rule', 'anonymous');
	$rule_obj->remove_string('new_rule', '$string2');
	print $rule_obj->as_string;

=head1 NOTE FOR PERL >= 5.18

Hash order will not be guaranteed so the use of Tie::IxHash is required for passing hashes into the module if order within the YARA rule is required.

For the example given above, the following steps would need to be taken:

    use Tie::IxHash;
    my $rule_element_hashref;
    my $rule_element_hashref_knot = tie(%{$rule_element_hashref}, 'Tie::IxHash');
    my $meta_hashref;
    my $meta_hashref_knot = tie(%{$meta_hashref}, 'Tie::IxHash');
    my $strings_hashref;
    my $strings_hashref_knot = tie(%{$strings_hashref}, 'Tie::IxHash');
    $meta_hashref->{info} = 'sample hash rule';
    $meta_hashref->{site} = 'http://search.cpan.org/~moofu/';
    $strings_hashref->{'$'} = { value => 'anon1', type => 'text' };
    $strings_hashref->{'$$'} = { value => 'anon2', type => 'text' };
    $strings_hashref->{'$test_string'}= { value => 'test_string', type => 'text' };
    $strings_hashref->{'$test_hex_string'} = { value => '{ AA BB CC DD }', type => 'hex' };
    $strings_hashref->{'$test_regex_string'} = { value => '/.*/', type => 'regex' };
    $rule_element_hashref = { 
                             modifier => 'private',
                             rule_id => 'sample_hash_rule_tied',
                             tag => [
                                     'tag1',
                                     'tag2'
                                    ],  
                             meta => $meta_hashref,
                             strings => $strings_hashref,
                             condition => 'true'
                            }; 

=cut

# Set some reserved words
our @RESERVED_ARRAY = qw/ all in and include any index ascii indexes at int8 condition int16 contains int32 entrypoint matches false meta filesize nocase fullword not for or global of private rule rva section strings them true uint8 uint16 uint32 wide /;
our %RESERVED_WORDS = map { $_ => 1 } @RESERVED_ARRAY;

=head1 METHODS

These are the object methods that can be used to read, add or modify any part of a YARA rule.

=over

=item new()

Create a new C<Parse::YARA> object, and return it. There are a couple of options when creating the object:

=over 4

=item new(disable_includes => 0, $verbose => 0)

Create an unpopulated object, that can be filled in using the individual rule element methods, or can be populated with the read_file method.

=item new(rule => $rule, disable_includes => 0, $verbose => 0)

Create an object by providing a YARA rule as a string value.

=item new(file => $file, $disable_includes => 0, $verbose => 0)

Parse a file containing one or more YARA rules and create objects for each rule.

The include option is turned on by default, this will ensure that all files included in the file being parsed are read in by the parser. Turn this off by setting disable_includes => 1.

=item new(rulehash => $rule_element_hashref, $disable_includes => 0, $verbose => 0)

Create an object based on a prepared hash reference.

    my $rule_element_hashref = { 
                                modifier => 'global',
                                rule_id => 'sample_hash_rule',
                                tag => [
                                        'tag1',
                                        'tag2'
                                       ],  
                                meta => {
                                         'info' => 'sample hash rule',
                                         'site' => 'http://search.cpan.org/~moofu/'
                                        },  
                                strings => {
                                            '$' => {
                                                    value => 'anon1',
                                                    type => 'text',
                                                   },  
                                            '$$' => {
                                                     value => 'anon2',
                                                     type => 'text'
                                                    },  
                                            '$test_string' => {
                                                               value => 'test_string',
                                                               type => 'text'
                                                              },  
                                            '$test_hex_string' => {
                                                                   value => '{ AA BB CC DD }',
                                                                   type => 'hex'
                                                                  },  
                                            '$test_regex_string' => {
                                                                     value => '/.*/',
                                                                     type => 'regex'
                                                                    },  
                                           },  
                                condition => 'all of them'
                               };

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};

    bless($self, $class);
    $self->_init(%args);
    return $self;
}

# _init
# 

sub _init {
    my ($self, %args) = @_;

    # Turn on verbose if requested
    if($args{verbose}) {
        $self->{verbose} = 1;
        delete($args{verbose});
    }

    # Turn on includes if requested
    if(!$args{disable_includes}) {
        $self->{include} = 1;
        delete($args{disable_includes});
    }

    # Tie a hash to contain all rules so we can assure order
    $self->{rules_knot} = tie(%{$self->{rules}}, 'Tie::IxHash');

    # Check what we were passed and behave appropriately
    if($args{rule}) {
        $self->parse($args{rule});
    } elsif($args{file}) {
        # This in turn will call $self->parse on the contents of the file
        $self->read_file($args{file});
    } elsif($args{rulehash}) {
        # We can't proceed without a rule_id so make sure it's set
        # then add it to the new rules object
        if($args{rulehash}->{rule_id}) {
            my $rule_id = $args{rulehash}->{rule_id};
            delete($args{rulehash}->{rule_id});
            # Loop through the remaining components of the rulehash
            # and add them to the rules object
            foreach my $key (keys(%{$args{rulehash}})) {
                my $sub = "_$key";
                $self->$sub($rule_id, $args{rulehash}->{$key});
            }
        } else {
            carp("Cannot add rule with no rule_id\n");
        }
    }

    return $self;
}

# _modifier
# Adds any modifiers passed to new() as a hashref
# by calling set_rule_modifier

sub _modifier {
    my ($self, $rule_id, $modifier) = @_;

    $self->set_rule_modifier($rule_id, $modifier);
}

# _tag
# Adds any tags passed to new() as a hashref
# by calling add_tag for each tag in the array

sub _tag {
    my ($self, $rule_id, $tags) = @_;

    foreach(@{$tags}) {
        $self->add_tag($rule_id, $_);
    }
}

# _meta_
# Adds any meta attributes passed to new() as a hashref
# by calling add_meta for each meta name/value in the hash

sub _meta {
    my ($self, $rule_id, $meta_hash) = @_;

    foreach my $meta_name (keys(%{$meta_hash})) {
        $self->add_meta($rule_id, $meta_name, $meta_hash->{$meta_name});
    }
}

# _strings
# Adds any string attributes passed to new() as a hashref
# by calling add_anonymous_string or add_string as appropriate
# for each string name/value in the hash

sub _strings {
    my ($self, $rule_id, $string_hash) = @_;

    # We need to make sure the strings hash element exists
    #if(!$self->{rules}->{$rule_id}->{strings}) {
    #    $self->{rules}->{$rule_id}->{strings} = undef;
    #}

    # Loop through each string in the hashref
    foreach my $string_name (keys(%{$string_hash})) {
        # If we find an array we need to loop through that too
        if(ref($string_hash->{$string_name}) eq "ARRAY") {
            foreach(@{$string_hash->{$string_name}}) {
                # We can add multiple anonymous strings so look for them then add them
                if($string_name eq "\$") {
                    $self->add_anonymous_string($rule_id, $_->{value}, $_->{type});
                # Otherwise we need to bail as we can't add multiple strings with the same string name
                } else {
                    carp("$rule_id: error parsing strings, found multiple strings with name $string_name");
                }
            }
        } else {
            # For unique string names, simply add the string
            $self->add_string($rule_id, $string_name, $string_hash->{$string_name}->{value}, $string_hash->{$string_name}->{type});
        }
    }
}

# _condition
# Adds the condition passed to new() as a hashref
# by calling set_condition

sub _condition {
    my ($self, $rule_id, $condition) = @_;

    $self->set_condition($rule_id, $condition);
}

# _is_valid
# Checks to see if a word is valid given context

sub _is_valid {
    my ($self, $str, $type) = @_;
    my $valid = 1;

    if($str) {
        if($type eq "rule_id") {
            # Can contain any alphanumeric character and the underscore character, but the first character can not be a digit
            if($str =~ /^\d/) {
                carp("$str: rule_id cannot start with a digit");
                $valid = 0;
            } elsif($str !~ /^[a-zA-Z0-9_]+$/) {
                carp("$str: rule_id can only contain alphanumeric and underscore characters");
                $valid = 0;
            }
        } elsif($type eq "string_name") {
            # Must start with a $
            if($str !~ /^\$/) {
                carp("String identifier must start with a \$: $str");
                $valid = 0;
            }
        }
    } else {
        carp("Can't check empty string");
        $valid = 0;
    }

    return $valid;
}

# _check_reserved
# Checks to see if a word is reserved and exits if one is found

sub _check_reserved {
    my ($self, $str, $type) = @_;
    my $reserved;

    if($str) {
        map {
            if(exists($RESERVED_WORDS{$_})) {
                # These lists are through trial and error
                if($type eq "meta" and $_ !~ /^(?:include|indexes)$/) {
                    $reserved = 1;
                } elsif($type eq "condition" and /^(?:include|ascii|condition|meta|nocase|fullword|strings|wide)$/) {
                    $reserved = 1;
                } elsif($type !~ /^(?:meta|condition)$/) {
                    $reserved = 1;
                }
            }
        } split(/\s+/, $str);
    } else {
        carp("Can't check empty string\n");
    }

    return $reserved;
}

=back

=item parse($rule_string)

Reads in a string of one or more rules and parses it into a hashref that can be manipulated by the other functions.

=cut

sub parse {
    my ($self, $rule_string) = @_;
    my $modifier;
    my $rule_id;
    my $tags;
    my $position = 1;
    my $rule_data = {};
    my $knot = tie(%{$rule_data}, 'Tie::IxHash');

    # Strip comments, I have replaced the comments with a newline as otherwise it was stripping the newline, this hasn't broken anything so far.
    # For an explanation, see: http://perldoc.perl.org/perlfaq6.html#How-do-I-use-a-regular-expression-to-strip-C-style-comments-from-a-file%3F
    $rule_string =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|//([^\\]|[^\n][\n]?)*?\n|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $3 ? $3 : "\n"#gse;
    $rule_string =~ s/\n\/\/.*//g;

    # Tidy up any strings that come in with strange formatting
    # Rules with the close brace for previous rule on the same line
    $rule_string =~ s/\n\s*}\s*(rule.*)/\n}\n$1/g;
    # String / Meta names on one line but values on the next
    $rule_string =~ s/\s*(\S+)\s*=\s*\n\s*(\S+)/\n\t\t$1 = $2\n/g;
    # Multiple strings on the same line
    $rule_string =~ s/(\/)(\$\S+\s*=)/$1\n\t\t$2/g;
    $rule_string =~ s/(")(\$\S+\s*=)/$1\n\t\t$2/g;
    $rule_string =~ s/(})(\$\S+\s*=)/$1\n\t\t$2/g;

    # Parse the rule line by line
    while($rule_string =~ /([^\n]+\n)?/g) {
        my $line = $1;

        # Need to find a rule_id before we can start
        if($line and $line =~ /^(?:(global|private)\s+)?rule\s+([a-zA-Z0-9_]+)(?:\s*:\s*([^{]*))?\s*({.*})?/) {
            chomp($line);
            $rule_id = $2;
            $rule_data->{$rule_id}->{modifier} = $1;
            $rule_data->{$rule_id}->{tags} = $3;
            # Make sure we don't set the rule_id to a YARA reserved word
            if($self->_check_reserved($rule_id, 'rule_id')) {
                carp("Cannot use reserved word as rule identifier: $rule_id");
                next;
            } elsif(!$self->_is_valid($rule_id, 'rule_id')) {
                # Or to an invalid one
                next;
            }

            $rule_data->{$rule_id}->{raw} = '';
            # If $4 exists, we have found a single line rule so add all the data to raw
            if($4) {
                $rule_data->{$rule_id}->{raw} = $4;
            }
        # Because their is no rule_id set we can't
        # add the line to the rule_data
        } elsif(!$rule_id) {
            next;
        # Now we have a rule_id, add the current
        # line to the rule_data ready for parsing
        } elsif($line) {
            $rule_data->{$rule_id}->{raw} .= $line;
        }
    }

    # Extract meta, strings and conditions from
    # each rule and add it to the hashref
    foreach my $rule (keys(%{$rule_data})) {
        # Tidy up the raw rule string to make sure we can easily parse this
        # line by line
        $rule_data->{$rule}->{raw} =~ s/(strings:|meta:|condition:)/\n\t$1\n\t\t/g;
        $rule_data->{$rule}->{raw} =~ s/}\s*$/\n}/;
        $self->_parse_meta($rule, $rule_data->{$rule}->{raw});
        $self->_parse_strings($rule, $rule_data->{$rule}->{raw});
        $self->_parse_condition($rule, $rule_data->{$rule}->{raw});
        if($rule_data->{$rule}->{modifier}) {
            $self->set_rule_modifier($rule, $rule_data->{$rule}->{modifier});
        }

        # If we found any tags add each one as an element
        # of an array to the tags key
        if($rule_data->{$rule}->{tags}) {
            foreach(split(/\s+/, $rule_data->{$rule}->{tags})) {
                $self->add_tag($rule, $_);
            }
        }
        # This is useful for testing
        if($self->{verbose}) {
            print "Added rule: $rule";
            if($self->{rules}->{$rule}->{tags} and scalar($self->{rules}->{$rule}->{tags}) > 0) {
                print " :";
                foreach my $tag (@{$self->{rules}->{$rule}->{tags}}) {
                    print " $tag";
                }
            }
            print "\n";
        }
    }
}

=item read_file ( $file )

Reads in a YARA rules file and any included files (if not disabled) and calls $self->parse() on the contents of the file.

=cut

sub read_file {
    my ($self, $file) = @_;
    my $rules = "";
    my @include_files;

    if($self->{verbose}) { print "Parsing file: $file\n" };

    open(RULESFILE, "<", $file) or die $!;
    # Loop through rules file and find all YARA rules
    while(<RULESFILE>) {
        # If we are including files, push to an array so we can
        # read them all in later
        if($self->{include} and /^include\s+"(.*?)"/) {
            push(@include_files, dirname($file) . "/" . $1);
        } elsif(!/^include\s+"(.*?)"/) {
            $rules .= $_;
        }
    }
    close(RULESFILE);

    $self->parse($rules);

    # Parse any include's we found earlier on
    foreach my $include_file (@include_files) {
        $self->read_file($include_file);
    }

}

# _parse_meta
# Extracts meta attributes from a YARA rule string and adds them to the rule hashref.

sub _parse_meta {
        my ($self, $rule_id, $raw) = @_;
        my $flag;

        # Parse the rule data line by line
    while($raw =~ /([^\n]+)\n?/g) {
        my $line = $1;

        # Once we find the meta tag set a flag
        # so that we know to start adding to
        # to the rule object
        if($line =~ /meta:/) {
            $flag = 1;
            next;
        }

        # When we get passed the meta section we should encounter
        # either a strings or condition section, if we find these
        # set the flag to 0 so we stop adding to the rule object
        if($flag and $line =~ /^\s*(?:strings:|condition:)\s*$/) {
            $flag = 0;
            next;
        }

        # Now we're in the meta section, so if we find a valid
        # meta attribute/value pair then add it to the rule object
        if($flag and $line =~ /^\s*(\S[^=\s]*)\s*=\s*(\S+.*)$/) {
            my $meta_name = $1;
            my $meta_val = $2;
            if($meta_val !~ /^(\d+|true|false)$/) {
                $meta_val =~ s/^\s*"//;
                $meta_val =~ s/"\s*$//;
            }
            $self->add_meta($rule_id, $meta_name, $meta_val);
        }
    }
}


# _parse_strings
# Extracts string attributes from a YARA rule string and adds them to the rule hashref.

sub _parse_strings {
    my ($self, $rule_id, $raw) = @_;
    my $flag;
    # Parse the rule data line by line
    while($raw =~ /([^\n]+)\n?/g) {
        my $line = $1;

        # Once we find the strings tag set a flag
        # so that we know to start adding to
        # to the rule object
        if($line =~ /strings:/) {
            $flag = 1;
            next;
        }

        # When we get passed the strings section we should encounter
        # either a meta or condition section, if we find these
        # set the flag to 0 so we stop adding to the rule object
        if($flag and $line =~ /^\s*(?:meta:|condition:)\s*$/) {
            $flag = 0;
            next;
        }

        # Now we're in the strings section, so if we find a valid
        # strings attribute/value pair then add it to the rule object
        if($flag and $line =~ /^\s*(\$[a-zA-Z0-9_]*)\s*=\s*((?:"|\/|{)\s*\S+.*(?:"|\/|}))\s*(.*)$/) {
            my $str_name = $1;
            my $str_val = $2;
            my $str_mods = $3;
            my $str_type = "text";
            # In YARA hex strings are bounded by {}
            if($str_val =~ /^{.*?}$/) {
                $str_type = "hex";
            # And regex are bounded by //
            } elsif($str_val =~ /^\/.*?\/$/) {
                $str_type = "regex";
            # Everything else should be a string.
            # I remove the quotes now for easier use throughout the module and re-add them when calling as_string
            } else {
                $str_val =~ s/^"//;
                $str_val =~ s/"$//;
            }
            if($str_name eq "\$") {
                $self->add_anonymous_string($rule_id, $str_val, $str_type);
            } else {
                $self->add_string($rule_id, $str_name, $str_val, $str_type);
            }
            if($str_mods) {
                foreach(split(/\s+/, $str_mods)) {
                    $self->add_string_modifier($rule_id, $str_name, $_)
                }
            }
        }
    }
}

# _parse_condition
# Extracts the condition from a YARA rule string and adds it to the rule hashref.

sub _parse_condition {
    my ($self, $rule_id, $raw) = @_;
    my $flag;
    my $condition = "";

    # Parse the rule data line by line
    while($raw =~ /([^\n]+)\n?/g) {
        my $line = $1;

        # Once we find the condition tag set a flag
        # so that we know to start adding to
        # to the rule object
        if($line =~ /condition:/) {
            $flag = 1;
            next;
        }

        # When we get passed the condition section we should encounter
        # either a meta or strings section (or EOR),  if we find these
        # set the flag to 0 so we stop adding to the rule object
        if($flag and $line =~ /^\s*(?:meta:|strings:)\s*$/) {
            $flag = 0;
            next;
        }

        # Now we're in the condition section, so if we find a valid
        # condition then append it to the condition string
        if($flag and $line =~ /^\s*(\S+.*)$/ and $line !~ /^\s*({|})\s*$/) {
            # To deal with multi-line conditions we check first then append
            # to the condition string til we're done before setting the 
            # condition below
            if(length($condition) == 0) {
                $condition = "$1\n";
            } else {
                $condition .= "\t\t$1\n";
            }
        }
    }
    # Remove any trailing new line and then set the condition
    chomp($condition);
    $self->set_condition($rule_id, $condition);
}

=item set_rule_modifier($rule_id, $modifier)

Set a modifier on a rule. The value for modifier must be one of the following strings:
    private
    global

If modifier is set to undef the current modifier (if any) will be removed.

=cut

sub set_rule_modifier {
    my ($self, $rule_id, $modifier) = @_;
    
    if($modifier) {
        # Their are only two valid rule modifiers, private and global
        # make sure we are only setting to these values, otherwise bail
        if($modifier =~ /^(?:private|global)$/) {
            $self->{rules}->{$rule_id}->{modifier} = $modifier;
        } else {
            carp("$rule_id: unable to set rule modifier to invalid value: $modifier");
        }
    } else {
        # If this is set to undef, assume the rule modifier requires deletion
        delete($self->{rules}->{$rule_id}->{modifier});
    }
}

=item set_condition($rule_id, $condition)

Sets the value of the condition to $condition.

=cut

sub set_condition {
    my ($self, $rule_id, $condition) = @_;
    my $flag = 1;

    if($condition) {
        # Make sure we are only setting the condition to something valid
        if($self->_check_reserved($condition, 'condition')) {
            carp("$rule_id: cannot set condition to a reserved word: $condition");
        } else {
            # Then set the condition directly
            $self->{rules}->{$rule_id}->{condition} = $condition;
        }
    } else {
        carp("$rule_id: can't set a null condition");
    }
}

=item add_tag($rule_id, $tag)

Adds a tag to the rule.

=cut

sub add_tag {
    my ($self, $rule_id, $tag) = @_;
    my $flag = 1;

    # Maybe not the most efficient, but I don't expect
    # the use of a large number of tags
    # Check to see that the tag is both valid, and not
    # already set. If either of these checks fails
    # set the flag to 0 and print an error.
    foreach(@{$self->{rules}->{$rule_id}->{tags}}) {
        if($_ eq $tag) {
            $flag = 0;
            carp("$rule_id: $tag already set.");
            last;
        } elsif($self->_check_reserved($tag, 'tag')) {
            $flag = 0;
            carp("$rule_id: cannot set tag to a reserved word: $tag");
            last;
        }
    }

    # If we didn't find any issues above, push the new tag to the tags array
    if($flag) {
        push(@{$self->{rules}->{$rule_id}->{tags}}, $tag);
    }
}

=item add_meta($rule_id, $meta_name, $meta_val)

Adds a meta name/value pair to the rule.

=cut

sub add_meta {
    my ($self, $rule_id, $meta_name, $meta_val) = @_;

    # Make sure the meta hash element exists
    if(!$self->{rules}->{$rule_id}->{meta}) {
        # If not, we need to tie a new hash to ensure meta order is maintained
        $self->{rules}->{$rule_id}->{meta_knot} = tie(%{$self->{rules}->{$rule_id}->{meta}}, 'Tie::IxHash');
    }
    # Check validity of meta name before adding it to the rule object
    if($self->_check_reserved($meta_name, 'meta')) {
        carp("$rule_id: $meta_name contains a reserved word, please try again");
    # Make sure we don't add duplicate meta names as this is invalid
    } elsif($self->{rules}->{$rule_id}->{meta}->{$meta_name}) {
        carp("$rule_id: $meta_name already set, select a new name or try modify_meta()");
    } else {
        $self->{rules}->{$rule_id}->{meta}->{$meta_name} = $meta_val;
    }
}

=item add_string_modifier($rule_id, $str_name, $modifier)

Set a modifier on a string. The value for the modifier must be one of the following strings:
    wide
    nocase
    ascii
    fullword

Use of the keyword 'all' will set all modifiers on a string.

=cut

sub add_string_modifier {
    my ($self, $rule_id, $str_name, $modifier) = @_;

    if($modifier) {
        # There are only four valid string modifiers so make sure we only add one of these
        if($modifier =~ /^(?:wide|nocase|ascii|fullword)$/) {
            push(@{$self->{rules}->{$rule_id}->{strings}->{$str_name}->{modifier}}, $modifier);
        # Unless we use the keyword 'all' in which case set all four string modifiers
        } elsif($modifier eq "all") {
            $self->{rules}->{$rule_id}->{strings}->{$str_name}->{modifier} = [ 'wide', 'ascii', 'nocase', 'fullword' ];
        } else {
            carp("$rule_id: unable to set string modifier to invalid value: $modifier");
        }
    } else {
        carp("$rule_id: cannot set undefined modifier");
    }
}

=item remove_string_modifier($rule_id, $str_name, $modifier)

Remove a modifier on a string. The value for the modifier must be one of the following strings:
    wide
    nocase
    ascii
    fullword

Use of the keyword 'all' will remove all modifiers from a string.

=cut

sub remove_string_modifier {
    my ($self, $rule_id, $str_name, $modifier) = @_;

    if($modifier) {
        # There are only four valid string modifiers so make sure we only both trying to remove these
        if($modifier =~ /^(?:wide|nocase|ascii|fullword)$/) {
            @{$self->{rules}->{$rule_id}->{strings}->{$str_name}->{modifier}} = grep { $_ ne $modifier } @{$self->{rules}->{$rule_id}->{strings}->{$str_name}->{modifier}};
        # Unless we use the keyword 'all' in which case remove all four string modifiers
        } elsif($modifier eq "all") {
            $self->{rules}->{$rule_id}->{strings}->{$str_name}->{modifier} = [];
        } else {
            carp("$rule_id: unabled to remove invalid modifier: $modifier");
        }
    } else {
        carp("$rule_id: cannot remove undefined modifier");
    }
}

=item add_anonymous_string($rule_id, $str_val, $str_type)

Allows the addition of anonymous strings

=cut

sub add_anonymous_string {
    my ($self, $rule_id, $str_val, $str_type) = @_;

    # Check if we've previously added strings
    if(!$self->{rules}->{$rule_id}->{strings}) {
        # If not, we need to tie a new hash to ensure string order is maintained
        $self->{rules}->{$rule_id}->{strings_knot} = tie(%{$self->{rules}->{$rule_id}->{strings}}, 'Tie::IxHash');
    }
    my $val = { value => $str_val, type => $str_type, modifier => [] };
    my $last_anon_string = undef;
    # So that we can add multiple anonymous strings as new hash elements
    # I am cheating and adding an extra $ for each new anon string
    # Here we find the latest anon string and then append a $ before
    # setting the value against this new string name
    foreach(keys(%{$self->{rules}->{$rule_id}->{strings}})) {
        if(/^\$+$/) {
            $last_anon_string = $_;
        }
    }
    $last_anon_string .= '$';
    $self->{rules}->{$rule_id}->{strings}->{$last_anon_string} = $val;
}

=item add_string($rule_id, $str_name, $str_val, $str_type)

Allows the addition of a new string name/value pair.

=cut

sub add_string {
    my ($self, $rule_id, $str_name, $str_val, $str_type) = @_;

    # Check if we've previously added strings
    if(!$self->{rules}->{$rule_id}->{strings}) {
        # If not, we need to tie a new hash to ensure string order is maintained
        $self->{rules}->{$rule_id}->{strings_knot} = tie(%{$self->{rules}->{$rule_id}->{strings}}, 'Tie::IxHash');
    }
    # Make sure we don't add duplicate strings as this is invalid
    if($self->{rules}->{$rule_id}->{strings}->{$str_name}) {
        carp("$rule_id: $str_name already set, pick a new name or try modify_string()");
    # Check validity of string before adding it to the rule object
    } elsif($self->_is_valid($str_name, 'string_name')) {
        my $val = { value => $str_val, type => $str_type, modifier => [] };
        $self->{rules}->{$rule_id}->{strings}->{$str_name} = $val;
    }
}

=item remove_tag($rule_id, $tag)

Removes a tag from the rule as identified by $tag.

=cut

sub remove_tag {
    my ($self, $rule_id, $tag) = @_;

    # Remove the tag from the tags array
    @{$self->{rules}->{$rule_id}->{tags}} = grep { $_ ne $tag } @{$self->{rules}->{$rule_id}->{tags}};
    # If their are no tags left, delete the tags hash element so we don't print a :
    if(scalar(@{$self->{rules}->{$rule_id}->{tags}} < 1)) {
        delete($self->{rules}->{$rule_id}->{tags});
    }
}

=item remove_meta($rule_id, $meta_name)

Removes a meta name/value pair as identified by $meta_name.

=cut

sub remove_meta {
    my ($self, $rule_id, $meta_name) = @_;

    # Just delete the hash element for the given meta name
    delete($self->{rules}->{$rule_id}->{meta}->{$meta_name});
}

=item remove_anonymous_string($rule_id, $str_val)

Removes an anonymous string with the value specified.

=cut

sub remove_anonymous_string {
    my ($self, $rule_id, $str_val) = @_;

    # Loop through all the strings to find anonymous strings
    foreach my $str_name (keys(%{$self->{rules}->{$rule_id}->{strings}})) {
        # Find the anonymous string with the correct value
        if($str_name =~ /^\$+$/ and $self->{rules}->{$rule_id}->{strings}->{$str_name}->{value} eq $str_val) {
            # Delete the hash element for the given string value then exit the loop
            delete($self->{rules}->{$rule_id}->{strings}->{$str_name});
            last;
        }
    }
}

=item remove_string($rule_id, $str_name)

Removes a string name/value pair, but only if it contains a single value.

=cut

sub remove_string {
    my ($self, $rule_id, $str_name) = @_;

    # Because their may be more than one anonymous string, bail at this point because we need the value for that string
    if($str_name eq '$') {
        carp("$rule_id: trying to remove anonymous string, use remove_anonymous_string() for this");
    } else {
        # Otherwise we can delete the hash element for the given string name
        delete($self->{rules}->{$rule_id}->{strings}->{$str_name});
    }
}

=item modify_meta($rule_id, $meta_name, $meta_val)

Modifies the value of $meta_name and sets it to $meta_val.

=cut

sub modify_meta {
    my ($self, $rule_id, $meta_name, $meta_val) = @_;

    # Check meta name already exists
    if(!$self->{rules}->{$rule_id}->{meta}->{$meta_name}) {
        carp("$rule_id: $meta_name not set, select the correct name or try add_meta()");
    } else {
        # If it does, set the new value
        $self->{rules}->{$rule_id}->{meta}->{$meta_name} = $meta_val;
    }
}

=item modify_string($rule_id, $str_name, $str_val)

Modifies the value of a string name/value pair, but only if it contains a single value.

Sets the value of $str_name to $str_val.

=cut

sub modify_string {
    my ($self, $rule_id, $str_name, $str_val) = @_;

    # Can't modify an anonymous string without knowing the current value
    if($str_name =~ /^\$+$/) {
        carp("$rule_id: cannot modify value of anonymous string as their may be multiple values and I don't know which one to modify.");
    # Can't modify a string that doesn't exist
    } elsif(!$self->{rules}->{$rule_id}->{strings}->{$str_name}) {
        carp("$rule_id: cannot modify $str_name as it does not exist, try add_string().");
    } else {
        # Set the new value directly
        $self->{rules}->{$rule_id}->{strings}->{$str_name}->{value} = $str_val;
    }
}

# _rule_as_string
# Parses the rule hash(es) contained within $self or if a $rule_id is provided parses that rule.
# Returns a string of the rule printed in YARA format.

sub _rule_as_string {
    my ($self, $rule_id) = @_;
    my $ret = '';
    my @missing;

    # Check for condition, if not the rule is invalid
    if(!exists($self->{rules}->{$rule_id}->{condition})) {
        carp("$rule_id does not contain a condition.");
    } else {
        if($self->{rules}->{$rule_id}->{modifier}) {
            $ret .= $self->{rules}->{$rule_id}->{modifier} . " ";
        }

        $ret .= "rule $rule_id";

        # If tags are set, add a : after the rule_id and then space separate each tag
        if($self->{rules}->{$rule_id}->{tags}) {
            $ret .= " :";
            foreach my $tag (@{$self->{rules}->{$rule_id}->{tags}}) {
                $ret .= " $tag";
            }
        }

        # Now add the opening brace on a new line
        $ret .= "\n{";

        # If their is a meta element, loop through each entry and add to the rule string
        if($self->{rules}->{$rule_id}->{meta}) {
            $ret .= "\n";
            $ret .= "\tmeta:\n";
            foreach my $meta_name (keys(%{$self->{rules}->{$rule_id}->{meta}})) {
                my $meta_val;
                if($self->{rules}->{$rule_id}->{meta}->{$meta_name} =~ /^(\d+|true|false)$/) {
                    $meta_val = $self->{rules}->{$rule_id}->{meta}->{$meta_name};
                } else {
                    $meta_val = "\"$self->{rules}->{$rule_id}->{meta}->{$meta_name}\"";
                }
                $ret .= "\t\t$meta_name = $meta_val\n";
            }
        }

        # If their is a strings element, loop through each entry and add to the rule string
        if($self->{rules}->{$rule_id}->{strings}) {
            $ret .= "\n";
            $ret .= "\tstrings:\n";
            foreach my $string_name (keys(%{$self->{rules}->{$rule_id}->{strings}})) {
                my $display_name = $string_name;
                my $display_val;
                if($string_name =~ /^\$+$/) {
                    $display_name = '$';
                }
                if($self->{rules}->{$rule_id}->{strings}->{$string_name}->{type} eq "text") {
                    $display_val = "\"$self->{rules}->{$rule_id}->{strings}->{$string_name}->{value}\"";
                    foreach my $str_mod (@{$self->{rules}->{$rule_id}->{strings}->{$string_name}->{modifier}}) {
                        $display_val .= " $str_mod";
                    }
                } elsif($self->{rules}->{$rule_id}->{strings}->{$string_name}->{type} eq "hex") {
                    $display_val = $self->{rules}->{$rule_id}->{strings}->{$string_name}->{value};
                } elsif($self->{rules}->{$rule_id}->{strings}->{$string_name}->{type} eq "regex") {
                    $display_val = $self->{rules}->{$rule_id}->{strings}->{$string_name}->{value};
                }
                $ret .= "\t\t$display_name = $display_val\n";
            }
        }

        # Add the condition and closing brace
        $ret .= "\n";
        $ret .= "\tcondition:\n";
        $ret .= "\t\t$self->{rules}->{$rule_id}->{condition}\n";
        $ret .= "}";
    }

    return $ret;
}

=item as_string()

Can take zero or one argument. With no arugments this return all rules within the rule hashref as a string.

=over 4

=item as_string($rule_id)

Extracts a single rule from the hashref and returns it as a string value.

=cut

sub as_string {
    my ($self, $rule_id) = @_;
    my $ret = '';

    # Check to see if their is a rule_id and return that rule as a string
    if($rule_id) {
        $ret = $self->_rule_as_string($rule_id);
    } else {
        # Otherwise loop through the hash and return all rules as a string
        foreach my $rule_id (keys(%{$self->{rules}})) { 
            $ret .= $self->_rule_as_string($rule_id) . "\n\n";
        }
        chomp($ret);
    }

    return $ret;
}

=back

=item get_referenced_rule($rule_id)

Check to see if $rule_id references any other rules and return any matched rule ID's as an array.

=cut

sub get_referenced_rule {
    my ($self, $rule_id) = @_;
    my @ret;

    # For each rule, check to see if the rule_id passed is contained 
    # within the rule's condition, if so add it to an array to be returned
    map { if (exists($self->{rules}->{$_})) { push(@ret, $_); } } split(/\s+/, $self->{rules}->{$rule_id}->{condition});

    return @ret;
}

=item position_rule($rule_id, $position, $relative_rule_id)

Position a rule before or after another rule where:

    $rule_id is the rule_id of the rule to be moved
    $position is either before or after
    $relative_rule_id is the rule_id of the rule to move this rule around

=cut

sub position_rule {
    my ($self, $rule_id, $position, $relative_rule_id) = @_;
    my $rule_found = 0;
    my $relative_rule_found = 0;

    # Make sure we pick a valid movement (before or after)
    if($position !~ /^(before|after)$/) {
        carp("$rule_id: position must be set to before or after $position");
    # Make sure the rule_id requested for movement exists
    } elsif(!$self->{rules}->{$rule_id}) {
        carp("Cannot position rule that does not exist: $rule_id");
    # Make sure the relative_rule_id to which the rule_id should be moved before or after exists
    } elsif(!$self->{rules}->{$relative_rule_id}) {
        carp("Cannot position around rule that does not exist: $relative_rule_id");
    } else {
        if($self->{verbose}) {
            print "Moving $rule_id $position $relative_rule_id\n";
        }
        # Create an array with the current order of keys
        my @new_order = $self->{rules_knot}->Keys;
        # Get the current position of the rule_id and relative_rule_id
        my $rule_pos = $self->{rules_knot}->Indices($rule_id);
        my $relative_rule_pos = $self->{rules_knot}->Indices($relative_rule_id);
        # Adjust the position accordingly
        if($position eq "after" and $rule_pos > $relative_rule_pos) {
            $rule_pos++;
        } elsif($position eq "before" and $rule_pos < $relative_rule_pos) {
            $relative_rule_pos--;
        }
        # Reorder within the array then set the order using Tie:IxHash->Reorder
        splice(@new_order, $relative_rule_pos, 0, splice(@new_order, $rule_pos, 1));
        $self->{rules_knot}->Reorder(@new_order);
    }
}

1;

__END__

=back

=head1 DESCRIPTION

Module for parsing and generating YARA rules.

=head1 TODO

Add error checking for the validity of regex and hex strings.

Add methods to allow the addition of comments to each element of a rule.

Fix the parser to extract rather than strip comments from rules passed as strings or form a file and assign them to the appropriate element of the rule.

Add methods to allow the re-ordering of strings and meta elements.

=head1 SEE ALSO

For information about YARA see: http://code.google.com/p/yara-project/

=head1 AUTHOR

Leigh Thompson, E<lt>moofu at cpan.orgE<gt>

=head1 DEPENDENCIES

Carp, Tie::IxHash, File::Basename

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Leigh Thompson

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

=over 4

http://www.apache.org/licenses/LICENSE-2.0

=back

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

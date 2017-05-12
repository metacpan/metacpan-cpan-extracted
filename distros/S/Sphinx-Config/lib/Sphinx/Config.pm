package Sphinx::Config;

use warnings;
use strict;
use Carp qw/croak/;
use Storable qw/dclone/;
use List::MoreUtils qw/firstidx/;

=head1 NAME

Sphinx::Config - Sphinx search engine configuration file read/modify/write

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    use Sphinx::Config;

    my $c = Sphinx::Config->new();
    $c->parse($filename);
    $path = $c->get('index', 'test1', 'path');
    $c->set('index', 'test1', 'path', $path);
    $c->save($filename);
    ...

=head1 CONSTRUCTOR

=head2 new

    $c = Sphinx::Config->new;

=cut

sub new {
    my $class = shift;

    bless { _bestow => 1 }, ref($class) || $class;
}

=head2 preserve_inheritance

    $c->preserve_inheritance(0);
    $c->preserve_inheritance(1);
    $pi = $c->preserve_inheritance(1);

Set/get the current behaviour for preserving inherited values.  When
set to a non-zero value (the default), if a value is set in a parent
section, then it is automatically inherited by any child sections, and
when the configuration file is saved, values that are implicit through
inheritance are not shown.  When set to zero, each section is
considered standalone and a complete set of values is shown in the
saved file.

This flag may be enabled and disabled selectively for calls to set() and
save().

=cut

sub preserve_inheritance {
    my $self = shift;
    $self->{_bestow} = shift if @_;

    return $self->{_bestow};
}

=head1 METHODS

=head2 parse

    $c->parse($filename)

Parse the given Sphinx configuration file.

Dies on errors.

=cut

sub parse {
    my ($self, $filename) = @_;

    die "Sphinx::Config: $filename does not exist" unless -f $filename;

    my $fh;
    open($fh, "<$filename") or die "Sphinx::Config: cannot open $filename: $!";
    $self->{_file} = [ <$fh> ];
    close( $fh );
    $self->{_filename} = $filename;
    $self->_parse_file;
    return;
}

=head2 parse_string

    $c->parse_string( $string );

Parse the Sphinx configuration in the given string.

Dies on errors.

=cut

sub parse_string {
    my( $self, $string ) = @_;
    # split string on newlines, keeping the newlines in-place
    $self->{_file} = [ split /^/m, $string ];
    delete $self->{_filename};
    # _filename is used by _parse_file in its error messages
    local $self->{_filename} = "STRING";
    $self->_parse_file;
    return;
}

sub _parse_file
{
    my( $self ) = @_;

    my $state = 'outer';
    my $seq = "section";
    my $max = @{ $self->{_file} };
    my $current;
    my @config;

    foreach( my $line = 0; $line < $max ; $line++ ) {
        my $first = $line;
        my $input = $self->{_file}[ $line ];
	chomp $input;
	# discard comments
	$input =~ s/\s*\#.*//o;
        # merge continued lines
        while ($input =~ s!\\\s*$!!s and $line < $max ) {
            $line++;
            my $new = $self->{_file}[ $line ];
            chomp( $new );
            # We are folding all space up.  XXX- How does Sphinx handle this?
            if( $input =~ / $/ ) {
                $new =~ s/^\s+//;
            } else {
                $new =~ s/^\s+/ /;
	}
            $input .= $new;
    	}
        # handling this virtual line
	while ($input) {
	    if ($state eq 'outer') {
		# split into tokens, fully consuming input line
		my @tokens = split(/\s+/, $input);
		$input = "";
                while( @tokens ) {
                    my $tok = shift @tokens;
                    next unless length $tok;
		    if ($seq eq "section") {
			if ($tok =~ m/^(?:source|index)$/o) {
                            $current = { _type => $tok, _lines => [ $first ] };
			    push(@config, $current);
			    $seq = "name";
			}
			elsif ($tok =~ m/^(?:indexer|searchd|search|common)$/o) {
                            $current = { _type => $tok, _lines => [ $first ] };
			    push(@config, $current);
			    $seq = "openblock";
			}
			else {
                            die "Sphinx::Config: $self->{_filename}:$first: Expected section type, got '$tok'";
			}
		    }
		    elsif ($seq eq "name") {
			$current->{_name} = $tok;
			$seq = "openorinherit";
		    }
		    elsif ($seq eq "openorinherit") {
			if ($tok eq ':') {
			    $seq = "inherit";
			}
			else {
			    unshift(@tokens, $tok);
			    $seq = "openblock";
			}
		    }
		    elsif ($seq eq "inherit") {
                        die "Sphinx::Config:: $self->{_filename}:$line: a section may not inherit from itself"
                            if $tok eq $current->{_name};
                        unless( $self->_setup_inherit( $current, $tok, \@config ) ) {
                            die "Sphinx::Config: $self->{_filename}:$first: Base section '$tok' does not exist";
                        } 
			$seq = "openblock";
		    }
		    elsif ($seq eq "openblock") {
                        die "Sphinx::Config: $self->{_filename}:$first: expected '{'" unless $tok eq "{";
			$seq = "section";
			$state = "inner";
			# return any leftovers
			$input = join(" ", @tokens);
		    }
		}
	    }
	    elsif ($state eq "inner") {
                my $pos = [ $first, $line ];
		if ($input =~ s/^\s*\}//o) {
		    $state = "outer";
                    $current->{_lines}[1] = $line;
		    $current = undef;
		}
		elsif ($input =~ s/^\s*([\w]+)\s*=\s*(.*)\s*$//o) {
		    my $k = $1;
		    my $v = $2;
		    if (exists($current->{_data}->{$k}) && ! $current->{_inherited}->{$k}) {
			if (ref($current->{_data}->{$k}) eq 'ARRAY') {
			    # append to existing array
			    push(@{$current->{_data}->{$k}}, $v);
			}
			else {
			    # promote to array
			    $current->{_data}->{$k} = [ $current->{_data}->{$k}, $v ];
			}
                        push(@{$current->{_pos}->{$k}}, $pos);
		    }
		    else {
			# first or simple value
			$current->{_data}->{$k} = $v;
                        $current->{_pos}->{$k} = [$pos];
			$current->{_inherited}->{$k} = 0;
		    }
		}
		elsif ($input =~ s/^\s+$//o) {
		    # carry on
		}
		else {
                    die "Sphinx::Config: $self->{_filename}:$line: expected name=value pair or end of section, got '$input'";
		}
	    }
	}	
    }

    $self->{_config} = \@config;
    my %keys;
    for (@config) {
	$keys{$_->{_type} . ($_->{_name}?(' ' . $_->{_name}):'')} = $_;
    }

    $self->{_keys} = \%keys;
    return;
}


# Find a section.  
# Either in $config (at parse-time) or in {_keys}
sub _find_section
{
    my( $self, $type, $name, $config ) = @_;
    if( $config ) {
        my $c;
        for (my $i = 0; $i <= $#$config; $i++) {
            $c = $config->[$i];
            next unless $c->{_name};    # ignore searchd, indexer sections
            if( $c->{_name} eq $name && $c->{_type} eq $type ) {
                return $c;
            }
        }
    }
    else {
        my $key = $type;
        $key .= " $name" if $name;
        return $self->{_keys}{$key};
    }
}

# setup (or change) the inheritance of a section
# returns true on success
# returns undef if it can't find the base section
sub _setup_inherit
{
    my( $self, $current, $base_name, $config ) = @_;

    my $base = $self->_find_section( $current->{_type}, $base_name, $config );
    
    return unless defined $base && $base != $current;

    my $out = $current->{_data} ||= {};

    if( $current->{_inherit} ) {
        # Delete all inherited variables
        my $I = $current->{_inherited};
        while( my( $f, $v ) = each %$I ) {
            next unless $v;
            delete $out->{$f};
        }
        $current->{_inherited} = {};
    }

    $current->{_inherit} = $base_name;
    # XXX - check that {_children} doesn't already have {_name}
    push(@{$base->{_children} ||= []}, $current->{_name});

    # copy new values over
    my $in = dclone($base->{_data} || {});
    while( my( $f, $v ) = each %$in ) {
        next if exists $out->{$f};
        $out->{$f} = $v;
        $current->{_inherited}{ $f } = 1;
    }
    return 1;
}




=head2 config

    $config = $c->config;

Get the parsed configuration data as an array of hashes, where each entry in the
array represents one section of the configuration, in the order as parsed or
constructed.

Each section is described by a hash with the following keys:

=over 4

=item * _type A mandatory key describing the section type (index, searchd etc)

=item * _name The name of the section, where applicable

=item * _inherited The name of the parent section, where applicable

=item * _data A hash containing the name/value pairs which hold the
configuration data for the section.  All values are simple data
elements, except where the same key can appear multiple times in the
configuration file with different values (such as in attribute
declarations), in which case the value is an array ref.

=item * _inherited A hash describing which data values have been inherited

=back

=cut

sub config {
    return shift->{_config};
}

=head2 get

    $value = $c->get($type, $name, $varname)
    $value = $c->get($type, $name)

Get the value of a configuration parameter.

If $varname is specified, the value of the named parameter from the section
identified by the type and name is returned as a scalar.  Otherwise, the hash containing all key/value pairs from the section is returned.

$name may be undef for sections that do not require a name (e.g. searchd,
indexer, search).

If the section cannot be found or the named parameter does not exist, undef is
returned.

=cut

sub get {
    my ($self, $type, $name, $var) = @_;

    my $key = $type;
    $key .= ' ' . $name if $name;

    my $current = $self->{_keys}->{$key};
    return undef unless $current;
    if ($var) {
	if ($var =~ m/^_/) {
	    return $current->{$var};
	}
	else {
	    return $current->{_data}->{$var};
	}
    }
    
    return $current->{_data};
}

=head2 set

    $c->set($type, $name, $varname, $value)
    $c->set($type, $name, \%values)
    $c->set($type, $name, undef(), $base_name)
    $c->set($type, $name, \%values, $base_name)

Set the value or values of a section in the configuration.

If varname is given, then the single parameter of that name in the
given section is set to the specified value.  If the value is an
array, multiple entries will be created in the output file for the
same key.

If a hash of name/value pairs is given, then any existing values are replaced
with the given hash.

    $c->set('source', , $name, \%values);

If the section does not currently exist, a new one is appended.

Set C<$name> to C<undef> to set variables in an C<indexer>, C<searchd> or
C<search> section.

    $c->set('indexer', undef, 'listen', $port);
    $c->set('search', undef, \%values );

To change the section's inheritance, set $value to undef and specify a value
in the 4th parameter.

    $c->set('source', 'src1', undef(), 'base2');

You this may be combined with a hash variable :

    $c->set('source', 'src1', \%values, 'base_source');

To delete a name/value pair, set $value to undef.

    $c->set('source', 'src1', 'sql_query_pre', undef());
    $c->set('source', 'src1', 'sql_query_pre');

Returns the hash containing the current data values for the given section.

See L<preserve_inheritance> for a description of how inherited values are handled.

=cut

sub set {
    my ($self, $type, $name, $var, $value) = @_;

    my $key = $type;
    $key .= ' ' . $name if $name;

    if (! $self->{_keys}->{$key}) {
        # append to configuration
	my $current = { _type => $type, _new => 1 };
	$current->{_name} = $name if $name;
	push(@{$self->{_config}}, $current);
	$self->{_keys}->{$key} = $current;
        # new lines will be created by as_string()
        # set inheritance at the same time
    }

    if( not defined $var and $value ) {
        # change inheritance
        unless( $self->_change_inherit( $key, $value ) ) {
            croak "Sphinx::Config: Unable to find $name $value for inheritance";
        }
    }
    elsif (! ref($var)) {
	if (! defined($var)) {
            # delete section
	    if (my $entry = delete $self->{_keys}->{$key}) {
		my $i = firstidx { $_ == $entry } @{$self->{_config}};
                if( $i >= 0 ) {
                    # delete config
                    splice(@{$self->{_config}}, $i, 1);
                    # delete from file
                    $self->_clear_lines( $entry->{_lines} );
                }
	    }
	}
	elsif ($var =~ m/^_/) {
            # This seems to be mainly useful for unit tests
	    if (defined $value) {
		$self->{_keys}->{$key}->{$var} = $value;
	    }
	    else {
		delete $self->{_keys}->{$key}->{$var};
	    }
            # _keys belong to us : no inheritance, not written to config file
	}
	else {
            $self->_set( $type, $name, $var, $value );
	}
    }
    elsif (ref($var) eq "HASH") {
        $self->_redefine( $type, $name, $var );
        if( $value ) {
            # Change inheritance
            unless( $self->_change_inherit( $key, $value ) ) {
                croak "Sphinx::Config: Unable to find $type $value for inheritance";
            }
        }
    }
    else {
        croak "Must provide variable name or hash, not " . ref($var);
    }

    return $self->{_keys}->{$key}->{_data};
}

# Set or remove a variable.  Deals with inheritance
sub _set
{
    my( $self, $type, $name, $var, $value ) = @_;

    my $key = $type;
    $key .= " $name" if $name;

	    if (defined $value) {
		$self->{_keys}->{$key}->{_data}->{$var} = $value;
        $self->_set_var_lines( $key, $var, $value );
	    }
	    else {
		delete $self->{_keys}->{$key}->{_data}->{$var};
        $self->_clear_var_lines( $key, $var );
	    }
    if( $self->{_keys}{$key}{_inherit} ) {
	    $self->{_keys}->{$key}->{_inherited}->{$var} = 0;
    }

	    for my $child (@{$self->{_keys}->{$key}->{_children} || []}) {
        my $ckey = join ' ', $type, $child;
        my $c = $self->{_keys}->{$ckey} or next;
		if ($self->{_bestow}) {
		    if ($c->{_inherited}->{$var}) {
			if (defined $value) {
			    $c->{_data}->{$var} = $value;
			}
			else {
			    delete $c->{_data}->{$var};
			}
		    }
		}
		else {
		    $c->{_inherited}->{$var} = 0;
            $self->_set_var_lines( $ckey, $var, $c->{_data}{$var} );
		}
	    }
}

# Completely redefine a section
sub _redefine {
    my( $self, $type, $name, $var ) = @_;
    
    my $key = $type;
    $key .= " $name" if $name;
    my $section = $self->{_keys}{$key};

    $var = dclone $var;
    # Get a list of variables that currently exist
    my @have = keys %{ $section->{_data} };
    my %had;
    @had{ @have } = (1) x @have;
    # Set new values
    foreach my $sk ( keys %$var ) {
        $self->_set( $type, $name, $sk, $var->{$sk} );
        delete $had{ $sk };
    }
    # Delete any remaining non-inherited values
    foreach my $sk ( keys %had ) {
        next if $section->{_inherited}{$sk};
        $self->_set( $type, $name, $sk );
    }
}


# Clear all lines between $pos->[0] and $pos->[1], inclusive
sub _clear_lines {
    my( $self, $pos ) = @_;
    for( my $line= $pos->[0]; $line <= $pos->[1]; $line++ ) {
        $self->{_file}[$line] = undef;
	}
}

# Clear all lines associated with a variable
sub _clear_var_lines {
    my( $self, $key, $var ) = @_;
    foreach my $pos ( @{ $self->{_keys}{$key}{_pos}{$var} } ) {
        $self->_clear_lines( $pos );
    }
}

# Append a variable to a section
sub _append_var_lines {
    my( $self, $key, $var, $value ) = @_;
    my $section = $self->{_keys}{ $key };

    # find last variable
    my( $last, $last_var, $output );
    foreach my $var ( keys %{ $section->{_pos} } ) {
        foreach my $pos ( @{ $section->{_pos}{$var} } ) {
            if( not $last or $pos->[1] > $last->[1] ) {
                $last_var = $var;
                $last = $pos
		}
		}
	    }
    # adding to an empty section?
    unless( $last ) {
        $last = $section->{_lines};
        $output = $self->_var_as_string( $var, $value );
    }
    else {
        $output = $self->_get_var_lines( $last );
        # change the key
        $output =~ s/$last_var(\s*=)/$var$1/;
        # change the value(s)
        $output = $self->_set_var_value( $output, $var, $value );
	}
    $section->{_append}{$var} = $output;
}

sub _set_var_value {
    my( $self, $output, $var, $value ) = @_;
    unless( ref $value ) {
        $output =~ s/($var\s*=\s*)(.+)$/$1$value\n/s;
    }
    else {
        my $line = $output;
        $output = '';
        foreach my $v ( @$value ) {
            $output .= $self->_set_var_value( $line, $var, $v );
        }
    }
    return $output;
}

# Convert a [min,max] into a string that may be modified
sub _get_var_lines {
    my( $self, $pos ) = @_;
    my @text;
    for( my $line= $pos->[0] ; $line <= $pos->[1] ; $line++ ) {
        push @text, $self->{_file}[$line]||'';
    }
    return join '', @text;
}

# Change the line(s) associated with a variable
sub _set_var_lines {
    my( $self, $key, $var, $value ) = @_;

    my $section = $self->{_keys}{ $key };
    croak "Can't find section $key" unless $section;

    # New variable...
    unless( $section->{_pos}{ $var } ) {
        # ... in a new section: generated by as_string
        return if $section->{_new};
    
        $self->_append_var_lines( $key, $var, $value );
        return;
    }

    # build one line based on the first instance
    my $pos = $section->{_pos}{$var}[0];
    my $input = $self->_get_var_lines( $pos );
    # modify the line
    my $output = $self->_set_var_value( $input, $var, $value );
    # clear every other instance
    $self->_clear_var_lines( $key, $var );
    # set the new line
    $self->{_file}[$pos->[0]] = $output;
    # only one pos, on only one line.  Yes this line could contain \n, but
    # and this will cause problems
    $pos->[1] = $pos->[0];
    $section->{_pos}{$var} = [ $pos ];
    return;
}

# Change the inheritance of a section
sub _set_inherit_lines {
    my( $self, $key, $base_name, $was ) = @_;

    my $section = $self->{_keys}{ $key };
    croak "Can't find section $key" unless $section;
    return 1 if $section->{_new};

    my $file = $self->{_file};
    my $pos  = $section->{_lines};
    my $done;
    for( my $line=$pos->[0]; $line <= $pos->[1]; $line++ ) {
        next unless defined $file->[$line];
        if( $was ) {
            if( ($file->[$line] =~ s/(:\s*)$was/$1$base_name/ or
                      $file->[$line] =~ s/^(\s*)$was(\s*(\{|\Z))/$1$base_name$2/ ) ) {
                return 1;
            }
        }
        elsif( $file->[$line] =~ s/\{/$base_name {/ ) {
            return 1;
        }
    }
    die "Can't find where to put the base name in ", join '', 
                @{ $file }[ $pos->[0] .. $pos->[1] ];
}

sub _change_inherit {
    my( $self, $key, $base_name ) = @_;
    my $section = $self->{_keys}{$key};
    my $was = $section->{_inherit};
    return unless $self->_setup_inherit( $section, $base_name );
    return $self->_set_inherit_lines( $key, $base_name, $was );
}

=head2 save

    $c->save
    $c->save($filename, $comment)

Save the configuration to a file.  The currently opened file is used if not
specified.

The comment is inserted literally, so each line should begin with '#'.

See L<preserve_inheritance> for a description of how inherited blocks are handled.

=cut

sub save {
    my ($self, $filename, $comment) = @_;

    if( not $filename and not $self->{_filename} ) {
        croak "Sphinx::Config: Please to specify the file to save to";
    }

    $filename ||= $self->{_filename};

    my $fh;
    open($fh, ">$filename") or croak "Sphinx::Config: Cannot open $filename for writing";
    print $fh $self->as_string($comment);
    close($fh);
}



=head2 as_string

    $s = $c->as_string
    $s = $c->as_string($comment)

Returns the configuration as a string, optionally with a comment prepended.

The comment is inserted literally, so each line should begin with '#'.

An effort has been made to make the configuration round-trip safe.  That is,
any formating or comments in the original should also appear as-is in the
generated configuration.  New sections are added at the end of the
configuration with an 8 space indent.

New variables added to existing sections are handled as follows:

=over 4

=item *

If you add a new variable to an existing section, it is added at the end of
the section, using the whitespace of the last existing variable.

Given:

    index foo {
        biff= bof
        # ...
    }

and you add C<honk> with the value C<bonk>, you will end up with:

    index foo {
        biff= bof
        # ...
        honk= bonk
    }

=item *

If you have a comment that looks a bit like the default or commented out
variable, the new value is added after the comment.

Given:

    index foo {
        ....
        # honk=foo
        # more details
    }

and you add C<honk> with the value C<bonk>, you will end up with:

    index foo {
        ....
        # honk=foo
        honk = bonk
        # more details
    }

=back

=cut

sub as_string {
    my ($self, $comment) = @_;

    # By using a copy, ->as_string can be called multiple times, even
    # if we append variables to a section.  Otherwise the new variables
    # would be added multiple times
    if (! $self->{_file} || ! @{$self->{_file}}) {
        return $self->as_string_new($comment);
    }
    my $file = [@{ $self->{_file} }];

    # Find new sections and variables
    my @todo;
    foreach my $section ( @{ $self->{_config} } ) {
        unless( $section->{_lines} ) {
            push @todo, $section;
            next;
        }
        if( $section->{_append} ) {
            my $A = { %{ $section->{_append} } };
            my $pos = $section->{_lines};
            LINE:
            for( my $line = $pos->[0] ; $line <= $pos->[1] ; $line++ ) {
                foreach my $var ( keys %$A ) {
                    next unless $file->[$line] =~ /(\s*)#\s*$var/;
                    my $prefix = $1;
                    my $output = delete $A->{$var};
                    $output =~ s/^\s+//;
                    $file->[$line] .= "$prefix$output";
                    next LINE;
                }
            }
            if( %$A ) {
                my $add = join '', values %$A;
                $DB::single = 1;
                $file->[ $pos->[1] ] =~ s/}/$add}/;
            }
        }
    }
    
    # Build a config string
    my $s = $comment ? "$comment\n" : "";
    foreach my $line ( @$file ) {
        next unless defined $line;
        $s .= $line;
    }

    # Append new sections
    for my $c (@todo) {
        $s .= "\n" if $s =~ /}$/;
	$s .= $c->{_type} . ($c->{_name} ? (" " . $c->{_name}) : '');
	my $data = dclone($c->{_data});
	if ($c->{_inherit} && $self->{_bestow}) {
	    $s .= " : " . $c->{_inherit};
	    # my $base = $self->get($c->{_type}, $c->{_inherit});
	}
	my $section = " {\n";
	for my $k (sort keys %$data) {
	    next if $self->{_bestow} && $c->{_inherited}->{$k};
            $section .= $self->_var_as_string( $k, $data->{$k} );
	}
	$s .= $section . "}\n";
    }

    return $s;
}

sub _var_as_string
{
    my( $self, $k, $value ) = @_;
    my $section = '';
    if ( ref($value) eq 'ARRAY' ) {
        for my $v (@$value ) {
            $section .= $self->_var_as_string( $k, $v );
        }
    }
    else {
        $section .= '        ' . $k . ' = ' . $value . "\n";
    }
    return $section;
}

=head2 as_string_new

    $s = $c->as_string_new
    $s = $c->as_string_new($comment)

Returns the configuration as a string, optionally with a comment prepended,
without attempting to preserve formatting from the original file.

The comment is inserted literally, so each line should begin with '#'.

=cut

sub as_string_new {
    my ($self, $comment) = @_;

    my $s = $comment ? "$comment\n" : "";
    for my $c (@{$self->{_config}}) {
	$s .= $c->{_type} . ($c->{_name} ? (" " . $c->{_name}) : '');
	my $data = dclone($c->{_data});
	if ($c->{_inherit} && $self->{_bestow}) {
	    $s .= " : " . $c->{_inherit};
	    my $base = $self->get($c->{_type}, $c->{_inherit});
	}
	my $section = " {\n";
	for my $k (sort keys %$data) {
	    next if $self->{_bestow} && $c->{_inherited}->{$k};
	    if (ref($data->{$k}) eq 'ARRAY') {
		for my $v (@{$data->{$k}}) {
		    $section .= '        ' . $k . ' = ' . $v . "\n";
		}
	    }
	    else {
		$section .= '        ' . $k . ' = ' . $data->{$k} . "\n";
	    }
	}
	$s .= $section . "}\n";
    }

    return $s;
}

=head1 SEE ALSO

L<Sphinx::Search>

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sphinx-config at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sphinx-Config>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sphinx::Config

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sphinx-Config>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sphinx-Config>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sphinx-Config>

=item * Search CPAN

L<http://search.cpan.org/dist/Sphinx-Config>

=back

=head1 ACKNOWLEDGEMENTS

Philip Gwyn contributed the patch to preserve round-trip formatting,
which was a significant chunk of work.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sphinx::Config

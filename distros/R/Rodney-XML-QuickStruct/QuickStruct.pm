package Rodney::XML::QuickStruct;

#QuickStruct.pm,v 1.1 2002/04/17 22:05:21 rbroom Exp

use HTML::SimpleParse;

use strict;

use vars (
    '@Errors',  # Used for error handling under the proceedural interface.
    '$VERSION', # The version number of this module.
);

# Some funny business here to support either mode of RCS that gets used to check
# this file out.
$VERSION = '1.1';
$VERSION =~ s/^\$Revision:\s//;
$VERSION =~ s/\s\$$//;


# The numbers don't currently mean anything. But it seems like they someday
# could.
my %KNOWN_DATA_TYPES = (
    hash => 3,
    list => 2,
    'scalar' => 1,
);


=pod

=head1 NAME

Rodney::XML::QuickStruct - Quick Perl data structures from XML.


=head1 VERSION

1.1

Please note, this API is currently beta software. I've tested it to my deisgns,
but I haven't had input from any other users, yet. If you have comments or other
input, please send them to me: Rodney Broom <perl@rbroom.com>.


=head1 SYNOPSIS


    # Setup:
    use Rodney::XML::QuickStruct;

    %tag_map = (
        person   => 'list',
        hobby    => 'list',
        name     => 'scalar',
        age      => 'scalar',
    );


    # Then:
    $parser = Rodney::XML::QuickStruct->new;
    $data_struct = $parser->parse_file($xml_file, %tag_map);

    # Or:
    $data_struct = Rodney::XML::QuickStruct::parse_file($xml_file, %tag_map);


Be sure to see the L<EXAMPLES> section.


=head1 DESCRIPTION

This API provides a quick and easy way to get XML-like markup into a Perl data
structure. This API isn't intended to be terribly powerful, or at all
extendable, but it I<is> easy. Also, it's pure Perl so it doesn't require
installing any of the usual Perl XML modules.


This API provides both an OO interface and a function interface. My preference
is the OO interface, but the function interface is probably what you'll want
since it's a touch simpler to get the job done. It should be noted that we let
you use which ever interface you like, but that the two do not share
information. For example, if you have an error recorded in your C<$parser>
object, it will only be available through that object and not via the function
interface. So this snippet will always C<die()>, without an error message.

    $data_struct = $parser->parse_file($bad_file_name);
    die Rodney::XML::QuickStruct::error() unless $data_struct;



=cut



=pod

=head1 FUNCTIONS

These are the functions that are intended for public use.


=head2 new()

This function is the intended starting place for most folks. If you don't create
an object to work with, then we'll quietly create one underneath for our own
use.

    $parser = Rodney::XML::QuickStruct->new($tag_map);
    $parser = Rodney::XML::QuickStruct->new(
        tag_map => \%tag_map,
        debug   => 1
    );

    unless ($parser) {
        die Rodney::XML::QuickStruct::error()."\n";
    }

All parameters are optional and case insensative.


=over 4

These are the arguments supported by C<new()>.

=item tag_map

Loads the given tag map into the object. This needs to be a ref to a hash and
will get loaded via the L<tag_map()|/"tag_map()"> method. (Don't worry about
your ref, we won't make changes inside of it.) This loaded tag map will serve as
the default map for any calls by this object that don't receive an overloaded
map.


=item debug

Turns on debugging messages printed to standard error. This is really intended
for debugging the API, but you may find it usefull. This is implimented via the
L<debug()|/"debug()"> method and accepts the same value.


=back


=cut


sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my @caller = caller(0);

    # They are allowed to pass a single argument of a tag map,
    my $tag_map;
    if (ref($_[0]) eq 'HASH') {
        $tag_map = shift;
        $self->tag_map($tag_map);

    }
    # otherwise we need an even number of arguments.
    elsif (@_ % 2 != 0) {
        error(sprintf qq{Invalid number of arguments to new(), %d.}, scalar(@_));
        return undef;
    }
    # They didn't pass a single tag map, but did pass an even number of
    # arguments. Now let's see what they passed.
    else {

        my %params;
        while (@_) {
            my ($k,$v) = splice(@_,0,2);

            $k = lc($k);
            $params{lc($k)} = $v;
        }

        # We only use the parts of the argument list that we want.
        $self->debug($params{debug})     if $params{debug};
        $self->tag_map($params{tag_map}) if $params{tag_map};

        #>> Don't know about this yet.
        $self->{sloppy} = 1 if $params{sloppy};

        #-- Undocumented.
        # I'm hoping that this package will eventually be able to be tuned at
        # the interface level to also work on HTML.
        $self->singles($params{single})  if $params{single};

    }


    # We have to make certain decisions base on who created the object.
    $self->{is_private} = $caller[0] eq __PACKAGE__ ? 1 : 0;

    return $self;
}



# Assign a list of tags that may only be used as a single tag and not as
# containers.
# This feature isn't documented and you use it at your own risk.
sub singles {
	my $self = shift;

    $self->{singles} ||= {};

    # Assume a list of single-only tags.
    if (ref($_[0]) eq 'ARRAY') {
        %{$self->{singles}} = map( {lc($_) => 1} @{$_[0]});
    }
    elsif (not ref($_[0]) and @_) {
        # Assign with this lone argument.
        if (defined($_[0])) {
            %{$self->{singles}} = lc($_[0]);
        }
        # Empty the list of single-only tags.
        else {
            %{$self->{singles}} = ();
        }
    }

    # Always copy the data to keep them away from the object.
    my %return = %{$self->{singles}};
    return wantarray ? %return : \%return;
}



# Test a tag name to see if it is only allowed to be used as a single.
# This feature isn't documented and you use it at your own risk.
sub _is_single {
	my $self     = shift;
    my $tag_name = shift;

    return $self->{singles}->{lc($tag_name)} ? 1 : 0;
}

=pod

=head2 parse_file()

Loads a file and processes through L<parse_content()|/"parse_content()">. Return
is in a hash or hashref on success, undef on failure. The hashref is prefered as
it's a bit cheaper for you.

=over 4

=item OO interface:

    $data_struct = $parser->parse_file($file_name);
    # Or:
    $data_struct = $parser->parse_file($file_name, %tag_map);
    # Or:
    $data_struct = $parser->parse_file($file_name, \%tag_map);


=item Function interface:

    $data_struct = Rodney::XML::QuickStruct::parse_file($file_name, %tag_map);
    # Or:
    $data_struct = Rodney::XML::QuickStruct::parse_file($file_name, \%tag_map);

=back



C<$file> may be a file name or a file handle. See the L<error()|/"error()">
routine also.


=cut


sub parse_file {

    my $me = (caller(0))[3];

    # Poly-morphism.
    my $self = shift if ref($_[0]) eq __PACKAGE__;

    # The next argument must be a file.
    my $file = shift;

    # Reset the error stack for a new run.
    $self ? $self->error(undef) : error(undef);

    unless ($file) {
        my $message = qq{$me(): No file.};
        $self ? $self->error($message) : error($message);
        return wantarray ? () : undef;
    }


    ##
    ##  Determin the tag map to use. Otherwise known as:
    ##    "Trying to be all things to all people"
    ##

    my $tag_map;    # The known tags and how to handle them.
    if (ref($_[0]) eq 'HASH') {
        $tag_map = shift;
    }
    elsif (@_ % 2 == 0) {
        my %temp = @_;
        $tag_map = \%temp if @_;
    }
    elsif (@_ % 2 != 0) {
        my $message =
          sprintf qq{Odd number of extra arguments to $me(), %d.}, scalar(@_);
        $self ? $self->error($message) : error($message);
        return wantarray ? () : undef;
    }


    # If they didn't call with an object, then we should have a tag map by now.
    if (not $self and not $tag_map) {
        error(qq{$me(): No tag map found in the argument list.});
        return wantarray ? () : undef;
    }


    # Allow a default tag map if called as an object method.
    if ($self) {
        $tag_map ||= $self->tag_map;
    }
    else {
        $self = __PACKAGE__->new;
    }

    # This is the tag map that we'll actually work from.
    $self->{use_tag_map} = $tag_map;

    unless ($self->{use_tag_map}) {
        $self->error(qq{$me(): No tag map found in the argument list or in the object.});
        return wantarray ? () : undef;
    }



    ##
    ##  Load the file and parse it.
    ##


    # I didn't write the calling application, so I don't believe that I have the
    # right to simply die() at my liesure.
    my $content;
    if (ref($file) eq 'GLOB') {
        #>> Some error checking here would be nice.
        while( read($file, my $buf, 1024) ) {
            $content .= $buf;
        }
    }
    else {
        open(I, "<$file") || do {
            $self->error(qq{$me(): Failed to open "$file" for read, [$!].});
            return wantarray ? () : undef;
        };
        read(I, $content, (-s $file));
        close(I);
    }

    return $self->parse_content($content, $tag_map);
}



=pod

=head2 parse_content()

This is where the work gets done. This routine parses the XML-like content that
gets passed to it. On success, returns a hash or hashref data structure
representing that content. On failure, returns C<undef>. Also see the
L<error()|/"error()"> routine.

=over 4

=item OO interface:

In all cases, we'll try to use the arguments that are passed instead of what's
currently in the object. However, if you pass new data, we will NOT load it into
your established object. The reason for this is to allow you to use the object
as a source of default information. Currently this only applies to the tag map.

    # If you've already loaded a tag map.
    $data_struct = $parser->parse_content($content);
    # Or, with a new tag map:
    $data_struct = $parser->parse_content($content, %new_tag_map);
    # Or:
    $data_struct = $parser->parse_content($content, \%new_tag_map);


=item Function interface:

    Rodney::XML::QuickStruct::parse_content($content, %tag_map);
    # Or:
    Rodney::XML::QuickStruct::parse_content($content, \%tag_map);


=back


=cut


sub parse_content {
    # Poly-morphism.
    my $self = shift if ref($_[0]) eq __PACKAGE__;
    my $content = shift;

    # Reset the error stack for a new run.
    $self ? $self->error(undef) : error(undef);

    my $me = (caller(0))[3];
    unless ($content) {
        my $message = qq{$me(): No content.};
        $self ? $self->error($message) : error($message);
        return wantarray ? () : undef;
    }


    ##
    ##  Trying to be all things to all people.
    ##

    my $tag_map;    # The known tags and how to handle them.
    if (ref($_[0]) eq 'HASH') {
        $tag_map = shift;
    }
    elsif (@_ % 2 == 0) {
        my %temp = @_;
        $tag_map = \%temp if @_;
    }

    if ($self) {
        $tag_map ||= $self->tag_map;
    }
    else {
        $self = __PACKAGE__->new;
    }

    # This is the tag map that we'll actually work from.
    $self->{use_tag_map} = $tag_map;



    ##
    ##  Now to get the parsing done.
    ##

    my $p = new HTML::SimpleParse($content);
    $self->{tree} = $p->{tree};


    # The first element of their content will always be at index 0 (zero). The
    # first thing that the process_*() routines do is to increment the index to
    # get at the next tree element. Since we are wrapping their content in a
    # fake element, we need to put that element at the begining of the content.
    # We do that by claiming that we are currently at index -1 (neg. one).
    my $start_i = -1;

    # The storage to return.
    my $container = {};
    $self->_process_hash($container, {type=>'fake_tag',content=>'super_parent'}, \$start_i);

    # Something benieth us had a terminal problem.
    if ($self->{stop_process}) {
        $container = undef;
        return wantarray ? () : undef;
    }

    unless (keys %{$container}) {
        $self->error(qq{No data from parsing. Maybe check the rest of the error stack.});
        return wantarray ? () : undef;
    }
    return wantarray ? %{$container} : $container;
}



=pod

=head2 tag_map()

Accessor/mutator for the object's tag map. This data controls what the parser
thinks of a given tag.


    # Assign/reassign new tag map.
    $self->tag_map(%tag_info);
    # Or:
    $self->tag_map(\%tag_info);

    # Read current tag map;
    %curr_map = $self->tag_map;
    # Or:
    $curr_map = $self->tag_map;     # No cheaper, this ref is a copy.


    # Clear the tag map
    $self->tag_map(undef);


If you are assigning a new tag map, the keys will be cast to lower case, and the
values will be checked agains the known data types. See L<TAG_MAP>.


=cut


sub tag_map {
	my $self = shift;

    # Object method only.
    return undef unless ref($self) eq __PACKAGE__;

    if (@_) {
        # Empty anything that's in place, but don't change the ref address.
        %{$self->{tag_map}} = ();
    }

    # Assigning an entirely new tag map.
    if (ref($_[0]) eq 'HASH') {
        # This forces a copy of the caller's data.
        return $self->tag_map(%{shift()});
    }
    elsif (@_) {
        PAIR:
        while (@_) {
            my ($k,$v) = splice(@_,0,2);

            # No funny business.
            next 'PAIR' if (ref($k) or ref($v));
            $k = lc($k); $v = lc($v);

            # Again, no funny business.
            next 'PAIR' unless exists($KNOWN_DATA_TYPES{$v});
            $self->{tag_map}->{$k} = $v;
        }
    }

    # Yes, a ref to a copy of a ref. That keeps folks from altering our object.
    my %return = %{$self->{tag_map}};
    return wantarray ? %return : \%return;
}



=pod

=head2 error()

Accesses the error stack. If called in scalar context, returns the most recent
error. If called in list context, returns all errors in reverse order of
occurance. The latter isn't very usefull yet, since virtually everyting that
sets an error also fails it's return.


=over 4


=item OO interface:

    $last_error = $parser->error;
    @all_errors = $parser->error;


=item Function interface:

    $last_error = Rodney::XML::QuickStruct::error;
    @all_errors = Rodney::XML::QuickStruct::error;


=back



=cut


sub error {

    my @caller = caller(0);
    my $me = $caller[3];

    # Objective or proceedural?
    my $err_ref;
    if (ref($_[0]) eq __PACKAGE__) {
        my $self = shift;

        # If the object is private, one we created, then the error stack needs
        # to be public so the caller can get at it.
        if ($self->{is_private}) {
            $err_ref = \@Errors;
        }
        else {
            $self->{errors} ||= [];
            $err_ref = $self->{errors};
        }
    }
    else {
        $err_ref = \@Errors;
    }


    # We only allow modifications to come from this API.
    if ( $caller[0] eq __PACKAGE__ ) {
        # They've included something in the arg list.
        if (@_) {
            # An explicit undef() means to reset the error stack.
            if ($_[0] eq undef) {
                @{$err_ref} = ();
            }
            else {
                push @{$err_ref}, @_;
            }
        }
    }

    # Always show the error(s).
    return wantarray ? @{$err_ref} : $err_ref->[-1];

}



=pod

=head2 debug()

Gets/sets the debug level for the calling object.

If you don't pass an argument, we'll simply return the current debug level. If
you pass a real integer argument, we'll set the debug level to that and return
the previous debug level. If you pass a non-integer argument, we'll set the
debug level to 1 (one) or 0 (zero), depending on Perl's idea of TRUE in relation
to your argument, and then return the previous debug level.

    $old_debug  = $self->debug($integer);
    $curr_debug = $self->debug;

=cut


sub debug {
	my $self = shift;

    # Object method only.
    return undef unless ref($self) eq __PACKAGE__;

    # Make sure that we've got a devined value for others to use.
    $self->{debug} = 0 unless defined($self->{debug});
    # The proposed "hook" operator would look nicer (to me):
    # $self->{debug} ??= 0;


    my $ret = $self->{debug};

    # Only modifiy the object if we've got an argument.
    if (@_) {
        # Valid numeric and we'll let them set the debug how they like.
        if ($_[0] =~ /^\d+$/) {
            $self->{debug} = $_[0];
        }
        # Otherwise: TRUE = 1, FALSE = 0.
        else {
            $self->{debug} = $_[0] ? 1 : 0;
        }
    }

    return $ret;
}



sub _process_hash {
    my $self      = shift;
    my $container = shift;  # The current container structure
    my $cont_elem = shift;  # The current hash element
    my $pi        = shift;  # A ref to the current index of $tree

    return undef unless ref($self) eq __PACKAGE__;

    # Makes nice messages.
    my $me = (caller(0))[3];

    my $tree      = $self->{tree};          # The HTML::SimpleParse tree
    my $tag_map   = $self->{use_tag_map};   # The known tags and how to handle them.

    $self->_process_elem($cont_elem);
    my $start_tag_name = $cont_elem->{tag_name};

print STDERR qq{$me():   Starting with tag name "$start_tag_name"\n} if $self->debug > 1;

    for my $k (keys %{$cont_elem->{params}}) {
        $container->{$k} = $cont_elem->{params}->{$k};
    }

    return if $cont_elem->{is_single};

    ELEMENT:
    for (my $i=${$pi}+1; $i<@{$tree}; $i++) {
        my $elem = $tree->[$i];

        $self->_process_elem($elem);

        my $tag_name  = $elem->{tag_name};
        my $data_type = $elem->{data_type};


        if ($elem->{type} eq 'starttag') {
            if ($data_type eq 'hash') {
                my $temp = {};
                $self->_process_hash($temp, $elem, \$i);
                # If somebody benieth us has said to stop.
                return undef if $self->{stop_process};
                $container->{$tag_name} = $temp;
            }
            elsif ($data_type eq 'list') {
                my $temp = [];
                $self->_process_list($temp, $elem, \$i);
                # If somebody benieth us has said to stop.
                return undef if $self->{stop_process};
                push @{$container->{$tag_name}}, @{$temp};
            }
            elsif ($data_type eq 'scalar') {
                my $temp = '';
                $self->_process_scalar(\$temp, $elem, \$i);
                # If somebody benieth us has said to stop.
                return undef if $self->{stop_process};
                $container->{$tag_name} = $temp;
            }
        }
        elsif ($elem->{type} eq 'text') {
            #>> We could add some hueristics here to attempt to asertain valid
            #>> text content and load it. But probably only in sloppy mode.
            print STDERR qq{$me():   Skipping text-type element...\n} if $self->debug;
        }
        elsif ($elem->{tag_name} eq $start_tag_name and $elem->{type} eq 'endtag') {
            ${$pi} = $i;
            return;
        }
        else {

            # How did we get here? Probably bad markup.
            print STDERR qq{$me():   Invalid 'type', [$elem->{type}], [$elem->{tag_name}]\n} if $self->debug;
            $self->error(qq{$me(): Invalid tag type ($elem->{type}), with tag name "$elem->{tag_name}".});

            #>> maybe allow for a "loose handling" option.
            unless ($self->{sloppy}) {
                $self->{stop_process} = 1;  # Tell our callers to stop processing.
                return undef;
            }
        }
    }

    unless ($cont_elem->{type} eq 'fake_tag') {
        print STDERR qq{$me():   No end tag found for "$start_tag_name".\n} if $self->debug;

        # We shouldn't get here. If we did, it means that we didn't find an end
        # tag and must have invalid content. If we are in "sloppy" mode and it
        # looks like this markup was supposed to mean a single tag that is just
        # missing the trailing slash, then we'll try to fix this problem.
        if ( $self->{sloppy}) {
            # May not be defined
            $container->{value} = $cont_elem->{params}->{value} if exists($cont_elem->{params}->{value});
            return;
        }
        # Not in "sloppy" mode, so this is an error.
        else {
            $self->{stop_process} = 1;  # Tell our callers to stop processing.
            $self->error(qq{$me(): No end tag found for "$start_tag_name".});
            return;
        }
    }
}




sub _process_list {
    my $self = shift;
    my $container = shift;  # The current container structure
    my $cont_elem = shift;  # The current hash element
    my $pi        = shift;  # A ref to the current index of $tree

    return undef unless ref($self) eq __PACKAGE__;

    my $me = (caller(0))[3];

    my $tree      = $self->{tree};          # The HTML::SimpleParse tree
    my $tag_map   = $self->{use_tag_map};   # The known tags and how to handle them.

    $self->_process_elem($cont_elem);
    my $start_tag_name = $cont_elem->{tag_name};

print STDERR qq{$me():   Starting with tag name "$start_tag_name"\n} if $self->debug > 1;

    my %load_hash;
    for my $k (keys %{$cont_elem->{params}}) {
        if ($cont_elem->{attr}->{casthash}) {
            $load_hash{lc($k)} = $cont_elem->{params}->{$k};
        }
        else {
            push @{$container}, $cont_elem->{params}->{$k};
        }
    }

    if ($cont_elem->{is_single}) {
        if ($cont_elem->{attr}->{casthash}) {
            push @{$container}, \%load_hash;
        }
        return;
    }
    else {
        ELEMENT:
        for (my $i=${$pi}+1; $i<@{$tree}; $i++) {
            my $elem = $tree->[$i];

            $self->_process_elem($elem);

            my $tag_name = $elem->{tag_name};
            my $data_type = $tag_map->{$tag_name};

#>> We should only be operating on tags we recognize...
            if ($elem->{type} eq 'starttag') {
                if ($data_type eq 'hash') {
                    my $temp = {};
                    $self->_process_hash($temp, $elem, \$i);

                    # If somebody benieth us has said to stop.
                    return undef if $self->{stop_process};

                    if ($cont_elem->{attr}->{casthash}) {
                        for my $k ( keys(%{$temp}) ) {
                            $load_hash{$k} = $temp->{$k};
                        }
                    }
                    else {
                        push @{$container}, $temp;
                    }
                }
                elsif ($data_type eq 'list') {
                    my $temp = [];
                    $self->_process_list($temp, $elem,, \$i);

                    # If somebody benieth us has said to stop.
                    return undef if $self->{stop_process};

                    if ($cont_elem->{attr}->{casthash}) {
                        push @{$load_hash{$tag_name}}, @{$temp};
                    }
                    else {
                        push @{$container}, $temp;
                    }
                }
                elsif ($data_type eq 'scalar') {
                    my $temp = '';
                    $self->_process_scalar(\$temp, $elem, \$i);

                    # If somebody benieth us has said to stop.
                    return undef if $self->{stop_process};

                    if ($cont_elem->{attr}->{casthash}) {
                        $load_hash{$tag_name} = $temp;
                    }
                    else {
                        push @{$container}, $temp;
                    }
                }
            }
            elsif ($elem->{type} eq 'text') {
                print STDERR qq{$me():   Skipping text-type element...\n} if $self->debug;
            }
            elsif ($elem->{tag_name} eq $start_tag_name and $elem->{type} eq 'endtag') {
                ${$pi} = $i;
#                last 'ELEMENT';
                if ($cont_elem->{attr}->{casthash}) {
                    push @{$container}, \%load_hash;
                }
                return;
            }
            else {

                # How did we get here? Probably bad markup.
                print STDERR qq{$me():   Invalid 'type', [$elem->{type}], "$elem->{tag_name}"\n} if $self->debug;
                $self->error(qq{$me(): Invalid tag type ($elem->{type}) with tag name "$elem->{tag_name}".});

                #>> maybe allow for a "loose handling" option.
                unless ($self->{sloppy}) {
                    $self->{stop_process} = 1;  # Tell our callers to stop processing.
                    return undef;
                }
            }
        }

        print STDERR qq{$me():   No end tag found for "$start_tag_name".\n} if $self->debug;

        # We shouldn't get here. If we did, it means that we didn't find an end
        # tag and must have invalid content. If we are in "sloppy" mode and it
        # looks like this markup was supposed to mean a single tag that is just
        # missing the trailing slash, then we'll try to fix this problem.
        if ( $self->{sloppy}) {
            # May not be defined
            if ($cont_elem->{attr}->{casthash}) {
                push @{$container}, {value => $cont_elem->{params}->{value}}
                  if exists($cont_elem->{params}->{value});
            }
            else {
                push @{$container}, $cont_elem->{params}->{value}
                  if exists($cont_elem->{params}->{value});
            }
            return;
        }
        # Not in "sloppy" mode, so this is an error.
        else {
            $self->{stop_process} = 1;  # Tell our callers to stop processing.
            $self->error(qq{$me(): No end tag found for "$start_tag_name".});
            return;
        }

    }

    die qq{$me():   We should have returned by now, what's up?\n};
}



sub _process_scalar {
    my $self      = shift;
    my $container = shift;  # The current container structure
    my $cont_elem = shift;  # The current hash element
    my $pi        = shift;  # A ref to the current index of $tree

    my $me = (caller(0))[3];

    return undef unless ref($self) eq __PACKAGE__;

    $self->_process_elem($cont_elem);
    my $start_tag_name = $cont_elem->{tag_name};

print STDERR qq{$me(): Starting with tag name "$start_tag_name"\n} if $self->debug > 1;

    my $tree = $self->{tree};          # The HTML::SimpleParse tree


    if ($cont_elem->{is_single}) {
        ${$container} = $cont_elem->{params}->{value};  # A special parameter name
        return;
    }
    else {
        my $full_content;

        ELEMENT:
        for (my $i=${$pi}+1; $i<@{$tree}; $i++) {
            my $elem = $tree->[$i];

            $self->_process_elem($elem);

            if ($elem->{tag_name} eq $start_tag_name and $elem->{type} eq 'endtag') {
                ${$pi} = $i;
                # We'll allow the "value" parameter as a fall-back default.
                ${$container} = $full_content || $cont_elem->{params}->{value};

                return;     # We've found the end tag, so we're finished.
            }

            #>> CDATA could get supported here.
            my $c = $elem->{content};
            $c = '<'.$c.'>' if $elem->{type} =~ /tag/;
            $full_content .= $c;
        }

        print STDERR qq{$me(): No end tag found for "$start_tag_name".\n} if $self->debug;

        # We shouldn't get here. If we did, it means that we didn't find an end
        # tag and must have invalid content. If we are in "sloppy" mode and it
        # looks like this markup was supposed to mean a single tag that is just
        # missing the trailing slash, then we'll try to fix this problem.
        if ( $self->{sloppy}) {
            ${$container} = $cont_elem->{params}->{value}; # May not be defined
            return;
        }
        # Not in "sloppy" mode, so this is an error.
        else {
            $self->{stop_process} = 1;  # Tell our callers to stop processing.
            $self->error(qq{$me(): No end tag found for "$start_tag_name".});
            return;
        }
    }

}



sub _process_elem {
    my $self = shift;
    my $elem = shift;

    return 1 if $elem->{tag_name};


    if ($elem->{type} =~ /tag/) {
        my $content = $elem->{content};
        $content =~ s/[\n\r]+/ /g;  # Crush newlines.
        $content =~ s{\s*|\s*$}{};  # Leading and trailing whitespace.


        # So we don't have to do this clean up every time we use the tag.
        $elem->{flattened_content} = $content;


        # This needs to happen first, other parts depend on the name.
        $self->_tag_name($elem);

        $elem->{data_type} = $self->{use_tag_map}->{$elem->{tag_name}};

        $self->_parse_params($elem);

        ##
        ##  Should this tag be handled as a single (no end tag)?

        # If the tag is explicitly closed with a trailing ./'.
        $elem->{is_single} = $elem->{flattened_content} =~ m{/\s*$} ? 1 : 0;

        # If they are in "sloppy" mode, then we'll allow badly formatted markup
        # and assume that a tag with a "value" parameter must be a single.
        if ($self->{sloppy}) {
            $elem->{is_single} = 1 if $elem->{params}->{value};
        }

        # This isn't documented, and can only be turned on explicitely. Usually,
        # nothing will hapen here.
        $elem->{is_single} = 1 if $self->_is_single($elem->{tag_name});
    }
    1;
}



# Finds the parameters listed in a given tag. Supports very sloppy usage
# including barewords, unquoted values, double or single quotes around values
# (but not mixed around a single value), and escaping quotes inside of a value
# string. All of these are valid parameter parts:

#   <tag barword>
#   <tag barword parm1=one parm2 = two parm3 = 'three'>
#   <tag parm1=one>
#   <tag parm2 = two>
#   <tag parm3 = 'three'>
#   <tag parm4 ="four">
#   <tag parm5 = "This is a string with an escaped \" quote mark">
#   <tag parm6 = one two>
#
# The "parm6" example will yield parm6="one" and a bareword of "two"

sub _parse_params {
    my $self = shift;
    my $elem = shift;

    return undef unless ref($self) eq __PACKAGE__;

    (my $content = $elem->{flattened_content}) =~ s{^/?$elem->{tag_name}\s*}{};
    $content =~ s/\s*\///;  # Remove trailing slash, if present. It occationally
                            # gets figured as a bareword.

    my (%barewords, %params, $dont_add_to_param, $curr_param, $curr_quote, $mode, $state);

    for my $c (split(//, $content)) {
        if ($c =~ /[^\s='"]/) {
            if ($mode eq 'param') {
                $params{$curr_param} .= $c;
            }
            elsif ($mode eq '') {
                # Looks like a bareword
                if ($dont_add_to_param) {
                    $barewords{lc($curr_param)}++;
                    $curr_param = $c;   # Assign, NOT append!
                    $dont_add_to_param = 0;
                }
                else {
                    $curr_param .= $c;
                }
            }
        }
        elsif ($c eq '=') {
            if ($mode eq 'param') {
                $params{$curr_param} .= $c;
            }
            else {
                $mode = 'param';
            }
        }
        elsif ($c =~ /'|"/) {
            if ($mode eq 'param') {
                if ($state eq 'open') {
                    if ($curr_quote eq $c) {
                        # Support for escaping.
                        if ($params{$curr_param} =~ s/\\$//) {
                            $params{$curr_param} .= $c;
                        }
                        else {
                            $state = 'closed';
                            $curr_quote = undef;
                            $curr_param = undef;
                            $mode = '';
                        }
                    }
                    else {
                        $params{$curr_param} .= $c;
                    }
                }
                else {
                    $state = 'open';
                    $curr_quote = $c;
                }
            }
        }
        elsif ($c =~ /\s/) {    #>> Fancy state handling...
            # If we get a space while reading, aren't in a quoted string, and
            # have stareted the value, then the space becomes a delimiter
            if ($mode eq 'param' and not $curr_quote and $params{$curr_param}) {
                $state = 'closed';      #>> This shouldn't be open.
                $curr_quote = undef;    #>> This can't be set.
                $curr_param = undef;
                $mode = '';
            }
            elsif ($mode eq 'param' and $state eq 'open') {
                $params{$curr_param} .= $c;
            }
            # Hmm, we've got a running param that's either a bareword or an
            # actuall parameter name. If we just wait for the next word char,
            # we'll think that it's part of the parameter name. So let's raise
            # a flag to let us know not to add to the curr_param.
            elsif ($curr_param) {
                $dont_add_to_param = 1;
            }
        }
    }

    # This catches barewords that have been listed at the end.
    if ($curr_param and not $params{$curr_param}) {
        $barewords{$curr_param}++;
    }

    $elem->{params} = \%params;
    $elem->{attr}   = \%barewords;
}



sub _tag_name {
    my $self = shift;
    my $elem = shift;

    return undef unless ref($self) eq __PACKAGE__;

    return $elem->{tag_name} if $elem->{tag_name};

    if ($elem->{type} =~ /tag$/) {
        #>> We could allow case sensitivity control here.
        ($elem->{tag_name} = lc($elem->{flattened_content})) =~ s/\///;
        $elem->{tag_name} =~ s/\s.*//;
    }
    return $elem->{tag_name};
}



=pod

=head1 TAG_MAP

A tag map is a description of your data. You use a tag map to tell the parser
the names of the tags that you want the parser to recognize and to define what
data type each tag should be treated as. There are three data types that a tag
can fall under: C<scalar>, C<list>, and C<hash>. These data types are loosly
ananougous to the Perl data types of the same names and refer to the storage
used for the content found inside of a tag.

There is a pseudo data type available for C<list> type tags, that being
C<casthash>. This is actually a directive telling the parser to store blocks of
list tag content in hashrefs instead of in scalars. The C<casthash> directive
gets used inside the tag definition as a bareword, not in the tag map.

Don't worry about any of this too much if it sounds confusing, the L<EXAMPLES>
section will explain it all. But see the L<CONTENT_STRUCTURE> first.



=head1 CONTENT_STRUCTURE

If you already know how to write XML, then you can probably just skip to the
L<EXAMPLES> section.

This document has refered to the content as being "XML-like". That's because
we've used tokens that start with a less-than character, end in a greater-than
character, can take named parameters, and can have a forward slash to say that
the token is alone and without a closing token. We've called these tokens
"tags", and this makes the whole thing "like" XML. It should be understood that
no effort has been made to follow anybody elses protocol. Instead, the focus has
been to make a quick and easy to use markup handler for simple data interchange.

All tag names are case insensitive and tags can be singular or paired:

  <single/>
  <pair>some content</pair>


Paired tags, "containers", may not have a trailing slash or they will get
mis-interpreted as a single tag. If you use an opening tag, you need to use a
closing tag. Not doing so will result in an error.



=head2 Parameters

All tags may use optional parameters in the form of I<param_name="param value">.
Parameters get handled like C<scalar> tags, but don't require a definition in
your tag map. So these three chunks would be equivilent. (The third would
require the C<age> tag to be defined as a C<scalar> data type in your tag map.)

    <myContainer age="15"></myContainer>

    <myContainer age="15"/>

    <myContainer>
      <age>15</age>
    </myContainer>


Parameters are handled in a fairly forgiving manor. They are defined as a
parameter name, an equal symbol, and a value. You may have space between the
parameter name, the equal symbol, and the value, and the value may optionally be
quoted with single or double quotes. Which ever quote type you use to start a
value, if any, must be used to complete that same value. If you need quotes
inside of your value, either use the other type of quote mark to encapsulate
your string, or just escape them with a backslash (\). Note, escaping only works
for quotes and we consider a back slash to be a litteral character any time that
it isn't needed for escaping. All parameter names are cast to lower case.


=head2 Parameter Examples


    <tag parm1=one>
    <tag parm1='one'>
    <tag parm1="one">

    <tag parm1=one parm2 = two parm3 = three>

    <tag parm1 = "This is a string with an escaped \" quote mark">
    <tag parm1 = 'This is a string with an embedded " quote mark'>
    <tag parm1 = "This is a string with a backslash and a single quote \' quote mark">

    <tag parm1 = one two>
    # This example will yield parm1="one" and a bareword of "two"



=head2 Sloppy

If you are using the object interface, you may construct your object with the
'sloppy' option. If you use this option, we'll allow for somewhat less strict
parsing of certain parts of your markup. This fledgling feature is an early
attempt at heuristic handling of human data. Note, this isn't really recomended,
but it's available. Here are the documented effects of "sloppy" mode.


=over 4

=item "value" parameter

We will consider a tag to be single if it includes the special parameter of
"value". Meaning that the trailing slash isn't required. So these two examples
would be equivilant:

  <single value="my value"/>

  <single value="my value">


Be careful, this means B<any> tag that includes the "value" parameter will get
treated as a single, not just the ones that look like they should be a single
tag anyway. So this markup would give you "21" in normal mode and "18" in
'sloppy' mode.

    <age value="18">
        21
    </age>

The reason for this is that in 'sloppy' mode the opening tag will get treated as
a single with a value of "18". Then 'sloppy' mode will prevent the failed return
that would have usually resulted from the invalid closing tag. However, the
error message will still be in the object's error stack:

    Rodney::XML::QuickStruct::_process_hash(): Invalid tag type (endtag), with tag name "age".



=item Missing closure

If you fail to close a tag or to end it with a slash, and it looks like this
markup was really supposed to mean a single tag that is just missing the
trailing slash, then we'll try to fix this problem. So this:

    <person casthash>
        <age>
        <name>Jack</name>
    </person>

Would result in this:

  {
    'person' => [
        {
            'name' => 'Jack',
            'age' => undef
        }
    ]
  }

=back




=head1 EXAMPLES

Here are some examples. They include the tag map used, the markup content used,
and the resulting data structure as represented by the Data::Dumper package.
Remember, the data structure is always a hashref.

Also, check your distribution for these same examples along with a script that
runs them.


=head2 Basic


This example is a single tag used to define some keyed data.


=over 4

=item Tag map

    groceries => 'hash'

=item Markup

    <groceries crackers=1 soup="2" milk='1'/>



=item Data structure

  {
    'groceries' => {
        'milk' => 1,
        'crackers' => 1,
        'soup' => 2
    }
  }

=back


=head2 Contained tags


This example adds some tags to get the data from.


=over 4

=item Tag map

    groceries  => 'hash'
    soup       => 'scalar'
    milk       => 'scalar'
    vegitables => 'list'

=item Markup

    <groceries crackers=1>
        <soup>2</soup>
        <milk value="1"/>
        <vegitables value="brocoli"/>
        <vegitables value="corn"/>
        <vegitables value="peas"/>
    </groceries>


=item Data structure

  {
    'groceries' => {
        'milk' => 1,
        'vegitables' => [
            'brocoli',
            'corn',
            'peas'
        ],
        'crackers' => 1,
        'soup' => 2
    }
  }

=back


=head2 Small error


This example adds an intuative, but incorrect usage of a C<list> type tag. (See
the "corn" line.)


=over 4

=item Tag map

    groceries  => 'hash'
    soup       => 'scalar'
    milk       => 'scalar'
    vegitables => 'list'

=item Markup

    <groceries crackers=1>
        <soup>2</soup>
        <milk value="1"/>
        <vegitables value="brocoli"/>
        <vegitables>corn</vegitables>
        <vegitables value="peas"/>
    </groceries>


=item Data structure

  {
    'groceries' => {
        'milk' => 1,
        'vegitables' => [
            'brocoli',
            'peas'
        ],
        'crackers' => 1,
        'soup' => 2
    }
  }


You'll notice that "corn" didn't make it into the vegitables list. That's
because C<hash> and C<list> type tags are intended strictly as containers for
other data tags. This means that loose text will get ignored. The exception to
this loose text rule is unknown tags, which will cause errors and a failed
return. Always use parameters of a scalar tag to encapsulate actual data. The
next example is a solution.


=back


=head2 Solution

Here we've added the "lit" tag to our map as a scalar in order to encapsulate
litteral pieces of text. Remember, "lit" could have been any name we liked, it
doesn't acutally mean "litteral".

=over 4

=item Tag map

    groceries  => 'hash'
    soup       => 'scalar'
    milk       => 'scalar'
    vegitables => 'list'
    lit        => 'scalar'

=item Markup

    <groceries crackers=1>
        <soup>2</soup>
        <milk value="1"/>
        <vegitables value="brocoli"/>
        <vegitables>
            <lit>corn</lit>
            <lit>carrots</lit>
            <lit>okra</lit>
        </vegitables>
        <vegitables value="peas"/>
    </groceries>


=item Data structure

  {
    'groceries' => {
        'milk' => 1,
        'vegitables' => [
            'brocoli',
            'corn',
            'carrots',
            'okra',
            'peas'
        ],
        'crackers' => 1,
        'soup' => 2
    }
  }



=back




=head2 CASTHASH

This example shows the use of the C<casthash> directive. We'll use it here to
allow us to build a list of data structures. This example is starting to be a
usefull demonstration of the value of the general data structures that this API
generates.


=over 4

=item Tag map

    person   => 'list'
    name     => 'scalar'
    age      => 'scalar'
    hobby    => 'list'
    lit      => 'scalar'

=item Markup

    <person casthash>
        <name>Jack</name>
        <age value="25"/>

        <hobby value="Climbing trees"/>
        <hobby>
            <lit>Climbing rocks</lit>
            <lit>Flying kites</lit>
        </hobby>
    </person>

    <person name="Jill" casthash>
        <age value="Are you kidding?"/>
        <hobby value="Scrap booking"/>
        <hobby value="Plantting"/>
    </person>


=item Data structure

  {
    'person' => [
        {
            'name' => 'Jack',
            'hobby' => [
                'Climbing trees',
                'Climbing rocks',
                'Flying kites'
            ],
            'age' => 25
        },
        {
            'name' => 'Jill',
            'hobby' => [
                'Scrap booking',
                'Plantting'
            ],
            'age' => 'Are you kidding?'
        }
    ]

  }


=back




=head2 Tag vs. params

Here we will show another example of C<casthash>, demonstrate the fact that tag
names and parameter names are not related, and show that tags may span lines.


=over 4

=item Tag map

    company  => 'list'
    person   => 'list'
    name     => 'scalar'
    age      => 'scalar'
    hobby    => 'list'
    lit      => 'scalar'


=item Markup


    <person company="ACME" casthash>
        <name>Jack</name>
        <age value="25"/>

        <hobby value="Climbing trees"/>
        <hobby>
            <lit>Climbing rocks</lit>
            <lit>Flying kites</lit>
        </hobby>
    </person>

    <person company="ACME - Perfume Division" name="Jill" casthash>
        <age value="Are you kidding?"/>
        <hobby value="Scrap booking"/>
        <hobby value="Plantting"/>
    </person>

    <company addr1="123 Road Runner blvd." casthash>
        <name value="ACME"/>
    </company>

    <company
        name  = "ACME - Perfume Division"
        addr1 = "1313 Mockingbird Lane"
        addr2 = "Room # 5"
        phone = "PA-65000"
        casthash
    />


=item Data structure

  {
    'company' => [
        {
            'name' => 'ACME',
            'addr1' => '123 Road Runner blvd.'
        },
        {
            'name' => 'ACME - Perfume Division',
            'phone' => 'PA-65000',
            'addr1' => '1313 Mockingbird Lane',
            'addr2' => 'Room # 5'
        }
    ],
    'person' => [
        {
            'name' => 'Jack',
            'hobby' => [
                'Climbing trees',
                'Climbing rocks',
                'Flying kites'
            ],
            'age' => 25,
            'company' => 'ACME'
        },
        {
            'name' => 'Jill',
            'hobby' => [
                'Scrap booking',
                'Plantting',
            ],
            'age' => 'Are you kidding?',
            'company' => 'ACME - Perfume Division'
        }
    ]
  }


=back

Be careful with C<casthash>. If you use it with one tag, you'll probably want to
use it in the rest of the tags of the same name. Not doing so will work, but
will likely give you results other than what you intended.

You can see in the person and company definitions that we've used parameters
that don't correlate with any know tags. That's because they don't have to. This
functionality allows the content writer to prepare data without having full
specification of what tag map it will be read with.




=head1 AUTHOR

Rodney Broom <perl@rbroom.com>

R.Broom Consulting, http://www.rbroom.com/consulting/



=cut



1;


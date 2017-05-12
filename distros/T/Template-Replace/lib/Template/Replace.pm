package Template::Replace;

use strict;
use warnings;
use 5.008;
use utf8;
use warnings qw( FATAL utf8 );
use Carp;
use Encode qw( encode decode );
use File::Spec::Functions qw( :ALL );
use open qw( :encoding(UTF-8) :std );

=head1 NAME

Template::Replace - PurePerl Push-Style Templating Module


=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

#
# TODO !!!!!
#
# . Changed var delimiter for HTML ({} collides with CSS and JS).
# . Changed include delimiter for HTML (<!--[ collides with MSIE Cond. Comm.).
# . Changed section/parts structure (single name space for sec/var).
# . Changed section structure (multiple same-name subsections).
# - Pseudo-variables to insert delimiters.
# - Set encoding for reading files (UTF-8 by default).
# - Value testing in tests (i.e. with iterations or variables).
# - Variable access to iteration count (first, n, even, odd, last, single).
# - Revise _access_data().
# - More and better documentation!
# - More and better tests!
# - #ROOT# and #RELATIVE# pseudo variables?
#


=head1 SYNOPSIS

Template::Replace is a rather basic, zero dependency "push style" templating
module with a simple API:

    use Template::Replace;

    my $tmpl = Template::Replace->new({
        path      => '/shared/httpd/tmpl', # templates path (required)
        filename  => 'test_template.html', # load template (optional)
        filter    => { default => 'xml' }, # XML escape data on default (opt.)
    });

    $tmpl->parse($str);                    # load template from string
    $tmpl->load($filename);                # load template from file
    print $tmpl->replace($data);           # replace placeholders by data

Example template file (standard delimiters are suitable for HTML; this
example assumes that the default filter for variables is set to 'xml'):

    <!DOCTYPE html>
    <html>
        <head>
            <meta charset="utf-8" />
            <title>($ html_title_var $)</title>
            <!--{ head.tmpl }-->     <!--# Include head template           #-->
        </head>
        <body>
            <!--#
                This is excluded from output (a "template comment").
                Could also be used to temporarily exclude portions
                of the template.
            #-->
            <!--{ header.tmpl }-->   <!--# Include header template         #-->
            <div class="Content">

            <h1>($ content_title_var $)</h1>

            ($ content_var | none $) <!--# Variable has HTML, don't filter #-->

            <!--? Comments ?-->      <!--# Test for section data           #-->
            <h5>Comments</h5>
            <!--( Comments )-->      <!--# Start of section 'Comments'     #-->
            <div class="comment">
                <h6><a href="($ url|url $)">($ name $):</a></h6>
                ($ comment $)
            </div>
            <!--( /Comments )-->   <!--# End of section                   #-->
            <!--? /Comments ?-->   <!--# End of test                      #-->
            <!--? !Comments ?-->   <!--# Test for missing section data    #-->
            <p>No comments yet!</p>
            <!--? /!Comments ?-->  <!--# End of test                      #-->

            </div>
            <!--{ footer.tmpl }--> <!--# Include footer template          #-->
        </body>
    </html>


Data example:

    my $data = {
        html_title_var    => 'Template::Replace: An Example',
        content_title_var => 'An Example',
        content_var       => $html_content,
        Comments          => [
            {
                url       => $author[0]->{url},
                name      => $author[0]->{name},
                comment   => $author[0]->{comment},
            },
            {
                url       => $author[1]->{url},
                name      => $author[1]->{name},
                comment   => $author[1]->{comment},
            },
        ],
        NotRepeating      => { content => 'This is simple content.' },
    };


=head1 EXPORT

Nothing is exported. This module provides an object oriented interface.


=head1 DEPENDENCIES

Requires Perl 5.8 (best served above 5.8.2), L<Carp>, L<Encode> and
L<File::Spec::Functions> (Perl 5.8 core modules).

This is a single file module that can be run without prior installation.


=head1 DESCRIPTION

#
# TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#

Beware: This module's code is neither elegant nor ingenious! Au contraire -
it's ugly, it's a mess ... and it is doing what I wanted it to do. (Okay, not
as bad as stated, but don't complain when looking at it ;-)


=head1 METHODS

=head2 C<new()>

    my $tmpl = Template::Replace->new({
        path      => [ 'path1', 'path2' ],
        filename  => 'template_filename',
        delimiter => {
            include => [ '<!--{', '}-->' ],
            section => [ '<!--(', ')-->' ],
            var     => [ '($'   ,   '$)' ],
            test    => [ '<!--?', '?-->' ],
            comment => [ '<!--#', '#-->' ],
        },
        filter => {
            default => 'xml',
            special => \&my_special_filter_function,
        },
    });
 
Path can be a single string or an array reference of multiple strings; given
paths have to exist, and template files (and includes) can only be loaded from
these paths (for security reasons)!

Filename is an optional string; the template is loaded on object creation if
given.

Single delimiter pairs can be given (default delimiters shown), but they have
to be array references with exactly 2 strings; the delimiters are fixed after
object creation, so this is the only chance to change them!

Filters can be re-declared and custom filters attached; the default filter is
a pass-through filter; filters can be changed anytime before invoking
$tmpl->replace().

All options are optional, but at least one existing path has to be given to
load a template from file (either with filename on object creation or later
with the load method).

=cut

sub new {

    # Process arguments ...
    croak __PACKAGE__ . '->new(): Only one optional argument!'
        unless @_ < 3;

    my ($class, $conf) = (shift, shift || {});

    croak __PACKAGE__ . '->new(): Argument has to be a hash reference!'
        unless defined $conf && ref $conf eq 'HASH';

    croak __PACKAGE__ . '->new(): Filename has to be a string!'
        if $conf->{filename} && ref \$conf->{filename} ne 'SCALAR';

    # Create object hash with default values ...
    my $self = {
        template  => {},
        path      => [],
        filename  => '',
        encoding  => 'UTF-8',
        delimiter => {
            include => [ '<!--{', '}-->' ],
            section => [ '<!--(', ')-->' ],
            var     => [ '($'   ,   '$)' ],
            test    => [ '<!--?', '?-->' ],
            comment => [ '<!--#', '#-->' ],
        },
        is_block    => {
            include => 1,
            section => 1,
            test    => 1,
            comment => 1,
        },
        filter => {
            default    => \&_filter_none,
            none       => \&_filter_none,
            literal    => \&_filter_none,
            xml        => \&_filter_xml,
            html       => \&_filter_html,
            uri        => \&_filter_uri,
            url        => \&_filter_url,
            'uri+xml'  => sub {_filter_xml(_filter_uri(shift));},
            'uri+html' => sub {_filter_html(_filter_uri(shift));},
            'url+xml'  => sub {_filter_xml(_filter_url(shift));},
            'url+html' => sub {_filter_html(_filter_url(shift));},
        },
    };

    # Check for path or path array ...
    # croak __PACKAGE__ . '->new(): No path or path array given!'
    #    unless $conf->{path};
    if (defined $conf->{path}) {
        if (ref $conf->{path} eq 'ARRAY') {
            croak __PACKAGE__ . '->new(): Path array contains invalid path!'
                if grep { !-e $_ } @{$conf->{path}};
            $self->{path} = $conf->{path};
        }
        elsif (ref \$conf->{path} eq 'SCALAR') {
            croak __PACKAGE__ . '->new(): Path '
                . $conf->{path}
                . ' does not exist!'
                unless -e $conf->{path};
            my @path = ($conf->{path});
            $self->{path} = \@path;
        }
        else {
            croak __PACKAGE__ . '->new(): Path is no string or array_ref!';
        }
    }

    # Check for filename ...
    croak __PACKAGE__ . '->new(): No paths defined to load files from!'
        if $conf->{filename} && $#{$self->{path}} == -1;
    $self->{filename} = $conf->{filename};

    # Get delimiters from $conf ...
    croak __PACKAGE__ . '->new(): Argument for delimiters is no hash ref!'
        if $conf->{delimiter} && ref $conf->{delimiter} ne 'HASH';
    foreach my $key (keys %{$self->{delimiter}}) {
        if (defined $conf->{delimiter}{$key}) {
            croak __PACKAGE__ . '->new(): ARRAY reference'
                . " of two delimiter strings expected for $key!"
                unless ref $conf->{delimiter}{$key} eq 'ARRAY'
                    && scalar @{$conf->{delimiter}{$key}} == 2;
            $self->{delimiter}{$key} = $conf->{delimiter}{$key};
        }
    }

    # Create slicer and parser regexps ...
    my $regexp_ref= {};
    foreach my $key (keys %{$self->{delimiter}}) {
        #my $rx = ($self->{is_block}{$key} ? '[ \t]*' : '')
        #my $rx = ($self->{is_block}{$key} ? '\n?[ \t]*' : '')
        my $rx =
            ($self->{is_block}{$key} ? '(?(?<=\n)[ \t]*|(?:\A[ \t]*)?)' : '')
            . quotemeta($self->{delimiter}{$key}[0])
            . '\s*?(\S.*?)?\s*?'
            . quotemeta($self->{delimiter}{$key}[1])
            . ($self->{is_block}{$key} ? '(?:[ \t]*\n)?' : '')
            ;
        $regexp_ref->{$key} = qr/$rx/s;
    }
    
    $self->{regexp} = $regexp_ref;

    # Get filter from $conf ...
    if ($conf->{filter}) {
        croak __PACKAGE__ . '->new(): Argument for filters is no hash ref!'
            unless ref $conf->{filter} eq 'HASH';
        foreach my $key (keys %{$conf->{filter}}) {
            if (ref $conf->{filter}{$key} eq 'CODE') {
                $self->{filter}{$key} = $conf->{filter}{$key};
            }
            elsif (ref \$conf->{filter}{$key} eq 'SCALAR') {
                $self->{filter}{$key} = $self->{filter}{$conf->{filter}{$key}}
                    or croak __PACKAGE__ . '->new(): Unknown pre-defined'
                        . " filter '$conf->{filter}{$key}'!";
            }
            else {
                croak __PACKAGE__ . '->new(): Filter has to be '
                    . 'a pre-defined filter name or a CODE reference!';
            }
        }
    }

    # Bless object hash ...
    bless($self, $class);

    $self->load($self->{filename}) if $self->{filename};

    return $self;
}


=head2 C<parse()>

    my $template_ref = $tmpl->parse($str);

Parses a template from $str. Stores the template structure reference in the
$tmpl object and returns it. No includes, because they are handled only on
reading from file (use $tmpl->load() instead)!

=cut

sub parse {
    my ($self, $str) = @_;
    $self->{template} = $self->_parse_slices($self->_slice_str($str));
    return $self->{template};
}


=head2 C<load()>

    my $template_ref = $tmpl->load($filename);

Loads a template from file $filename and parses it. Stores the template
structure reference in the $tmpl object and returns it.

=cut

sub load {
    my ($self, $filename) = @_;
    return $self->parse($self->_read_file($filename));
}


=head2 C<replace()>

    my $txt = $tmpl->replace($data);

Replaces $data in $tmpl and returns the resulting string (text).

=cut

sub replace {
    my ($self, $data) = @_;
    return $self->_replace($self->{template}, $data);
}


=head2 C<has()>

    my $result = $tmpl->has($access_str);

Tries to access a template element and returns the usage count of a section (0
or 1 for now) or of a variable in the template structure. The access string
has the following form:

    'RootSection' (or '/RootSection')
    'RootSection/Subsection'
    'RootVariable'
    'RootSection/SectionVariable'
    'RootSection/Subsection/SubsectionVariable'
    etc.

=cut

# TODO: Adapt for new template structure (multiple same-name subsections),
# don't forget to change documentation!
# 
sub has {
    my ($self, $access_str) = @_;
    return _access_template($access_str, $self->{template});
}


#
# Private methods ...
#

sub _replace {
    #
    #   my $txt = $self->_replace($sec_ref, @data_refs);
    #
    # Format of a data reference:
    #
    #   my $data_ref = {
    #       'GlobalVar' => GlobalVarString,
    #       'Section1Name' => { # section data for single invocation
    #           var1_name => var1_scalar,
    #           var2_name => var2_scalar,
    #           'SubSectionName' => ...,
    #       },
    #       'Section2Name' => [ # section data for iterated invocation
    #           { var1_name => var1_scalar, var2_name => var2_scalar },
    #           { var1_name => var1_scalar, var2_name => var2_scalar },
    #       ],
    #   };
    #
    my ($self, $sec_ref, @data_refs) = @_;
    my $sec_data_ref = $data_refs[$#data_refs];
    my $txt = '';
    my $skip = '';

    PART:
    foreach my $part (@{$sec_ref->{parts}}) {
        if ($skip) { # skip parts inside test
            $skip = '' if ref $part eq 'HASH' 
                && $part->{test} && $part->{test} eq "/$skip";
        }
        elsif (ref $part eq 'HASH') { # subsection, test or var
            if (my $subsec_name = $part->{sec}) { # subsection
                my $subsec_idx = $part->{idx};
                my $subsec_data_ref = $sec_data_ref->{$subsec_name};
                next PART unless $subsec_data_ref;
                croak __PACKAGE__ . '->_replace(): Data for section'
                    . " $subsec_name has to be"
                    . " a HASH or ARRAY reference!"
                    unless ref $subsec_data_ref eq 'HASH'
                        || ref $subsec_data_ref eq 'ARRAY'
                    ;
                my @iterations = ref $subsec_data_ref eq 'HASH'
                               ? ($subsec_data_ref)
                               : @$subsec_data_ref
                               ;
                foreach my $iteration_data_ref (@iterations) {
                    $txt .= $self->_replace(
                        $sec_ref->{children}{$subsec_name}[$subsec_idx],
                        @data_refs,
                        $iteration_data_ref,
                    );
                }
            }
            elsif ($part->{test}) { # test
                next PART if $part->{test} =~ m{^/};
                my $test = $part->{test};
                if ($test =~ s/^!//) {
                    $skip = _access_data($test, @data_refs)
                          ? $part->{test} : '' ;
                }
                else {
                    $skip = _access_data($test, @data_refs)
                          ? '' : $part->{test} ;
                }
            }
            else { # var
                my $filter =  $self->{filter}{$part->{filter}}
                           || $self->{filter}{default};
                $txt .= &$filter(
                    _access_data($part->{var}, @data_refs) || ''
                );
            }
        }
        else { # string
            $txt .= $part;
        }
    }

    return $txt;
}

sub _parse_slices {
    #
    #   my $sec_ref = $self->_parse_slices(
    #       $slices_ref[, $sec_name[, $parent_sec_ref]]
    #   );
    #
    # The template's recursive structure is returned:
    #
    #   {
    #       name     => 'root',
    #       parent   => undef,
    #       children => {
    #           'var_name_1'    => count,
    #           'subsec_name_1' => [
    #               {
    #                   name     => 'subsec_name_1',
    #                   parent   => root_ref,
    #                   children => {...},
    #                   parts    => {...}
    #               },
    #               {
    #                   name     => 'subsec_name_1',
    #                   parent   => root_ref,
    #                   children => {...},
    #                   parts    => {...}
    #               }
    #           ],
    #           'var_name_2'    => count,
    #           'subsec_name_2' => [...],
    #       },
    #       parts    => [
    #           string,
    #           { var  => 'var_name_1', filter => 'default' },
    #           { test => 'test_name' },
    #           { sec  => 'subsec_name_1', idx => 0 },
    #           string,
    #           { var  => 'var_name_2', filter => 'xml' },
    #           string,
    #           { test => '/test_name' },
    #           { sec  => 'subsec_name_2', idx => 0 },
    #           { sec  => 'subsec_name_1', idx => 1 },
    #           ...
    #       ]
    #   }
    #
    # The 'children' hashref is for faster template inspection (convenience)
    # and (for subsections) to simplify the elements in the parts arrayref.
    #
    # Variables can be used more than once in a section, because they
    # are not defined in the template but only filled with their data.
    #
    # Sections can be used more than one also, e.g. for localization inside a
    # template (with language conditions - TODO). They will be processed with
    # the same data!
    #
    my ($self, $slices_ref, $sec_name, $parent_sec_ref) = @_;
    $sec_name ||= 'root';
    my $sec_ref = {
        name     => $sec_name,
        parent   => $parent_sec_ref,
        children => {},
        parts    => [],
    };
    my $regexp_comment = quotemeta($self->{delimiter}{comment}[0]);

    SLICE:
    while (my $slice = shift @$slices_ref) {
        if ($slice =~ m/$regexp_comment/) { # comment
            next;
        }
        elsif ($slice =~ m/$self->{regexp}{test}/) { # test
            push @{$sec_ref->{parts}}, { test => $1 };
        }
        elsif ($slice =~ m/$self->{regexp}{section}/) { # subsection
            my $subsec_name = $1;
            if ($subsec_name =~ m{^/(.+)$}) { # end of subsection
                croak __PACKAGE__
                    . '->_parse_slices(): Section ended with '
                    . "$1 instead of $sec_name!"
                        unless $1 eq $sec_name;
                last SLICE;
            }
            if (!$sec_ref->{children}{$subsec_name}) {
                $sec_ref->{children}{$subsec_name} = [];
            }
            my $subsec_array_ref = $sec_ref->{children}{$subsec_name};
            if (ref $subsec_array_ref ne 'ARRAY') {
                croak __PACKAGE__
                    . "->_parse_slices(): Section name '$subsec_name' "
                    . "already used for a variable in '$sec_name'!"
                    ;
            }
            my $subsec_ref = $self->_parse_slices(
                $slices_ref, $subsec_name, $sec_ref
            );
            push @{$subsec_array_ref}, $subsec_ref;
            push @{$sec_ref->{parts}}, {
                sec => $subsec_name,
                idx => $#$subsec_array_ref,
            };
        }
        elsif ($slice =~ m/$self->{regexp}{var}/) { # var
            my ($var, $filter) = $1 =~ m/^([^|\s]+)\s*\|?\s*([^\s]+)?$/;
            $filter = lc($filter || 'default');
            croak __PACKAGE__
                . "->_parse_slices(): Variable name '$var' "
                . "already used for a section in '$sec_name'!"
                    if ref $sec_ref->{children}{$var} eq 'ARRAY';
            push @{$sec_ref->{parts}}, { var => $var, filter => $filter, };
            $sec_ref->{children}{$var}++;
        }
        else { # string
            push @{$sec_ref->{parts}}, $slice;
        }
    }

    return $sec_ref;
}

sub _slice_str {
    #
    #   my $slices = $tmpl->_slice_str($str);
    #
    # This method returns the reference to a list of strings that represents
    # the found slices (the given string is cut to pieces - without any
    # characters removed or added).
    #
    my ($self, $str) = @_;
    croak __PACKAGE__ . '->_slice_str(): Missing string argument!'
        unless defined $str;
    croak __PACKAGE__ . '->_slice_str(): Not a string argument!'
        unless ref \$str eq 'SCALAR';

    my $rx = qr(
            $self->{regexp}{comment}
        |   $self->{regexp}{test}
        |   $self->{regexp}{section}
        |   $self->{regexp}{var}
    )x;
    my $dbldelim = '^[ \t]*(';
    foreach my $key (keys %{$self->{delimiter}}) {
        $dbldelim .= quotemeta($self->{delimiter}{$key}[0]) . '|';
    }
    $dbldelim = substr($dbldelim, 0, -1) . ').*?\1';
    $dbldelim = qr/$dbldelim/s;

    my @strings = ();
    my $last_pos = 0;

    while ($str =~ m/$rx/cg) {
        my $start = $-[0];
        my $end   = $+[0];
        if ($start > $last_pos) { # string slice before match
            push @strings, substr $str, $last_pos, $start - $last_pos;
        }
        my $slice =  substr $str, $start, $end - $start; # element slice
        # Check for doubled start delimiter (which breaks $rx) ...
        croak __PACKAGE__ . '->_slice_str(): Repeated start delimiter '
            . "in slice '$slice'!"
            if $slice =~ m/$dbldelim/;
        push @strings, $slice;
        $last_pos = $end;
    }

    if (length $str > $last_pos) { # remaining string slice
        push @strings, substr $str, $last_pos;
    }
    
    return \@strings;
}

sub _read_file {
    #
    #   my $str = $tmpl->_read_file($file_name[, @ancestors]);
    #
    # TODO:
    # - Restrict filenames to an ASCII subset
    # - Allways Unix path notation in Template::Replace?
    # - Use explicit file encoding when reading
    # 
    my ($self, $file_name, @ancestors) = @_;

    # Cleanup of file name ...
    my @canon_path = splitpath(canonpath($file_name));
    my @canon_dir = grep {$_ !~ /\.\./} splitdir($canon_path[1]);
    my $canon_file_name = catfile(@canon_dir, $canon_path[2]);

    # Try to find file in paths ...
    my $canon_file_path = '';
    foreach my $path (@{$self->{path}}) {
        $canon_file_path = catfile($path, $canon_file_name);
        last if -e $canon_file_path;
        $canon_file_path = '';
    }
    croak __PACKAGE__ . "->read_file(): File $file_name not found!"
        . ' (Perhaps paths are wrong.)'
        unless $canon_file_path;

    croak __PACKAGE__ . '->read_file(): File recursion for '
        . "$canon_file_path detected!"
        if grep {$canon_file_path eq $_} @ancestors;

    open(my $fd, "<:encoding($self->{encoding})", $canon_file_path)
        or croak __PACKAGE__ . '->_read_file() can\'t open '
        . "$canon_file_path: $!";
    my $str = '';
    {
        local $/;
        defined ($str = readline $fd) or
            croak __PACKAGE__ . '->_read_file() can\'t read from '
            . "$file_name: $!";
    }
    $str =~ s/\x0D?\x0A/\n/g;
    push @ancestors, $canon_file_path;
    $str =~ s/$self->{regexp}{include}/$self->_read_file($1, @ancestors)/ogme;

    return $str;
}


#
# Private functions ...
#

sub _access_template {
    #
    #   my $result = _access_template($access_str, $template_ref);
    #
    # The $access_str starts always at the template root and uses the
    # following notation:
    #   
    #   'bla', same as '/bla', is root element 'bla'
    #   'bla/blub' is element 'blub' of section 'bla'
    #   'bla/blub/blib' is element 'blib' of section 'blub',
    #     assuming the first section definition of 'blub',
    #   'bla/blub/0/blib' is the same as 'bla/blub/blib'
    #   'bla/blub/1 assumes 'blub' to be a section with a second definition
    #   etc.
    #
    # Elements can be sections or variables. For sections the array reference
    # that contains the references to the data structures defined by the
    # section name is returned (if no section count is given) or the section
    # hash reference, for variables the usage count inside of
    # their section.
    #
    # TODO: There's a problem with variable syntax (can contain '../Sec/Var')!
    #       (So variable references can't be detected.)
    #
    my ($access_str, $tmpl_ref) = @_;
    croak __PACKAGE__ . '::_access_template(): '
        . 'Template has to be a HASH reference!'
        unless ref $tmpl_ref eq 'HASH';
    croak __PACKAGE__ . '::_access_template(): '
        . 'Access string is no SCALAR!'
        unless ref \$access_str eq 'SCALAR';

    return unless $access_str;

    my $result = $tmpl_ref;
    $access_str =~ s/^\///;
    my @parts = split /\//, $access_str;

    foreach my $part (@parts) {
        return unless $result;
        if (ref $result eq 'HASH') {
            $result = $result->{children}{$part};
        }
        elsif (ref $result eq 'ARRAY') {
            $result = ($part =~ /^\d+$/) ? $result->[$part]
                                         : $result->[0]{children}{$part};
        }
        else {
            return;
        }
    }

    return $result;
}

sub _access_data {
    #
    #   my $data = _access_data($access_str, @data_refs);
    #
    #   'bla' is data in current section
    #   'bla/blub' is subsection data (same as 'bla/0/blub' = first iteration)
    #   'bla/2/blub' is third iteration data blub (iterations start w/ 0)
    #   '/bla' is root data
    #   '../bla' is parent data, '../../bla' is parent's parent data etc.
    #
    # and so on ...
    #
    # @data_refs is a stack of data references; topmost is the data ref of
    # the current section (respectively of its current iteration), below the
    # data ref of the parent section (respectively of its current iteration),
    # and so forth, with the root data reference at the bottom.
    #
    # Therefor it is possible to access another iteration of the parent's data
    # by going to the parent's parent data and down again from there ...
    #
    my ($access_str, @data_refs) = @_;
    #
    # Croak instead?
    #
    return unless scalar @data_refs;

    my $data = $access_str =~ s/^\/// ? $data_refs[0] : pop @data_refs ;
    my @parts = split /\//, $access_str;
    #
    # Croak instead?
    #
    return unless scalar @parts;

    foreach my $part (@parts) {
        next if $part eq '.'; # What if no parts left?
        if ($part eq '..') {
            $data = pop @data_refs;
        }
        elsif (ref $data eq 'ARRAY') {
            $data = ($part =~ /^\d+$/) ? $data->[$part] : $data->[0]{$part};
        }
        elsif (ref $data eq 'HASH') {
            $data = $data->{$part};
        }
        else {
            return; # Is that right?
        }
    }
    
    return $data;
}

#
# Pre-defined filter functions ...
#

sub _filter_none {
    local $_ = shift;
    return $_;
}

sub _filter_xml {
    local $_ = shift;
    croak __PACKAGE__ . "::_filter_xml: Undefined string not accepted!"
        unless defined $_; 
    return '' unless length $_;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/'/&apos;/g;
    s/"/&quot;/g;
    return $_;
}

sub _filter_html {
    local $_ = shift;
    croak __PACKAGE__ . "::_filter_xml: Undefined string not accepted!"
        unless defined $_; 
    return '' unless length $_;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/"/&quot;/g;
    return $_;
}

our $URI_ESCAPES; # Cache of escaped characters

sub _filter_uri {
    # URI escape a string.  This code is borrowed from Gisle Aas' URI::Escape
    # module, copyright 1995-2004.  See RFC2396 for details.
    my $str = shift;
    return '' unless length $str;

    $URI_ESCAPES ||= {
        map { ( chr($_), sprintf("%%%02X", $_) ) } (0..255),
    };

    if ($] >= 5.008002) {
        utf8::encode($str) if utf8::is_utf8($str);
        $str =~ s/([^A-Za-z0-9\-_.!~*'()])/$URI_ESCAPES->{$1}/eg;
    }
    else {
        # More reliable with older Perl versions, but complicated and slow ...
        # This particular implementation is not yet tested (used in the past)!
        use bytes;
        my @bytes = split '', $str;
        foreach my $byte (@bytes) {
            $byte = uc("%" . unpack('H*', $byte)) if /[^A-Za-z0-9\-_.!~*'()]/;
        };
        $str = join '', @bytes;
    }

    return $str;
}

sub _filter_url {
    # URI escape a string.  This code is borrowed from Gisle Aas' URI::Escape
    # module, copyright 1995-2004.  See RFC2396 for details.
    # Less agressive than _filter_uri().
    my $str = shift;
    return '' unless length $str;

    $URI_ESCAPES ||= {
        map { ( chr($_), sprintf("%%%02X", $_) ) } (0..255),
    };

    if ($] >= 5.008002) {
        utf8::encode($str) if utf8::is_utf8($str);
        $str =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$URI_ESCAPES->{$1}/eg;
    }
    else {
        # More reliable with older Perl versions, but complicated and slow ...
        # This particular implementation is not yet tested (used in the past)!
        use bytes;
        my @bytes = split '', $str;
        foreach my $byte (@bytes) {
            $byte = uc("%" . unpack('H*', $byte))
                        if /[^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()]/;
        };
        $str = join '', @bytes;
    }

    return $str;
}

1;

__END__

=head1 DIAGNOSTICS

#
# TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#


=head1 FUNCTIONAL DESCRIPTION

To better understand some of the peculiarities of Template::Replace, here is
how it works:

=over 4

=item 1.

When using C<load()> (implicitly by providing a filename with C<new()> or
explicitly), the private method C<_read_file()> is called, which does some
path and filename cleanup (for security reasons) and slurps the template file.

File inclusion is only done in this step! There is a mechanism to prevent
recursive file inclusion. The inclusion in C<_read_file()> is done because it
makes the other steps much simpler.

This step results in a single string containing the complete template with all
inclusions.

=item 2.

Then C<parse()> (implicitely called by C<load()>) is used to process the
template string. First the private method C<_slice_str()> creates a linear
list of slices (using regular expressions based on the given delimiters) that
is then processed by C<_parse_slices()> to build the template structure of
sections (and subsections), tests, variables and text fragments ("strings").

Custom delimiters can only be defined on object creation, because they are used
beforehand when slicing (and parsing) the template.

=item 3.

The rendering of the final output is done with C<replace()> (which calls
C<_replace()>), replacing the various template parts by the contents of a
corresponding data structure. Output filters can be applied to the replacement
of variables. This is a dynamic process, so that output filters can be changed
after parsing a template. (Oh, and you can do this over and over again with
the loaded template and changing data ...)

=back



=head1 RATIONALE

Yet another template module ... oh no ... why? For the fun of it ;-)

No, not really. There were other considerations that lead me to write Yet
Another Perl Template Module (I won't do it again, I promise). I had the
following requirements when I started searching CPAN for template modules:

=over 4

=item *

no programming in the template (no DSL, no Perl)

=item *

replacement oriented

=item *

implicit looping

=item *

nested sections

=item *

scoped variables (with access to other scopes)

=item *

output filters for variables

=item *

file includes

=item

strict include path(s)

=item *

template defines overall structure of output

=item *

template testing in the script (what is defined in the template?)

=item *

data testing in the template (what data is defined?)

=item *

configurable delimiters

=item *

template items should not interfere with target syntax (i.e. HTML)

=item *

independent of target syntax/language

=item *

no installation/compilation required

=item *

only Perl 5.8 core dependencies

=back

Okay, with data testing in the template the line to programming or "business
logic" is slightly blurred, but it is necessary to define alternate parts for
a template according to data availability (i.e. comments/no comments).

With the ability to query the template (and the structure of its replacement
parts) there is a greater chance to de-couple the structures of template and
program (the program can prepare the data structures used to fill the template
according to the specific template used). And programming can be more
efficient (avoiding expensive processing if the result isn't used in the
template).

The requirement to have no DSL or Perl in the template has the side effect
that the templating "syntax" can be easily re-implemented in other programming
languages and that the whole system can be switched without effecting the
templates.

None of those properties are new or unseen, but I found no module that would
satisfy all of my requirements (and then there's a potential problem with
UTF-8 and taint mode that bit me again and again before, so I wanted to have
full control over the source so that I can intervene when necessary). And at
least many APIs where much too complicated or bloated for my liking.



=head2 Other programmer's brainchilds ...

If you want to use some really cool template engines, or if you think you are
creating The Next Big Thing, and if you can afford module installation or
compilation, and if you are not afraid of module dependencies, then look out
for L<Template::Toolkit> or L<HTML::Mason> and all the other great (or big -
depends on your point of view :-)) template modules on CPAN. Or stay with
simpler modules like L<Template::Tiny> etc.

Here is some reading for you:

=over 4

=item *

L<http://perl.apache.org/docs/tutorials/tmpl/comparison/comparison.html>

=item *

L<http://www.perl.com/pub/a/2008/03/14/reverse-callback-templating.html>

=item *

L<http://www.perlmonks.org/?node_id=674225>

=item *

L<http://www.cs.usfca.edu/~parrt/papers/mvc.templates.pdf>

=back

Have fun ...




=head1 AUTHOR

Christian Augustin, C<< <mail at caugustin.de> >>



=head1 BUGS

Please report any bugs or feature requests to C<bug-template-replace at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Replace>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Replace


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Replace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Replace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Replace>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Replace/>

=back



=head1 ACKNOWLEDGEMENTS

Some years ago I stumbled over some ingeniously simple Perl templating code,
consisting of only two rather short and clever functions, that could do some
of the things I used as requirements for Template::Replace (it was replace
oriented, had some sort of nested sections and did implicit looping). But the
code had some annoying properties and quirks, the data structures for
replacement were all but intuitive, and the lack of "global" variables or an
access mechanism made the use a slight pain in the ass (and no documentation).
What I learned at least was: Don't be too clever ...

But the basic idea resonated and inspired the creation of Template::Replace.
As did many other modules I found while I searched the CPAN. I can't give
specific achnowledgements, but if you find some ideas in here you saw in one
of the other modules, they probably came from them.



=head1 LICENSE AND COPYRIGHT

Copyright 2012 Christian Augustin (caugustin.de).

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.


=cut

# End of Template::Replace

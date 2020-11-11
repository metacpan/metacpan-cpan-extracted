package Pod::Definitions;

our $VERSION = '0.03';

use strict;
use warnings;

use v5.20;

use feature 'signatures';
no warnings 'experimental::signatures';

use Pod::Headings;
use Pod::Definitions::Heuristic;

#
#
#
sub new ($class, @args) {
    my $self = {@args};
    bless $self, $class;

    return $self;
}

#
# Accessors
#

sub file ($self) { return $self->{file}; }       # Local path to file
sub manpage ($self) { return $self->{manpage}; } # Full name of manpage ('Mojo::Path')
sub module ($self) { return $self->{module}; }   # Module leaf name ('Path')
sub sections ($self, $section = undef) {
    return defined $section ?
    $self->{sections}->{$section} : # Array of entries in that section, or undef
    $self->{sections};              # Hash (key=toplevel section) of arrays of section names
} 
#
#
#

sub convert_to_href_text ($human_text) {
    $human_text =~ s/(\s|\(|=|\[)/-/g;
    $human_text =~ s/([^a-zA-Z0-9_\-*:])//g;
    return $human_text;
}

sub _save_definition ($self, $parser, $attrs, $head1, $text) {
    my $cooked_heading = Pod::Definitions::Heuristic->new(text => $text);
    push @{$self->{sections}{$head1}}, {raw => $text,
                                        cooked => $cooked_heading->clean,
                                        sequence => $attrs->{sequence},
                                        link => $self->manpage(),
                                        link_fragment => convert_to_href_text($text),
                                    };
}

sub _save_file_manpage ($self, $text) {
    $self->{manpage} = $text unless defined $self->{manpage};
}

sub _save_file_module_leaf ($self, $text) {
    $self->{module} = $text;
}

sub _save_module_name ($self, $parser, $elem, $attrs, $text) {
    $text =~ m/^\s*(?<module_name>\S+)/;
    my $module_name = $+{module_name};
    $self->_save_file_manpage($module_name);
    # "Mojo::Log" → index under last component: "Log"
    $self->_save_file_module_leaf( (split /::/, $module_name)[-1] );
}

sub _save_version ($self, $parser, $elem, $attrs, $text) {
    $self->{version} = $text;
}

sub _save_see_also ($self, $parser, $elem, $attrs, $text) {
    push @{$self->{see_also}}, $text;
}

sub parse_file ($self, $file, $podname = undef) {

    my $save_next;

    $self->{file} = $file;
    $self->_save_file_manpage($podname) if defined $podname;

    return Pod::Headings->new(
        head1 => sub ($parser, $elem, $attrs, $plaintext) {
            # "Archive::Zip Methods" -> "Methods":
            $plaintext =~ s/^($self->{manpage}\s+)//i if defined $self->{manpage};
            # Change headings starting in all-uppercase to inital caps
            # only. Note, "READING CPAN.pm" -> "Reading cpan.pm"
            # (there is only so much we can do without A.I.)
            if ($plaintext =~ /^[ \p{Uppercase}]{2,}/) {
                $plaintext =~ s/^(.)(.*)/\u$1\L$2/;
            }
            $parser->{_save_head1} = $plaintext;
            undef $parser->{_save_head2};
            $parser->{_save_first_para} = 1;

            if (lc($plaintext) eq 'name') {
                $save_next = \&_save_module_name;
            } elsif (lc($plaintext) eq 'version') {
                $save_next = \&_save_version;
            } elsif (lc($plaintext) eq 'see also') {
                $save_next = \&_save_see_also;
            } else {
                undef $save_next;
            }

            1;
        },
        head2 => sub ($parser, $elem, $attrs, $plaintext) {
            # print " $elem: $parser->{_save_head1}: $plaintext\n";
            $parser->{_save_head2} = $plaintext;
            $parser->{_save_first_para} = 1;

            $self->_save_definition ( $parser, $attrs, $parser->{_save_head1}, $plaintext );

            1;
        },
        head3 => sub ($parser, $elem, $attrs, $plaintext) {
            # print " $elem: $parser->{_save_head1} / $parser->{_save_head2}: $plaintext\n";
            $self->_save_definition ( $parser, $attrs, $parser->{_save_head2}, $plaintext );
            1;
        },
        Para => sub ($parser, $elem, $attrs, $plaintext) {
            if ($parser->{_save_first_para}) {
                # print " .... text: $plaintext\n";
                $self->$save_next($parser, $elem, $attrs, $plaintext) if defined $save_next;
                undef $save_next;
            }
            $parser->{_save_first_para} = 0;
            1;
        },
        L => 1,  # Return 0 to drop the plaintext passed to the containing element
        # Possible extension: In 'See Also' sections, accumulate the
        # actual links from Pod::Simple in the same form with (raw, cooked, link)
    )->parse_file($file);
}

1;

__END__

=pod

=head1 NAME

Pod::Definitions -- extract main sections and contained definitions from Pod

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $pod_file = Pod::Definitions->new();
    $pod_file->parse_file($file_name);

=head1 DESCRIPTION

This class uses L<Pod::Headings> to parse a Pod file and extract the
top-level (head1) headings, and the names of the functions, methods,
events, or such as documented therein.

Heading names, presumed to be written in the English language, are
simplifed for indexing purposes. (See L<Pod::Headings::Heuristic> for
details.)  For example:

    What is the Q function?               -> Q function
    How can I blip the blop?              -> Blip the blop
    Why doesn't my socket have a packet?  -> Socket have a packet
    Where are the pockets on the port?    -> Pockets on the port
    I need to reap the zombie             -> Reap the zombie
    What does the error "Disk full" mean? -> Disk full
    What about backwards compatibility?   -> Backwards compatibility
    Reaping the zombie from proctab       -> Zombie, reaping from proctab
    $c = Mojo::Path->new()                -> new

Currently, captialization (other than rewrites of type type shown
above) is mostly left for the caller to handle.

=head1 METHODS

=head2 new

Creates a new object of type Pod::Definitions

=head2 parse_file ($filename)

Parse a podfile, or Perl source file. Returns the Pod::Headings
object, which, as a subclass of Pod::Simple, may give various useful
information about the parsed document (e.g., the line_count() or
pod_para_count() methods, or the source_dead() method which will be
true if the Pod::Simple parser successfully read, and came to the end
of, a document).

=head2 file

Local path to file as passed to parse_file

=head2 manpage

Full name of manpage (e.g., 'Mojo::Path').

=head2 module

Module leaf name (e.g., 'Path')

=head2 sections

Hash (with the key being the toplevel section, e.g., "FUNCTIONS") of
arrays of section names, or undef if no sections (other than the
standard NAME and SEE ALSO) were given in the Pod file

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Headings>

=head1 SUPPORT

This module is managed in an open GitHub repository,
L<https://github.com/lindleyw/Pod-Definitions>. Feel free to fork and
contribute, or to clone and send patches.

=head1 AUTHOR

This module was written and is maintained by William Lindley
<wlindley@cpan.org>.

=cut

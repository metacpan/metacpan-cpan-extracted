package MooseX::Getopt::Usage::Formatter;

use 5.010;
our $VERSION = '0.24';

use Moose;
#use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use Term::ANSIColor;
use Term::ReadKey;
use Text::Wrap;
use Pod::Usage;
use Pod::Select;
use Pod::Find qw(pod_where contains_pod);
use MooseX::Getopt::Usage::Pod::Text;
use File::Basename;
use Module::Loaded;
use FindBin;

BEGIN {
    # Grab prog name before someone decides to change it.
    my $prog_name;
    sub prog_name { @_ ? ($prog_name = shift) : $prog_name }
    prog_name(File::Basename::basename($0));
}

# Util wrapper for pod select and its file based API
sub podselect_text {
    my @args = @_;
    my $selected = "";
    open my $fh, ">", \$selected or die;
    if ( exists $args[0] and ref $args[0] eq "HASH" ) {
        $args[0]->{'-output'} = $fh;
    }
    else {
        unshift @args, { '-output' => $fh };
    }
    podselect @args;
    return $selected;
}

#
# Types

subtype 'PodSelectList', as 'ArrayRef[Str]';

enum 'ColorUsage', [qw(auto never always env)];


#
# Attributes

has getopt_class => (
    is       => "rw",
    isa      => "ClassName",
    required => 1,
);

has pod_file => (
    is      => "rw",
    isa     => "Undef|Str",
    lazy_build => 1,
);

sub _build_pod_file {
    my $self = shift;

    # Script file, may have inline pod docs
    my $file = "$FindBin::Bin/$FindBin::Script";
    return $file if -f $file && contains_pod($file);

    # Use the pod docs from the class
    my $gclass = $self->getopt_class;
    return pod_where( {-inc => 1}, $gclass ) if is_loaded($gclass);

    return undef;
}

has colours => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { {
        flag          => ['yellow'],
        heading       => ['bold'],
        command       => ['green'],
        type          => ['magenta'],
        default_value => ['cyan'],
        error         => ['red']
    } },
);

has headings => (
    is      => "rw",
    isa     => "Bool",
    default => 1,
);

has groups => (
    is      => "rw",
    isa     => "Undef|Bool",
    default => undef,
);

has format => (
    is      => "rw",
    isa     => "Str",
    lazy_build => 1,
);

sub _build_format {
    my $self = shift;
    my $pod_file = $self->pod_file;
    my $sections = $self->format_sections;
    my $selected = "";
    if ( $pod_file ) {
        $selected = podselect_text { -sections => $sections }, $pod_file;
        $selected =~ s{^=head1.*?\n$}{}mg;
        $selected =~ s{^.*?\n}{};
        $selected =~ s{\n$}{};
    }
    return $selected ? $selected : "%c [OPTIONS]";
}

has width => (
    is      => "rw",
    isa     => "Int",
    lazy_build => 1,
);

sub _build_width {
    my $self = shift;
    my $w = 72;
    if (-t STDOUT) {
        my ($tw) = GetTerminalSize();
        $w = $tw -1 if defined $tw;
    }
    return $w;
}


has attr_sort => (
    is      => "rw",
    isa     => "CodeRef",
    default => sub { sub {0} },
);

has use_color => (
    is      => "rw",
    isa     => "ColorUsage",
    default => "auto",
);

has format_sections => (
    is      => "rw",
    isa     => "PodSelectList",
    default => sub { ["SYNOPSIS"] },
);

has usage_sections => (
    is      => "rw",
    isa     => "PodSelectList",
    default => sub { ["SYNOPSIS|OPTIONS"] },
);

has man_sections => (
    is      => "rw",
    isa     => "PodSelectList",
    default => sub { ["!ATTRIBUTES|METHODS"] },
);

has unexpand => (
    is      => "rw",
    isa     => "Int",
    default => 0,
);

has tabstop => (
    is      => "rw",
    isa     => "Int",
    default => 4,
);

#
# Methods

sub _set_color_handling {
    my $self = shift;
    my $mode = shift;

    $ENV{ANSI_COLORS_DISABLED} = defined $ENV{ANSI_COLORS_DISABLED} ? 1 : undef;
    if ($mode eq 'auto') {
        if ( not defined $ENV{ANSI_COLORS_DISABLED} ) {
            $ENV{ANSI_COLORS_DISABLED} = -t STDOUT ? undef : 1;
        }
    }
    elsif ($mode eq 'always') {
        $ENV{ANSI_COLORS_DISABLED} = undef;
    }
    elsif ($mode eq 'never') {
        $ENV{ANSI_COLORS_DISABLED} = 1;
    }
    # 'env' is done in the env set line above
}

sub usage {
    my $self = shift;
    my $args = { @_ };

    my $exit    = $args->{exit};
    my $err     = $args->{err} || "";
    my $colours = $self->colours;

    # Set the color handling for this call
    $self->_set_color_handling( $args->{use_color} || $self->use_color );

    my $pod = $self->_get_pod(
        sections      => $self->usage_sections,
        options_style => 'text',
    );
    my $parser = MooseX::Getopt::Usage::Pod::Text->new(
        width    => $self->width,
        headings => $self->headings
    );
    my $out;
    $parser->output_string(\$out);
    $parser->parse_string_document($pod);

    $out = colored($colours->{error}, $err)."\n".$out if $err;

    if ( defined $exit ) {
        print $out;
        exit $exit;
    }
    return $out;
}

sub manpage {
    my $self   = shift;

    $self->_set_color_handling('never');

    my $pod = $self->_get_pod( sections => $self->man_sections );

    open my $fh, "<", \$pod or die;
    pod2usage( -verbose => 2, -input => $fh );
}

# Get the pod for the target class. Fills in missing sections.
sub _get_pod {
    my $self = shift;
    my %args = @_;
    my $opt_style = $args{options_style} || "pod";
    my $sections  = $args{sections} || [];
    my $gclass    = $self->getopt_class;

    # Grab all the pod text (strips out the code).
    my $pod = $self->pod_file ? podselect_text( $self->pod_file ) : "";

    # XXX Some dirty pod regexp hacking. Needs moving to a real parser.
    # Insert SYNOPSIS if not there. After NAME or top of pod.
    unless ($pod =~ m/^=head1\s+SYNOPSIS\s*$/ms) {
        my $synopsis = "\n=head1 SYNOPSIS\n\n".$self->format."\n";
        if ($pod =~ m/^=head1\s+NAME\s*$/ms) {
            $pod =~ s/(^=head1\s+NAME\s*\n.*?)(^=|\z)/$1$synopsis\n\n$2/ms;
        }
        else {
            $pod = "$synopsis\n$pod";
        }
    }

    # Insert OPTIONS if not there. After DESCRIPTION or SYNOPSIS or end of pod.
    unless ($pod =~ m/^=head1\s+OPTIONS\s*$/ms) {
        my $newpod = "\n=head1 OPTIONS\n\n";
        if ($pod =~ m/^=head1\s+DESCRIPTION\s*$/ms) {
            $pod =~ s/(^=head1\s+DESCRIPTION\s*\n.*?)(^=|\z)/$1$newpod$2/ms;
        }
        elsif ($pod =~ m/^=head1\s+SYNOPSIS\s*$/ms) {
            $pod =~ s/(^=head1\s+SYNOPSIS\s*\n.*?)(^=|\z)/$1$newpod$2/ms;
        }
        else {
            $pod = "$pod\n$newpod";
        }
    }

    # Add options list to OPTIONS
    my $meth = "_options_$opt_style";
    my $options = $self->$meth;
    $pod =~ s/(^=head1\s+OPTIONS\s*\n.*?)
              (^=|\z)
             /$1\n$options$2/msx;

    # Process the SYNOPSIS
    $pod =~ s/(^=head1\s+SYNOPSIS\s*\n)  # The header $1
              (.*?)                      # Content $2
              (^=|\z)                    # Next section or eof $3
             /$1.$self->_parse_format($2).$3/mesx;

    # Select again to trim down to just the sections asked for.
    my $out = "";
    open my $fhin,  "<", \$pod or die;
    open my $fhout, ">", \$out or die;
    my $selector = Pod::Select->new();
    $selector->select(@$sections);
    $selector->parse_from_filehandle($fhin, $fhout);
    return $out;
}

# Return list of class attributes that are options.
sub _getopt_attrs {
    my $self   = shift;
    my $gclass = $self->getopt_class;
    my $attr_sort = $self->attr_sort;
    return sort { $attr_sort->($a, $b) } $gclass->_compute_getopt_attrs;
}

# Generate POD version of the options from the meta info.
sub _options_pod {
    my $self   = shift;

    my @attrs = $self->_getopt_attrs;
    my $options_pod = "";
    $options_pod .= "=over 4\n\n";
    foreach my $attr (@attrs) {
        my $label = $self->_attr_label($attr);
        $options_pod .= "=item B<$label>\n\n";
        $options_pod .= ($attr->documentation || "")."\n\n";
    }
    $options_pod .= "=back\n\n";
    return $options_pod;
}

# Generate (colored) text version of the options from meta info.
sub _options_text {
    my $self = shift;
    my $args = { @_ };
    my $colours = $self->colours;

    my @attrs = $self->_getopt_attrs;
    my $max_len = 0;
    my (@req_attrs, @opt_attrs);
    foreach (@attrs) {
        my $len  = length($self->_attr_label($_));
        $max_len = $len if $len > $max_len;
        if ( $_->is_required && !$_->has_default && !$_->has_builder ) {
            push @req_attrs, $_;
        }
        else {
            push @opt_attrs, $_;
        }
    }

    my $groups  = $self->groups;
    $groups  = @req_attrs ? 1 : 0 if not defined $groups;
    my $indent = $groups ? 4 : 0;

    my $out = " ";
    $out .= colored($colours->{heading}, "Required:")."\n"
        if $groups && @req_attrs;
    $out .= $self->_attr_str($_, max_len => $max_len, indent => $indent )."\n"
        foreach @req_attrs;
    $out .= colored($colours->{heading}, "Optional:")."\n"
        if $groups && @opt_attrs;
    $out .= $self->_attr_str($_, max_len => $max_len, indent => $indent )."\n"
        foreach @opt_attrs;
    $out =~ s{\n}{\n }gsm; # Make into pod preformat para
    $out .= "\n\n";

    return $out;
}

sub _parse_format {
    my $self    = shift;
    my $fmt     = shift or confess "No format";
    my $colours = $self->colours;

    $fmt =~ s/%c/colored $colours->{command}, prog_name()/ieg;
    $fmt =~ s/%a/$self->_format_opt_line('a')/ieg;
    $fmt =~ s/%r/$self->_format_opt_line('r')/ieg;
    $fmt =~ s/%o/$self->_format_opt_line('o')/ieg;
    $fmt =~ s/%%/%/g;
    # TODO - Be good to have a include that generates a list of the opts
    #        %r - required  %a - all  %o - options
    $fmt =~ s/^(.*?:\n)/colored $colours->{heading}, "$1"/egm;
    $self->_colourise(\$fmt);
    return $fmt;
}

sub _format_opt_line {
    my $self = shift;
    my $group = shift;

    my @attrs;
    if ( !$group || $group eq "a" ) {
        @attrs = $self->_getopt_attrs;
    }
    elsif ( $group eq "r" ) {
        @attrs = grep {
            $_->is_required && !$_->has_default && !$_->has_builder
        } $self->_getopt_attrs;
    }
    elsif ( $group eq "o" ) {
        @attrs = grep {
            !($_->is_required && !$_->has_default && !$_->has_builder)
        } $self->_getopt_attrs;
    }
    else {
        confess "Unknown grouping: $group";
    }

    my @out;
    foreach my $attr (@attrs) {
        my $opt = "";
        my $label = $self->_attr_label($attr);
        $opt .= "$label";
        if ( not $attr->type_constraint->is_a_type_of("Bool") ) {
            $opt .= "=".uc($attr->name)
        }
        if (!$attr->is_required || $attr->has_default || $attr->has_builder) {
            $opt = "[$opt]";
        }
        push @out, $opt;
    }
    return join(" ", @out);;
}

# Return the full label, including aliases and dashes, for the passed attribute
sub _attr_label {
    my $self   = shift;
    my $attr   = shift || confess "No attr";
    my $gclass = $self->getopt_class;

    my ( $flag, @aliases ) = $gclass->_get_cmd_flags_for_attr($attr);
    my $label = join " ", map {
        length($_) == 1 ? "-$_" : "--$_"
    } ($flag, @aliases);
    return $label;
}

# Return the formated and coloured usage string for the passed attribute.
sub _attr_str {
    my $self    = shift;
    my $attr    = shift or confess "No attr";
    my %args    = @_;
    my $max_len = $args{max_len} or confess "No max_len";
    my $indent  = $args{indent} || 0;
    my $colours = $self->colours;

    local $Text::Wrap::columns  = $self->width;
    local $Text::Wrap::unexpand = $self->unexpand;
    local $Text::Wrap::tabstop  = $self->tabstop;

    my $label = $self->_attr_label($attr);

    my $docs  = "";
    my $pad   = $max_len - length($label);
    my $def   = $attr->has_default ? $attr->default : undef;
    (my $type = $attr->type_constraint) =~ s/(\w+::)*//g;
    $docs .= colored($colours->{type}, "$type. ") if $type;
    $docs .= colored($colours->{default_value}, "Default=$def").". "
        if defined $def && ! ref $def;
    $docs  .= $attr->documentation || "";

    my $col1 = (" " x $indent).$label;
    $col1 .= "".( " " x $pad );
    my $out = wrap($col1, (" " x ($max_len + 9)), " - $docs" );
    $self->_colourise(\$out);
    return $out;
}

# Extra colourisation for the attributes usage string. Think syntax highlight.
sub _colourise {
    my $self    = shift;
    my $out     = shift || "";
    my $colours = $self->colours;

    my $str = ref $out ? $out : \$out;
    $$str =~ s/(^|\s|\[)(--?[\w?]+)/"$1".colored $colours->{flag},"$2"/ge;
    return ref $out ? $out : $$str;
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=pod

=head1 NAME

MooseX::Getopt::Usage::Formatter - 

=head1 SYNOPSIS

 my $fmtr = MooseX::Getopt::Usage::Formatter->new(
    getopt_class => 'Some::Getopt::Class'
 );
 $fmtr->usage;
 $fmtr->man;

=head1 DESCRIPTION

Internal module to do the heavy lifting of usage message and man page
generation for L<MooseX::Getopt::Usage>. See it's documentation for usage and
attribute descriptions.

=head1 ATTRIBUTES

=head2 getopt_class

=head2 colours

=head2 headings

=head2 format

=head2 attr_sort

=head2 use_color

=head2 unexpand

=head2 tabstop

=head1 FUNCTIONS

=head2 podselect_text

=head1 METHODS

=head2 usage

=head2 manpage

=head2 prog_name

The name of the program, grabbed at BEGIN time before someone decides to
change it.

=head1 SEE ALSO

L<MooseX::Getopt::Usage>, L<Moose>, L<perl>.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no exception.
See L<MooseX::Getopt::Usage/BUGS> for details of how to report bugs.

=head1 ACKNOWLEDGEMENTS

Thanks to Hans Dieter Pearcey for prog name grabbing. See L<Getopt::Long::Descriptive>.

=head1 AUTHOR

Mark Pitchless, C<< <markpitchless at gmail.com> >>

=head1 COPYRIGHT

Copyright 2012 Mark Pitchless 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


package Template::Plugin::XML::File;

use strict;
use warnings;
use Template::Plugin::XML;
use base 'Template::Plugin::File';

our $VERSION    = 2.15;
our $DEBUG      = 0                       unless defined $DEBUG;
our $EXCEPTION  = 'Template::Exception'   unless defined $EXCEPTION;
our $XML_PLUGIN = 'Template::Plugin::XML' unless defined $XML_PLUGIN;
our $FILE_TYPES = {
    name     => 'name',
    file     => 'name',
    xml_file => 'name',
    fh       => 'handle',
    handle   => 'handle',
    xml_fh   => 'handle',
};


sub new {
    my $class   = shift;
    my $context = shift;
    my $params  = @_ && ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my ($source, $type);
    
    my $self = bless { 
        debug   => delete $params->{ debug  },
        libxml  => delete $params->{ libxml },
    }, $class;

    # apply default for debug from package variable
    $self->{ debug  } = $DEBUG unless defined $self->{ debug };

    if (@_) {
        # first positional argument is file name or XML string
        $source = shift;
        $type   = $XML_PLUGIN->detect_filehandle($source) ? 'handle' : 'name'; 
        $self->{  type } = $type;
        $self->{ $type } = $source;
    }
    else {
        # look in named params for a known type
        while (my ($param, $type) = each %$FILE_TYPES) {
            if (defined ($source = delete $params->{ $param })) {
                $self->{  type } = $type;
                $self->{ $type } = $source;
            }
        }
    }

    return $self->throw('a file name or file handle must be specified')
        unless defined $self->{ type };

    return $self;
}


sub type {
    return $_[0]->{ type };
}


sub name {
    return $_[0]->{ name };
}


sub libxml {
    my $self = shift;
    return $self->{ libxml };
}

sub dom {
    my $self = shift;
    my $args = @_ && ref $_[-1] eq 'HASH' ? pop(@_) : { };

    return $self->{ dom } ||= do {
        my ($parser, $dom);

        if ($parser = $self->{ libxml }) {
            if (defined $self->{ name }) {
                # file name
                eval { $dom = $parser->parse_file($self->{ name }) }
                    || $self->throw("failed to parse $self->{ name }: $@");
            }
            else {
                # file handle
                eval { $dom = $parser->parse_fh($self->{ handle }) }
                    || $self->throw("failed to parse file handle: $@");
            }
        }
        else {
            eval { require XML::DOM } 
                || $self->throw("XML::DOM not available: $@");

            $parser = XML::DOM::Parser->new(%$args)
                || $self->throw("failed to create parser");

            # TODO: must call dispose() on any XML::DOM documents we create
            if (defined $self->{ name }) {
                # file name
                eval { $dom = $parser->parsefile($self->{ name }) }
                    || $self->throw("failed to parse $self->{ name }: $@");
            }
            else {
                # file handle
                local $/ = undef;
                my $fh   = $self->{ handle };
                my $text = <$fh>;
                eval { $dom = $parser->parse($text) }
                    || $self->throw("failed to parse $self->{ name }: $@");
            }
        }
        $dom;
    };
}

#------------------------------------------------------------------------
# handle()
# 
# TODO: this currently returns the handle iff one was specified as a
# constructor arg, and undef otherwise.  But it would be nice if it
# opened the file for you (using any mode/write/append/create params
# specified either in the constructor or as args) and returned the handle.
# Then you could write [% dir.file('foo.xml').handle %]
#------------------------------------------------------------------------

sub handle {
    return $_[0]->{ handle };
}


sub debug {
    return $_[0]->{ debug };
}

sub throw {
    my $self = shift;
    die $Template::Plugin::XML::EXCEPTION->new( 'XML.File' => join('', @_) );
}



1;

__END__

=head1 NAME

Template::Plugin::XML::File - TT plugin for XML files

=head1 SYNOPSIS

    # different want to specify an XML file name
    [% USE xf = XML.File( filename ) %]
    [% USE xf = XML.File( file     = filename ) %]
    [% USE xf = XML.File( name     = filename ) %]
    [% USE xf = XML.File( xml_file = filename ) %]

    # different want to specify an XML file handle
    [% USE xf = XML.File( handle ) %]
    [% USE xf = XML.File( fh       = handle ) %]
    [% USE xf = XML.File( handle   = handle ) %]
    [% USE xf = XML.File( xml_fh   = handle ) %]

    [% xf.type   %]   # 'name' or 'handle'
    [% xf.name   %]   # filename (if defined)
    [% xf.handle %]   # file handle (if defined)


=head1 DESCRIPTION

TODO

=head1 METHODS

TODO

=head1 AUTHORS

Andy Wardley, Mark Fowler and others...

=head1 COPYRIGHT

TODO

=head1 SEE ALSO

L<Template|Template>, L<Template::Plugins>,
L<Template::Plugin::XML::DOM>, L<Template::Plugin::XML::RSS>,
L<Template::Plugin::XML::Simple>, L<Template::Plugin::XML::XPath>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

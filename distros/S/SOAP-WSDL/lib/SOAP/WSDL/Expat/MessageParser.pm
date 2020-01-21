#!/usr/bin/perl
package SOAP::WSDL::Expat::MessageParser;
use strict; use warnings;

use SOAP::WSDL::XSD::Typelib::Builtin;
use SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType;

use base qw(SOAP::WSDL::Expat::Base);

BEGIN { require Class::Std::Fast };

our $VERSION = 3.004;

# GLOBALS
my $OBJECT_CACHE_REF = Class::Std::Fast::OBJECT_CACHE_REF();

# keep track of classes loaded
my %LOADED_OF = ();

sub new {
    my ($class, $args) = @_;
    my $self = {
        class_resolver => $args->{ class_resolver },
        strict => exists $args->{ strict } ? $args->{ strict } : 1,
    };

    bless $self, $class;

    # could be written as && - but Devel::Cover doesn't like that
    if ($args->{ class_resolver }) {
        $self->load_classes()
            if ! exists $LOADED_OF{ $self->{ class_resolver } };
    }
    return $self;
}

sub class_resolver {
    my $self = shift;
    if (@_) {
        $self->{ class_resolver } = shift;
        $self->load_classes()
            if ! exists $LOADED_OF{ $self->{ class_resolver } };
    }
    return $self->{ class_resolver };
}

sub load_classes {
    my $self = shift;

    return if $LOADED_OF{ $self->{ class_resolver } };

    # requires sorting to make sub-packages load after their parent
    for (sort values %{ $self->{ class_resolver }->get_typemap }) {
        no strict qw(refs);
        my $class = $_;

        # a bad test - do you know a better one?
        next if $class eq '__SKIP__';
        next if defined *{ "$class\::" }; # check if namespace exists

        # Require takes a bareword or a file name - we have to take
        # the filname road here...
        $class =~s{ :: }{/}xmsg;
        require "$class.pm";    ## no critic (RequireBarewordIncludes)
    }
    $LOADED_OF{ $self->{ class_resolver } } = 1;
}

sub _initialize {
    my ($self, $parser) = @_;
    $self->{ parser } = $parser;

    delete $self->{ data };                     # remove potential old results
    delete $self->{ header };

    my $characters;

    # Note: $current MUST be undef - it is used as sentinel
    # on the object stack via if (! defined $list->[-1])
    # DON'T set it to anything else !
    my $current = undef;
    my $list = [];                      # node list (object stack)

    my $path = [];                      # current path
    my $skip = 0;                       # skip elements
    my $depth = 0;

    my %content_check = $self->{strict}
        ? (
            0 => sub {
                    die "Bad top node $_[1]" if $_[1] ne 'Envelope';
                    die "Bad namespace for SOAP envelope: " . $_[0]->recognized_string()
                        if $_[0]->namespace($_[1]) ne 'http://schemas.xmlsoap.org/soap/envelope/';
                    $depth++;
                    return;
            },
            1 => sub {
                    $depth++;
                    if ($_[1] eq 'Body') {
                        if (exists $self->{ data }) { # there was header data
                            $self->{ header } = $self->{ data };
                            delete $self->{ data };
                            $list = [];
                            $path = [];
                            undef $current;
                        }
                    }
                    return;
            }
        )
        : (
            0 => sub { $depth++ },
            1 => sub { $depth++ },
        );

    # use "globals" for speed
    my ($_prefix, $_method, $_class, $_leaf) = ();

    my $char_handler = sub {
        return if (!$_leaf);    # we only want characters in leaf nodes
        $characters .= $_[1];   # add to characters
        return;                 # return void
    };

    no strict qw(refs);
    $parser->setHandlers(
        Start => sub {
            # my ($parser, $element, %attrs) = @_;

            $_leaf = 1;  # believe we're a leaf node until we see an end

            # call methods without using their parameter stack
            # That's slightly faster than $content_check{ $depth }->()
            # and we don't have to pass $_[1] to the method.
            # Yup, that's dirty.
            return &{$content_check{ $depth }}
                if exists $content_check{ $depth };

            push @{ $path }, $_[1];        # step down in path
            return if $skip;               # skip inside __SKIP__

            # resolve class of this element
            $_class = $self->{ class_resolver }->get_class( $path );

            if (! defined($_class) and $self->{ strict }) {
                die "Cannot resolve class for "
                    . join('/', @{ $path }) . " via " . $self->{ class_resolver };
            }

            if (! defined($_class) or ($_class eq '__SKIP__') ) {
                $skip = join('/', @{ $path });
                $_[0]->setHandlers( Char => undef );
                return;
            }

            # step down in tree (remember current)
            #
            # on the first object (after skipping Envelope/Body), $current
            # is undef.
            # We put it on the stack, anyway, and use it as sentinel when
            # going through the closing tags in the End handler
            #
            push @$list, $current;

            # cleanup. Mainly here to help profilers find the real hot spots
            undef $current;

            # cleanup
            $characters = q{};

            # Create and set new objects using Class::Std::Fast's object cache
            # if possible, or blessing directly into the class in question
            # (circumventing constructor) here.
            # That's dirty, but fast.
            #
            # TODO: check whether this is faster under all perls - there's
            # strange benchmark results...
            #
            # The alternative would read:
            # $current = $_class->new({ @_[2..$#_] });
            #
            $current = pop @{ $OBJECT_CACHE_REF->{ $_class } };
            if (not defined $current) {
                my $o = Class::Std::Fast::ID();
                $current = bless \$o, $_class;
            }

            # set attributes if there are any
            ATTR: {
                if (@_ > 2) {
                    # die Data::Dumper::Dumper(@_[2..$#_]);
                    my %attr = @_[2..$#_];
                    if (my $nil = delete $attr{nil}) {
                        # TODO: check namespace
                        if ($nil && $nil ne 'false') {
                            undef $characters;
                            last ATTR if not (%attr);
                        }
                    }
                    $current->attr(\%attr);
                }
            }
            $depth++;

            # TODO: Skip content of anyType / any stuff

            return;
        },

        Char => $char_handler,

        End => sub {

            pop @{ $path };                     # step up in path

            # check __SKIP__
            if ($skip) {
                return if $skip ne join '/', @{ $path }, $_[1];
                $skip = 0;
                $_[0]->setHandlers( Char => $char_handler );
                return;
            }

            $depth--;

            # we only set character values in leaf nodes
            if ($_leaf) {
                # Use dirty but fast access via global variables.
                #
                # The normal way (via method) would be this:
                #
                # $current->set_value( $characters ) if (length($characters));
                #
                $SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType::___value
                    ->{ $$current } = $characters
                        if defined $characters && defined $current; # =~m{ [^\s] }xms;
            }

            # empty characters
            $characters = q{};

            # stop believing we're a leaf node
            $_leaf = 0;

            # return if there's only one elment - can't set it in parent ;-)
            # but set as root element if we don't have one already.
            if (not defined $list->[-1]) {
                $self->{ data } = $current if (not exists $self->{ data });
                return;
            };

            # set appropriate attribute in last element
            # multiple values must be implemented in base class
            # TODO check if hash access is faster
            # $_method = "add_$_localname";
            $_method = "add_$_[1]";
            #
            # fixup XML names for perl names
            #
            $_method =~s{\.}{__}xg;
            $_method =~s{\-}{_}xg;
            $list->[-1]->$_method( $current );

            $current = pop @$list;          # step up in object hierarchy

            return;
        }
    );
    return $parser;
}

sub get_header {
    return $_[0]->{ header };
}

1;

=pod

=head1 NAME

SOAP::WSDL::Expat::MessageParser - Convert SOAP messages to custom object trees

=head1 SYNOPSIS

 my $parser = SOAP::WSDL::Expat::MessageParser->new({
    class_resolver => 'My::Resolver'
 });
 $parser->parse( $xml );
 my $obj = $parser->get_data();

=head1 DESCRIPTION

Real fast expat based SOAP message parser.

See L<SOAP::WSDL::Manual::Parser> for details.

=head2 Skipping unwanted items

Sometimes there's unnecessary information transported in SOAP messages.

To skip XML nodes (including all child nodes), just edit the type map for
the message, set the type map entry to '__SKIP__', and comment out all
child elements you want to skip.

=head1 Bugs and Limitations

=over

=item * Ignores all namespaces

=item * Does not handle mixed content

=item * The SOAP header is ignored

=back

=head1 AUTHOR

Replace the whitespace by @ for E-Mail Address.

 Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2004-2007 Martin Kutter.

This file is part of SOAP-WSDL. You may distribute/modify it under
the same terms as perl itself

=head1 Repository information

 $Id: MessageParser.pm 851 2009-05-15 22:45:18Z kutterma $

 $LastChangedDate: 2009-05-16 00:45:18 +0200 (Sa, 16. Mai 2009) $
 $LastChangedRevision: 851 $
 $LastChangedBy: kutterma $

 $HeadURL: https://soap-wsdl.svn.sourceforge.net/svnroot/soap-wsdl/SOAP-WSDL/trunk/lib/SOAP/WSDL/Expat/MessageParser.pm $


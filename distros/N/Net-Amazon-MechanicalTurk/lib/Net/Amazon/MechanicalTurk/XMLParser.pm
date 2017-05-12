package Net::Amazon::MechanicalTurk::XMLParser;
use strict;
use warnings;
use Carp;
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::DataStructure;
use Net::Amazon::MechanicalTurk::ModuleUtil;
use Net::Amazon::MechanicalTurk::IOUtil;
use IO::File;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };
our @XML_MODULES = qw{
    XML::Parser
    XML::Parser::Lite
};

Net::Amazon::MechanicalTurk::XMLParser->attributes(qw{
    parser
});

sub init {
    my $self = shift;
    if ($#_ >= 0) {
        $self->parser(shift);
    }
    else {
        $self->parser(newParser());
    }
}

sub parseURL {
    my ($self, $url) = @_;
    require LWP::UserAgent;
    my $userAgent = LWP::UserAgent->new(ssl_opts => {verify_hostname => 1});
    # Not available on all LWP's
    #$userAgent->default_headers->push_header("Connection" => "close");
    my $response = $userAgent->get($url);
    if (!$response->is_success) {
        Carp::croak("Could not retrieve url $url - " . $response->status_line);
    }
    return $self->parse($response->content);
}

sub parseFile {
    my ($self, $file) = @_;
    my $in = IO::File->new($file, "r");
    if (!$in) {
        Carp::croak("Could not open file $file - $!");
    }
    return $self->parse($in);
}

sub parse {
    my ($self, $xml) = @_;

    if (UNIVERSAL::isa($xml, "GLOB")) {
        $xml = Net::Amazon::MechanicalTurk::IOUtil->readContents($xml);
    }

    my $context = { root => undef, rootElement => undef, stack => [] };
    my $parser = $self->newParser();
    $parser->setHandlers(
        Start => sub { $self->xmlOnStart($context, @_); },
        End   => sub { $self->xmlOnEnd($context, @_); },
        Char  => sub { $self->xmlOnChar($context, @_); }
    );

    $parser->parse($xml);
    my $data = Net::Amazon::MechanicalTurk::DataStructure->wrap(xmlCondenseText($context->{root})); 

    return (wantarray) ? ($data, $context->{rootElement}) : $data;
}

sub newParser {
    return Net::Amazon::MechanicalTurk::ModuleUtil->requireFirst(@XML_MODULES)->new;
}

sub xmlOnStart {
    my $self = shift;
    my $context = shift;
    my $parser = shift;
    my $element = shift;
    my %attrs = @_;
    
    my $stack = $context->{stack};

    my $node = {};
    if ($#${stack} >= 0) {
        my $parent = $stack->[$#{$stack}];
        if (!exists $parent->{$element}) {
            $parent->{$element} = [];
        }
        push(@{$parent->{$element}}, $node);
        push(@{$stack}, $node);
    }
    else {
        $context->{root} = $node;
        $context->{rootElement} = $element;
        push(@{$stack}, $node);
    } 

    if (%attrs) {
        while (my ($name,$value) = each %attrs) {
            $self->xmlOnStart($context, $parser, $name);
            $self->xmlOnChar($context, $parser, $value);
            $self->xmlOnEnd($context, $parser, $name);
        }
    }
}

sub xmlOnChar {
    my ($self, $context, $parser, $text) = @_;
    my $parent = $context->{stack}[$#{$context->{stack}}];
    if (!exists $parent->{_value}) {
        $parent->{_value} = $text; 
    }
    else {
        $parent->{_value} .= $text;
    }
}

sub xmlOnEnd {
    my ($self, $context, $parser, $element) = @_;
    pop(@{$context->{stack}}); 
}

sub xmlCondenseText {
    my ($node) = @_;

    return unless defined ($node);

    while (my ($name, $array) = each(%$node)) {
        if ($name eq "_value") {
            if ($array =~ /^\s*$/) {
                delete $node->{$name};
            }
            next;
        }

        next unless UNIVERSAL::isa($array, "ARRAY");

        for (my $i=0; $i<=$#{$array}; $i++) {
            my $subNode = $array->[$i];
            if (UNIVERSAL::isa($subNode, 'HASH')) {
                if (exists $subNode->{_value} and $subNode->{_value} =~ /^\s*$/) {
                    delete $subNode->{_value};
                }
                if (exists $subNode->{_value} and (scalar keys %$subNode) == 1) {
                    $array->[$i] = $subNode->{_value}; 
                }
                elsif ((scalar keys %$subNode) == 0) {
                    $array->[$i] = undef;
                }
                else {
                    xmlCondenseText($subNode);
                }
            }
        }
    }

    return $node;
}

return 1;

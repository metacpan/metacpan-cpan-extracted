#
# Module Parse::Eyapp::Options
#
# This module is based on Francois Desarmenien Parse::Yapp module
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon, all rights reserved.

package Parse::Eyapp::Options;

use strict;
use Carp;

############################################################################
#Definitions of options
#
# %known_options    allowed options
#
# %default_options  default
#
# %actions          sub refs to execute if option is set with ($self,$value)
#                   as parameters
############################################################################
#
#A value of '' means any value can do
#
my(%known_options)= (
    language    =>  {
        perl    => "Ouput parser for Perl language",
# for future use...
#       'c++'   =>  "Output parser for C++ language",
#       c       =>  "Output parser for C language"
    },
    linenumbers =>  {
        0       =>  "Don't embbed line numbers in parser",
        1       =>  "Embbed source line numbers in parser"
    },
    firstline   =>  {
        ''      =>  "Line number where the input grammar starts"
    },
    inputfile   =>  {
        ''      =>  "Input file name: will automagically fills input"
    },
    prefix      =>  {
        ''      =>  "Accept if a prefix of the input belongs to the language"
    },
    classname   =>  {
        ''      =>  "Class name of parser object (Perl and C++)"
    },
    standalone  =>  {
        0       =>  "Don't create a standalone parser (Perl and C++)",
        1       =>  "Create a standalone parser"
    },
    buildingtree   =>  {
        0       =>  "Not building AST (for lists)",
        1       =>  "Building AST (for lists)"
    },
    input       =>  {
        ''      =>  "Input text of grammar"
    },
    template    => {
        ''      =>  "Template text for generating grammar file"
    },
    prefixname   =>  {
        ''      =>  "Prefix for the Tree Classes"
    },
    modulino   =>  {
        ''      =>  "Produce modulino code at the end of the generated module"
    },
    start      =>  {
        ''      =>  "Specify start symbol"
    },
    tree  =>  {
        0       =>  "don't build AST",
        1       =>  "build AST"
    },
    nocompact  =>  {
        0       =>  "Do not compact action tables. No DEFAULT field for 'STATES'",
        1       =>  "Compact action tables"
    },
    lexerisdefined  =>  {
        0       =>  "Built a lexer",
        1       =>  "don't build a lexer"
    },
);

my(%default_options)= (
    language => 'perl',
    firstline => 1,
    linenumbers => 1,
    inputfile => undef,
    classname   => 'Parser',
    standalone => 0,
    buildingtree => 1,
    input => undef,
    template => undef,
    shebang => undef,
    prefixname => '',
    modulino => undef,
    tree => undef,
    nocompact => 0,
    lexerisdefined => 0,
);

my(%actions)= (
    inputfile => \&__LoadFile
);

#############################################################################
#
# Actions
#
# These are NOT a method, although they look like...
#
# They are super-private routines (that's why I prepend __ to their names)
#
#############################################################################
sub __LoadFile {
    my($self,$filename)=@_;

    return if defined($self->{OPTIONS}{input});

        open(IN,"<$filename")
    or  croak "Cannot open input file '$filename' for reading";
    $self->{OPTIONS}{input}=join('',<IN>);
    close(IN);
}

#############################################################################
#
# Private methods
#
#############################################################################

sub _SetOption {
    my($self)=shift;
    my($key,$value)=@_;

    $key=lc($key);

        @_ == 2
    or  croak "Invalid number of arguments";

        exists($known_options{$key})
    or  croak "Unknown option: '$key'";

    if(exists($known_options{$key}{lc($value)})) {
        $value=lc($value) if defined($value);
    }
    elsif(not exists($known_options{$key}{''})) {
        croak "Invalid value '$value' for option '$key'";
    }

        exists($actions{$key})
    and &{$actions{$key}}($self,$value);

    $self->{OPTIONS}{$key}=$value;
}

sub _GetOption {
    my($self)=shift;
    my($key)=map { lc($_) } @_;

        @_ == 1
    or  croak "Invalid number of arguments";

        exists($known_options{$key})
    or  croak "Unknown option: '$key'";

    $self->{OPTIONS}{$key};
}

#############################################################################
#
# Public methods
#
#############################################################################

#
# Constructor
#
sub new {
    my($class)=shift;
    my($self)={ OPTIONS => { %default_options } };

        ref($class)
    and $class=ref($class);
    
    bless($self,$class);

    $self->Options(@_);

    $self;
}

#
# Specify one or more options to set
#
sub Options {
    my($self)=shift;
    my($key,$value);

        @_ % 2 == 0
    or  croak "Invalid number of arguments";

    while(($key,$value)=splice(@_,0,2)) {
        $self->_SetOption($key,$value);
    }
}

#
# Set (2 parameters) or Get (1 parameter) values for one option
#
sub Option {
    my($self)=shift;
    my($key,$value)=@_;

        @_ == 1
    and return $self->_GetOption($key);

        @_ == 2
    and return $self->_SetOption($key,$value);

    croak "Invalid number of arguments";

}

1;

__END__


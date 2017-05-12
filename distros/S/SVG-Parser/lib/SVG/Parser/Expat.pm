package SVG::Parser::Expat;
use strict;

require 5.004;

use base qw(XML::Parser SVG::Parser::Base);
use SVG 2.0;

use vars qw($VERSION @ISA);
$VERSION="1.03";

#---------------------------------------------------------------------------------------

=head1 NAME

SVG::Parser::Expat - XML Expat Parser for SVG documents

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use SVG::Parser::Expat;

  die "Usage: $0 <file>\n" unless @ARGV;

  my $xml;
  {
      local $/=undef;
      $xml=<>;
  }

  my $parser=new SVG::Parser::Expat;

  my $svg=$parser->parse($xml);

  print $svg->xmlify;

=head1 DESCRIPTION

SVG::Parser::Expat is the Expat-specific parser module used by SVG::Parser when an
underlying XML::Parser-based parser is selected. It may also be used directly, as shown
in the synopsis above.

Use SVG::Parser to retain maximum flexibility as to which underlying parser is chosen.
Use SVG::Parser::Expat to supply Expat-specific parser options or where the presence
of XML::Parser is known and/or preferred.

=head2 EXPORTS

None. However, an alternative parent class (other than XML::Parser) can be specified by
passing the package name to SVG::Parser::Expat in the import list. For example:

    use SVG::Parser::Expat qw(My::XML::Parser::Subclass);

Where My::XML::Parser::Subclass is a subclass like:

    package My::XML::Parser::Subclass;
    use strict;
    use vars qw(@ISA);
    use XML::Parser;
    @ISA=qw(XML::Parser);

    ...custom methods...

    1;

When loaded via SVG::Parser, this parent class may be specified by placing it after
the '=' in a parser specification:

    use SVG::Parser qw(Expat=My::XML::Parser::Subclass);

See L<SVG::Parser> for more details.

=head2 EXAMPLES

See C<svgexpatparse> in the examples directory of the distribution.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG>, L<SVG::Parser>, L<SVG::Parser::SAX>, L<XML::Parser>

=cut

#---------------------------------------------------------------------------------------
# SVG::Parser::Expat constructor. Attributes with no minus prefix are passed to
# the parent parser class. Attributes with a minus are set locally.

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my %attrs=@_;

    # pass on non-minus-prefixed attributes to XML::Parser
    my %parser_attrs;
    foreach (keys %attrs) {
        $parser_attrs{$_}=delete $attrs{$_} unless /^-/;
    }

    my $parser=$class->SUPER::new(%parser_attrs);
    $parser->setHandlers(
        XMLDecl    => sub { XMLDecl($parser, @_) },
        Doctype    => sub { Doctype($parser, @_) },
        Init       => sub { StartDocument($parser, @_) },
        Final      => sub { FinishDocument($parser, @_) },

        Start      => sub { StartTag($parser, @_) },
        End        => sub { EndTag($parser, @_) },
        Char       => sub { Text($parser, @_) },
        CdataStart => sub { $parser->SVG::Parser::Base::CdataStart(@_) },
        CdataEnd   => sub { $parser->SVG::Parser::Base::CdataEnd(@_) },
        Proc       => sub { PI($parser, @_) },
        Comment    => sub { Comment($parser, @_) },

	Unparsed   => sub { Unparsed($parser, @_) },
        Notation   => sub { Notation($parser,@_) },
        Entity     => sub { Entity($parser, @_) },
	Element    => sub { Element($parser,@_) },
        Attlist    => sub { Attlist($parser,@_) },
    );

    # minus-prefixed attributes stay here, double-minus to SVG object
    foreach (keys %attrs) {
        if (/^-(-.+)$/) {
            $parser->{__svg_attr}{$1}=$attrs{$_};
        } else {
            $parser->{$_}=$attrs{$_};
        }
    }

    return $parser;
}

#---------------------------------------------------------------------------------------
# Import method to change default inheritance, if required

sub import {
    my $package=shift;

    # permit an alternative XML::Parser subclass to be our parent class
    if (@_) {
        my $superclass=shift;

        $ISA[0]=$superclass,return if eval qq[
            use $superclass qw(@_);
            1;
        ];

        die "Parent parser class $superclass not found: $@\n";
    }
}

#---------------------------------------------------------------------------------------
# Handlers

# create and set SVG document object as root element
sub StartDocument {
    my ($parser,$expat)=@_;
    return $parser->SVG::Parser::Base::StartDocument();
}

# handle start of element - extend chain by one
sub StartTag {
    my ($parser,$expat,$type,%attrs)=@_;
    return $parser->SVG::Parser::Base::StartTag($type,%attrs);
}

# handle end of element - shorten chain by one
sub EndTag {
    my ($parser,$expat,$type)=@_;
    return $parser->SVG::Parser::Base::EndTag($type);
}

# handle cannonical data (text)
sub Text {
    my ($parser,$expat,$text)=@_;
    return $parser->SVG::Parser::Base::Text($text);
}

# handle processing instructions
sub PI {
    my ($parser,$expat,$target,$data)=@_;
    return $parser->SVG::Parser::Base::PI($target,$data);
}

# handle XML Comments
sub Comment {
    my ($parser,$expat,$data)=@_;
    return $parser->SVG::Parser::Base::Comment($data);
}

# return root SVG document object as result of parse()
sub FinishDocument {
    my ($parser,$expat)=@_;
    return $parser->SVG::Parser::Base::FinishDocument();
}

#---------------------------------------------------------------------------------------

# handle XML declaration, if present
sub XMLDecl {
    my ($parser,$expat,$version,$encoding,$standalone)=@_;
    return $parser->SVG::Parser::Base::XMLDecl($version,$encoding,$standalone);
}

# handle Doctype declaration, if present
sub Doctype {
    my ($parser,$expat,$name,$sysid,$pubid,$internal)=@_;
    return $parser->SVG::Parser::Base::Doctype($name,$sysid,$pubid,$internal);
}

#---------------------------------------------------------------------------------------

# Unparsed (Expat, Entity, Base, Sysid, Pubid, Notation)
sub Unparsed {
    my ($parser,$expat,$name,$base,$sysid,$pubid,$notation)=@_;
    return $parser->SVG::Parser::Base::Unparsed($name,$base,$sysid,$pubid,$notation);
}

# Notation (Expat, Notation, Base, Sysid, Pubid)
sub Notation {
    my ($parser,$expat,$name,$base,$sysid,$pubid)=@_;
    return $parser->SVG::Parser::Base::Notation($name,$base,$sysid,$pubid);
}

# Entity (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
sub Entity {
    my ($parser,$expat,$name,$val,$sysid,$pubid,$data,$isp)=@_;
    return $parser->SVG::Parser::Base::Entity($name,$val,$sysid,$pubid,$data,$isp);
}

# Element (Expat, Name, Model)
sub Element {
    my ($parser,$expat,$name,$model)=@_;
    return $parser->SVG::Parser::Base::Element($name,$model);
}

# Attlist (Expat, Elname, Attname, Type, Default, Fixed)
sub Attlist {
    my ($parser,$expat,$name,$attr,$type,$default,$fixed)=@_;
    return $parser->SVG::Parser::Base::Attlist($name,$attr,$type,$default,$fixed);
}

#---------------------------------------------------------------------------------------
# SAX -> Expat compatability

sub parse_file {
    shift->parsefile(@_);
}

#---------------------------------------------------------------------------------------

1;

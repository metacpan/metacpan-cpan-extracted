# Tools.pm -- SGML::Parser::OpenSP::Tools module
#
# $Id: Tools.pm,v 1.9 2006/08/30 14:50:35 hoehrmann Exp $

package SGML::Parser::OpenSP::Tools;
use 5.008; 
use strict;
use warnings;
use Carp;

# white-space as defined in XML 1.0
our $WHITESPACE = qr/[\x20\x09\x0d\x0a]/;

sub value_attribute
{
    my $attr = shift;
    
    # illegal input
    return 0 unless defined $attr;
    return 0 unless ref $attr eq "HASH";
    return 0 unless exists $attr->{Type};
    
    # these cannot have values
    return 0 if $attr->{Type} eq "implied";
    return 0 if $attr->{Type} eq "invalid";
    
    return 1;
}

sub specified_attribute
{
    my $attr = shift;

    return 0 unless value_attribute($attr);
    return 0 if $attr->{Defaulted} ne "specified";
    return 1;
}

sub defaulted_attribute
{
    my $attr = shift;
    return 0 unless value_attribute($attr);
    return 0 if $attr->{Defaulted} eq "specified";
    return 1;
}

sub attribute_value
{
    my $attr = shift;
    
    # ...
    return unless value_attribute($attr);

    # tokenized attributes
    return $attr->{Tokens}
      if $attr->{Type} eq "tokenized";

    my $value = "";
    
    # type is cdata
    foreach my $chunk (@{$attr->{CdataChunks}})
    {
        # todo: fix this for SDATA
        # todo: fix this for non-sgml chars

        $value .= $chunk->{Data};
    }
    
    return $value;
}

sub split_pi
{
    my $orig = shift;

    return unless defined $orig;
    return unless length $orig;
    
    my ($targ, $data) = split /$WHITESPACE/, $orig, 1;
    
    return $targ, $data;
}

sub split_message
{
    my $mess = shift; # message text
    my $name = shift; # file name
    my $oent = shift; # show_open_entities
    my $errn = shift; # show_error_numbers
    my $oelm = shift; # show_open_elements
    my $mess_debug = $mess;
    
    my %resu;
    
    if ($oent)
    {
        while($mess =~ s/^In entity (\S+) included from (.*?):(\d+):(\d+)\s+//)
        {
            push @{$resu{open_entities}}, { EntityName   => $1,
                                            FileName     => $2,
                                            LineNumber   => $3,
                                            ColumnNumber => $4 }
        }
    }
    
    # this splits the error message into its components. this is designed
    # to cope with most if not all delimiter problems inherent to the
    # message format which does not escape delimiters which can result in
    # ambiguous data. The following format is expected by this code
    # each error message component starts on a new line which is either
    # the first line or something that follows \n, then an optional formal
    # system identifier such as <LITERAL> or <OSFILE>, then the file name
    # as reported by $p->get_location->{FileName} then the line and finally
    # the column number -- for each message there should thus be three
    # individual components, line, column, "text" -- which can contain
    # additional components depending on the message, see below.
    
    my @comp = split(/(?:^|\n)(?:<[^>]+>)?\Q$name\E:(\d+):(\d+):\s*/, $mess);
    
    # check for proper format, the first component must be
    # empty and each entry must have line, column and text
    croak "Unexpected error message format ($mess_debug)"
      if length $comp[0] or (@comp - 1) % 3;
    
    # remove empty component
    shift @comp;
    
    # the first component is the primary message
    $resu{primary_message}->{LineNumber}   = shift @comp;
    $resu{primary_message}->{ColumnNumber} = shift @comp;
    
    if ($errn)
    {
        # with show_error_numbers the first component is
        # "<module>.<error number>", remove and store it
        $comp[0] =~ s/^(\d+)\.(\d+)://;
        
        # this can happen if it was incorrectly specified
        # that show_error_numbers was enabled or if OpenSP
        # has a bug that causes the number to be missing
        croak "message lacks error number information"
          unless defined $1 and defined $2;
        
        $resu{primary_message}->{Module} = $1;
        $resu{primary_message}->{Number} = $2;
    }
    
    # next component is a character indicating the severity
    $comp[0] =~ s/^(\w):\s+//;

    # this can happen if OpenSP has a bug in this regard
    croak "severity character missing from error message"
      unless defined $1;
      
    $resu{primary_message}->{Severity} = $1;

    # trim trailing white-space from the text
    $comp[0] =~ s/\s+$//;

    # the remainder of the message is the error message text
    $resu{primary_message}->{Text} = shift @comp;

    # optional auxiliary message
    if (@comp > 3 or (@comp == 3 and !$oelm))
    {
        # trim trailing white-space from the text
        $comp[2] =~ s/\s+$//;
        
        $resu{aux_message}->{LineNumber}   = shift @comp;
        $resu{aux_message}->{ColumnNumber} = shift @comp;
        $resu{aux_message}->{Text}         = shift @comp;
    }
    
    # open elements are optional in SGML declarations, etc.
    if ($oelm and @comp)
    {
        # this should only happen in case of OpenSP bugs
        croak "unexpected number of components in message"
          unless @comp == 3;

        croak "expected listing of open elements"
          unless pop(@comp) =~ /^open elements: (.*)/s;
          
        $resu{open_elements} = $1;
    }
    
    \%resu
}

1;

__END__

=pod

=head1 NAME

SGML::Parser::OpenSP::Tools - Tools to process OpenSP output

=head1 DESCRIPTION

Routines to post-process OpenSP event data.

=head1 UTILITY FUNCTIONS

=over 4

=item specified_attribute($attribute)

specified_attribute returns a true value if the attribute is
of type C<cdata> or C<tokenized> and has its C<Defaulted> property
set to C<specified>. For example

  sub start_element
  {
    my $self = shift;
    my $elem = shift;
    my @spec = grep specified_attribute($_),
                    values %{$elem->{Attributes}};

    # @spec contains all explicitly specified attributes
  }

=item defaulted_attribute($attribute)

defaulted_attribute returns a true value if the attribute is
of type C<cdata> or C<tokenized> and has its C<Defaulted> property
set to something but C<specified>. For all attributes, the following
always holds true,

  !defined(attribute_value($_)) or
  defaulted_attribute($_) or
  specified_attribute($_)

since only defaulted and specified attributes can have a value.

=item value_attribute($attribute)

Returns true if the value can have a value, i.e., it is either
specified or defaulted.

=item attribute_value($attribute)

attribute_value returns a textual representation of the value
of an attribute as reported to a C<start_element> handler or
C<undef> if no value is available.

=item split_message($message, $filename, $open_ent, $error_num, $open_elem)

split_message splits an OpenSP error message into its components,
the error or warning message, an optional auxiliary message that
provides additional information about the error, like the first
occurence of an ID in case of duplicate IDs in a document, each
accompanied by line and column numbers relevant to the message,
and depending on the parser configuration the open entities for
the message, the error number of the message and a list of the
current open elements.

It returns a hash reference like

  # this is always present
  primary_message =>
  {
    Number       => 141,       # only if $p->show_error_numbers(1)
    Module       => 554521624, # only if $p->show_error_numbers(1)
    ColumnNumber => 9,
    LineNumber   => 12,
    Severity     => 'E',
    Text         => 'ID "a" already defined'
  },

  # only some messages have an aux_message 
  aux_message =>
  {
    ColumnNumber => 9,
    LineNumber   => 11,
    Text         => 'ID "a" first defined here'
  },

  # iff $p->show_open_elements(1) and there are open elements
  open_elements => 'html body[1] (p[1])',

  # iff $p->show_open_entities(1) and there are open entities
  # other than the document, but the document will be reported
  # if the error is in some other entity
  open_entities => [
  {
    ColumnNumber => 55,
    FileName     => 'example.xhtml',
    EntityName   => 'html',
    LineNumber   => 2
  }, ... ],

This would typically be used like

  sub error
  {
    my $self = shift;
    my $erro = shift;
    my $mess = $erro->{Message};

    # parser is the SGML::Parser::OpenSP
    # object stored in the handler object
    my $loca = $self->{parser}->get_location;
    my $name = $loca->{FileName};

    my $splt = split_message($mess, $name,
                             $self->{parser}->show_open_entities,
                             $self->{parser}->show_error_numbers,
                             $self->{parser}->show_open_elements);

    # ...
  }

A more convenient way to access this function is provided by the
C<SGML::Parser::OpenSP> module which you can use like

  sub error
  {
    my $self = shift;
    my $erro = shift;

    my $mess = $self->{parser}->split_message($erro);

    # relevant data is now $mess and $erro->{Severity}
    # of which the latter provides more detailed information
    # than $mess->{primary_message}->{Severity}, see the
    # SGML::Parser::OpenSP documentation for details
  }

=item split_pi($data)

split_pi splits the data of a processing instructions at the first
white space character into two components where white space character
is defined in the $WHITESPACE package variable, qr/[\x20\x09\x0d\x0a]/
by default. It returns C<undef> if there is no data to split.

  sub pi
  {
    my $self = shift;
    my $proc = shift;

    my ($target, $data) = split_pi($proc->{Data});

    # ...
  }

=back

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2006-2008 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut

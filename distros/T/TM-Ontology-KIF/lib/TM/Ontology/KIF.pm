package TM::Ontology::KIF;

use 5.008003;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = ( );
our @EXPORT    = qw();

our $VERSION   = '0.02';
our $REVISION  = '$Id: KIF.pm,v 1.1.1.1 2004/07/25 23:49:52 rho Exp $';

use Data::Dumper;

#-- KIF Grammar
##                       <nocheck>
my $grammar = q{
                      {
                       my $handlers;
                       my $sentence_count = 0;
                       }


                       startrule : { $handlers = $arg[0]; } kiffile

                       kiffile   : result(s)

                       result    : sentence { 
                                             &{$handlers->{sentence}} ($item{sentence});
                                             die "limit reached" if defined $handlers->{sentence_limit} && $sentence_count++ >= $handlers->{sentence_limit};
#warn Data::Dumper::Dumper ($item{sentence});
                                             1; }

                       sentence  : '(' ( quantsent | logsent | relsent ) ')' { $return = $item[2]; }

                       quantsent : 'forall' '(' variable(s) ')' sentence  { $return = [ 'forall', $item{'variable'}, $item{sentence} ]; } |
                                   'exists' '(' variable(s) ')' sentence  { $return = [ 'exists', $item{'variable'}, $item{sentence} ]; }

                       logsent   : 'not' sentence           { $return = [ 'not', $item{sentence}      ];} |
                                   'and' sentence(s)        { $return = [ 'and', $item{sentence}      ];} |
                                   'or'  sentence(s)        { $return = [ 'or',  $item{sentence}      ];} |
                                   '=>'  sentence sentence  { $return = [ '=>',  $item[2], $item[3]   ];} |
                                   '<=>' sentence sentence  { $return = [ '<=>', $item[2], $item[3]   ];}

                       relsent   : (word | variable ) term(s?)             { $return = [ $item[1], $item{'term'} ];}

                       term      : variable |
                                   funterm  |
                                   number   |
                                   word     |
                                   string   |
                                   sentence |
                                   '<=>'    |
                                   '=>'

                       funterm   : '(' funword term(s) ')' { $return = [ $item{funword}, $item{'term'} ];}

                       variable  : /(\?|\@)[\w-]+/

                       word      : /[a-zA-Z]+/

                       funword   : /\w+Fn/

                       string    : /"[^"]*"/

                       number    : /(\-)?\d+(\.\d+)?(e\-?\d)?/
};


=pod

=head1 NAME

TM::Ontology::KIF - Topic Map KIF Parser

=head1 SYNOPSIS

  use TM::Ontology::KIF;
  my $kif = new TM::Ontology::KIF (start_line_nr  => 42,
				   sentence_limit => 1000,
				   sentence       => sub {
                                                          my $s = shift;
                                                          print "got sentence ";
                                                          ....
                                                     }
                                   );
  use IO::Handle;
  my $input = new IO::Handle;
  ....
  eval {
     $kif->parse ($input);
  }; warn $@ if $@;


=head1 DESCRIPTION

This module provides KIF parsing functionality for IO::* streams. The concept
is that the parser is reading a text stream and will invoke a subroutine which
the calling application provided whenever a KIF sentence has been successfully
parsed. (Similar to XML SAX processing).

=head2 Caveats

=over

=item Compliance

Currently, only a subset of the KIF syntax

   http://logic.stanford.edu/kif/dpans.html

is supported, just enough to make the SUMO (IEEE) parse.  Feel free to
patch this module or bribe/contact me if you need more.

=item Speed

Currently I am using Parse::RecDescent underneath for parsing. While
it is incredibly flexible and powerful, it is also dead slow.

=back

=head1 INTERFACE

=head2 Constructor

The constructor creates a new stream object. As parameters a hash can be provided
whereby the following fields are recognized:

=over

=item C<sentence>:

If this is provided, then the value will be interpreted as subroutine reference. The subroutine
will be executed every time a KIF sentence has been parsed whereby the sentence will be based as
the only parameter. Otherwise, things will fail horribly.

=item C<start_line_nr>:

If this is provided, then all lines will be skipped until this line number is reached.

=item C<sentence_limit>

If this is present it limits the number of sentences which will be delivered back.
When this limit is exceeded an exception will be raised.

=back

=cut

sub new {
    my $class = shift;
    my %par   = @_;
    $par{sentence} ||= sub { };
    die "no subroutine reference" unless ref ($par{sentence}) eq 'CODE';
    return bless { %par }, $class;
}

=pod

=head2 Methods

=over

=item C<parse>

This methods takes a text stream and tries to parse this according to KIF. Whenever
particular portions of the input stream have been successfully parsed, they exist as
an abstract trees and will be handed over to the handlers which have been setup in the
stream constructor.

=cut

use IO::Handle;

sub parse {
    my $self  = shift;
    my $input = shift;

    my $text; # we use Parse::RecDescent here, this one wants to have a string
    my $line_nr = 0;
    while (!$input->eof) {
	my $l = $input->getline;
	next if defined $self->{start_line_nr} && $line_nr++ < $self->{start_line_nr};
	$l =~ s/^;.*?$//g;                    # remove comments here
	$text .= $l;
    }

    use Parse::RecDescent;
    $::RD_HINT = 1;
    my $parser = new Parse::RecDescent ($grammar) or die "Problem in grammar";
    $parser->startrule (\$text, 1, $self)         or die "Error in parsing";
}

=pod

=back

=head1 AUTHOR

Robert Barta, E<lt>rho@bigpond.net.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

__END__

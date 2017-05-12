use strict;
use warnings;
package Pod::Stupid;
BEGIN {
  $Pod::Stupid::VERSION = '0.005';
}
BEGIN {
  $Pod::Stupid::DIST = 'Pod-Stupid';
}
# ABSTRACT: The simplest, stupidest 'pod parser' possible

use English qw( -no_match_vars );
use Carp qw( croak );
use Data::Dumper;
use Scalar::Util qw( blessed );
#use Encode;

# right now, I've hard-coded unix EOL into these regexen... I probably
# should use \R, however it's not supported on older perls, though the
# docs say it's equivalent to this:
my $eol = qr{ (?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}]) };


# match the end of any pod paragraph (pp). I'm being generous by allowing
# a pp to end by detecting another command pp with the lookahead thus not
# enforcing the "must end with blank line" part of the spec.
my $pod_paragraph_end_qr = qr{ (?: [\n]{2,} | [\n]+(?= ^=\w+) | \z ) }msx;

# match a command paragraph. Note: the 'cut' directive is handled
# specially because it signifies the end of a block of pod and the
# spec states that it need not be followed by a blank line. If any
# other directives should be parsed the same way, put them in the
# qw() list below. Still, only 'cut' will end a block of pod.
my $cut_like_cmds_qr = join '|', qw( cut );
my $pod_command_qr = qr{
    (                        # capture everything as $1
      (?:
        ^[=]                   # start of pod command
        (?!$cut_like_cmds_qr)  # exclude cut, to be handled below
        (\w+?)                 # command type (directive) as $2
        (\d*)                  # optional command 'level' as $3
        (?:                      # optionally followed by...
          (?:
            [ \t]+ | \n            # blank space OR single newline
          )
          (.*?)                  # and 'command text' as $4
        )?
        $pod_paragraph_end_qr  # followed by paragraph end pattern
      )
      |                     # OR... special case for cut
      (?:                    # (and cut-like) commands...
        ^[=]                 # start of pod command
        ($cut_like_cmds_qr)  # capture command as $5
        (?:                  # if followed by...
          [ \t]+               # horizontal white space
          (.*?)                # and grab anything else as $6
          [\n]                 # up to the end of line
          |                   # OR
          [\n]                 # just the end of the line
        )
        [\n]?                 # and possibly one more newline
      )
    )
}msx;

# match a non-command paragraph. this only applies when
# already within a pod block.
my $pod_paragraph_qr = qr{
    (               # grab everything as $1...
      (               # but just the paragraph contents as $2
        (?:
          ^[^=].*?$   # any lines that do not begin with =
        )+?           # until...
      )
      $pod_paragraph_end_qr  # two newlines or end of string
    )
}msx;


sub new { return bless {}, shift; }


# NOTE: the 'c' modifiers on the regexes in this sub are *critical!* NO TOUCH!
sub parse_string {
    my ($self, $text) = @_;

    croak "missing \$text parameter" if ! defined $text;

    # collect the parsed pieces here:
    my @parsed_pieces;

    # find the beginning of the next pod block in the text
    # (which, by definition, is any pod command)
    while ( $text =~ m{ \G (.*?) $pod_command_qr }msxgc ) {
        my $non_pod_txt = $1;
        my $pod_txt     = $2;
        my $cmd_type    = $3 || $6;
        my $cmd_level   = $4 || '';
        my $cmd_text    = $5 || $7 || '';

        #print "COMMAND: [=$cmd_type$cmd_level $cmd_text]\n\n"; ### DEBUG

        # record the text that wasn't pod, if any
        push @parsed_pieces, { 
            non_pod   => 1,
            orig_txt  => $non_pod_txt,
            start_pos => $LAST_MATCH_START[1],
            end_pos   => $LAST_MATCH_END[1],
        } if $non_pod_txt;

        # record the pod found
        push @parsed_pieces, {
            is_pod    => 1,
            cmd_type  => $cmd_type,
            cmd_level => $cmd_level,
            cmd_txt   => $cmd_text,
            orig_txt  => $pod_txt,
            start_pos => $LAST_MATCH_START[2],
            end_pos   => $LAST_MATCH_END[2],
        };

        # cut *always* signifies the end of a block of pod
        next if $cmd_type eq 'cut';

        #if ( $cmd_type eq 'encoding' ) {
        #    # change encoding of string - this feels wonky to me..
        #    my $pos = pos( $text );
        #    $cmd_text =~ s/\A\s*|\s*\z//gms;
        #    $text = Encode::decode( $cmd_text, $text );
        #    pos( $text ) = $pos;
        #}

        # look for paragraphs within the current pod block
        while ( $text =~ m{ \G $pod_paragraph_qr }msxgc ) {
            my $orig_txt  = $1;
            my $paragraph = $2;

            #print "PARAGRAPH: [$paragraph]\n\n"; ### DEBUG

            push @parsed_pieces, {
                is_pod    => 1,
                paragraph => $paragraph,
                orig_txt  => $orig_txt,
                start_pos => $LAST_MATCH_START[1],
                end_pos   => $LAST_MATCH_END[1],
            };
        }
    }

    # Take care of any remaining text in the string
    my $last_pos  = pos( $text ) || 0;
    my $end_pos   = length( $text ) - 1;
    my $remainder = substr( $text, $last_pos );
    push @parsed_pieces, {
        non_pod   => 1,
        orig_txt  => $remainder,
        start_pos => $last_pos,
        end_pos   => $end_pos,
    } if $remainder;

    return \@parsed_pieces;
}



sub strip_string {
    my ( $self, $text_ref, $pod_pieces ) = @_;

    croak "missing \$text_ref parameter" unless defined $text_ref;

    # make a copy of the text if necessary.
    $text_ref = \"$text_ref" unless ref $text_ref;

    # get the pieces if we don't already have them
    $pod_pieces = $self->parse_string( $$text_ref ) unless ref $pod_pieces;

    my $shrinkage = 0;
    for my $pp ( @$pod_pieces ) {

        next unless $pp->{is_pod};

        my $length      = $pp->{end_pos}   - $pp->{start_pos};
        my $new_start   = $pp->{start_pos} - $shrinkage;
        substr( $$text_ref, $new_start, $length, '' );

        $shrinkage += $length;
    }
    return $$text_ref;
}

1 && q{Beauty is in the eye of the beholder}; # Truth.



=pod

=head1 NAME

Pod::Stupid - The simplest, stupidest 'pod parser' possible

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Pod::Stupid;
  
  my $file = shift; # '/some/file/with/pod.pl';
  my $original_text = do { local( @ARGV, $/ ) = $file; <> }; # slurp
  
  my $ps = Pod::Stupid->new();
  
  # in scalar context returns an array of hashes.
  my $pieces = $ps->parse_string( $original_text );
  
  # get your text sans all POD
  my $stripped_text = $ps->strip_string( $original_text );
  
  # reconstruct the original text from the pieces...
  substr( $stripped_text, $_->{start_pos}, 0, $_->{orig_txt} )
      for grep { $_->{is_pod} } @$pieces;
  
  print $stripped_text eq $original_text ? "ok - $file\n" : "not ok - $file\n";

=head1 DESCRIPTION

This module was written to do one B<simple> thing: Given some text
as input, split it up into pieces of POD "paragraphs" and non-POD
"whatever" and output an AoH describing each piece found, in order.

The end user can do whatever s?he wishes with the output AoH. It is
trivially simple to reconstruct the input from the output, and
hopefully I've included enough information in the inner hashes that
one can easily perform just about any other manipulation desired.

=head1 INDESCRIPTION

There are a bunch of things this module will B<NOT> do:

=over 4

=item *

Create a "parse tree"

=item *

Pod validation (it either parses or not)

=item *

Pod cleanup

=item *

"Handle" encoded text (but it I<should> still parse)

=item *

Feed your cat

=back

However, it may make it easier to do any of the above, with a lot
less time and effort spent trying to grok many of the other POD
parsing solutions out there.

A particular design decision I've made is to avoid needing to save
any state. This means there's no need or advantage to instantiating
an object, except for your own preferences. You can use any method
as either an object method or a class method and it will work the
same way for both. This design should also discourage me from trying
to bloat Pod::Stupid with every feature that tickles my fancy (or
yours!) but still, B<I encourage any feature requests!>

=head1 METHODS

=head2 new

the most basic object constructor possible. Currently takes no
options because the object neither has nor needs to keep any state.

This is only here if you want to use this module with an OO interface.

=head2 parse_string

Given a string, parses for pod and, in scalar context, returns an AoH
describing each pod paragraph found, as well as any non-pod.

  # typical usage
  my $pieces = $ps->parse_string( $text );
  
  # to separate pod and non-pod
  my @pod_pieces     = grep { $_->{is_pod}  } @$pieces;
  my @non_pod_pieces = grep { $_->{non_pod} } @$pieces;

=head2 strip_string

given a string or string ref, and (optionally) an array of pod pieces,
return a copy of the string with all pod stripped out and an AoH
containing the pod pieces. If passed a string ref, that string is
modified in-place. In any case you can still always get the stripped
string and the array of pod parts as return values.

  # most typical usage
  my $txt_nopod = $ps->strip_string( $text );
  
  # pass in a ref to change string in-place...
  $ps->strip_string( \$text );   # $text no longer contains any pod
  
  # if you need the pieces...
  my ( $txt_nopod, $pieces ) = $ps->strip_string( $text );
  
  # if you already have the pod pieces...
  my $txt_nopod = $ps->strip_string( $text, $pod_pieces );

=head1 KNOWN LIMITATIONS

=over 4

=item *

Currently only works on files with unix-style line endings.

=back

=head1 TODO

This is only what I've thought of... B<suggestions *very* welcome!!!>

=over 4

=item *

Fix aforementioned limitation

=item *

More comprehensive tests

=item *

A utility module to do common things with the output

=back

=head1 CREDITS

Uri Guttman for giving me the task that led to my shaving this particular yak

=head1 SEE ALSO

=over 4

=item *

L<Pod::Simple>

=item *

L<Pod::Parser>

=item *

L<Pod::Stripper>

=item *

L<Pod::Escapes>

=item *

L<perlpod>

=item *

L<perlpodspec>

=item *

L<perldoc>

=item *

and about a million other things...

=back

=head1 POD TERMINOLOGY FOR DUMMIES (aka: me)

=head2 paragraphs

In Pod, everything is a paragraph. A paragraph is simply one or more
consecutive lines of text. Multiple paragraphs are separated from each other
by one or more blank lines.

Some paragraphs have special meanings, as explained below.

=head2 command

A command (aka directive) is a paragraph whose first line begins with a
character sequence matching the regex m/^=([a-zA-Z]\S*)/

I've actually been a bit more generous, matching m/^=(\w+)/ instead.
Don't rely on that though. I may have to change to be closer to the spec
someday.

In the above regex, the type of command would be in $1. Different types of
commands have different semantics and validation rules yadda yadda.

Currently, the following command types (directives) are described in the
Pod Spec L<http://perldoc.perl.org/perlpodspec.html> and technically,
a proper Pod parser should consider anything else an error. (I won't though)

=over 4

=item *

head[\d] (\d is a number from 1-4)

=item *

pod

=item *

cut

=item *

over

=item *

item

=item *

back

=item *

begin

=item *

end

=item *

for

=item *

encoding

=back

=head2 directive

Ostensibly a synonym for a command paragraph, I consider it a subset of that,
specifically the "command type" as described above.

=head2 verbatim paragraph

This is a paragraph where each line begins with whitespace.

=head2 ordinary paragraph

This is a prargraph where each line does B<not> begin with whitespace

=head2 data paragraph

This is a paragraph that is between a pair of "=begin identifier" ...
"=end identifier" directives where "identifier" does not begin with a
literal colon (":")

I do not plan on handling this type of paragraph in any special way.

=head2 block

A Pod block is a series of paragraphs beginning with any directive except
"=cut" and ending with the first occurence of a "=cut" directive or the
end of the input, whichever comes first.

=head2 piece

This is a term I'm introducting myself. A piece is just a hash containing info
on a parsed piece of the original string. Each piece is either pod or not pod.
If it's pod it describes the kind of pod. If it's not, it contains a 'non_pod'
entry. All pieces also include the start and end offsets into the original
string (starting at 0) as 'start_pos' and 'end_pos', respectively.

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__










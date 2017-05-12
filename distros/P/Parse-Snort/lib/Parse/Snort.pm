package Parse::Snort;

use strict;
use warnings;
use base qw(Class::Accessor);
use List::Util qw(first);
use Carp qw(carp);

our $VERSION = '0.6';

=head1 NAME

Parse::Snort - Parse and create Snort rules

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Parse::Snort;

    my $rule = Parse::Snort->new(
      action => 'alert',
      proto => 'tcp',
      src => '$HOME_NET', src_port => 'any',
      direction => '->'
      dst =>'$EXTERNAL_NET', dst_port => 'any'
    );

    $rule->action("pass");

    $rule->opts(
	[ 'depth' => 50 ],
	[ 'offset' => 0 ],
	[ 'content' => "perl6" ],
	[ "nocase" ]
    );

    my $rule = Parse::Snort->new();
    $rule->parse('pass tcp $HOME_NET any -> $EXTERNAL_NET 6667;');
    $rule->msg("IRC server");
    my $rule_string = $rule->as_string;
);

=cut 

our @RULE_ACTIONS           = qw/ alert pass drop sdrop log activate dynamic reject /;
our @RULE_ELEMENTS_REQUIRED = qw/ action proto src src_port direction dst dst_port /;
our @RULE_ELEMENTS = ( @RULE_ELEMENTS_REQUIRED, 'opts' );

# create the accessors for the standard parts (note; opts comes later)
__PACKAGE__->mk_accessors(@RULE_ELEMENTS_REQUIRED);


=head1 METHODS

These are the object methods that can be used to read or modify any part of a Snort rule.  B<Please note: None of these methods provide any sort of input validation to make sure that the rule makes sense, or can be parsed at all by Snort.>  

=for comment If input validation is required, check out the L<Parse::Snort::Strict> module.

=over 4

=item new ()

Create a new C<Parse::Snort> object, and return it.  There are a couple of options when creating the object:

=over 4

=item new ( )

Create an unpopulated object, that can be filled in using the individual rule element methods, or can be populated with the L<< parse|/"PARSE" >> method.

=item new ( $rule_string )

Create an object based on a plain text Snort rule, all on one line.  This module doesn't understand the UNIX style line continuations (a backslash at the end of the line) that Snort does.

  $rule_string = 'alert tcp $EXTERNAL_NET any -> $HOME_NET any (msg:"perl 6 download detected\; may the world rejoice!";depth:150; offset:0; content:"perl-6.0.0"; nocase;)'


=item new ( $rule_element_hashref )

Create an object baesd on a prepared hash reference similar to the internal strucutre of the L<Parse::Snort> object.

  $rule_element_hashref = {
    action => 'alert',
    proto => 'tcp',
    src => '$EXTERNAL_NET', src_port => 'any',
    direction => '->',
    dst => '$HOME_NET', dst_port => 'any',
    opts => [
    	[ 'msg' => '"perl 6 download detected\; may the world rejoice!"' ],
    	[ 'depth' => 150 ],
    	[ 'offset' => 0 ].
    	[ 'content' => 'perl-6.0.0' ],
    	[ 'nocase' ],
    ],
      
  };

=back

=cut

sub new {
    my ( $class, $data ) = @_;

    my $self = {
    };

    bless $self, $class;
    $self->_init($data);
}

=for comment
The _init method is called by the new method, to figure out what sort of data was passed to C<new()>.  If necessary, it calls $self->parse(), individual element accessor methods, or simply returns $self.

=cut


sub _init {
    my ( $self, $data ) = @_;

    # were we passed a hashref? (formatted rule in hashref form)
    if ( ref($data) eq "HASH" ) {
        # loop through the bits and set the values
        while ( my ( $method, $val ) = each %$data ) {
            $self->$method($val);
        }
    } elsif ( defined($data) ) {
        # otherwise, interpret this as a plain text rule.
        $self->parse($data);
    }
    # nothing
    return $self;
}

=item parse( $rule_string )

The parse method is what interprets a plain text rule, and populates the rule object.  Beacuse this module does not support the UNIX style line-continuations (backslash at the end of a line) the rule must be all on one line, otherwise the parse will fail in unpredictably interesting and confusing ways.  The parse method tries to interpret the rule from left to right, calling the individual accessor methods for each rule element.  This will overwrite the contents of the object (if any), so if you want to parse multiple rules at once, you will need multiple objects.

  $rule->parse($rule_string);

=cut

sub parse {
    my ( $self, $rule ) = @_;

    # nuke extra whitespace pre/post rule
    $rule =~ s/^\s+//;
    $rule =~ s/\s+$//;

    # 20090823 RGH: m/\s+/ instead of m/ /; bug reported by Leon Ward
    my @values = split( m/\s+/, $rule, scalar @RULE_ELEMENTS );    # no critic

    for my $i ( 0 .. $#values ) {
        my $meth = $RULE_ELEMENTS[$i];
        $self->$meth( $values[$i] );
    }
}

=back

=head2 METHODS FOR ACCESSING RULE ELEMENTS

You can access the core parts of a rule (action, protocol, source IP, etc) with the method of their name.  These are read/write L<Class::Accessor> accessors.  If you want to read the value, don't pass an argument.  If you want to set the value, pass in the new value.  In either case it returns the current value, or undef if the value has not been set yet.

=for comment Need to figure out "truth" again in perl sense, do I simply "return;" or "return undef" if the value doesn't exist?  For Parse::Snort::Strict, I need to have two things: 1) make it known to the user that the rule failed to parse, 2) which (may?) be a different meaning than the rule element being empty/undefined.

=over 4

=item action 

The rule action.  Generally one of the following: C<alert>, C<pass>, C<drop>, C<sdrop>, or C<log>.

=item proto

The protocol of the rule.  Generally one of the following: C<tcp>, C<udp>, C<ip>, or C<icmp>.

=item src

The source IP address for the rule.  Generally a dotted decimal IP address, Snort $HOME_NET variable, or CIDR block notation.

=item src_port

The source port for the rule.  Generally a static port, or a contigious range of ports.

=item direction

The direction of the rule.  One of the following: C<->> C<<>> or C<<->.

=item dst

The destination IP address for the rule.  Same format as C<src>

=item dst_port

The destination port for the rule.  Same format as C<src>

=item opts ( $opts_array_ref )

=item opts ( $opts_string )

The opts method can be used to read existing options of a parsed rule, or set them.  The method takes two forms of arguments, either an Array of Arrays, or a rule string.

=over 4

=item $opts_array_ref

  $opts_array_ref = [
       [ 'msg' => '"perl 6 download detected\; may the world rejoice!"' ],
       [ 'depth' => 150 ],
       [ 'offset' => 0 ].
       [ 'content' => 'perl-6.0.0' ],
       [ 'nocase' ],
  ]

=item $opts_string

  $opts_string='(msg:"perl 6 download detected\; may the world rejoice!";depth:150; offset:0; content:"perl-6.0.0"; nocase;)';

The parenthesis surround the series of C<key:value;> pairs are optional.

=back

=cut

sub opts {
    my ( $self, $args ) = @_;

    if ($args) {

        # setting
        if ( ref($args) eq "ARRAY" ) {

            # list interface:
            # ([depth => 50], [offset => 0], [content => "perl6"], ["nocase"])
            $self->set( 'opts', $args );
        } else {

            # string interface
            # 'depth:50; offset:0; content:"perl\;6"; nocase;'
            if ( $args =~ m/^\(/ ) {
              # remove opts parens if they exist
                $args =~ s/^\((.+)\)$/$1/;
            }

            # When I first wrote this regex I thought it was slick.
            # I still think that, but 2y after doing it the first time
            # it just hurt to look at.  So, /x modifier we go!
            my @set = map { [ split( m/\s*:\s*/, $_, 2 ) ] } $args =~ m/
                \s*         # ignore preceeding whitespace
                (           # begin capturing
                 (?:        # grab characters we want
                     \\.    # skip over escapes
                     |
                     [^;]   # or anything but a ;
                 )+?        # ? greedyness hack lets the \s* actually match
                )           # end capturing
                \s*         # ignore whitespace between value and ; or end of line
                (?:         # stop anchor at ...
                  ;         # semicolon
                  |         # or
                  $         # end of line
                )
                \s*/gx;
            $self->set( 'opts', @set );
        }
    } else {
        # getting
        return $self->get('opts');
    }
}

sub _single_opt_accessor {
    my $opt = shift;
    return sub {
        my ( $self, $val ) = @_;

        # find the (hopefully) pre-existing option in the opts AoA
        my $element;

        if ( defined $self->get('opts') ) {
            $element = first { $_->[0] eq $opt } @{ $self->get('opts') };
        }

        if ( ref($element) ) {

            # preexisting
            if ($val) { $element->[1] = $val; }
            else { return $element->[1]; }
        } else {

            # doesn't exist
            if ($val) {

                # setting
                if ( scalar $self->get('opts') ) {

                    # other opts exist, tack it on the end
                    $self->set(
                        'opts',
                        @{ $self->get('opts') },
                        [ $opt, $val ]
                    );
                } else {

                    # blank slate, create the AoA
                    $self->set( 'opts', [ [ $opt, $val ] ] );
                }
            } else {

                # getting
                return;
            }
        }
      }
}

# helper accessors that poke around inside rule options

*sid       = _single_opt_accessor('sid');
*rev       = _single_opt_accessor('rev');
*msg       = _single_opt_accessor('msg');
*classtype = _single_opt_accessor('classtype');
*gid       = _single_opt_accessor('gid');
*metadata  = _single_opt_accessor('metadata');
*priority  = _single_opt_accessor('priority');

=back

=head2 HELPER METHODS FOR VARIOUS OPTIONS

=over 4

=item sid

=item rev

=item msg

=item classtype

=item gid

=item metadata

=item priority

The these methods allow direct access to the rule option of the same name

  my $sid = $rule_obj->sid(); # reads the sid of the rule
  $rule_obj->sid($sid); # sets the sid of the rule
  ... etc ...

=item references

The C<references> method permits read-only access to the C<reference:> options in the rule.  This is in the form of an array of arrays, with each reference in the format

  [ 'reference_type' => 'reference_value' ]

To modify references, use the C<opts> method to grab all the rule options, modify it to your needs, and use the C<opts> method to save your changes back to the rule object.


  $references = $rule->references(); # just the references
  $no_references = grep { $_->[0] != "reference" } @{ $rule->opts() }; # everything but the references

=cut 

sub references {
    my ($self) = shift;
    my @references =
      map { [ split( m/,/, $_->[1], 2 ) ] }
      grep { $_->[0] eq "reference" } @{ $self->get('opts') };
    return \@references;
}

=item as_string

The C<as_string> method returns a string that matches the normal Snort rule form of the object.  This is what you want to use to write a rule to an output file that will be read by Snort.

=cut

sub as_string {
    my $self = shift;
    my $ret;
    my @missing;

    # we may be incomplete
    @missing = grep { $_ } map { exists( $self->{$_} ) ? undef : $_ } @RULE_ELEMENTS_REQUIRED;

    # stitch together the required bits
    if (! scalar @missing)
    { $ret .= sprintf( "%s %s %s %s %s %s %s", @$self{@RULE_ELEMENTS_REQUIRED} ); }

    # tack on opts if they exist
    if ( defined $self->get('opts') )
    { $ret .= sprintf( " (%s)", join( " ", map { defined($_->[1]) ? "$_->[0]:$_->[1];" : "$_->[0];" } @{ $self->get('opts') } )); }

    #carp sprintf( "Missing required rule element(s): %s", join( " ", @missing )) if (scalar @missing);
    return ! scalar @missing ? $ret : undef;
}

=back

=head1 AUTHOR

Richard G Harman Jr, C<< <perl-cpan at richardharman.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parse-snort at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Snort>.
I will be notified, and then you' ll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Snort

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Snort>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Snort>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Snort>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Snort>

=back

=head1 DEPENDENCIES

L<Test::More>, L<Class::Accessor>, L<List::Util>

=head1 ACKNOWLEDGEMENTS

MagNET #perl for putting up with me :)

=head1 COPYRIGHT & LICENSE

Copyright 2007 Richard Harman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

!!'mtfnpy!!';

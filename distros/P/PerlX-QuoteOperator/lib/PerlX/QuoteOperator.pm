package PerlX::QuoteOperator;
use strict;
use warnings;
use 5.008001;

use Devel::Declare ();
use Text::Balanced ();
use base 'Devel::Declare::Context::Simple';

our $VERSION = '0.08';
our $qtype   = __PACKAGE__ . '::qtype';
our $parser  = __PACKAGE__ . '::parser';
our $debug   = __PACKAGE__ . '::debug';

sub import {
    my ($self, $name, $param, $caller) = @_;
    
    # not importing unless name & parameters provided (TBD... check these)
    return unless $name && $param;
    
    # called directly and not via a PerlX::QuoteOperator::* module
    unless ($caller) {
        $caller = caller;
        $self   = __PACKAGE__->new;
    }
    
    # quote like operator to emulate.  Default is qq// unless -emulate is provided
    $self->{ $qtype } = $param->{ -emulate } || 'qq';  
    
    # invoke my heath robinson parser or not?  
    # (not using parser means just insert quote operator and leave to Perl)
    $self->{ $parser } = $param->{ -parser } || 0;
    
    # debug or not to debug... that is the question
    $self->{ $debug } = $param->{ -debug } || 0;

    # Create D::D trigger for $name in calling program
    Devel::Declare->setup_for(
        $caller, { 
            $name => { const => sub { $self->parser(@_) } },
        },
    );
    
    no strict 'refs';
    *{$caller.'::'.$name} = $param->{ -with };
}

sub parser {
    my $self = shift;
    $self->init(@_);
    $self->skip_declarator;          # skip past "http"
    $self->skipspace;

    my $line = $self->get_linestr;   # get me current line of code

    if ( $self->{ $parser } ) {
        # find start & end of quote operator
        my $pos    = $self->offset;        # position just after "http"
        my $opener = substr( $line, $pos, 1 );
        my $closer = _closing_delim( $opener );
        if ($closer eq $opener) {
            do { $pos++ } until substr( $line, $pos, 1 ) eq $closer;
        }
        else {
            my $text = substr($line, $pos);
            my ($capture, $remaining) = Text::Balanced::extract_bracketed($text, $opener);
            $pos += length $capture;
            $pos--;
        }
        
        # and wrap sub() around quote operator (needed for lists)
        substr( $line, $pos + 1, 0 )      = ')';
        substr( $line, $self->offset, 0 ) = '(' . $self->{ $qtype };
        
    }
    else {
        # Can rely on Perl parser for everything.. just insert quote-like operator
        substr( $line, $self->offset, 0 ) = q{ } . $self->{ $qtype };
    }

    # eg: qURL(http://www.foo.com/baz) => qURL qq(http://www.foo.com/baz)
    # pass back to parser
    $self->set_linestr( $line );
    warn "$line\n" if $self->{ $debug };

    return;
}

sub _closing_delim {
    my $d = shift;
    return ')' if $d eq '(';
    return '}' if $d eq '{';
    return ']' if $d eq '[';
    return '>' if $d eq '<';
    return $d;
}

1;


__END__

=head1 NAME

PerlX::QuoteOperator - Create new quote-like operators in Perl

=head1 VERSION

Version 0.08


=head1 SYNOPSIS

Create a quote-like operator which convert text to uppercase:

    use PerlX::QuoteOperator quc => {
        -emulate => 'q', 
        -with    => sub ($) { uc $_[0] }, 
    };
    
    say quc/do i have to $hout/;
    
    # => DO I HAVE TO $HOUT


=head1 DESCRIPTION

=head2 QUOTE-LIKE OPERATORS

Perl comes with some very handy Quote-Like Operators 
L<http://perldoc.perl.org/perlop.html#Quote-Like-Operators> :)

But what it doesn't come with is some easy method to create your own quote-like operators :(

This is where PerlX::QuoteOperator comes in.  Using the fiendish L<Devel::Declare> under its hood  
it "tricks", sorry "helps!" the perl parser to provide new first class quote-like operators.

=head2 HOW DOES IT DO IT?

The subterfuge doesn't go that deep.  If we take a look at the SYNOPSIS example:

    say quc/do i have to $hout/;
    
Then all PerlX::QuoteOperator actually does is convert this to the following before perl compiles it:

    say quc q/do i have to $hout/;
    
Where 'quc' is a defined sub expecting one argument  (ie, sub ($) { uc $_[0] }  ).

This approach allows PerlX::QuoteOperator to perform the very basic keyhole surgery on the code,
ie. just put in the emulated quote-like operator between keyword & argument.

However this approach does have caveats especially when qw// is being used!.  See CAVEATS.
There is an alternative parser when can be invoked,  see -parser Export parameter.

=head2 WHY?

Bit like climbing Mount Everest... because we can!  ;-)

Is really having something like:

    say quc/do i have to $hout/;
    
so much better than:

    say uc 'do i have to $hout';
    
or more apt this:

    say uc('do i have to $hout');
    
Probably not... at least in the example shown.  But things like this are certainly eye catching:

    use PerlX::QuoteOperator::URL 'qh';
    
    my $content = qh( http://transfixedbutnotdead.com );   # does HTTP request

NOTICE - As for version 0.05 (23rd Feb 2015), PerlX::QuoteOperator::URL was moved to its own distribution.

And this:

    use PerlX::QuoteOperator qwHash => { 
        -emulate    => 'qw',
        -with       => sub (@) { my $n; map { $_ => ++$n } @_ },
    };

    my %months = qwHash/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

Certainly give the code aesthetic a good pause for thought.

=head1 EXPORT

By default nothing is exported:

    use PerlX::QuoteOperator;    # => imports nothing
    
Quote operator is imported when passed a name and options like so:

    use PerlX::QuoteOperator quote_operator_name_i_want_to_use => { }   

A hashref is used to pass the options.

=head2 PARAMETERS

=head3 -emulate

Which Perl quote-like operator required to emulate.  q, qq & qw have all been tested.

Default: emulates qq

=head3 -with

Your quote-like operator code reference / anon subroutine goes here.

Remember to use subroutine prototype (if not using -parser option):

    -with    => sub ($) { uc $_[0] }, 

This is a mandatory parameter.

=head3 -parser

If set then alternative parser kicks in.   This parser currenly works on single line of code only
and must open/close quote with (), {}, [], <> or must have same delimeter for beginning and end of quote:

    -parser => 1
    
When invoked this parser will take this:

    quc/do i have to $hout/;

And by finding the end of the quote will then encapulate it like so:

    quc(q/do i have to $hout/);

Default: Not using alternative parsing.

=head3 -debug

If set then prints (warn) the transmogrified line so that you can see what PerlX::QuoteOperator has done!

    -debug => 1

Default:  No debug.

=head1 FUNCTIONS

=head2 import

Module import sub.

=head2 parser

When keyword (defined quote operator) is triggered then this sub uses L<Devel::Declare> 
to provide necessary keyhole surgery/butchery on the code to make it valid Perl code (think Macro here!).

=head2 _closing_delim

Internal subroutine used in -parser option.

=head1 CAVEATS

Performing a method call or dereference using -> like below will not work:

    use PerlX::QuoteOperator qurl => { 
        -emulate => 'q', 
        -with    => sub ($) { require URI; URI->new($_[0]) },
    };
    
    qurl(http://www.google.com/)->authority;   # Throws an error

Because the parsed qurl line becomes this...

    qurl q(http://www.google.com/)->authority;

... so throwing an error trying to call C<authority> on a string.  See "HOW DOES IT DO IT" for more info.  

A workaround is to use the I<alternative> parser and the line would now be parsed like this:

    qurl(q(http://www.google.com/))->authority;
    
See -parser option for more information.

Also see examples/qw.pl for some more issues with creating qw based quote-like operators. NB. The alternative parser will get around some of these problems but then (potentially) introduces a few new ones! (see TODO)

Recommendation: Stick with Perl parser and all will be fine! 

=head1 WRITING A QUOTE OPERATOR MODULE

This section shows how you can create a module that
defines a custom quote operator,
if you have one that you want to re-use.

Let's say you want a C<qROT13> operator,
which will L<ROT13|http://en.wikipedia.org/wiki/ROT13> a string.
First, here's a simple rot13 function.
Look at the <wikipedia page on rot13|http://en.wikipedia.org/wiki/ROT13>
if you're not familiar with rot13:

    my $rot13 = sub ($) {
        my $string = shift;
        $string =~ y/A-Za-z/N-ZA-Mn-za-m/;
        return $string;
    };

You don't create your module as a subclass of C<PerlX::QuoteOperator>,
but your module creates an instance of it, then calls its C<import()>
method, passing an additional final argument,
which specifies the name of the package
that the operator should be imported into.

Leaving out the rot13 function for ease of reading,
here's a module which defines the operator:

    package PerlX::QuoteOperator::Rot13;
    use PerlX::QuoteOperator ();

    sub import {
        my $class     = shift;
        my $name      = @_ > 0 ? shift : 'qROT13';
        my $export_to = caller();
        my $pqo       = PerlX::QuoteOperator->new();

        $pqo->import($name, { -emulate => 'qq', -with => $rot13 }, $export_to);
    }
    1;

You can now use your module as follows:

    use PerlX::QuoteOperator::Rot13;
    my $string = qROT13|This is a string|;
    print "string = '$string'\n";

=head1 SEE ALSO

=over 4

=item * L<PerlX::QuoteOperator::URL>

=back


=head1 CONTRIBUTORS

Toby Inkster (L<https://metacpan.org/author/TOBYINK>) for Text::Balanced patch to the alternative parser at 0.04



=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/draegtun/PerlX-QuoteOperator/issues>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PerlX::QuoteOperator


You can also look for information at:

=over 4

=item * Github issues & push requests

L<https://github.com/draegtun/PerlX-QuoteOperator/issues>

=item * Old resolved bugs can be found on RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PerlX-QuoteOperator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PerlX-QuoteOperator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PerlX-QuoteOperator>

=item * Search CPAN

L<http://search.cpan.org/dist/PerlX-QuoteOperator/>
L<https://metacpan.org/pod/PerlX::QuoteOperator/>

=back


=head1 ACKNOWLEDGEMENTS

From here to oblivion!:  L<http://transfixedbutnotdead.com/2009/12/16/url-develdeclare-and-no-strings-attached/>

And a round of drinks for the mad genius of L<MST|http://search.cpan.org/~mstrout/> for creating L<Devel::Declare> in the first place!


=head1 DISCLAIMER

This is (near) beta software.   I'll strive to make it better each and every day!

However I accept no liability I<whatsoever> should this software do what you expected ;-)

=head1 COPYRIGHT & LICENSE

Copyright 2009-2015 Barry Walsh (Draegtun Systems Ltd | L<http://www.draegtun.com>), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


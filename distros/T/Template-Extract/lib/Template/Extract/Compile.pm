package Template::Extract::Compile;
$Template::Extract::Compile::VERSION = '0.50';
use strict;
use warnings;
use 5.006;

our ( $DEBUG,  );
our $EXACT = undef();

my ( $paren_id, $block_id );

sub new {
    my $class = shift;
    my $self  = {};
    return bless( $self, $class );
}

sub compile {
    my ( $self, $template, $parser ) = @_;

    $self->_init();

    if ( defined $template ) {
        $parser->{FACTORY} = ref($self);
        $template = $$template if UNIVERSAL::isa( $template, 'SCALAR' );
        $template =~ s/\n+$//;
        $template =~ s/\[%\s*(?:\.\.\.|_|__)\s*%\]/[% \/.*?\/ %]/g;
        $template =~ s/\[%\s*(\/.*?\/)\s*%\]/'[% "' . quotemeta($1) . '" %]'/eg;
        $template =~ s{
            \[%\s*([a-zA-z0-9][a-zA-z0-9\.]*)\s*\=\~\s*(/.*?/)\s*%\]
        }{
            '[% SET ' . $1 . ' = "' . quotemeta($2) . '" %]'
        }mxegi;

        return $parser->parse($template)->{BLOCK};
    }
    ## no critic
    return undef;
}

# initialize temporary variables
sub _init {
    $paren_id = 0;
    $block_id = 0;
}

# utility function to add regex eval brackets
sub _re { "(?{\n    @_\n})" }

# --- Factory API implementation begins here ---

sub template {
    my $regex = $_[1];

    $regex =~ s/\*\*//g;
    $regex =~ s/\+\+/+/g;
    if ($EXACT)
    {
        $regex = "^$regex\$";
    }

    # Deal with backtracking here -- substitute repeated occurences of
    # the variable into backtracking sequences like (\1)
    my %seen;
    $regex =~ s{(                       # entire sequence [1]
        \(\.\*\?\)                      #   matching regex
        \(\?\{                          #   post-matching regex...
            \s*                         #     whitespaces
            _ext\(                      #     capturing handler...
                \(                      #       inner cluster of...
                    \[ (.+?) \],\s*     #         var name [2]
                    \$.*?,\s*           #         dollar with ^N/counter
                    (\d+)               #         counter [3]
                \)                      #       ...end inner cluster
                (.*?)                   #       outer loop stack [4]
            \)                          #     ...end capturing handler
            \s*                         #     whitespaces
        \}\)                            #   ...end post-maching regex
    )}{
        if ($seen{$2, $4}) {                # if var reoccured in the same loop
            "(\\$seen{$2, $4})";            #   replace it with backtracker
        }
        else {
            $seen{$2, $4} = $3;
            if ($+[0] == length $regex) {   # otherwise, if it is the end
                '(.*)' . substr( $1, 5 );   #   make it greedy
            }
            else {
                $1;                         # otherwise, preserve the sequence 
            }
        }
    }gex;

    return $regex;
}

sub foreach {
    my $regex = $_[4];

    # find out immediate children
    my %vars =
      reverse( $regex =~ /_ext\(\(\[(\[?)('\w+').*?\], [^,]+, \d+\)\*\*/g );
    my $vars = join( ',', map { $vars{$_} ? "\\$_" : $_ } sort keys %vars );

    # append this block's id into the _get calling chain
    ++$block_id;
    ++$paren_id;
    $regex =~ s/\*\*/, $block_id**/g;
    $regex =~ s/\+\+/*/g;

    return (

        # sets $cur_loop
        _re("_enter_loop($_[2], $block_id)") .

          # match loop content
          "(?:\\n*?$regex)++()" .

          # weed out partial matches
          _re("_ext(([[$_[2],[$vars]]], \\'leave_loop', $paren_id)**)") .

          # optional, implicit newline
          "\\n*?"
    );
}

sub get {
    return "(?:$1)" if $_[1] =~ m{^/(.*)/$};

    ++$paren_id;

    # ** is the placeholder for parent loop ids
    return "(.*?)" . _re("_ext(([$_[1]], \$$paren_id, $paren_id)\*\*)");
}

sub set {
    my $regex = undef;

    ++$paren_id;

    if ( $_[1][1] =~ m|^/(.*)/$| ) {
        $regex = $1;
    }

    my $val = $_[1][1];
    $val =~ s/^'(.*)'\z/$1/;
    $val = quotemeta($val);

    my $parents =
      join( ',', map { $_[1][0][ $_ * 2 ] } ( 0 .. $#{ $_[1][0] } / 2 ) );

    if ( defined($regex) ) {
        return $1 . _re("_ext(([$parents], \$$paren_id, $paren_id)\*\*)");
    }
    else {
        return '()' . _re("_ext(([$parents], \\\\'$val', $paren_id)\*\*)");
    }
}

sub textblock {
    return quotemeta( $_[1] );
}

sub block {
    my $rv = '';
    foreach my $chunk ( map "$_", @{ $_[1] || [] } ) {
        $chunk =~ s/^#line .*\n//;
        $rv .= $chunk;
    }
    return $rv;
}

sub quoted {
    my $rv = '';

    foreach my $token ( @{ $_[1] } ) {
        if ( $token =~ m/^'(.+)'$/ ) {    # nested hash traversal
            $rv .= '$';
            $rv .= "{$_}" foreach split( /','/, $1 );
        }
        else {
            $rv .= $token;
        }
    }

    return $rv;
}

sub ident {
    return join( ',', map { $_[1][ $_ * 2 ] } ( 0 .. $#{ $_[1] } / 2 ) );
}

sub text {
    return $_[1];
}

# debug routine to catch unsupported directives
sub AUTOLOAD {
    $DEBUG or return;

    require Data::Dumper;
    $Data::Dumper::Indent = $Data::Dumper::Indent = 1;

    our $AUTOLOAD;
    print "\n$AUTOLOAD -";

    for my $arg ( 1 .. $#_ ) {
        print "\n    [$arg]: ";
        print ref( $_[$arg] )
          ? Data::Dumper->Dump( [ $_[$arg] ], ['__'] )
          : $_[$arg];
    }

    return '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Extract::Compile - Compile TT2 templates into regular expressions

=head1 VERSION

version 0.50

=head1 SYNOPSIS

    use Template::Extract::Compile;

    my $template = << '.';
    <ul>[% FOREACH record %]
    <li><A HREF="[% url %]">[% title %]</A>: [% rate %] - [% comment %].
    [% ... %]
    [% END %]</ul>
    .
    my $regex = Template::Extract::Compile->new->compile($template);

    open FH, '>', 'stored_regex' or die $!;
    print FH $regex;
    close FH;

=head1 DESCRIPTION

This module utilizes B<Template::Parser> to transform a TT2 template into
a regular expression suitable for the B<Template::Extract::Run> module.

=head1 METHODS

=head2 new()

Constructor.  Currently takes no parameters.

=head2 compile($template)

Returns the regular expression compiled from C<$template>.

=head1 SEE ALSO

L<Template::Extract>, L<Template::Extract::Run>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2005, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Template-Extract>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Extract>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Template-Extract>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Template-Extract>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Template-Extract>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Template::Extract>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-template-extract at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Template-Extract>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/template-extract>

  git clone git://github.com/shlomif/template-extract.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/template-extract/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2003 by Audrey Tang.

This is free software, licensed under:

  The MIT (X11) License

=cut

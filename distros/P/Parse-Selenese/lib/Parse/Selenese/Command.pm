# ABSTRACT: A Selenese Command
package Parse::Selenese::Command;
use Moose;
use MooseX::AttributeShortcuts;
use Try::Tiny;
use Parse::Selenese::TestCase;
use Carp ();
use HTML::TreeBuilder;
use Template;

our $VERSION = '0.006'; # VERSION

has 'values' => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 0,
    default  => sub { [] }
);

has 'element' => (
    is      => 'ro',
    lazy_build => 1,
);

has 'result' => (
    isa => 'Str',
    is  => 'ro',
    lazy_build => 1,
    predicate => 1,
);

has 'content' => (
    isa       => 'Str',
    is        => 'rw',
    required  => 0,
    clearer   => 1,
    predicate => 1,
);

has '_tree' => (
    isa        => 'HTML::TreeBuilder',
    is         => 'ro',
    clearer    => 1,
    lazy_build => 1,
);

sub _build__tree {
    my $self = shift;
    my $tree = HTML::TreeBuilder->new;
    $tree->store_comments(1);
    return $tree;
}

sub _build_result {
    my $self = shift;
    #warn Data::Dumper->Dump( [$self], ['self'] ) if $self->case eq 'Tests/Backroom/logout_of_backroom.html';
    my $r = '';
    $r = try {
        my ($result) = $self->_tree->look_down( '_tag', 'tr')->attr('class') =~ /status_(.*)/;
        $result;
    } catch {
        ""
    };
    return $r;
}

my $_selenese_command_template = <<'END_SELENESE_COMMAND_TEMPLATE';
<tr>
[% FOREACH value = values -%]
	<td>[% value %]</td>
[% END %]</tr>
END_SELENESE_COMMAND_TEMPLATE

my $_selenese_comment_template = "<!--[% values.1 %]-->\n";

my %command_map = (

    # a comment
    comment => {    # Selenese command name
        func => '#',    # method name in Test::WWW::Selenium
        args => 1,      # number of arguments to pass
    },

    # opens a page using a URL.
    open => {           # Selenese command name
        func => 'open_ok',    # method name in Test::WWW::Selenium
        args => 1,            # number of arguments to pass
    },

    # performs a click operation, and optionally waits for a new page to load.
    click => {
        func => 'click_ok',
        args => 1,
    },
    clickAndWait => {
        func => [             # combination of methods
            {
                func => 'click_ok',
                args => 1,
            },
            {
                func => 'wait_for_page_to_load_ok',
                force_args => [30000],    # force arguments to pass
            },
        ],
    },

    # verifies an expected page title.
    verifyTitle => {
        func => 'title_is',
        args => 1,
    },
    assertTitle => {
        func => 'title_is',
        args => 1,
    },

    # verifies expected text is somewhere on the page.
    verifyTextPresent => {
        func => 'is_text_present_ok',
        args => 1,
    },
    assertTextPresent => {
        func => 'is_text_present_ok',
        args => 1,
    },

# verifies an expected UI element, as defined by its HTML tag, is present on the page.
    verifyElementPresent => {
        func => 'is_element_present_ok',
        args => 1,
    },
    assertElementPresent => {
        func => 'is_element_present_ok',
        args => 1,
    },

# verifies expected text and it's corresponding HTML tag are present on the page.
    verifyText => {
        func => 'text_is',
        args => 2,
    },
    assertText => {
        func => 'text_is',
        args => 2,
    },

    # verifies a table's expected contents.
    verifyTable => {
        func => 'table_is',
        args => 2,
    },
    assertTable => {
        func => 'table_is',
        args => 2,
    },

    # pauses execution until an expected new page loads.
    # called automatically when clickAndWait is used.
    waitForPageToLoad => {
        func => 'wait_for_page_to_load_ok',
        args => 1,
    },

    # pauses execution until an expected UI element,
    # as defined by its HTML tag, is present on the page.
    waitForElementPresent => {
        wait => 1,                      # use WAIT structure
        func => 'is_element_present',
        args => 1,
    },

    store => {
        args         => 1,
        store        => 1,
        pass_through => 1,
    },

    # store text in the variable.
    storeText => {
        args  => 1,
        store => 1,
        func  => 'get_text',
    },
    storeTextPresent => {
        args  => 1,
        store => 1,                   # store value in variable
        func  => 'is_text_present',
    },
    storeElementPresent => {
        args  => 1,
        store => 1,
        func  => 'is_element_present',
    },
    storeTitle => {
        args  => 0,
        store => 1,
        func  => 'get_title',
    },

    # miscellaneous commands
    waitForTextPresent => {
        wait => 1,
        func => 'is_text_present',
        args => 1,
    },

    # type text in the field.
    type => {
        func => 'type_ok',
        args => 2,
    },

    # select option from the <select> element.
    select => {
        func => 'select_ok',
        args => 2,
    },
);


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref $_[0] ) {
        if ( ref $_[0] eq 'ARRAY') {
            return $class->$orig( values => $_[0] );
        } elsif ( ref $_[0] eq 'HTML::Element' ) {
            return $class->$orig( content => $_[0]->as_HTML );
        } else {
            return $class->$orig( content => $_[0] );
        }
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    $self->_parse if $self->has_content;
}

sub _parse {
    my $self = shift;
    $self->_tree->parse( $self->content );

    foreach my $trs_comments ( $self->_tree->find( ( 'tr', '~comment' ) ) ) {
        my @values;
        if ( $trs_comments->tag() eq '~comment' ) {
            @values = ( 'comment', $trs_comments->attr('text'), '' );
        }
        elsif ( $trs_comments->tag() eq 'tr' ) {

            @values = map {
                my $value = '';
                foreach my $child ( $_->content_list ) {

                    if ( ref($child) && eval { $child->isa('HTML::Element') } ) {
                        $value .= $child->as_HTML('<>&');
                    }

                    elsif ( try { $child->attr('_tag') == '~comment' } catch { 0 } )
                    {
                        $value .= $child->attr('text');
                    }
                    else {
                        $value .= $child;
                    }
                }
                $value;
            } $trs_comments->find('td');
        }
        $self->values( \@values );
    }
}

sub as_perl {
    my $self = shift;

    my $line;
    my $code = $command_map{ $self->{values}->[0] };
    my @args = @{ $self->{values} };
    shift @args;
    if ($code) {
        $line = _turn_func_into_perl( $code, @args );
    }
    if ($line) {
        $line .= "\n";
    }
    return $line;
}

sub _build_element {
    my $self = shift;

    my $element = HTML::Element->new('tr');
    if ( $self->{values}->[0] eq "comment" ) {
        $element = HTML::Element->new('~comment');
        $element->attr( 'text', $self->{values}->[1] );

    }
    else {
        $element = HTML::Element->new('tr');
        foreach my $value ( @{ $self->{values} } ) {
            my $td = HTML::Element->new('td')->unshift_content($value);
            $element->push_content($td);
        }
    }
    return $element;
}

sub _get_selenese_template_for_tag {
    my $self = shift;
    my $tag = shift;
    $tag = $self->element->tag unless $tag;

    #my $tag = $self->element->tag;
    my $template = $_selenese_command_template;
    $template = $_selenese_comment_template
      if ( $tag eq "~comment" );
    return $template;
}

sub as_html {
    my $self     = shift;
    my $tt       = Template->new;
    my $template = $self->_get_selenese_template_for_tag( $self->element->tag );
    my $output   = '';
    my $vars     = { values => $self->values, };
    $tt->process( \$template, $vars, \$output );
    return Encode::decode_utf8 $output;
}

sub as_HTML { shift->as_html };

sub _turn_func_into_perl {
    my ( $code, @args ) = @_;

    my $line = '';
    if ( ref( $code->{func} ) eq 'ARRAY' ) {
        foreach my $subcode ( @{ $code->{func} } ) {
            $line .= "\n" if $line;
            $line .= _turn_func_into_perl( $subcode, @args );
        }
    }
    else {
        if ( defined $code->{func} && $code->{func} eq '#' ) {
            $line = $code->{func} . _make_args( $code, @args );
        }
        elsif ( defined $code->{store} && $code->{store} ) {
            my $varname = pop @args;
            $line = 'my $' . "$varname = ";
            if ( $code->{func} ) {
                $line .=
                    "\$sel->"
                  . $code->{func} . '('
                  . _make_args( $code, @args ) . ');';
            }
            else {
                $line .= _make_args( $code, @args ) . ";";
            }
        }
        else {
            $line =
              '$sel->' . $code->{func} . '(' . _make_args( $code, @args ) . ');';
        }

        #        if ( $code->{repeat} ) {
        #            my @lines;
        #            push( @lines, $line ) for ( 1 .. $code->{repeat} );
        #            $line = join( "\n", @lines );
        #        }
        if ( $code->{wait} ) {
            $line =~ s/;$//;
            $line = <<EOF;
WAIT: {
    for (1..60) {
        if (eval { $line }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}
pass;
EOF
            chomp $line;
        }
    }
    return $line;
}

sub _make_args {
    my ( $code, @args ) = @_;
    my $str = '';
    if ( $code->{force_args} ) {
        $str .= join( ', ', map { _quote($_) } @{ $code->{force_args} } );
    }
    else {
        my @args = map { defined $args[$_] ? $args[$_] : '' } ( 0 .. $code->{args} - 1 );
        my @a;
        foreach my $arg (@args) {
            $arg =~ s/^exact://;
            push @a, $arg;
        }
        if ( defined $code->{func} && $code->{func} eq '#' ? 0 : 1 ) {
            my @_args;
            foreach my $arg (@a) {
                push @_args, _quote($arg);
            }
            $str .= join( ', ', @_args);
        }
        else {
            $str .= join( ', ', @a );
        }
    }

    return $str;
}

sub _quote {
    my $str        = shift;
    my $quote_char = shift;

    $str =~ s,<br />,\\n,g;
    unless ( $str =~ s/^\$\{(.*)\}/\$$1/ ) {
        $str =~ s/\Q$_\E/\\$_/g for qw(" % @ $);
        $str = '"' . $str . '"';
    }
    return $str;
}

1;


=pod

=head1 NAME

Parse::Selenese::Command - A Selenese Command

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Parse::Selenese;

=head1 DESCRIPTION

Parse::Selenese consumes Selenium Selenese Test Cases and Suites and can turn
them into Perl.

=head2 Functions

=over

=item C<BUILD>

Moose method that runs after object initialization and attempts to parse
whatever content was provided.

=item C<as_html>

Return the command in HTML (Selenese) format.

=item C<as_HTML>

An alias to C<as_html>

=item C<as_perl>

Return the command as a string of Perl.

=back

=head1 NAME

Parse::Selenese - Parse Selenium Selenese Test Cases and Suites

=head1 AUTHOR

Theodore Robert Campbell Jr E<lt>trcjr@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Theodore Robert Campbell Jr <trcjr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Theodore Robert Campbell Jr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


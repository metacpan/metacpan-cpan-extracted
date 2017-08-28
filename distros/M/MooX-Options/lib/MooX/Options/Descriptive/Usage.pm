package MooX::Options::Descriptive::Usage;

use strictures 2;

=head1 NAME

MooX::Options::Descriptive::Usage - Usage class

=head1 DESCRIPTION

Usage class to display the error message.

This class use the full size of your terminal

=cut

## no critic (ProhibitExcessComplexity)

our $VERSION = "4.103";

use Getopt::Long::Descriptive;
use Module::Runtime qw(use_module);
use Scalar::Util qw/blessed/;
use Text::LineFold ();

use Moo;
with "MooX::Locale::Passthrough";

has format_doc => ( is => "lazy" );

## no critic (Subroutines::RequireFinalReturn, Subroutines::ProhibitUnusedPrivateSubroutines)

sub _build_format_doc {
    my $self = shift;
    +{  's'  => $self->__("String"),
        's@' => $self->__("[Strings]"),
        'i'  => $self->__("Int"),
        'i@' => $self->__("[Ints]"),
        'o'  => $self->__("Ext. Int"),
        'o@' => $self->__("[Ext. Ints]"),
        'f'  => $self->__("Real"),
        'f@' => $self->__("[Reals]"),
    };
}

has format_doc_long => ( is => "lazy" );

sub _build_format_doc_long {
    my $self = shift;
    +{  's'  => $self->__("String"),
        's@' => $self->__("Array of Strings"),
        'i'  => $self->__("Integer"),
        'i@' => $self->__("Array of Integers"),
        'o'  => $self->__("Extended Integer"),
        'o@' => $self->__("Array of extended integers"),
        'f'  => $self->__("Real number"),
        'f@' => $self->__("Array of real numbers"),
    };
}

=head1 ATTRIBUTES

Following attributes are present and behave as GLD::Usage describe them.

=head2 leader_text

Text that appear on top of your message

=head2 options

The options spec of your message

=cut

has leader_text => ( is => "ro" );
has options     => ( is => "ro" );

=head1 METHODS

=head2 sub_commands_text

Return the list of sub commands if available.

=cut

sub sub_commands_text {
    my ($self) = @_;
    my $sub_commands = [];
    if (defined $self->{target}
        && defined(
            my $sub_commands_options = $self->{target}->_options_sub_commands
        )
        )
    {
        $sub_commands = $sub_commands_options;
    }
    return if !@$sub_commands;
    return "",
        $self->__("SUB COMMANDS AVAILABLE: ")
        . join( ', ', map { $_->{name} } @$sub_commands ), "";
}

=head2 text

Return a compact help message.

=cut

sub text {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target}
        ? $self->{target}->_options_config
        : ( spacer => " " );
    my $getopt_options = $self->options;

    my $lf = _get_line_fold();

    my @to_fold;
    my $max_spec_length = 0;
    for my $opt (@$getopt_options) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @to_fold, '';
            push @to_fold,
                $options_config{spacer} x ( $lf->config('ColMax') - 4 );
            next;
        }
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $self->format_doc->{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};

        my $spec
            = ( defined $short ? "-" . $short . " " : "" ) . "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name}
            . ( defined $format_doc_str ? "=" . $format_doc_str : "" );

        $max_spec_length = length($spec) if $max_spec_length < length($spec);

        push @to_fold, $spec, $opt->{desc};
    }

    my @message;
    while (@to_fold) {
        my $spec = shift @to_fold;
        my $desc = shift @to_fold;
        if ( length($spec) ) {
            push @message,
                $lf->fold(
                "    ",
                " " x ( 6 + $max_spec_length ),
                sprintf(
                    "%-" . ( $max_spec_length + 1 ) . "s %s",
                    $spec, $desc
                )
                );
        }
        else {
            push @message, $desc, "\n";
        }
    }

    return join( "\n",
        $self->leader_text, "", join( "", @message ),
        $self->sub_commands_text );
}

# set the column size of your terminal into the wrapper
sub _get_line_fold {
    my $columns = $ENV{TEST_FORCE_COLUMN_SIZE}
        || eval {
        use_module("Term::Size::Any");
        [ Term::Size::Any::chars() ]->[0];
        } || 80;

    return Text::LineFold->new( ColMax => $columns - 4 );
}

=head2 option_help

Return the help message for your options

=cut

sub option_help {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target}
        ? $self->{target}->_options_config
        : ( spacer => " " );
    my $getopt_options = $self->options;
    my @message;
    my $lf = _get_line_fold();
    for my $opt (@$getopt_options) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @message,
                $options_config{spacer} x ( $lf->config('ColMax') - 4 );
            push @message, "";
            next;
        }
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $self->format_doc->{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};
        push @message,
              ( defined $short ? "-" . $short . " " : "" ) . "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name} . ":"
            . ( defined $format_doc_str ? " " . $format_doc_str : "" );

        my $opt_data = $options_data{ $opt->{name} };
        $opt_data = {} if !defined $opt_data;
        push @message,
            $lf->fold(
            "    ",
            "        ",
            defined $opt_data->{long_doc}
            ? $self->__( $opt_data->{long_doc} )
            : $self->__( $opt->{desc} )
            );
    }

    return join( "\n",
        $self->leader_text, join( "\n    ", "", @message ),
        $self->sub_commands_text );
}

=head2 option_pod

Return the usage message in pod format

=cut

sub option_pod {
    my ($self) = @_;

    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target}
        ? $self->{target}->_options_config
        : ( spacer => " " );

    my $prog_name = $self->{prog_name};
    $prog_name = Getopt::Long::Descriptive::prog_name if !defined $prog_name;

    my $sub_commands = [];
    if (defined $self->{target}
        && defined(
            my $sub_commands_options
                = $self->{target}->_options_sub_commands()
        )
        )
    {
        $sub_commands = $sub_commands_options;
    }

    my @man = ( "=encoding UTF-8", "=head1 NAME", $prog_name, );

    if ( defined( my $description = $options_config{description} ) ) {
        push @man, "=head1 DESCRIPTION", $description;
    }

    push @man,
        (
        "=head1 SYNOPSIS",
        $prog_name . " [-h] [" . $self->__("long options ...") . "]"
        );

    if ( defined( my $synopsis = $options_config{synopsis} ) ) {
        push @man, $synopsis;
    }

    push @man, ( "=head1 OPTIONS", "=over" );

    my $spacer_escape = "E<" . ord( $options_config{spacer} ) . ">";
    for my $opt ( @{ $self->options } ) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @man, "=back";
            push @man, $spacer_escape x 40;
            push @man, "=over";
            next;
        }
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $self->format_doc_long->{$format}
            if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};

        my $opt_long_name
            = "-" . ( length( $opt->{name} ) > 1 ? "-" : "" ) . $opt->{name};
        my $opt_name
            = ( defined $short ? "-" . $short . " " : "" )
            . $opt_long_name . ":"
            . ( defined $format_doc_str ? " " . $format_doc_str : "" );

        push @man, "=item B<" . $opt_name . ">";

        my $opt_data = $options_data{ $opt->{name} };
        $opt_data = {} if !defined $opt_data;
        push @man, defined $opt_data->{long_doc}
            ? $opt_data->{long_doc}
            : $opt->{desc};
    }
    push @man, "=back";

    if (@$sub_commands) {
        push @man, "=head1 AVAILABLE SUB COMMANDS";
        push @man, "=over";
        for my $sub_command (@$sub_commands) {
            if ($sub_command->{command}->can("_options_config")
                && defined(
                    my $desc
                        = { $sub_command->{command}->_options_config }
                        ->{description}
                )
                )
            {
                push @man, "=item B<" . $sub_command->{name} . "> : " . $desc;
            }
            else {
                push @man, "=item B<" . $sub_command->{name} . "> :";
            }

            push @man,
                  $prog_name . " "
                . $sub_command->{name}
                . " [-h] ["
                . $self->__("long options ...") . "]";
        }
        push @man, "=back";
    }

    if ( defined( my $authors = $options_config{authors} ) ) {
        if ( !ref $authors && length($authors) ) {
            $authors = [$authors];
        }
        if (@$authors) {
            push @man, ( "=head1 AUTHORS", "=over" );
            push @man, map { "=item B<" . $_ . ">" } @$authors;
            push @man, "=back";
        }
    }

    return join( "\n\n", @man );
}

=head2 option_short_usage

All options message without help

=cut

sub option_short_usage {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my $getopt_options = $self->options;

    my $prog_name = $self->{prog_name};
    $prog_name = Getopt::Long::Descriptive::prog_name if !defined $prog_name;

    my @message;
    for my $opt (@$getopt_options) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @message, '';
            next;
        }
        my ($format) = $opt->{spec} =~ /(?:\|\w)?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $self->format_doc->{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};
        push @message,
              "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name}
            . ( defined $format_doc_str ? "=" . $format_doc_str : "" );
    }
    return
        join( " ", $prog_name, map { $_ eq '' ? " | " : "[ $_ ]" } @message );
}

=head2 warn

Warn your options help message

=cut

sub warn { return CORE::warn shift->text }

=head2 die

Croak your options help message

=cut

sub die {
    my ($self) = @_;
    $self->{should_die} = 1;
    return;
}

use overload (
    q{""} => "text",
    '&{}' => sub {
        return
            sub { my ($self) = @_; return $self ? $self->text : $self->warn; };
    }
);

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Options

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Options>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Options>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-Options>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Options/>

=back

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This software is copyright (c) 2017 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;

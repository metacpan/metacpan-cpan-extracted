package Prophet::CLI::TextEditorCommand;
{
  $Prophet::CLI::TextEditorCommand::VERSION = '0.751';
}
use Any::Moose 'Role';
use Params::Validate qw/validate/;

requires 'process_template';


use constant separator_pattern => qr/^=== (.*) ===$/;


use constant comment_pattern => qr/^\s*#/;


sub build_separator {
    my $self = shift;
    my $text = shift;

    return "=== $text ===";
}


sub build_template_section {
    my $self = shift;
    my %args = validate( @_, { header => 1, data => 0 } );
    return $self->build_separator( $args{'header'} ) . "\n\n"
      . ( $args{data} || '' );
}


sub try_to_edit {
    my $self = shift;
    my %args = validate(
        @_,
        {
            template => 1,
            record   => 0,
        }
    );

    my $template = ${ $args{template} };

    # do the edit
    my $updated = $self->edit_text($template);

    die "Aborted.\n" if $updated eq $template;    # user didn't change anything

    $self->process_template(
        template => $args{template},
        edited   => $updated,
        record   => $args{record}
    );
}


sub handle_template_errors {
    my $self = shift;
    my %args = validate(
        @_,
        {
            error          => 1,
            template_ref   => 1,
            bad_template   => 1,
            rtype          => 1,
            errors_pattern => 0,
            old_errors     => 0
        }
    );
    my $errors_pattern =
      defined $args{errors_pattern}
      ? $args{errors_pattern}
      : "=== errors in this $args{rtype} ===";

    $self->prompt_Yn(
        "Whoops, an error occurred processing your $args{rtype}.\nTry editing again? (Errors will be shown.)"
    ) || die "Aborted.\n";

    # template is section-based
    if ( !defined $args{old_errors} ) {

        # if the bad template already has an errors section in it, remove it
        $args{bad_template} =~ s/$errors_pattern.*?\n(?==== .*? ===\n)//s;
    }

    # template is not section-based: we allow passing in the old error to kill
    else {
        $args{bad_template} =~ s/\Q$args{old_errors}\E\n\n\n//;
    }

    ${ $args{'template_ref'} } =
        ( $errors_pattern ? "$errors_pattern\n\n" : '' )
      . $args{error}
      . "\n\n\n"
      . $args{bad_template};
    return 0;
}

no Any::Moose 'Role';
1;

__END__

=pod

=head1 NAME

Prophet::CLI::TextEditorCommand

=head1 VERSION

version 0.751

=head1 METHODS

=head2 build_separator $text

Takes a string and returns it in separator form. A separator is a line of text
that denotes a section in a template.

=head2 build_template_section header => '=== foo ===' [, data => 'bar']

Takes a header text string and (optionally) a data string and formats them into
a template section.

=head2 try_to_edit template => \$tmpl [, record => $record ]

Edits the given template if possible. Passes the updated template in to
process_template (errors in the updated template must be handled there, not
here).

=head2 handle_template_errors error => 'foo', template_ref => \$tmpl_str, bad_template => 'bar', rtype => 'ticket'

Should be called in C<process_template> if errors (usually validation ones)
occur while processing a record template. This method prompts the user to
re-edit and updates the template given by C<template_ref> to contain the bad
template (given by the arg C<bad_template> prefixed with the error messages
given in the C<error> arg. If an errors section already exists in the template,
it is replaced with an errors section containing the new errors.

If the template you are editing is not section-based, you can override what
will be prepended to the template by passing in the C<errors_pattern> argument,
and passing in C<old_errors> if a template errors out repeatedly and there are
old errors in the template that need to be replaced.

Other arguments are: C<rtype>: the type of the record being edited. All
arguments except overrides (C<errors_pattern> and C<old_errors> are required.

=head2 separator_pattern

A pattern that will match on lines that count as section separators in record
templates. Separator string text is remembered as C<$1>.

=head2 comment_pattern

A pattern that will match on lines that count as comments in record templates.

=head1 calling code must implement

run process_template

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
